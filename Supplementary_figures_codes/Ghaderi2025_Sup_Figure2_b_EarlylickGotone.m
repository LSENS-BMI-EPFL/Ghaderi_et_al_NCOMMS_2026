%% =========================================================================
% Ghaderi2025_Figure2Sup_EarlylickGotone.m
% =========================================================================
%
% This script generates Figure 2 Supplement showing early lick probability for Go-tone trials
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script creates plots showing early lick probability across different
% optogenetic stimulation windows and brain regions for Go-tone trials. It analyzes
% performance changes during audio, delay, and whisker stimulation periods with
% statistical significance testing and multiple comparison corrections.
%
% Dependencies:
%   - psth_10ms.mat (contains trial data)
%   - Optoinhibition_mat.mat (contains optogenetic data)
%   - tight_subplot.m (for subplot management)
%   - prettify_plot.m (for plot formatting)
%   - prettify_pvalues.m (for statistical significance plotting)
%   - P_value.m (for statistical testing)
%   - mafdr.m (for multiple comparison correction)
%
% Output: PDF figure showing early lick probability across sessions and brain regions
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc

%% Optional: Change figure name (set to 1 to enable)
change_name = 0;
newname = 'Figure3_4_1';
fullname = mfilename('fullpath');
inds = regexp(fullname, '\', 'all');
name = fullname(inds(end)+1:end);

if change_name
    movefile([name '.m'], [newname '.m']);
end

%% Load required data

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'Optoinhibition_mat.mat'])

%% Define analysis parameters
correction = 'area';  % Multiple comparison correction method: 'window', 'trial_type', 'area', 'all', 'nocorrection'
close all;

% Color scheme for plotting
a = .2;

colorcodes = [0 0 1 a; .5 .5 .5 a; 1 0 0 a; 1 .5 0 a; 0 0 0 a];


%% Initialize main figure

parent = figure('Position', [100 100 1600 300]);

% Create subplot layout (6 rows, 1 column)
h = tight_subplot(1, 6, [.2 .05], [.2 .1], [.05 .05]);

axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters
window_list = {'nolight', 'audio', 'delay', 'whisker'};  % Optogenetic stimulation windows
window_list_label = {'Nolight', 'Audio', 'Delay', 'Whisker'};  % Labels for plotting

trialtype_list = [1];  % Trial type: 1 = Go-tone
num_trials = length(trialtype_list);
trialname_list = {'Go-tone'};
region_list = {'A1', 'wS1', 'wS2', 'wM2', 'ALM', 'fpS1'};  % Brain regions
completion_state = 'early_licks';  % Analysis condition: early licks

%% Calculate performance across brain regions
fiberlist = [];

for ind_area = 1:length(region_list)

    current_area = cell2mat(region_list(ind_area));
    fiberlist = find(strcmp(current_area, {optomat.fiber_location}));
    performance = [];

    % Process each trial type
    for ind_trialtype = 1:length(trialtype_list)

        current_trialtype_name = cell2mat(trialname_list(ind_trialtype));

        % Process each optogenetic window
        for ind_window = 1:length(window_list)

            current_window = cell2mat(window_list(ind_window));
            session_counter = 1;

            % Process each session in current area
            for ind_session = fiberlist

                Trial = optomat(ind_session).trial_type;
                Lick = optomat(ind_session).lick_flag;
                Windows = optomat(ind_session).opto_window;

                % Apply trial type filter (Go-tone trials: type 1 or 2)
                current_trialtype_ind = (Trial == 1 | Trial == 2);

                % Apply optogenetic window filter
                current_optocondition_ind = strcmp(Windows, current_window);

                % Determine completion state
                switch completion_state
                    case 'completed_trials'
                        completion_state_ind = ~optomat(ind_session).early_lick;
                    case 'early_licks'
                        early_licks_all = optomat(ind_session).early_lick;
                        lick_time = 0 < (optomat(ind_session).lick_time - optomat(ind_session).start_time);
                        completion_state_ind = lick_time & early_licks_all;
                    case 'all_trials'
                        completion_state_ind = ones(length(~optomat(ind_session).early_lick), 1);
                end

                % Calculate early lick probability
                CurrTrialInd = [current_trialtype_ind & current_optocondition_ind];
                plick = sum(completion_state_ind & CurrTrialInd) / sum(CurrTrialInd) * 100;
                performance(ind_window, session_counter) = plick;
                session_counter = session_counter + 1;

            end % End of session loop

            % Statistical analysis

            if strcmp(current_window, 'nolight')  % Skip statistics for nolight condition
                continue;
            else
                pvaluse(ind_window) = P_value(performance(1, :), performance(ind_window, :));
            end

        end % End of window loop

        % Store p-values and create plots

        pvalue_matrix(ind_area, ind_trialtype, :) = pvaluse(2:end);
        color_code = colorcodes(ind_trialtype, :);

        % Plot individual session data
        plot(axs(ind_area), performance, '-', 'color', [0.7 0.7 0.7]);
        hold(axs(ind_area), 'on');

        % Plot mean and error bars
        errorbar(axs(ind_area), nanmean(performance'), nanstd(performance'), '-o', 'color', color_code, 'Markersize', 8);

        % Set y-axis limits for early licks (lower range)
        ylim(axs(ind_area), [0 110]);

        % Configure x-axis labels
        xticks(axs(ind_area), [1:4]);
        xticklabels(axs(ind_area), window_list_label);

    end % End of trial type loop

    % Add region labels and formatting

    ylim(axs(ind_area), [0 50]);  % Adjusted range for early licks
    xlim(axs(ind_area), [0.5 4.5]);
    title(axs(ind_area), cell2mat(region_list(ind_area)))

    if ind_area==1
        ylabel(axs(ind_area), 'P-Lick (%)');
    end
    
    All_Area_P_EarlyLick.(current_area)=performance;

