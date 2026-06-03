%% =========================================================================
% Ghaderi2025_Figure8A_CDcontext_stim_lickNolick.m
% =========================================================================
%
% This script generates Figure 8A showing coding direction analysis for context vs stimulus
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script analyzes coding direction (CD) relationships between context and stimulus
% across different brain areas and trial conditions. It plots trajectories in CD space showing
% how neural activity evolves for different trial types.
%
% Dependencies:
%   - psth_mat.mat (contains trial data)
%   - coding_direction5ms.mat (contains coding direction data)
%   - tight_subplot.m (for subplot management)
%   - prettify_plot.m (for plot formatting)
%   - hex2rgb.m (for color conversion)
%
% Output: PDF figure showing coding direction analysis
% =========================================================================

%% Clear workspace and set up environment
% clear all
close all
clc

%% Optional: Change figure name

change_name = 0;
newname = 'Figure8A_CDcontext_stim_lickNolick';
fullname = mfilename('fullpath');
inds = regexp(fullname,'\','all');
name = fullname(inds(end)+1:end);
if change_name
    movefile([name '.m'],[newname '.m']);
end

%% Load required data

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'Coding_direction_5ms.mat'])
load([directory filesep 'data_helpers' filesep 'Area_list.mat'])

%% Initialize main figure

parent = figure('Position', [200 200 1400 300]);
h = tight_subplot(1,5,[0 .04],[.2 .1],[0.08 0.01]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters

plottype = 'plot';  % 'scatter'
n_colors = 50;
reds = RedColors(n_colors);
blue = BlueColors(n_colors);
gray = GrayColors(n_colors);
colorcodes = [blue(n_colors,:);blue(n_colors/2,:);reds(n_colors,:);reds(n_colors/2,:);gray(n_colors,:);gray(n_colors/2,:)];
colorscheme = {blue,blue,reds,reds,gray,gray};
scattersize = [15,5,15,5,15,5];
linewidth = [2.5,1,2.5,1,2.5,1];
params.trialtypes = {'Ind=[ trial==1 & lick==1];';'Ind=[ trial==1 & lick==0];';'Ind=[ trial==3 & lick==1];';'Ind=[ trial==3 & lick==0];';'Ind=[ trial==5 & lick==1];';'Ind=[ trial==5 & lick==0];'};
params.baseline_win = [-1,0];
XTickLabel = {'-1';'0';'1';'2'};
xtick = [-1;0;1;2];
smoothed = 1;
params.arealist = {'A1','wS1','wS2','wM2','ALM'};

t1_show = 1;
t2_show = 1.03;
t_tone = 0;
t_whisker = 1;
Wbaseline = [-1,-.1];
expr2 = 'currMat=context_concat;';

baselinesubtraction = 0; % Define baseline subtraction parameter

%% Process each brain area

for ind_area = 1:length(params.arealist)

    currentarea = cell2mat(params.arealist(ind_area));

    % Process each trial condition
    for ind_cond = 1:length(params.trialtypes)

        current_cond_name = cell2mat(params.trialtypes(ind_cond));

        if isempty(current_cond_name)
            continue;
        end

        context_concat = [];
        stim_concat = [];
        lick_concat = [];

        % Process each session
        for ind_session = 1:size(coding_direction_matrix.(currentarea),2)

            current_context = coding_direction_matrix.(currentarea)(ind_session).Contextproj;
            current_stim = coding_direction_matrix.(currentarea)(ind_session).Stimproj;
            current_lick = coding_direction_matrix.(currentarea)(ind_session).lickproj;
            trial = coding_direction_matrix.(currentarea)(ind_session).index.trial;

            if ~isnan(trial)
                lick = coding_direction_matrix.(currentarea)(ind_session).index.lick;
                Quietind = coding_direction_matrix.(currentarea)(ind_session).index.Quiet;
                Completed = coding_direction_matrix.(currentarea)(ind_session).index.completed_trial;

                eval(current_cond_name);
                trial_indecis = Ind & Quietind & Completed;
                current_context = current_context(:,trial_indecis);

                % Apply baseline subtraction if requested

                if baselinesubtraction
                    context_baseline = mean(current_context(1:100,:),1);
                    current_context = current_context - repmat(context_baseline,size(current_context,1),1);

                    context_concat = [context_concat,current_context];
                    stim_concat = [stim_concat,current_stim(:,trial_indecis)];
                    lick_concat = [lick_concat,current_lick(:,trial_indecis)];
                else
                    context_concat = [context_concat,current_context];
                    stim_concat = [stim_concat,current_stim(:,trial_indecis)];
                    lick_concat = [lick_concat,current_lick(:,trial_indecis)];
                end
            end

        end % End of session loop

        % Calculate trajectory matrix

        trajectory_matrix = [nanmean(context_concat,2),nanmean(stim_concat,2),nanmean(lick_concat,2)];
        plot(axs(ind_area), trajectory_matrix(400:406,1),trajectory_matrix(400:406,2),'o','color',colorcodes(ind_cond,:));
        hold(axs(ind_area),'on');

        % Apply smoothing if requested

        if smoothed

            trajectory_matrix_smoothed(:,1) = spline(windowCenters,trajectory_matrix(:,1),[windowCenters(1):0.001:windowCenters(end)]);
            trajectory_matrix_smoothed(:,2) = spline(windowCenters,trajectory_matrix(:,2),[windowCenters(1):0.001:windowCenters(end)]);
            trajectory_matrix_smoothed(:,3) = spline(windowCenters,trajectory_matrix(:,3),[windowCenters(1):0.001:windowCenters(end)]);
            trajectory_matrix = trajectory_matrix_smoothed;

            windowCenters_smoothed = [windowCenters(1):0.001:windowCenters(end)];

            [a,b] = min(abs(windowCenters_smoothed-t1_show)); firstBin = (b);
            [a,b] = min(abs(windowCenters_smoothed-t2_show)); lastBin = (b);
            [a,b] = min(abs(windowCenters_smoothed-t_tone)); ToneBin = (b);
            [a,b] = min(abs(windowCenters_smoothed-t_whisker)); WhiskerBin = (b);

        end

        % Plot trajectory based on type

        switch plottype
            case 'plot'
                plot(axs(ind_area), trajectory_matrix(firstBin:lastBin,1),trajectory_matrix(firstBin:lastBin,2),'color',colorcodes(ind_cond,:),'linewidth',linewidth(ind_cond));
            case 'scatter'
                scatter(axs(ind_area), trajectory_matrix(firstBin:lastBin,1),trajectory_matrix(firstBin:lastBin,2),scattersize(ind_cond),colorscheme{ind_cond}(1:41,:),'filled');
        end

        hold(axs(ind_area),'on');
        plot(axs(ind_area),trajectory_matrix(WhiskerBin,1),trajectory_matrix(WhiskerBin,2), 'o', 'color',[1 .5 0],'MarkerSize',6);

    end % End of trial condition loop

    % Set plot limits and labels

    xlim(axs(ind_area),[-0.1,.7]);
    ylim(axs(ind_area),[-.1,1.5]);
    title(axs(ind_area),currentarea);

    xlabel(h(ind_area),'Context CD (a.u)');
    if ind_area==1
        ylabel(h(1),'Whisker CD (a.u)');
    end

    prettify_plot('LineThickness', 1,'TickWidth',1.5,'AxisTightness', 'keep','TickLength',[.01 .001],'PointSize',6);

   
end % End of brain area loop

%% Add axis labels and formatting

plot(axs(4),[0.63],[0.6], 'o', 'color',[0 0.7 1],'MarkerSize',40, 'LineWidth',2);
        
%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');

