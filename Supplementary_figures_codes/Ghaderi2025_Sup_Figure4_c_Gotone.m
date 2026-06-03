%% =========================================================================
% Ghaderi2025_Figure3Sup1_c_psth.m
% =========================================================================
%
% This script generates Figure 3Sup1C showing PSTH analysis and movement traces
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script creates PSTH plots showing neural activity across different
% brain areas and trial conditions, along with movement traces. It analyzes firing rates
% during different trial periods and plots them with error shading for statistical visualization.
%
% Dependencies:
%   - psth_10ms.mat (contains trial data)
%   - psth_sub_PG082_ses_20221113T145317.mat (contains session-specific trial data)
%   - Area_list.mat (contains brain area information)
%   - tight_subplot.m (for subplot management)
%   - legend_just_txt.m (for legend creation)
%   - prettify_plot.m (for plot formatting)
%   - prettify_addScaleBars.m (for scale bar addition)
%   - bin_spike_counts.m (for spike count binning)
%   - hex2rgb.m (for color conversion)
%
% Output: PDF figure showing PSTH plots and movement traces
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

load([directory filesep 'processed_data' filesep 'psth_sub_PG082_ses_20221113T145317.mat'])
load([directory filesep 'data_helpers' filesep 'Area_list.mat'])

%% Initialize main figure

parent = figure('Position', [100 100 700 900]);

