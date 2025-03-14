clear; clc;

% STEP 1 - Extract VOIs
% Run with Leyla masks, subj 1 bc preproc and reg to MNI

% Download rois
roiPath = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ROIs_mask';
cd(roiPath)
roiNames = []; %{'CerebellumLobVII', 'IFGOpL', 'IFGOpR', 'MFGL_dlPFCmPFC', 'MFGR_dlPFCmPFC', 'PrecuneusL', 'PrecuneusR', 'STGL', 'STGR', 'TemporalPoleL','TemporalPoleR'};
rois = dir('*.nii');
roi = [];

for r = 1:length(rois)
    roi{r} = fullfile(roiPath,rois(r).name);
   [pathstr,name,ext] = fileparts(fullfile(roiPath,rois(r).name));
    roiNames{r} = name;
end

% Download data
dataPath = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2';
subPaths = [];
cd(dataPath)
allSubs = dir('sub-*');
%allSubs(32) = [];

% SPM.map files path
for s = 1:length(allSubs)
        subPaths{s} = fullfile(dataPath, allSubs(s).name);
end


%% Start SPM 
% Add spm path
addpath('/Users/barbaragrosjean/Documents/MATLAB/spm12')
spm('Defaults','fMRI');
spm_jobman('initcfg');

% Initialize batch counter
batchCounter = 0;

%-----------------------------------------------------------------------
% Job saved on 13-Jan-2025 12:51:52 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
for s = 1:length(subPaths)
    thisPath= subPaths{s};
    cd(thisPath)
    load SPM.mat 
      
    lSess = length(SPM.Sess);
    %clear SPM

    for j = 1:lSess % session 
        for i = 1:length(rois) % ROIs
            batchCounter = batchCounter + 1; % Increment batch counter
            matlabbatch{batchCounter}.spm.util.voi.spmmat = {fullfile(thisPath, 'SPM.mat')};
            matlabbatch{batchCounter}.spm.util.voi.adjust = 5; % leyla used 4
            matlabbatch{batchCounter}.spm.util.voi.session = j;
            matlabbatch{batchCounter}.spm.util.voi.name = [roiNames{i}, '_', num2str(j)];
            matlabbatch{batchCounter}.spm.util.voi.roi{1}.mask.image = roi(i);
            matlabbatch{batchCounter}.spm.util.voi.roi{1}.mask.threshold = 0.5 ; % 0.5 leyla
            matlabbatch{batchCounter}.spm.util.voi.expression = 'i1';
        end
    end
end

%% Save batch and run
save('matlabbatch');
spm_jobman('run',matlabbatch);
