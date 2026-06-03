%% =========================================================================
% Ghaderi2025_Figure1Sup_DeeplabCut.m
% =========================================================================
%
% This script generates Figure 1 Supplementary showing DeepLabCut movement traces
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script analyzes and plots individual trial movement traces
% using DeepLabCut data. It identifies trials with high neural activity and
% plots the corresponding movement signals (whisker speed, snout angle, jaw
% movement, and tongue movement) for individual trials.
%
% Dependencies:
%   - psth_10ms.mat (contains trial data)
%   - psth_sub_PG082_ses_20221113T145317.mat (contains session-specific data)
%   - tight_subplot.m (for subplot management)
%   - prettify_plot.m (for plot formatting)
%   - prettify_addScaleBars.m (for scale bar addition)
%
% Output: PDF figure showing individual trial movement traces with proper formatting
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc


%% Optional: Change figure name (set to 1 to enable)
change_name = 0;
newname = 'Figure3_1_2';
fullname = mfilename('fullpath');
inds = regexp(fullname, '\', 'all');
name = fullname(inds(end)+1:end);

if change_name
    movefile([name '.m'], [newname '.m']);
end

%% Load required data

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'psth_sub_PG082_ses_20221113T145317.mat'])

%% Find interesting sample trials based on neural activity

params.TrialType = [1];  % 1: gotone/whisker, 2: gotone/nowhisker, 3: nogotone/whisker, 4: nogotone/nowhisker, 5: notone/whisker
params.LickState = [1];  % 1: lick, 0: nolick
cnt_area = 0;
mean_fr = [];
regionlist = {'A1', 'wS1', 'wS2', 'wM2', 'ALM'};  % Brain regions to analyze
params.completion_state = 'completed_trials';  % Options: 'early_licks', 'completed_trials'

% Define analysis windows
win_area = {[.8, 1.1]};  % Response window
baseline = [-1, 0];       % Baseline window
WindowCenters = psth_mat_session(2).trial_timestamps;

% Calculate mean firing rates for each brain region
for ind_area = 1:length(regionlist)
    CurrentArea = cell2mat(regionlist(ind_area));
    ind_probe = find(strcmp(CurrentArea, [psth_mat_session.probe_location]));

    for ind_cond = 1:length(params.TrialType)
        Concatsig = [];
        ind_probe;

        Trial = psth_mat_session(ind_probe).trial_type;
        Lick = psth_mat_session(ind_probe).lick_flag;

        % Apply trial type and lick state filters
        IndTrialType = Trial == params.TrialType(ind_cond);
        IndLickstate = Lick == params.LickState(ind_cond);

        % Determine completion state based on early lick behavior
        switch params.completion_state
            case 'completed_trials'
                completion_state = ~psth_mat_session(ind_probe).early_lick;
            case 'early_licks'
                early_licks_all = psth_mat_session(ind_probe).early_lick;
                lick_time = 0 < (psth_mat_session(ind_probe).lick_time - psth_mat_session(ind_probe).start_time);
                completion_state = lick_time & early_licks_all;
        end

        % Find trials meeting all criteria
        CurrTrialInd = find([completion_state & IndLickstate & IndTrialType]);

        % Extract spike counts for selected trials
        CurrSp = psth_mat_session(ind_probe).spike_counts;
        CurrSp_CurrTrialInd = squeeze(mean(CurrSp(:, CurrTrialInd, :), 3));

        % Define response and baseline windows
        window = cell2mat(win_area(1));
        [~, b] = min(abs(WindowCenters - window(1)));
        t1 = b;
        [~, b] = min(abs(WindowCenters - window(2)));
        t2 = b;

        % Define baseline window
        [~, b] = min(abs(WindowCenters - baseline(1)));
        t1baseline = b;
        [~, b] = min(abs(WindowCenters - baseline(2)));
        t2baseline = b;

        % Calculate mean firing rate (response - baseline)
        means = mean(CurrSp_CurrTrialInd(t1:t2, :), 1) - mean(CurrSp_CurrTrialInd(t1baseline:t2baseline, :), 1);
        mean_fr(:, ind_area) = means';
    end % End condition loop
end % End area loop

% Sort trials by firing rate and select top trials
[~, bb] = sort(mean_fr(:, 1), 'descend');
BB = CurrTrialInd(bb);

%% Generate plots for individual trials
close all;

% Plot movement traces for top 10 trials

