%% =========================================================================
% Ghaderi2025_Figure7A_psths.m
% =========================================================================
%
% This script generates Figure 7A showing PSTH analysis for all cell types
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script analyzes and plots peri-stimulus time histograms (PSTHs)
% for all cell types across different brain areas and trial conditions. It also plots
% the difference in firing rates between Go and Nogo trials.
%
% Dependencies:
%   - psth_mat.mat (contains trial data)
%   - area_list.mat (contains brain area information)
%   - tight_subplot.m (for subplot management)
%   - legend_just_txt.m (for legend creation)
%   - prettify_plot.m (for plot formatting)
%   - hex2rgb.m (for color conversion)
%
% Output: PDF figure showing PSTH analysis for all cell types
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc

rng(0)
%% Optional: Change figure name
change_name = 0;
newname = 'Figure7A_psths';
fullname = mfilename('fullpath');
inds = regexp(fullname,'\','all');
name = fullname(inds(end)+1:end);
if change_name
    movefile([name '.m'],[newname '.m']);
end

%% Load required data
CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'psth_5ms.mat'])
load([directory filesep 'data_helpers' filesep 'Area_list.mat'])


%% Initialize main figure
parent = figure('Position', [200 200 1000 400]);

h = tight_subplot(1,1,[0.1 .1],[.2 .1],[0.08 0.08]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters
WindowCenters = [-1+0.005:0.005:2]';
params.QuietState = 'Quiet_(jaw & whisker)'; % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trials'
params.BaselineSubtraction = 1;
params.completion_state = 'completed_trials';
params.TrialType = [1,3];
params.LickState = [1,0];
params.TrialType_name = {'Go-tone context';'Nogo-tone context'};
params.CellType = 'All';
params.regionlist = {'A1','wS1','wS2','wM2','ALM'};
bin_width = 0.005;
XTickLabel = {'0.95';'1';'1.05';'1.1'};
xtick = [0.95;1;1.05;1.1];
t_show = [0.95,1.1];

params.colormap = {'#0008FF';'#228B22';'#00C3FF';'#FF0000';'#FF7F00';'#000000';'#00C3FF';'#FF7F00';'#FF7F00';'#808080';'#6B3686';'#74B99A';'#A020F0';'#FFD700'};
params.colortype = {'wS1';'wS2';'CR2';'ALM';'CR4';'wM2';'FA2';'FA3';'FA4';'FA5';'Lick';'NoLick';'A1';'tjM1'};
params.Map = horzcat(params.colortype,params.colormap);

diff_sp = struct();

%% Process each trial condition

for ind_cond = 1:length(params.TrialType)

    current_trialtype = cell2mat(params.TrialType_name(ind_cond));

    for ind_area = 1:length(params.regionlist)

        current_area = cell2mat(params.regionlist(ind_area));
        probe_list = find(strcmp(current_area,[psth_mat.probe_location]));
        concat_sp = [];

        for ind_probe = probe_list

            Trial = psth_mat(ind_probe).trial_type;
            Lick = psth_mat(ind_probe).lick_flag;
            IndTrialType = Trial == params.TrialType(ind_cond);
            IndLickstate = Lick == params.LickState(ind_cond);
            switch params.completion_state
                case 'completed_trials'
                    completion_state = ~psth_mat(ind_probe).early_lick;
                case 'early_licks'
                    early_licks_all = psth_mat(ind_probe).early_lick;
                    lick_time = 0 < (psth_mat(ind_probe).lick_time - psth_mat(ind_probe).start_time);
                    completion_state = lick_time & early_licks_all;
            end
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

            ind_ccf_filter = ismember(psth_mat(ind_probe).unit_ccf_location,area_list.(current_area));
            current_cell_ind = (CelltypeInd & ind_ccf_filter);
            curr_sp = psth_mat(ind_probe).spike_counts;
            curr_sp_trials = squeeze(nanmean(curr_sp(:,current_trial_ind,:),2));
            curr_sp_trials_cells = curr_sp_trials(:,current_cell_ind);
            t1 = .95;
            t2 = 1;
            [a,b] = min(abs(WindowCenters-t1)); baselineFirstBin = (b);
            [a,b] = min(abs(WindowCenters-t2)); baselineLastBin = (b);

            baseline_mean = repmat(mean(curr_sp_trials_cells(baselineFirstBin:baselineLastBin,:),1),size(curr_sp_trials_cells,1),1);

            if params.BaselineSubtraction
                curr_sp_trials_cells = curr_sp_trials_cells - baseline_mean;
            end

            concat_sp = [concat_sp,curr_sp_trials_cells];

        end % End of session

        signal2plot = concat_sp;
        time2plot = WindowCenters;
        signal2plot = signal2plot/bin_width; % convert to Hz
        diff_sp.(current_area){ind_cond} = signal2plot;

    end % End over areas

end % End loop over Trial types


%% Calculate p-values for each area and time bin
flg = 0;
for ind_area = 1:length(params.regionlist)
    flg = flg + 1;
    current_area = cell2mat(params.regionlist(ind_area));
    current_diff_sp = diff_sp.(current_area){1} - diff_sp.(current_area){2};
    for ind_bin = 1:size(current_diff_sp,1)
        P(ind_area,ind_bin) = signrank(current_diff_sp(ind_bin,:));
    end
end

%% Apply multiple comparison correction
pvalues = P(:,391:420);
pvalues_area_corrected = mafdr(pvalues(:), 'BHFDR', 'True');
pvalues_corrected = reshape(pvalues_area_corrected,[5,30]);
pvalues_corrected((0.05 <= pvalues_corrected)) = nan;

%% Create heatmap
h_map = heatmap(pvalues_corrected,'YLabel','Areas','XLabel','Time','XDisplayLabels',WindowCenters(391:420),'YDisplayLabels',params.regionlist);
MAX = .05;
MIN = 0;
zero = 0;
cyan = [0 128 255]/255;
pink = [255 0 128]/255;

% Create color maps for negative and positive values
min_max_scale = [100;0];
min_max_rgb_neg = [0 0 0;pink];
map_neg = interp1(min_max_scale,min_max_rgb_neg,linspace(90,0,abs(MIN)));
min_max_scale = [100;0];
min_max_rgb_pos = [0,0,0;pink];
map_pos = interp1(min_max_scale,min_max_rgb_pos,linspace(90,0,abs(MAX)));
clim([MIN,MAX]);
MAP = [flipud(map_neg);map_pos];
[cmap, norm_values] = custom_cmap(0, .05, 0, 256);
colorbar;

%% Extract data and labels for custom heatmap

data = pvalues_corrected(:, 1:end);
xLabels = WindowCenters(391:420);
yLabels = params.regionlist;

% Create custom heatmap using imagesc
h = imagesc(data);

% Reverse colormap so lower p-values look brighter
colormap(flipud(hot));

% Set color scale to ignore NaNs
minval = min(data(~isnan(data)),[],'all');
maxval = max(data(~isnan(data)),[],'all');
caxis([-0.02 0.07]);

% Set NaNs to be transparent
h.AlphaData = ~isnan(data);
set(gca, 'Color', 'k');

% Add colorbar
colorbar;

% Axis labeling
xlabel('Time bin');
ylabel('Areas');

% X and Y ticks
xticks(1:length(xLabels));
xticklabels(string(xLabels));
yticks(1:length(yLabels));
yticklabels(yLabels);
xtickangle(90);

% Overlay vertical line at specific cluster index
targetClusterIndex = 10;
hold on;
yLimits = ylim;
plot([targetClusterIndex targetClusterIndex], yLimits, 'w--', 'LineWidth', 2);
ax = gca;
ax.TickLength = [0 0];

%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '_Pval_Map.pdf'], 'ContentType', 'vector');

