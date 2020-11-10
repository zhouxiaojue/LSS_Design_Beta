function [Onset,Len] = GetTiming_AdCue(eventsList,scan,eventName)
%eventName: 'movie', 'cueBlank', checking timing file last column 
%Xiaojue Zhou zhouxiaojue22@gmail.com
events = importdata([eventsList(scan).folder '/' eventsList(scan).name]);

%convert to onset and length 
AllOnsets = [];
AllLen = [];
AlleventName = cell(1,length(events)-1);
for numevent = 1:length(events)-1 %first one are the names 
    tmp = strsplit(char(events(numevent+1)));
    AllOnsets(numevent) = str2double(tmp(1));
    AllLen(numevent) = str2double(tmp(2));
    AlleventName(numevent) = tmp(3);
end
%here we want movie and cueBlank
ind = contains(AlleventName,eventName);

Onset = AllOnsets(ind);
Len = AllLen(ind); 

end