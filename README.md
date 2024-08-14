# Vulintus Firmware Updates

This page will guide through the process of updating the firmware on Vulintus devices. We're always working to make the firmware-updating process easier, and we'll update this guide with each new improvement, so check back every once in a while!

---

## First Steps: Download/Install the Vulintus Firmware Updater program

1. The first step for updating the firmware on any Vulintus device is to download and install the Vulintus Firmware Updater program. The program is written in MATLAB, and can be run either as a MATLAB script or, if you don't have MATLAB on the updating computer, it can be installed like any other Windows-based program.

     * To run the Firmware Updater as a MATLAB script, you'll need to download the scripts from this repository, which you can do by clicking the "<> Code" button on the main page and selecting "Download ZIP" or by cloning the repository to your computer using Git.

     * To install the Firmware Updater as a typical Windows program, download the installer from this link, launch the installer, and then follow the prompts to install it. To find the program once it's installed, search for "Vulintus Firmware Updater" in the windows search bar, and you should see it. It's helpful to create a desktop shortcut for the program.

2. Start up the Firmware Updater Program.

     * If using the MATLAB script, the script is located in the downloaded files under:

     \Vulintus_Firmware_Updates\MATLAB Scripts\Vulintus_Firmware_Updater.m

     * If using the compiled program, search for "Vulintus_Firmware_Updater" in the Windows search bar to locate the program.
  
3. In the Window that opens, you'll see three parameters you'll need to set for every Vulintus device:

    ![Vulintus Firmware Updater with no fields yet set](/assets/updater_with_no_fields_set.png)

     * **COM Port:** Select the COM port associated with the OmniTrak Controller you want to reprogram. If you're unsure which COM port is assigned to which controller, make a note of the COM ports that are listed in the drop-down menu, and then unplug the target controller's USB cable. Press the "SCAN" button to the right of the drop-down menu to refresh the COM port list. Whichever port is now not in the list is the COM port associated with your controller. Plug it back in, click "SCAN" one more time, and then select that port.
     
     * **HEX/BIN File:** Firmware updates are provided as compiled binary files. The files you'll need are attached to this email. In the future, we'll keep the latest firmware updates in the Vulintus Fimware Updates repository, so they will download automatically when you download the MATLAB scripts or install the compiled program. Download the "OmniTrak_Controller_20240712.bin" file attached to this email and click the "LOAD" button to locate and select it for the firmware update.
     
     * **Programmer:** Vulintus uses two types of microcontrollers in our devices, and each requires a different upload-control program. For the OmniTrak Controller, select "bossac.exe".

---
### Updating the Firmware on the OmniTrak Common Controller (OT-CC)



In the Window that opens, you'll see three parameters you'll need to set:

image.png

COM Port: Select the COM port associated with the OmniTrak Controller you want to reprogram. If you're unsure which COM port is assigned to which controller, make a note of the COM ports that are listed in the drop-down menu, and then unplug the target controller's USB cable. Press the "SCAN" button to the right of the drop-down menu to refresh the COM port list. Whichever port is now not in the list is the COM port associated with your controller. Plug it back in, click "SCAN" one more time, and then select that port.
HEX/BIN File: Firmware updates are provided as compiled binary files. The files you'll need are attached to this email. In the future, we'll keep the latest firmware updates in the Vulintus Fimware Updates repository, so they will download automatically when you download the MATLAB scripts or install the compiled program. Download the "OmniTrak_Controller_20240712.bin" file attached to this email and click the "LOAD" button to locate and select it for the firmware update.
Programmer: Vulintus uses two types of microcontrollers in our devices, and each requires a different upload-control program. For the OmniTrak Controller, select "bossac.exe".
With all three fields set, the interface will look something like this:

image.png

Press the "PROGRAM" button to start programming.
At this point you may encounter an error message that looks like this:

image.png

If you see this error, it means that the program couldn't find the upload-control program and associated files. Often, this is caused by internet security programs blocking downloads or installation of *.exe files, and you may need administrator privileges on your computer to fix it. Here are the steps to fix this error:
If you haven't already, download the entire "Vulintus Firmware Updates" repository (step #1).
Open the "utilities" folder and copy all of the files in that folder.

image.png
If you're running the program from the MATLAB script, paste those files into the same folder as " Vulintus_Firmware_Updater.m", which should be:

     \Vulintus_Firmware_Updates\MATLAB Scripts\Vulintus_Firmware_Updater.m

If you're running the standalone program, paste the files into this folder (you can copy and paste into Windows Explorer):

C:\Program Files\Vulintus\Vulintus_Firmware_Updater\application


Try running it again, and the error shouldn't re-appear.
If everything worked correctly, you should see a lot of text crawl across the messagebox on the window, ending a "Verify successful" message that looks like this:

image.png

---
### Updating the Firmware on the OmniTrak Nosepoke Module (OT-NP)

We're going to use the same "Vulintus Firmware Updater" program that we used for the OmniTrak Controller, so follow steps #1 and #2 above to download and install it.
The procedure to program the nosepokes is a little more complicated than for the OmniTrak Controller, because we have to program them through the Controller. To do this, we'll need to set up the OmniTrak Controller to act as a relay by temporarily uploading some specialized firmware to it. Download the attached "OmniTrak_Controller_Serial_Relay_20240712.bin" file, and follow all the same steps above to upload it to the OmniTrak Controller.
Next, keeping the "Vulintus Firmware Updater" program open, keep the COM port set to the OmniTrak Controller, but change the "HEX/BIN File:" to the attached "OmniTrak_Nosepoke_V3_20240712.hex".
Finally, change the programmer to "avrdude.exe". The program should now look something like this:

image.png

Next, if you have multiple nosepokes connected to the OmniTrak Controller, we'll need to program them one at a time. You'll select the target nosepoke by rotating the encoder dial on the front of the controller to highlight the target port, which will be shown with a yellow border on the display screen like so:

PXL_20240801_171707508.jpg

You're ready to program, but now comes the tricky part. We need to reset the nosepoke microcontroller right as the upload starts so that it enters a bootloader mode. The reset button on the nosepoke / pellet receiver is located here, just below the ethernet style connector:

PXL_20240801_171827324.jpg

Now, press the "PROGRAM" button on the "Vulintus Firmware Updater" program, and press the reset button on the nosepoke at the same time or just slightly afterwards. There's a grace period of ~half a second. 
If the timing was correct, you should see text in the message box on the program ending in:

"avrdude.exe done. Thank you."

Great! The nosepoke is reprogrammed and you can move on to the next one.
If the timing was incorrect, you'll see a series of messages that say:

"avrdude.exe: stk500_getsync() attempt 10 of 10: not in sync: resp = 0x00"

If you see those messages, just try pressing the "PROGRAM" button and reset button at the same time again, there's nothing bad that happens if it misses the bootloader window.
If you've successfully programmed one nosepoke, all you need to do to program another one is to change the target port on the OmniTrak Controller. You can leave all settings the same on the "Vulintus Firmware Updater" program. Just make sure you're pressing the reset button on the nosepoke that corresponds to the selected port.
Finally, repeat the steps above to put the "OmniTrak_Controller_20240712.bin" firmware back on the OmniTrak Controller.

Whew, okay, that was a lot to type, but I hope it covers all the bases. Try it out and let me know if you run into any issues.
