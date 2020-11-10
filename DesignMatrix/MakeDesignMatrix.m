function OutDesignMatrix = MakeDesignMatrix(method,designType,GSRin,GSRDir,subID,designMotionfName,DesignMDir,nVols,fdThresh,TR,sdmList,eventsList,labelList,vtcList,NumVTCs,fsPath)
%MakeLSSdesignmatrix with method of [DespikeLSS DespikeAll SkipTrialZero]
%future: add in NOGSR option, add in precue button response etc option
%compare between SkipTrialzero and DespikeAll. choose one 
%Output Xlss:[Xlss Residualvariables] stimLabels: 1/0 for each instruction
%typ
addpath '/data1/2018_ActionDecoding/analysis_fc/'
%where the sub scripts live
%Xiaojue Zhou zhouxiaojue22@gmail.com
%MAKE CHANGES TO 
%Have no GSR option


%%%ADAPT for future study 
%change the input for sdm events behav list 
radius = 50; %conversion for head motion angle
minChunkSize = 5;
%sdmList = dir(strcat(subPath,'/*actdecode*run*3DMC.sdm'));
%eventsList = dir(strcat(behPath,'*_events.tsv'));
%behavList = dir(strcat(behPath,'*_responses.tsv'));

testLog = numel(unique([length(sdmList),NumVTCs,length(eventsList)]));
if testLog ~= 1
    warning('Number of sdm, fMRI, Timing, and behavorial data doesnt match, exiting program')
    return
end 
AllOutSpike = cell(1,NumVTCs); %this is how spike index volume saved per scan
AllTrialSpike = cell(1,NumVTCs); %this is how many spikes per trial per scan 
for scan = 1:NumVTCs
    %%
    %Getting all the files and timing here first 
    %
    %change to use GetTiming_AdCue 
    
    
   [movieOnset,movieLen] = GetTiming_AdCue(eventsList,scan,'movie');
   [cueOnset,cueLen] = GetTiming_AdCue(eventsList,scan,'cueBlank');
    
    nTrials = length(movieOnset);
