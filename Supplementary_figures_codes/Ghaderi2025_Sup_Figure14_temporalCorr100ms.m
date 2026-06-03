%% =========================================================================
% Ghaderi2025_ExtendedData_Figure14_temporalCorr100ms.m
% =========================================================================
%
% This script generates Figure 6Sup2 showing temporal correlation analysis with 100ms bins
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script analyzes temporal correlations in neural activity across different
% brain areas and trial conditions using 100ms time bins. It creates correlation matrices
% and plots average correlation values for different trial types.
%
% Dependencies:
%   - psth_10ms.mat (contains trial data)
%   - Temporal_Corrrelation_100ms.mat (contains correlation data)
%   - tight_subplot.m (for subplot management)
%   - legend_just_txt.m (for legend creation)
%   - prettify_plot.m (for plot formatting)
%   - prettify_Pvalues.m (for statistical significance plotting)
%
% Output: PDF figure showing temporal correlation analysis
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc

%% Optional: Change figure name
change_name = 0;
newname = 'Figure6Sup2_temporalCorr100ms';
fullname = mfilename('fullpath');
inds = regexp(fullname,'\','all');
name = fullname(inds(end)+1:end);
if change_name
    movefile([name '.m'],[newname '.m']);
end

%% Load required data

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'Temporal_corrrelation_100ms.mat'])
load([directory filesep 'data_helpers' filesep 'Area_list.mat'])

%% Define analysis parameters

trialtype_names = {'gotone_whisker_lick';'nogotone_whisker';'gotone';'gotone_whisker'};
trialtype_names_tag = {'Hit','Nogo CR','No W','Miss'};

colorcodes = [[0 0 1]; % GoTone+W Hit
    [1 0 0]; % NogoTone+W CR
    [0 0.7 0.7]; % GoTone CR
    [0.5 0 0.8]]; % GoTone+W Miss