% Create subplot layout (3 rows, 1 column)
h = tight_subplot(2, 1, [0.05 .05], [.05 .05], [.08 .08]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters

params.QuietState = 'Quiet_(jaw & whisker)';  % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trials'
params.BaselineSubtraction = 1;
params.completion_state = 'completed_trials';  % Options: 'early_licks', 'completed_trials'
params.TrialType = [1];  % 1: gotone/whisker, 2: gotone/nowhisker, 3: nogotone/whisker, 4: nogotone/nowhisker, 5: notone/whisker
params.LickState = [1];  % 1: lick, 0: nolick
params.CellType = 'All';  % Options: 'RS', 'FS', 'RS_FS', 'All'
params.regionlist = {'A1', 'wS1', 'wS2', 'wM2', 'ALM'};  % Brain regions
params.Trial_names = {'Go-tone Whisker', 'Go-tone', 'Nogo-tone Whisker', 'Nogo-tone', 'Whisker'};


% Time window parameters
t_start = -1;  % Start time
t_end = 2;     % End time
bin_width = 0.01; % bin size in s
XTickLabel = {'-1'; '0'; '1'; '2'};
xtick = [-1; 0; 1; 2];

% Movement signal parameters
movements_signals = {'whisker_speed', 'snout_angle', 'piezo_lick_trace', 'jaw_movement', 'tongue_movement'};
movements_signals_tag = {'Whisker speed (pixel/s)', 'Snout angle (degree)', 'Piezo lick (mv)', 'Jaw (pixel)', 'Tongue (pixel)'};
params.movement_baselineSubtraction = 1;
params.movement_normalization = 0;

% Color scheme for plotting
colorcodes = [0 0 1; 1 0 0];
params.colormap = {'#0008FF'; '#228B22'; '#00C3FF'; '#FF0000'; '#FF7F00'; '#000000'; '#00C3FF'; '#FF7F00'; '#FF7F00'; '#808080'; '#6B3686'; '#74B99A'; '#A020F0'; '#FFD700'};
params.colortype = {'wS1'; 'wS2'; 'CR2'; 'ALM'; 'CR4'; 'wM2'; 'FA2'; 'FA3'; 'FA4'; 'FA5'; 'Lick'; 'NoLick'; 'A1'; 'tjM1'};
params.Map = horzcat(params.colortype, params.colormap);
shift_y_values = [-5, 10, 20, 40, 65];

%% Process each brain area for PSTH analysis

cnt_area = 0;

for iarea = 1:length(params.regionlist)

    CurrentArea = cell2mat(params.regionlist(iarea));
    iprb = find(strcmp(CurrentArea, [psth_mat_session.probe_location]));
    
    % Process each trial condition
    for icond = 1:length(params.TrialType)

        Concatsig = [];
        
        % Process each probe in current area
        for i = iprb

            Trial = psth_mat_session(i).trial_type;
            Lick = psth_mat_session(i).lick_flag;
            
            % Apply trial type filter
            IndTrialType = Trial == params.TrialType(icond);
            IndLickstate = Lick == params.LickState(icond);
            
            % Determine completion state
            switch params.completion_state
                case 'completed_trials'
                    completion_state = ~psth_mat_session(i).early_lick;
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
            
            CurrTrialInd = [Qind & completion_state & IndLickstate & IndTrialType];
            
            % Apply cell type filter
            switch params.CellType
                case 'RS'
                    CelltypeInd = psth_mat_session(i).unit_rsUnits;
                case 'FS'
                    CelltypeInd = psth_mat_session(i).unit_fsUnits;
                case 'RS_FS'
                    CelltypeInd = (psth_mat_session(i).unit_fsUnits | psth_mat_session(i).unit_rsUnits);
                case 'All'
                    CelltypeInd = logical(ones(length(psth_mat_session(i).unit_rsUnits), 1));
            end
            
            % Apply CCF filter on cell location
            ind_ccf_filter = ismember(psth_mat_session(i).unit_ccf_location, area_list.(CurrentArea));
            CurrCellInd = (CelltypeInd);
            
            % Calculate PSTH for current condition

            % Get current spike counts
            CurrSp = psth_mat_session(i).spike_counts;
            CurrSp = bin_spike_counts(CurrSp, bin_width*1000, 1);
            Number_of_trials=sum(CurrTrialInd);

            % Average over specific trial conditions
            CurrSp_CurrTrialInd = squeeze(nanmean(CurrSp(:, CurrTrialInd, :), 2));
            
            % Filter for specified cell types
            CurrSp_CurrTrialInd_CurrCellInd = CurrSp_CurrTrialInd(:, CurrCellInd);
            
            % Define time windows
            WindowCenters = [-0.99:bin_width:2]';
            
            % Calculate baseline

            t1 = -1;
            t2 = 0;
            [a, b] = min(abs(WindowCenters - t1)); baselineFirstBin = (b);
            [a, b] = min(abs(WindowCenters - t2)); baselineLastBin = (b);
            baseline_mean = repmat(mean(CurrSp_CurrTrialInd_CurrCellInd(baselineFirstBin:baselineLastBin, :), 1), size(CurrSp_CurrTrialInd_CurrCellInd, 1), 1);
            
            % Apply baseline subtraction if requested

            if params.BaselineSubtraction
                CurrSp_CurrTrialInd_CurrCellInd = CurrSp_CurrTrialInd_CurrCellInd - baseline_mean;
            end
            
            % Concatenate signals across probes
            Concatsig = [Concatsig, CurrSp_CurrTrialInd_CurrCellInd];

        end % End of probe loop
        
        % Plot PSTH for current condition

        % Define plotting window
        [a, b] = min(abs(WindowCenters - t_start)); Win(1) = (b);
        [a, b] = min(abs(WindowCenters - t_end)); Win(2) = (b);
        
        signal2plot = Concatsig(Win(1):Win(2), :);
        time2plot = WindowCenters(Win(1):Win(2));
        shiftin_y = 0;
        shift_y = shift_y_values(iarea);
        
        % Plot with error shading

        hold(axs(icond), 'on');
        ind_color = find(strcmp(CurrentArea, params.Map(:, 1)));
        
        signal2plot = signal2plot / bin_width;  % Convert to Hz
        Number_of_units=size(signal2plot, 2);
        meansig = nanmean(signal2plot, 2);
        semsig = nanstd(signal2plot, [], 2) ./ sqrt(size(signal2plot, 2));
        curve1 = meansig + semsig;
        curve2 = meansig - semsig;
        x2 = [time2plot', fliplr(time2plot')];
        inBetween = [curve1', fliplr(curve2')];
        
        fill(axs(icond), x2, inBetween, hex2rgb(cell2mat(params.Map(ind_color, 2))), 'FaceAlpha', 0.2, 'LineStyle', 'none');
        hold(axs(icond), 'on');
        plot(axs(icond), time2plot, meansig, 'color', hex2rgb(cell2mat(params.Map(ind_color, 2))), 'linewidth', 1);
        ylim(axs(icond), [-2 12]);

    end % End of condition loop
    
    cnt_area = cnt_area + 1;

