%% =========================================================================
% Ghaderi2025_Figure5A_deltafr.m
% =========================================================================
%
% This script generates Figure 5A showing delta firing rate analysis
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script calculates and plots delta firing rates (difference between trial conditions)
% across different brain areas. It analyzes neural activity changes between Go-tone/whisker and
% Nogo-tone/whisker trials, with error shading for statistical visualization.
%
% Dependencies:
%   - psth_10ms.mat (contains trial data)
%   - Area_list.mat (contains brain area information)
%   - tight_subplot.m (for subplot management)
%   - legend_just_txt.m (for legend creation)
%   - prettify_plot.m (for plot formatting)
%   - hex2rgb.m (for color conversion)
%
% Output: PDF figure showing delta firing rate analysis
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc

%% Optional: Change figure name
change_name = 0;
newname = 'Figure5A_deltafr';
fullname = mfilename('fullpath');
inds = regexp(fullname,'\','all');
name = fullname(inds(end)+1:end);
if change_name
    movefile([name '.m'],[newname '.m']);
end

%% Load required data
CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'psth_10ms.mat'])
load([directory filesep 'processed_data' filesep 'Roc_hit_cr3.mat'])
load([directory filesep 'data_helpers' filesep 'Area_list.mat'])

%% Initialize main figure

