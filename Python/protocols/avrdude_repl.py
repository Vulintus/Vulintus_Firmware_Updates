import serial
import time
import sys
from intelhex import IntelHex

class STK500v1:
    """
    Pure Python implementation of a subset of the STK500v1 protocol.
    Targeted for Arduino Uno (Atmega328p) bootloaders.
    """
    
    # STK500 Constants
    STK_OK              = 0x10
    STK_INSYNC          = 0x14
    STK_NOSYNC          = 0x15
    CRC_EOP             = 0x20 # "Space"
    
    # Commands
    STK_GET_SYNC        = 0x30
    STK_GET_SIGN_ON     = 0x31
    STK_GET_PARAMETER   = 0x41
    STK_SET_DEVICE      = 0x42
    STK_ENTER_PROGMODE  = 0x50
    STK_LEAVE_PROGMODE  = 0x51
    STK_LOAD_ADDRESS    = 0x55
    STK_PROG_PAGE       = 0x64
    STK_READ_PAGE       = 0x74
    STK_READ_SIGN       = 0x75
    
    def __init__(self, port, baudrate=115200, timeout=1):
        self.ser = serial.Serial(port, baudrate=baudrate, timeout=timeout)
        # Toggle DTR to reset Arduino
        self.ser.dtr = False
        time.sleep(0.1)
        self.ser.dtr = True
        time.sleep(0.1)
        
    def close(self):
        if self.ser.is_open:
            self.ser.close()

    def _send(self, data):
        """Send byte(s) to serial port."""
        if isinstance(data, list):
            self.ser.write(bytearray(data))
        elif isinstance(data, int):
            self.ser.write(bytes([data]))
        else:
            self.ser.write(data)

    def _recv(self, count=1):
        """Receive byte(s) from serial port."""
        return self.ser.read(count)

    def _get_sync(self):
        """Establish synchronization with the bootloader."""
        # Try multiple times to sync
        for _ in range(5):
            self._send([self.STK_GET_SYNC, self.CRC_EOP])
            resp = self._recv(2)
            if len(resp) == 2 and resp[0] == self.STK_INSYNC and resp[1] == self.STK_OK:
                return True
            time.sleep(0.1)
        return False

    def check_connection(self):
        """Check if we can talk to the bootloader."""
        return self._get_sync()

    def get_signature(self):
        """Read 3 bytes of device signature."""
        self._send([self.STK_READ_SIGN, self.CRC_EOP])
        if self._recv(1)[0] != self.STK_INSYNC:
            raise Exception("Sync lost during signature read")
            
        sig = self._recv(3)
        
        if self._recv(1)[0] != self.STK_OK:
            raise Exception("Protocol error during signature read")
            
        return sig

    def set_device_params(self):
        """
        Send device parameters. For Arduino Uno/328p, these are fairly standard.
        We are essentially mimicking what avrdude checks/sends, though simple bootloaders
        often ignore most of this.
        """
        # Using typical ATmega328p parameters
        cmd = [
            self.STK_SET_DEVICE,
            0x86, # device code
            0x00, # revision
            0x00, # progtype
            0x01, # parmode
            0x01, # polling
            0x01, # selftimed
            0x01, # lockbytes
            0x03, # fusebytes
            0xff, # flashpollval1
            0xff, # flashpollval2
            0xff, # eeprompollval1
            0xff, # eeprompollval2
            0x00, # pagesizehigh
            0x80, # pagesizelow  (128 bytes)
            0x04, # eepromsizehigh
            0x00, # eepromsizelow
            0x00, # flashsize4
            0x80, # flashsize3
            0x00, # flashsize2
            0x00, # flashsize1 (32KB)
            self.CRC_EOP
        ]
        self._send(cmd)
        resp = self._recv(2)
        return len(resp) == 2 and resp[0] == self.STK_INSYNC and resp[1] == self.STK_OK
    
    def enter_progmode(self):
        self._send([self.STK_ENTER_PROGMODE, self.CRC_EOP])
        resp = self._recv(2)
        return len(resp) == 2 and resp[0] == self.STK_INSYNC and resp[1] == self.STK_OK
        
    def leave_progmode(self):
        self._send([self.STK_LEAVE_PROGMODE, self.CRC_EOP])
        resp = self._recv(2)
        return len(resp) == 2 and resp[0] == self.STK_INSYNC and resp[1] == self.STK_OK

    def load_address(self, addr):
        """Set the address for the next read/write. Address is in words for Flash."""
        # STK500v1 uses word addressing for flash, so divide byte address by 2
        addr_word = addr // 2
        low = addr_word & 0xFF
        high = (addr_word >> 8) & 0xFF
        self._send([self.STK_LOAD_ADDRESS, low, high, self.CRC_EOP])
        resp = self._recv(2)
        return len(resp) == 2 and resp[0] == self.STK_INSYNC and resp[1] == self.STK_OK

    def program_page(self, data):
        """Write a block of data to the currently loaded address."""
        length = len(data)
        high_len = (length >> 8) & 0xFF
        low_len = length & 0xFF
        
        cmd = [self.STK_PROG_PAGE, high_len, low_len, 0x46] # 0x46 = Flash memory
        self._send(cmd)
        self._send(data)
        self._send([self.CRC_EOP])
        
        resp = self._recv(2)
        return len(resp) == 2 and resp[0] == self.STK_INSYNC and resp[1] == self.STK_OK

    def read_page(self, length):
        """Read a block of data from the current loaded address."""
        high_len = (length >> 8) & 0xFF
        low_len = length & 0xFF
        
        cmd = [self.STK_READ_PAGE, high_len, low_len, 0x46] # 0x46 = Flash memory
        self._send(cmd)
        
        if self._recv(1)[0] != self.STK_INSYNC:
             raise Exception("Sync lost during read page")
        
        data = self._recv(length)
        
        if self._recv(1)[0] != self.STK_OK:
            raise Exception("Protocol error during read page")
            
        return data

    def program_hex(self, hex_file_path, callback=None):
        """
        Main function to flash a HEX file.
        callback: function(current, total) for progress updates
        """
        uh = IntelHex(hex_file_path)
        # Atmega328p page size is 128 bytes
        page_size = 128
        
        binary_data = uh.tobinarray()
        
        # Pad with 0xFF to multiple of page size
        remainder = len(binary_data) % page_size
        if remainder > 0:
            binary_data.extend([0xFF] * (page_size - remainder))
            
        total_bytes = len(binary_data)
        
        if not self.check_connection():
            raise Exception("Failed to sync with device")
            
        if not self.set_device_params():
            raise Exception("Failed to set device parameters")
        
        if not self.enter_progmode():
            raise Exception("Failed to enter programming mode")
            
        # Write pages
        for addr in range(0, total_bytes, page_size):
            page_data = list(binary_data[addr:addr+page_size])
            
            if not self.load_address(addr):
                 raise Exception(f"Failed to load address {hex(addr)}")
            
            if not self.program_page(page_data):
                raise Exception(f"Failed to program page at {hex(addr)}")
                
            if callback:
                callback(addr + page_size, total_bytes * 2) # *2 for verify phase

        # Verify pages (simple read-back)
        for addr in range(0, total_bytes, page_size):
            page_data_orig = list(binary_data[addr:addr+page_size])
            
            if not self.load_address(addr):
                 raise Exception(f"Failed to load address {hex(addr)} for verify")
            
            read_data = list(self.read_page(page_size))
            
            if read_data != page_data_orig:
                raise Exception(f"Verify failed at {hex(addr)}")
            
            if callback:
                callback(total_bytes + addr + page_size, total_bytes * 2)

        self.leave_progmode()
        return True

if __name__ == "__main__":
    # Simple test if run directly
    if len(sys.argv) < 3:
        print("Usage: python avrdude_repl.py <COM_PORT> <HEX_FILE>")
    else:
        try:
            uploader = STK500v1(sys.argv[1])
            def progress(current, total):
                print(f"Progress: {current}/{total} ({int(current/total*100)}%)")
            uploader.program_hex(sys.argv[2], progress)
            print("Upload complete!")
        except Exception as e:
            print(f"Error: {e}")
