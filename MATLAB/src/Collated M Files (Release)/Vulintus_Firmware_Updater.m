function Vulintus_Firmware_Updater

%Collated: 2024-09-05, 09:28:12

Vulintus_Firmware_Updater_Startup;                                          %Call the startup function.


%% ***********************************************************************
function Vulintus_Firmware_Updater_Startup(varargin)

%Vulintus_Firmware_Updater.m - Vulintus, Inc., 2021
%
%   VULINTUS_FIRMWARE_UPDATER creates and executes firmware programming
%   commands for the avrdude.exe (AVR microcontrollers) and bossac.exe
%   (SAMD microcontrollers) firmware uploading programs. Users select a COM
%   port target, a HEX or BIN file, and the upload program, and the script
%   then creates the appropriate command line entry.
%
%   UPDATE LOG:
%   2021-??-?? - Drew Sloan - Function first created.
%

%% Clean up the workspace.
close all force;                                                            %Close any open figures.
fclose all;                                                                 %Close any open data files.


%% Check for required toolboxes.
if ~Vulintus_Check_MATLAB_Toolboxes('Instrument Control Toolbox')           %If the instrument control toolbox isn't installed...
    return                                                                  %Skip execution of the rest of the function.
end

[port, description] = Scan_COM_Ports('Checking for Vulintus devices');      %Scan the COM ports.

if isempty(port)                                                            %If no serial ports were found...
    errordlg(['ERROR: No Vulintus devices were detected connected to '...
        'this computer.'],'No Devices Detected!');                          %Show an error in a dialog box.
    return                                                                  %Skip execution of the rest of the function.
end

ui_h = 0.7;                                                                 %Set the height for all buttons, in centimeters.
fig_w = 15;                                                                 %Set the width of the figure, in centimeters.
ui_sp = 0.1;                                                                %Set the space between uicontrols, in centimeters.
fig_h = 7*ui_sp + 13*ui_h;                                                  %Calculate the height of the figure.
set(0,'units','centimeters');                                               %Set the screensize units to centimeters.
pos = get(0,'ScreenSize');                                                  %Grab the screensize.
pos = [pos(3)/2-fig_w/2, pos(4)/2-fig_h/2, fig_w, fig_h];                   %Scale a figure position relative to the screensize.
fig = figure('units','centimeters',...
    'Position',pos,...
    'resize','off',...
    'MenuBar','none',...
    'name','Vulintus Firmware Updater',...
    'numbertitle','off');                                                   %Set the properties of the figure.

