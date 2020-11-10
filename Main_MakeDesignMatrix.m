clear all;
addpath('/usr/local/MATLAB/R2017a/toolbox/fMRItoolbox/')
addpath('/home/xiaojue/bin/nifti_tools/')
addpath '/data2/2020_ActDecode_Cueing/analysis/Scripts/DesignMatrix/'

vtcDir = '/data2/2020_ActDecode_Cueing/bv/'; %subID/*NATIVE.vtc
TimingDir = '/data2/2020_ActDecode_Cueing/behav/'; %subID/func/*events.tsv
sdmDir = '/data2/2020_ActDecode_Cueing/bv/';
OutFileDir = '/data2/2020_ActDecode_Cueing/analysis/';
%GSRDir = '/data1/2018_ActionDecoding/analysis_fc/Despike/GSRTS/';
DesignMDir = '/data2/2020_ActDecode_Cueing/analysis/DesignMat/';
GSRDir = '/data2/2020_ActDecode_Cueing/analysis/GSRTS/';
designfNameSuffix = '_LSSDespike.mat';
fsPath = '/data2/2020_ActDecode_Cueing/fs/ad_cue_sub-01/';
nVols = 208 ; %needs to check in the future, but for create design Data
nTrials = 20;

TR = 1.5;
fdThresh = 0.4;
sdmFlag = 1; % 1 = include 3DMC motion regressors
% OutideFiller = zeros(1, 1, 1, NumSeeds);
GSRin = 1;
designType = 'LSS'; %LSS or ''(traditional HRF design)
method = 'DespikeLSS';

radius = 50; %conversion for head motion angle

fileID = fopen ('/data2/2020_ActDecode_Cueing/analysis/2020ad_cue_sublist.txt','r');
file = textscan(fileID,'%q');
subList = file{1};
fclose(fileID);
NumSubs = length(subList);

for sub =  1:NumSubs 
 
    subID = char(subList(sub));
    %example: sub-07
    subID
    OutPrefix  = subID;

    vtcList = dir(strcat(vtcDir,subID,'/*.vtc'));
    NumVTCs = length(vtcList);
    
    sdmList =  dir(strcat(sdmDir,subID,'/*3DMC.sdm'));
    
    eventsList = dir(strcat(TimingDir,subID,'/func/*_events.tsv'));
    %change to load the evnets.tsv
    labelList = dir(strcat(TimingDir,subID,'/func/*_params.mat'));
    
    
    designMotionfName = strcat(subID,'DespikeLSS_GSR.mat');
    if exist(fullfile(DesignMDir,designMotionfName),'file')
        disp(['already saved ' designMotionfName])
    else
        %use script to calcualte and save design matrix
        %(method,subPath,behPath,GSRDir,designMotionfName,DesignMDir,baseline,GSRin)
       MakeDesignMatrix(method,designType,GSRin,GSRDir,subID,designMotionfName,DesignMDir,nVols,fdThresh,TR,sdmList,eventsList,labelList,vtcList,NumVTCs,fsPath)

    end
end