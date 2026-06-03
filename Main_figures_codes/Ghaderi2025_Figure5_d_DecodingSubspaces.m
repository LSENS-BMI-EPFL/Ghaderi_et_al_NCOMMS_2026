%% =========================================================================
% Ghaderi2025_Figure5D_null_decoding.m
% =========================================================================
%
% This script generates Figure 5D showing null subspace decoding analysis
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script analyzes decoding accuracy in the null subspace across different brain areas.
% It plots temporal decoding accuracy curves and statistical comparisons between baseline and
% response periods for each brain region in the null subspace.
%
% Dependencies:
%   - Decoding_null.mat (contains null subspace decoding results)
%   - tight_subplot.m (for subplot management)
%   - prettify_plot.m (for plot formatting)
%   - prettify_pvalues.m (for statistical significance plotting)
%   - hex2rgb.m (for color conversion)
%
% Output: PDF figure showing null subspace decoding analysis
% =========================================================================

%%  Decoding from Null subspace

%% Clear workspace and set up environment
clear all
close all
clc

%% Load required data
CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'Decoding_null.mat'])

rng(0)

All_Area_Accuracy_Null=[];
All_Area_Accuracy_Potent=[];
%% Optional: Change figure name
change_name = 0;
newname = 'Figure5D_null_decoding';
fullname = mfilename('fullpath');
inds = regexp(fullname,'\','all');
name = fullname(inds(end)+1:end);
if change_name
    movefile([name '.m'],[newname '.m']);
end

%% Initialize main figure
figure('Position',[200 200 1200 500]);
h = tight_subplot(1,2,[.1 .1],[.13 .03],[.1 .01]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters
arealist = {'A1','wS1','wS2','wM2','ALM'};  % Brain regions
colormap = {'#0008FF';'#228B22';'#ff0000';'#000000';'#FF00FF'};
colortype = {'wS1';'wS2';'ALM';'wM2';'A1'};
Map = horzcat(colortype,colormap);
params.Win1 = [-.8,0];  % Window 1 for statistical comparison
params.Win2 = [.8,1];   % Window 2 for statistical comparison

Accuracy_Null=[];

%% Define analysis parameters
windowCenters = [-.99:0.01:2];
flg = 0;

%% Process each brain area
for areacounter = arealist
    flg = flg + 1;
    area = cell2mat(areacounter);
    indcolor = find(strcmp(area,Map(:,1)));

    current_Nb_mat = Accuracy;

    % Find non-empty sessions for current area
    ind_nonempty = find(~cellfun(@isempty,current_Nb_mat.sessionaddress.(area)));
    currsig = current_Nb_mat.(area);
    currsig = nanmean(currsig,3)';
    currsig = currsig(:,ind_nonempty);

    % Calculate mean and standard error
    meansig = nanmean(currsig,2);
    semsig = nanstd(currsig,[],2)./sqrt(size(currsig,2));
    curve1 = meansig + semsig;
    curve2 = meansig - semsig;
    x2 = [windowCenters,fliplr(windowCenters)];
    inBetween = [curve1', fliplr(curve2')];

    % Plot with error shading
    fill(axs(1),x2, inBetween, hex2rgb(cell2mat(Map(indcolor,2))),'FaceAlpha',0.3,'LineStyle','none');
    hold(axs(1),'on');
    plot(axs(1),windowCenters,meansig,'color',hex2rgb(cell2mat(Map(indcolor,2))),'Linewidth',1);

    %% Calculate statistics for comparison windows
    [a,b] = min(abs(windowCenters-params.Win1(1))); W1FirstBin = (b);
    [a,b] = min(abs(windowCenters-params.Win1(2))); W1LastBin = (b);
    [a,b] = min(abs(windowCenters-params.Win2(1))); W2FirstBin = (b);
    [a,b] = min(abs(windowCenters-params.Win2(2))); W2LastBin = (b);

    V1 = mean(currsig(W1FirstBin:W1LastBin,:),1);
    V2 = mean(currsig(W2FirstBin:W2LastBin,:),1);

%     eval(['Accuracy_Null.' area '=V2;']);

    % Plot statistical comparison
    hold(h(2),'on');
    plot(h(2),[flg,flg+.4],[V1',V2'],'-', 'Linewidth',1, 'Color', [0.7 0.7 0.7]);
    errorbar(h(2),[flg-.1,flg+.4+.1],[nanmean(V1),nanmean(V2)],[nanstd(V1,0),nanstd(V2,0)],'-ok','CapSize',0,'Linewidth',2, 'Markersize',8);
    pval(flg) = P_value(V1,V2);
    Decoding_Null_Pvalue.(area)= P_value(V1,V2);
end % End of area loop

%% Format plots
yline(axs(1),50);
xline(axs(1),0);
xline(axs(1),1);
ylim(axs(1),[40,100]);
xlabel(h(1),'Time (s)');
ylabel(h(1),'Accuracy (%)');

yticklabels(h(2),get(h(2),'YTick'));
xticks(h(2),[1:5]+.2);
xticklabels(h(2),arealist);
ylabel(h(2),'Accuracy (%)');

%% Apply final plot formatting
prettify_plot('LineThickness', 1,'TickWidth',1.5,'AxisTightness', 'keep','TickLength',[.01 .001],'PointSize',4);

%% Add statistical significance indicators
prettify_pvalues(axs(2), [1,2,3,4,5], [1.5,2.5,3.5,4.5,5.5], pval,'PlotNonSignif', true,'OnlyStars',false);

%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '_Null.pdf'], 'ContentType', 'vector');