arealist = {'A1','wS1','wS2','wM2','ALM'};
ind_figures = [reshape([1:25]',5,5)]';

%% Initialize main figure

params.subtraction = 1;
params.smoothing = 0;
params.Clim = [-.2 .2];
params.Cmap = 'jet';
params.Pvalue = 0;

parent = figure('Position', [100 100 1000 1000]);
h = tight_subplot(5,5,[.05 .05],[.03 .03],[.09 .01]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);


%% Process each brain area
for ind_area = 1:length(arealist)

    curr_area = cell2mat(arealist(ind_area));
    flg = 0;
    pval = [];
    
    % Process each trial condition
    for i_cond = 1:length(trialtype_names)

        flg = flg + 1;
        curr_cond = cell2mat(trialtype_names(i_cond));
        curr_cond_area_correlation = correlation_matrix.(curr_cond).(curr_area);
        
        % Process correlation data

        if params.Pvalue
            curr_cond_area_correlation = curr_cond_pvalue.(curr_area);
            mean_corr_map = squeeze(nanmean(curr_cond_area_correlation,3));
            mean_corr_map(.05 < mean_corr_map) = 0;
            mean_corr_map(find(mean_corr_map)) = 1;
            mean_corr_map = logical(mean_corr_map);
        else
            all_maps = [];
            FWHM = [];
            AUC = [];
            
            % Process each session
            for i_session = 1:size(curr_cond_area_correlation,3)

                [active_cells,b] = min(abs(windowCenters-0));
                bin_timezero = (b);
                curr_map = squeeze(curr_cond_area_correlation(:,:,i_session));
                
                % Skip if all values are NaN
                if all(isnan(curr_map(:)))
                    AUC(i_session) = NaN;
                    continue;
                end
                
                % Skip specific problematic session
                if ((i_session == 4) && (strcmp(curr_area,'A1')) && (strcmp(curr_cond,'gotone_whisker')))
                    AUC(i_session) = NaN;
                    continue;
                end
                
                % Apply baseline subtraction if requested

                if params.subtraction
                    baseline_mean = nanmean(nanmean(curr_map(1:bin_timezero,1:bin_timezero).*(1+diag(nan(bin_timezero,1)))));
                    curr_map = curr_map - baseline_mean;
                end
                
                % Calculate AUC for correlation map
                auc = mean(curr_map(10:20,10:20),"all");
                AUC(i_session) = auc;
                all_maps(:,:,i_session) = curr_map;

            end % End of session loop
            
            mean_corr_map = squeeze(nanmean(all_maps,3));

        end % End of Pvalue condition
        
        % Plot correlation matrix

        [active_cells,b] = min(abs(windowCenters-0));
        bin_timezero = (b);
        
        % Apply smoothing if requested

        if params.smoothing
            mean_corr_map = imgaussfilt(mean_corr_map,1);
        end
        
        % Display correlation matrix

        imagesc(axs(ind_figures(i_cond,ind_area)),windowCenters,windowCenters,mean_corr_map);
        
        % Calculate mean correlation

        L = 10;
        [lags, mean_correlations, sem_correlations] = compute_mean_corr(mean_corr_map, 10, 19, L);
        lags = lags(L:end); 
        mean_correlations = mean_correlations(L:end); 
        sem_correlations = sem_correlations(L:end);
        
        % Format correlation plot

        clim(axs(ind_figures(i_cond,ind_area)),params.Clim);
        hold(axs(ind_figures(i_cond,ind_area)),'on');
        xline(axs(ind_figures(i_cond,ind_area)),[0,1]);
        yline(axs(ind_figures(i_cond,ind_area)),[0,1]);
        xticklabels(axs(ind_figures(i_cond,ind_area)),[]);
        yticklabels(axs(ind_figures(i_cond,ind_area)),[]);
        axs(ind_figures(i_cond,ind_area)).XAxis.Visible = 'off';
        axs(ind_figures(i_cond,ind_area)).YAxis.Visible = 'off';
        
        % Set colormap
        switch params.Cmap
            case 'map'
                colormap(map);
            case 'jet'
                colormap jet;
            case 'copper'
                colormap copper;
        end
        
        % Add area labels
        if i_cond == 1
            text(axs(ind_figures(1,ind_area)),0,-1.2,cell2mat(arealist(ind_area)));
        end
        
        % Plot AUC values

        hold(axs(ind_figures(5,ind_area)),'on');
        bar(axs(ind_figures(5,ind_area)),[i_cond],nanmean(AUC),'FaceColor',colorcodes(i_cond,:));
        errorbar(axs(ind_figures(5,ind_area)),[i_cond],nanmean(AUC),nanstd(AUC,0)/sqrt(sum(~isnan(AUC))),'-k','CapSize',3,'Linewidth',1,'MarkerSize',4);
        plot(axs(ind_figures(5,ind_area)),i_cond+.2, AUC,'ok','MarkerFaceColor','none','MarkerSize',4);
        
        % Calculate statistics

        mean_values{ind_area}(:,flg) = (AUC');
        P(flg) = P_value(mean_values{ind_area}(:,1),mean_values{ind_area}(:,flg));

        % Add trial type labels

        if ind_area==1

            text(axs(ind_figures(i_cond,1)),-1.3,1,strrep(cell2mat(trialtype_names_tag(i_cond)),'_',' '),'rotation',90,'FontSize',8, 'Color', colorcodes(i_cond,:));
        end

    end % End of trial condition loop

    % Apply Bonferroni correction for each area (n=3 tests)

    P_Corr=P*3;

    All_area_P_Values.(curr_area)=P_Corr;
    
    %% Format plots
   
    ylabel(axs(21),'mean correlation');
    ylim(axs(ind_figures(5,ind_area)),[-0.1,0.3]);
    yticklabels(axs(ind_figures(5,ind_area)),get(axs(ind_figures(5,ind_area)),"YTick"));
    xlim(axs(ind_figures(5,ind_area)),[0 5]);
    axs(ind_figures(5,ind_area)).XAxis.Visible = 'off';
   
    %% Add statistical significance indicators
    prettify_pvalues(axs(ind_figures(5,ind_area)), [1,1,1], [2,3,4], P_Corr(2:end),'PlotNonSignif', false,'OnlyStars',true,'Yposition',.2);
    
end % End of brain area loop

%% Add colorbar and legend

colorbar(axs(1),'Position',[0.165 0.78 .008 .05]);
legend_just_txt(axs(ind_figures(5,1)),trialtype_names_tag,'Xoffset',0.5,'Yoffset',.3,'relX',0,'relY',0.08,'type','bar');

%% Apply final plot formatting

prettify_plot('LineThickness', .5,'AxisTightness', 'keep','TickLength',[.01 0],'PointSize','keep','GeneralFontSize',10);

%% Export figure

directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');
