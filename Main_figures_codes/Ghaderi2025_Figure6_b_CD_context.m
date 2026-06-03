%% =========================================================================
% Ghaderi2025_Figure6B_CD_context.m
% =========================================================================
%
% This script generates Figure 6B showing context coding direction analysis
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script analyzes context coding direction (CD) across different brain areas
% and trial conditions. It plots temporal evolution of context CD and statistical comparisons
% between baseline and response periods for each brain region.
%
% Dependencies:
%   - psth_10ms.mat (contains trial data)
%   - Coding_direction_10ms.mat (contains coding direction data)
%   - tight_subplot.m (for subplot management)
%   - legend_just_txt.m (for legend creation)
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
newname = 'Figure6B_CD_context';
fullname = mfilename('fullpath');
inds = regexp(fullname,'\','all');
name = fullname(inds(end)+1:end);
if change_name
    movefile([name '.m'],[newname '.m']);
end

%% Load required data

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'Coding_direction_10ms.mat'])


%% Initialize main figure

parent = figure('Position', [100 100 1400 600]);
h = tight_subplot(2,5,[.09 .09],[.08 .08],[.1 .01]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters
params.arealist = {'A1','wS1','wS2','wM2','ALM'};  % Brain regions
params.Win1 = [-1,0];  % Window 1 for statistical comparison
params.Win2 = [.8,1];  % Window 2 for statistical comparison

colorcodes = [[0 0 1]; % GoTone+W Hit
    [1 0 0]; % NogoTone+W CR
    [0 0.7 0.7]; % GoTone CR
    [0.5 0 0.8]]; % GoTone+W Miss


params.trialtypes = {'Ind=[ trial==1 & lick==1]';'Ind=[ trial==3 & lick==0]';'Ind=[ trial==2 & lick==0]';'Ind=[ trial==1 & lick==0]'};

params.baseline_win = [-1,0];
XTickLabel = {'-1';'0';'1';'2'};
xtick = [-1;0;1;2];
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define baseline subtraction parameter
baselinesubtraction = 0;

%% Define subplot indices
ind_figures = [reshape([1:10]',5,2)]';

%% Process each brain area

for ind_area = 1:length(params.arealist)
    currentarea = cell2mat(params.arealist(ind_area));
    flg = 0;
    pval = [];

    % Process each trial condition
    for ind_cond = 1:length(params.trialtypes)
        flg = flg + 1;

        % Get current condition name
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

            % Extract trial indices
            lick = coding_direction_matrix.(currentarea)(ind_session).index.lick;
            trial = coding_direction_matrix.(currentarea)(ind_session).index.trial;
            Quietind = coding_direction_matrix.(currentarea)(ind_session).index.Quiet;
            Completed = coding_direction_matrix.(currentarea)(ind_session).index.completed_trial;

            % Evaluate condition
            eval(current_cond_name);
            trial_indecis = Ind & Quietind & Completed;

            % Extract context data for current trials
            current_context = current_context(:,trial_indecis);

            % Apply baseline subtraction if requested
            if baselinesubtraction
                conext_baseline = mean(current_context(1:100,:),1);
                current_context = current_context - repmat(conext_baseline,size(current_context,1),1);
                context_concat = [context_concat,nanmean(current_context,2)];
            else
                context_concat = [context_concat,nanmean(current_context,2)];
            end
        end % End of session loop

        % Plot context coding direction

        signal2plot = context_concat;
        meansig = nanmean(signal2plot,2);
        semsig = nanstd(signal2plot,[],2)./sqrt(size(signal2plot,2));
        curve1 = meansig + semsig;
        curve2 = meansig - semsig;
        x2 = [windowCenters,fliplr(windowCenters)];
        inBetween = [curve1', fliplr(curve2')];

        % Plot with error shading

        fill(axs(ind_figures(1,ind_area)),x2, inBetween, colorcodes(ind_cond,:),'FaceAlpha',0.3,'LineStyle','none');
        hold(axs(ind_figures(1,ind_area)), 'on');
        plot(axs(ind_figures(1,ind_area)),windowCenters,meansig,'color',colorcodes(ind_cond,:),'Linewidth',.1);

        % Calculate statistics for comparison windows

        [a,b] = min(abs(windowCenters-params.Win1(1))); W1FirstBin = (b);
        [a,b] = min(abs(windowCenters-params.Win1(2))); W1LastBin = (b);
        [a,b] = min(abs(windowCenters-params.Win2(1))); W2FirstBin = (b);
        [a,b] = min(abs(windowCenters-params.Win2(2))); W2LastBin = (b);

        V1 = mean(context_concat(W1FirstBin:W1LastBin,:),1);
        V2 = mean(context_concat(W2FirstBin:W2LastBin,:),1);

        % Plot statistical comparison

        hold(axs(ind_figures(2,ind_area)),'on');
        bar(axs(ind_figures(2,ind_area)),[flg],nanmean(V2),'FaceColor',colorcodes(ind_cond,:));
        errorbar(axs(ind_figures(2,ind_area)),[flg],[nanmean(V2)],[nanstd(V2,0)]/sqrt(length(V2)),'-k','CapSize',3,'Linewidth',1,'MarkerSize',4);
        plot(axs(ind_figures(2,ind_area)),[flg+.2],[V2]','ok','Markersize',4,'markerfacecolor','none');

        % Calculate statistics

        mean_values{ind_area}(:,flg) = (V2');
        P(ind_area,flg) = P_value(mean_values{ind_area}(:,1),mean_values{ind_area}(:,flg));

    end % End of trial condition loop

    % apply Bonferroni correction for each area (3 tests)

    P_Corr=P*3;

    % Add statistical significance indicators
    prettify_pvalues(axs(ind_figures(2,ind_area)), [1,1,1], [2,3,4], P_Corr(ind_area,2:end),'PlotNonSignif', false,'OnlyStars',true,'Yposition',1.5);

    % Format plots

    ylim(axs(ind_figures(1,ind_area)),[-.2,1.6]);
    ylim(axs(ind_figures(2,ind_area)),[-.5,2]);
    xlim(axs(ind_figures(2,ind_area)),[0,5]);
    axs(ind_figures(2,ind_area)).XAxis.Visible = 'off';

    xline(axs(ind_figures(1,ind_area)),0);
    xline(axs(ind_figures(1,ind_area)),1);
    yline(axs(ind_figures(1,ind_area)),0,'Tag','y=0');

    title(axs(ind_figures(1,ind_area)),currentarea);
    yticklabels(axs(ind_figures(2,ind_area)),get(axs(ind_figures(2,ind_area)),'YTick'));

end % End of brain area loop

%% Add axis labels and formatting
xticks(h(1),xtick);
xticklabels(h(1),XTickLabel);
xlabel(h(1),'Time (s)');
ylabel(h(1),'CD Context (a.u)');
ylabel(h(6),'Mean delay CD Context');


%% Add legend
legend_just_txt(axs(1),{'Hit','Nogo CR','No Whisker CR','Miss'},'Xoffset',-0.9,'Yoffset',1.5,'relX',0,'relY',0.1,'type','line');

%% Apply final plot formatting
prettify_plot('LineThickness', 1,'TickWidth',1.5,'AxisTightness', 'keep','TickLength',[.01 .001],'PointSize','keep');

%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');


