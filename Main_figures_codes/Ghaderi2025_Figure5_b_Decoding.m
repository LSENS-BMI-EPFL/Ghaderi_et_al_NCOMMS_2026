%% =========================================================================
% Ghaderi2025_Figure5B_Decoding50N.m
% =========================================================================
%
% This script generates Figure 5B showing decoding analysis with 50 neurons
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script analyzes decoding accuracy using 50 neurons across different brain areas.
% It plots temporal decoding accuracy curves and statistical comparisons between baseline and
% response periods for each brain region.
%
% Dependencies:
%   - psth_10ms.mat (contains trial data)
%   - Decoding_NbNeurons5_75.mat (contains decoding results for different neuron counts)
%   - tight_subplot.m (for subplot management)
%   - prettify_plot.m (for plot formatting)
%   - prettify_pvalues.m (for statistical significance plotting)
%   - hex2rgb.m (for color conversion)
%
% Output: PDF figure showing decoding analysis with 50 neurons
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc

%% Load required data
CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'Decoding_NbNeurons5_75.mat'])

%% Optional: Change figure name
change_name = 0;
newname = 'Figure5B_Decoding50N';
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

windowCenters = [-.99:0.01:2];
Nb_list = fieldnames(Accuracy);
Nb_list = {'Nb_neurons50'};  % Focus on 50 neurons
flg = 0;


%% Process each brain area

for areacounter = arealist
    flg = flg + 1;
    area = cell2mat(areacounter);
    indcolor = find(strcmp(area,Map(:,1)));

    Nb_name = cell2mat(Nb_list(1));
    current_Nb_mat = Accuracy.(Nb_name);

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
    Decoding_50N_Pval.(area)=P_value(V1,V2);

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
prettify_pvalues(axs(2), [1,2,3,4,5], [1.5,2.5,3.5,4.5,5.5], pval,'PlotNonSignif', false,'OnlyStars',false,'Yposition',70);

%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '_50Neurons.pdf'], 'ContentType', 'vector');


%% Accuracy as function of number of Neurons

%% Clear workspace and set up environment
clearvars -except Decoding_50N_Pval
clc

%% Load required data
CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'Decoding_NbNeurons5_50.mat'])

All_Area_Accuracy_50N=[];


%% Optional: Change figure name

change_name = 0;
newname = 'Figure5B_Decoding_AccxNeuron';
fullname = mfilename('fullpath');
inds = regexp(fullname,'\','all');
name = fullname(inds(end)+1:end);
if change_name
    movefile([name '.m'],[newname '.m']);
end

%% Initialize main figure

figure('Position',[200 200 500 500]);
h = tight_subplot(1,1,[.01 .01],[.2 .02],[.2 .03]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);
hold on;

%% Define analysis parameters

arealist = {'A1','wS1','wS2','wM2','ALM'};  % Brain regions
colormap = {'#0008FF';'#228B22';'#ff0000';'#000000';'#FF00FF'};
colortype = {'wS1';'wS2';'ALM';'wM2';'A1'};
Map = horzcat(colortype,colormap);
params.Win1 = [-.8,0];  % Window 1 for statistical comparison
params.Win2 = [.8,1];   % Window 2 for statistical comparison


%% Define analysis parameters
windowCenters = [-.99:0.01:2];
Nb_list = fieldnames(Accuracy);
flg = 0;

%% Process each brain area

for areacounter = arealist

    flg = flg + 1;
    area = cell2mat(areacounter);
    indcolor = find(strcmp(area,Map(:,1)));

    % Process each neuron count

    Acc_all_N_Nb=[];

    for Nb_id = 1:length(Nb_list')
        Nb_name = cell2mat(Nb_list(Nb_id));
        current_Nb_mat = Accuracy.(Nb_name);

        % Find non-empty sessions for current area
        ind_nonempty = find(~cellfun(@isempty,current_Nb_mat.sessionaddress.(area)));
        currsig = current_Nb_mat.(area);
        currsig = nanmean(currsig,3)';
        currsig = currsig(:,ind_nonempty);

        % Calculate statistics for window 2
        [a,b] = min(abs(windowCenters-params.Win1(1))); W1FirstBin = (b);
        [a,b] = min(abs(windowCenters-params.Win1(2))); W1LastBin = (b);
        [a,b] = min(abs(windowCenters-params.Win2(1))); W2FirstBin = (b);
        [a,b] = min(abs(windowCenters-params.Win2(2))); W2LastBin = (b);

        % Calculate mean accuracy and standard error
        Acc_1_N_Nb=mean(currsig(W2FirstBin:W2LastBin,:),1);
        M = mean(mean(currsig(W2FirstBin:W2LastBin,:),1));
        S = std(mean(currsig(W2FirstBin:W2LastBin,:),1))/sqrt(length(mean(currsig(W2FirstBin:W2LastBin,:),1)));
        acc.(area)(Nb_id) = M;
        acc_sem.(area)(Nb_id) = S;
%         Acc_all_N_Nb=horzcat(Acc_all_N_Nb,Acc_1_N_Nb');
    end % End of neuron count loop

    % Plot accuracy curve for current area
    plot(acc.(area),'LineStyle','--','Marker','o','color',hex2rgb(cell2mat(Map(indcolor,2))));
    hold on;
    errorbar(acc.(area), acc_sem.(area),'color',hex2rgb(cell2mat(Map(indcolor,2))));

end % End of area loop

%% Format plot
xlim([0 11])
ylim([49 66])
xticks(1:length(Nb_list'));
xticklabels([5:5:50]);

yticklabels(axs,get(axs,'Ytick'));
xlabel('# Neurons (s)');
ylabel('Accuracy (%)');

%% Add legend
legend_just_txt(gca,arealist,'Xoffset',1.02,'Yoffset',62,'relX',0,'relY',0.055,'type','line');

%% Apply final plot formatting
prettify_plot('LineThickness', 1,'TickWidth',1.5,'AxisTightness', 'keep','TickLength',[.01 .001],'PointSize','keep');

%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '_XNeurons.pdf'], 'ContentType', 'vector');

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

    for Nb_id = 1:length(Nb_list')
        Nb_name = cell2mat(Nb_list(Nb_id));
        current_Nb_mat = Accuracy.(Nb_name);
        ind_empty = find(cellfun(@isempty,current_Nb_mat.sessionaddress.(area)));

        currsig = current_Nb_mat.(area);
        currsig = nanmean(currsig,3)';

       
        Acc_delay(Nb_id,:)=mean(currsig(W2FirstBin:W2LastBin,:),1);
        Acc_delay(Nb_id,ind_empty)=NaN;

        if strcmp(Nb_name, 'Nb_neurons50')
            
            Acc_baseline=mean(currsig(W1FirstBin:W1LastBin,:),1);
            Acc_baseline(1,ind_empty)=NaN;
        end
        
    end
    
    Acc_One_area=vertcat(Acc_baseline, Acc_delay);
       
    All_Area_Accuracy_50N.(area)=Acc_One_area';
end