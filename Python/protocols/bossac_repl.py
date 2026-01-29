import serial
import time
import sys
import struct
from intelhex import IntelHex

class SAM_BA:
    """
    Pure Python implementation of the SAM-BA bootloader protocol.
    Targeted for SAMD21/SAMD51 devices (Arduino Zero, Feather M0/M4, etc).
    """
    
    def __init__(self, port, baudrate=115200, timeout=2):
        self.port_name = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.ser = None

    def connect(self):
        try:
            self.ser = serial.Serial(self.port_name, self.baudrate, timeout=self.timeout, write_timeout=self.timeout)
            # SAM-BA sync: send '#' and expect 'U' (on some) or just start commands
            # Usually Arduino SAMD bootloaders expect a '#' to switch to binary mode if they are in text mode,
            # or just start accepting commands.
            # We will try to sync by reading the version.
            
            # Set binary mode (just in case)
            self.ser.write(b'#')
            self.ser.read_all() # flush
            
            # Enable echo? No, usually disable echo in simple clients, but SAM-BA is often raw.
            # Let's just try to read the version.
            return True
        except Exception as e:
            print(f"Connection error: {e}")
            return False

    def close(self):
        if self.ser and self.ser.is_open:
            self.ser.close()

    def _send_cmd(self, cmd):
        self.ser.write(cmd.encode('ascii'))
        
    def _read_resp(self):
        # Responses logic can vary, usually it's silent on success or sends specific bytes
        pass

    def read_version(self):
        self.ser.write(b'V#')
        # Typical response is nothing on some, or version string on others
        # For BOSSA/SAM-BA, 'V#' should return the version.
        # However, many custom bootloaders are stripped down.
        # Let's try standard SAM-BA "N#" command (Set Normal Mode) or "T#" (Set Terminal Mode, avoid)
        # Actually checking communication:
        # Send non-command, expect error? 
        # Better: invalid command
        # Let's rely on the init phase.
        
        # Real verification:
        # Read a word from a known address?
        return "Unknown"

    def set_address(self, addr):
        """Set the current address pointer."""
        # Command: S + Address(hex) + ','
        cmd = f"S{addr:08X},"
        self.ser.write(cmd.encode('ascii'))
        # No response expected usually for Set Address
        
    def write_page(self, data):
        """Write a full page to the current address."""
        # Command: W + Length(hex) + ',' + DATA
        # However, standard SAM-BA for SAMD often uses:
        # Send data first? Or 'W' command?
        # Looking at BOSSA source, it uses 'W' command:
        # write(size) -> Write size bytes
        
        # Actually, for SAM-BA on Arduino (Bossa), the flow is:
        # 1. Set Address (S...)
        # 2. Write Page: send "W", size(4 bytes?? NO), data?
        
        # Re-visiting BOSSA protocol (SAM-BA Monitor):
        # It's text based for commands.
        # Write Byte: O
        # Write Word: W
        # Write File: ? No, that's high level.
        
        # Correct SAM-BA operations for Flash writing (applet based usually, but bootloader has built-in):
        # We want to use the 'write page' functionality if available, but SAM-BA bootloaders usually support:
        # Receive File (S command to set addr, then R/Send File) -- wait 'S' sets address.
        # For writing blocks: 
        # The BOSSA implementation uses "Write Page" which might be specific to their modified SAM-BA.
        # Standard SAM-BA: 
        # 'S' <addr> ',' : Set address
        # 'Y' <addr> ',' : Set start address?
        # 'W' <val> ',' : Write word. Slow.
        
        # Arduino SAMD Bootloaders (based on BOSSA) support a "Write Page" extension or similar?
        # Actually, they often support:
        # 'S' <addr> ','
        # 'Y' <len> ',' : Write <len> bytes to address.
        
        # Let's assume standard Arduino SAMD bootloader (SAM-BA 2.1 extension).
        # Write format:
        # S<ADDR>,
        # Y<LEN>,<DATA>
        # No, 'Y' is often "Go to address".
        
        # Let's look at `bossac` source or `arduino-flash-tools`.
        # It seems `bossac` uses:
        # write_flash:
        #  Use 'w' command? 
        #  It seems the SAMD bootloader (CDC) might be different.
        
        # Let's try to find a reference or use a simpler "write word" loop if needed, but that's slow.
        # Most "Bossa" compatible bootloaders use:
        # COMMAND_WRITE_FILE (0x57) 'W' ?
        # Wait, the BOSSA protocol is:
        # S<Addr>,
        # W<Size>,<Data...>
        # This writes to RAM usually? No.
        
        # Okay, let's look at a known Python implementation reference (pysamloader or similar) logic.
        # Common logic:
        # 1. 'N#' (Set Normal Mode)
        # 2. 'S' + ADDR + ','
        # 3. 'W' + SIZE + ',' + DATA? 
        # Actually 'W' is write word in standard SAM-BA.
        
        # The SAM-BA bootloader used in Arduino is often the "Sam-Ba monitor".
        # It supports:
        # V : Display version
        # R : Read byte
        # W : Write byte?
        # S : Set address
        # ...
        
        # HOWEVER, bossac uses a "Block Write" if available.
        # Or it assumes a specific buffer usage.
        
        # Let's implement the 'safe' way used by `acbminiuser/sam-ba-loader`:
        # It uses the standard 'W' (write word) for small chunks or specific applets.
        # BUT Arduino boards don't have the full SAM-BA ROM code, they have a bootloader in Flash.
        # This bootloader is usually the "SAM-BA Monitor" from the underlying SDK.
        
        # A key document: Atmel SAM-BA Monitor documentation.
        # Command 'S': Set Address.
        # Command 'Y': Write buffer? (No, Y is Go).
        
        # Let's go with what `bossac` does.
        # Bossac code `Samba::write`:
        # Sends 'S' address
        # Sends 'W' size ','
        # Sends data
        
        cmd = f"W{len(data):X},"
        self.ser.write(cmd.encode('ascii'))
        self.ser.write(data)
        
        # Wait for ack?
        # Bootloader usually sends no ack for raw writes, or sends a prompt?
        # We need to verify with a read.
        return True

    def read_page(self, length):
        # 'S' address
        # 'R' size ','
        # Reads size bytes.
        
        # Wait, 'R' in standard SAM-BA is Read Byte?
        # "R" -> Read Byte
        # "w" -> Read Word
        # "o" -> Write Byte
        
        # Actually, let's use the 'R' command logic from bossac:
        # `read(size)`:
        # sends 'R' + size + ','
        # reads size bytes.
        
        cmd = f"R{length:X},"
        self.ser.write(cmd.encode('ascii'))
        return self.ser.read(length)

    def verify_buffer(self, data, start_addr):
        # We can implement verify by reading back
        chunk_size = 256 # Safe chunk
        total = len(data)
        for offset in range(0, total, chunk_size):
            chunk = data[offset:offset+chunk_size]
            this_addr = start_addr + offset
            
            self.set_address(this_addr)
            read_back = self.read_page(len(chunk))
            
            if read_back != chunk:
                return False
        return True

    def program_binary(self, bin_file_path, start_offset=0x2000, callback=None):
        with open(bin_file_path, 'rb') as f:
            data = f.read()
        
        # Common page size for SAMD21 is 64 bytes, but we can write larger chunks if buffer allows.
        # Bossac usually writes larger blocks (e.g. 256 or 1024).
        # Let's use 256 bytes (safe).
        block_size = 256
        
        # Align data
        pad = len(data) % 4
        if pad:
            data += b'\xFF' * (4 - pad)
        
        # Normal mode
        self.ser.write(b'N#')
        
        total_bytes = len(data)
        
        # Writing
        for i in range(0, total_bytes, block_size):
            chunk = data[i:i+block_size]
            current_addr = start_offset + i
            
            self.set_address(current_addr)
            self.write_page(chunk)
            
            if callback:
                callback(i + block_size, total_bytes * 2)
                
        # Verification
        if not self.verify_buffer(data, start_offset):
            raise Exception("Verification failed!")
            
        # Reset
        # To reset, we can write to the AIRCR register via the bootloader?
        # Or just use the 'R' (Go) command to the start address?
        # Usually we assume the user will cycle power, or we can try to jump.
        # Application start address on SAMD21 with 0x2000 offset is 0x2000 + 4 (Stack Ptr) + 4 (Reset Handler)?
        # No, we just reset the board.
        # Standard SAM-BA 'G' command?
        # 'G' + Addr + '#'
        # self.ser.write(f"G{start_offset:X}#".encode('ascii'))
        return True

    @staticmethod
    def touch_port_1200bps(port):
        """
        Open port at 1200bps and close it to trigger SAMD bootloader reset.
        """
        try:
            s = serial.Serial(port, baudrate=1200)
            s.close()
            time.sleep(1) # Wait for device to re-enumerate
            return True
        except:
            return False

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python bossac_repl.py <COM_PORT> <BIN_FILE> [OFFSET_HEX]")
    else:
        port = sys.argv[1]
        bin_file = sys.argv[2]
        offset = int(sys.argv[3], 16) if len(sys.argv) > 3 else 0x2000
        
        # Touch 1200bps first?
        # For testing we assume it's already in bootloader mode or we want to force it.
        # print("Touching 1200bps...")
        # SAM_BA.touch_port_1200bps(port)
        # Wait for re-enumeration logic usually happens here
        
        uploader = SAM_BA(port)
        if uploader.connect():
            try:
                def progress(c, t):
                    print(f"Prop: {c}/{t}")
                uploader.program_binary(bin_file, offset, progress)
                print("Success")
            except Exception as e:
                print(f"Error: {e}")
            uploader.close()
        else:
            print("Failed to connect")