%% Initialize main figure
parent = figure('Position', [200 200 1000 400]);

h = tight_subplot(1,1,[0.1 .1],[.2 .1],[0.08 0.08]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);


%% Plot difference between Go and Nogo
flg = 0;

for ind_area = 1:length(params.regionlist)
    flg = flg + 1;
    current_area = cell2mat(params.regionlist(ind_area));
    current_diff_sp = diff_sp.(current_area){1} - diff_sp.(current_area){2};
    signal2plot = current_diff_sp;
    ind_color = find(strcmp(current_area,params.Map(:,1)));
    meansig = nanmean(signal2plot,2);
    semsig = nanstd(signal2plot,[],2)./sqrt(size(signal2plot,2));
    curve1 = meansig + semsig;
    curve2 = meansig - semsig;
    x2 = [time2plot',fliplr(time2plot')];
    inBetween = [curve1', fliplr(curve2')];
    fill(axs(end),x2, inBetween, hex2rgb(cell2mat(params.Map(ind_color,2))),'FaceAlpha',0.2,'LineStyle','none');
    hold(axs(end),'on');
    plot(axs(end),time2plot,meansig,'color',hex2rgb(cell2mat(params.Map(ind_color,2))),'linewidth',1);
    xlim(axs(end),t_show);
    xline(axs(end),[1,1.03]);
    ylim(axs(end),[-2,2]);
    yline(axs(end),0,'Tag','y=0');
    xlabel(axs(end),'Time (s)');
    ylabel(axs(end),'\Delta firing rate (Hz)');
    xticks(axs(end),xtick);
    xticklabels(axs(end),XTickLabel);
    title(axs(end),current_trialtype);
    title(axs(end),'Go-tone minus Nogo-tone');
end

%% Add legend and formatting
legend_just_txt(axs(1),params.regionlist,'Xoffset',1.1,'Yoffset',2,'relX',0,'relY',0.05,'type','line');
prettify_plot('LineThickness', 1,'TickWidth',1.5,'AxisTightness', 'keep','TickLength',[.02 .02],'PointSize',4);

%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '_psths.pdf'], 'ContentType', 'vector');

%% Save data structure for the Source Data File

All_Area_DeltaFR=[];
All_Pvalue=[];

for ind_area = 1:length(params.regionlist)

    current_area=[];
    current_area = cell2mat(params.regionlist(ind_area));
    current_diff_sp = diff_sp.(current_area){1} - diff_sp.(current_area){2};
    signal2plot = current_diff_sp(391:420,:)';

    All_Area_DeltaFR.(current_area)=signal2plot;

    this_area_Pval=[];
    this_area_Pval_corrected=[];

    for t=1:size(signal2plot,2)

        this_area_Pval(1,t)=signrank(signal2plot(:,t));

    end
%     this_area_Pval_corrected = mafdr(this_area_Pval, 'BHFDR', 'True');
%     All_Area_Pvalue(ind_area,:)=this_area_Pval_corrected;

    All_Pvalue(ind_area,:)=this_area_Pval;

end

All_Pvalue_corrected = mafdr(All_Pvalue(:), 'BHFDR', 'True');
All_Pvalue = reshape(pvalues_area_corrected,[5,30]);


All_Area_Pvalue=[];

for ind_area = 1:length(params.regionlist)

    current_area=[];
    current_area = cell2mat(params.regionlist(ind_area));
    All_Area_Pvalue.(current_area)=All_Pvalue(ind_area,:);
end
