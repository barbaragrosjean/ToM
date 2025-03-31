
%% STEP 2:
%% DCM Model estimate

%The software will find a setting of the parameters that makes the model as good as possible. 
% Here, the measure of goodness is a statistic called the free energy or evidence lower bound (ELBO), 
% which quantifies the trade-off between the model’s accuracy and complexity.

clear; clc;

% ==== SETTINGS ====
% VOIs 
roiNames = {'PrecuneusL', 'STGL', 'IFGOpL', 'MFGL_dlPFCmPFC'};
numROIs = length(roiNames); 

% Paths
dataPath = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2';
 
cd(dataPath);
allSubs = dir('sub-*');
subPaths = cellfun(@(x) fullfile(dataPath, x, 'func', 'ResultsModel1FB'), {allSubs.name}, 'UniformOutput', false);

% SPM 
addpath('/Users/barbaragrosjean/Documents/MATLAB/spm12')
spm('Defaults','fMRI');
spm_jobman('initcfg'); 

% Storage 
BatchStorage = cell(length(subPaths), 1);

% Models
nbmodels = 10;
 
for s= 2 %:length(subPaths)  
    % Set subj path
    thisPath = subPaths{s};
    sub = allSubs(s).name;
    cd(thisPath);
    disp('Running subj : ')
    disp(sub)

    % Get spm.mat
    spmData = load(fullfile(thisPath, 'SPM.mat'));
    SPM = spmData.SPM; 
    TR = SPM.xY.RT; 
    numSessions = length(SPM.Sess); 

    for sess = 1:numSessions 
        disp('running session n°')
        disp(sess)
        for m = 1:nbmodels % test several models of interaction
            disp('running model n°')
            disp(m)

            % DCM file 
            dcmMatFile = fullfile(thisPath, sprintf('DCM_%s_sess%d_model%d.mat', sub, sess, m));
           
            matlabbatch = {};

            % === 1. Specify Group ===
            matlabbatch{1}.spm.dcm.spec.fmri.group.template.fulldcm = cellstr(dcmMatFile);
            matlabbatch{1}.spm.dcm.spec.fmri.group.output.dir = {thisPath};
            matlabbatch{1}.spm.dcm.spec.fmri.group.output.name = sprintf('DCM_%s_sess%d_model%d.mat', sub, sess, m);
            matlabbatch{1}.spm.dcm.spec.fmri.group.template.altdcm = ''; 
            matlabbatch{1}.spm.dcm.spec.fmri.group.data.spmmats = {fullfile(thisPath, 'SPM.mat')}; 
            matlabbatch{1}.spm.dcm.spec.fmri.group.data.session = sess;
        
            % === 2. Specify VOIs ===
            voiFiles = cell(numROIs, 1);
            
            for i = 1:numROIs
              voiFile = fullfile(thisPath, sprintf('VOI_%s_%d_%d.mat', roiNames{i}, sess, sess));
             
                if ~isfile(voiFile)
                    error('Missing VOI file for region %s: %s\n', roiNames{i}, voiFile);
                end

                voiFiles{i} = fullfile(thisPath, sprintf('VOI_%s_%d_%d.mat', roiNames{i}, sess, sess));
            end

            for i =1:numROIs 
                matlabbatch{1}.spm.dcm.spec.fmri.group.data.region{i} = {voiFiles{i}};
            end

            matlabbatch{2}.spm.dcm.spec.fmri.regions.dcmmat = cellstr(dcmMatFile);
            matlabbatch{2}.spm.dcm.spec.fmri.regions.voimat = cellstr(voiFiles);
        
            % === 3. Specify Inputs (Conditions) ===
            matlabbatch{3}.spm.dcm.spec.fmri.inputs.dcmmat = cellstr(dcmMatFile);
            matlabbatch{3}.spm.dcm.spec.fmri.inputs.spmmat = {fullfile(thisPath, 'SPM.mat')};
            matlabbatch{3}.spm.dcm.spec.fmri.inputs.session = sess;
            matlabbatch{3}.spm.dcm.spec.fmri.inputs.val = {0 0 1 1 };
            
            % === 4. Estimate DCM ===
            matlabbatch{4}.spm.dcm.estimate.dcms.gcmmat(1) = cfg_dep('Specify group: GCM mat File(s)', ...
                substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), ...
                substruct('.','gcmmat'));

            matlabbatch{4}.spm.dcm.estimate.output.single.dir = {thisPath};
            matlabbatch{4}.spm.dcm.estimate.output.single.name = sprintf('DCMest_%s_sess%d_model%d', sub, sess, m);
            matlabbatch{4}.spm.dcm.estimate.est_type = 1; % Leyla put 2? 
            matlabbatch{4}.spm.dcm.estimate.fmri.analysis = 'time';

            spm_jobman('run', matlabbatch);
            clear matlabbatch; % Reset for next model
        end
    end
end 
%%

groupPath = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2/group';


% === Inspecting result x Prepare for group level: Creat GCM file ===
for sess = 1:numSessions
    GCM = cell(length(subPaths), nbmodels);
    for s = 1:length(subPaths)
        for m = 1:nbmodels
            thisPath = subPaths{s};
            sub = allSubs(s).name;
            cd(thisPath);
            GCM{s, m} = fullfile(thisPath, sprintf('DCM_DCM_%s_sess%d_model%d.mat_m0001.mat', sub, sess, m));
        end
    end
    save(fullfile(groupPath, sprintf('GCM_full_sess%d.mat', sess)), 'GCM'); % Save group model set

end 

save(fullfile(groupPath, 'GCM_full.mat'), 'GCM'); % Save group model set


spm_dcm_fmri_check(GCM);