%     %Here needs to edit to fit in the new 
%     events = importdata([eventsList(scan).folder '/' eventsList(scan).name]);
%     
%     %convert to onset and length 
%     AllOnsets = [];
%     AllLen = [];
%     AlleventName = cell(1,length(events)-1);
%     for numevent = 1:length(events)-1 %first one are the names 
%         tmp = strsplit(char(events(numevent+1)));
%         AllOnsets(numevent) = str2double(tmp(1));
%         AllLen(numevent) = str2double(tmp(2));
%         AlleventName(numevent) = tmp(3);
%     end
%     %here we want movie and cueBlank
%     movieind = contains(AlleventName,'movie');
%     cueind = contains(AlleventName,'cueBlank');
%     %FUTURE, input the desirable model event here match with the trial type
%     
%     movieOnset = AllOnsets(movieind);
%     movieLen = AllLen(movieind); 
%     
%     cueOnset = AllOnsets(cueind);
%     cueLen = AllLen(cueind);
%     
%     nTrials = length(movieOnset);
    
    %%,BetaSkip
    %Function 2 create hrf 
    %needs 1. total length 2. event onset timing 3 events duration 
    %output = [hrf for each eventOnset point] (202 time points for input stimuli onset and length)
    %output is also the lsa design AllTrialSpike
    
    OutHrfStim = CalculateHRF(movieOnset,movieLen,TR,nVols);
    OutHrfCue = CalculateHRF(cueOnset,cueLen,TR,nVols); 
    %this is 202 by 1 use as covariate in design matrix
    %%
    %Function 3 create LSS or LSA design matrix from hrf output above
    %variable is designType
    %Create LSS Design matrix
    %Future, if want separated by trial type, then have another function to
    %index and then combine same type together
    
    Indtask = '';
    switch designType
        case 'LSS'
            %LSS design
            X_lssmovie = CreateLSSDesign(OutHrfStim,'noMeanCenter',designType,Indtask); 
            X_lssCue = CreateLSSDesign(OutHrfCue,'noMeanCenter',designType,Indtask); 
        case 'LSA'
            %LSA design
            X_lss = OutHrfStim;
        case 'LSStask'
            X_lss = CreateLSSDesign(OutHrfStim,'noMeanCenter',designType,Indtask); 
        otherwise
            %traditional Hrf estimation function
            X_lss = sum(OutHrfStim,2);
    end %LSS or LSA
    
    %combine movie and cue together, add along the second dimension 
    X_lss = cat(2,X_lssmovie,X_lssCue);
    %%
    %%%function 4 process motion information and output 
    %%% [spikeregressor volterraExpansion] also trial skipping 
    
    %now try to find the spikes and also despike the data

    sdmFileN = fullfile(sdmList(scan).folder,sdmList(scan).name);
    % '/data1/2018_ActionDecoding/data/sub-07/bv/sub-07_actdecode_run-1_3DMC.sdm'
    
    [sdmVolt,spikeReg,spikeIdx,OutSpikeIdx] = MotionInDesign(fdThresh,sdmFileN,radius,minChunkSize);
   
    if length(OutSpikeIdx) <=0
        AllOutSpike{scan} = 0;
    else
        AllOutSpike{scan} = OutSpikeIdx;
    end
    %in the futuer, can output this AllOutSpike as needed for future
    %analysis
    %%
    %function 5 calculateGSR
    if GSRin
        fGSROut = strcat(subID,'_',num2str(scan),'GSRTS.mat');
        if exist(fullfile(GSRDir,fGSROut),'file')
            GSRTS = load(fullfile(GSRDir,fGSROut));
            GSRTS = GSRTS.GSRTS;
        else
            disp('extracting GSR Time Series')
            GSRTS = ExtractTS_GSRFSMask(vtcList,subID,GSRDir,scan,subID,fsPath);
        end %if already have the GSR matrix
    end %gsr

    %%
    %function 6 trial skipping 
    %skip whole trial (set output beta to NaN if there are too many spikes 
    %can set the whole trial dimension to NaNs to have NaN as beta output to skip the trial
    
    [VolSkip,BetaSkip,OutTotSpike] = SkipTrial(movieOnset,spikeIdx,TR,nVols);
    %AllOutSpike(:,scan) = VolSkip; %think about ways to save this
    %information
    
    AllTrialSpike{scan} = OutTotSpike;
    
    
    %things to be combined: Nuisance(button precue) X_lss sdmVolt spikeReg,spikeIdx
    switch method
        
        case 'DespikeLSS'
            %%Comebining verything into full design matrix
            %It doesn't spike sdmVolt or other nuisance regressor but only
            %LSS design matrix
            sdmVolt_Pad = repmat(sdmVolt,[1 1 size(X_lss,3)]);
            spikeReg_Pad = repmat(spikeReg,[1 1 size(X_lss,3)]); 
            if GSRin
                GSRTS_Pad = repmat(GSRTS,[1 1 size(X_lss,3)]);
            end
            
            X_lss(spikeIdx,:,:) = 0;
            if GSRin
                OutDesignMatrix.Xlss{scan} = cat(2,X_lss, sdmVolt_Pad,GSRTS_Pad,spikeReg_Pad);
            else
                OutDesignMatrix.Xlss{scan} = cat(2,X_lss, sdmVolt_Pad,spikeReg_Pad);
            end
           
            OutDesignMatrix.BetaSkip{scan} = BetaSkip;
            
        case 'DespikeAll'
            %%Comebining verything into full design matrix
            sdmVolt_Pad = repmat(sdmVolt,[1 1 size(X_lss,3)]);
            sdmVolt_Pad(spikeIdx,:,:)=0;
            spikeReg_Pad = repmat(spikeReg,[1 1 size(X_lss,3)]); 
            if GSRin
                GSRTS_Pad = repmat(GSRTS,[1 1 size(X_lss,3)]);
                GSRTS_Pad(spikeIdx,:,:)=0;
            end %GSR or not
            X_lss(spikeIdx,:,:) = 0;
            
            if GSRin
               OutDesignMatrix.Xlss{scan} = cat(2,X_lss, sdmVolt_Pad,GSRTS_Pad,spikeReg_Pad);
            else
               OutDesignMatrix.Xlss{scan} = cat(2,X_lss, sdmVolt_Pad,spikeReg_Pad);
            end %GSR or not
            OutDesignMatrix.BetaSkip{scan} = BetaSkip;
            
          
            
        case 'SkipTrialZero'
            %here is using the VolSkip to set everything to zero
            sdmVolt_Pad = repmat(sdmVolt,[1 1 size(X_lss,3)]);
            sdmVolt_Pad(logical(VolSkip),:,:)=0;
            spikeReg_Pad = repmat(spikeReg,[1 1 size(X_lss,3)]); 
            if GSRin
                GSRTS_Pad = repmat(GSRTS,[1 1 size(X_lss,3)]);
                GSRTS_Pad(logical(VolSkip),:,:)=0;
            end
            X_lss(logical(VolSkip),:,:) = 0;
            
            if GSRin
               OutDesignMatrix.Xlss{scan} = cat(2,X_lss, sdmVolt_Pad,spikeReg_Pad,GSRTS_Pad);
            else
               OutDesignMatrix.Xlss{scan} = cat(OutHrfresponse,X_lss, sdmVolt_Pad,spikeReg_Pad);
            end
            OutDesignMatrix.BetaSkip{scan} = BetaSkip;
            
            
        %designMatrix: currTrial/NuisanceTrial/intercept/sdmVolterraExpansion/regressors of motion 
    end %end switch method

    %behavioral data is in another _params.mat 
    stimLabels = load([labelList(scan).folder '/' labelList(scan).name]);

    OutDesignMatrix.stimLabels{scan} = stimLabels.p.rec;
    OutDesignMatrix.stimLabelName = {'instruction','action(1crouch2jump)','actor','viewpoing','cued(1valid2blank3invalid)'};

    
 
end %NumVTCs/scans
OutDesignMatrix.AllOutSpike = AllOutSpike;
OutDesignMatrix.AllTrialSpike = AllTrialSpike;
%The code below needs to be run if want to run analysis for spike can also
%just load design matrix and save the spike 
%     OutSpikeIndexTxt = strcat(OutPrefix,'_','AllSpikeIdx.txt');
%     if ~exist(fullfile(DesignMDir,OutSpikeIndexTxt),'file')
%         OutSpikeTrialIdx = reshape(OutSpikeTrialIdx,[],1);
%         dlmwrite(fullfile(DesignMDir,OutSpikeIndexTxt),OutSpikeTrialIdx,'delimiter','\t','-append')
%         clear OutSpikeTrialIdx
%     end %if written txt file exist or not 
save(fullfile(DesignMDir,designMotionfName),'OutDesignMatrix');