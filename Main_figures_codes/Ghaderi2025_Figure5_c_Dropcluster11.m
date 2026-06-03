%% =========================================================================
% Ghaderi2025_Figure5C_Dropcluster11.m
% =========================================================================
%
% This script generates Figure 5C showing cluster dropout analysis
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script analyzes the effect of dropping specific cell clusters on decoding performance.
% It plots the difference in decoding accuracy when cluster 11 is removed compared to random dropout,
% showing the importance of this specific cluster for decoding performance.
%
% Dependencies:
%   - Decoding_clusters_random_dropout.mat (contains cluster dropout results)
%   - Decoding_delay.mat (contains baseline decoding results)
%   - tight_subplot.m (for subplot management)
%   - prettify_plot.m (for plot formatting)
%   - prettify_pvalues.m (for statistical significance plotting)
%   - hex2rgb.m (for color conversion)
%
% Output: PDF figure showing cluster dropout analysis
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc

%% Optional: Change figure name
change_name = 0;
newname = 'Figure5C_Dropcluster11';
fullname = mfilename('fullpath');
inds = regexp(fullname,'\','all');
name = fullname(inds(end)+1:end);
if change_name
    movefile([name '.m'],[newname '.m']);
end

%% Define analysis parameters
arealist = {'A1','wS1','wS2','wM2','ALM'};  % Brain regions
colormap = {'#0008FF';'#228B22';'#ff0000';'#000000';'#FF00FF'};
colortype = {'wS1';'wS2';'ALM';'wM2';'A1'};
Map = horzcat(colortype,colormap);
params.Win1 = [-.8,0];  % Window 1 for statistical comparison
params.Win2 = [.8,1];   % Window 2 for statistical comparison

%% Load required data
CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'Decoding_clusters_random_dropout.mat'])
load([directory filesep 'processed_data' filesep 'Decoding_delay.mat'])


%% Define cluster to analyze
names = fieldnames(ACC);
names = {'cluster11'};  % Focus on cluster 11
ind_fig=1;
%% Process each cluster
Mean_Accuracy=[];

for clusters = names'
    %% Initialize figure
    figure('Units','centimeters','Position',[2 2 30 15],'PaperType','A4','PaperUnits','centimeters','PaperSize',[21 29.7],'PaperPosition',[1 1 20 25]);
    h = tight_subplot(1,2,[.1 .1],[.13 .03],[.1 .01]);
    axs = findall(gcf, 'type', 'axes');
    axs = flipud(axs);
    
    cluster_name = cell2mat(clusters);
    fig_cnt = 2*ind_fig-1;
    flg = 0;
    
    %% Get cluster-specific data
    Accuracy_clus_selection = ACC.(cluster_name).Accuracy;
    windowCenters = ACC.(cluster_name).windowCenters;
    
    %% Process each brain area
    for areacounter = arealist
        flg = flg + 1;
        area = cell2mat(areacounter);
        indcolor = find(strcmp(area,Map(:,1)));
        hold on;
        
        %% Get accuracy data for different conditions
        currsig_clus_droped = Accuracy_clus_selection.(area)';
        currsig_all_selected = Accuracy.(area)';
        
        % Handle special case for A1 cluster1
        if strcmp(area,'A1') && strcmp(cluster_name,'cluster1')
            currsig_all_selected(:,6) = zeros(300,1);
        end
        
        % Remove empty sessions
        currsig_all_selected(:,all(currsig_all_selected==0)) = [];
        currsig_clus_droped(:,all(currsig_clus_droped==0)) = [];
        
        %% Calculate difference between cluster dropout and baseline
        delta = currsig_clus_droped - currsig_all_selected;
        
        %% Calculate mean and standard error
        meansig = nanmean(delta,2);
        semsig = nanstd(delta,[],2)./sqrt(size(delta,2));
        curve1 = meansig + semsig;
        curve2 = meansig - semsig;
        x2 = [windowCenters',fliplr(windowCenters')];
        inBetween = [curve1', fliplr(curve2')];
        
        %% Plot with error shading
        fill(h(fig_cnt),x2, inBetween, hex2rgb(cell2mat(Map(indcolor,2))),'FaceAlpha',0.3,'LineStyle','none');
        hold(h(fig_cnt),'on');
        plot(h(fig_cnt),windowCenters,meansig,'color',hex2rgb(cell2mat(Map(indcolor,2))),'Linewidth',1);
        
        %% Calculate statistics for window 2
        [a,b] = min(abs(windowCenters-params.Win2(1))); W2FirstBin = (b);
        [a,b] = min(abs(windowCenters-params.Win2(2))); W2LastBin = (b);
        V2 = mean(delta(W2FirstBin:W2LastBin,:),1);
        
        %% Plot statistical comparison
        hold(h(2),'on');
        plot(h(2),[flg+.2],[V2'],'ok','Markersize',5,'markerfacecolor','none', 'Color', [0.5 0.5 0.5]);
        errorbar(h(2),[flg],[nanmean(V2)],[nanstd(V2,0)/sqrt(length(V2))],'-o','Markersize',8,'CapSize',4,'Linewidth',2,'Color',hex2rgb(cell2mat(Map(indcolor,2))));
        A=[];
        A=V2';

        eval(['Mean_Accuracy.' area '=A;']);
        
        %% Calculate p-value
        pval(flg) = signrank(V2);
        
    end % End of area loop

    %% Apply FDR correction for multiple test
    p_values_Corr = mafdr(pval, 'BHFDR', 'True');

    flg=0;
    for areacounter = arealist
        flg = flg + 1;
        area = cell2mat(areacounter);
        display([area ' pval =' num2str(p_values_Corr(flg))]);

    end
    %% Format plots
    yline(axs(1),0);
    xline(axs(1),0);
    xline(axs(1),1);
    ylim(axs(1),[-15,10]);
    ylim(axs(2),[-20,10]);
    yline(axs(2),0);
    xlim(axs(2),[0,6]);
    
    xlabel(h(fig_cnt),'Time (s)');
    ylabel(h(fig_cnt),'Accuracy (%)');
    
    yticklabels(h(fig_cnt+1),get(h(fig_cnt+1),'YTick'));
    xticks(h(fig_cnt+1),[1:5]+.2);
    xticklabels(h(fig_cnt+1),arealist);
    ylabel(h(fig_cnt+1),'Accuracy (%)');
    
    %% Add statistical significance indicators
    prettify_pvalues(axs(fig_cnt+1), [1,2,3,4,5], [1,2,3,4,5], p_values_Corr,'PlotNonSignif', false,'OnlyStars',true);
    
    %% Apply final plot formatting
    prettify_plot('LineThickness', 1,'TickWidth',1.5,'AxisTightness', 'keep','TickLength',[.01 .001],'PointSize','keep');
    
    %% Add title
    sgtitle(cluster_name);
end % End of cluster loop

%% Export figure

directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');
