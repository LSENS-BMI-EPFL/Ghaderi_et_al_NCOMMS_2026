%% =========================================================================
% Ghaderi2025_Figure8B_contextCD_licknolick.m
% =========================================================================
%
% This script generates Figure 8B showing context coding direction analysis for lick vs no-lick
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script analyzes context coding direction (CD) across different brain areas
% and trial conditions, comparing lick vs no-lick trials. It plots temporal evolution of context CD
% and performs statistical comparisons between different trial types.
%
% Dependencies:
%   - psth_mat.mat (contains trial data)
%   - coding_direction5ms.mat (contains coding direction data)
%   - area_list.mat (contains brain area information)
%   - tight_subplot.m (for subplot management)
%   - prettify_plot.m (for plot formatting)
%   - prettify_pvalues.m (for statistical significance plotting)
%
% Output: PDF figure showing context coding direction analysis
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc

%% Optional: Change figure name

change_name = 0;
newname = 'Figure8B_contextCD_licknolick';
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

parent = figure('Position', [200 200 1400 600]);
h = tight_subplot(2,5,[.09 .05],[.08 .08],[.1 .05]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

ind_figures = [reshape([1:10]',5,2)]'; % Define subplot indices

%% Define analysis parameters

params.arealist = {'A1','wS1','wS2','wM2','ALM'};
params.Win1 = [-1,0];  % Window 1 for statistical comparison
params.Win2 = [1.03,1.03];  % Window 2 for statistical comparison

min_num_trials = 4; % Define minimum number of trials parameter
% baselinesubtraction = 0; % Define baseline subtraction parameter

NaN_Vector(1:600,1)=NaN;

colorcodes = [[0 0 255];
    [255 0 0];
    [0 0 0];
    [170 170 255];
    [255 170 170];
    [170 170 170]]/255;
params.trialtypes = {'Ind=[ trial==1 & lick==1]';'Ind=[ trial==3 & lick==1]';'Ind=[ trial==5 & lick==1]';'Ind=[ trial==1 & lick==0]';'Ind=[ trial==3 & lick==0]';'Ind=[ trial==5 & lick==0]'};

params.baseline_win = [-1,0];
XTickLabel = {'-1';'0';'1';'2'};
xtick = [-1;0;1;2];
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

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

            if isnan(coding_direction_matrix.(currentarea)(ind_session).Contextproj)

                session2drop.(currentarea)(ind_session,ind_cond) = 1;

            else

                current_context = coding_direction_matrix.(currentarea)(ind_session).Contextproj;
                current_stim = coding_direction_matrix.(currentarea)(ind_session).Stimproj;
                current_lick = coding_direction_matrix.(currentarea)(ind_session).lickproj;
                lick = coding_direction_matrix.(currentarea)(ind_session).index.lick;
                trial = coding_direction_matrix.(currentarea)(ind_session).index.trial;
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

                current_context = coding_direction_matrix.(currentarea)(ind_session).Contextproj;
                current_stim = coding_direction_matrix.(currentarea)(ind_session).Stimproj;

                lick = coding_direction_matrix.(currentarea)(ind_session).index.lick;
                trial = coding_direction_matrix.(currentarea)(ind_session).index.trial;
                Quietind = coding_direction_matrix.(currentarea)(ind_session).index.Quiet;
                Completed = coding_direction_matrix.(currentarea)(ind_session).index.completed_trial;

                eval(current_cond_name);
                trial_indecis = Ind & Quietind & Completed;
                current_context = current_context(:,trial_indecis);
                current_stim = current_stim(:,trial_indecis);

                context_concat = [context_concat,nanmean(current_context,2)];
                
            else
                context_concat = [context_concat,NaN_Vector];
            end

        end % End of session loop

        % Plot context coding direction

        signal2plot=context_concat;
        meansig = nanmean(signal2plot,2);
        semsig = nanstd(signal2plot,[],2)./sqrt(sum(~isnan(signal2plot(1,:))));
        curve1 = meansig + semsig;
        curve2 = meansig - semsig;
        
        x2 = [windowCenters,fliplr(windowCenters)];
        inBetween = [curve1', fliplr(curve2')];
        fill(axs(ind_figures(1,ind_area)),x2, inBetween, colorcodes(ind_cond,:),'FaceAlpha',0.3,'LineStyle','none');
        hold(axs(ind_figures(1,ind_area)), 'on');
        plot(axs(ind_figures(1,ind_area)),windowCenters,meansig,'color',colorcodes(ind_cond,:),'Linewidth',.1);
        xlim(axs(ind_figures(1,ind_area)),[.95,1.1]);

        % Calculate statistics for comparison windows

        [a,b] = min(abs(windowCenters-params.Win1(1))); W1FirstBin = (b);
        [a,b] = min(abs(windowCenters-params.Win1(2))); W1LastBin = (b);
        [a,b] = min(abs(windowCenters-params.Win2(1))); W2FirstBin = (b);
        [a,b] = min(abs(windowCenters-params.Win2(2))); W2LastBin = (b);
        V2 = mean(context_concat(W2FirstBin:W2LastBin,:),1)';

        All_Area_CD.(currentarea)(:, ind_cond)=V2;

        % Plot statistical comparison

        hold(axs(ind_figures(2,ind_area)),'on');
        V2_values = [V2_values;[V2,ind_cond*ones(length(V2),1)]];
        bar(axs(ind_figures(2,ind_area)),[flg],nanmean(V2),'FaceColor',colorcodes(ind_cond,:));
        errorbar(axs(ind_figures(2,ind_area)),[flg],[nanmean(V2)],[nanstd(V2,0)]/sqrt(sum(~isnan(V2(:,1)))),'-k','CapSize',3,'Linewidth',1,'MarkerSize',4);
        plot(axs(ind_figures(2,ind_area)),[flg+.2],[V2]','ok','Color', [0.5 0.5 0.5],'Markersize',4,'markerfacecolor','none');

        % Calculate statistics

        mean_values{ind_area}(:,flg) = (V2');
        P(flg) = P_value(mean_values{ind_area}(:,1),mean_values{ind_area}(:,flg));

    end % End of trial condition loop

    % Perform statistical analysis
    [P_KWT,~,stats] = kruskalwallis(V2_values(:,1),V2_values(:,2),'off');
    [c,m,h,gnames] = multcompare(stats,'Display','off','CriticalValueType','lsd');

    All_Area_Stat_Pvalues.(currentarea).KWT=P_KWT;
    All_Area_Stat_Pvalues.(currentarea).MultiCmpT=c;

    % Format plots
    ylim(axs(ind_figures(1,ind_area)),[-.1,1]);
    ylim(axs(ind_figures(2,ind_area)),[-.4,2]);
    xlim(axs(ind_figures(2,ind_area)),[0,7]);
    axs(ind_figures(2,ind_area)).XAxis.Visible = 'off';

     if P_KWT<0.05

        prettify_pvalues(axs(ind_figures(2,ind_area)), c(:,1), c(:,2), c(:,6),'TickLength',0.02,'LineMargin',.05,'PlotNonSignif', false,'OnlyStars',true,'Yposition',1.1);
     end

    % Add reference lines and labels
    xline(axs(ind_figures(1,ind_area)),0);
    xline(axs(ind_figures(1,ind_area)),1);
    xline(axs(ind_figures(1,ind_area)),1.03,'Tag','t=30ms');
    yline(axs(ind_figures(1,ind_area)),0,'Tag','y=0');
    title(axs(ind_figures(1,ind_area)),currentarea);
    yticklabels(axs(ind_figures(2,ind_area)),get(axs(ind_figures(2,ind_area)),'YTick'));
    xlabel(axs(ind_figures(1,ind_area)),'Time (s)');

end % End of brain area loop


%% Add axis labels and formatting

ylabel(axs(ind_figures(1,1)),'Context CD (a.u)');
ylabel(axs(ind_figures(2,1)),'Context CD (a.u)');

prettify_plot('LineThickness', 1,'TickWidth',1.5,'AxisTightness', 'keep','TickLength',[.01 .001],'PointSize','keep');

%% Export figure
directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];
% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');

