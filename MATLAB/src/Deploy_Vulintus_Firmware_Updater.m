function Deploy_Vulintus_Firmware_Updater

%
%Deploy_Vulintus_Firmware_Updater.m - Vulintus, Inc.
%
%   DEPLOY_VULINTUS_FIRMWARE_UPDATER collates all of the *.m file 
%   dependencies for the Vulintus Firmware Updater program into a single 
%   *.m file.
%
%   UPDATE LOG:
%   2024-06-11- Drew Sloan - Function first created, adapted from
%                             Deploy_Fixed_Reinforcement.m
%


start_script = 'Vulintus_Firmware_Updater_Startup.m';                       %Set the expected name of the initialization script.
collated_filename = 'Vulintus_Firmware_Updater.m';                          %Set the name for the collated script.

[collated_file, ~] = Vulintus_Collate_Functions(start_script,...
    collated_filename,'DepFunFolder','on');                                 %Call the generalized function-collating script.

[path, ~, ~] = fileparts(collated_file);                                    %Grab the parts of the collated file.
path(strfind(path,'\src'):end) = [];                                        %Find the parent directory of the "src" folder.
copyfile(collated_file,path,'f');                                           %Copy the collated file to the parent directory.
winopen(fullfile(path,collated_filename));                                  %Open the newly collated *.m file.