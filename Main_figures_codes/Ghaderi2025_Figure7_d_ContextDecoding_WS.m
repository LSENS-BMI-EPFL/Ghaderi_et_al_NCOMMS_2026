%% =========================================================================
% Ghaderi2025_Figure7C_decoding_overruns.m
% =========================================================================
%
% This script generates Figure 7C showing decoding accuracy across runs
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script analyzes decoding accuracy across multiple runs for different
% brain areas. It plots temporal decoding accuracy curves averaged across runs and
% performs statistical comparisons between baseline and response periods.
%
% Dependencies:
%   - Decoding_mat_afterwhisker_run*.mat (contains decoding results for different runs)
%   - tight_subplot.m (for subplot management)
%   - prettify_plot.m (for plot formatting)
%   - hex2rgb.m (for color conversion)
%
% Output: PDF figure showing decoding accuracy across runs
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc

%% Optional: Change figure name
change_name = 0;
newname = 'Figure7C_decoding_overruns';
fullname = mfilename('fullpath');
inds = regexp(fullname,'\','all');
name = fullname(inds(end)+1:end);
if change_name
    movefile([name '.m'],[newname '.m']);
end

%% Initialize main figure
figure('Position', [200 200 1000 400]);
h = tight_subplot(1,1,[.07 .07],[.2 .2],[.1 .1]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters

params.regionlist = {'A1','wS1','wS2','wM2','ALM'};
params.colormap = {'#0008FF';'#228B22';'#00C3FF';'#FF0000';'#FF7F00';'#000000';'#00C3FF';'#FF7F00';'#FF7F00';'#808080';'#6B3686';'#74B99A';'#A020F0';'#FFD700'};
params.colortype = {'wS1';'wS2';'CR2';'ALM';'CR4';'wM2';'FA2';'FA3';'FA4';'FA5';'Lick';'NoLick';'A1';'tjM1'};
params.Map = horzcat(params.colortype,params.colormap);

baseline_win=[0.955,1];  % window 1 for statistical comparison
bin_list=[0.955:0.005:1.1];  % window 2 for statistical comparison

CurrentDir=pwd;
directory=[CurrentDir];

%% Initialize structure to hold data
Accuracy_avg = struct();

%% Load and average data across runs

for f = 1:length(params.regionlist)
    field = params.regionlist{f};
    data_all = [];

    for i = 1:5
        % Load the Accuracy struct from each file
        S = load([directory filesep 'processed_data' filesep 'Decoding_afterwhisker_run' num2str(i) '.mat'], 'Accuracy','windowCenters');

        % Get the current field's data
        data = S.Accuracy.(field);  % e.g., Accuracy.A1

        % Concatenate over 4th dimension
        data_all = cat(4, data_all, data);
    end

    % Take mean across the 4th dimension
    Accuracy_avg.(field) = mean(data_all, 4);
end

%% Prepare accuracy data
Accuracy = Accuracy_avg;
Accuracy.sessionaddress = S.Accuracy.sessionaddress;
windowCenters = S.windowCenters;

%% Process each brain area
ind_fig = 1;
fig_cnt = 2*ind_fig-1;
flg = 0;

for ind_area = 1:length(params.regionlist)
    flg = flg + 1;
    area = cell2mat(params.regionlist(ind_area));
    ind_color = find(strcmp(area,params.Map(:,1)));
    hold on;
    currsig = Accuracy.(area);
    if size(currsig,3) ~= 0
        currsig = mean(currsig,3)';
    end
    ind_nonempty = find(~cellfun(@isempty,Accuracy.sessionaddress.(area)));
    currsig = currsig(:,ind_nonempty);

    % Calculate mean and standard error
    meansig = nanmean(currsig,2);
    semsig = nanstd(currsig,[],2)./sqrt(size(currsig,2));
    curve1 = meansig + semsig;
    curve2 = meansig - semsig;
    x2 = [windowCenters',fliplr(windowCenters')];
    inBetween = [curve1', fliplr(curve2')];

    % Plot with error shading

    fill(h(fig_cnt),x2, inBetween, hex2rgb(cell2mat(params.Map(ind_color,2))),'FaceAlpha',0.2,'LineStyle','none');
    hold(h(fig_cnt),'on');
    plot(h(fig_cnt),windowCenters,meansig,'color',hex2rgb(cell2mat(params.Map(ind_color,2))),'Linewidth',1);

end

%% Add reference lines and formatting

yline(axs(fig_cnt),50);
xline(axs(fig_cnt),[1,1.03]);
xlabel(h(fig_cnt),'Time (s)');
ylabel(h(fig_cnt),'Accuracy (%)');
yticklabels(h(1),get(h(1),'YTick'));
xticklabels(h(1),get(h(1),'XTick'));

%% Apply final plot formatting
legend_just_txt(axs(1),params.regionlist,'Xoffset',0.96,'Yoffset',70,'relX',0,'relY',0.1,'type','line');
prettify_plot('LineThickness', 1,'TickWidth',1.5,'AxisTightness', 'keep','TickLength',[.01 .001],'PointSize','keep');

%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '_accuracy.pdf'], 'ContentType', 'vector');

