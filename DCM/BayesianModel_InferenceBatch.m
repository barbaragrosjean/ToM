clear; clc;

addpath('/Users/barbaragrosjean/Documents/MATLAB/spm12')
spm('Defaults','fMRI');

% Define paths
dataPath = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2/';
groupOutputPath = fullfile(dataPath, 'GroupDCM_Test'); % Output directory

% List of subjects 
subjects = {'sub-01', 'sub-02'} ;

%, 'sub-03', 'sub-05', 'sub-07', 'sub-08', 'sub-09', ...
%            'sub-11',  'sub-15', 'sub-17', 'sub-18', 'sub-19', ...
%            'sub-21', 'sub-22', 'sub-23', 'sub-25', 'sub-26', 'sub-27', 'sub-28', ...
%            'sub-29', 'sub-30', 'sub-31', 'sub-32', 'sub-34', 'sub-36',  ...
%            'sub-39', 'sub-42', 'sub-43', 'sub-46', 'sub-48', 'sub-49'};

%skip 'sub-14',
% also sub-5, 'sub-10'
%skip 4 ROIS 38, 40, 47
% sub-29 problematic for session 2, different events/onsets etc.

% Define number of models
numModels = 10;
modelNames = arrayfun(@(x) sprintf('model%d.mat', x), 1:numModels, 'UniformOutput', false);

% Initialize batch structure
matlabbatch = {};

% Set output directory for BMS results
matlabbatch{1}.spm.dcm.bms.inference.dir = {groupOutputPath};

% Loop through subjects
sess_idx = 0; % Initialize session index counter
GCM = {}; % Initialize empty cell array
for sub_idx = 1:length(subjects)
    subID = subjects{sub_idx}; % Current subject
    subPath = fullfile(dataPath, subID, 'func', 'ResultsModel1FB');

    % Check available sessions (session 1 and 2)
    sessions = {};
    for sess = 1:2
        % Check if the first model file exists for the session
        testFile = fullfile(subPath, sprintf('DCM_%s_sess%d_model1.mat', subID, sess));
        if isfile(testFile)
            sessions{end+1} = sess; % Add session to list if it exists
        end
    end

    % If no valid sessions, skip subject
    if isempty(sessions)
        fprintf('Skipping %s (no valid sessions found)\n', subID);
        continue;
    end

    % Process each available session
    for sess_idx_sub = 1:length(sessions)
        sess = sessions{sess_idx_sub};
        if strcmp(subID, 'sub-29') && sess == 2
            fprintf('⚠️ Skipping sub-29, session 2 due to event timing mismatch.\n');
            continue;
        end

        sess_idx = sess_idx + 1; % Increase session index for batch structure

        % Collect all model files for this subject and session
        dcmFiles = {};
        for model_idx = 1:numModels
            dcmFile = fullfile(subPath, sprintf('DCM_%s_sess%d_model%d.mat', subID, sess, model_idx));
            if isfile(dcmFile)
                dcmFiles{end+1} = dcmFile; % Add model file if it exists
            else
                fprintf('Warning: Missing %s\n', dcmFile);
            end
        end

        % If no valid models, skip this session
        if isempty(dcmFiles)
            fprintf('Skipping %s session %d (no valid models found)\n', subID, sess);
            continue;
        end

        % Add session to batch structure
        matlabbatch{1}.spm.dcm.bms.inference.sess_dcm{sess_idx}.dcmmat = dcmFiles';
    end
end

% BMS settings
matlabbatch{1}.spm.dcm.bms.inference.method = 'RFX'; % Random Effects Model Selection
matlabbatch{1}.spm.dcm.bms.inference.model_sp = {''}; % No predefined model space
matlabbatch{1}.spm.dcm.bms.inference.load_f = {''}; % No predefined file loading
matlabbatch{1}.spm.dcm.bms.inference.family_level.family_file = {''}; % No predefined family-level analysis
matlabbatch{1}.spm.dcm.bms.inference.bma.bma_no = 0; % No Bayesian Model Averaging
matlabbatch{1}.spm.dcm.bms.inference.verify_id = 1; % Verify individual models
matlabbatch{1}.spm.dcm.bms.inference.bma.bma_yes = 1; % Enable Bayesian Model Averaging


% Save the batch for later use
save(fullfile(groupOutputPath, 'BMS_Batch.mat'), 'matlabbatch');

% Run the batch
spm('defaults', 'FMRI');
spm_jobman('initcfg');
spm_jobman('run', matlabbatch);


GCM = {}; % Initialize empty cell array
sess_idx = 0;

% Loop through subjects again
for sub_idx = 1:length(subjects)
    subID = subjects{sub_idx}; 
    subPath = fullfile(dataPath, subID, 'func', 'ResultsModel1FB');

    sessions = {};
    for sess = 1:2
        testFile = fullfile(subPath, sprintf('DCM_%s_sess%d_model1.mat', subID, sess));
        if isfile(testFile)
            sessions{end+1} = sess; 
        end
    end

    if isempty(sessions)
        fprintf('Skipping %s (no valid sessions found)\n', subID);
        continue;
    end

    for sess_idx_sub = 1:length(sessions)
        sess = sessions{sess_idx_sub};

        % Skip problematic subject session
        if strcmp(subID, 'sub-29') && sess == 2
            fprintf('⚠️ Skipping sub-29, session 2 due to event timing mismatch.\n');
            continue;
        end

        sess_idx = sess_idx + 1; 
        dcmFiles = {};
        for model_idx = 1:numModels
            dcmFile = fullfile(subPath, sprintf('DCM_%s_sess%d_model%d.mat', subID, sess, model_idx));
            if isfile(dcmFile)
                dcmFiles{end+1} = dcmFile; 
            else
                fprintf('Warning: Missing %s\n', dcmFile);
            end
        end

        if isempty(dcmFiles)
            fprintf('Skipping %s session %d (no valid models found)\n', subID, sess);
            continue;
        end

        % Store the subject's model files
        GCM{sess_idx} = dcmFiles';
    end
end

% Assign the reconstructed GCM to BMS
BMS.DCM.rfx.GCM = GCM;
save(fullfile(groupOutputPath, 'BMS_fixed.mat'), '-struct', 'BMS');

disp('✅ GCM successfully reconstructed!');


% % Define the path to the BMS results file
% dataPath = '/Users/sysadmin/Documents/GorgolewskiDataSet/ds000109-download/';
% groupOutputPath = fullfile(dataPath, 'GroupDCM_Test'); % Output directory
% bmsFile = fullfile(groupOutputPath, 'BMS.mat');
% 
% % Load Bayesian Model Selection results
% if exist(bmsFile, 'file')
%     BMS = load(bmsFile);
%     fprintf('✅ Successfully loaded BMS.mat\n');
% else
%     error('❌ BMS.mat file not found! Ensure that BMS has been run.');
% end
% 
% % Ensure the RFX field exists before computing BMA
% if isfield(BMS.DCM, 'rfx')
%     fprintf('🔄 Computing Bayesian Model Averaging...\n');
%     bmaResults = spm_dcm_bma(BMS.DCM.rfx); % Compute BMA
% 
%     % Save the new BMA results back into the BMS structure
%     BMS.DCM.bma = bmaResults;
%     save(bmsFile, '-struct', 'BMS');
% 
%     fprintf('✅ BMA successfully computed and saved to BMS.mat!\n');
% else
%     error('❌ RFX model selection results not found in BMS.DCM! Cannot compute BMA.');
% end


