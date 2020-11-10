function [VolSkip,BetaSkip,OutTotSpike] = SkipTrial(stimOnset,spikeIdx,TR,nVols)
%this function takes in spikeIndex after connecting all the spikes that's
%less than 4 timepoints apart and also the stimulus Onset time, TR(to determine which Volume it onsets)
%and Output:VolSkip: nVols X 1 where if the curren trial is considered to
%skip, all the current trial volume will be 1. 
%Betaskip: nTrials x 1 where is the index for setting the calculated trial
%as NA
%Xiaojue Zhou zhouxiaojue22@gmail.com
nTrials = length(stimOnset);
movieOnsetVolume = round(stimOnset/TR,0); %this is also trial start 
BetaSkip = zeros(nTrials,1);
VolSkip = zeros(nVols,1);
OutTotSpike = zeros(nTrials,1);
for trial = 1: nTrials 
    currTrialVolume = [movieOnsetVolume(trial):1:(movieOnsetVolume(trial)+7)];
    TrialTotSpike = length(intersect(currTrialVolume,spikeIdx));
    CoreTrialSpike = intersect((movieOnsetVolume(trial)+4):1:(movieOnsetVolume(trial)+7),spikeIdx);
    if TrialTotSpike > 4  
        BetaSkip(trial) = 1;
        VolSkip(currTrialVolume,:) = 1;
    elseif CoreTrialSpike >= 4
        %if there are more than or equal to three started from 4:7
        BetaSkip(trial) = 1;
        VolSkip(currTrialVolume,:) = 1;
    end 
    currTrialVolume = NaN;

    %save out spike Index for later analysis in ROIlist
    %count the trial the spike happened 
    OutTotSpike(trial) = TrialTotSpike;
end %trial 

end