%% STEP 2:
%% Create DCM files 
%For each participant, specify a model that describes how experimental stimuli (or the resting state) generated their neural activity and 
%connectivity, and in turn, their neuroimaging data. These models contain parameters - unknown quantities such as neural connection strengths, 
%which we wish to estimate from the data.

clear; clc;

path_to_save = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2/sub-01/func/ResultsModel1FB/DCM_templateR.mat';
dataPath = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2';
roiNames = {'PrecuneusL', 'STGL', 'IFGOpL', 'MFGL_dlPFCmPFC'};

% Load SPM file 
DCM = struct();

% SPM 
addpath('/Users/barbaragrosjean/Documents/MATLAB/spm12')
spm('Defaults','fMRI');
spm_jobman('initcfg'); 

% Define experimental inputs
DCM.U.u = zeros(100,1); 
DCM.xY.Dfile = dataPath; 
DCM.xY.name = roiNames;
DCM.xY.Ic = [1 2 3 4];  

% Define experimental inputs
DCM.U.dt = 2;  % Repetition time (TR)
DCM.U.name = {'FB Story Ons', 'CTRL Story Ons', 'FB Resp Ons', 'CTRL Resp Ons'};  
DCM.U.u = zeros(100,1); 

% Define connectivity matrices
nROIs = length(DCM.xY.Ic);
DCM.n = 4;
DCM.v = 0; 
DCM.a = ones(nROIs, nROIs);  
DCM.b = zeros(nROIs, nROIs, 1); 

% Define connectivity matrices
nROIs = length(DCM.xY.Ic);

% Models
models = {
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

% Subjects
cd(dataPath);
allSubs = dir('sub-*');

subPaths = cellfun(@(x) fullfile(dataPath, x, 'func', 'ResultsModel1FB'), {allSubs.name}, 'UniformOutput', false);

%Add info 
for s = 1:length(subPaths)
    thisPath = subPaths{s};
    sub = allSubs(s).name;
    disp(sub)
    cd(thisPath);

    % get SPM data 
    spmData = load(fullfile(thisPath, 'SPM.mat')); % Load into struct
    SPM = spmData.SPM; % Extract SPM
    TR = SPM.xY.RT; % Extract TR
    numSessions = length(SPM.Sess); % Number of sessions

    for sess = 1:numSessions

        for m = 1:length(models) 
            modelA = models{m};
            numROIs = size(modelA, 1);

       
            % === 1. Initialize DCM structure ===
            
            DCM.n = numROIs;
            DCM.v = SPM.nscan(sess); % Number of scans
            DCM.Y.dt = TR; % TR
            DCM.b(:,:,1) = modelA; % Use model-specific connectivity
            DCM.b(:,:,2) = modelA;
            DCM.a = ones(nROIs, nROIs);  
            DCM.c = ones(4, 2);
            
            
            % === 2. Assign spm_dcm_voi VOIs to DCM.xY ===
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

            % === 3. Define experimental inputs ===
            if ~isempty(SPM.Sess(sess).U)
                DCM.U.u = [];
                if length(SPM.Sess(sess).U) >= 4 % Ensure at least 4 conditions exist
                    DCM.U.u = [SPM.Sess(sess).U(1).u, SPM.Sess(sess).U(2).u, SPM.Sess(sess).U(3).u, SPM.Sess(sess).U(4).u]; 
                    DCM.U.name = {SPM.Sess(sess).U(1).name,SPM.Sess(sess).U(2).name, SPM.Sess(sess).U(3).name, SPM.Sess(sess).U(4).name};
                    
                else
                    error('Not enough conditions in SPM.Sess(sess).U.');
                end
            else
                DCM.U.u = zeros(DCM.v, 1);
                DCM.U.name = {'null'};
            end     

            % Save DCM file
            dcmFile = fullfile(thisPath, sprintf('DCM_%s_sess%d_model%d.mat', sub, sess, m));
            %save(sprintf(dcmFile, s),"-fromstruct",DCM);
            save(sprintf(dcmFile, s), 'DCM', '-mat');

        end 
    end 
end 


