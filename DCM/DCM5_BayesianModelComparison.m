%% STEP 4 :
%% Bayesian model comparison

% Compare the free energy of different candidate group-level (PEB) models, 
% which differ in terms of which connectivity parameters or covariates are included.

clear; clc;
spm('defaults', 'FMRI');
spm_jobman('initcfg');

path_to_save = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2/sub-01/func/ResultsModel1FB/DCM_templateR.mat';
dataPath = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2';
groupPath = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2/group';

% Subjs 
cd(dataPath);
allSubs = dir('sub-*');

subPaths = cellfun(@(x) fullfile(dataPath, x, 'func', 'ResultsModel1FB'), {allSubs.name}, 'UniformOutput', false);
numSessions = 2;

% === 2. Specify Bayesian Model Selection (BMS) ===
matlabbatch{1}.spm.dcm.bms.inference.dcmmat = {fullfile(groupPath, 'GCM_BMC.mat')}; % Input GCM file
matlabbatch{1}.spm.dcm.bms.inference.model_sp = {''}; % Assume models are fully specified
matlabbatch{1}.spm.dcm.bms.inference.method = 'RFX'; % Choose 'RFX' (Random Effects) or 'FFX' (Fixed Effects)
matlabbatch{1}.spm.dcm.bms.inference.family_level.infer = false; % No family inference
matlabbatch{1}.spm.dcm.bms.inference.verify_id = false; % No verification required_
spm_jobman('run', matlabbatch);