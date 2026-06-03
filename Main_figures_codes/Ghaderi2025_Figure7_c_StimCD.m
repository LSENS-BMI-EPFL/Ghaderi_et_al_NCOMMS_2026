%% =========================================================================
% Ghaderi2025_Figure7B_StimCD.m
% =========================================================================
%
% This script generates Figure 7B showing stimulus coding direction analysis
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script analyzes stimulus coding direction (CD) across different brain areas
% and trial conditions. It plots temporal evolution of stimulus CD and statistical comparisons
% between baseline and response periods for each brain region.
%
% Dependencies:
%   - psth_mat.mat (contains trial data)
%   - coding_direction5ms.mat (contains coding direction data)
%   - area_list.mat (contains brain area information)
%   - tight_subplot.m (for subplot management)
%   - prettify_plot.m (for plot formatting)
%   - prettify_pvalues.m (for statistical significance plotting)
%
% Output: PDF figure showing stimulus coding direction analysis
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc

%% Optional: Change figure name
change_name = 0;
newname = 'Figure7B_StimCD';
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

parent = figure('Position', [200 200 1400 400]);

h = tight_subplot(1,5,[.09 .09],[.15 .08],[.1 .01]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters

min_num_trials = 4; % minimum number of trials to select a session

params.arealist = {'A1','wS1','wS2','wM2','ALM'};
params.Win1 = [-1,0];  % Window 1 for statistical comparison
params.Win2 = [1.03,1.03];  % Window 2 for statistical comparison

baselinesubtraction = 0; % Define baseline subtraction parameter


colorcodes = [[0 0 255];
    [255 0 0];
    [0 0 0];
    [170 170 255];
    [255 170 170];
    [170 170 170]]/255;
params.trialtypes = {'Ind=[ trial==1 & lick==1]';'Ind=[ trial==3 & lick==0]'};

params.baseline_win = [-1,0];
XTickLabel = {'-1';'0';'1';'2'};
xtick = [-1;0;1;2];
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

ind_figuers = [reshape([1:10]',5,2)]'; % Define subplot indices

%% Find sessions to drop based on minimum trial count

for ind_area = 1:length(params.arealist)
    currentarea = cell2mat(params.arealist(ind_area));
    session2drop.(currentarea) = zeros(size(coding_direction_matrix.(currentarea),2),length(params.trialtypes));

    for ind_cond = 1:length(params.trialtypes)

        current_cond_name = cell2mat(params.trialtypes(ind_cond));
        context_concat = [];
        stim_concat = [];
        lick_concat = [];

        for ind_session = 1:size(coding_direction_matrix.(currentarea),2)
            current_stim = coding_direction_matrix.(currentarea)(ind_session).Stimproj;
            trial = coding_direction_matrix.(currentarea)(ind_session).index.trial;

            if isnan(trial)

                session2drop.(currentarea)(ind_session,ind_cond) = 1;

            else
                lick = coding_direction_matrix.(currentarea)(ind_session).index.lick;
                Quietind = coding_direction_matrix.(currentarea)(ind_session).index.Quiet;
                Completed = coding_direction_matrix.(currentarea)(ind_session).index.completed_trial;
                eval(current_cond_name);
                trial_indecis = Ind & Quietind & Completed;

                if sum(trial_indecis) < min_num_trials
                    session2drop.(currentarea)(ind_session,ind_cond) = 1;
                end
            end

        end % End of session loop

    end % End of condition loop

end % End of area loop

%% Process each brain area

for ind_area = 1:length(params.arealist)

    currentarea = cell2mat(params.arealist(ind_area));
    flg = 0;
    pval = [];
    V2_values = [];

    % Process each trial condition
    for ind_cond = 1:length(params.trialtypes)

        flg = flg + 1;
        current_cond_name = cell2mat(params.trialtypes(ind_cond));
        if isempty(current_cond_name)
            continue;
        end
        context_concat = [];
        stim_concat = [];
        lick_concat = [];

        % Process each session

        for ind_session = 1:size(coding_direction_matrix.(currentarea),2)

            if session2drop.(currentarea)(ind_session,ind_cond)==0

                current_stim = coding_direction_matrix.(currentarea)(ind_session).Stimproj;
                lick = coding_direction_matrix.(currentarea)(ind_session).index.lick;
                trial = coding_direction_matrix.(currentarea)(ind_session).index.trial;
                Quietind = coding_direction_matrix.(currentarea)(ind_session).index.Quiet;
                Completed = coding_direction_matrix.(currentarea)(ind_session).index.completed_trial;
                eval(current_cond_name);
                trial_indecis = Ind & Quietind & Completed;
                current_stim = current_stim(:,trial_indecis);

                % Apply baseline subtraction if requested

                if baselinesubtraction
                    stim_concat = [stim_concat,current_stim];
                else
                    stim_concat = [stim_concat,nanmean(current_stim,2)];
                end

            end

        end % End of session loop

        % Plot stimulus coding direction

%         session2keep = find(all(~session2drop.(currentarea),2));
%         numsession.(currentarea) = length(session2keep);
%         signal2plot = stim_concat(:,session2keep);
%         meansig = nanmean(signal2plot,2);
%         semsig = nanstd(signal2plot,[],2)./sqrt(size(signal2plot,2));

        meansig = nanmean(stim_concat,2);
        semsig = nanstd(stim_concat,[],2)./sqrt(size(stim_concat,2));
        curve1 = meansig + semsig;
        curve2 = meansig - semsig;
        x2 = [windowCenters,fliplr(windowCenters)];
        inBetween = [curve1', fliplr(curve2')];
        fill(axs(ind_figuers(1,ind_area)),x2, inBetween, colorcodes(ind_cond,:),'FaceAlpha',0.3,'LineStyle','none');
        hold(axs(ind_figuers(1,ind_area)), 'on');
        plot(axs(ind_figuers(1,ind_area)),windowCenters,meansig,'color',colorcodes(ind_cond,:),'Linewidth',.1);
        xlim(axs(ind_figuers(1,ind_area)),[.95,1.1]);

        % Calculate statistics for comparison windows

        [a,b] = min(abs(windowCenters-params.Win1(1))); W1FirstBin = (b);
        [a,b] = min(abs(windowCenters-params.Win1(2))); W1LastBin = (b);
        [a,b] = min(abs(windowCenters-params.Win2(1))); W2FirstBin = (b);
        [a,b] = min(abs(windowCenters-params.Win2(2))); W2LastBin = (b);
        V2 = mean(stim_concat(W2FirstBin:W2LastBin,:),1)';     
        V2_values = [V2_values;[V2,ind_cond*ones(length(V2),1)]];
        
        % Calculate statistics
        mean_values{ind_area}(:,flg) = (V2');
        P(flg) = P_value(mean_values{ind_area}(:,1),mean_values{ind_area}(:,flg));

        if strcmp(currentarea, 'ALM')

            ALM_Response(:,ind_cond)=(V2');

        end

    end % End of trial condition loop

    % Perform statistical analysis
    [~,~,stats] = kruskalwallis(V2_values(:,1),V2_values(:,2),'off');
    [c,m,h,gnames] = multcompare(stats,'Display','off','CriticalValueType','lsd');

    %% Format plots
    ylim(axs(ind_figuers(1,ind_area)),[0 1.6]);

    %% Add reference lines and labels
    xline(axs(ind_figuers(1,ind_area)),0);
    xline(axs(ind_figuers(1,ind_area)),1);
    xline(axs(ind_figuers(1,ind_area)),1.03,'Tag','t=30ms');
    title(axs(ind_figuers(1,ind_area)),currentarea);
    xlabel(axs(ind_figuers(1,1)),'Time (s)');

end % End of brain area loop

%% Add axis labels and formatting
ylabel(axs(ind_figuers(1,1)),'Whisker CD (a.u)');

%% Apply final plot formatting
prettify_plot('LineThickness', 1,'TickWidth',1.5,'AxisTightness', 'keep','TickLength',[.01 .001],'PointSize','keep');


%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');


