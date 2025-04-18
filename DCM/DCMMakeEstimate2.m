clear; clc;

% 2 Estimate DCM 
addpath('/Users/barbaragrosjean/Documents/MATLAB/spm12')

% Paths
dataPath = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2';

%roiNamesF = {'CerebellumLobVII', 'PrecuneusR', 'STGR', 'IFGOpR', 'MFGR_dlPFCmPFC'};
roiNamesR = {'PrecuneusL', 'STGL', 'IFGOpL', 'MFGL_dlPFCmPFC'};

% Subjects
cd(dataPath);
allSubs = dir('sub-*');
%allSubs(32) = []; % Exclude a specific subject

subPaths = cellfun(@(x) fullfile(dataPath, x, 'func', 'ResultsModel1FB'), {allSubs.name}, 'UniformOutput', false);

% Models: Define as connectivity matrices
modelsF = {
    ones(5) - eye(5);                      % Model 1: Fully connected
    [1 0 1 1 1; 0 0 0 0 0; 1 0 1 1 1; 1 0 1 1 1; 1 0 1 1 1]; % Model 2
    [1 1 0 1 1; 1 1 0 1 1; 0 0 0 0 0; 1 1 0 1 1; 1 1 0 1 1]; % Model 3
    [1 1 1 0 1; 1 1 1 0 1; 1 1 1 0 1; 0 0 0 0 0; 1 1 1 0 1]; % Model 4
    [0 0 0 0 0; 0 0 0 0 0; 0 0 0 1 1; 0 0 1 0 1; 0 0 1 1 0]; % Model 5
    [0 0 1 1 1; 0 0 1 1 1; 1 1 0 1 1; 1 1 1 0 1; 1 1 1 1 0]; % Model 6
    [0 0 1 1 1; 0 0 1 1 1; 1 1 0 1 1; 1 1 1 0 1; 1 1 1 1 0]; % Model 7
    [0 0 1 1 0; 0 0 1 1 0; 1 1 0 1 0; 1 1 1 0 0; 0 0 0 0 0]; % Model 8
    [0 0 1 1 0; 0 0 1 1 0; 1 1 0 1 0; 1 1 1 0 0; 0 0 0 0 0]; % Model 9
    [0 0 0 0 1; 0 0 0 0 1; 0 0 0 0 1; 0 0 0 0 1; 1 1 1 1 0]; % Model 10
};

modelsR = {
    ones(4) - eye(4);                      % Model 1: Fully connected
    [0 1 1 1; 
     0 0 0 0; 
     0 1 1 1; 
     0 1 1 1];  % Model 2
    
    [1 0 1 1; 
     1 0 1 1;
     0 0 0 0; 
     1 0 1 1];  % Model 3
    
    [1 1 0 1; 
     1 1 0 1; 
     1 1 0 1; 
     0 0 0 0];  % Model 4
    
    [0 0 0 0; 
     0 0 0 0; 
     0 0 1 1; 
     0 1 0 1];  % Model 5
    
    [0 1 1 1; 
     0 1 1 1; 
     1 0 1 1; 
     1 1 0 1];  % Model 6
    
    [0 1 1 1; 
     0 1 1 1; 
     1 0 1 1; 
     1 1 0 1];  % Model 7
    
    [0 1 1 0; 
     0 1 1 0; 
     1 0 1 0; 
     1 1 0 0];  % Model 8
    
    [0 1 1 0; 
     0 1 1 0; 
     1 0 1 0; 
     1 1 0 0];  % Model 9
    
    [0 0 0 1; 
     0 0 0 1; 
     0 0 0 1; 
     0 0 0 1];  % Model 10
};

%templateFileF = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2/sub-01/func/ResultsModel1FB/DCM_template.mat';
templateFileR = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2/sub-01/func/ResultsModel1FB/DCM_templateR.mat';

% Preallocate storage for results
BatchStorage = cell(length(subPaths), 1);