y = fig_h - ui_h - ui_sp;                                                   %Set the bottom edge for this row of uicontrols.
uicontrol(fig,'style','edit',...
    'String','COM Port: ',...
    'units','centimeters',...    
    'position',[ui_sp, y, 3, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','inactive',...
    'horizontalalignment','right',...
    'backgroundcolor',[0.9 0.9 1],...
    'tag','port_lbl');                                                      %Make a label for the port.
uicontrol(fig,'style','popupmenu',...
    'String',description,...
    'userdata',port,...
    'units','centimeters',...    
    'position',[3 + 2*ui_sp, y, 10, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','on',...
    'tag','port_pop');                                                      %Make a port pop-up menu.
rescan_btn = uicontrol(fig,'style','pushbutton',...
    'String','SCAN',...
    'units','centimeters',...    
    'position',[13 + 3*ui_sp, y, fig_w - 4*ui_sp - 13, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','on',...
    'tag','rescan_btn');                                                    %Make a re-scan button

y = fig_h - 2*ui_h - 2*ui_sp;                                               %Set the bottom edge for this row of uicontrols.
uicontrol(fig,'style','edit',...
    'String','HEX/BIN File: ',...
    'units','centimeters',...    
    'position',[ui_sp, y, 3, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','inactive',...
    'horizontalalignment','right',...
    'backgroundcolor',[0.9 0.9 1],...
    'tag','file_lbl');                                                      %Make a label for the hex/bin file.
uicontrol(fig,'style','edit',...
    'String','[click LOAD to select >>]',...
    'units','centimeters',...    
    'position',[3 + 2*ui_sp, y, 10, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','inactive',...
    'horizontalalignment','left',...
    'tag','file_edit');                                                     %Make clickable editbox for the hex file.
load_btn = uicontrol(fig,'style','pushbutton',...
    'String','LOAD',...
    'units','centimeters',...    
    'position',[13 + 3*ui_sp, y, fig_w - 4*ui_sp - 13, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','on',...
    'tag','load_btn');                                                      %Make a load button.

y = fig_h - 3*ui_h - 3*ui_sp;                                               %Set the bottom edge for this row of uicontrols.
uicontrol(fig,'style','edit',...
    'String','Programmer: ',...
    'units','centimeters',...    
    'position',[ui_sp, y, 3, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','inactive',...
    'horizontalalignment','right',...
    'backgroundcolor',[0.9 0.9 1],...
    'tag','programmer_lbl');                                                %Make a label for the programmer.
uicontrol(fig,'style','popupmenu',...
    'String',{'avrdude.exe','bossac.exe'},...
    'units','centimeters',...    
    'position',[3 + 2*ui_sp, y, fig_w - 3*ui_sp - 3, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','on',...
    'tag','prog_pop');                                                      %Make a programmer pop-up menu.

y = fig_h - 4*ui_h - 4*ui_sp;                                               %Set the bottom edge for this row of uicontrols.
uicontrol(fig,'style','edit',...
    'String','Boot Offset: ',...
    'units','centimeters',...    
    'position',[ui_sp, y, 3, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','inactive',...
    'horizontalalignment','right',...
    'backgroundcolor',[0.9 0.9 1],...
    'tag','bootloader_lbl');                                                %Make a label for the bootloader offset.
uicontrol(fig,'style','popupmenu',...
    'String',{'0x2000','0x4000'},...
    'units','centimeters',...    
    'position',[3 + 2*ui_sp, y, fig_w - 3*ui_sp - 3, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'value',2,...
    'enable','on',...
    'tag','boot_pop');                                                      %Make a bootloader offset pop-up menu.

y = fig_h - 5*ui_h - 5*ui_sp;                                               %Set the bottom edge for this row of uicontrols.
prog_btn = uicontrol(fig,'style','pushbutton',...
    'String','PROGRAM',...
    'units','centimeters',...    
    'position',[ui_sp, y, fig_w - 2*ui_sp, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','off',...
    'tag','prog_btn');                                                      %Make a program button.

msgbox = uicontrol(fig,'style','listbox',...
    'enable','inactive',...
    'string',{},...
    'units','centimeters',...
    'position',[ui_sp, ui_sp, fig_w - 2*ui_sp, 8*ui_h],...
    'fontweight','bold',...
    'fontsize',10,...
    'min',0,...
    'max',2,...
    'value',[],...
    'backgroundcolor','w',...
    'tag','msgbox');                                                        %Make a listbox for displaying messages to the user.

set(prog_btn,'callback',@Program_Vulintus_Device);                          %Set the program button callback.
set(rescan_btn,'callback',@Rescan_COM_Ports);                               %Set the program button callback.
set(load_btn,'callback',@Set_File);                                         %Set the program button callback.
Add_Msg(msgbox,'Select a COM port and hex file to start.');                 %Add a message to the message box.


function Rescan_COM_Ports(hObject, ~)
fig = get(hObject,'parent');                                                %Grab the parent of the "Scan" button uicontrol.
obj = get(fig,'children');                                                  %Grab all children of the figure.
for i = 1:length(obj)                                                       %Step through each object.
    if ~strcmpi(get(obj(i),'enable'),'inactive')                            %If the object is active...
        set(obj(i),'enable','off');                                         %Disable the object. 
    end
end
msgbox = findobj(obj,'tag','msgbox');                                       %Grab the messagebox handle.
port_pop = findobj(obj,'tag','port_pop');                                   %Grab the port pop-up menu handle.
Add_Msg(msgbox,'Re-scanning COM ports...');                                 %Show a message in the messagebox.
[port, description] = Scan_COM_Ports('Re-scanning COM ports...');           %Re-scan the COM ports.
set(port_pop,'String',description,...
    'userdata',port);                                                       %Update the port pop-up menu.
for i = 1:length(obj)                                                       %Step through each object.
    if ~strcmpi(get(obj(i),'enable'),'inactive')                            %If the object is active...
        set(obj(i),'enable','on');                                          %Enable the object. 
    end
end


function Program_Vulintus_Device(hObject, ~)
if isdeployed                                                               %If the program is compiled and deployed...
    [~, result] = system('set PATH');                                       %Grab the curent system search path.
    cur_dur = char(regexpi(result,'Path=(.*?);','tokens','once'));          %Find the path containing the current executable.
else                                                                        %Otherwise, if we're running as a MATLAB script...
    cur_dur = pwd;                                                          %Grab the current directory.
end 
fig = get(hObject,'parent');                                                %Grab the parent of the "Scan" button uicontrol.
obj = get(fig,'children');                                                  %Grab all children of the figure.
for i = 1:length(obj)                                                       %Step through each object.
    if ~strcmpi(get(obj(i),'enable'),'inactive')                            %If the object is active...
        set(obj(i),'enable','off');                                         %Disable the object. 
    end
end
msgbox = findobj(obj,'tag','msgbox');                                       %Grab the messagebox handle.
port_pop = findobj(obj,'tag','port_pop');                                   %Grab the port pop-up menu handle.
file_edit = findobj(obj,'tag','file_edit');                                 %Grab the file editbox handle.
prog_pop = findobj(obj,'tag','prog_pop');                                   %Grab the programmer pop-up menu handle.
boot_pop = findobj(obj,'tag','boot_pop');                                   %Grab the bootloader offset pop-up menu handle.
Clear_Msg(msgbox);                                                          %Clear the message.
temp = port_pop.UserData;                                                   %Grab the user data from the port pop-up menu.
port = temp{port_pop.Value};                                                %Grab the name of the selected COM port.
file = file_edit.UserData;                                                  %Grab the hex filename from the file editbox user data.
% [~,filename,ext] = fileparts(file);                                         %Grab the filename and extension for the hex file.
% temp_file = fullfile(tempdir,[filename,ext]);                               %Create a temporary filename.
% copyfile(file,temp_file,'f');                                               %Copy the file to the temporary directory.
temp = prog_pop.String;                                                     %Grab the string from the programmer pop-up menu.
programmer = temp{prog_pop.Value};                                          %Grab the name of the selected COM port.
temp = boot_pop.String;                                                     %Grab the bootloader offset options.
offset = temp{boot_pop.Value};                                              %Grab the currently selected booloader offset.
switch programmer                                                           %Switch between the programmers.

    case 'avrdude.exe'                                                      %If we're using avrdude...
        if ~exist(fullfile(cur_dur,programmer),'file') || ...
                ~exist(fullfile(cur_dur, 'avrdude.conf'),'file') || ...
                ~exist(fullfile(cur_dur, 'libusb0.dll'),'file')             %If avrdude.exe or it's configuration files aren't found...
            
            str1 = sprintf(['ERROR: Could not find programmer %s or '...
                'associated files in the current directory.'],...
                programmer);                                                %Set the first string of an error message.
            str2 = sprintf('Directory: %s',cur_dur);                        %Set the second string of an error message.
            errordlg({str1,[],str2},...
                'Required Programming Files Not Found!');                   %Show an error in a dialog box.
            close(hObject.Parent);                                          %Close the figure.
            return                                                          %Skip execution of the function.
        end
%         copyfile(fullfile(cur_dur,programmer),tempdir,'f');                 %Copy avrdude.exe to the temporary folder.
%         copyfile(fullfile(cur_dur,'avrdude.conf'),tempdir,'f');             %Copy avrdude.conf to the temporary folder.
        cmd = ['"' fullfile(cur_dur,programmer) '" '...                     %avrdude.exe location
            '-C"' fullfile(cur_dur,'avrdude.conf') '" '...                  %avrdude.conf location
            '-patmega328p '...                                              %microcontroller type
            '-carduino '...                                                 %arduino programmer
            '-P' port ' '...                                                %port
            '-b115200 '...                                                  %baud rate
            '-D '...                                                        %disable erasing the chip
            '-Uflash:w:"' file '":i'];                                      %hex file name.

    case 'bossac.exe'                                                       %If we're using bossac...

%         'https://github.com/arduino/arduino-flash-tools/raw/master/tools_darwin/bossac/bin/bossac'
        
        if ~exist(fullfile(cur_dur,programmer),'file')                      %If bossac.exe or it's configuration file aren't found...
            bossac_url = 'https://github.com/Vulintus/Vulintus_Firmware_Updater/raw/main/src/bossac.exe';
            try                                                             %Try to download bossac.
                bossac = webread(bossac_url);                               %Grab the bossac binary.
                fid = fopen(fullfile(cur_dur,programmer),'w');              %Open a binary file for writing.
                fwrite(fid,bossac);                                         %Write the binary data to the file.
                fclose(fid);                                                %Close the *.exe.
            catch
                errordlg(sprintf(['ERROR: Could not find programmer '...
                    '%s or associated files in the current directory.'],...
                    programmer),...
                    'Required Programming Files Not Found!');               %Show an error in a dialog box.
                close(hObject.Parent);                                      %Close the figure.
                return                                                      %Skip execution of the function.
            end
        end
%         copyfile(fullfile(cur_dur,programmer),tempdir,'f');                 %Copy avrdude.exe to the temporary folder.
        Add_Msg(msgbox,'Attempting programming reset...');                  %Show a message in the messagebox.
        original_ports = instrhwinfo('serial');                             %Grab information about the currently-available serial ports.
        original_ports = original_ports.SerialPorts;                        %Save the list of all serial ports regardless of whether they're busy.
        serialcon = serialport(port,1200);                                  %Set up the serial connection on the specified port.
        pause(5);                                                           %Pause for 5 seconds.
        delete(serialcon);                                                  %Delete the serial object.
        pause(5);                                                           %Pause for 5 seconds.
        temp_port = instrhwinfo('serial');                                  %Grab information about the available serial ports.
        temp_port = temp_port.SerialPorts;                                  %Save the list of all serial ports regardless of whether they're busy.
        new_port = setdiff(temp_port,original_ports);                       %Check to see if a new COM port showed up.
        if ~isempty(new_port)                                               %If a new port was found...
            temp_port = new_port{1};                                        %Set the new port as the target.            
            str = sprintf('Upload port found: %s...',temp_port);            %Show a message in the messagebox.
        else                                                                %Otherwise...
            temp_port = port;                                               %Use the original port.
            str = sprintf('No port reset detected! Using %s.',temp_port);   %Create a messagebox message.
        end
        Add_Msg(msgbox,str);                                                %Sow a message in the messagebox.


        % "C:\Users\drew\AppData\Local\Arduino15\packages\adafruit\tools\bossac\1.8.0-48-gb176eee/bossac" 
        % -i 
        % -d 
        % --port=COM10 
        % -U 
        % -i 
        % --offset=0x4000 
        % -w 
        % -v 
        % "C:\Users\drew\AppData\Local\Temp\arduino\sketches\42E4916E2275720E41C66BEA2D560F1E/OmniTrak_Controller_5Poke.ino.bin" 
        % -R
        [~, programmer, ~] = fileparts(programmer);                         %Strip the file extension from the programmer name.
        cmd = ['"' fullfile(cur_dur,programmer) '" '...                     %bossac.exe location
            '-i '...                                                        %Display diagnostic information about the device.
            '-d '...                                                        %Print verbose diagnostic messages
            '--port=' temp_port ' '...                                      %Set the COM port.
            '-U '...                                                        %Allow automatic COM port detection.
            '-i '...                                                        %Display diagnostic information about the device.
            '--offset=' offset ' '...                                           %Specify the flash memory starting offset (to retain the bootloader).
            '-w '...                                                        %Write the file to the target's flash memory.
            '-v '...                                                        %Verify the file matches the contents after writing.
            '"' file '" '...                                                %Set the file.
            '-R'];                                                          %Reset the microcontroller after writing the flash.

        % cmd = '"H:\My Drive\Vulintus Software (Drew)\Vulintus Common Functions\Vulintus Firmware Updater\src\bossac" -i -d --port=COM10 -U -i --offset=0x4000 -w -v "H:\My Drive\Vulintus Software (Drew)\Custom Software\Aldridge Lab (U-Iowa)\Firmware\OmniTrak_Controller_5Poke.ino.bin" -R'
        % cmd = '"C:\Users\drew\AppData\Local\Arduino15\packages\adafruit\tools\bossac\1.8.0-48-gb176eee/bossac" -i -d --port=COM10 -U -i --offset=0x4000 -w -v "C:\Users\drew\AppData\Local\Temp\arduino\sketches\42E4916E2275720E41C66BEA2D560F1E/OmniTrak_Controller_5Poke.ino.bin" -R'
end
clc;                                                                        %Clear the command line.
cprintf('*blue','\n%s\n',cmd);                                              %Print the command in bold green.
[~, short_file, ext] = fileparts(file);                                     %Grab the file minus the path.
Add_Msg(msgbox,sprintf('Uploading: %s%s...', short_file, ext));             %Show a message in the messagebox.
Add_Msg(msgbox,cmd);                                                        %Show a message in the messagebox.
[status, output] = dos(cmd,'-echo');                                        %Execute the command in a dos prompt, showing the results.
ln = [0, find(output == 10), numel(output) + 1];                            %Find line indices.
for i = 1:numel(ln) - 1                                                     %Step through each line.
    str = output(ln(i)+1:ln(i+1)-1);                                        %Grab the line.
    str(str < 31) = [];                                                     %Kick out any special characters.
    Add_Msg(msgbox,str);                                                    %Show a message in the messagebox.
end
if status == 0                                                              %If the command was successful...
    Add_Msg(msgbox,'Microcode successfully updated!');                      %Show a success message in the messagebox.    
else                                                                        %Otherwise...
    Add_Msg(msgbox,'Microcode update failed!');                             %Show a failure message in the messagebox.    
end
% if exist(fullfile(tempdir,programmer),'file')                               %If the programmer exists in the temporary directory...
%     delete(fullfile(tempdir,programmer));                                   %Delete it.
% end
% if exist(fullfile(tempdir,'avrdude.conf'),'file')                           %If "avrdude.conf" exists in the temporary directory...
%     delete(fullfile(tempdir,'avrdude.conf'));                               %Delete it.
% end
% if exist(temp_file,'file')                                                  %If the temporary hex file exists...
%     delete(temp_file);                                                      %Delete it.
% end
[port, description] = Scan_COM_Ports('Re-scanning COM ports...');           %Re-scan the COM ports.
set(port_pop,'String',description,...
    'userdata',port);                                                       %Update the port pop-up menu.
for i = 1:length(obj)                                                       %Step through each object.
    if ~strcmpi(get(obj(i),'enable'),'inactive')                            %If the object is active...
        set(obj(i),'enable','on');                                          %Enable the object. 
    end
end


function Set_File(hObject, ~)
fig = get(hObject,'parent');                                                %Grab the parent of the file editbox button uicontrol.
obj = get(fig,'children');                                                  %Grab all children of the figure.
prog_btn = findobj(obj,'tag','prog_btn');                                   %Grab the program button handle.
file_edit = findobj(obj,'tag','file_edit');                                 %Grab the file editbox handle.
[file, path] = uigetfile('*.hex;*.bin');                                    %Have the user select a hex file.
if file(1) == 0                                                             %If the user didn't select a file.
    return
end
file_edit.UserData = [path file];                                           %Save the filename with path.
file_edit.String = file;                                                    %Set the editbox string to the filename.
prog_btn.Enable = 'on';                                                     %Enable the program button.


function [port, description] = Scan_COM_Ports(str)
waitbar = big_waitbar('title',str,...
    'string','Detecting serial ports...',...
    'value',0.25);                                                          %Create a waitbar figure.
port = instrhwinfo('serial');                                               %Grab information about the available serial ports.
if isempty(port)                                                            %If no serial ports were found...
    errordlg(['ERROR: No Vulintus devices were detected connected to '...
        'this computer.'],'No Devices Detected!');                          %Show an error in a dialog box.
    return                                                                  %Skip execution of the rest of the function.
end
busyports = setdiff(port.SerialPorts,port.AvailableSerialPorts);            %Find all ports that are currently busy.
port = port.SerialPorts;                                                    %Save the list of all serial ports regardless of whether they're busy.
if waitbar.isclosed()                                                       %If the user closed the waitbar figure...
    return                                                                  %Skip execution of the rest of the function.
end
waitbar.string('Identifying Vulintus devices...');                          %Update the waitbar text.
waitbar.value(0.50);                                                        %Update the waitbar value.
description = cell(size(port));                                             %Create a cell array to hold the port description.
key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\';              %Set the registry query field.
[~, txt] = dos(['REG QUERY ' key ' /s /f "FriendlyName" /t "REG_SZ"']);     %Query the registry for all USB devices.
for i = 1:numel(port)                                                       %Step through each port name.
    j = strfind(txt,['(' port{i} ')']);                                     %Find the port in the USB device list.    
    if ~isempty(j)                                                          %If a matching port was found...
        k = strfind(txt(1:j),'    ');                                       %Find all quadruple spaces preceding the port.
        description{i} = txt(k(end)+4:j-2);                                 %Grab the description.
    end
end
busyports = intersect(port,busyports);                                      %Kick out all non-Vulintus devices from the busy ports list.
if waitbar.isclosed()                                                       %If the user closed the waitbar figure...
    return                                                                  %Skip execution of the rest of the function.
end
waitbar.close();                                                            %Close the waitbar.
for i = 1:numel(port)                                                       %Step through each remaining port.
    description{i} = horzcat(port{i}, ': ', description{i});                %Add the COM port to each descriptions.
    if ~isempty(busyports) && any(strcmpi(port{i},busyports))               %If the port is busy...
        description{i} = horzcat(description{i}, ' (busy)');                %Add a busy indicator.
    end
end


%% ***********************************************************************
function Add_Msg(msgbox,new_msg)
%
%Add_Msg.m - Vulintus, Inc.
%
%   ADD_MSG displays messages in a listbox on a GUI, adding new messages to
%   the bottom of the list.
%
%   Add_Msg(listbox,new_msg) adds the string or cell array of strings
%   specified in the variable "new_msg" as the last entry or entries in the
%   ListBox or Text Area whose handle is specified by the variable 
%   "msgbox".
%
%   UPDATE LOG:
%   2016-09-09 - Drew Sloan - Fixed the bug caused by setting the
%                             ListboxTop property to an non-existent item.
%   2021-11-26 - Drew Sloan - Added the option to post status messages to a
%                             scrolling text area (uitextarea).
%   2022-02-02 - Drew Sloan - Fixed handling of the UIControl ListBox type
%                             to now use the "style" for identification.
%   2024-06-11 - Drew Sloan - Added a for loop to handle arrays of
%                             messageboxes.
%

for gui_i = 1:length(msgbox)                                                %Step through each messagebox.

    switch get(msgbox(gui_i),'type')                                        %Switch between the recognized components.
        
        case 'uicontrol'                                                    %If the messagebox is a listbox...
            switch get(msgbox(gui_i),'style')                               %Switch between the recognized uicontrol styles.
                
                case 'listbox'                                              %If the messagebox is a listbox...
                    messages = get(msgbox(gui_i),'string');                 %Grab the current string in the messagebox.
                    if isempty(messages)                                    %If there's no messages yet in the messagebox...
                        messages = {};                                      %Create an empty cell array to hold messages.
                    elseif ~iscell(messages)                                %If the string property isn't yet a cell array...
                        messages = {messages};                              %Convert the messages to a cell array.
                    end
                    messages{end+1} = new_msg;                              %Add the new message to the listbox.
                    set(msgbox(gui_i),'string',messages);                   %Update the strings in the listbox.
                    set(msgbox(gui_i),'value',length(messages),...
                        'ListboxTop',length(messages));                     %Set the value of the listbox to the newest messages.
                    set(msgbox(gui_i),'min',0,...
                        'max',2',...
                        'selectionhighlight','off',...
                        'value',[]);                                        %Set the properties on the listbox to make it look like a simple messagebox.
                    drawnow;                                                %Update the GUI.
                    
            end
            
        case 'uitextarea'                                                   %If the messagebox is a uitextarea...
            messages = msgbox(gui_i).Value;                                 %Grab the current strings in the messagebox.
            if ~iscell(messages)                                            %If the string property isn't yet a cell array...
                messages = {messages};                                      %Convert the messages to a cell array.
            end
            checker = 1;                                                    %Create a matrix to check for non-empty cells.
            for i = 1:numel(messages)                                       %Step through each message.
                if ~isempty(messages{i})                                    %If there any non-empty messages...
                    checker = 0;                                            %Set checker equal to zero.
                end
            end
            if checker == 1                                                 %If all messages were empty.
                messages = {};                                              %Set the messages to an empty cell array.
            end
            messages{end+1} = new_msg;                                      %Add the new message to the listbox.
            msgbox(gui_i).Value = messages;                                 %Update the strings in the Text Area.        
            drawnow;                                                        %Update the GUI.
            scroll(msgbox(gui_i),'bottom');                                 %Scroll to the bottom of the Text Area.
    end

end
        


%% ***********************************************************************
function Clear_Msg(varargin)

%
%Clear_Msg.m - Vulintus, Inc.
%
%   CLEAR_MSG deleles all messages in a listbox on a GUI.
%
%   CLEAR_MSG(msgbox) or CLEAR_MSG(~,~,msgbox) clears all messages out of
%   the ListBox / uitextarea whose handle is specified in the variable 
%   "msgbox".
%
%   UPDATE LOG:
%   2013-01-24 - Drew Sloan - Function first created.
%   2021-11-26 - Drew Sloan - Added functionality to use scrolling text
%                             areas (uitextarea) as messageboxes.
%   2024-06-11 - Drew Sloan - Added a for loop to handle arrays of
%                             messageboxes.
%

if nargin == 1                                                              %If there's only one input argument...
    msgbox = varargin{1};                                                   %The listbox handle is the first input argument.
elseif nargin == 3                                                          %Otherwise, if there's three input arguments...
    msgbox = varargin{3};                                                   %The listbox handle is the third input argument.
end

for i = 1:length(msgbox)                                                    %Step through each messagebox.

    if strcmpi(get(msgbox(1),'type'),'uicontrol')                           %If the messagebox is a uicontrol...
        msgbox_type = get(msgbox(1),'style');                               %Grab the style property.
    else                                                                    %Otherwise...
        msgbox_type = get(msgbox(1),'type');                                %Grab the type property.
    end
    
    switch msgbox_type                                                      %Switch between the recognized components.
        
        case 'listbox'                                                      %If the messagebox is a listbox...
            set(msgbox(1),'string',{},...
                'min',0,...
                'max',0',...
                'selectionhighlight','off',...
                'value',[]);                                                %Clear the messages and set the properties on the listbox to make it look like a simple messagebox.
            
        case 'uitextarea'                                                   %If the messagebox is a uitextarea...
            messages = {''};                                                %Create a cell array with one empty entry.
            msgbox(1).Value = messages;                                     %Update the strings in the Text Area.
            scroll(msgbox(1),'bottom');                                     %Scroll to the bottom of the Text Area.
            drawnow;                                                        %Update the GUI.
            
    end

end 


%% ***********************************************************************
function toolbox_exists = Vulintus_Check_MATLAB_Toolboxes(toolbox, varargin)

%
%Vulintus_Check_MATLAB_Toolboxes.m - Vulintus, Inc.
%
%   VULINTUS_CHECK_MATLAB_TOOLBOXES checks the MATLAB installation for the 
%   specified required toolbox and throws an error if it isn't found.
%   
%   UPDATE LOG:
%   2024-01-24 - Drew Sloan - Function first created.
%


if ~isdeployed                                                              %If the function is running as a script instead of deployed code...
    matproducts = ver;                                                      %Grab all of the installed MATLAB products.
    toolbox_exists = any(strcmpi({matproducts.Name},toolbox));              %Check to see if the toolbox is installed.
    if ~toolbox_exists                                                      %If the specified toolbox isn't installed...
        fcn = dbstack;                                                      %Grab the function call stack that led to this line.       
        str = sprintf(['"%s.m" requires the MATLAB %s, which is not '...
            'installed on your computer. You will need to install the '...
            'toolbox or run a compiled version of the program.'],...
            fcn(end).name, toolbox);                                        %Create the text for an error dialog.
        errordlg(str,'Missing Required MATLAB Toolbox');                    %Show an error dialog.
    end
else                                                                        %Otherise, if the function is compiled...
    toolbox_exists = 1;                                                     %Assume the toolbox exists.
end


%% ***********************************************************************
function waitbar = big_waitbar(varargin)

figsize = [2,16];                                                           %Set the default figure size, in centimeters.
barcolor = 'b';                                                             %Set the default waitbar color.
titlestr = 'Waiting...';                                                    %Set the default waitbar title.
txtstr = 'Waiting...';                                                      %Set the default waitbar string.
val = 0;                                                                    %Set the default value of the waitbar to zero.

str = {'FigureSize','Color','Title','String','Value'};                      %List the allowable parameter names.
for i = 1:2:length(varargin)                                                %Step through any optional input arguments.
    if ~ischar(varargin{i}) || ~any(strcmpi(varargin{i},str))               %If the first optional input argument isn't one of the expected property names...
        beep;                                                               %Play the Matlab warning noise.
        cprintf('red','%s\n',['ERROR IN BIG_WAITBAR: Property '...
            'name not recognized! Optional input properties are:']);        %Show an error.
        for j = 1:length(str)                                               %Step through each allowable parameter name.
            cprintf('red','\t%s\n',str{j});                                 %List each parameter name in the command window, in red.
        end
        return                                                              %Skip execution of the rest of the function.
    else                                                                    %Otherwise...
        if strcmpi(varargin{i},'FigureSize')                                %If the optional input property is "FigureSize"...
            figsize = varargin{i+1};                                        %Set the figure size to that specified, in centimeters.            
        elseif strcmpi(varargin{i},'Color')                                 %If the optional input property is "Color"...
            barcolor = varargin{i+1};                                       %Set the waitbar color the specified color.
        elseif strcmpi(varargin{i},'Title')                                 %If the optional input property is "Title"...
            titlestr = varargin{i+1};                                       %Set the waitbar figure title to the specified string.
        elseif strcmpi(varargin{i},'String')                                %If the optional input property is "String"...
            txtstr = varargin{i+1};                                         %Set the waitbar text to the specified string.
        elseif strcmpi(varargin{i},'Value')                                 %If the optional input property is "Value"...
            val = varargin{i+1};                                            %Set the waitbar value to the specified value.
        end
    end    
end

orig_units = get(0,'units');                                                %Grab the current system units.
set(0,'units','centimeters');                                               %Set the system units to centimeters.
pos = get(0,'Screensize');                                                  %Grab the screensize.
h = figsize(1);                                                             %Set the height of the figure.
w = figsize(2);                                                             %Set the width of the figure.
fig = figure('numbertitle','off',...
    'name',titlestr,...
    'units','centimeters',...
    'Position',[pos(3)/2-w/2, pos(4)/2-h/2, w, h],...
    'menubar','none',...
    'resize','off');                                                        %Create a figure centered in the screen.
ax = axes('units','centimeters',...
    'position',[0.25,0.25,w-0.5,h/2-0.3],...
    'parent',fig);                                                          %Create axes for showing loading progress.
if val > 1                                                                  %If the specified value is greater than 1...
    val = 1;                                                                %Set the value to 1.
elseif val < 0                                                              %If the specified value is less than 0...
    val = 0;                                                                %Set the value to 0.
end    
obj = fill(val*[0 1 1 0 0],[0 0 1 1 0],barcolor,'edgecolor','k');           %Create a fill object to show loading progress.
set(ax,'xtick',[],'ytick',[],'box','on','xlim',[0,1],'ylim',[0,1]);         %Set the axis limits and ticks.
txt = uicontrol(fig,'style','text','units','centimeters',...
    'position',[0.25,h/2+0.05,w-0.5,h/2-0.3],'fontsize',10,...
    'horizontalalignment','left','backgroundcolor',get(fig,'color'),...
    'string',txtstr);                                                       %Create a text object to show the current point in the wait process.  
set(0,'units',orig_units);                                                  %Set the system units back to the original units.

waitbar.type = 'big_waitbar';                                               %Set the structure type.
waitbar.title = @(str)SetTitle(fig,str);                                    %Set the function for changing the waitbar title.
waitbar.string = @(str)SetString(fig,txt,str);                              %Set the function for changing the waitbar string.
% waitbar.value = @(val)SetVal(fig,obj,val);                                  %Set the function for changing waitbar value.
waitbar.value = @(varargin)GetSetVal(fig,obj,varargin{:});                  %Set the function for reading/setting the waitbar value.
waitbar.color = @(val)SetColor(fig,obj,val);                                %Set the function for changing waitbar color.
waitbar.close = @()CloseWaitbar(fig);                                       %Set the function for closing the waitbar.
waitbar.isclosed = @()WaitbarIsClosed(fig);                                 %Set the function for checking whether the waitbar figure is closed.

drawnow;                                                                    %Immediately show the waitbar.


%% This function sets the name/title of the waitbar figure.
function SetTitle(fig,str)
if ishandle(fig)                                                            %If the waitbar figure is still open...
    set(fig,'name',str);                                                    %Set the figure name to the specified string.
    drawnow;                                                                %Immediately update the figure.
else                                                                        %Otherwise...
    warning('Cannot update the waitbar figure. It has been closed.');       %Show a warning.
end


%% This function sets the string on the waitbar figure.
function SetString(fig,txt,str)
if ishandle(fig)                                                            %If the waitbar figure is still open...
    set(txt,'string',str);                                                  %Set the string in the text object to the specified string.
    drawnow;                                                                %Immediately update the figure.
else                                                                        %Otherwise...
    warning('Cannot update the waitbar figure. It has been closed.');       %Show a warning.
end


% %% This function sets the current value of the waitbar.
% function SetVal(fig,obj,val)
% if ishandle(fig)                                                            %If the waitbar figure is still open...
%     if val > 1                                                              %If the specified value is greater than 1...
%         val = 1;                                                            %Set the value to 1.
%     elseif val < 0                                                          %If the specified value is less than 0...
%         val = 0;                                                            %Set the value to 0.
%     end
%     set(obj,'xdata',val*[0 1 1 0 0]);                                       %Set the patch object to extend to the specified value.
%     drawnow;                                                                %Immediately update the figure.
% else                                                                        %Otherwise...
%     warning('Cannot update the waitbar figure. It has been closed.');       %Show a warning.
% end


%% This function reads/sets the waitbar value.
function val = GetSetVal(fig,obj,varargin)
if ishandle(fig)                                                            %If the waitbar figure is still open...
    if nargin > 2                                                           %If a value was passed.
        val = varargin{1};                                                  %Grab the specified value.
        if val > 1                                                          %If the specified value is greater than 1...
            val = 1;                                                        %Set the value to 1.
        elseif val < 0                                                      %If the specified value is less than 0...
            val = 0;                                                        %Set the value to 0.
        end
        set(obj,'xdata',val*[0 1 1 0 0]);                                   %Set the patch object to extend to the specified value.
        drawnow;                                                            %Immediately update the figure.
    else                                                                    %Otherwise...
        val = get(obj,'xdata');                                             %Grab the x-coordinates from the patch object.
        val = val(2);                                                       %Return the right-hand x-coordinate.
    end
else                                                                        %Otherwise...
    warning('Cannot access the waitbar figure. It has been closed.');       %Show a warning.
end
    


%% This function sets the color of the waitbar.
function SetColor(fig,obj,val)
if ishandle(fig)                                                            %If the waitbar figure is still open...
    set(obj,'facecolor',val);                                               %Set the patch object to have the specified facecolor.
    drawnow;                                                                %Immediately update the figure.
else                                                                        %Otherwise...
    warning('Cannot update the waitbar figure. It has been closed.');       %Show a warning.
end


%% This function closes the waitbar figure.
function CloseWaitbar(fig)
if ishandle(fig)                                                            %If the waitbar figure is still open...
    close(fig);                                                             %Close the waitbar figure.
    drawnow;                                                                %Immediately update the figure to allow it to close.
end


%% This function returns a logical value indicate whether the waitbar figure has been closed.
function isclosed = WaitbarIsClosed(fig)
isclosed = ~ishandle(fig);                                                  %Check to see if the figure handle is still a valid handle.


%% ***********************************************************************
function count = cprintf(style,format,varargin)
% CPRINTF displays styled formatted text in the Command Window
%
% Syntax:
%    count = cprintf(style,format,...)
%
% Description:
%    CPRINTF processes the specified text using the exact same FORMAT
%    arguments accepted by the built-in SPRINTF and FPRINTF functions.
%
%    CPRINTF then displays the text in the Command Window using the
%    specified STYLE argument. The accepted styles are those used for
%    Matlab's syntax highlighting (see: File / Preferences / Colors / 
%    M-file Syntax Highlighting Colors), and also user-defined colors.
%
%    The possible pre-defined STYLE names are:
%
%       'Text'                 - default: black
%       'Keywords'             - default: blue
%       'Comments'             - default: green
%       'Strings'              - default: purple
%       'UnterminatedStrings'  - default: dark red
%       'SystemCommands'       - default: orange
%       'Errors'               - default: light red
%       'Hyperlinks'           - default: underlined blue
%
%       'Black','Cyan','Magenta','Blue','Green','Red','Yellow','White'
%
%    STYLE beginning with '-' or '_' will be underlined. For example:
%          '-Blue' is underlined blue, like 'Hyperlinks';
%          '_Comments' is underlined green etc.
%
%    STYLE beginning with '*' will be bold (R2011b+ only). For example:
%          '*Blue' is bold blue;
%          '*Comments' is bold green etc.
%    Note: Matlab does not currently support both bold and underline,
%          only one of them can be used in a single cprintf command. But of
%          course bold and underline can be mixed by using separate commands.
%
%    STYLE also accepts a regular Matlab RGB vector, that can be underlined
%    and bolded: -[0,1,1] means underlined cyan, '*[1,0,0]' is bold red.
%
%    STYLE is case-insensitive and accepts unique partial strings just
%    like handle property names.
%
%    CPRINTF by itself, without any input parameters, displays a demo
%
% Example:
%    cprintf;   % displays the demo
%    cprintf('text',   'regular black text');
%    cprintf('hyper',  'followed %s','by');
%    cprintf('key',    '%d colored', 4);
%    cprintf('-comment','& underlined');
%    cprintf('err',    'elements\n');
%    cprintf('cyan',   'cyan');
%    cprintf('_green', 'underlined green');
%    cprintf(-[1,0,1], 'underlined magenta');
%    cprintf([1,0.5,0],'and multi-\nline orange\n');
%    cprintf('*blue',  'and *bold* (R2011b+ only)\n');
%    cprintf('string');  % same as fprintf('string') and cprintf('text','string')
%
% Bugs and suggestions:
%    Please send to Yair Altman (altmany at gmail dot com)
%
% Warning:
%    This code heavily relies on undocumented and unsupported Matlab
%    functionality. It works on Matlab 7+, but use at your own risk!
%
%    A technical description of the implementation can be found at:
%    <a href="http://undocumentedmatlab.com/blog/cprintf/">http://UndocumentedMatlab.com/blog/cprintf/</a>
%
% Limitations:
%    1. In R2011a and earlier, a single space char is inserted at the
%       beginning of each CPRINTF text segment (this is ok in R2011b+).
%
%    2. In R2011a and earlier, consecutive differently-colored multi-line
%       CPRINTFs sometimes display incorrectly on the bottom line.
%       As far as I could tell this is due to a Matlab bug. Examples:
%         >> cprintf('-str','under\nline'); cprintf('err','red\n'); % hidden 'red', unhidden '_'
%         >> cprintf('str','regu\nlar'); cprintf('err','red\n'); % underline red (not purple) 'lar'
%
%    3. Sometimes, non newline ('\n')-terminated segments display unstyled
%       (black) when the command prompt chevron ('>>') regains focus on the
%       continuation of that line (I can't pinpoint when this happens). 
%       To fix this, simply newline-terminate all command-prompt messages.
%
%    4. In R2011b and later, the above errors appear to be fixed. However,
%       the last character of an underlined segment is not underlined for
%       some unknown reason (add an extra space character to make it look better)
%
%    5. In old Matlab versions (e.g., Matlab 7.1 R14), multi-line styles
%       only affect the first line. Single-line styles work as expected.
%       R14 also appends a single space after underlined segments.
%
%    6. Bold style is only supported on R2011b+, and cannot also be underlined.
%
% Change log:
%    2012-08-09: Graceful degradation support for deployed (compiled) and non-desktop applications; minor bug fixes
%    2012-08-06: Fixes for R2012b; added bold style; accept RGB string (non-numeric) style
%    2011-11-27: Fixes for R2011b
%    2011-08-29: Fix by Danilo (FEX comment) for non-default text colors
%    2011-03-04: Performance improvement
%    2010-06-27: Fix for R2010a/b; fixed edge case reported by Sharron; CPRINTF with no args runs the demo
%    2009-09-28: Fixed edge-case problem reported by Swagat K
%    2009-05-28: corrected nargout behavior sugegsted by Andreas Gäb
%    2009-05-13: First version posted on <a href="http://www.mathworks.com/matlabcentral/fileexchange/authors/27420">MathWorks File Exchange</a>
%
% See also:
%    sprintf, fprintf

% License to use and modify this code is granted freely to all interested, as long as the original author is
% referenced and attributed as such. The original author maintains the right to be solely associated with this work.

% Programmed and Copyright by Yair M. Altman: altmany(at)gmail.com
% $Revision: 1.08 $  $Date: 2012/10/17 21:41:09 $

  persistent majorVersion minorVersion
  if isempty(majorVersion)
      %v = version; if str2double(v(1:3)) <= 7.1
      %majorVersion = str2double(regexprep(version,'^(\d+).*','$1'));
      %minorVersion = str2double(regexprep(version,'^\d+\.(\d+).*','$1'));
      %[a,b,c,d,versionIdStrs]=regexp(version,'^(\d+)\.(\d+).*');  %#ok unused
      v = sscanf(version, '%d.', 2);
      majorVersion = v(1); %str2double(versionIdStrs{1}{1});
      minorVersion = v(2); %str2double(versionIdStrs{1}{2});
  end

  % The following is for debug use only:
  %global docElement txt el
  if ~exist('el','var') || isempty(el),  el=handle([]);  end  %#ok mlint short-circuit error ("used before defined")
  if nargin<1, showDemo(majorVersion,minorVersion); return;  end
  if isempty(style),  return;  end
  if all(ishandle(style)) && length(style)~=3
      dumpElement(style);
      return;
  end

  % Process the text string
  if nargin<2, format = style; style='text';  end
  %error(nargchk(2, inf, nargin, 'struct'));
  %str = sprintf(format,varargin{:});

  % In compiled mode
  try useDesktop = usejava('desktop'); catch, useDesktop = false; end
  if isdeployed | ~useDesktop %#ok<OR2> - for Matlab 6 compatibility
      % do not display any formatting - use simple fprintf()
      % See: http://undocumentedmatlab.com/blog/bold-color-text-in-the-command-window/#comment-103035
      % Also see: https://mail.google.com/mail/u/0/?ui=2&shva=1#all/1390a26e7ef4aa4d
      % Also see: https://mail.google.com/mail/u/0/?ui=2&shva=1#all/13a6ed3223333b21
      count1 = fprintf(format,varargin{:});
  else
      % Else (Matlab desktop mode)
      % Get the normalized style name and underlining flag
      [underlineFlag, boldFlag, style] = processStyleInfo(style);

      % Set hyperlinking, if so requested
      if underlineFlag
          format = ['<a href="">' format '</a>'];

          % Matlab 7.1 R14 (possibly a few newer versions as well?)
          % have a bug in rendering consecutive hyperlinks
          % This is fixed by appending a single non-linked space
          if majorVersion < 7 || (majorVersion==7 && minorVersion <= 1)
              format(end+1) = ' ';
          end
      end

      % Set bold, if requested and supported (R2011b+)
      if boldFlag
          if (majorVersion > 7 || minorVersion >= 13)
              format = ['<strong>' format '</strong>'];
          else
              boldFlag = 0;
          end
      end

      % Get the current CW position
      cmdWinDoc = com.mathworks.mde.cmdwin.CmdWinDocument.getInstance;
      lastPos = cmdWinDoc.getLength;

      % If not beginning of line
      bolFlag = 0;  %#ok
      %if docElement.getEndOffset - docElement.getStartOffset > 1
          % Display a hyperlink element in order to force element separation
          % (otherwise adjacent elements on the same line will be merged)
          if majorVersion<7 || (majorVersion==7 && minorVersion<13)
              if ~underlineFlag
                  fprintf('<a href=""> </a>');  %fprintf('<a href=""> </a>\b');
              elseif format(end)~=10  % if no newline at end
                  fprintf(' ');  %fprintf(' \b');
              end
          end
          %drawnow;
          bolFlag = 1;
      %end

      % Get a handle to the Command Window component
      mde = com.mathworks.mde.desk.MLDesktop.getInstance;
      cw = mde.getClient('Command Window');
      xCmdWndView = cw.getComponent(0).getViewport.getComponent(0);

      % Store the CW background color as a special color pref
      % This way, if the CW bg color changes (via File/Preferences), 
      % it will also affect existing rendered strs
      com.mathworks.services.Prefs.setColorPref('CW_BG_Color',xCmdWndView.getBackground);

      % Display the text in the Command Window
      count1 = fprintf(2,format,varargin{:});

      %awtinvoke(cmdWinDoc,'remove',lastPos,1);   % TODO: find out how to remove the extra '_'
      drawnow;  % this is necessary for the following to work properly (refer to Evgeny Pr in FEX comment 16/1/2011)
      docElement = cmdWinDoc.getParagraphElement(lastPos+1);
      if majorVersion<7 || (majorVersion==7 && minorVersion<13)
          if bolFlag && ~underlineFlag
              % Set the leading hyperlink space character ('_') to the bg color, effectively hiding it
              % Note: old Matlab versions have a bug in hyperlinks that need to be accounted for...
              %disp(' '); dumpElement(docElement)
              setElementStyle(docElement,'CW_BG_Color',1+underlineFlag,majorVersion,minorVersion); %+getUrlsFix(docElement));
              %disp(' '); dumpElement(docElement)
              el(end+1) = handle(docElement);  %#ok used in debug only
          end

          % Fix a problem with some hidden hyperlinks becoming unhidden...
          fixHyperlink(docElement);
          %dumpElement(docElement);
      end

      % Get the Document Element(s) corresponding to the latest fprintf operation
      while docElement.getStartOffset < cmdWinDoc.getLength
          % Set the element style according to the current style
          %disp(' '); dumpElement(docElement)
          specialFlag = underlineFlag | boldFlag;
          setElementStyle(docElement,style,specialFlag,majorVersion,minorVersion);
          %disp(' '); dumpElement(docElement)
          docElement2 = cmdWinDoc.getParagraphElement(docElement.getEndOffset+1);
          if isequal(docElement,docElement2),  break;  end
          docElement = docElement2;
          %disp(' '); dumpElement(docElement)
      end

      % Force a Command-Window repaint
      % Note: this is important in case the rendered str was not '\n'-terminated
      xCmdWndView.repaint;

      % The following is for debug use only:
      el(end+1) = handle(docElement);  %#ok used in debug only
      %elementStart  = docElement.getStartOffset;
      %elementLength = docElement.getEndOffset - elementStart;
      %txt = cmdWinDoc.getText(elementStart,elementLength);
  end

  if nargout
      count = count1;
  end
  return;  % debug breakpoint

% Process the requested style information
function [underlineFlag,boldFlag,style] = processStyleInfo(style)
  underlineFlag = 0;
  boldFlag = 0;

  % First, strip out the underline/bold markers
  if ischar(style)
      % Styles containing '-' or '_' should be underlined (using a no-target hyperlink hack)
      %if style(1)=='-'
      underlineIdx = (style=='-') | (style=='_');
      if any(underlineIdx)
          underlineFlag = 1;
          %style = style(2:end);
          style = style(~underlineIdx);
      end

      % Check for bold style (only if not underlined)
      boldIdx = (style=='*');
      if any(boldIdx)
          boldFlag = 1;
          style = style(~boldIdx);
      end
      if underlineFlag && boldFlag
          warning('YMA:cprintf:BoldUnderline','Matlab does not support both bold & underline')
      end

      % Check if the remaining style sting is a numeric vector
      %styleNum = str2num(style); %#ok<ST2NM>  % not good because style='text' is evaled!
      %if ~isempty(styleNum)
      if any(style==' ' | style==',' | style==';')
          style = str2num(style); %#ok<ST2NM>
      end
  end

  % Style = valid matlab RGB vector
  if isnumeric(style) && length(style)==3 && all(style<=1) && all(abs(style)>=0)
      if any(style<0)
          underlineFlag = 1;
          style = abs(style);
      end
      style = getColorStyle(style);

  elseif ~ischar(style)
      error('YMA:cprintf:InvalidStyle','Invalid style - see help section for a list of valid style values')

  % Style name
  else
      % Try case-insensitive partial/full match with the accepted style names
      validStyles = {'Text','Keywords','Comments','Strings','UnterminatedStrings','SystemCommands','Errors', ...
                     'Black','Cyan','Magenta','Blue','Green','Red','Yellow','White', ...
                     'Hyperlinks'};
      matches = find(strncmpi(style,validStyles,length(style)));

      % No match - error
      if isempty(matches)
          error('YMA:cprintf:InvalidStyle','Invalid style - see help section for a list of valid style values')

      % Too many matches (ambiguous) - error
      elseif length(matches) > 1
          error('YMA:cprintf:AmbigStyle','Ambiguous style name - supply extra characters for uniqueness')

      % Regular text
      elseif matches == 1
          style = 'ColorsText';  % fixed by Danilo, 29/8/2011

      % Highlight preference style name
      elseif matches < 8
          style = ['Colors_M_' validStyles{matches}];

      % Color name
      elseif matches < length(validStyles)
          colors = [0,0,0; 0,1,1; 1,0,1; 0,0,1; 0,1,0; 1,0,0; 1,1,0; 1,1,1];
          requestedColor = colors(matches-7,:);
          style = getColorStyle(requestedColor);

      % Hyperlink
      else
          style = 'Colors_HTML_HTMLLinks';  % CWLink
          underlineFlag = 1;
      end
  end

% Convert a Matlab RGB vector into a known style name (e.g., '[255,37,0]')
function styleName = getColorStyle(rgb)
  intColor = int32(rgb*255);
  javaColor = java.awt.Color(intColor(1), intColor(2), intColor(3));
  styleName = sprintf('[%d,%d,%d]',intColor);
  com.mathworks.services.Prefs.setColorPref(styleName,javaColor);

% Fix a bug in some Matlab versions, where the number of URL segments
% is larger than the number of style segments in a doc element
function delta = getUrlsFix(docElement)  %#ok currently unused
  tokens = docElement.getAttribute('SyntaxTokens');
  links  = docElement.getAttribute('LinkStartTokens');
  if length(links) > length(tokens(1))
      delta = length(links) > length(tokens(1));
  else
      delta = 0;
  end

% fprintf(2,str) causes all previous '_'s in the line to become red - fix this
function fixHyperlink(docElement)
  try
      tokens = docElement.getAttribute('SyntaxTokens');
      urls   = docElement.getAttribute('HtmlLink');
      urls   = urls(2);
      links  = docElement.getAttribute('LinkStartTokens');
      offsets = tokens(1);
      styles  = tokens(2);
      doc = docElement.getDocument;

      % Loop over all segments in this docElement
      for idx = 1 : length(offsets)-1
          % If this is a hyperlink with no URL target and starts with ' ' and is collored as an error (red)...
          if strcmp(styles(idx).char,'Colors_M_Errors')
              character = char(doc.getText(offsets(idx)+docElement.getStartOffset,1));
              if strcmp(character,' ')
                  if isempty(urls(idx)) && links(idx)==0
                      % Revert the style color to the CW background color (i.e., hide it!)
                      styles(idx) = java.lang.String('CW_BG_Color');
                  end
              end
          end
      end
  catch
      % never mind...
  end

% Set an element to a particular style (color)
function setElementStyle(docElement,style,specialFlag, majorVersion,minorVersion)
  %global tokens links urls urlTargets  % for debug only
  global oldStyles
  if nargin<3,  specialFlag=0;  end
  % Set the last Element token to the requested style:
  % Colors:
  tokens = docElement.getAttribute('SyntaxTokens');
  try
      styles = tokens(2);
      oldStyles{end+1} = styles.cell;

      % Correct edge case problem
      extraInd = double(majorVersion>7 || (majorVersion==7 && minorVersion>=13));  % =0 for R2011a-, =1 for R2011b+
      %{
      if ~strcmp('CWLink',char(styles(end-hyperlinkFlag))) && ...
          strcmp('CWLink',char(styles(end-hyperlinkFlag-1)))
         extraInd = 0;%1;
      end
      hyperlinkFlag = ~isempty(strmatch('CWLink',tokens(2)));
      hyperlinkFlag = 0 + any(cellfun(@(c)(~isempty(c)&&strcmp(c,'CWLink')),tokens(2).cell));
      %}

      styles(end-extraInd) = java.lang.String('');
      styles(end-extraInd-specialFlag) = java.lang.String(style);  %#ok apparently unused but in reality used by Java
      if extraInd
          styles(end-specialFlag) = java.lang.String(style);
      end

      oldStyles{end} = [oldStyles{end} styles.cell];
  catch
      % never mind for now
  end
  
  % Underlines (hyperlinks):
  %{
  links = docElement.getAttribute('LinkStartTokens');
  if isempty(links)
      %docElement.addAttribute('LinkStartTokens',repmat(int32(-1),length(tokens(2)),1));
  else
      %TODO: remove hyperlink by setting the value to -1
  end
  %}

  % Correct empty URLs to be un-hyperlinkable (only underlined)
  urls = docElement.getAttribute('HtmlLink');
  if ~isempty(urls)
      urlTargets = urls(2);
      for urlIdx = 1 : length(urlTargets)
          try
              if urlTargets(urlIdx).length < 1
                  urlTargets(urlIdx) = [];  % '' => []
              end
          catch
              % never mind...
              a=1;  %#ok used for debug breakpoint...
          end
      end
  end
  
  % Bold: (currently unused because we cannot modify this immutable int32 numeric array)
  %{
  try
      %hasBold = docElement.isDefined('BoldStartTokens');
      bolds = docElement.getAttribute('BoldStartTokens');
      if ~isempty(bolds)
          %docElement.addAttribute('BoldStartTokens',repmat(int32(1),length(bolds),1));
      end
  catch
      % never mind - ignore...
      a=1;  %#ok used for debug breakpoint...
  end
  %}
  
  return;  % debug breakpoint

% Display information about element(s)
function dumpElement(docElements)
  %return;
  numElements = length(docElements);
  cmdWinDoc = docElements(1).getDocument;
  for elementIdx = 1 : numElements
      if numElements > 1,  fprintf('Element #%d:\n',elementIdx);  end
      docElement = docElements(elementIdx);
      if ~isjava(docElement),  docElement = docElement.java;  end
      %docElement.dump(java.lang.System.out,1)
      disp(' ');
      disp(docElement)
      tokens = docElement.getAttribute('SyntaxTokens');
      if isempty(tokens),  continue;  end
      links = docElement.getAttribute('LinkStartTokens');
      urls  = docElement.getAttribute('HtmlLink');
      try bolds = docElement.getAttribute('BoldStartTokens'); catch, bolds = []; end
      txt = {};
      tokenLengths = tokens(1);
      for tokenIdx = 1 : length(tokenLengths)-1
          tokenLength = diff(tokenLengths(tokenIdx+[0,1]));
          if (tokenLength < 0)
              tokenLength = docElement.getEndOffset - docElement.getStartOffset - tokenLengths(tokenIdx);
          end
          txt{tokenIdx} = cmdWinDoc.getText(docElement.getStartOffset+tokenLengths(tokenIdx),tokenLength).char;  %#ok
      end
      lastTokenStartOffset = docElement.getStartOffset + tokenLengths(end);
      txt{end+1} = cmdWinDoc.getText(lastTokenStartOffset, docElement.getEndOffset-lastTokenStartOffset).char;  %#ok
      %cmdWinDoc.uiinspect
      %docElement.uiinspect
      txt = strrep(txt',sprintf('\n'),'\n');
      try
          data = [tokens(2).cell m2c(tokens(1)) m2c(links) m2c(urls(1)) cell(urls(2)) m2c(bolds) txt];
          if elementIdx==1
              disp('    SyntaxTokens(2,1) - LinkStartTokens - HtmlLink(1,2) - BoldStartTokens - txt');
              disp('    ==============================================================================');
          end
      catch
          try
              data = [tokens(2).cell m2c(tokens(1)) m2c(links) txt];
          catch
              disp([tokens(2).cell m2c(tokens(1)) txt]);
              try
                  data = [m2c(links) m2c(urls(1)) cell(urls(2))];
              catch
                  % Mtlab 7.1 only has urls(1)...
                  data = [m2c(links) urls.cell];
              end
          end
      end
      disp(data)
  end

% Utility function to convert matrix => cell
function cells = m2c(data)
  %datasize = size(data);  cells = mat2cell(data,ones(1,datasize(1)),ones(1,datasize(2)));
  cells = num2cell(data);

% Display the help and demo
function showDemo(majorVersion,minorVersion)
  fprintf('cprintf displays formatted text in the Command Window.\n\n');
  fprintf('Syntax: count = cprintf(style,format,...);  click <a href="matlab:help cprintf">here</a> for details.\n\n');
  url = 'http://UndocumentedMatlab.com/blog/cprintf/';
  fprintf(['Technical description: <a href="' url '">' url '</a>\n\n']);
  fprintf('Demo:\n\n');
  boldFlag = majorVersion>7 || (majorVersion==7 && minorVersion>=13);
  s = ['cprintf(''text'',    ''regular black text'');' 10 ...
       'cprintf(''hyper'',   ''followed %s'',''by'');' 10 ...
       'cprintf(''key'',     ''%d colored'',' num2str(4+boldFlag) ');' 10 ...
       'cprintf(''-comment'',''& underlined'');' 10 ...
       'cprintf(''err'',     ''elements:\n'');' 10 ...
       'cprintf(''cyan'',    ''cyan'');' 10 ...
       'cprintf(''_green'',  ''underlined green'');' 10 ...
       'cprintf(-[1,0,1],  ''underlined magenta'');' 10 ...
       'cprintf([1,0.5,0], ''and multi-\nline orange\n'');' 10];
   if boldFlag
       % In R2011b+ the internal bug that causes the need for an extra space
       % is apparently fixed, so we must insert the sparator spaces manually...
       % On the other hand, 2011b enables *bold* format
       s = [s 'cprintf(''*blue'',   ''and *bold* (R2011b+ only)\n'');' 10];
       s = strrep(s, ''')',' '')');
       s = strrep(s, ''',5)',' '',5)');
       s = strrep(s, '\n ','\n');
   end
   disp(s);
   eval(s);


%%%%%%%%%%%%%%%%%%%%%%%%%% TODO %%%%%%%%%%%%%%%%%%%%%%%%%
% - Fix: Remove leading space char (hidden underline '_')
% - Fix: Find workaround for multi-line quirks/limitations
% - Fix: Non-\n-terminated segments are displayed as black
% - Fix: Check whether the hyperlink fix for 7.1 is also needed on 7.2 etc.
% - Enh: Add font support


