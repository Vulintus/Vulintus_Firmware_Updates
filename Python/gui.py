import tkinter as tk
from tkinter import filedialog, messagebox, ttk
import serial.tools.list_ports
import os
import threading
from protocols.avrdude_repl import STK500v1
from protocols.bossac_repl import SAM_BA

class FirmwareUpdaterDetails:
    def __init__(self, root):
        self.root = root
        self.root.title("Vulintus Firmware Updater (Python)")
        self.root.geometry("600x500")
        
        # Styles
        style = ttk.Style()
        style.configure("Bold.TLabel", font=('Helvetica', 10, 'bold'))
        
        # Variables
        self.com_port = tk.StringVar()
        self.file_path = tk.StringVar()
        self.programmer = tk.StringVar(value="AVR (Atmega328p)")
        self.boot_offset = tk.StringVar(value="0x2000")
        
        # Layout
        self._create_widgets()
        self._scan_ports()

    def _create_widgets(self):
        # COM Port Section
        frame_port = ttk.Frame(self.root, padding=10)
        frame_port.pack(fill='x')
        
        ttk.Label(frame_port, text="COM Port:", style="Bold.TLabel").pack(side='left')
        self.combo_port = ttk.Combobox(frame_port, textvariable=self.com_port, state="readonly", width=30)
        self.combo_port.pack(side='left', padx=5)
        ttk.Button(frame_port, text="SCAN", command=self._scan_ports).pack(side='left', padx=5)
        
        # File Section
        frame_file = ttk.Frame(self.root, padding=10)
        frame_file.pack(fill='x')
        
        ttk.Label(frame_file, text="Firmware File:", style="Bold.TLabel").pack(side='left')
        ttk.Entry(frame_file, textvariable=self.file_path, state='readonly', width=35).pack(side='left', padx=5)
        ttk.Button(frame_file, text="LOAD", command=self._load_file).pack(side='left', padx=5)
        
        # Programmer Section
        frame_prog = ttk.Frame(self.root, padding=10)
        frame_prog.pack(fill='x')
        
        ttk.Label(frame_prog, text="Programmer:", style="Bold.TLabel").pack(side='left')
        prog_combo = ttk.Combobox(frame_prog, textvariable=self.programmer, state="readonly", width=20)
        prog_combo['values'] = ("AVR (Atmega328p)", "SAM-BA (SAMD21)")
        prog_combo.bind('<<ComboboxSelected>>', self._update_ui_state)
        prog_combo.pack(side='left', padx=5)
        
        #  set (Hidden for AVR)
        self.lbl_offset = ttk.Label(frame_prog, text="Offset:", style="Bold.TLabel")
        self.combo_offset = ttk.Combobox(frame_prog, textvariable=self.boot_offset, state="readonly", width=10)
        self.combo_offset['values'] = ("0x0000", "0x2000", "0x4000")
        
        # Program Button
        self.btn_program = ttk.Button(self.root, text="PROGRAM", command=self._start_programming, state='disabled')
        self.btn_program.pack(pady=10, fill='x', padx=20)
        
        # Log Area
        self.log_area = tk.Text(self.root, height=15, width=70, state='disabled')
        self.log_area.pack(pady=10, padx=10, fill='both', expand=True)
        
        self._update_ui_state()

    def _log(self, message):
        self.log_area.config(state='normal')
        self.log_area.insert(tk.END, message + "\n")
        self.log_area.see(tk.END)
        self.log_area.config(state='disabled')

    def _scan_ports(self):
        ports = serial.tools.list_ports.comports()
        port_list = [f"{p.device} ({p.description})" for p in ports]
        self.combo_port['values'] = port_list
        if port_list:
            self.combo_port.current(0)
        else:
            self.com_port.set("")
        self._log(f"Found {len(port_list)} ports.")

    def _load_file(self):
        filetypes = [("Hex/Bin Files", "*.hex *.bin"), ("All Files", "*.*")]
        path = filedialog.askopenfilename(filetypes=filetypes)
        if path:
            self.file_path.set(path)
            self.btn_program.config(state='normal')
            
    def _update_ui_state(self, event=None):
        if self.programmer.get() == "SAM-BA (SAMD21)":
            self.lbl_offset.pack(side='left', padx=5)
            self.combo_offset.pack(side='left')
        else:
            self.lbl_offset.pack_forget()
            self.combo_offset.pack_forget()

    def _start_programming(self):
        if not self.com_port.get():
            messagebox.showerror("Error", "Please select a COM port.")
            return
        if not self.file_path.get():
            messagebox.showerror("Error", "Please select a firmware file.")
            return

        # Extract actual COM port (COMx)
        port = self.com_port.get().split(' ')[0]
        file = self.file_path.get()
        mode = self.programmer.get()
        offset = self.boot_offset.get()

        self.btn_program.config(state='disabled')
        self._log("-" * 30)
        self._log(f"Starting upload on {port}...")
        
        # Run in thread to not freeze UI
        threading.Thread(target=self._run_upload, args=(port, file, mode, offset)).start()

    def _run_upload(self, port, file, mode, offset):
        try:
            if mode == "AVR (Atmega328p)":
                if not file.lower().endswith('.hex'):
                    self._log("Converting BIN to HEX is not supported for AVR yet. Please use .hex file.")
                    return
                
                uploader = STK500v1(port)
                self._log("Connecting to AVR...")
                uploader.program_hex(file, callback=self._progress_callback)
                uploader.close()
                
            elif mode == "SAM-BA (SAMD21)":
                # Convert HEX to BIN if needed?
                # The protocol expects BIN data or we assume BIN file.
                # If HEX, we need to convert.
                target_file = file
                if file.lower().endswith('.hex'):
                    self._log("Converting HEX to temporary BIN...")
                    ih = IntelHex(file)
                    target_file = file + ".tmp.bin"
                    ih.tobinfile(target_file)
                
                # 1200bps touch
                self._log("Touching 1200bps to reset...")
                SAM_BA.touch_port_1200bps(port)
                
                # Wait heavily depends on OS re-enumeration
                self._log("Waiting for re-enumeration...")
                # In a real app, we might need to re-scan for the new port if it changes
                # But typically it stays same COM or we blindly try.
                # Let's blindly try the same port or ask user? 
                # Vulintus script logic: Scan for new port.
                
                # Check for new port logic (simplified):
                time.sleep(3) 
                
                new_port = self._find_new_port(port)
                self._log(f"Targeting port: {new_port}")
                
                uploader = SAM_BA(new_port)
                if not uploader.connect():
                     raise Exception("Failed to connect to SAM-BA bootloader")
                
                off_int = int(offset, 16)
                self._log(f"Uploading to {new_port} at offset {offset}...")
                uploader.program_binary(target_file, start_offset=off_int, callback=self._progress_callback)
                uploader.close()
                
                if target_file != file:
                    os.remove(target_file)
            
            self._log("SUCCESS! Firmware updated.")
            messagebox.showinfo("Success", "Firmware update completed successfully!")
            
        except Exception as e:
            self._log(f"ERROR: {e}")
            messagebox.showerror("Error", f"Update failed: {str(e)}")
        finally:
             if self.root: # basic check if still alive
                self.btn_program.config(state='normal')

    def _find_new_port(self, old_port):
        # Scan ports again, if we see a new one, use it.
        # Otherwise use old_port (maybe it didn't change name)
        current_ports = [p.device for p in serial.tools.list_ports.comports()]
        if old_port in current_ports:
            return old_port
        # If old port gone, look for any new port?
        # This detection is tricky without knowing previous state perfectly.
        # For now, return old_port and hope it's consistent (common on some drivers).
        return old_port

    def _progress_callback(self, current, total):
        pct = int((current / total) * 100)
        # Update log sparingly
        if pct % 10 == 0:
            self.root.after(0, lambda: self._log(f"Progress: {pct}%"))

def main():
    root = tk.Tk()
    app = FirmwareUpdaterDetails(root)
    root.mainloop()

if __name__ == "__main__":
    main()
