%% =========================================================================
% Ghaderi2025_Figure3B_PSTH_brainareas.m
% =========================================================================
% 
% This script generates Figure 3B showing PSTH (Peri-Stimulus Time Histogram) across brain areas
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making" 
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script creates PSTH plots showing neural activity across different 
% brain areas and trial types. It analyzes firing rates during different trial periods 
% and plots them with error shading for statistical visualization.
%
% Dependencies: 
%   - psth_10ms.mat (contains trial data)
%   - Area_list.mat (contains brain area information)
%   - tight_subplot.m (for subplot management)
%   - prettify_plot.m (for plot formatting)
%   - legend_just_txt.m (for legend creation)
%
% Output: PDF figure showing PSTH plots across brain areas
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
load([directory filesep 'data_helpers' filesep 'Area_list.mat'])


%% Initialize main figure
% close all;
parent = figure('Units', 'centimeters', ...
               'Position', [1 1 35.7 18], ...
               'PaperType', 'A4', ...
               'PaperUnits', 'centimeters', ...
               'PaperSize', [35.7 18], ...
               'PaperPosition', [1 1 35.7 18]);

% Create subplot layout (5 rows, 1 column)
h = tight_subplot(1, 5, [.1 .1], [.1 .1], [.1 .1]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters
params.QuietState = 'Quiet_(jaw & whisker)';  % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trials'
params.BaselineSubtraction = 0;
params.completion_state = 'completed_trials';  % Options: 'early_licks', 'completed_trials'
params.TrialType = [1, 2, 3, 4, 5];  % 1: gotone/whisker, 2: gotone/nowhisker, 3: nogotone/whisker, 4: nogotone/nowhisker, 5: notone/whisker
params.LickState = [1, 0, 0, 0, 0];  % 1: lick, 0: nolick
params.CellType = 'All';  % Options: 'RS', 'FS', 'RS_FS', 'All'
regionlist = {'A1', 'wS1', 'wS2', 'wM2', 'ALM'};  % Brain regions

% Time window parameters
t_start = -0.1;  % Start time
t_end = 0.2;     % End time
bin_width = 0.01;
XTickLabel = {'-0.1';'0';'0.1';'0.2'};
xtick = [-0.1; 0; 0.1; 0.2];

% Movement signal parameters
movements_signals = {'whisker_speed', 'snout_angle', 'piezo_lick_trace', 'jaw_movement', 'tongue_movement'};
movements_signals_tag = {'Whisker speed (pixel/s)', 'Snout angle (degree)', 'Piezo lick (mv)', 'Jaw (pixel)', 'Tongue (pixel)'};
params.movement_baselineSubtraction = 1;
params.movement_normalization = 0;

% Color scheme for plotting
colorcodes = [0 0 1; 0 .5 1; 1 0 0; 1 .5 0; 0 0 0;];
params.colormap = {'#0008FF'; '#228B22'; '#00C3FF'; '#FF0000'; '#FF7F00'; '#000000'; '#00C3FF'; '#FF7F00'; '#FF7F00'; '#808080'; '#6B3686'; '#74B99A'; '#A020F0'; '#FFD700'};
params.colortype = {'wS1'; 'wS2'; 'CR2'; 'ALM'; 'CR4'; 'wM2'; 'FA2'; 'FA3'; 'FA4'; 'FA5'; 'Lick'; 'NoLick'; 'A1'; 'tjM1'};
params.Map = horzcat(params.colortype, params.colormap);

% Y-axis shift values for different areas
shift_y_values = [-5, 10, 20, 40, 65];

%% Process each brain area
cnt_area = 0;

for iarea = 1:length(regionlist)
    CurrentArea = cell2mat(regionlist(iarea));
    iprb = find(strcmp(CurrentArea, [psth_mat.probe_location]));
    
    % Process each trial condition
    for icond = 1:length(params.TrialType)
        Concatsig = [];
        
        % Process each probe in current area
        for i = iprb
            Trial = psth_mat(i).trial_type;
            Lick = psth_mat(i).lick_flag;
            
            % Apply trial type filter
            IndTrialType = Trial == params.TrialType(icond);
            IndLickstate = Lick == params.LickState(icond);
            
            % Determine completion state
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
            
            CurrTrialInd = [Qind & completion_state & IndLickstate & IndTrialType];
            
            % Apply cell type filter
            switch params.CellType
                case 'RS'
                    CelltypeInd = psth_mat(i).unit_rsUnits;
                case 'FS'
                    CelltypeInd = psth_mat(i).unit_fsUnits;
                case 'RS_FS'
                    CelltypeInd = (psth_mat(i).unit_fsUnits | psth_mat(i).unit_rsUnits);
                case 'All'
                    CelltypeInd = logical(ones(length(psth_mat(i).unit_rsUnits), 1));
            end
            
            % Apply CCF filter on cell location
            ind_ccf_filter = ismember(psth_mat(i).unit_ccf_location, area_list.(CurrentArea));
            CurrCellInd = (CelltypeInd & ind_ccf_filter);
            
            %% Calculate PSTH for current condition
            % Get current spike counts
            CurrSp = psth_mat(i).spike_counts;
            
            % Average over specific trial conditions
            CurrSp_CurrTrialInd = squeeze(nanmean(CurrSp(:, CurrTrialInd, :), 2));
            
            % Filter for specified cell types
            CurrSp_CurrTrialInd_CurrCellInd = CurrSp_CurrTrialInd(:, CurrCellInd);
            
            % Calculate baseline
            WindowCenters = psth_mat(i).trial_timestamps;
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
        
        %% Plot PSTH for current condition
        % Define plotting window
        [a, b] = min(abs(WindowCenters - t_start)); Win(1) = (b);
        [a, b] = min(abs(WindowCenters - t_end)); Win(2) = (b);
        
        signal2plot = Concatsig(Win(1):Win(2), :);
        time2plot = WindowCenters(Win(1):Win(2));
        
        % Convert to Hz and apply y-axis shift
        signal2plot = signal2plot / bin_width;  % Convert to Hz
        colorcode = colorcodes(icond, :);
        
        % Calculate mean and standard error
        meansig = nanmean(signal2plot, 2);
        semsig = nanstd(signal2plot, [], 2) ./ sqrt(size(signal2plot, 2));
        
        % Create error shading
        curve1 = meansig + semsig;
        curve2 = meansig - semsig;
        x2 = [time2plot', fliplr(time2plot')];
        inBetween = [curve1', fliplr(curve2')];
        
        % Plot error shading and mean line
        fill(axs(iarea), x2, inBetween, colorcode, 'FaceAlpha', 0.2, 'LineStyle', 'none');
        hold(axs(iarea), 'on');
        plot(axs(iarea), time2plot, meansig, 'color', colorcode, 'linewidth', 1);
    end % End of condition loop
    
    %% Add formatting elements
    % Add reference lines
    xline(axs(iarea), 0);
    % xline(axs(iarea), 1);
    
    % Add labels and formatting
        xlabel(axs(iarea), 'Time (s)');

    text(axs(iarea), .5, .75, {[num2str(size(signal2plot, 2)) ' cells']}, 'Units', 'normalized');
    % xticks(axs(iarea), xtick);
    % xticklabels(axs(iarea), XTickLabel);
    title(axs(iarea), CurrentArea);
    cnt_area = cnt_area + 1;
end % End of area loop
    ylabel(axs(1), 'Firing rate (Hz)');

%% Add legend and final formatting
legend_just_txt(axs(5), {'Go-tone Whisker', 'Go-tone', 'Nogo-tone Whisker', 'Nogo-tone', 'Whisker'}, ...
                'Xoffset', .1, 'Yoffset', 8, 'relX', 0, 'relY', 0.15,'type','line');

% Add reference lines to first subplot
xline(axs(1), 0);
% xline(axs(1), 1);

%% Set y-axis limits for different areas
ylim(h(4), [0 8]);
ylim(h(5), [0 8]);
ylim(h(1), [0 12]);
ylim(h(3), [0 8]);
ylim(h(2), [0 8]);

% Format y-tick labels
% for i = 1:5
%     yticklabels(axs(i), get(axs(iarea), 'Ytick'));
% end

%% Apply final plot formatting
prettify_plot('LineThickness', 1, 'AxisTightness', 'keep', 'TickLength', [.01 .003], 'PointSize', 3, 'GeneralFontSize', 14);

%% Export figure

directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');





