%% =========================================================================
% Ghaderi2025_Figure3C_roc_hit.m
% =========================================================================
% 
% This script generates Figure 3C showing ROC analysis for Hit trials across brain areas
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making" 
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script creates ROC analysis plots showing neural modulation across 
% different brain areas and trial periods. It analyzes discrimination indices, p-values, 
% and delta firing rates for positive, negative, and non-modulated cells.
%
% Dependencies: 
%   - psth_10ms.mat (contains trial data)
%   - Area_list.mat (contains brain area information)
%   - Modulation.mat (contains ROC analysis data)
%   - tight_subplot.m (for subplot management)
%   - prettify_plot.m (for plot formatting)
%
% Output: PDF figure showing ROC analysis results across brain areas
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
load([directory filesep 'processed_data' filesep 'Modulation.mat'])

%% Define analysis parameters
area_name = {'A1', 'wS1', 'wS2', 'wM2', 'ALM'};  % Brain areas
period_name = {'audio', 'delay', 'whisker', 'lick'};  % Trial periods

%% Initialize main figure

parent = figure('Position', [100 100 500 1000]);

% Create subplot layout (5 rows, 2 columns)
h = tight_subplot(5, 2, [.06 .06], [.1 .1], [.08 .08]);
axs = findall(gcf, 'type', 'axes');
area_ind = [1 2 3 4 5];
period_ind = [1 3];

ax_ind = [1:10];
ax_ind = reshape(ax_ind, [2, 5])';

axs = flipud(axs);
params.CellType = 'All';

% Colors for fractions and delta
mod_colors = [0 0 1; 1 0 0; 0.5 0.5 0.5];  % Blue, red, gray
period_colors = lines(4);  % Unique colors for 4 periods

%% Process each brain area
for ind_area = 1:length(area_name)
    % Initialize data containers for the current area
    fraction_data = zeros(length(period_name), 3);
    delta_means = zeros(length(period_name), 3);
    delta_errors = zeros(length(period_name), 3);
    current_area = cell2mat(area_name(ind_area));
    
    % Collect data across periods for this area
    for period = 1:length(period_name)
        % Gather modulation indices
        current_period = period_name{period};
        roc_data = modulation.(current_period).roc_mat;
        
        % Area-specific data extraction
        probe_indices = find(strcmp(current_area, [psth_mat.probe_location]));
        
        concat_discrimination_index = [];
        concat_pval = [];
        concat_roc_diff = [];
        
        % Process each probe in current area
        for probe = probe_indices
            % Apply cell type filter
            switch params.CellType
                case 'RS'
                    CelltypeInd = psth_mat(probe).unit_rsUnits;
                case 'FS'
                    CelltypeInd = psth_mat(probe).unit_fsUnits;
                case 'RS_FS'
                    CelltypeInd = (psth_mat(probe).unit_fsUnits | psth_mat(probe).unit_rsUnits);
                case 'All'
                    CelltypeInd = logical(ones(length(psth_mat(probe).unit_rsUnits), 1));
            end
            
            % Apply CCF filter on cell location
            ind_ccf_filter = ismember(psth_mat(probe).unit_ccf_location, area_list.(current_area));
            current_cell_ind = (CelltypeInd & ind_ccf_filter);
            
            % Extract discrimination indices, p-values, and deltas
            roc_diff = roc_data(probe).diff_fr(current_cell_ind);
            disc_index = roc_data(probe).discrimination_index(current_cell_ind);
            p_values = roc_data(probe).pvalue(current_cell_ind);
            
            % Concatenate data across probes
            concat_discrimination_index = [concat_discrimination_index; disc_index];
            concat_pval = [concat_pval; p_values];
            concat_roc_diff = [concat_roc_diff; roc_diff];
        end
        
        %% Calculate modulation statistics
        % Indices for positive, negative, and non-modulated cells
        ind_pos = (concat_discrimination_index > 0 & concat_pval < 0.05);
        ind_neg = (concat_discrimination_index < 0 & concat_pval < 0.05);
        ind_non_mod = ~(ind_pos | ind_neg);
        
        % Calculate fractions and deltas
        fraction_data(period, :) = [sum(ind_pos), sum(ind_neg), sum(ind_non_mod)] / length(concat_discrimination_index);
        delta_means(period, :) = [mean(concat_roc_diff(ind_pos)), mean(concat_roc_diff(ind_neg)), mean(concat_roc_diff(ind_non_mod))];
        delta_errors(period, :) = [std(concat_roc_diff(ind_pos)) / sqrt(sum(ind_pos)), ...
            std(concat_roc_diff(ind_neg)) / sqrt(sum(ind_neg)), ...
            std(concat_roc_diff(ind_non_mod)) / sqrt(sum(ind_non_mod))];

        All_Area_DeltaFR.(current_area).(current_period)=horzcat(concat_roc_diff, ind_pos, ind_neg, ind_non_mod);
    end
    
    %% Plot Column 1 (Fractions)
    hold(axs(ax_ind(ind_area, 1)), "on");
    
    % Create bar plots for positive and negative modulation fractions
    for p = 1:length(period_name)
        % Bar plot for positive modulation (blue)
        bar(axs(ax_ind(ind_area, 1)), p, fraction_data(p, 1) * 100, ...
            'FaceColor', mod_colors(1, :), 'BarWidth', 0.4);
        
        % Bar plot for negative modulation (red, negative values)
        bar(axs(ax_ind(ind_area, 1)), p, -fraction_data(p, 2) * 100, ...
            'FaceColor', mod_colors(2, :), 'BarWidth', 0.4);
    end
    
    % Format fraction plot
    ylabel(axs(ax_ind(ind_area, 1)), 'Fraction of Cells');
    xticks(axs(ax_ind(ind_area, 1)), 1:length(period_name));
    xticklabels(axs(ax_ind(ind_area, 1)), period_name);
    ylim(axs(ax_ind(ind_area, 1)), [-25 50]);
    
    % Assign colors to the bars
    for k = 1:size(fraction_data(:, 1:2), 2)  % Loop through each bar group
        b(k).CData = repmat(mod_colors(k, :), size(fraction_data(:, 1:2), 1), 1);
    end
    
    % Format y-tick labels
    yticklabels(axs(ax_ind(ind_area, 1)), round([abs(get(axs(ax_ind(ind_area, 1)), 'YTick'))], 1));
    
    %% Plot Column 2 (Delta Firing)
    hold(axs(ax_ind(ind_area, 2)), "on");
    
    % Create bar plots for delta firing rates
    for p = 1:length(period_name)
        % Bar plot for positive modulation (blue)
        bar(axs(ax_ind(ind_area, 2)), p, delta_means(p, 1), ...
            'FaceColor', mod_colors(1, :), 'BarWidth', 0.4);
        
        % Bar plot for negative modulation (red)
        bar(axs(ax_ind(ind_area, 2)), p, delta_means(p, 2), ...
            'FaceColor', mod_colors(2, :), 'BarWidth', 0.4);
        
        % Add error bars
        errorbar(axs(ax_ind(ind_area, 2)), [p, p], delta_means(p, 1:2), ...
                delta_errors(p, 1:2), 'k', 'CapSize', 3, 'LineStyle', 'none');
    end
    
    % Format delta firing plot
    ylabel(axs(ax_ind(ind_area, 2)), 'Delta Firing Rate');
    xticks(axs(ax_ind(ind_area, 2)), 1:length(period_name));
    xticks(axs(ax_ind(ind_area, 1)), 1:length(period_name));
    
    xticklabels(axs(ax_ind(ind_area, 2)), period_name);
    xticklabels(axs(ax_ind(ind_area, 1)), period_name);
    
    % Rotate x-tick labels
    set(axs(ax_ind(ind_area, 2)), 'XTickLabelRotation', 45);
    set(axs(ax_ind(ind_area, 1)), 'XTickLabelRotation', 45);
    
    % Set y-axis limits and format
    ylim(axs(ax_ind(ind_area, 2)), [-15, 30]);
    yticklabels(axs(ax_ind(ind_area, 2)), get(axs(ax_ind(ind_area, 2)), 'YTick'));
    
    % Add titles
    title(axs(ax_ind(ind_area, 2)), current_area);
    title(axs(ax_ind(ind_area, 1)), current_area);

    All_Area_Fraction.(current_area)=fraction_data;
    
