%% =========================================================================
% Coding_direction_5ms.m
% =========================================================================
%
% This script calculates coding directions for different behavioral variables
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script computes coding directions for context, stimulus, and lick
% responses using 10ms time bins. It performs cross-validation, orthogonalized
% coding directions, and projects single-trial responses onto these directions.
%
% Dependencies:
%   - psth_10ms.mat (contains trial data with 10ms bins)
%   - area_list.mat (contains brain area information)
%   - fn_gram_Schmidt_process.m (for orthogonalization)
%
% Output: coding_direction_matrix.mat containing projections and indices
% =========================================================================

%% Initialize workspace and load data
clear all
close all
clc

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'psth_5ms.mat'])

load([directory filesep 'data_helpers' filesep 'Area_list.mat'])
load([directory filesep 'data_helpers' filesep 'Lick_times.mat'])


%% Define analysis parameters
% Trial selection and behavioral parameters
params.quietstate = 'Quiet_(jaw & whisker)';   % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trial'
params.completion_state = 'completed_trial';   % Options: 'early_licks', 'completed_trial'
params.trialType = [1, 2, 3, 4, 5,1, 2, 3, 4, 5];   % 1: gotone/whisker, 2: gotone/nowhisker, 3: nogotone/whisker, 4: nogotone/nowhisker, 5: notone/whisker
params.lickState = [1, 0, 0, 0, 0,0,1,1,1,1,];  % lick 1: lick, 0: nolick
params.celltype = 'All';           % Options: 'RS', 'FS', 'RS-FS', 'All'
params.regionlist = {'ALM', 'wM2', 'wS2', 'wS1', 'A1'};       % Brain regions to analyze
rng(0)
% Time window parameters
params.bin_width = 0.005;  % 10ms bins
params.XTickLabel = {'-1'; '0'; '1'; '2'};
params.xtick = [-1; 0; 1; 2];

% Analysis parameters
params.preTime = -1;
params.postTime = 2;
params.BinSize = 0.005;
params.BinStep = 0.005;
params.windowCenters = [-1 + params.BinSize:params.BinSize:2];

% Analysis windows for different behavioral periods
params.Win_context = [0.8, 1];      % Context coding direction window
% params.Win_lick = [1.4, 1.6];      % Lick coding direction window
params.Win_stim = [1.000, 1.03];       % Stimulus coding direction window
params.Win_base = [-1, 0];          % Baseline window for stimulus
params.Win_lick_after_4qc = [0, 0.1];  % Window after lick for quality check
params.Win_lick_before_4qc = [-1, 0];  % Window before lick for quality check

params.jaw_extract_window_4plot=[-1,1]
bout_dur=.5
params.lick_quality_ratio = 3;  % After/Before ratio threshold (mean_after should be > 1.2 * mean_before)


params.Win_lick = [0.2,0.5];  % 100ms
params.Win_nolick=[-1,-0.5]


% Set random seed for reproducibility
rng(0)

%% Define trial classification expressions
% Context classification (trial type 1 vs 3)
expr1 = 'Ind.Class1 = [(trial == 1 & lick == 1)];';   % Go-tone with whisker and lick
expr2 = 'Ind.Class2 = [(trial == 3 & lick == 0)];';   % No-go-tone with whisker, no lick

% Stimulus classification (trial type 5)
expr3 = 'Ind.Class3 = [(trial == 1 | trial == 3 | trial == 5)];';   % All trials with whisker stimulation
% expr3 = 'Ind.Class3 = [(trial == 5 & lick == 0)];';   % All trials with whisker stimulation