end % End of area loop

%% Add formatting elements to PSTH plots

xline(axs(1), [0, 1]);
ylabel(axs(1), '\Delta Firing rate (Hz)');

xticks(axs(1), xtick);
xticklabels(axs(1), XTickLabel);

title(axs(1), 'Go-tone context');
yticklabels(axs(1), get(axs(1), 'YTick'));

legend_just_txt(axs(1), params.regionlist, 'Xoffset', -0.5, 'Yoffset', 10, 'relX', 0, 'relY', 0.085, 'type', 'line');
text(axs(1), 0.2, 10, ['n = ' num2str(Number_of_trials) ' trials'])

%% Plot movement signals
hold(axs(2), 'on');

% Get probe list for movement analysis
prblist = [];
for iarea = 1:length(params.regionlist)
    CurrentArea = cell2mat(params.regionlist(iarea));
    prblist = [prblist, find(strcmp(params.regionlist(iarea), [psth_mat_session.probe_location]))];
end

% Get unique session IDs for movement analysis
[unique_session_names, unique_session_ids] = unique([psth_mat_session(prblist).session_id]);

%% Process each movement signal

for ind_signal = 1:length(movements_signals)
    current_signal_name = cell2mat(movements_signals(ind_signal));
    
    % Process each trial condition
    for icond = 1:length(params.TrialType)
        Concatsig = [];
        
        % Process each session
        for i = unique_session_ids'
            Trial = psth_mat_session(i).trial_type;
            Lick = psth_mat_session(i).lick_flag;
            
            % Apply trial type filter
            IndTrialType = Trial == params.TrialType(icond);
            IndLickstate = Lick == params.LickState(icond);
            
            % Determine completion state
            switch params.completion_state
                case 'completed_trials'
                    completion_state = ~psth_mat_session(i).early_lick;
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
                    Qind = ones(length(IndLickstate), 1);
            end
            
            CurrTrialInd = [Qind & completion_state & IndLickstate & IndTrialType];
            
            % Process movement signal

            % Get current movement signal
            CurrSignal = psth_mat_session(i).(current_signal_name);
            
            % Handle special case for tongue movement
            if strcmp(current_signal_name, 'tongue_movement')
                for itrial = 1:size(CurrSignal, 2)
                    CurrSignal(find(isnan(CurrSignal(1:300, itrial))), itrial) = 0;
                end
            end
            
            CurrSignal_CurrTrialInd = CurrSignal(:, CurrTrialInd);
            
            % Define time windows

            WindowCenters = psth_mat_session(i).behaviour_timestamps;
            t1 = -1;
            t2 = 0;
            [a, b] = min(abs(WindowCenters - t1)); baselineFirstBin = (b);
            [a, b] = min(abs(WindowCenters - t2)); baselineLastBin = (b);
            
            % Apply gain for piezo lick trace
            if strcmp(current_signal_name, 'piezo_lick_trace')
                CurrSignal_CurrTrialInd = CurrSignal_CurrTrialInd * 100;  % Add gain for small signal
            end
            
            % Calculate baseline statistics
            baseline_mean = repmat(nanmean(CurrSignal(baselineFirstBin:baselineLastBin, :), 1), size(CurrSignal, 1), 1);
            baseline_std = repmat(nanstd(CurrSignal_CurrTrialInd(1:300, :), 1), size(CurrSignal_CurrTrialInd, 1), 1);
            
            % Apply baseline subtraction if requested
            if params.movement_baselineSubtraction
                CurrSignal_CurrTrialInd = CurrSignal_CurrTrialInd - baseline_mean(:, CurrTrialInd);
            end
            
            % Apply normalization if requested
            if params.movement_normalization
                CurrSignal_CurrTrialInd = (CurrSignal_CurrTrialInd - baseline_mean) ./ baseline_std;
            end
            
            % Concatenate signals across sessions
            Concatsig = [Concatsig, CurrSignal_CurrTrialInd];
        end % End of session loop
        
        % Plot movement signal

        [a, b] = min(abs(WindowCenters - t_start)); Win(1) = (b);
        [a, b] = min(abs(WindowCenters - t_end)); Win(2) = (b);
        signal2plot = Concatsig(Win(1):Win(2), :);
        time2plot = WindowCenters(Win(1):Win(2));
        shiftin_y = 0;
        shift_y = shift_y_values(ind_signal);
        colorcode = colorcodes(icond, :);
        
        % Calculate mean and standard error
        meansig = nanmean(signal2plot, 2);
        semsig = nanstd(signal2plot, [], 2) ./ sqrt(size(signal2plot, 2));
        curve1 = meansig + semsig;
        curve2 = meansig - semsig;
        x2 = [time2plot', fliplr(time2plot')];
        inBetween = [curve1', fliplr(curve2')];
        
        % Plot with error shading
        fill(axs(2), x2, inBetween + shift_y, colorcode, 'FaceAlpha', 0.2, 'LineStyle', 'none');
        hold(axs(2), 'on');
        plot(axs(2), time2plot, meansig + shift_y, 'color', colorcode, 'linewidth', 1);
        numberoftrials{icond, 1} = num2str(size(signal2plot, 2));

    end % End of condition loop
    
    % Add movement signal label
    text(axs(2), -.9, mean(meansig(baselineFirstBin:baselineLastBin)) + 6 + shift_y, movements_signals_tag(ind_signal));

