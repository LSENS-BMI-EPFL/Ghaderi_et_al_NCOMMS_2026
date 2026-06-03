%% =========================================================================
% Ghaderi2025_Figure1_MovementsTraceAllTrials.m
% =========================================================================
%
% This script generates Figure 1 showing movement traces for all trial types
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script plots movement traces (whisker speed, snout angle,
% piezo lick trace, jaw movement, and tongue movement) for all trial types
% across multiple brain regions. The traces are averaged across sessions and
% trials, with baseline subtraction and error shading for visualization.
%
% Dependencies:
%   - psth_10ms.mat (contains trial data)
%   - Area_list.mat (contains brain area information)
%   - tight_subplot.m (for subplot management)
%   - distinguishable_colors.m (for color generation)
%   - legend_just_txt.m (for legend formatting)
%   - prettify_plot.m (for plot formatting)
%   - prettify_addScaleBars.m (for scale bar addition)
%
% Output: PDF figure showing movement traces for all trial types with proper formatting
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc

%% Optional: Change figure name (set to 1 to enable)
change_name = 0;
newname = 'Figure3_4_1';
fullname = mfilename('fullpath');
inds = regexp(fullname, '\', 'all');
name = fullname(inds(end)+1:end);

if change_name
    movefile([name '.m'], [newname '.m']);
end

%% Load required data

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'psth_10ms.mat'])

%% Initialize figure and plotting parameters

parent = figure('Position', [100 100 600 800]);

