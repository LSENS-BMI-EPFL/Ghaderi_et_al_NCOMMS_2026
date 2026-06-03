
function behavior_table=nwb_findQuietTrial(behavior_table,params)

currwincenter=behavior_table.trial_timestamps;

[a,b]=min(abs(currwincenter-params.prewhisk_window(1))),prewin(1)=(b)
[a,b]=min(abs(currwincenter-params.prewhisk_window(2))),prewin(2)=(b)

[a,b]=min(abs(currwincenter-params.baseline_window(1))),basewin(1)=(b)
[a,b]=min(abs(currwincenter-params.baseline_window(2))),basewin(2)=(b)

curr_quiet_ind=[];
for sig=1:length(params.movement_signals)
    curr_signal_name=cell2mat(params.movement_signals(sig))
    curr_signal=behavior_table.(curr_signal_name);
    curr_quiet_ind=logical(zeros(size(curr_signal,2),1))
    baselinevalue=(nanmean((curr_signal(basewin(1):basewin(2),:)),1));
    prewhiskvalue=(nanmean((curr_signal(prewin(1):prewin(2),:)),1));
    % setting thereshold based on baseline for all
    % trials , even early licks
    TH=[nanmedian(baselinevalue),nanmedian(baselinevalue)+mad(baselinevalue),nanmedian(baselinevalue)+2*mad(baselinevalue)]
    thereshold=TH(2)
    % select each trials based on TH value or compare
    % each trial basel line with prewhisk
    switch params.selectin_method
        case 'one_by_one'
            ind_quiete=prewhiskvalue' <= (1)*baselinevalue';   % each trial basel line with prewhisk
        case 'mad_all'   %select each trials based on TH value
            ind_quiete=prewhiskvalue<=thereshold;
    end
    curr_quiet_ind(ind_quiete)=1;
    behavior_table.(['quiet_trial_' curr_signal_name])=curr_quiet_ind;
end