end % End of signal loop

%% Add formatting elements to movement plot
xlabel(axs(2), 'Time (s)');
ylabel(axs(2), 'Movements (a.u)');
title(axs(2), 'Movements trace');
xline(axs(2), [0 1]);
xticks(axs(2), xtick);
xticklabels(axs(2), XTickLabel);
yticklabels(get(axs(2), 'YTick'));

axis(axs(2));
prettify_addScaleBars(.5, 20, '500 ms', '20', [], [], [], [], [], axs(2));

%% Apply final plot formatting
prettify_plot('LineThickness', 1, 'TickWidth', 1.5, 'AxisTightness', 'keep', 'TickLength', [.005 .005], 'PointSize', 4);

%% Export figure
directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '_psth.pdf'], 'ContentType', 'vector');

%% Initialize main figure

parent = figure('Position', [100 100 700 900]);

% Create subplot layout (6 rows, 1 column)
h = tight_subplot(6, 1, [.03 .03], [.05 .05], [.1 .02]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Trial to be plotted

trialnumber=204; % trial to be plotted

%% Define analysis parameters

% Movement signal parameters
movements_signals = {'tongue_movement'};
movements_signals_tag = {'Tongue (pixel)'};

% Color scheme
colorcodes = ([0 0 1; 0 .5 1; 1 0 0; 1 .5 0; 0 0 0;]);
colors = {'#A020F0'; '#0008FF'; '#228B22'; '#000000' ; '#FF0000'};
params.regionlist = {'A1'; 'wS1'; 'wS2'; 'wM2'; 'ALM'};
areas = params.regionlist;
color_dic = table(areas, colors);
shift_y_values = [0, 20, 20, 40, 80];

%%

% Process each brain area
cnt_area = 0;

for ind_area = 1:length(params.regionlist)

    CurrentArea = cell2mat(params.regionlist(ind_area));
    ind_probe = find(strcmp(CurrentArea, [psth_mat_session.probe_location]));
    base = 0;
    base2 = 0;

    % Process each trial condition

    for ind_cond = 1:length(params.TrialType)
        id_figure = ind_area;
        Concatsig = [];
        ind_probe;

        Trial = psth_mat_session(ind_probe).trial_type;
        Lick = psth_mat_session(ind_probe).lick_flag;

        % Apply trial type filter
        IndTrialType = Trial == params.TrialType(ind_cond);
        IndLickstate = Lick == params.LickState(ind_cond);

        % Determine completion state
        switch params.completion_state
            case 'completed_trials'
                completion_state = ~psth_mat_session(ind_probe).early_lick;
            case 'early_licks'
                early_licks_all = psth_mat_session(ind_probe).early_lick;
                lick_time = 0 < (psth_mat_session(ind_probe).lick_time - psth_mat_session(ind_probe).start_time);
                completion_state = lick_time & early_licks_all;
        end

        % Apply quiet state filter
        switch params.QuietState
            case 'Quiet_(whisker_speed)'
                Qind = psth_mat_session(ind_probe).quiet_trial_whisker_speed;
            case 'Quiet_(jaw_movement)'
                Qind = psth_mat_session(ind_probe).quiet_trial_jaw_movement;
            case 'Quiet_(jaw & whisker)'
                Qind = psth_mat_session(ind_probe).quiet_trial_jaw_movement & psth_mat_session(ind_probe).quiet_trial_whisker_speed;
            case 'Non_quiet'
                Qind = ~(psth_mat_session(ind_probe).quiet_trial_jaw_movement & psth_mat_session(ind_probe).quiet_trial_whisker_speed);
            case 'All_trials'
                Qind = logical(ones(length(IndLickstate), 1));
        end

        CurrTrialInd = find((completion_state & IndLickstate & IndTrialType));

        % Process neural data
        % Get current spike counts
        CurrSp = psth_mat_session(ind_probe).spike_counts;
        bin_sz = 0.01;
        CurrSp_10ms = bin_spike_counts(CurrSp, bin_sz*1000, 1);

        % Get data for specific trial
        CurrSp_CurrTrialInd = squeeze(CurrSp(:, trialnumber, :));
        CurrSp_CurrTrialInd_CurrCellInd = CurrSp_CurrTrialInd;

        % Sort cells by depth
        cell_depth = psth_mat_session(ind_probe).unit_ccf_depth;
        [a, b] = sort(cell_depth);
        CurrSp_CurrTrialInd_CurrCellInd = CurrSp_CurrTrialInd_CurrCellInd(:, b);

        % Create raster plot
        mat = CurrSp_CurrTrialInd_CurrCellInd .* repmat([1:1:size(CurrSp_CurrTrialInd_CurrCellInd, 2)], size(CurrSp_CurrTrialInd_CurrCellInd, 1), 1);
        mat(find(~mat)) = nan;
        WindowCenters = psth_mat_session(2).trial_timestamps;
        colorcode = hex2rgb(cell2mat(color_dic.colors(find(strcmp(CurrentArea, color_dic.areas)))));

        % Plot raster
        plot(h(id_figure), WindowCenters, base + mat, '.', 'color', colorcode, 'markersize', .5);
        hold(h(id_figure), 'on');
        axs(id_figure).XAxis.Visible = 'off';  % Remove x-axis

        % Add region label
        if ind_cond == 1
            text(axs(id_figure), -2, 50, [CurrentArea ' shank'], 'rotation', 90);
        end
        xline(axs(id_figure), [0 1]);

        % Calculate and plot PSTH
        signal2plot = (squeeze(CurrSp_10ms(:, trialnumber, :))) ./ bin_sz;
        WindowCenters = [-0.99:bin_sz:2]';

        % Calculate baseline
        t1 = -1;
        t2 = 0;
        [a, b] = min(abs(WindowCenters - t1)); baselineFirstBin = (b);
        [a, b] = min(abs(WindowCenters - t2)); baselineLastBin = (b);
        baseline_mean = repmat(mean(signal2plot(baselineFirstBin:baselineLastBin, :), 1), size(signal2plot, 1), 1);

        % Apply baseline subtraction if requested
        if params.BaselineSubtraction
            signal2plot = signal2plot - baseline_mean;
        end

        % Calculate mean and standard error
        meansig = nanmean(signal2plot, 2);
        semsig = nanstd(signal2plot, [], 2) ./ sqrt(size(signal2plot, 2));
        curve1 = meansig + semsig;
        curve2 = meansig - semsig;
        x2 = [WindowCenters', fliplr(WindowCenters')];
        inBetween = [curve1', fliplr(curve2')];

    end % End of condition loop

