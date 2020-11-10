function sdm = expandRegVolterra( sdm )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here


if size(sdm,2) ~= 6
   error('Please provide exactly six motion regressors for Volterrra expansion.'); 
end

%Add regressors for motion at previous timepoint
sdm(:,7:12) = [repmat(0,1,6); sdm(1:length(sdm)-1,1:6)];

%Add the square of the motion regressors
sdm(:,13:18) = sdm(:,1:6).^2;

%Add the square of the previous time point
sdm(:,19:24) = sdm(:,7:12).^2;

end

