%% =========================================================================
% Ghaderi2025_Figure5C_DropoutClusters_heatmap.m
% =========================================================================
%
% This script generates Figure 5C showing cluster dropout heatmap
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script creates a heatmap showing the effect of dropping different cell clusters
% on decoding performance across brain areas. It visualizes the difference in decoding accuracy
% when specific clusters are removed compared to random dropout.
%
% Dependencies:
%   - Decoding_clusters_random_dropout.mat (contains cluster dropout results)
%   - Decoding_delay.mat (contains baseline decoding results)
%   - tight_subplot.m (for subplot management)
%   - prettify_plot.m (for plot formatting)
%   - SC_Scale2Color.m (for color scaling)
%
% Output: PDF figure showing cluster dropout heatmap
% =========================================================================

%% Clear workspace and set up environment
clear all
% close all
clc

%% Optional: Change figure name
change_name = 0;
newname = 'Figure5C_DropoutClusters_heatmap';
fullname = mfilename('fullpath');
inds = regexp(fullname,'\','all');
name = fullname(inds(end)+1:end);
if change_name
    movefile([name '.m'],[newname '.m']);
end

%% Define analysis parameters
arealist = {'A1','wS1','wS2','wM2','ALM'};  % Brain regions
params.Win1 = [-1,0];  % Window 1 for statistical comparison
params.Win2 = [.8,1];  % Window 2 for statistical comparison


%% Load required data
CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'Decoding_clusters_random_dropout.mat'])
load([directory filesep 'processed_data' filesep 'Decoding_delay.mat'])


%% Initialize heatmap matrix
heatmaps = nan(5,29);
names = fieldnames(ACC);
All_Area_Delta_ACC=[];
All_Area_Delta_ACC_pvalues=[];
All_Area_Delta_ACC_pvalues_Corr=[];
%% Initialize main figure
figure('Units','centimeters','Position',[2 2 30 15],'PaperType','A4','PaperUnits','centimeters','PaperSize',[21 29.7],'PaperPosition',[1 1 20 25]);
h = tight_subplot(1,1,[.1 .1],[.2 .015],[.1 .1]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Process each cluster
cluster_cnt = 0;
fig_cnt = 1;
flg_c = 1;


for clusters = names'
    cluster_cnt = cluster_cnt + 1;
    cluster_name = cell2mat(clusters);
    flg = 0;
    
    %% Get cluster-specific data
    Accuracy_clus_selection = ACC.(cluster_name).Accuracy;
    windowCenters = ACC.(cluster_name).windowCenters;
    
    d = 0;
    
    [a,b] = min(abs(windowCenters-params.Win2(1))); W2FirstBin = (b);
    [a,b] = min(abs(windowCenters-params.Win2(2))); W2LastBin = (b);

    %% Process each brain area
    for areacounter = arealist
        d = d + .1;
        flg = flg + 1;
        area = cell2mat(areacounter);
        
        %% Get accuracy data for different conditions
        currsig_clus_droped = Accuracy_clus_selection.(area)';
        currsig_all_selected = Accuracy.(area)';
        
        % Handle special case for A1 cluster1
        if strcmp(area,'A1') && strcmp(cluster_name,'cluster1')
            currsig_all_selected(:,6) = zeros(300,1);
        end
        
        % Remove empty sessions
        currsig_all_selected(:,all(currsig_all_selected==0)) = NaN;
        currsig_clus_droped(:,all(currsig_clus_droped==0)) = NaN;
        
        %% Calculate difference between cluster dropout and baseline
        delta = currsig_clus_droped - currsig_all_selected;
        meansig=mean(delta(W2FirstBin:W2LastBin,:),1);

               
        %% Calculate statistics for window 2
        
        V2=[];
        V2 = mean(meansig,2, 'omitnan');
       
        
        %% Store value in heatmap matrix
        heatmaps(flg,cluster_cnt) = V2;
        
        %% Calculate color for heatmap
        [C] = SC_Scale2Color(V2, -4, 4, 0);
        colors(flg_c,:) = C;
        
        %% Calculate p-value
        A=[];
        A=rmmissing(meansig);
        P = signrank(A);
        flg_c = flg_c + 1;

        
        All_Area_Delta_ACC.(area)(:,cluster_cnt)=meansig';
        All_Area_Delta_ACC_pvalues(flg,cluster_cnt)=P;
    end % End of area loop
end % End of cluster loop

%% Create heatmap
names = [1:29];
axes(axs(1));
h_map = heatmap(-heatmaps,'YLabel','Areas','XLabel','Clusters','XDisplayLabels',names,'YDisplayLabels',arealist);

%% Set color limits and colormap
MAX = 4;
MIN = -4;
zero = 0;
cyan = [0 128 255]/255;
pink = [255 0 128]/255;

% Create colormap for negative values
min_max_scale = [100;0];
min_max_rgb_neg = [0 0 0;pink];
map_neg = interp1(min_max_scale,min_max_rgb_neg,linspace(90,0,abs(MIN)));

% Create colormap for positive values
min_max_scale = [100;0];
min_max_rgb_pos = [0,0,0;cyan];
map_pos = interp1(min_max_scale,min_max_rgb_pos,linspace(90,0,abs(MAX)));

clim([MIN,MAX]);
MAP = [flipud(map_neg);map_pos];

%% Apply colormap and add colorbar
colormap(h_map,"parula");
colorbar;

%% Apply fdr correction to P values from one cluster
for i=1:size(names,2)
Vector_Pvalues=[];
Vector_Pvalues=All_Area_Delta_ACC_pvalues(:,i);

p_values_Corr=[];
p_values_Corr = mafdr(Vector_Pvalues, 'BHFDR', 'True');

All_Area_Delta_ACC_pvalues_Corr(:,i)=p_values_Corr;
end
%% Export figure

directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');