figure('Position',[200 200 500 500]);
h = tight_subplot(1,1,[.01 .01],[.16 .01],[.16 .02]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters
params.QuietState = 'Quiet_(jaw & whisker)';  % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trials'
params.BaselineSubtraction = 0;
params.completion_state = 'completed_trials';  % Options: 'early_licks', 'completed_trials'
params.TrialType = [1,3];  % 1: gotone/whisker, 3: nogotone/whisker
params.LickState = [1,0];  % 1: lick, 0: nolick
params.CellType = 'All';  % Options: 'RS', 'FS', 'RS_FS', 'All'
params.regionlist = {'A1','wS1','wS2','wM2','ALM'};  % Brain regions
t_start = -1;  % Start time
t_end = 2;     % End time
bin_width = 0.01;

XTickLabel = {'-1','0','1','2'};
xtick = [-1,0,1,2];

% Analysis parameters
cnt_area = 0;
area_name = {'A1','wS1','wS2','wM2','ALM'};
area_ind = [1 2 3 4 5];
period_name = {'delay'};
period_ind = [1];
ax_ind = [1:10];
ax_ind = reshape(ax_ind,[5,2])';


% Movement signal parameters
% movements_signals = {'whisker_speed','snout_angle','piezo_lick_trace','jaw_movement','tongue_movement'};
% movements_signals_tag = {'Whisker','Snout','Piezo lick','Jaw','Tongue'};
% params.movement_baselineSubtraction = 1;
% params.movement_normalization = 0;

% Color scheme for delta FR
params.colormap = {'#0008FF';'#228B22';'#00C3FF';'#FF0000';'#FF7F00';'#000000';'#00C3FF';'#FF7F00';'#FF7F00';'#808080';'#6B3686';'#74B99A';'#A020F0';'#FFD700'};
params.colortype = {'wS1';'wS2';'CR2';'ALM';'CR4';'wM2';'FA2';'FA3';'FA4';'FA5';'Lick';'NoLick';'A1';'tjM1'};
params.Map = horzcat(params.colortype,params.colormap);

% Color scheme for ROC
color_map = {'#FF00FF';'#0008FF';'#00FF00';'#000000';'#ff0000'};
colortype = {'A1';'wS1';'wS2';'wM2';'ALM'};
map = horzcat(colortype,color_map);

% Convert hex colors to RGB
for i = 1:5
    color_map_rgb(i,:) = hex2rgb(color_map(i));
end

%% Process each trial condition
for ind_cond = 1:length(params.TrialType)
    cnt_area = 0;
    for ind_area = 1:length(params.regionlist)
        current_area = cell2mat(params.regionlist(ind_area));
        probe_list = find(strcmp(current_area,[psth_mat.probe_location]));
        
        concat_sp = [];
        for ind_probe = probe_list
            Trial = psth_mat(ind_probe).trial_type;
            Lick = psth_mat(ind_probe).lick_flag;
            
            % Apply trial type and lick state filters
            IndTrialType = Trial == params.TrialType(ind_cond);
            IndLickstate = Lick == params.LickState(ind_cond);
            
            % Determine completion state
            switch params.completion_state
                case 'completed_trials'
                    completion_state = ~psth_mat(ind_probe).early_lick;
                case 'early_licks'
                    early_licks_all = psth_mat(ind_probe).early_lick;
                    lick_time = 0 < (psth_mat(ind_probe).lick_time - psth_mat(ind_probe).start_time);
                    completion_state = lick_time & early_licks_all;
            end
            
            % Apply quiet state filter
            switch params.QuietState
                case 'Quiet_(whisker_speed)'
                    Qind = psth_mat(ind_probe).quiet_trial_whisker_speed;
                case 'Quiet_(jaw_movement)'
                    Qind = psth_mat(ind_probe).quiet_trial_jaw_movement;
                case 'Quiet_(jaw & whisker)'
                    Qind = psth_mat(ind_probe).quiet_trial_jaw_movement & psth_mat(ind_probe).quiet_trial_whisker_speed;
                case 'Non_quiet'
                    Qind = ~(psth_mat(ind_probe).quiet_trial_jaw_movement & psth_mat(ind_probe).quiet_trial_whisker_speed);
                case 'All_trials'
                    Qind = ones(length(IndLickstate),1);
            end
            
            current_trial_ind = [Qind & completion_state & IndLickstate & IndTrialType];
            
            % Apply cell type filter
            switch params.CellType
                case 'RS'
                    CelltypeInd = psth_mat(ind_probe).unit_rsUnits;
                case 'FS'
                    CelltypeInd = psth_mat(ind_probe).unit_fsUnits;
                case 'RS_FS'
                    CelltypeInd = (psth_mat(ind_probe).unit_fsUnits | psth_mat(ind_probe).unit_rsUnits);
                case 'All'
                    CelltypeInd = logical(ones(length(psth_mat(ind_probe).unit_rsUnits),1));
            end
            
            % Apply CCF filter on cell location
            ind_ccf_filter = ismember(psth_mat(ind_probe).unit_ccf_location,area_list.(current_area));
            current_cell_ind = (CelltypeInd & ind_ccf_filter);
            
            % Get current PSTH data
            curr_sp = psth_mat(ind_probe).spike_counts;
            curr_sp_trials = squeeze(nanmean(curr_sp(:,current_trial_ind,:),2));
            curr_sp_trials_cells = curr_sp_trials(:,current_cell_ind);
            WindowCenters = psth_mat(ind_probe).trial_timestamps;
            
            % Calculate baseline
            t1 = -1;
            t2 = 0;
            [a,b] = min(abs(WindowCenters-t1)); baselineFirstBin = (b);
            [a,b] = min(abs(WindowCenters-t2)); baselineLastBin = (b);
            baseline_mean = repmat(mean(curr_sp_trials_cells(baselineFirstBin:baselineLastBin,:),1),size(curr_sp_trials_cells,1),1);
            
            % Apply baseline subtraction if requested
            if params.BaselineSubtraction
                curr_sp_trials_cells = curr_sp_trials_cells - baseline_mean;
            end
            
            concat_sp = [concat_sp,curr_sp_trials_cells];
        end % End of probe loop
        
        % Store data for plotting
        signal2plot = concat_sp;
        time2plot = WindowCenters;
        signal2plot = signal2plot/bin_width; % Convert to Hz
        ind_color = find(strcmp(current_area,params.Map(:,1)));
        meansig = nanmean(signal2plot,2);
        semsig = nanstd(signal2plot,[],2)./sqrt(size(signal2plot,2));
        curve1 = meansig + semsig;
        curve2 = meansig - semsig;
        x2 = [time2plot',fliplr(time2plot')];
        inBetween = [curve1', fliplr(curve2')];
        
        % Store for calculating difference
        diff_sp.(current_area){ind_cond} = signal2plot;
    end % End of area loop
end % End of condition loop

