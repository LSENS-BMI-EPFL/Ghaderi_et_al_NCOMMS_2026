%% =========================================================================
% Ghaderi2025_Figure6_Sup1_decoding_fix_decoder.m
% =========================================================================
%
% This script generates Figure 6Sup1 showing decoding analysis with fixed decoder
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script analyzes decoding accuracy using different decoder types
% (all cells, RS cells, FS cells) across different brain areas. It plots temporal
% decoding accuracy curves and statistical comparisons between baseline and response
% periods for each brain region.
%
% Dependencies:
%   - Decoding_training_on_prewhisk_All.mat (contains decoding results for all cells)
%   - Decoding_training_on_prewhisk_RS.mat (contains decoding results for RS cells)
%   - Decoding_training_on_prewhisk_FS.mat (contains decoding results for FS cells)
%   - tight_subplot.m (for subplot management)
%   - prettify_plot.m (for plot formatting)
%   - prettify_pvalues.m (for statistical significance plotting)
%   - hex2rgb.m (for color conversion)
%
% Output: PDF figure showing decoding analysis with fixed decoder
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



%% 
figure('Position',[500 50 1000 950]);
h = tight_subplot(3,2,[.07 .07],[.07 .04],[.07 .01]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters
arealist = {'A1','wS1','wS2','wM2','ALM'};  % Brain regions
colormap = {'#0008FF';'#00FF00';'#ff0000';'#000000';'#FF00FF'};
colortype = {'wS1';'wS2';'ALM';'wM2';'A1'};
Map = horzcat(colortype,colormap);
params.Win1 = [-1,0];  % Window 1 for statistical comparison
params.Win2 = [.8,1];  % Window 2 for statistical comparison
name_list = {'Decoding_training_on_prewhisk_All.mat','Decoding_training_on_prewhisk_RS.mat','Decoding_training_on_prewhisk_FS.mat'};
XTickLabel = {'-1';'0';'1';'2'};
xtick = [-1;0;1;2];

Included_Neurons={'All'; 'RS' ; 'FS'};

%% Process each decoder type

for ind_fig = 1:length(name_list)
    % Load required data
    load([directory filesep 'processed_data' filesep cell2mat(name_list(ind_fig))]);
    fig_cnt = 2*ind_fig-1;
    flg = 0;
    Decoding_from=[];
    Decoding_from=Included_Neurons{ind_fig,1};
    
    % Process each brain area
    for areacounter = arealist
        flg = flg + 1;
        area = cell2mat(areacounter);
        indcolor = find(strcmp(area,Map(:,1)));
        currsig = Accuracy.(area)';  % Extract accuracy data for current area
        
        % Calculate mean and standard error
        meansig = nanmean(currsig,2);
        semsig = nanstd(currsig,[],2)./sqrt(size(currsig,2));
        curve1 = meansig + semsig;
        curve2 = meansig - semsig;
        x2 = [windowCenters',fliplr(windowCenters')];
        inBetween = [curve1', fliplr(curve2')];
        
        % Plot with error shading
        fill(h(fig_cnt),x2, inBetween, hex2rgb(cell2mat(Map(indcolor,2))),'FaceAlpha',0.3,'LineStyle','none');
        hold(h(fig_cnt),'on');
        plot(h(fig_cnt),windowCenters,meansig,'color',hex2rgb(cell2mat(Map(indcolor,2))),'Linewidth',1);
        
        % Calculate statistics for comparison windows
        [a,b] = min(abs(windowCenters-params.Win1(1))); W1FirstBin = (b);
        [a,b] = min(abs(windowCenters-params.Win1(2))); W1LastBin = (b);
        [a,b] = min(abs(windowCenters-params.Win2(1))); W2FirstBin = (b);
        [a,b] = min(abs(windowCenters-params.Win2(2))); W2LastBin = (b);
        
        V1 = mean(currsig(W1FirstBin:W1LastBin,:),1);
        V2 = mean(currsig(W2FirstBin:W2LastBin,:),1);
        
        % Plot statistical comparison
        hold(h(fig_cnt+1),'on');
        %plot(h(fig_cnt+1),[flg,flg+.4],[V1',V2'],'-ob','Markersize',.5,'markeredgecolor','none');
        plot(h(fig_cnt+1),[flg,flg+.4],[V1',V2'],'-', 'Color', [0.5 0.5 0.5]);
        errorbar(h(fig_cnt+1),[flg-.1,flg+.4+.1],[nanmean(V1),nanmean(V2)],[nanstd(V1,0),nanstd(V2,0)],'-ok','CapSize',0,'Linewidth',2);
        pval(flg) = P_value(V1,V2);

        All_Area_Acc.(Decoding_from).(area)=horzcat(V1', V2');
        All_Area_P_Values.(Decoding_from).(area)=P_value(V1,V2);
        
    end % End of area loop

    
    
    % Format plots
    yline(axs(fig_cnt),50);
    xline(axs(fig_cnt),0);
    xline(axs(fig_cnt),1);
    ylim(axs(fig_cnt),[40, 100]);
    xlabel(h(fig_cnt),'Time (s)');
    ylabel(h(fig_cnt),'Accuracy (%)');
    xticks(h(fig_cnt),xtick);
    xticklabels(h(fig_cnt),XTickLabel);
    axs(fig_cnt).XAxis.Visible = 'off';

    ylim(axs(fig_cnt+1),[40,110]);
    
    yticklabels(h(fig_cnt+1),get(h(fig_cnt+1),'YTick'));
    xticks(h(fig_cnt+1),[1:5]+.2);
    xticklabels(h(fig_cnt+1),arealist);
    
    % Add title for each decoder type
    text(axs(fig_cnt),-0.95, 85,strrep(name_list{1,ind_fig}(1:end-4),'_',' '));
    ylabel(h(fig_cnt+1),'Accuracy (%)');
    
    % Add statistical significance indicators
    prettify_pvalues(axs(fig_cnt+1), [1,2,3,4,5], [1.5,2.5,3.5,4.5,5.5], pval,'PlotNonSignif', false,'OnlyStars',true,'Yposition',90);
    xlim(axs(fig_cnt+1),[0,6]);
    

end % End of decoder type loop

%% Apply final plot formatting
prettify_plot('LineThickness', 1,'TickWidth',1.5,'AxisTightness', 'keep','TickLength',[.02 .02],'PointSize',4);

%% Export figure

directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');



