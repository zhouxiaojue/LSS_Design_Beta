function OutHrf = CalculateHRF(eventOnset,stimLen,TR,nVols)
%
%needs 1. total length 2. event onset timing (s), 0 first one 3 events duration (s)
%output = [hrf for each eventOnset point] (202 time points for input stimuli onset and length)
%output is also the lsa design 
% Upsample Time resolution to .1 sec resolution
% See Mumford, Poldrack, Nichols (2011) for rationale
%      Add 147 seconds after last trial
%Xiaojue Zhou zhouxiaojue22@gmail.com
totTime = nVols*TR;
timeUp = 0:.1:totTime-TR;
nUp = length(timeUp);
timeDown = timeUp(1:15:length(timeUp));
nDown = length(timeDown); %number of total timepoints in the current run 
nTrials = length(eventOnset);
hrf = twoGammaHrf( 30, .1, 0, 6, 16, ...
    1, 1, 6, 3 );
% Scale hrf so when convolved with really long boxcar
%   it will saturate at height of 1
hrf = hrf/sum(hrf);
OutHrf = zeros(nDown,nTrials);
for i=1:length(eventOnset)
    boxcar = (timeUp >= eventOnset(i)) .* (timeUp < (eventOnset(i)+stimLen(i)));
    pred = conv(hrf,boxcar);
    pred = pred(1:length(boxcar));
    pred = pred(1:(TR*10):end);
    OutHrf(:,i) = pred;
end

end