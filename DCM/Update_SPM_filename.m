% update_SPM_paths
% Barbara Grosjean, 2025

% Set path to data folder
your_absolute_path_to_the_data_folder = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2';

% List the directories in the SPM_data folder
spm_data_folder = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/SPM_data';
dir_info = dir(spm_data_folder);
list_dir = {};

for i = 1:length(dir_info)
    if startsWith(dir_info(i).name, 'sub')
        list_dir{end+1} = dir_info(i).name; 
    end
end

% Loop over subject directories
for i = 1:length(list_dir)
    subj_dir = list_dir{i};
    spm_path = fullfile(spm_data_folder, subj_dir, 'SPM.mat');
 
    try 
        % Load SPM.mat
        SPMmat = load(spm_path);
        SPM = SPMmat.SPM;
    
        % Update paths in SPM.xY.P
        for j = 1:length(SPM.xY.P)
            for p = 1:size(SPM.xY.P, 1)
                new_path = strrep(SPM.xY.P(p, :), SPM.xY.P(p, 1:62),  your_absolute_path_to_the_data_folder);
                SPM.xY.P(p, :) = new_path;
            end 
        end
        
        % Update paths in SPM.swd
        new_path = strrep(SPM.swd, SPM.swd(1:62),  your_absolute_path_to_the_data_folder);
        SPM.swd = new_path;

        % Update paths in SPM.xY.VY.fname
        for j = 1:length(SPM.xY.VY)
            fname_old = SPM.xY.VY(j).fname;
            new_path = strrep(SPM.xY.VY(j).fname, fname_old(1:62),  your_absolute_path_to_the_data_folder );
            SPM.xY.VY(j).fname = new_path;
     
        end

        % Update paths in SPM.xM.VM.fname
        fname_old = SPM.xM.VM.fname;
        new_path = strrep(SPM.xM.VM.fname, fname_old(1:36),  '/Users/barbaragrosjean/Documents/MATLAB/spm'); 
        SPM.xM.VM.fname = new_path;     
    
        % Save updated SPM to new file
        save(fullfile(your_absolute_path_to_the_data_folder, subj_dir, 'SPM.mat'), 'SPM');

    catch ME
        warning('Failed for subject %s: %s', subj_dir, ME.message);
        continue
    end
end