end % End of area loop

%% Plot movement signals

% Get probe list for movement analysis

prblist = [];
for iarea = 1:length(params.regionlist)
    CurrentArea = cell2mat(params.regionlist(iarea));
    prblist = [prblist, find(strcmp(params.regionlist(iarea), [psth_mat_session.probe_location]))];
end

% Get unique session IDs
[unique_session_names, unique_session_ids] = unique([psth_mat_session(prblist).session_id]);

%% Process each trial condition

for ind_cond = 1:length(params.TrialType)

    % Process each movement signal

    for ind_signal = 1:length(movements_signals)
        Concatsig = [];
        current_signal_name = cell2mat(movements_signals(ind_signal));

        Trial = psth_mat_session(1).trial_type;
        Lick = psth_mat_session(1).lick_flag;

        % Apply trial type filter
        IndTrialType = Trial == params.TrialType(ind_cond);
        IndLickstate = Lick == params.LickState(ind_cond);

        % Determine completion state
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

        CurrTrialInd = find([completion_state & IndLickstate & IndTrialType]);

        % Process movement signal
        
        CurrSignal = psth_mat_session(1).(current_signal_name); % Get current movement signal

        % Handle special case for tongue movement

        if strcmp(current_signal_name, 'tongue_movement')

            for itrial = 1:size(CurrSignal, 2)
                CurrSignal(find(isnan(CurrSignal(1:300, itrial))), itrial) = 0;
            end
        end

        CurrSignal_CurrTrialInd = CurrSignal(:, trialnumber(ind_cond));

        % Define time windows

        WindowCenters = psth_mat_session(1).behaviour_timestamps;
        t1 = -1;
        t2 = 0;
        [a, b] = min(abs(WindowCenters - t1)); baselineFirstBin = (b);
        [a, b] = min(abs(WindowCenters - t2)); baselineLastBin = (b);

        % Apply gain for piezo lick trace

        if strcmp(current_signal_name, 'piezo_lick_trace')
            CurrSignal_CurrTrialInd = CurrSignal_CurrTrialInd * 100;  % Add gain for small signal
        end

        % Calculate baseline statistics
        baseline_mean = repmat(nanmean(CurrSignal(baselineFirstBin:baselineLastBin, :), 1), size(CurrSignal, 1), 1);
        baseline_std = repmat(nanstd(CurrSignal_CurrTrialInd(1:300, :), 1), size(CurrSignal_CurrTrialInd, 1), 1);

        % Apply baseline subtraction if requested

        if params.movement_baselineSubtraction
            CurrSignal_CurrTrialInd = CurrSignal_CurrTrialInd - baseline_mean(:, trialnumber(ind_cond));
        end

        % Apply normalization if requested

        if params.movement_normalization
            CurrSignal_CurrTrialInd = (CurrSignal_CurrTrialInd - baseline_mean) ./ baseline_std;
        end

        Concatsig = CurrSignal_CurrTrialInd;

        % Plot movement signal

        [a, b] = min(abs(WindowCenters - t_start)); Win(1) = (b);
        [a, b] = min(abs(WindowCenters - t_end)); Win(2) = (b);
        signal2plot = Concatsig(Win(1):Win(2), :);
        WindowCenters = WindowCenters(Win(1):Win(2));
        shift_y = shift_y_values(ind_signal);

        hold on;
        colorcode = colorcodes(ind_cond, :);
        meansig = signal2plot;

        % Plot movement trace
        hold(axs(6), 'on');
        plot(axs(6), WindowCenters, meansig + shift_y, 'color', 'k', 'linewidth', 1);
        xline(axs(6), [0 1]);
        ylim(axs(6), [-30 100]);
        axs(6).YAxis.Visible = 'off';  % Remove y-axis
        axs(6).XAxis.Visible = 'off';  % Remove x-axis

        % Add movement signal label

        if ind_cond == 1
            text(axs(5), -2.5, mean(meansig(baselineFirstBin:baselineLastBin)) + 6 + shift_y, movements_signals_tag(ind_signal));
        end

    end % End of signal loop

end % End of condition loop

%% Add formatting elements

sgtitle([params.Trial_names(params.TrialType(ind_cond)) 'trial: ' num2str(trialnumber)]);
prettify_addScaleBars(.5, 20, '500 ms', '20', [], [], [], [], [], axs(6));
prettify_plot('LineThickness', 1, 'TickWidth', 1.5, 'AxisTightness', 'keep', 'TickLength', [.01 .001], 'PointSize', 4);

%% Export figure
directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '_raster.pdf'], 'ContentType', 'vector');