%% Create Data srtructure for the Data File

[a,b] = min(abs(windowCenters-params.Win1(1))); W1FirstBin = (b);
[a,b] = min(abs(windowCenters-params.Win1(2))); W1LastBin = (b);
[a,b] = min(abs(windowCenters-params.Win2(1))); W2FirstBin = (b);
[a,b] = min(abs(windowCenters-params.Win2(2))); W2LastBin = (b);

for areacounter = arealist

    area = cell2mat(areacounter);

    % Process each neuron count

    Acc_delay=[];
    Acc_baseline=[];
    Acc_One_area=[];
    currsig=[];

    currsig = Accuracy.(area);
    ind_empty = find(cellfun(@isempty,Accuracy.sessionaddress.(area)));
    currsig = nanmean(currsig,3)';


    Acc_delay(1,:)=mean(currsig(W2FirstBin:W2LastBin,:),1);
    Acc_delay(1,ind_empty)=NaN;


    Acc_baseline=mean(currsig(W1FirstBin:W1LastBin,:),1);
    Acc_baseline(1,ind_empty)=NaN;


    Acc_One_area=vertcat(Acc_baseline, Acc_delay);

    All_Area_Accuracy_Null.(area)=Acc_One_area';
end
%%  Decoding from Potent subspace

%% Clear workspace and set up environment
clearvars -except All_Area_Accuracy_Null Decoding_Null_Pvalue

%% Load required data
CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'Decoding_potent.mat'])


