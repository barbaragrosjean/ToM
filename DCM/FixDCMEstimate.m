% clear; clc;
% dataPath = '/Users/sysadmin/Documents/GorgolewskiDataSet/ds000109-download/';
% subjects = {'sub-01', 'sub-02', 'sub-03', 'sub-05', 'sub-07', 'sub-08', 'sub-09', ...
%             'sub-10', 'sub-11', 'sub-14', 'sub-15', 'sub-17', 'sub-18', 'sub-19', ...
%             'sub-21', 'sub-22', 'sub-23', 'sub-25', 'sub-26', 'sub-27', 'sub-28', ...
%             'sub-29', 'sub-30', 'sub-31', 'sub-32', 'sub-34', 'sub-36', 'sub-38', ...
%             'sub-39', 'sub-40', 'sub-42', 'sub-43', 'sub-46', 'sub-47', 'sub-48', 'sub-49'};
% 
% numModels = 10; % Number of models
% incompleteFiles = {}; % Store problematic files
% 
% for sub_idx = 1:length(subjects)
%     subID = subjects{sub_idx};
%     subPath = fullfile(dataPath, subID, 'func', 'ResultsModel1FB');
% 
%     for sess = 1:2
%         for model_idx = 1:numModels
%             dcmFile = fullfile(subPath, sprintf('DCM_%s_sess%d_model%d.mat', subID, sess, model_idx));
% 
%             if isfile(dcmFile)
%                 % Check if the DCM file contains the field 'F'
%                 try
%                     load(dcmFile, 'DCM');
%                     if ~isfield(DCM, 'F')
%                         incompleteFiles{end+1} = dcmFile;
%                         fprintf('Warning: %s is missing "F" field (not estimated properly)\n', dcmFile);
%                     end
%                 catch
%                     incompleteFiles{end+1} = dcmFile;
%                     fprintf('Error loading %s (corrupted or missing data)\n', dcmFile);
%                 end
%             end
%         end
%     end
% end
% 
% % Display missing files
% if isempty(incompleteFiles)
%     disp('✅ All DCM files are properly estimated!');
% else
%     disp('⚠️ The following DCM files are missing the "F" field and need to be re-estimated:');
%     disp(incompleteFiles');
% end
% parpool(4); % Adjust number based on CPU cores
% parfor sub_idx = 1:length(subjects)
% % for i = 1:length(incompleteFiles)
%     fprintf('Re-estimating %s...\n', incompleteFiles{i});
%     load(incompleteFiles{i}, 'DCM');
%     DCM = spm_dcm_estimate(DCM);
%     save(incompleteFiles{i}, 'DCM');
% end
% delete(gcp);

% clear; clc;
% dataPath = '/Users/sysadmin/Documents/GorgolewskiDataSet/ds000109-download/';
% subjects = {'sub-01', 'sub-02', 'sub-03', 'sub-05', 'sub-07', 'sub-08', 'sub-09', ...
%             'sub-10', 'sub-11', 'sub-14', 'sub-15', 'sub-17', 'sub-18', 'sub-19', ...
%             'sub-21', 'sub-22', 'sub-23', 'sub-25', 'sub-26', 'sub-27', 'sub-28', ...
%             'sub-29', 'sub-30', 'sub-31', 'sub-32', 'sub-34', 'sub-36', 'sub-38', ...
%             'sub-39', 'sub-40', 'sub-42', 'sub-43', 'sub-46', 'sub-47', 'sub-48', 'sub-49'};
% 
% numModels = 10; % Number of models
% spm('defaults', 'FMRI'); % Initialize SPM
% numWorkers = 6; % Adjust based on CPU
% 
% % Start parallel pool
% parpool(numWorkers);
% 
% % Collect all DCM file paths before running parfor
% allDCMFiles = {}; % Store valid DCM file paths
% 
% for sub_idx = 1:length(subjects)
%     subID = subjects{sub_idx};
%     subPath = fullfile(dataPath, subID, 'func', 'ResultsModel1FB');
% 
%     for sess = 1:2
%         for model_idx = 1:numModels
%             dcmFile = fullfile(subPath, sprintf('DCM_%s_sess%d_model%d.mat', subID, sess, model_idx));
%             if isfile(dcmFile)
%                 allDCMFiles{end+1} = dcmFile; % Store file path
%             end
%         end
%     end
% end
% 
% % Create a temp folder for parallel saving
% tempDir = fullfile(dataPath, 'TempDCM');
% if ~exist(tempDir, 'dir')
%     mkdir(tempDir);
% end
% 
% % Re-estimate all DCM models in parallel
% parfor file_idx = 1:length(allDCMFiles)
%     dcmFile = allDCMFiles{file_idx}; % Get file path
%     tempFile = fullfile(tempDir, sprintf('temp_%d.mat', file_idx)); % Temporary save location
% 
%     try
%         fprintf('Re-estimating: %s\n', dcmFile);
%         DCM = load(dcmFile, 'DCM'); % Load DCM struct safely
%         DCM.DCM = spm_dcm_estimate(DCM.DCM); % Estimate model
%         save(tempFile, '-struct', 'DCM'); % Save to temp file
%         fprintf('✅ Successfully re-estimated: %s\n', dcmFile);
%     catch ME
%         fprintf('⚠️ Error estimating %s: %s\n', dcmFile, ME.message);
%     end
% end
% 
% % Move estimated models back to original locations (outside parfor)
% for file_idx = 1:length(allDCMFiles)
%     tempFile = fullfile(tempDir, sprintf('temp_%d.mat', file_idx));
%     if isfile(tempFile)
%         movefile(tempFile, allDCMFiles{file_idx});
%     end
% end
% 
% % Remove temp directory
% rmdir(tempDir, 's');
% 
% % Close parallel pool
% delete(gcp);


clear; clc;
dataPath = '/Users/sysadmin/Documents/GorgolewskiDataSet/ds000109-download/';
% subjects = {'sub-01', 'sub-02', 'sub-03', 'sub-05', 'sub-07', 'sub-08', 'sub-09', ...
%             'sub-10', 'sub-11', 'sub-14', 'sub-15', 'sub-17', 'sub-18', 'sub-19', ...
%             'sub-21', 'sub-22', 'sub-23', 'sub-25', 'sub-26', 'sub-27', 'sub-28', ...
%             'sub-29', 'sub-30', 'sub-31', 'sub-32', 'sub-34', 'sub-36', 'sub-38', ...
%             'sub-39', 'sub-40', 'sub-42', 'sub-43', 'sub-46', 'sub-47', 'sub-48', 'sub-49'};
subjects = {
            'sub-11', 'sub-14', 'sub-15', 'sub-17', 'sub-18', 'sub-19', ...
            'sub-21', 'sub-22', 'sub-23', 'sub-25', 'sub-26', 'sub-27', 'sub-28', ...
            'sub-29', 'sub-30', 'sub-31', 'sub-32', 'sub-34', 'sub-36', 'sub-38', ...
            'sub-39', 'sub-40', 'sub-42', 'sub-43', 'sub-46', 'sub-47', 'sub-48', 'sub-49'};

numModels = 10; % Number of models
spm('defaults', 'FMRI'); % Initialize SPM
numWorkers = 6; % Adjust based on CPU

% Collect all DCM file paths before running parallel processing
allDCMFiles = {}; 

for sub_idx = 1:length(subjects)
    subID = subjects{sub_idx};
    subPath = fullfile(dataPath, subID, 'func', 'ResultsModel1FB');

    for sess = 1:2
        for model_idx = 1:numModels
            dcmFile = fullfile(subPath, sprintf('DCM_DCM_%s_sess%d_model%d.mat', subID, sess, model_idx));
            if isfile(dcmFile)
                allDCMFiles{end+1} = dcmFile; % Store file path
            end
        end
    end
end

% Start parallel pool
parpool(numWorkers);

% Use SPMD to estimate DCM models in parallel safely
spmd
    % Divide files among workers
    workerIdx = labindex;
    numWorkers = numlabs;
    for file_idx = workerIdx:numWorkers:length(allDCMFiles)
        dcmFile = allDCMFiles{file_idx}; % Get file path

        try
            fprintf('Re-estimating: %s\n', dcmFile);
            DCM = load(dcmFile, 'DCM'); % Load DCM struct
            DCM.DCM = spm_dcm_estimate(DCM.DCM); % Estimate model
            save(dcmFile(4:end), '-struct', 'DCM'); % Save estimated model
            fprintf('✅ Successfully re-estimated: %s\n', dcmFile);
        catch ME
            fprintf('⚠️ Error estimating %s: %s\n', dcmFile, ME.message);
        end
    end
end

% Close parallel pool
delete(gcp);