% Create subplot with tight spacing
h = tight_subplot(1, 1, [.15 .15], [.1 .1], [.07 .01]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters
params.QuietState = 'All_trials';  % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trials'
params.BaselineSubtraction = 0;

params.completion_state = 'completed_trials';  % Options: 'early_licks', 'completed_trials'
params.TrialType = [1, 2, 3, 4, 5];  % 1: gotone/whisker, 2: gotone/nowhisker, 3: nogotone/whisker, 4: nogotone/nowhisker, 5: notone/whisker
params.LickState = [1, 0, 0, 0, 0];  % 1: lick, 0: nolick
params.CellType = 'All';  % Options: 'RS', 'FS', 'RS_FS', 'All'

% Brain regions to analyze
regionlist = {'A1', 'wM2', 'wS1', 'ALM', 'wS2'};  % Options: 'ALM', 'wM2', 'wS2', 'wS1', 'A1', 'tjM1'

% Time window parameters
t_start = -1;  % Start time (seconds)
t_end = 2;    % End time (seconds)
bin_width = 0.01;

% X-axis formatting
XTickLabel = {'-1'; '0'; '1'; '2'};
xtick = [-1; 0; 1; 2];

%% Movement signal parameters
movements_signals = {'tongue_movement', 'jaw_movement', 'whisker_speed'};  % Signals to plot : {'whisker_speed', 'snout_angle', 'piezo_lick_trace', 'jaw_movement', 'tongue_movement'}
movements_signals_tag = {'Tongue (pixel)', 'Jaw (pixel)', 'Whisker speed (pixel/s)'}; % Signal labels: {'Whisker speed (pixel/s)', 'Snout angle (degree)', 'Piezo lick (mv)', 'Jaw (pixel)', 'Tongue (pixel)'}

%%

% Processing parameters
params.movement_baselineSubtraction = 1;
params.movement_scaling = 1;


% Color scheme
colorcodes = [0 0 1; 0 .5 1; 1 0 0; 1 .5 0; 0 0 0];

% Y-axis shift for different signals
shift_y_values = [0, 10, 20, 30, 40];
Y_Scaling_values=[14, 22, 3, 1, 1];


%% Get probe locations for specified regions
prblist = [];
for iarea = 1:length(regionlist)
    CurrentArea = cell2mat(regionlist(iarea));
    prblist = [prblist, find(strcmp(regionlist(iarea), [psth_mat.probe_location]))];
end

% Get unique session IDs for movement plotting
[unique_session_names, unique_session_ids] = unique([psth_mat(prblist).session_id]);

%% Plot movement signals
for ind_signal = 1:length(movements_signals)
    current_signal_name = cell2mat(movements_signals(ind_signal));

    for icond = 1:length(params.TrialType)
        Concatsig = [];

        % Process each session
        for i = unique_session_ids'
            Trial = psth_mat(i).trial_type;
            Lick = psth_mat(i).lick_flag;

            % Apply trial type and lick state filters
            IndTrialType = Trial == params.TrialType(icond);
            IndLickstate = Lick == params.LickState(icond);

            % Determine completion state based on early lick behavior
            switch params.completion_state
                case 'completed_trials'
                    completion_state = ~psth_mat(i).early_lick;
                case 'early_licks'
                    early_licks_all = psth_mat(i).early_lick;
                    lick_time = 0 < (psth_mat(i).lick_time - psth_mat(i).start_time);
                    completion_state = lick_time & early_licks_all;
            end

            % Apply quiet state filter
            switch params.QuietState
                case 'Quiet_(whisker_speed)'
                    Qind = psth_mat(i).quiet_trial_whisker_speed;
                case 'Quiet_(jaw_movement)'
                    Qind = psth_mat(i).quiet_trial_jaw_movement;
                case 'Quiet_(jaw & whisker)'
                    Qind = psth_mat(i).quiet_trial_jaw_movement & psth_mat(i).quiet_trial_whisker_speed;
                case 'Non_quiet'
                    Qind = ~(psth_mat(i).quiet_trial_jaw_movement & psth_mat(i).quiet_trial_whisker_speed);
                case 'All_trials'
                    Qind = ones(length(IndLickstate), 1);
            end

            % Combine all trial selection criteria
            CurrTrialInd = [Qind & completion_state & IndLickstate & IndTrialType];

            % Extract current movement signal
            CurrSignal = psth_mat(i).(current_signal_name);

            % Handle NaN values in tongue movement data
            if strcmp(current_signal_name, 'tongue_movement')
                for itrial = 1:size(CurrSignal, 2)
                    CurrSignal(find(isnan(CurrSignal(1:300, itrial))), itrial) = 0;
                end
            end

            % Select trials based on criteria
            CurrSignal_CurrTrialInd = CurrSignal(:, CurrTrialInd);

            % Define baseline window for normalization
            WindowCenters = psth_mat(i).trial_timestamps;
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
                CurrSignal_CurrTrialInd = CurrSignal_CurrTrialInd - baseline_mean(:, CurrTrialInd);
            end


            % Concatenate signals across sessions
            Concatsig = [Concatsig, nanmean(CurrSignal_CurrTrialInd,2)];

         

        end % End of session loop

        % Define plotting window
        [~, b] = min(abs(WindowCenters - t_start));
        Win(1) = b;
        [~, b] = min(abs(WindowCenters - t_end));
        Win(2) = b;

        % Extract data for plotting
        signal2plot = Concatsig(Win(1):Win(2), :);
        time2plot = WindowCenters(Win(1):Win(2));

        All_Sessions.(current_signal_name){icond,1}=signal2plot;

        % Apply y-axis shift for signal separation
        shift_y = shift_y_values(ind_signal);
        colorcode = colorcodes(icond, :);

        % Calculate mean and standard error
        meansig = nanmean(signal2plot, 2);
        semsig = nanstd(signal2plot, [], 2) ./ sqrt(size(signal2plot, 2));

        if params.movement_scaling
            meansig=meansig./Y_Scaling_values(ind_signal)*8;
            semsig=semsig./Y_Scaling_values(ind_signal)*8;
        end

        % Create error shading
        curve1 = meansig + semsig;
        curve2 = meansig - semsig;
        x2 = [time2plot', fliplr(time2plot')];
        inBetween = [curve1', fliplr(curve2')];

        % Plot error shading and mean line
        fill(h(1), x2, inBetween + shift_y, colorcode, 'FaceAlpha', 0.2, 'LineStyle', 'none');
        hold(h(1), 'on');
        plot(h(1), time2plot, meansig + shift_y, 'color', colorcode, 'linewidth', 1);

        % Store number of trials for legend
        numberoftrials{icond, 1} = num2str(size(signal2plot, 2));

    end % End condition loop

    % Add signal label
    text(axs(1), -.9, mean(meansig(baselineFirstBin:baselineLastBin)) + 6 + shift_y, movements_signals_tag(ind_signal));

end % End signal loop

%% Add reference lines and format plot

% Add stimulus onset and offset lines
xline(axs(1), 0);
xline(axs(1), 1);

% Set axis labels
xlabel(h(1), 'Time (s)');
ylabel(h(1), 'Movements (a.u)');

% Set x-axis ticks and labels
xticks(h(1), xtick);
xticklabels(h(1), XTickLabel);
yticklabels(get(h(1), 'YTick'));

% Add legend
legend_just_txt(axs(1), {'Gotone+Whisker', 'Gotone', 'Nogotone+Whisker', 'Nogotone', 'Whisker'}, ...
    'Xoffset', 0, 'Yoffset', 56, 'relX', 0, 'relY', 0.02,'type','line');

% Add scale bars
prettify_addScaleBars(.5, 5, '500 ms', '5', [], [], [], [], [], axs(1));

% Apply plot formatting
prettify_plot('LineThickness', 1, 'AxisTightness', 'keep', 'TickLength', [.03 .003], ...
    'PointSize', 3, 'GeneralFontSize', 12);


%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');






