function [SpikeRates,WindowCenters SpikeCounts]= PSTH_Simple(SpikeTimes, AnchorTimes, PreTime, PostTime, WindowSize,WindowStep)
% WindowStep=WindowSize; % in seconds
NumberOfTrials = numel(AnchorTimes);
RelativeEdges = PreTime:WindowStep:PostTime;
NumberOfEdges = numel(RelativeEdges);
NumberOfWindows = NumberOfEdges - 1;

% bin the spikes in windows to have one column per trial
%  SpikeCounts=zeros(NumberOfWindows,NumberOfTrials);
for AnchorTimeIndex = 1:NumberOfTrials
    BinEdges = AnchorTimes(AnchorTimeIndex) + RelativeEdges;
    [SpikeCounts(:,AnchorTimeIndex),~]=histcounts(SpikeTimes, BinEdges);  
end

SpikeRates = SpikeCounts / WindowSize;
WindowCenters = (RelativeEdges(1:NumberOfWindows)+ WindowSize );
end

% + WindowSize/2