end % End of area loop

%% Add legend and final formatting
legend(axs(1), {'Positive', 'Negative'});

%% Apply final plot formatting
prettify_plot('LineThickness', 1, 'AxisTightness', 'keep', 'TickLength', [.01 .1], 'PointSize', 3, 'GeneralFontSize', 8);

%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');

%% Perform statistical comparison of proportions up-modulated neurons in the delay period between wM2 and ALM

Total_wM2=size(All_Area_DeltaFR.wM2.delay,1);
Total_ALM=size(All_Area_DeltaFR.ALM.delay,1);

Numb_UpMod_wM2=sum(All_Area_DeltaFR.wM2.delay(:,2));
Numb_UpMod_ALM=sum(All_Area_DeltaFR.ALM.delay(:,2));

Numb_DownMod_wM2=sum(All_Area_DeltaFR.wM2.delay(:,3));
Numb_DownMod_ALM=sum(All_Area_DeltaFR.ALM.delay(:,3));


Prop_Up_wM2=100*Numb_UpMod_wM2/Total_wM2
Prop_Up_ALM=100*Numb_UpMod_ALM/Total_ALM

x1=[]; x2=[];

x1 = [repmat('a',Total_wM2,1); repmat('b',Total_ALM,1)];
x2 = [repmat(1,Numb_UpMod_wM2,1); repmat(2,Total_wM2-Numb_UpMod_wM2,1); repmat(1,Numb_UpMod_ALM,1); repmat(2,Total_ALM-Numb_UpMod_ALM,1)];
[tbl_up,chi2stat_up,pval_up] = crosstab(x1,x2)

Prop_Down_wM2=100*Numb_DownMod_wM2/Total_wM2
Prop_Down_ALM=100*Numb_DownMod_ALM/Total_ALM

x3=[];

x3 = [repmat(1,Numb_DownMod_wM2,1); repmat(2,Total_wM2-Numb_DownMod_wM2,1); repmat(1,Numb_DownMod_ALM,1); repmat(2,Total_ALM-Numb_DownMod_ALM,1)];
[tbl_dwon,chi2stat_down,pval_down] = crosstab(x1,x3)