%% Optional: Change figure name
change_name = 0;
newname = 'Figure5D_potent_decoding';
fullname = mfilename('fullpath');
inds = regexp(fullname,'\','all');
name = fullname(inds(end)+1:end);
if change_name
    movefile([name '.m'],[newname '.m']);
end

%% Initialize main figure
figure('Position',[200 200 1200 500]);
h = tight_subplot(1,2,[.1 .1],[.13 .03],[.1 .01]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters
arealist = {'A1','wS1','wS2','wM2','ALM'};  % Brain regions
colormap = {'#0008FF';'#228B22';'#ff0000';'#000000';'#FF00FF'};
colortype = {'wS1';'wS2';'ALM';'wM2';'A1'};
Map = horzcat(colortype,colormap);
params.Win1 = [-.8,0];  % Window 1 for statistical comparison
params.Win2 = [.8,1];   % Window 2 for statistical comparison

%% Define analysis parameters
windowCenters = [-.99:0.01:2];
flg = 0;

%% Process each brain area
for areacounter = arealist
    flg = flg + 1;
    area = cell2mat(areacounter);
    indcolor = find(strcmp(area,Map(:,1)));

    current_Nb_mat = Accuracy;

    % Find non-empty sessions for current area
    ind_nonempty = find(~cellfun(@isempty,current_Nb_mat.sessionaddress.(area)));
    currsig = current_Nb_mat.(area);
    currsig = nanmean(currsig,3)';
    currsig = currsig(:,ind_nonempty);

    % Calculate mean and standard error
    meansig = nanmean(currsig,2);
    semsig = nanstd(currsig,[],2)./sqrt(size(currsig,2));
    curve1 = meansig + semsig;
    curve2 = meansig - semsig;
    x2 = [windowCenters,fliplr(windowCenters)];
    inBetween = [curve1', fliplr(curve2')];

    % Plot with error shading
    fill(axs(1),x2, inBetween, hex2rgb(cell2mat(Map(indcolor,2))),'FaceAlpha',0.3,'LineStyle','none');
    hold(axs(1),'on');
    plot(axs(1),windowCenters,meansig,'color',hex2rgb(cell2mat(Map(indcolor,2))),'Linewidth',1);

    %% Calculate statistics for comparison windows
    [a,b] = min(abs(windowCenters-params.Win1(1))); W1FirstBin = (b);
    [a,b] = min(abs(windowCenters-params.Win1(2))); W1LastBin = (b);
    [a,b] = min(abs(windowCenters-params.Win2(1))); W2FirstBin = (b);
    [a,b] = min(abs(windowCenters-params.Win2(2))); W2LastBin = (b);

    V1 = mean(currsig(W1FirstBin:W1LastBin,:),1);
    V2 = mean(currsig(W2FirstBin:W2LastBin,:),1);

    % Plot statistical comparison
    hold(h(2),'on');
    plot(h(2),[flg,flg+.4],[V1',V2'],'-', 'Linewidth',1, 'Color', [0.7 0.7 0.7]);
    errorbar(h(2),[flg-.1,flg+.4+.1],[nanmean(V1),nanmean(V2)],[nanstd(V1,0),nanstd(V2,0)],'-ok','CapSize',0,'Linewidth',2, 'Markersize',8);
    pval(flg) = P_value(V1,V2);
    Decoding_Potent_Pvalue.(area)= P_value(V1,V2);

end % End of area loop

%% Format plots
yline(axs(1),50);
xline(axs(1),0);
xline(axs(1),1);
ylim(axs(1),[40,100]);
xlabel(h(1),'Time (s)');
ylabel(h(1),'Accuracy (%)');

yticklabels(h(2),get(h(2),'YTick'));
xticks(h(2),[1:5]+.2);
xticklabels(h(2),arealist);
ylabel(h(2),'Accuracy (%)');

%% Apply final plot formatting
prettify_plot('LineThickness', 1,'TickWidth',1.5,'AxisTightness', 'keep','TickLength',[.01 .001],'PointSize',4);

%% Add statistical significance indicators
prettify_pvalues(axs(2), [1,2,3,4,5], [1.5,2.5,3.5,4.5,5.5], pval,'PlotNonSignif', false,'OnlyStars',false);

%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '_Potent.pdf'], 'ContentType', 'vector');

%%
% Create Data srtructure for the Data File

[a,b] = min(abs(windowCenters-params.Win1(1))); W1FirstBin = (b);
[a,b] = min(abs(windowCenters-params.Win1(2))); W1LastBin = (b);
[a,b] = min(abs(windowCenters-params.Win2(1))); W2FirstBin = (b);
[a,b] = min(abs(windowCenters-params.Win2(2))); W2LastBin = (b);

for areacounter = arealist

    area = cell2mat(areacounter);

    % Process each neuron count

    Acc_delay=[];
    Acc_baseline=[];
    Acc_One_area=[];
    currsig=[];

    currsig = Accuracy.(area);
    ind_empty = find(cellfun(@isempty,Accuracy.sessionaddress.(area)));
    currsig = nanmean(currsig,3)';


    Acc_delay(1,:)=mean(currsig(W2FirstBin:W2LastBin,:),1);
    Acc_delay(1,ind_empty)=NaN;


    Acc_baseline=mean(currsig(W1FirstBin:W1LastBin,:),1);
    Acc_baseline(1,ind_empty)=NaN;


    Acc_One_area=vertcat(Acc_baseline, Acc_delay);

    All_Area_Accuracy_Potent.(area)=Acc_One_area';
end
