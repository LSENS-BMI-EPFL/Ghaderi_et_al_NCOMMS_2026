function [PSTH_Signal,WindowCenters]= PSTHBehavior(MovementSignal,Signal_Time ,AnchorTimes, PreTime, PostTime, WindowSize,WindowStep,fs)

[PSTH_Signal,WindowCenters] = structfun(@(S) SimplebehaviorPSTH(S,Signal_Time ,AnchorTimes, PreTime, PostTime, WindowSize,WindowStep,fs),MovementSignal,'UniformOutput',false);

    function [Mean_Signal,WindowCenters]= SimplebehaviorPSTH(Signal,Signal_Time ,AnchorTimes, PreTime, PostTime, WindowSize,WindowStep,fs)

        % global Signal_Time AnchorTimes PreTime PostTime WindowSize WindowStep fs

        NumberOfTrials = numel(AnchorTimes);
        RelativeEdges = PreTime:WindowStep:PostTime-WindowSize;
        NumberOfEdges = numel(RelativeEdges);
        % NumberOfWindows = NumberOfEdges - 1;

        % bin the spikes in windows to have one column per trial
        % SpikeCounts=zeros(NumberOfWindows,NumberOfTrials);

        WindowSizeFrame=WindowSize*fs;
        WindowStepFrame=(WindowStep)*fs;
        PreFrame=PreTime*fs;
        PostFrame=PostTime*fs;

        RelativeFrame = PreFrame:WindowStepFrame:PostFrame-WindowSizeFrame;

        Win_len=[PostTime-PreTime]*fs;
        WindowCenters=RelativeEdges+ WindowSize;

        % for S=1:length(MovementSignal)
        %
        % Signal=MovementSignal{S};

        for AnchorTimeIndex = 1:NumberOfTrials


            if  AnchorTimes(AnchorTimeIndex) < Signal_Time (1)
                Mean_Signal(1:length(RelativeFrame),AnchorTimeIndex)=nan;


                continue

            end

            if   Signal_Time (end)<AnchorTimes(AnchorTimeIndex)
                Mean_Signal(1:length(RelativeFrame),AnchorTimeIndex)=nan;
                continue
            end

            [a,AnchorFrame]=min(abs(AnchorTimes(AnchorTimeIndex)-Signal_Time));
            startFrame=AnchorFrame+PreFrame;
            endFrame=AnchorFrame+PostFrame-WindowSizeFrame;


            % for a time when we have -pretime
            if  startFrame < 0
                Mean_Signal(1:length(RelativeFrame),AnchorTimeIndex)=nan;
                continue
            end
            % if we dont have video filming frames at the end of session , it is vereyyyy rare but still hapened in 1 pg085 17/12/2022session
            if  length(Signal)<endFrame
                Mean_Signal(1:length(RelativeFrame),AnchorTimeIndex)=nan;
                continue
            end


            CuurentSignal=Signal(startFrame:endFrame);
            %  [Mean_Signal(:,AnchorTimeIndex)]=CuurentSignal;

            % to calculate moving average
            k=1;
            for ii=startFrame:WindowStepFrame:endFrame
                [Mean_Signal(k,AnchorTimeIndex)]=mean(Signal(ii:ii+WindowSizeFrame));
                k=k+1;
            end

        end


    end

end