for trialnumbernumber = BB(1:10)'

    parent = figure('Position', [100 100 600 800]);


    % Create subplot with tight spacing
    h = tight_subplot(1, 1, [.02 .03], [.05 .05], [.1 .02]);
    axs = findall(gcf, 'type', 'axes');
    axs = flipud(axs);

    % Define analysis parameters
    params.QuietState = 'All_trials';  % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trials'
    params.BaselineSubtraction = 0;
    params.completion_state = 'completed_trials';  % Options: 'early_licks', 'completed_trials'
    params.TrialType = ([1]);  % 1: gotone/whisker, 2: gotone/nowhisker, 3: nogotone/whisker, 4: nogotone/nowhisker, 5: notone/whisker
    params.LickState = ([1]);  % 1: lick, 0: nolick
    trial_names = {'Go-tone Whisker', 'Go-tone', 'Nogo-tone Whisker', 'Nogo-tone', 'Whisker'};

    params.CellType = 'All';  % Options: 'RS', 'FS', 'RS_FS', 'All'
    regionlist = {'A1', 'wS1', 'wS2', 'wM2', 'ALM'};  % Brain regions to analyze

    % Time window parameters
    gaussiansmoothing = 1;
    t_start = -1;  % Start time (seconds)
    t_end = 2;    % End time (seconds)
    bin_width = 0.01;
    XTickLabel = {'-1'; '0'; '1'; '2'};
    xtick = [-1; 0; 1; 2];

    % Movement signal parameters
    movements_signals = {'whisker_speed', 'snout_angle', 'jaw_movement', 'tongue_movement'};  % Signals to plot
    movements_signals_tag = {'Whisker speed (pixel/s)', 'Snout angle (degree)', 'Jaw (pixel)', 'Tongue (pixel)'};

    % Processing parameters
    params.movement_baselineSubtraction = 1;
    params.movement_normalization = 0;

    % Color scheme
    colorcodes = ([0 0 1; 0 .5 1; 1 0 0; 1 .5 0; 0 0 0]);
    colors = {'#0008FF'; '#228B22'; '#FF0000'; '#000000'; '#A020F0'; '#FFD700'};
    areas = {'wS1'; 'wS2'; 'ALM'; 'wM2'; 'A1'; 'tjM1'};
    color_dic = table(areas, colors);

    % Y-axis shift for different signals
    shift_y_values = [-10, 10, 30, 85];
    params.BaselineSubtraction = 1;

    % Get probe locations for specified regions
    prblist = [];
    for iarea = 1:length(regionlist)
        CurrentArea = cell2mat(regionlist(iarea));
        prblist = [prblist, find(strcmp(regionlist(iarea), [psth_mat_session.probe_location]))];
    end

    % Get unique session IDs for movement plotting
    [unique_session_names, unique_session_ids] = unique([psth_mat_session(prblist).session_id]);

    % Plot movement signals for individual trial
    for ind_cond = 1:length(params.TrialType)
        for ind_signal = 1:length(movements_signals)
            Concatsig = [];
            current_signal_name = cell2mat(movements_signals(ind_signal));

            Trial = psth_mat_session(1).trial_type;
            Lick = psth_mat_session(1).lick_flag;

            % Apply trial type and lick state filters
            IndTrialType = Trial == params.TrialType(ind_cond);
            IndLickstate = Lick == params.LickState(ind_cond);

            % Determine completion state based on early lick behavior
            switch params.completion_state
                case 'completed_trials'
                    completion_state = ~psth_mat_session(1).early_lick;
                case 'early_licks'
                    early_licks_all = psth_mat_session(i).early_lick;
                    lick_time = 0 < (psth_mat_session(i).lick_time - psth_mat_session(i).start_time);
                    completion_state = lick_time & early_licks_all;
            end

            % Apply quiet state filter
            switch params.QuietState
                case 'Quiet_(whisker_speed)'
                    Qind = psth_mat_session(i).quiet_trial_whisker_speed;
                case 'Quiet_(jaw_movement)'
                    Qind = psth_mat_session(i).quiet_trial_jaw_movement;
                case 'Quiet_(jaw & whisker)'
                    Qind = psth_mat_session(i).quiet_trial_jaw_movement & psth_mat_session(i).quiet_trial_whisker_speed;
                case 'Non_quiet'
                    Qind = ~(psth_mat_session(i).quiet_trial_jaw_movement & psth_mat_session(i).quiet_trial_whisker_speed);
                case 'All_trials'
                    Qind = logical(ones(length(IndLickstate), 1));
            end

            % Find trials meeting all criteria
            CurrTrialInd = find([completion_state & IndLickstate & IndTrialType]);

            % Extract current movement signal
            CurrSignal = psth_mat_session(1).(current_signal_name);

            % Handle NaN values in tongue movement data
            if strcmp(current_signal_name, 'tongue_movement')
                for itrial = 1:size(CurrSignal, 2)
                    CurrSignal(find(isnan(CurrSignal(1:300, itrial))), itrial) = 0;
                end
            end

            % Select specific trial
            CurrSignal_CurrTrialInd = CurrSignal(:, trialnumbernumber(ind_cond));

            % Define baseline window for normalization
            WindowCenters = psth_mat_session(1).behaviour_timestamps;
            t1 = -1;
            t2 = 0;
            [~, b] = min(abs(WindowCenters - t1));
            baselineFirstBin = b;
            [~, b] = min(abs(WindowCenters - t2));
            baselineLastBin = b;

            % Apply gain to piezo lick trace for better visualization
            if strcmp(current_signal_name, 'piezo_lick_trace')
                CurrSignal_CurrTrialInd = CurrSignal_CurrTrialInd * 100;  % Add gain for small signals
            end

            % Calculate baseline statistics
            baseline_mean = repmat(nanmean(CurrSignal(baselineFirstBin:baselineLastBin, :), 1), size(CurrSignal, 1), 1);
            baseline_std = repmat(nanstd(CurrSignal_CurrTrialInd(1:300, :), 1), size(CurrSignal_CurrTrialInd, 1), 1);

            % Apply baseline subtraction if enabled
            if params.movement_baselineSubtraction
                CurrSignal_CurrTrialInd = CurrSignal_CurrTrialInd - baseline_mean(:, trialnumbernumber(ind_cond));
            end

            % Apply normalization if enabled
            if params.movement_normalization
                CurrSignal_CurrTrialInd = (CurrSignal_CurrTrialInd - baseline_mean) ./ baseline_std;
            end

            Concatsig = CurrSignal_CurrTrialInd;

            % Define plotting window
            [~, b] = min(abs(WindowCenters - t_start));
            Win(1) = b;
            [~, b] = min(abs(WindowCenters - t_end));
            Win(2) = b;

            % Extract data for plotting
            signal2plot = Concatsig(Win(1):Win(2), :);
            WindowCenters = WindowCenters(Win(1):Win(2));
            shift_y = shift_y_values(ind_signal);

            % Plot individual trial trace
            hold on;
            colorcode = colorcodes(ind_cond, :);
            meansig = signal2plot;
            hold(axs(1), 'on');
            plot(axs(1), WindowCenters, meansig + shift_y, 'color', 'k', 'linewidth', 1);

            % Add reference lines
            xline(axs(1), [0 1]);
            ylim(axs(1), [-30 150]);

            % Hide axes for cleaner appearance
            axs(1).YAxis.Visible = 'off';  % Remove y-axis
            axs(1).XAxis.Visible = 'off';  % Remove x-axis

            % Add signal label
            text(axs(1), -.9, mean(meansig(baselineFirstBin:baselineLastBin)) + 6 + shift_y, movements_signals_tag(ind_signal));
        end % End signal loop
    end % End condition loop

    % Add scale bars
    prettify_addScaleBars(.5, 20, '500 ms', '20', [], [], [], [], [], axs(1));

    % Apply plot formatting
    prettify_plot('LineThickness', 1, 'TickWidth', 1.5, 'AxisTightness', 'keep', 'TickLength', [.01 .001], 'PointSize', 4);

end % End trial loop

%% Export figures

directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

outputPDF = [directory name '.pdf'];

% Delete previous version if exists
if exist(outputPDF, 'file')
    delete(outputPDF);
end

% Get all figure handles
figHandles = findall(0, 'Type', 'figure');

% Sort them by figure number (optional)
[~, idx] = sort(arrayfun(@(f) f.Number, figHandles));
figHandles = figHandles(idx);

% Loop over each figure and export to PDF
for i = 1:length(figHandles)
    fig = figHandles(i);

    % Export to PDF and append
    exportgraphics(fig, outputPDF, 'ContentType', 'vector', 'Append', true);
end

disp(['All figures saved into: ', outputPDF]);