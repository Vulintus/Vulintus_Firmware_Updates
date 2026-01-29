# Vulintus Firmware Updater (Python)

This is a Python port of the Vulintus Firmware Updater, designed to replace the MATLAB/avrdude/bossac toolchain with a pure Python solution.

## Installation

1.  Ensure you have Python installed.
2.  Install the dependencies:
    ```bash
    pip install -r requirements.txt
    ```

## Usage

1.  Run the GUI:
    ```bash
    python gui.py
    ```
2.  Select your **COM Port**.
3.  Load your firmware file (`.hex` for AVR, `.bin` or `.hex` for SAMD).
4.  Select the **Programmer**:
    *   **AVR (Atmega328p)**: For Arduino Uno/Nano based boards.
    *   **SAM-BA (SAMD21)**: For Arduino Zero/M0/Feather M0 based boards.
5.  Click **PROGRAM**.

## Features

*   **Pure Python**: No external `.exe` files required.
*   **STK500v1**: Native implementation for AVR flashing.
*   **SAM-BA**: Native implementation for SAMD flashing (replacing `bossac`).
*   **Auto-Reset**: Handles the "1200bps touch" reset for SAMD boards automatically.
