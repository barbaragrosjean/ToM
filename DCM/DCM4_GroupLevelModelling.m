%% STEP 4:
%% Group Level modelling

% Take all participants’ estimated parameters to the group level and fit a second level model, 
% using an approach called Parametric Empirical Bayes (PEB). This captures the commonalities and differences between participants, 
% and returns a score for the quality of the entire group-level model (free energy).
clear matlabbatch;
clear; clc;

%% Load PEB prerequisites

% Load design matrix

Spmpath = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2/sub-01/func/ResultsModel1FB/SPM.mat';
groupPath = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2/group';
sess = 1;

%SPM = load(Spmpath);
%X        = SPM.SPM.xX.X;
X  = [1; 1];

%X_labels = SPM.SPM.xX.name;
X_labels = {'Overall/Average effect'};

% Load GCM
gcmfile = load(fullfile(groupPath, sprintf('GCM_full_sess%d.mat', sess)));
GCM=gcmfile.GCM;

% PEB settings
M = struct();
M.Q      = 'all';
M.X      = X;
M.Xnames = X_labels;
M.maxit  = 256;

% set up SPM
addpath('/Users/barbaragrosjean/Documents/MATLAB/spm12')
spm('defaults', 'FMRI');
spm_jobman('initcfg');

%% Build PEB (using B parameters) - for each models 
% 'D': driving inputs in DCM
% 'A': intrinsic connectivity
% 'B': modulation effect 
% 'C': inputs

% models 1 sess 1
GCM_1=gcmfile.GCM(:, 1);
[PEB_B_1,RCM_B_1] = spm_dcm_peb(GCM_1,M,{'B'});
%save(fullfile(groupPath, sprintf('PEB_B_sess%d.mat',sess )),'PEB_B_1','RCM_B_1');

% model 2 sess 1 
GCM_2=gcmfile.GCM(:, 2);
[PEB_B_2,RCM_B_2] = spm_dcm_peb(GCM_1,M,{'B'});
%save(fullfile(groupPath, sprintf('PEB_B_sess%d.mat',sess )),'PEB_B_2','RCM_B_2');

%to examine 
%spm_dcm_peb_review(PEB_B_2, GCM_2)



%% Automatic search
BMA_B = spm_dcm_peb_bmc(PEB_B_1); 
%save(fullfile(groupPath, sprintf('BMA_B_model1_sess1.mat',sess )),'BMA_B');   

%% Hypothesis-based analysis (B)

% Run model comparison
[BMA,BMR] = spm_dcm_peb_bmc(PEB_B_1, PEB_B_2); % to debug 
% using family spm_dcm_peb_bcm_fam

% Show connections in winning model 4
%BMA.Kname(BMA.K(4,:)==1)
%save(fullfile(groupPath,  sprintf('BMA_B_sess%d_tot.mat', sess)),'BMA','BMR');

%% Family analysis

% Load the result from the comparison of 28 reduced models
%load(fullfile(groupPath,  sprintf('BMA_B_sess%d_tot.mat', sess)));

% Compare families
[BMA_fam_task,fam_task] = spm_dcm_peb_bmc_fam(BMA, BMR, GCM.task_family, 'ALL');

[BMA_fam_b_dv,fam_b_dv] = spm_dcm_peb_bmc_fam(BMA, BMR, templates.b_dv_family, 'NONE');

[BMA_fam_b_lr,fam_b_lr] = spm_dcm_peb_bmc_fam(BMA, BMR, templates.b_lr_family, 'NONE');

%save(fullfile(groupPath,  sprintf('BMA_fam_task.mat', sess) ,'BMA_fam_task','fam_task');
%save('../analyses/BMA_fam_b_dv.mat','BMA_fam_b_dv','fam_b_dv');
%save('../analyses/BMA_fam_b_lr.mat','BMA_fam_b_lr','fam_b_lr');
%% LOO
[qE,qC,Q] = spm_dcm_loo(GCM,M,{'B(4,4,3)'});

%save('../analyses/LOO_rdF_words.mat','qE','qC','Q');
%% Correlate rdF
B = cellfun(@(x)x.Ep.B(4,4,3),GCM(:,1));
LI = X(:,2);
figure;scatter(LI,B);
lsline;
[R,P] = corrcoef(LI,B);
%% Build PEB (A)
[PEB_A,RCM_A] = spm_dcm_peb(GCM(:,1),M,{'A'});
save('../analyses/PEB_A.mat','PEB_A','RCM_A');  
%% Search-based analysis (A)
load('../analyses/PEB_A.mat');
BMA_A = spm_dcm_peb_bmc(PEB_A);
save('../analyses/BMA_search_A.mat','BMA_A');
spm_dcm_peb_review(BMA_A,GCM);




%%
%%
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
nbmodels = 10;

for sess =1:numSessions
    gcmfile = fullfile(groupPath, sprintf('GCM_full_sess%d.mat', sess)); % sub x model

    matlabbatch{1}.spm.dcm.peb.specify.name = 'EPY_nonlinear_timepoint';
    matlabbatch{1}.spm.dcm.peb.specify.model_space_mat = gcmfile;
    matlabbatch{1}.spm.dcm.peb.specify.dcm.index = {1}; %???
       
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



