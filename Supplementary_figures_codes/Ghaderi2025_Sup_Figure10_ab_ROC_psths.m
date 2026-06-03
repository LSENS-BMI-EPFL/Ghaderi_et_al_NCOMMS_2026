%% =========================================================================
% Ghaderi2025_Figure5_Sup1_roc_psths.m
% =========================================================================
%
% This script generates Figure 5Sup1 showing ROC analysis and PSTH plots
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script creates PSTH plots showing neural activity for positive and negative
% modulated cells across different brain areas. It analyzes firing rates during different trial
% conditions and plots them with error shading for statistical visualization.
%
% Dependencies:
%   - Area_list.mat (contains brain area information)
%   - psth_10ms.mat (contains trial data)
%   - Roc_hit_cr3.mat (contains ROC analysis results)
%   - tight_subplot.m (for subplot management)
%   - legend_just_txt.m (for legend creation)
%   - prettify_plot.m (for plot formatting)
%   - hex2rgb.m (for color conversion)
%
% Output: PDF figure showing ROC analysis and PSTH plots
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc

%% Optional: Change figure name (set to 1 to enable)
change_name = 0;
newname = 'Figure4A_ROC_PSTH_Combined';
fullname = mfilename('fullpath');
inds = regexp(fullname, '\', 'all');
name = fullname(inds(end)+1:end);

if change_name
    movefile([name '.m'], [newname '.m']);
end

%% Load required data

CurrentDir=pwd;
directory=CurrentDir;

load([directory filesep 'processed_data' filesep 'psth_10ms.mat'])
load([directory filesep 'processed_data' filesep 'Roc_hit_cr3.mat']) 

%% Initialize main figure

parent = figure('Position', [100 100 800 1000]);

% Create subplot layout (5 rows, 2 columns)
h = tight_subplot(5, 2, [.08 .08], [.05 .05], [.07 .01]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters
params.BaselineSubtraction = 0;
ind_window = 1;  % 1: 200 ms pre whisk, 2: 20 ms after whisk
params.CellType = 'All';  % Options: 'RS', 'FS', 'RS_FS', 'All'
regionlist = {'A1', 'wS1', 'wS2', 'wM2', 'ALM'};  % Brain regions

% Time window parameters
t_start = -1;  % Start time
t_end = 2;     % End time
bin_width = 0.01;

% Color scheme for plotting
color_map = {'#FF00FF'; '#0008FF'; '#00FF00'; '#000000'; '#ff0000'};
colortype = {'A1'; 'wS1'; 'wS2'; 'wM2'; 'ALM'};
map = horzcat(colortype, color_map);

% Convert hex colors to RGB
for i = 1:5
    color_map_rgb(i, :) = hex2rgb(color_map(i));
end

colorcode = [0 0 1; 1 0 0];
params.colormap = {'#0008FF'; '#228B22'; '#00C3FF'; '#FF0000'; '#FF7F00'; '#000000'; '#00C3FF'; '#FF7F00'; '#FF7F00'; '#808080'; '#6B3686'; '#74B99A'; '#A020F0'; '#FFD700'};
params.colortype = {'wS1'; 'wS2'; 'CR2'; 'ALM'; 'CR4'; 'wM2'; 'FA2'; 'FA3'; 'FA4'; 'FA5'; 'Lick'; 'NoLick'; 'A1'; 'tjM1'};
params.Map = horzcat(params.colortype, params.colormap);

%% Process each brain area

for ind_area = 1:length(regionlist)

    CurrentArea = cell2mat(regionlist(ind_area));
    probe_list = find(strcmp(CurrentArea, [psth_mat.probe_location]));
    
    % Initialize data containers
    concat_pval = [];
    concat_roc = [];
    concat_hit = [];
    concat_cr3 = [];
    concat_cellclass = [];
    
    % Process each probe in current area
    for ind_probe = probe_list

        % Apply cell type filter

        switch params.CellType
            case 'RS'
                CurrCellInd = psth_mat(ind_probe).unit_rsUnits;
            case 'FS'
                CurrCellInd = psth_mat(ind_probe).unit_fsUnits;
            case 'RS_FS'
                CurrCellInd = (psth_mat(ind_probe).unit_fsUnits | psth_mat(ind_probe).unit_rsUnits);
            case 'All'
                CurrCellInd = logical(ones(length(psth_mat(ind_probe).unit_rsUnits), 1));
        end
        
        % Get ROC analysis results

        current_roc = roc_mat(ind_probe).discrimination_index(:, ind_window);
        curent_pvalue = roc_mat(ind_probe).pvalue(:, ind_window);
        
        % Define trial conditions

        Trial = psth_mat(ind_probe).trial_type;
        Lick = psth_mat(ind_probe).lick_flag;
        completion_state = ~psth_mat(ind_probe).early_lick;
        
        % Apply quiet state filter

        Qind = psth_mat(ind_probe).quiet_trial_jaw_movement & psth_mat(ind_probe).quiet_trial_whisker_speed;
        
        % Define trial indices

        hit_ind = [(Qind) & (completion_state) & (Trial == 1) & (Lick == 1)];
        cr3_ind = [(Qind) & (completion_state) & (Trial == 3) & (Lick == 0)];
        
        % Extract spike counts
        current_sc = psth_mat(ind_probe).spike_counts;
        current_sc_hit = squeeze(mean(current_sc(:, hit_ind, :), 2));
        current_sc_cr3 = squeeze(mean(current_sc(:, cr3_ind, :), 2));
        
        % Filter for specified cell types
        current_roc_cell = current_roc(CurrCellInd);
        current_pval_cell = curent_pvalue(CurrCellInd);
        
        % Concatenate data across probes
        concat_pval = [concat_pval; curent_pvalue];
        concat_roc = [concat_roc; current_roc];
        concat_hit = [concat_hit, current_sc_hit];
        concat_cr3 = [concat_cr3, current_sc_cr3];

    end % End of probe loop
    
    % Identify positive and negative modulated cells

    ind_pos = [(0 < concat_roc) & (concat_pval <= 0.05)];
    ind_neg = [(concat_roc < 0) & (concat_pval <= 0.05)];
    x = [sum(ind_pos) sum(ind_neg) sum(~(ind_neg | ind_pos))];
    
    time2plot = psth_mat(ind_probe).trial_timestamps;
    
    % Plot positive modulated cells (Left column - odd indices: 1,3,5,7,9)

    ax_pos = axs(2*ind_area - 1);
    
    % Plot hit trials (positive)

    signal2plot = concat_hit(:, ind_pos) / bin_width;  % Convert to Hz
    meansig = nanmean(signal2plot, 2);
    semsig = nanstd(signal2plot, [], 2) ./ sqrt(size(signal2plot, 2));
    curve1 = meansig + semsig;
    curve2 = meansig - semsig;
    x2 = [time2plot', fliplr(time2plot')];
    inBetween = [curve1', fliplr(curve2')];
    
    fill(ax_pos, x2, inBetween, colorcode(1, :), 'FaceAlpha', 0.2, 'LineStyle', 'none');
    hold(ax_pos, 'on');
    plot(ax_pos, time2plot, meansig, 'color', colorcode(1, :), 'linewidth', 1);
    text(ax_pos, .1, 0.9, [num2str(size(signal2plot, 2)) ' cells'], 'Units', 'normalized');
    
    % Plot cr3 trials (positive)

    signal2plot = concat_cr3(:, ind_pos) / bin_width;  % Convert to Hz
    meansig = nanmean(signal2plot, 2);
    semsig = nanstd(signal2plot, [], 2) ./ sqrt(size(signal2plot, 2));
    curve1 = meansig + semsig;
    curve2 = meansig - semsig;
    x2 = [time2plot', fliplr(time2plot')];
    inBetween = [curve1', fliplr(curve2')];
    
    fill(ax_pos, x2, inBetween, colorcode(2, :), 'FaceAlpha', 0.2, 'LineStyle', 'none');
    hold(ax_pos, 'on');
    plot(ax_pos, time2plot, meansig, 'color', colorcode(2, :), 'linewidth', 1);
    xline(ax_pos, [0, 1]);

     if (2*ind_area - 1)==9
        xlabel(ax_pos, 'Time (s)');
     end

    ylabel(ax_pos, 'Firing rate (Hz)');
    title(ax_pos, [CurrentArea ' - Positive']);
    
    % Plot negative modulated cells (Right column - even indices: 2,4,6,8,10)

    ax_neg = axs(2*ind_area);
    
    % Plot hit trials (negative)

    signal2plot = concat_hit(:, ind_neg) / bin_width;  % Convert to Hz
    meansig = nanmean(signal2plot, 2);
    semsig = nanstd(signal2plot, [], 2) ./ sqrt(size(signal2plot, 2));
    curve1 = meansig + semsig;
    curve2 = meansig - semsig;
    x2 = [time2plot', fliplr(time2plot')];
    inBetween = [curve1', fliplr(curve2')];
    
    fill(ax_neg, x2, inBetween, colorcode(1, :), 'FaceAlpha', 0.2, 'LineStyle', 'none');
    hold(ax_neg, 'on');
    plot(ax_neg, time2plot, meansig, 'color', colorcode(1, :), 'linewidth', 1);
    text(ax_neg, .1, 0.9, [num2str(size(signal2plot, 2)) ' cells'], 'Units', 'normalized');
    
    % Plot cr3 trials (negative)

    signal2plot = concat_cr3(:, ind_neg) / bin_width;  % Convert to Hz
    meansig = nanmean(signal2plot, 2);
    semsig = nanstd(signal2plot, [], 2) ./ sqrt(size(signal2plot, 2));
    curve1 = meansig + semsig;
    curve2 = meansig - semsig;
    x2 = [time2plot', fliplr(time2plot')];
    inBetween = [curve1', fliplr(curve2')];
    
    fill(ax_neg, x2, inBetween, colorcode(2, :), 'FaceAlpha', 0.2, 'LineStyle', 'none');
    hold(ax_neg, 'on');
    plot(ax_neg, time2plot, meansig, 'color', colorcode(2, :), 'linewidth', 1);
    xline(ax_neg, [0, 1]);

    if (2*ind_area)==10
        xlabel(ax_neg, 'Time (s)');
    end

    ylabel(ax_neg, 'Firing rate (Hz)');
    title(ax_neg, [CurrentArea ' - Negative']);

end % End of area loop

%% Set y-limits for each subplot
ylim(axs(1), [0 35]);   % A1 positive
ylim(axs(2), [0 20]);   % A1 negative
ylim(axs(3), [0 35]);   % wS1 positive
ylim(axs(4), [0 20]);   % wS1 negative
ylim(axs(5), [0 35]);   % wS2 positive
ylim(axs(6), [0 20]);   % wS2 negative
ylim(axs(7), [0 35]);   % wM2 positive
ylim(axs(8), [0 8]);    % wM2 negative
ylim(axs(9), [0 35]);   % ALM positive
ylim(axs(10), [0 8]);   % ALM negative

%% Add legend to the first subplot
legend_just_txt(axs(1), {'Go-tone whisker', 'Nogo-tone whisker'}, 'Xoffset', 0, 'Yoffset', 20, 'relX', 0, 'relY', 0.08, 'type', 'line');

%% Apply final plot formatting
prettify_plot('LineThickness', 1, 'TickWidth', 1.5, 'AxisTightness', 'keep', 'TickLength', [.01 .001], 'PointSize', 4);

%% Export figure
directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');