%% Main analysis loop across brain regions
for ind_area = 1:length(params.regionlist)
    current_area = cell2mat(params.regionlist(ind_area));
    probe_list = find(strcmp(current_area, [psth_mat.probe_location]));
    session_counter = 1;

    for i_prob = probe_list
        % Extract trial information
        trial = psth_mat(i_prob).trial_type;
        lick = psth_mat(i_prob).lick_flag ;       % changed here

        %% Determine trial completion status
        switch params.completion_state
            case 'completed_trial'
                completed_trial_ind = ~psth_mat(i_prob).early_lick;
            case 'early_licks'
                early_licks_all = psth_mat(i_prob).early_lick;
                lick_time = 0 < (psth_mat(i_prob).lick_time - psth_mat(i_prob).start_time);
                completed_trial_ind = lick_time & early_licks_all;
        end

        %% Determine quiet trial status
        switch params.quietstate
            case 'Quiet_(whisker_speed)'
                Qind = psth_mat(i_prob).quiet_trial_whisker_speed;
            case 'Quiet_(jaw_movement)'
                Qind = psth_mat(i_prob).quiet_trial_jaw_movement;
            case 'Quiet_(jaw & whisker)'
                Qind = psth_mat(i_prob).quiet_trial_jaw_movement & psth_mat(i_prob).quiet_trial_whisker_speed;
            case 'Non_quiet'
                Qind = ~(psth_mat(i_prob).quiet_trial_jaw_movement & psth_mat(i_prob).quiet_trial_whisker_speed);
            case 'All_trial'
                Qind = logical(ones(length(trial), 1));
        end

        %% Determine cell type filter
        switch params.celltype
            case 'RS'
                CelltypeInd = psth_mat(i_prob).unit_rsUnits;
            case 'FS'
                CelltypeInd = psth_mat(i_prob).unit_fsUnits;
            case 'RS-FS'
                CelltypeInd = (psth_mat(i_prob).unit_fsUnits | psth_mat(i_prob).unit_rsUnits);
            case 'All'
                CelltypeInd = logical(ones(length(psth_mat(i_prob).unit_rsUnits), 1));
        end

        % Apply CCF location filter
        ind_ccf_filter = ismember(psth_mat(i_prob).unit_ccf_location, area_list.(current_area));
        CurrCellInd = (CelltypeInd & ind_ccf_filter);

        % Skip sessions with insufficient cells
        if sum(CurrCellInd) < 5

            coding_direction_matrix.(current_area)(session_counter).lickproj = NaN;
            coding_direction_matrix.(current_area)(session_counter).Contextproj = NaN;
            coding_direction_matrix.(current_area)(session_counter).Stimproj = NaN;
            coding_direction_matrix.(current_area)(session_counter).index.Quiet = NaN;
            coding_direction_matrix.(current_area)(session_counter).index.lick = NaN;
            coding_direction_matrix.(current_area)(session_counter).index.trial = NaN;
            coding_direction_matrix.(current_area)(session_counter).index.completed_trial = NaN;
            coding_direction_matrix.(current_area)(session_counter).Error_Type = 1;
            session_counter=session_counter+1;
            continue
        end

        %% Extract current session data
        Currsig = psth_mat(i_prob).spike_counts;
        Currsig_CurrCellInd = Currsig(:, :, CurrCellInd);

        %% Evaluate classification expressions
        eval(expr1);
        eval(expr2);
        eval(expr3);


        % Apply quiet trial and completion filters
        Ind.Class1 = Ind.Class1 & Qind & completed_trial_ind;
        Ind.Class2 = Ind.Class2 & Qind & completed_trial_ind;
        Ind.Class3 = Ind.Class3 & Qind & completed_trial_ind;

        % Get trial indices for each class
        id1 = find(Ind.Class1);
        id2 = find(Ind.Class2);
        id3 = find(Ind.Class3);

        %% Perform cross-validation split (70% training, 30% testing)
        cv = cvpartition(size(id1, 1), 'HoldOut', 0.7); idx = cv.test; id1Train = id1(~idx, :); id1Test = id1(idx, :);
        cv = cvpartition(size(id2, 1), 'HoldOut', 0.7); idx = cv.test; id2Train = id2(~idx, :); id2Test = id2(idx, :);
        cv = cvpartition(size(id3, 1), 'HoldOut', 0.7); idx = cv.test; id3Train = id3(~idx, :); id3Test = id3(idx, :);

        %% Calculate coding directions for each time bin
        % Context coding direction
        CDcontext = [];
        for ind_bin = 1:size(Currsig_CurrCellInd, 1)
            X1 = squeeze(Currsig_CurrCellInd(ind_bin, id1Train, :));
            X2 = squeeze(Currsig_CurrCellInd(ind_bin, id2Train, :));
            CDcontext(ind_bin, :) = (mean(X1) - mean(X2));
        end

        %% Extract coding directions for specific time windows
     
        [~, b] = min(abs(params.windowCenters - params.Win_context(1))); WContextFirstBin = b;
        [~, b] = min(abs(params.windowCenters - params.Win_context(2))); WContextLasttBin = b;
        coding_direction_context = nanmean(CDcontext(WContextFirstBin:WContextLasttBin, :), 1);
        coding_direction_context = coding_direction_context ./ norm(coding_direction_context);

        % Lick coding direction (based on spontaneous licks)
        lick_times_all = lick_times(i_prob).lick_time;
        start_times = psth_mat(i_prob).start_time(:);

        % Get lick_mask if available (logical array indicating licking periods)
        lick_mask = lick_times(i_prob).lick_mask;
        video_timestamps = lick_times(i_prob).video_timestamp_continues;

        spontaneous_licks = [];
        n_outside_trials = 0;
        n_filtered_by_duration = 0;
        n_filtered_by_quality = 0;

        % Get jaw movement data for quality filtering
        jaw_continuous = lick_times(i_prob).jaw_movement_continues;
        time_continuous_jaw = lick_times(i_prob).video_timestamp_continues;


        for ilick = 1:length(lick_times_all)

            lick_t = lick_times_all(ilick);
            in_any_trial = false;
            for itrial = 1:length(start_times)
                if lick_t >= start_times(itrial) && lick_t <= (start_times(itrial) + 6)
                    in_any_trial = true;
                    break;
                end
            end

            % Check if lick is outside trials AND has lick_mask duration > 1 second
            if ~in_any_trial
                n_outside_trials = n_outside_trials + 1;
                lick_passes_duration_filter = false;

                % Additional filter: check lick_mask duration
                % if ~isempty(lick_mask) && ~isempty(video_timestamps)
                % Find the continuous lick bout around this lick time
                % lick_mask is a logical array aligned with video_timestamps
                [~, closest_idx] = min(abs(video_timestamps - lick_t));

                % Find the start and end of this lick bout
                bout_start = closest_idx;
                while bout_start > 1 && lick_mask(bout_start - 1)
                    bout_start = bout_start - 1;
                end

                bout_end = closest_idx;
                while bout_end < length(lick_mask) && lick_mask(bout_end + 1)
                    bout_end = bout_end + 1;
                end

                % Calculate bout duration
                bout_duration = video_timestamps(bout_end) - video_timestamps(bout_start);

                % Check if duration > threshold
                if bout_duration > bout_dur
                    lick_passes_duration_filter = true;
                else
                    n_filtered_by_duration = n_filtered_by_duration + 1;
                end
                % else
                %     % If no lick_mask available, include the lick anyway
                %     lick_passes_duration_filter = true;
                % end

                % Third filter: Check jaw movement quality (before vs after lick)
                lick_passes_quality_filter = false;
                if lick_passes_duration_filter %&& ~isempty(jaw_continuous) && ~isempty(time_continuous_jaw)
                    % Extract jaw movement before and after lick
                    before_window = [lick_t + params.Win_lick_before_4qc(1), lick_t + params.Win_lick_before_4qc(2)];
                    after_window = [lick_t + params.Win_lick_after_4qc(1), lick_t + params.Win_lick_after_4qc(2)];

                    % Find indices for before window
                    idx_before = find(time_continuous_jaw >= before_window(1) & time_continuous_jaw <= before_window(2));
                    % Find indices for after window
                    idx_after = find(time_continuous_jaw >= after_window(1) & time_continuous_jaw <= after_window(2));

                    % if ~isempty(idx_before) && ~isempty(idx_after)
                    mean_before = nanmean(jaw_continuous(idx_before));
                    mean_after = nanmean(jaw_continuous(idx_after));

                    % Check if after > ratio * before (indicating clear jaw opening)
                    if mean_after > params.lick_quality_ratio * mean_before
                        lick_passes_quality_filter = true;
                    else
                        n_filtered_by_quality = n_filtered_by_quality + 1;
                    end
                    % else
                    % If can't extract jaw data, pass this filter
                    % lick_passes_quality_filter = true;
                    % end
                else
                    % If no jaw data or didn't pass duration filter, use duration filter result
                    lick_passes_quality_filter = lick_passes_duration_filter;
                end

                if lick_passes_quality_filter
                    spontaneous_licks = [spontaneous_licks; lick_t];
                end

            end  % if outside trials
        end  % over spont lick

        % Print filtering statistics
        fprintf('    Session %d: Total licks=%d, Outside trials=%d, Filtered by duration=%d, Filtered by quality=%d, Final spontaneous licks=%d\n', ...
            session_counter, length(lick_times_all), n_outside_trials, n_filtered_by_duration, n_filtered_by_quality, length(spontaneous_licks));

        if length(spontaneous_licks) < 2

            coding_direction_matrix.(current_area)(session_counter).lickproj = NaN;
            coding_direction_matrix.(current_area)(session_counter).Contextproj = NaN;
            coding_direction_matrix.(current_area)(session_counter).Stimproj = NaN;
            coding_direction_matrix.(current_area)(session_counter).index.Quiet = NaN;
            coding_direction_matrix.(current_area)(session_counter).index.lick = NaN;
            coding_direction_matrix.(current_area)(session_counter).index.trial = NaN;
            coding_direction_matrix.(current_area)(session_counter).index.completed_trial = NaN;
            coding_direction_matrix.(current_area)(session_counter).Error_Type = 2;
            session_counter=session_counter+1;

            continue
        end

        spontaneous_licks_train = spontaneous_licks;
        unit_spike_times = psth_mat(i_prob).unit_spike_times;
        cell_indices = find(CurrCellInd);

        % Extract jaw movement data for this session
        if isfield(lick_times(i_prob), 'jaw_movement_continues')
            jaw_continuous = lick_times(i_prob).jaw_movement_continues;
            time_continuous = lick_times(i_prob).video_timestamp_continues;
        else
            jaw_continuous = [];
            time_continuous = [];
        end



        spike_counts_before_lick = [];
        spike_counts_after_lick = [];
        for ilick = 1:length(spontaneous_licks_train)
            lick_t = spontaneous_licks_train(ilick);

            % Extract jaw movement around this lick time
            % Find time window around lick: [lick_t - 0.2, lick_t + 1.0]
            jaw_win_start = lick_t + params.jaw_extract_window_4plot(1);
            jaw_win_end = lick_t + params.jaw_extract_window_4plot(2);

            % Find indices in continuous data
            jaw_idx = find(time_continuous >= jaw_win_start & time_continuous <= jaw_win_end);

            if ~isempty(jaw_idx)
                % Store jaw movement and corresponding time (using cell arrays for variable lengths)
                jaw_movement_matrix.(current_area)(session_counter).jaw_traces{ilick} = jaw_continuous(jaw_idx);
                jaw_movement_matrix.(current_area)(session_counter).jaw_time{ilick} = time_continuous(jaw_idx) - lick_t;  % Time relative to lick
                jaw_movement_matrix.(current_area)(session_counter).lick_times(ilick) = lick_t;
            end

            for iunit = 1:length(cell_indices)
                unit_idx = cell_indices(iunit);
                SpikeTimes = unit_spike_times{unit_idx};

                % Calculate PSTH around this lick [-0.1, 0] seconds
                PreTime = params.Win_lick(1);
                PostTime = params.Win_lick(2);
                [SpikeRates, ~, SpikeCounts] = PSTH_Simple(SpikeTimes, lick_t, PreTime, PostTime, params.BinSize, params.BinStep);

                % Average spike rate across the 100ms window
                % mean_rate = mean(SpikeRates);
                spike_counts_after_lick(:,ilick,iunit) = SpikeCounts;


                % Calculate PSTH around this lick [-0.1, 0] seconds
                PreTime = params.Win_nolick(1);
                PostTime = params.Win_nolick(2);
                [SpikeRates, ~, SpikeCounts] = PSTH_Simple(SpikeTimes, lick_t, PreTime, PostTime, params.BinSize, params.BinStep);

                spike_counts_before_lick(:,ilick,iunit) = SpikeCounts;


            end

        end

        % Calculate lick coding direction

        % should change to mean
        sum_spike_counts_after_lick=squeeze(mean(spike_counts_after_lick,1));
        sum_spike_counts_before_lick=squeeze(mean(spike_counts_before_lick,1));
        coding_direction_lick=nanmean(sum_spike_counts_after_lick)-nanmean(sum_spike_counts_before_lick);

        % Lick coding direction (already calculated above using spontaneous licks)
        coding_direction_lick = coding_direction_lick ./ norm(coding_direction_lick);

        % method 3
        [~, b] = min(abs(params.windowCenters - params.Win_stim(1))); WStimFirstBin = b;
        [~, b] = min(abs(params.windowCenters - params.Win_stim(2))); WStimLasttBin = b;
        [~, b] = min(abs(params.windowCenters - params.Win_base(1))); WBaseFirstBin = b;
        [~, b] = min(abs(params.windowCenters - params.Win_base(2))); WBaseLasttBin = b;
        sum_whisker=squeeze(sum(Currsig_CurrCellInd(WStimFirstBin:WStimLasttBin, :, :), 1));
        sum_baseline=squeeze(sum(Currsig_CurrCellInd(WBaseFirstBin:WBaseLasttBin, :, :), 1));
        coding_direction_stim=nanmean(sum_whisker(id3Train,:))-nanmean(sum_baseline(id3Train,:));

        coding_direction_stim = coding_direction_stim ./ norm(coding_direction_stim);

        %% Orthogonalize coding directions using Gram-Schmidt process
        % v = fn_gram_schmidt_process([coding_direction_context', coding_direction_stim', coding_direction_lick']);
        % coding_direction_context = v(:, 1)';
        % coding_direction_stim = v(:, 2)';
        % coding_direction_lick = v(:, 3)';

        % v = fn_gram_schmidt_process([coding_direction_stim', coding_direction_lick']);
        % coding_direction_stim = v(:, 1)';
        % coding_direction_lick = v(:, 2)';

        %% Project single trials onto coding directions
        % Context projection
       
        ProjContext = [];
        for itrial = 1:size(Currsig_CurrCellInd, 2)
            curr = squeeze(Currsig_CurrCellInd(:, itrial, :));
            ProjContext(:, itrial) = curr * coding_direction_context';
        end
        id_training_context = sort([id1Train; id2Train])';
        ProjContext(:, id_training_context) = nan;

        % Lick projection
        % Note: Lick CD is now based on spontaneous licks, not trials
        % So all trial projections are valid (no training trials to exclude)
        Projlick = [];
        for itrial = 1:size(Currsig_CurrCellInd, 2)
            curr = squeeze(Currsig_CurrCellInd(:, itrial, :));
            Projlick(:, itrial) = curr * coding_direction_lick';
        end
        % No trials to exclude since lick CD was trained on spontaneous licks

        % Stimulus projection
        ProjStim = [];
        for itrial = 1:size(Currsig_CurrCellInd, 2)
            curr = squeeze(Currsig_CurrCellInd(:, itrial, :));
            ProjStim(:, itrial) = curr * coding_direction_stim';
        end
        id_training_stim = sort([id3Train])';
        ProjStim(:, id_training_stim) = nan;

        %% Store results for current session
        coding_direction_matrix.(current_area)(session_counter).lickproj = [Projlick];
        coding_direction_matrix.(current_area)(session_counter).Contextproj = [ProjContext];
        coding_direction_matrix.(current_area)(session_counter).Stimproj = [ProjStim];
        coding_direction_matrix.(current_area)(session_counter).index.Quiet = [Qind];
        coding_direction_matrix.(current_area)(session_counter).index.lick = [lick];
        coding_direction_matrix.(current_area)(session_counter).index.trial = [trial];
        coding_direction_matrix.(current_area)(session_counter).index.completed_trial = [completed_trial_ind];
        coding_direction_matrix.(current_area)(session_counter).Error_Type = NaN;

        session_counter = session_counter + 1
    end
end

%% Prepare output variables
windowCenters = params.windowCenters;

%% Save results
directory=[CurrentDir filesep 'processed_data' filesep];
save([directory 'Coding_direction_SpontLick.mat'], "coding_direction_matrix", "windowCenters", "params");

