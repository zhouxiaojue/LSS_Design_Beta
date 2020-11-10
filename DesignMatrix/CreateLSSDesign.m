function OutDesign = CreateLSSDesign(Hrf,MeanCenter,LSStype,Indtask)
%%Type is either LSS/LSA
%Hrf is a number of Volumes by number of trials
%covariate is number of volumes by number of covariate of interest
%variable is designType
%Create LSS Design matrix
%Future, if want separated by trial type, then have another function to
%index and then combine same type together
%Xiaojue Zhou zhouxiaojue22@gmail.com
%loop over trial which is the number of columnes of hrf
switch LSStype
    case 'LSS'
        OutDesign = zeros(size(Hrf,1),2,size(Hrf,2));
        for i=1:size(Hrf,2)
            %sum over all other trials, used as second column
            %size: nVols by 2, 1:current trial, 2:sum of all other trials
            OutDesign(:,1,i) = Hrf(:,i);
            inOther = (1:size(Hrf,2)) ~= i ;
            OutDesign(:,2,i) = sum(Hrf(:,inOther),2);
        end %number of trials
    case 'LSStask'
        OutDesign = zeros(size(Hrf,1),size(Indtask,2)+1,size(Hrf,2));
        
        Hrftask = zeros(size(Hrf,1),size(Indtask,2)); %here is outputting total timepoints by tasktypes
        for task = 1:size(Indtask,2)
            Hrftask(:,task) = sum(Hrf(:,logical(Indtask(:,task))),2);
        end
        
        for i=1:size(Hrf,2)
            %sum over all other trials, used as second column
            %size: nVols by 2, 1:current trial, 2:sum of all other trials
            indc = Indtask(i,:)==1;
            OutDesign(:,1,i) = Hrf(:,i);
            OutDesign(:,2,i) =  Hrftask(:,indc) - Hrf(:,i);
            OutDesign(:,3:(size(Indtask,2)+1),i) = Hrftask(:,~indc);  
        end %number of trials
end
%X_lss: timepoint(202)xstim/null x trials 
%mean centering X_lss matrix
switch MeanCenter
    case 'MeanCenter'
        nrow = size(OutDesign,1);
        for dim = 1:size(OutDesign,3)
            OutDesign(:,:,dim) = OutDesign(:,:,dim) - ones(nrow,1) * mean(OutDesign(:,:,dim));
        end 
    case 'noMeanCenter'
end %if mean center lss matrix or not

   
end