end % End of area loop



%% Apply multiple comparison correction

switch correction
    case 'all'
        % Correct across all p-values
        pvalues_corrected = mafdr(pvalue_matrix(:), 'Method', 'polynomial');
        pvalues_corrected = reshape(pvalues_corrected, [6, num_trials, 3]);

    case 'area'
        % Correct within each brain area
        for ind_area = 1:length(region_list)
            pvalues_area = squeeze([pvalue_matrix(ind_area, :, :)]);
            pvalues_area_corrected = mafdr(pvalues_area(:), 'BHFDR', 'True');
            pvalues_corrected(ind_area, :, :) = reshape(pvalues_area_corrected, [num_trials, 3]);
        end

    case 'trial_type'
        % Correct within each trial type
        for ind_trial = 1:length(trialname_list)
            pvalues_trials = squeeze([pvalue_matrix(:, ind_trial, :)]);
            pvalues_trials_corrected = mafdr(pvalues_trials(:), 'BHFDR', 'True');
            pvalues_corrected(:, ind_trial, :) = reshape(pvalues_trials_corrected, [6, 3]);
        end

    case 'window'
        % Correct within each time window
        for ind_window = 1:length(window_list) - 1
            pvalues_window = squeeze([pvalue_matrix(:, :, ind_window)]);
            pvalues_window_corrected = mafdr(pvalues_window(:), 'BHFDR', 'True');
            pvalues_corrected(:, :, ind_window) = reshape(pvalues_window_corrected, [6, num_trials]);
        end

    case 'nocorrection'
        % No correction applied
        pvalues_corrected = pvalue_matrix;
end

%% Add statistical significance indicators

for ind_area = 1:length(region_list)

    for ind_trialtype = 1:length(trialtype_list)

        prettify_pvalues(axs(ind_area), [1, 1, 1], [2, 3, 4], ...
            squeeze(pvalues_corrected(ind_area, ind_trialtype, :)), ...
            'PlotNonSignif', false, 'OnlyStars', true, ...
            'LineMargin', 0.15, 'TickLength', 0.08, 'Yposition', 30);

    end % End of trial type loop

end % End of area loop

%% Store results for reporting

for ind_trialtype = 1:length(trialtype_list)

    current_trialtype_name = cell2mat(trialname_list(ind_trialtype));
    trial_name = strrep(current_trialtype_name, '-', '_');
    trial_name = strrep(trial_name, ' ', '_');
    p_val = squeeze(pvalues_corrected(:, ind_trialtype, :));
    pvalue_table.(trial_name) = table(p_val);

end % End of trial type loop

%% Apply final plot formatting

prettify_plot('LineThickness', 2, 'TickLength', [.001 .001], 'AxisTightness', 'keep', 'PointSize', 'keep');

%% Export figure
directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');





