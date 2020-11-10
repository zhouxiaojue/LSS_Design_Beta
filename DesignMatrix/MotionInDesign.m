function [sdmVolt,spikeReg,spikeIdx,OutSpikeIdx] = MotionInDesign(fdThresh,sdmFileN,radius,minChunkSize)
%Output: sdm volterra expansion, Spike Regressor (each column with 1 where
%there is spike),
%spikeIdx is the number of time points where there is spike after
%concatenanting all the small spikes 
%OutSpikeIdx is the number of time points where there is spike without
%combining them. It's useful for output spike information as needed. 
%Xiaojue Zhou zhouxiaojue22@gmail.com
addpath('/data1/2018_ActionDecoding/analysis_fc/')

sdm = readBvSDM(sdmFileN,6);     %read in sdm file
nVols = size(sdm,1);
%read in all six columns by 202 times points motion parameters 
sdm(:,4:6,:) = sdm(:,4:6,:)*(pi/180); %First convert deg to rad 
sdm(:,4:6,:) = sdm(:,4:6,:)*radius;   %... arc length (in mm) 

fd = getFwd(sdm);
sdm = detrend(sdm);  %Remove linear trend
%202x6
sdmVolt = expandRegVolterra(sdm);       %Add Volterra expansion to design matrix
%202x12 

%202x1 time series of FD       
%regress 3DMC+Volt and Despike
%FD threshold is set at top of script
spikeIdx = find(fd > fdThresh);  
%Remove any segments that are too short in length
%here is where we can save out spikeIdx if wanted 
OutSpikeIdx = spikeIdx;

chunkTest = [0;diff(spikeIdx)];
for i = 1:length(chunkTest)
   if chunkTest(i) > 1 && chunkTest(i) < minChunkSize
       startIdx = spikeIdx(i-1)+1;
       endIdx = spikeIdx(i)-1;
       spikeIdx = [spikeIdx; transpose(startIdx:endIdx)];
   end
end
spikeIdx = sort(spikeIdx);

nSpike = length(spikeIdx);
spikeReg = zeros(nVols,nSpike);
for spk = 1:nSpike
    spikeReg(spikeIdx(spk),spk) = 1;
    %spikeReg : 202*77 (each column contains 1 for the timepoint motion censored)
    %
end

end %function