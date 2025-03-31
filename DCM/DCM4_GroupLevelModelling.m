%% STEP 3:
%% Group Level modelling

% Take all participants’ estimated parameters to the group level and fit a second level model, 
% using an approach called Parametric Empirical Bayes (PEB). This captures the commonalities and differences between participants, 
% and returns a score for the quality of the entire group-level model (free energy).
clear matlabbatch;
clear; clc;

path_to_save = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2/sub-01/func/ResultsModel1FB/DCM_templateR.mat';
dataPath = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2';
groupPath = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2/group';

% SPM 
addpath('/Users/barbaragrosjean/Documents/MATLAB/spm12')
spm('Defaults','fMRI');
spm_jobman('initcfg'); 

% Subj 
cd(dataPath);
allSubs = dir('sub-*');

subPaths = cellfun(@(x) fullfile(dataPath, x, 'func', 'ResultsModel1FB'), {allSubs.name}, 'UniformOutput', false);

% sess
numSessions = 2;

%models 
nbmodels = 3;

for sess =1:numSessions
    gcmfile = fullfile(groupPath, sprintf('GCM_full_sess%d.mat', sess)); % sub x model

    for m = 1:nbmodels 
     
        matlabbatch{1}.spm.dcm.peb.specify.name = 'EPY_nonlinear_timepoint';
        matlabbatch{1}.spm.dcm.peb.specify.model_space_mat = gcmfile;
        %matlabbatch{1}.spm.dcm.peb.specify.dcm.index = 1:length(gcmfile); %???
           
        % Each row corresponds to a subject, and each column is a covariate (e.g., timepoint, age, group).
        matlabbatch{1}.spm.dcm.peb.specify.cov.design_mtx.cov_design = [1 ;2];
        matlabbatch{1}.spm.dcm.peb.specify.cov.design_mtx.name = {'Timepoint'};

        % 'D': driving inputs in DCM
        % 'A': intrinsic connectivity
        % 'B': modulation effect 
        % 'C': inputs
        matlabbatch{1}.spm.dcm.peb.specify.fields.custom = {'A', 'B', 'C', 'D'};

        %'All' means PEB will analyze all parameters in the specified fields.
        matlabbatch{1}.spm.dcm.peb.specify.priors_between.components = 'All';

        %  scales the prior variance on between-subject effects.
        matlabbatch{1}.spm.dcm.peb.specify.priors_between.ratio = 16;

        % prior expectation (mean) to 0, meaning no a priori assumption.
        matlabbatch{1}.spm.dcm.peb.specify.priors_between.expectation = 0;
        matlabbatch{1}.spm.dcm.peb.specify.priors_between.var = 0.0625;

        % assumes equal weight between subjects
        matlabbatch{1}.spm.dcm.peb.specify.priors_glm.group_ratio = 1;
        matlabbatch{1}.spm.dcm.peb.specify.estimation.maxit = 64;
        matlabbatch{1}.spm.dcm.peb.specify.show_review = 0;
        spm_jobman('run', matlabbatch);

        % spm_dcm_peb_review(PEB);
        clear matlabbatch;
    
    end 
end 