%% Plot difference between trial conditions
flg = 0;
for ind_area = 1:length(params.regionlist)
    flg = flg + 1;
    current_area = cell2mat(params.regionlist(ind_area));
    current_diff_sp = diff_sp.(current_area){1} - diff_sp.(current_area){2};
    signal2plot = current_diff_sp;
    time2plot = WindowCenters;
    ind_color = find(strcmp(current_area,params.Map(:,1)));
    
    % Calculate mean and standard error
    meansig = nanmean(signal2plot,2);
    semsig = nanstd(signal2plot,[],2)./sqrt(size(signal2plot,2));
    curve1 = meansig + semsig;
    curve2 = meansig - semsig;
    x2 = [time2plot',fliplr(time2plot')];
    inBetween = [curve1', fliplr(curve2')];
    
    % Plot with error shading
    fill(h(1),x2, inBetween, hex2rgb(cell2mat(params.Map(ind_color,2))),'FaceAlpha',0.2,'LineStyle','none');
    hold(h(1),'on');
    plot(h(1),time2plot,meansig,'color',hex2rgb(cell2mat(params.Map(ind_color,2))),'linewidth',1);
    xline(axs(1),0);
    xline(axs(1),1);
    ylim(axs(1),[-1.5,3.5]);
    yline(axs(1),0,'Tag','y=0');
    xlabel(axs(1),'Time (s)');
    ylabel(axs(1),'\Delta Firing rate (Hz)');
    xticks(axs(1),xtick);
    xticklabels(axs(1),XTickLabel);
end

%% Add legend and final formatting
legend_just_txt(axs(1),params.regionlist,'Xoffset',-.8,'Yoffset',3,'relX',0,'relY',0.09,'type','line');
prettify_plot('LineThickness', 1,'TickWidth',1.5,'AxisTightness', 'keep','TickLength',[.01 .001],'PointSize',4);

%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '_DeltaFR.pdf'], 'ContentType', 'vector');

%% ROC

%% Initialize main figure

