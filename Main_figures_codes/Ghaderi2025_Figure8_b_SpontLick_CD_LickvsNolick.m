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
newname = 'Ghaderi2025_Figure8_b_SpontLick_CD_LickvsNolick';
fullname = mfilename('fullpath');
inds = regexp(fullname,'\','all');
name = fullname(inds(end)+1:end);
if change_name
    movefile([name '.m'],[newname '.m']);
end


%% Load required data

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'Coding_direction_SpontLick.mat'])
load([directory filesep 'data_helpers' filesep 'Area_list.mat'])


%% Define minimum number of trials parameter
min_num_trials = 2;
NaN_Vector(1:600,1)=NaN;
%% Initialize main figure
figure('Units','centimeters','Position',[4 4 30 15],'PaperType','A4','PaperUnits','centimeters','PaperSize',[21 29.7],'PaperPosition',[1 1 20 25]);
h = tight_subplot(2,5,[.09 .09],[.08 .08],[.1 .01]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters
params.arealist = {'A1','wS1','wS2','wM2','ALM'};
params.Win1 = [-1,0];  % Window 1 for statistical comparison
params.Win2 = [1.03,1.03];  % Window 2 for statistical comparison
params.Win3 = [1.2,1.4];  % Window 3 for statistical comparison

colorcodes = [[0 0 255];
    [255 0 0];
    [0 0 0];
    [170 170 255];
    [255 170 170];
    [170 170 170]]/255;
params.trialtypes = {'Ind=[ trial==1 & lick==1];';'Ind=[ trial==3 & lick==1];';'Ind=[ trial==5 & lick==1];';'Ind=[ trial==1 & lick==0];';'Ind=[ trial==3 & lick==0];';'Ind=[ trial==5 & lick==0];'};

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

        for ind_session = 1:size(coding_direction_matrix.(currentarea),2)

            if ~isnan(coding_direction_matrix.(currentarea)(ind_session).Error_Type)
                session2drop.(currentarea)(ind_session,ind_cond) = 1;

            else

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
end


%% Define subplot indices
ind_figuers = [reshape([1:10]',5,2)]';

%% Process each brain area
mean_values={};
for ind_area = 1:length(params.arealist)
    currentarea = cell2mat(params.arealist(ind_area));
    flg = 0;
    pval = [];
    V2_values = [];
    V3_values = [];

    %% Process each trial condition
    for ind_cond = 1:length(params.trialtypes)
        flg = flg + 1;
        current_cond_name = cell2mat(params.trialtypes(ind_cond));
        if isempty(current_cond_name)
            continue;
        end

        lick_concat = [];


        %% Process each session
        for ind_session = 1:size(coding_direction_matrix.(currentarea),2)

            if session2drop.(currentarea)(ind_session,ind_cond)==0

                curr_context = coding_direction_matrix.(currentarea)(ind_session).Contextproj;
                curr_stim = coding_direction_matrix.(currentarea)(ind_session).Stimproj;
                curr_lick = coding_direction_matrix.(currentarea)(ind_session).lickproj;

                lick = coding_direction_matrix.(currentarea)(ind_session).index.lick;
                trial = coding_direction_matrix.(currentarea)(ind_session).index.trial;
                Quietind = coding_direction_matrix.(currentarea)(ind_session).index.Quiet;
                Completed = coding_direction_matrix.(currentarea)(ind_session).index.completed_trial;

                eval(current_cond_name);
                trial_indecis = Ind & Quietind & Completed;
                current_context = curr_context(:,trial_indecis);
                current_stim = curr_stim(:,trial_indecis);
                current_lick = curr_lick(:,trial_indecis);


                lick_concat = [lick_concat,nanmean(current_lick,2)];

            else

                lick_concat = [lick_concat,NaN_Vector];

            end

        end % End of session loop

        %% Plot context coding direction

        signal2plot = lick_concat;

        meansig = nanmean(signal2plot,2);
        semsig = nanstd(signal2plot,[],2)./sqrt(sum(~isnan(signal2plot(1,:))));
        curve1 = meansig + semsig;
        curve2 = meansig - semsig;
        x2 = [windowCenters,fliplr(windowCenters)];
        inBetween = [curve1', fliplr(curve2')];
        fill(axs(ind_figuers(1,ind_area)),x2, inBetween, colorcodes(ind_cond,:),'FaceAlpha',0.3,'LineStyle','none');
        hold(axs(ind_figuers(1,ind_area)), 'on');
        plot(axs(ind_figuers(1,ind_area)),windowCenters,meansig,'color',colorcodes(ind_cond,:),'Linewidth',.1);
        xlim(axs(ind_figuers(1,ind_area)),[.95,1.1]);

        %% Calculate statistics for comparison windows
        [a,b] = min(abs(windowCenters-params.Win1(1))); W1FirstBin = (b);
        [a,b] = min(abs(windowCenters-params.Win1(2))); W1LastBin = (b);

        [a,b] = min(abs(windowCenters-params.Win2(1))); W2FirstBin = (b);
        [a,b] = min(abs(windowCenters-params.Win2(2))); W2LastBin = (b);

        [a,b] = min(abs(windowCenters-params.Win3(1))); W3FirstBin = (b);
        [a,b] = min(abs(windowCenters-params.Win3(2))); W3LastBin = (b);

        V2=[];
        V2 = mean(lick_concat(W2FirstBin:W2LastBin,:),1)';

        All_Area_CD.(currentarea)(:, ind_cond)=V2;

        %% Plot values for Win2

        hold(axs(ind_figuers(2,ind_area)),'on');
        V2_values = [V2_values;[V2,ind_cond*ones(length(V2),1)]];
        bar(axs(ind_figuers(2,ind_area)),[flg],nanmean(V2),'FaceColor',colorcodes(ind_cond,:));
        errorbar(axs(ind_figuers(2,ind_area)),[flg],[nanmean(V2)],[nanstd(V2,0)]/sqrt(sum(~isnan(V2(:,1)))),'-k','CapSize',3,'Linewidth',1,'MarkerSize',4);
        plot(axs(ind_figuers(2,ind_area)),[flg+.2],[V2]','o','Markersize',4,'Color', [0.5 0.5 0.5]);


        mean_values{ind_area}(:,flg) = (V2');

    end % End of trial condition loop

    %% Perform statistical analysis for Win2

    [P_KWT,~,stats2] = kruskalwallis(V2_values(:,1),V2_values(:,2),'off');
    [c2,m,h,gnames] = multcompare(stats2,'Display','off','CriticalValueType','lsd');

    All_Area_Stat_Pvalues.(currentarea).KWT=P_KWT;
    All_Area_Stat_Pvalues.(currentarea).MultiCmpT=c2;

    %% Format plots

    ylim(axs(ind_figuers(1,ind_area)),[-.2,1]);
    ylim(axs(ind_figuers(2,ind_area)),[-.5,2.5]);

    xlim(axs(ind_figuers(2,ind_area)),[0,7]);

    if P_KWT<0.05
        prettify_pvalues(axs(ind_figuers(2,ind_area)), c2(:,1), c2(:,2), c2(:,6),'TickLength',0.02,'LineMargin',.05,'PlotNonSignif', false,'OnlyStars',true,'Yposition',1.1);
    end

    %% Add reference lines and labels

    xline(axs(ind_figuers(1,ind_area)),0);
    xline(axs(ind_figuers(1,ind_area)),1);
    xline(axs(ind_figuers(1,ind_area)),1.03,'Tag','t=30ms');
    yline(axs(ind_figuers(1,ind_area)),0,'Tag','y=0');
    title(axs(ind_figuers(1,ind_area)),currentarea);
    yticklabels(axs(ind_figuers(2,ind_area)),get(axs(ind_figuers(2,ind_area)),'YTick'));

end % End of brain area loop

%% Add axis labels and formatting
xlabel(axs(ind_figuers(1,1)),'Time (s)');
ylabel(axs(ind_figuers(1,1)),'pCD_{Lick} (a.u)');

%% Apply final plot formatting
prettify_plot('LineThickness', 1,'TickWidth',1.5,'AxisTightness', 'keep','TickLength',[.01 .001],'PointSize','keep');

%% Add title with minimum trial count
sgtitle(num2str(min_num_trials));

%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');