%% Initialize main figure
figure('Position', [200 200 1000 300]);
h = tight_subplot(1,1,[.07 .07],[.2 .2],[.1 .1]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Compute significance

pval=[];
ind_fig=1;

fig_cnt=2*ind_fig-1;
flg=0;

for areacounter=1:length(params.regionlist)

    flg=flg+1;
    area = cell2mat(params.regionlist(areacounter));
    currsig=Accuracy.(area);

    if size(currsig,3)~=0
        currsig=mean(currsig,3)';
    end

    ind_nonempty=find(~cellfun(@isempty,Accuracy.sessionaddress.(area)));
    currsig=currsig(:,ind_nonempty);

    bin_flg=0;

    for i_bins=bin_list

        bin_flg=bin_flg+1;
        [a,b]=min(abs(windowCenters-baseline_win(1)));W1FirstBin=(b);
        [a,b]=min(abs(windowCenters-baseline_win(2)));W1LastBin=(b);


        [a,b]=min(abs(windowCenters-i_bins));W2FirstBin=(b);
        [a,b]=min(abs(windowCenters-i_bins));W2LastBin=(b);

        V1=nanmean(currsig(W1FirstBin:W1LastBin,:),1);
        V2=nanmean(currsig(W2FirstBin:W2LastBin,:),1);
        pval(areacounter,bin_flg)=P_value(V1,V2);

    end

end

pvalues=pval;
pvalues_area_corrected = mafdr(pvalues(:), 'BHFDR', 'True');
pvalues_corrected=reshape(pvalues_area_corrected,[5,30]);
pvalues_corrected((0.05 <= pvalues_corrected))=nan;
pval((0.05 <= pval))=nan;


%% Plot P values map

axes(axs(1))
h_map=heatmap(pvalues_corrected,'YLabel','Areas','XLabel','Clusters','XDisplayLabels',windowCenters(1:end),'YDisplayLabels',params.regionlist); % heatmap  of table
 
MAX=.05; %m ax(diff_performance(:))
MIN=0; % min(diff_performance(:))

cyan=[0 128 255]/255;
pink=[255 0 128]/255;

min_max_scale=[100;0];
min_max_rgb_neg=[0 0 0;pink];
map_neg=interp1(min_max_scale,min_max_rgb_neg,linspace(90,0,abs(MIN)));

min_max_scale=[100;0];
min_max_rgb_pos=[0,0,0;pink];
map_pos=interp1(min_max_scale,min_max_rgb_pos,linspace(90,0,abs(MAX)));

clim([MIN,MAX]);
MAP=[flipud(map_neg);map_pos];
[cmap, norm_values] = custom_cmap(0, .05, 0, 256);


%% Extract data and labels

data = pvalues_corrected(:, 1:end);
xLabels = windowCenters(1:end);
yLabels = params.regionlist;

% Create the figure

% Show the heatmap using imagesc
h = imagesc(data);

% Reverse colormap so lower p-values look brighter
colormap(flipud(hot));

% Set color scale (caxis) to ignore NaNs
minval = min(data(~isnan(data)), [], 'all');
maxval = max(data(~isnan(data)), [], 'all');
caxis([-0.02 0.07]);

% Set NaNs to be transparent using AlphaData
h.AlphaData = ~isnan(data);  % make NaNs transparent
set(gca, 'Color', 'k');      % show NaNs as black by setting background

% Add colorbar
colorbar;

% Axis labeling
xlabel('Clusters');
ylabel('Time (s)');

% X and Y ticks
xticks(1:length(xLabels));
xticklabels(string(xLabels));
yticks(1:length(yLabels));
yticklabels(yLabels);
xtickangle(90);

% Overlay vertical line at a specific time bin index
targetClusterIndex = 10;
hold on;
yLimits = ylim;
plot([targetClusterIndex targetClusterIndex], yLimits, 'w--', 'LineWidth', 2); % white dashed line

ax = gca;                 % get current axes
ax.TickLength = [0 0];    % remove both x and y tick lines

%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '_Pvalues.pdf'], 'ContentType', 'vector');

%%



%% Save data structure for the Source Data File

All_Area_Accuracy=[];

for ind_area = 1:length(params.regionlist)
    
    area = cell2mat(params.regionlist(ind_area));
    
    currsig = Accuracy.(area);
    if size(currsig,3) ~= 0
        currsig = mean(currsig,3)';
    end
    ind_nonempty = find(~cellfun(@isempty,Accuracy.sessionaddress.(area)));
    currsig = currsig(:,ind_nonempty);
    
    All_Area_Accuracy.(area)=currsig';
    
end


for areacounter=1:length(params.regionlist)

    area = cell2mat(params.regionlist(areacounter));
    currsig=All_Area_Accuracy.(area)';

    bin_flg=0;

    for i_bins=bin_list

        bin_flg=bin_flg+1;
        [a,b]=min(abs(windowCenters-baseline_win(1)));W1FirstBin=(b);
        [a,b]=min(abs(windowCenters-baseline_win(2)));W1LastBin=(b);


        [a,b]=min(abs(windowCenters-i_bins));W2FirstBin=(b);
        [a,b]=min(abs(windowCenters-i_bins));W2LastBin=(b);

        V1=nanmean(currsig(W1FirstBin:W1LastBin,:),1);
        V2=nanmean(currsig(W2FirstBin:W2LastBin,:),1);
        pval(areacounter,bin_flg)=P_value(V1,V2);

    end

end

pvalues=pval;
pvalues_area_corrected = mafdr(pvalues(:), 'BHFDR', 'True');
pvalues_corrected=reshape(pvalues_area_corrected,[5,30]);


All_Area_Pvalue=[];

for ind_area = 1:length(params.regionlist)

    current_area=[];
    current_area = cell2mat(params.regionlist(ind_area));
    All_Area_Pvalue.(current_area)=pvalues_corrected(ind_area,:);
end






