figure('Position',[100 200 1000 500]);
h = tight_subplot(2,5,[.001 .08],[.1 .1],[.08 .08]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

% Process each brain area for ROC
NumbCell=[];

for ind_area = 1:length(params.regionlist)
    current_area = cell2mat(params.regionlist(ind_area));
    probe_list = find(strcmp(current_area,[psth_mat.probe_location]));
    
    % Initialize data containers for the current area
    fraction_data = zeros(length(period_name), 3);
    delta_means = zeros(length(period_name), 3);
    delta_errors = zeros(length(period_name), 3);
    concat_cellclass = [];
    concat_discrimination_index = [];
    concat_pval = [];
    concat_roc_diff = [];
    
    % Process each probe in current area
    for ind_probe = probe_list
        % Apply cell type filter
        switch params.CellType
            case 'RS'
                CelltypeInd = psth_mat(ind_probe).unit_rsUnits;
            case 'FS'
                CelltypeInd = psth_mat(ind_probe).unit_fsUnits;
            case 'RS_FS'
                CelltypeInd = (psth_mat(ind_probe).unit_fsUnits | psth_mat(ind_probe).unit_rsUnits);
            case 'All'
                CelltypeInd = logical(ones(length(psth_mat(ind_probe).unit_rsUnits),1));
        end
        
        % Apply CCF filter on cell location
        ind_ccf_filter = ismember(psth_mat(ind_probe).unit_ccf_location,area_list.(current_area));
        CurrCellInd = (CelltypeInd & ind_ccf_filter);
        
        % Classify cells by type
%         current_cellclass = {};
%         current_cellclass(psth_mat(ind_probe).unit_rsUnits) = {'RS'};
%         current_cellclass(psth_mat(ind_probe).unit_fsUnits) = {'FS'};
%         current_cellclass(~(psth_mat(ind_probe).unit_fsUnits | psth_mat(ind_probe).unit_rsUnits)) = {'nan'};
        
        % Get ROC analysis results
        current_roc_diff = roc_mat(ind_probe).diff_fr;
        current_discrimination_index = roc_mat(ind_probe).discrimination_index;
        curent_pvalue = roc_mat(ind_probe).pvalue;
        
        % Get trial information
        Trial = psth_mat(ind_probe).trial_type;
        Lick = psth_mat(ind_probe).lick_flag;
        completion_state = ~psth_mat(ind_probe).early_lick;
        
        % Filter for specified cell types
        current_roc_diff_cell = current_roc_diff(CurrCellInd);
        current_discrimination_index_cell = current_discrimination_index(CurrCellInd);
        current_pval_cell = curent_pvalue(CurrCellInd);
        
        % Concatenate data across probes
        concat_pval = [concat_pval; current_pval_cell];
        concat_discrimination_index = [concat_discrimination_index; current_discrimination_index_cell];
        concat_roc_diff = [concat_roc_diff; current_roc_diff_cell];
%         concat_cellclass = [concat_cellclass; current_cellclass'];
    end % End of probe loop
    
    %% Identify modulated cells
    ind_pos = [(0 < concat_discrimination_index) & (concat_pval < 0.05)];
    ind_neg = [(concat_discrimination_index < 0) & (concat_pval < 0.05)];
    ind_nan = [0.05 <= concat_pval];
    x = [sum(ind_pos) sum(ind_neg) sum(~(ind_neg | ind_pos))];
    
    eval(['NumbCell.' current_area '=x;']);

    % Set colors for pie chart
    newcolors = [0 0 1; 1 0 0; 0.5 0.5 0.5];
    ax_col = area_ind(strcmp(current_area,area_name));
    ax_row = 1;
    
    %% Create pie chart
    pie(axs(ax_ind(1,ax_col)), x);
    axs(ax_ind(1,ax_col)).Colormap = newcolors;
    title(axs(ax_ind(1,ax_col)), current_area);
    
    %% Calculate delta firing rates for different modulation types
    diff_pos = concat_roc_diff(ind_pos);
    diff_neg = concat_roc_diff(ind_neg);
    diff_nan = concat_roc_diff(ind_nan);
    
    axs(ax_ind(1,ax_col)).XAxis.Visible = 'off';
    hold(axs(ax_ind(2,ax_col)), 'on');

    All_Area_DeltaFR.(current_area)=horzcat(concat_roc_diff, ind_pos, ind_neg, ind_nan);
    
    %% Create bar plot
    bar(axs(ax_ind(2,ax_col)), [1], [mean(diff_pos)], 'FaceColor', 'b');
    bar(axs(ax_ind(2,ax_col)), [2], [mean(diff_neg)], 'FaceColor', 'r');
    bar(axs(ax_ind(2,ax_col)), [3], [mean(diff_nan)], 'FaceColor', [.5 .5 .5]);
    
    % Add error bars
    errorbar(axs(ax_ind(2,ax_col)), [1 2 3], [mean(diff_pos), mean(diff_neg), mean(diff_nan)], ...
            [std(diff_pos)/sqrt(length(diff_pos)), std(diff_neg)/sqrt(length(diff_neg)), std(diff_nan)/sqrt(length(diff_nan))], ...
            '.', 'CapSize', 2, 'LineWidth', 1, 'MarkerFaceColor', 'none', 'Color', 'k');
    
    ylim(axs(ax_ind(2,ax_col)), [-5 10]);
    axs(ax_ind(2,ax_col)).YTickLabel = axs(ax_ind(ax_row+1,ax_col)).get("YTick");
end % End of area loop

%% Add labels and legend
ylabel(axs(ax_ind(2,1)), 'delta firing rate (Hz)');
text(axs(ax_ind(1,1)), 3, 1.5, 'Fraction of cells', 'unit', 'normalized');
legend_just_txt(axs(ax_ind(2,1)), {'positive'; 'negative'; 'non modulated'}, 'Xoffset', 2, 'Yoffset', 10, 'relX', 0, 'relY', 0.08, 'type', 'bar');

%% Apply final plot formatting
prettify_plot('LineThickness', 1, 'AxisTightness', 'keep', 'TickLength', [.01 .003], 'GeneralFontSize', 8);

%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '_ROC.pdf'], 'ContentType', 'vector');

