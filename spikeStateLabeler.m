%**************************************************************************
% UPDATED 11.20.2013 by Brooks A. Gross
% -Changed to read in any type of stage scored file created by Sleep Scorer
% or Auto-Scorer.
% -Updated rest of code to reflect correct column of data to read based on
% updated matrix loaded from the scored file.
%__________________________________________________________________________
function spikeStateLabeler(sleepFileName, AllSpikeTimeStamps,plx_cluster_indx)
% Load the Sleep Scorer file if isolating states for the analysis:
% try
%     scoredStates = xlsread(sleepFileName);
% catch %#ok<*CTCH>
%     uiwait(errordlg('Check if the file is saved in Microsoft Excel format.',...
%      'ERROR','modal'));
% end

try
    [numData, stringData] = xlsread(sleepFileName);
catch %#ok<*CTCH>
    uiwait(errordlg('Check if the file is saved in Microsoft Excel format.',...
     'ERROR','modal'));
end

%Detect if states are in number or 2-letter format:
if isequal(size(numData,2),3)
    
    scoredStates = numData(:,2:3);
    clear numData stringData
else
    scoredStates = numData(:,2);
    clear numData
    stringData = stringData(3:end,3);
    [stateNumber] = stateLetter2NumberConverter(stringData);
    scoredStates = [scoredStates stateNumber];
    clear stateNumber stringData
end

lengthAllSpikeTS = length(AllSpikeTimeStamps);
stateLabeledSpikes = [AllSpikeTimeStamps; zeros(1, lengthAllSpikeTS)];
stateTargetInterval=[];
lengthScoredStates =length(scoredStates);
lengthScoredSubStates =[];
for i = 1:8
    isoCount = 1;
    lengthScoredSubStates = lengthScoredStates;
    scoredSubStates = scoredStates;
    for j = 1:lengthScoredSubStates
        if isequal(scoredStates(j,2),i)
            scoredSubStates(j,2) = 1;
        else
            scoredSubStates(j,2) = 0;   
        end  
    end
    firstIsoInd = find(scoredSubStates(:,2)==1, 1);
    if isempty(firstIsoInd)
        scoredSubStates = [];
    else
        scoredSubStates(1:firstIsoInd-1,:) = [];
    end
    lengthScoredSubStates =length(scoredSubStates); %Recalculate the length of the array due to removal of initial rows.
    if lengthScoredSubStates < 2
        stateTargetInterval = [];
    else
        stateTargetInterval(isoCount,1) = scoredStates(1,1); 
        %The following FOR loop generates isolated intervals based on user-selected states:
        for j = 2:lengthScoredSubStates   
            if isequal(scoredSubStates(j,2),1)
                if isequal(scoredSubStates(j-1,2),0)
                    stateTargetInterval(isoCount,1) = scoredSubStates(j,1); %Looking at time
                end
                if isequal(j, lengthScoredSubStates)
                    stateTargetInterval(isoCount,2) = scoredSubStates(j,1); %Looking at time
                end
            elseif isequal(scoredSubStates(j,2),0) && isequal(scoredSubStates(j-1,2),1)
                stateTargetInterval(isoCount,2) = scoredSubStates(j,1); %Looking at time
                isoCount = isoCount + 1;
            end
        end
    end

%     isolatedSpikes = [];
    [lengthIsoArray, ignore] = size(stateTargetInterval);
    if isequal(0,lengthIsoArray)
    else
        for m = 1:lengthIsoArray % Extract all of the sub-intervals for states containing spikes.
           subIntervalIndx = find(AllSpikeTimeStamps(1,:) >= stateTargetInterval(m,1) & AllSpikeTimeStamps(1,:) <= stateTargetInterval(m,2));
           if isempty(subIntervalIndx)
           else
               stateLabeledSpikes(2,subIntervalIndx) = i;
    %            isolatedSpikes = [isolatedSpikes AllSpikeTimeStamps(1,subIntervalIndx)]; %#ok<AGROW,FNDSB>
           end
        end
    end
    clear stateTargetInterval subIntervalIndx
end
[fileName,ignore2] = uiputfile(['stateLabeledSpikesRat_Day_TT_Cell' num2str(plx_cluster_indx) '.mat'],'Save state labeled spikes as:');
save(fileName, 'stateLabeledSpikes');