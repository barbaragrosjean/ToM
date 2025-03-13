clear; clc;

dataPath = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2/';
% subjects = {'sub-01', 'sub-02', 'sub-03', 'sub-05', 'sub-07', 'sub-08', 'sub-09', ...
%             'sub-10', 'sub-11', 'sub-14', 'sub-15', 'sub-17', 'sub-18', 'sub-19', ...
%             'sub-21', 'sub-22', 'sub-23', 'sub-25', 'sub-26', 'sub-27', 'sub-28', ...
%             'sub-29', 'sub-30', 'sub-31', 'sub-32', 'sub-34', 'sub-36', 'sub-38', ...
%             'sub-39', 'sub-40', 'sub-42', 'sub-43', 'sub-46', 'sub-47', 'sub-48', 'sub-49'};
subjects = {'sub-01'};
            %'sub-11', 'sub-14', 'sub-15', 'sub-17', 'sub-18', 'sub-19', ...
            %'sub-21', 'sub-22', 'sub-23', 'sub-25', 'sub-26', 'sub-27', 'sub-28', ...
            %'sub-29', 'sub-30', 'sub-31', 'sub-32', 'sub-34', 'sub-36', 'sub-38', ...
            %'sub-39', 'sub-40', 'sub-42', 'sub-43', 'sub-46', 'sub-47', 'sub-48', 'sub-49'};

addpath('/Users/barbaragrosjean/Documents/MATLAB/spm12')
numModels = 10; % Number of models
spm('defaults', 'FMRI'); % Initialize SPM
numWorkers = 4; % Adjust based on CPU

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
            fprintf('Successfully re-estimated: %s\n', dcmFile);
        catch ME
            fprintf('Error estimating %s: %s\n', dcmFile, ME.message);
        end
    end
end

% Close parallel pool
delete(gcp);