% Loop through subjects and sessions
for s = 1:length(subPaths)
    spm('defaults', 'FMRI');
    spm_jobman('initcfg'); % Initialize SPM job manager
    thisPath = subPaths{s};

    % init subj name
    sub = allSubs(s).name;
    cd(thisPath);
    
    % Load SPM data
    spmData = load(fullfile(thisPath, 'SPM.mat'));
    SPM = spmData.SPM; 
    TR = SPM.xY.RT; 
    numSessions = length(SPM.Sess); 
    

    for sess = 1:numSessions 
        models = modelsR; 
        roiNames = roiNamesR; 
        templateFile = templateFileR; 

        for m = 1:length(models) % test several models of interaction
            modelA = models{m}; 
            numROIs = size(modelA, 1);

            % Initialize DCM structure
            templateData = load(templateFile);
            DCM = templateData.DCM; 
            DCM.n = numROIs; 
            DCM.v = SPM.nscan(sess); 
            DCM.Y.dt = TR; 

            DCM.b(:,:,1) = modelA; 
            DCM.b(:,:,2) = modelA;

            % Assign spm_dcm_voi VOIs to DCM.xY
            DCM.xY = struct([]);
            for i = 1:numROIs
                voiFile = fullfile(thisPath, sprintf('VOI_%s_%d_%d.mat', roiNames{i}, sess, sess));
                if ~isfile(voiFile)
                    error('VOI file missing: %s', voiFile);
                end
                voiData = load(voiFile, 'xY'); % Load VOI data into struct
                xY = voiData.xY; % Extract xY explicitly
                
                DCM.xY(i).name = xY.name;
                DCM.xY(i).Ic = xY.Ic;
                DCM.xY(i).Sess = xY.Sess;
                DCM.xY(i).xyz = xY.xyz;
                DCM.xY(i).def = xY.def;
                DCM.xY(i).spec = xY.spec;
                DCM.xY(i).str = xY.str;
                DCM.xY(i).XYZmm = xY.XYZmm;
                DCM.xY(i).X0 = xY.X0;
                DCM.xY(i).y = xY.y;
                DCM.xY(i).u = xY.u;
                DCM.xY(i).v = xY.v;
                DCM.xY(i).s = xY.s;
            end

            % Define experimental inputs
            if ~isempty(SPM.Sess(sess).U)
                DCM.U.u = [];
                if length(SPM.Sess(sess).U) >= 4 % Ensure at least 4 conditions exist
                    % new
                    DCM.U.u = [SPM.Sess(sess).U(1).u, SPM.Sess(sess).U(2).u, SPM.Sess(sess).U(3).u, SPM.Sess(sess).U(4).u]; 
                    DCM.U.name = {SPM.Sess(sess).U(1).name, SPM.Sess(sess).U(2).name, SPM.Sess(sess).U(3).name, SPM.Sess(sess).U(4).name};
                else
                    error('Not enough conditions in SPM.Sess(sess).U.');
                end
            else
                DCM.U.u = zeros(DCM.v, 1);
                DCM.U.name = {'null'};
            end     

            % Save DCM file
            dcmFile = fullfile(thisPath, sprintf('DCM_%s_sess%d_model%d.mat', sub, sess, m));
            save(sprintf(dcmFile, s),"-fromstruct",DCM);

            % Specify batch for DCM
            matlabbatch = {};
            matlabbatch{1}.spm.dcm.spec.fmri.group.output.dir = {thisPath};
            matlabbatch{1}.spm.dcm.spec.fmri.group.output.name = ['DCM_',sub, '_sess',num2str(sess),'_model', num2str(m), '.mat'];
            matlabbatch{1}.spm.dcm.spec.fmri.group.template.fulldcm = {templateFile}; % Empty template
            matlabbatch{1}.spm.dcm.spec.fmri.group.template.altdcm = '';
            matlabbatch{1}.spm.dcm.spec.fmri.group.data.spmmats = {fullfile(thisPath, 'SPM.mat')};
            matlabbatch{1}.spm.dcm.spec.fmri.group.data.session = sess;
            
            % Specify regions (VOIs)
             voiFiles = cell(numROIs, 1);
             for i = 1:numROIs
                roiIndex = i;
                voiFile = fullfile(thisPath, sprintf('VOI_%s_%d_%d.mat', roiNames{i}, sess, sess));
                voiFiles{i} = voiFile;
             end
            
            matlabbatch{1}.spm.dcm.spec.fmri.group.data.region = voiFiles;
            matlabbatch{1}.spm.dcm.spec.fmri.group.data.region = cell(numROIs, 1);

            for i = 1:numROIs
                voiFile = fullfile(thisPath, sprintf('VOI_%s_%d_%d.mat', roiNames{i}, sess, sess));

                if ~isfile(voiFile)
                    error('Missing VOI file for region %s: %s\n', roiNames{i}, voiFile);
                end
                matlabbatch{1}.spm.dcm.spec.fmri.group.data.region{i} = {voiFile};
            end

            % Specify SPM and DCM 
            dcmMat = ['DCM_',sub, '_sess',num2str(sess),'_model', num2str(m), '.mat'];
            dcmMatFile = fullfile(thisPath,dcmMat);
            spmMatFile = fullfile(thisPath, 'SPM.mat');
            matlabbatch{2}.spm.dcm.spec.fmri.regions.dcmmat ={dcmMatFile};            
            matlabbatch{2}.spm.dcm.spec.fmri.regions.voimat = voiFiles;
            matlabbatch{3}.spm.dcm.spec.fmri.inputs.dcmmat = {dcmMatFile};
            matlabbatch{3}.spm.dcm.spec.fmri.inputs.spmmat = {spmMatFile};
            matlabbatch{3}.spm.dcm.spec.fmri.inputs.session = sess;
            %matlabbatch{3}.spm.dcm.spec.fmri.inputs.val = {1 2 3 4};

            % Initialize the batch for DCM specification
            matlabbatch{3}.spm.dcm.spec.fmri.inputs.val = cell(2, 1);
            
            % Condition 3 (onsets and durations)
            matlabbatch{3}.spm.dcm.spec.fmri.inputs.val{1} = SPM.Sess.U(3).ons;  % Onsets of Condition 3
            matlabbatch{3}.spm.dcm.spec.fmri.inputs.val{2} = SPM.Sess.U(4).ons;  % Onsets of Condition 4
                                   
                                              
            % Specify estimation step
            matlabbatch{4}.spm.dcm.estimate.dcms.gcmmat = cfg_dep('Specify group: GCM mat File(s)', ...
                substruct('.','val', '{}',{1}), substruct('.','gcmmat'));

            % Specify output 
            matlabbatch{4}.spm.dcm.estimate.output.single.dir = {thisPath};
            matlabbatch{4}.spm.dcm.estimate.output.single.name = sprintf('GCM_sub%s_sess%d_model%d', sub, sess, m);
            matlabbatch{4}.spm.dcm.estimate.est_type = 2; % type of DCM Estimation
            matlabbatch{4}.spm.dcm.estimate.fmri.analysis = 'time';
            
            % Run the batch
            try
                spm_jobman('run', matlabbatch);
            catch ME
                fprintf('Error in subject %s, session %d, model %d: %s\n', sub, sess, m, ME.message);
            end
        end
    end
end