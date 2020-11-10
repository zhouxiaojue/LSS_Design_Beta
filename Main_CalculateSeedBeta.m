function Main_CalculateSeedBeta(eventName,DGSR,CueNuis)
%eventName can be 'movie', 'cue'. Then calculate beta for differernt type 
%DGSR: 'WGSR' 'WOGSR'
%CueNuis: 'asNuis' or ''
addpath '/data2/2020_ActDecode_Cueing/analysis/Scripts/'


ROITSDir = '/data2/2020_ActDecode_Cueing/analysis/TS/';
vtcDir = '/data2/2020_ActDecode_Cueing/bv/';
designMDir = '/data2/2020_ActDecode_Cueing/analysis/DesignMat/';
outBetaDir = '/data2/2020_ActDecode_Cueing/analysis/Beta/'; 

switch DGSR
    case 'WGSR'
        outBetaDir = strcat(outBetaDir,'WGSR/');
    case 'WOGSR'
        outBetaDir = strcat(outBetaDir,'WOGSR/');
end
designsuffix = 'DespikeLSS';

ROITSsuffix = '_MT';
%first run NativeVOI2MatlabCoords to convert voi to mat file 
fileID = fopen ('/data2/2020_ActDecode_Cueing/analysis/2020ad_cue_sublist.txt','r');
file = textscan(fileID,'%q');
subList = file{1};
fclose(fileID);
NumSubs = length(subList);

%estimate two sets of beta, one for movie and one for cue. For later
%classification on 
for sub =  1:NumSubs
 
    subID = char(subList(sub)); 
    subID
    %load designMatrix
    designfName = strcat(designMDir,subID,designsuffix,'.mat');
    load(designfName);
    %OutDesignMatrix loaded 
    
    %loadROITS
    load(strcat(ROITSDir,subID,ROITSsuffix,'.mat'));
    ROIName = cellstr(Data.ROIlist.labels);
    NumROIs = length(Data.patterns);
    for r = 1:NumROIs
        %loadROITS
        InROITS = Data.patterns{r};
        
        %loaded Data
        NumVox = size(InROITS,2); %voxel time series 
        NumScan = length(OutDesignMatrix.Xlss);
        NumTrials = size(OutDesignMatrix.Xlss{1},3);
        BetaHat_allrun = zeros(NumScan*NumTrials,NumVox);
        TaskInd_allrun = zeros(NumScan*NumTrials,1);
        
        
        saveBetaTxtFileName = char(strcat(subID,'_',ROIName(r),'_',eventName,'_',CueNuis,'_',DGSR,'_allBeta.txt'));
        for v = 1:NumScan
            %give designmatrix and necessary input for calculating betas
            BetaSkip = OutDesignMatrix.BetaSkip{v};
            %find BetaSkip for current run 
            BetaSkipT = true;
            
            switch DGSR
                case 'WGSR'
                    Nuis = OutDesignMatrix.Xlss{v}(:,5:end,1);
                case 'WOGSR'
                    Nuis = OutDesignMatrix.Xlss{v}(:,5:end-2,1);
            end
            Nuis(:,size(Nuis,2)+1) = 1;
            switch eventName
                case 'movie'
                    X_lss = OutDesignMatrix.Xlss{v}(:,1:2,:);
                    
                    
                    switch CueNuis %if model the other cue/movie as nuisance regressor
                        case 'asNuis'
                            tmp = OutDesignMatrix.Xlss{v}(:,3:4,1);
                            Nuis = cat(2,Nuis,sum(tmp,2));
                    end
                case 'cue'
                    X_lss = OutDesignMatrix.Xlss{v}(:,3:4,:);
                    
                    switch CueNuis
                        case 'asNuis'
                             tmp = OutDesignMatrix.Xlss{v}(:,1:2,1);
                             Nuis = cat(2,Nuis,sum(tmp,2));
                    end
                    
            end
            
            
            X_lss(:,size(X_lss,2)+1,:) = 1;
            c = zeros(1,size(X_lss,2));
            c(1,1) = 1;

            indexBetaHatStart = 1+(v-1)*size(X_lss,3); 
            %trying to find which trial index in 192 the current Beta
            indexBetaHatEnd = size(X_lss,3)+(v-1)*size(X_lss,3);

            BetaHat = zeros(size(X_lss,3),NumVox);
            for vox = 1:NumVox
                TS = Data.patterns{r}(:,vox);
       
                BetaHat(:,vox) = CalculateBeta(TS,Nuis,X_lss,c,BetaSkip,BetaSkipT);
                
            end
            BetaHat_allrun(indexBetaHatStart:indexBetaHatEnd,:) = BetaHat;
            
             %Don't need to change the label, but index to classification
             %TaskInd for later classification of interest. Save multiple
             %index here 
            %2: save action and cued index here to classification beta
            %files %index out current beta 
            
            switch eventName
                case 'movie'
                    TaskInd = OutDesignMatrix.stimLabels{v}(:,2);
                case 'cue'
                    TaskInd = OutDesignMatrix.stimLabels{v}(:,5);
            end
            
            TaskInd_allrun(indexBetaHatStart:indexBetaHatEnd,1) = TaskInd;
        end %scan 
        %save output to a txt file 
        %output with [VoxBetahat Run trialLabel]
        
        %the run are 1 to 6 with numTrials repetition for each run 
        tmprun = repmat(1:NumScan,NumTrials,1);
        %all the voxel name for column name 
        
       
        OutAllBeta = horzcat(BetaHat_allrun,tmprun(:),TaskInd_allrun);

        if ~exist(strcat(outBetaDir,saveBetaTxtFileName),'file')
            num = cellstr(string(1:NumVox));
            header = cellstr([num(:);'Run';'TaskInd'])';
            fid = fopen(fullfile(outBetaDir,saveBetaTxtFileName),'wt');
            fprintf(fid,'%s\t',header{1:end-1});
            fprintf(fid,'%s\n',header{end});
            fclose(fid);    
            dlmwrite(fullfile(outBetaDir,saveBetaTxtFileName),OutAllBeta,'delimiter','\t','-append')
        else
            disp(['already saved' strcat(outBetaDir,saveBetaTxtFileName)])
        end
        
    end %ROI 
    
end %sub
end