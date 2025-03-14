%% Create template DCM file 

path_to_save = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2/sub-01/func/ResultsModel1FB/DCM_templateR.mat';
dataPath = '/Users/barbaragrosjean/Desktop/CHUV/ToM/dataAll/ds000109-2.0.2';
roiNamesR = {'PrecuneusL', 'STGL', 'IFGOpL', 'MFGL_dlPFCmPFC'};

DCM = struct();
% Define regions of interest (ROIs)
DCM.xY.Dfile = dataPath; 
DCM.xY.name = roiNamesR;
DCM.xY.Ic = [1 2 3 4];  % Indices of ROIs

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
DCM.c = zeros(nROIs, 4);  
% Save DCM file
save(path_to_save, 'DCM');
