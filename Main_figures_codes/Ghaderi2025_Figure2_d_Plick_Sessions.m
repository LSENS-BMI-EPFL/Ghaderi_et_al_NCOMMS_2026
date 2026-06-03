%% =========================================================================
% Ghaderi2025_Figure2_Plick_SessionsHit.m
% =========================================================================
% 
% This script generates Figure 2 showing lick probability across sessions for Hit trials
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making" 
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script creates plots showing lick probability across different 
% optogenetic stimulation windows and brain regions for Hit trials. It analyzes 
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
% Output: PDF figure showing lick probability across sessions and brain regions
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc
rng(0)

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

% Color scheme for plotting
a = .2;
colorcodes = [0 0 1 a; 0 .5 1 a; 1 0 0 a; 1 .5 0 a; 0 0 0 a];

All_Area_Performance=[];
%% Initialize main figure

parent = figure('Position', [50 200 1600 400])

% Create subplot layout (6 rows, 1 column)
h = tight_subplot(1, 6, [.07 .07], [.15 .1], [.05 .03]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters
window_list = {'nolight', 'audio', 'delay', 'whisker'};  % Optogenetic stimulation windows
window_list_label = {'No light', 'Auditory', 'Delay', 'Whisker'};  % Labels for plotting

trialtype_list = [1];  % Trial type: 1 = Go-tone Whisker
num_trials = length(trialtype_list);
trialname_list = {'Go-tone Whisker'};
region_list = {'A1', 'wS1', 'wS2', 'wM2', 'ALM', 'fpS1'};  % Brain regions
completion_state = 'completed_trials';  % Analysis condition

%% Calculate performance across brain regions
fiberlist = [];

% Initialize storage for session counts and p-values
session_counts = zeros(length(region_list), length(window_list));
pvalue_matrix = zeros(length(region_list), num_trials, length(window_list)-1);

for ind_area = 1:length(region_list)
    current_area = cell2mat(region_list(ind_area));
    fiberlist = find(strcmp(current_area, {optomat.fiber_location}));
    performance = [];
    
    % Process each trial type
    for ind_trialtype = 1:length(trialtype_list)
        current_trial_type = trialtype_list(ind_trialtype);
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
                
                % Apply trial type filter
                current_trialtype_ind = Trial == current_trial_type;
                
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
                
                % Calculate lick probability
                CurrTrialInd = [completion_state_ind & current_trialtype_ind & current_optocondition_ind];
                plick = sum(CurrTrialInd & Lick) / sum(CurrTrialInd) * 100;
                performance(ind_window, session_counter) = plick;
                session_counter = session_counter + 1;
            end % End of session loop
            
            % Store session count for this window and area
            session_counts(ind_area, ind_window) = session_counter - 1;
            
            %% Statistical analysis
            if strcmp(current_window, 'nolight')  % Skip statistics for nolight condition
                continue;
            else
                pvaluse(ind_window) = P_value(performance(1, :), performance(ind_window, :));
            end
        end % End of window loop
        
        %% Store p-values and create plots
        pvalue_matrix(ind_area, ind_trialtype, :) = pvaluse(2:end);
        color_code = colorcodes(ind_trialtype, :);
        
        % Plot individual session data
        plot(axs(ind_area), performance, '-', 'Color', [0.7 0.7 0.7]);
        hold(axs(ind_area), 'on');
        
        % Plot mean and error bars
        errorbar(axs(ind_area), nanmean(performance'), nanstd(performance'), '-o', 'color', color_code, 'Markersize', 10);
        
        % Configure x-axis labels
            xticks(axs(ind_area), [1:4]);
            xticklabels(axs(ind_area), window_list_label);
        
        % Add title for first subplot
        if ind_area == 1
            title(axs(ind_area), strrep(current_trialtype_name, '_', ' '));
        end
        All_Area_Performance.(current_area)=performance;
    end % End of trial type loop
    
    %% Add region labels and formatting
    ylim(axs(ind_area), [0 130]);
    xlim(axs(ind_area), [0.8 4]);
    text(axs(ind_area), -.5, 95, cell2mat(region_list(ind_area)), 'rotation', 90, 'FontWeight', 'bold');
    ylabel(axs(ind_area), 'P-Lick (%)');

end % End of area loop

%% Correct within each time window
        for ind_window = 1:length(window_list) - 1
            pvalues_window = squeeze([pvalue_matrix(:, :, ind_window)]);
            pvalues_window_corrected = mafdr(pvalues_window(:), 'BHFDR', 'True');
            pvalues_corrected(:, :, ind_window) = reshape(pvalues_window_corrected, [6, num_trials]);
        end

%% Add statistical significance indicators
for ind_area = 1:length(region_list)
    for ind_trialtype = 1:length(trialtype_list)
        prettify_pvalues(axs(ind_area), [1, 1, 1], [2, 3, 4], ...
                        squeeze(pvalues_corrected(ind_area, ind_trialtype, :)), ...
                        'PlotNonSignif', false, 'OnlyStars', true, ...
                        'LineMargin', 0.1, 'TickLength', 0.03, 'Yposition', 100);
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

directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');




%% statistics 

clearvars -except optomat pvalue_table trialtype_list region_list completion_state window_list window_list_label All_Area_Performance;

n_bootstrap = 10000;  % Number of bootstrap iterations
confidence_level = 0.95;  % For confidence intervals


%% Step 1: Extract performance data for all regions
performance_data = struct();
session_counts = zeros(length(region_list), length(window_list));

for ind_area = 1:length(region_list)
    current_area = cell2mat(region_list(ind_area));
    fiberlist = find(strcmp(current_area, {optomat.fiber_location}));
    
    for ind_window = 1:length(window_list)
        current_window = cell2mat(window_list(ind_window));
        performance_sessions = [];
        
        for ind_session = fiberlist
            Trial = optomat(ind_session).trial_type;
            Lick = optomat(ind_session).lick_flag;
            Windows = optomat(ind_session).opto_window;
            
            current_trialtype_ind = Trial == trialtype_list(1);
            current_optocondition_ind = strcmp(Windows, current_window);
            
            switch completion_state
                case 'completed_trials'
                    completion_state_ind = ~optomat(ind_session).early_lick;
                case 'all_trials'
                    completion_state_ind = ones(length(~optomat(ind_session).early_lick), 1);
            end
            
            CurrTrialInd = [completion_state_ind & current_trialtype_ind & current_optocondition_ind];
            plick = sum(CurrTrialInd & Lick) / sum(CurrTrialInd) * 100;
            performance_sessions = [performance_sessions; plick];
        end
        
        performance_data.(current_area).(current_window) = performance_sessions;
        session_counts(ind_area, ind_window) = sum(~isnan(performance_sessions));
    end
end

%% Find minimum number of sessions across all regions
min_sessions = min(session_counts(:));
fprintf('Minimum sessions across all regions/windows: %d\n\n', min_sessions);

%% Method 1: BOOTSTRAP 
bootstrap_pvalues = zeros(length(region_list), length(window_list)-1);
bootstrap_effect_sizes = zeros(length(region_list), length(window_list)-1);

for ind_area = 1:length(region_list)
    current_area = cell2mat(region_list(ind_area));
    
    for ind_window = 2:length(window_list)  % Compare to nolight
        current_window = cell2mat(window_list(ind_window));
        
        % Get data and REMOVE NaNs
        nolight_data = performance_data.(current_area).nolight;
        opto_data = performance_data.(current_area).(current_window);
        
        % Remove NaN values
        nolight_data = nolight_data(~isnan(opto_data));
        opto_data = opto_data(~isnan(opto_data));
        
        
        % Determine minimum N for this comparison
        % min_n_comparison = min(length(nolight_data), length(opto_data));
        min_n_comparison = min_sessions;


        
        % Bootstrap procedure
        boot_diff = zeros(n_bootstrap, 1);
        
        for iboot = 1:n_bootstrap
            % Randomly sample SAME indices from both conditions (paired data)
            indices = randsample(length(nolight_data), min_n_comparison, true);
            nolight_sample = nolight_data(indices);
            opto_sample = opto_data(indices);
            
            % Calculate difference
            boot_diff(iboot) = nanmean(nolight_sample) - nanmean(opto_sample);
        end
        
        % P-value: proportion of bootstrap samples where difference has opposite sign
        observed_diff = nanmean(nolight_data) - nanmean(opto_data);
        if observed_diff > 0
            p_val = (sum(boot_diff <= 0) +1) / n_bootstrap;   % the lowest number with bootstrap 1000 is 0.001 
        else
            p_val = (sum(boot_diff >= 0) +1) / n_bootstrap;
        end
        p_val = 2 * min(p_val, 1 - p_val);  % Two-tailed
        
        % Effect size (Cohen's d) - use nanstd to handle any remaining NaNs
        nolight_std = nanstd(nolight_data);
        opto_std = nanstd(opto_data);
     
        if isnan(nolight_std) || isnan(opto_std)
            % Still have NaN in std
            cohens_d = NaN;
        elseif nolight_std == 0 && opto_std == 0
            % Both have zero variance - no effect
            cohens_d = 0;
        elseif nolight_std == 0 || opto_std == 0
            % One has zero variance - use the other
            pooled_std = max(nolight_std, opto_std);
            if pooled_std > 0
                cohens_d = observed_diff / pooled_std;
            else
                cohens_d = 0;
            end
        else
            % Normal case
            pooled_std = sqrt((nolight_std^2 + opto_std^2) / 2);
            cohens_d = observed_diff / pooled_std;
        end
        
        bootstrap_pvalues(ind_area, ind_window-1) = p_val;
        bootstrap_effect_sizes(ind_area, ind_window-1) = cohens_d;
    end
end

%% FDR CORRECTION 
% Initialize matrices for FDR-corrected p-values
bootstrap_pvalues_fdr = nan(length(region_list), length(window_list)-1);

% Apply FDR correction for each window separately
for ind_window = 2:length(window_list)
    
    % Collect all bootstrap p-values for this window
    all_pvals = [];
    valid_indices = [];  % Track which regions have valid p-values
    
    for ind_area = 1:length(region_list)
        p_boot = bootstrap_pvalues(ind_area, ind_window-1);
        if ~isnan(p_boot)
            all_pvals = [all_pvals; p_boot];
            valid_indices = [valid_indices; ind_area];
        end
    end
    
    % Apply FDR correction if we have valid p-values
        %  FDR correction using mafdr
        adjusted_pvals = mafdr(all_pvals(:), 'BHFDR', true);

        % Map back to original matrix
        for idx = 1:length(valid_indices)
            ind_area = valid_indices(idx);
            bootstrap_pvalues_fdr(ind_area, ind_window-1) = adjusted_pvals(idx);
        end
end

%% Method 2: EFFECT SIZE ANALYSIS (Cohen's d with CIs)
effect_sizes = struct();

for ind_area = 1:length(region_list)
    current_area = cell2mat(region_list(ind_area));
    
    for ind_window = 2:length(window_list)
        current_window = cell2mat(window_list(ind_window));
        
        % Get data and REMOVE NaNs
        nolight_data = performance_data.(current_area).nolight;
        opto_data = performance_data.(current_area).(current_window);
        
        nolight_data = nolight_data(~isnan(opto_data));
        opto_data = opto_data(~isnan(opto_data));
        
        if isempty(nolight_data) || isempty(opto_data) || length(nolight_data) < 2 || length(opto_data) < 2
            effect_sizes.(current_area).(current_window).cohens_d = NaN;
            effect_sizes.(current_area).(current_window).ci = [NaN, NaN];
            continue
        end
        
        % Calculate Cohen's d
        mean_diff = nanmean(nolight_data) - nanmean(opto_data);
        nolight_std = nanstd(nolight_data);
        opto_std = nanstd(opto_data);
        
        if nolight_std == 0 && opto_std == 0
            cohens_d = 0;
            pooled_std = 1;  % Arbitrary for bootstrap
        elseif nolight_std == 0 || opto_std == 0
            pooled_std = max(nolight_std, opto_std);
            cohens_d = mean_diff / pooled_std;
        else
            pooled_std = sqrt((nolight_std^2 + opto_std^2) / 2);
            cohens_d = mean_diff / pooled_std;
        end
        
        % Bootstrap confidence interval for Cohen's d
        boot_cohens_d = zeros(n_bootstrap, 1);
        for iboot = 1:n_bootstrap
            % Randomly sample SAME indices from both conditions (paired data)
            indices = randsample(length(nolight_data), length(nolight_data), true);
            boot_nolight = nolight_data(indices);
            boot_opto = opto_data(indices);
            
            boot_diff = nanmean(boot_nolight) - nanmean(boot_opto);
            boot_nolight_std = nanstd(boot_nolight);
            boot_opto_std = nanstd(boot_opto);
            
            if boot_nolight_std == 0 && boot_opto_std == 0
                boot_cohens_d(iboot) = 0;
            elseif boot_nolight_std == 0 || boot_opto_std == 0
                boot_pooled_std = max(boot_nolight_std, boot_opto_std);
                if boot_pooled_std > 0
                    boot_cohens_d(iboot) = boot_diff / boot_pooled_std;
                else
                    boot_cohens_d(iboot) = 0;
                end
            else
                boot_pooled_std = sqrt((boot_nolight_std^2 + boot_opto_std^2) / 2);
                boot_cohens_d(iboot) = boot_diff / boot_pooled_std;
            end
        end
        
        ci_lower = prctile(boot_cohens_d, (1-confidence_level)/2 * 100);
        ci_upper = prctile(boot_cohens_d, (1+confidence_level)/2 * 100);
        
        effect_sizes.(current_area).(current_window).cohens_d = cohens_d;
        effect_sizes.(current_area).(current_window).ci = [ci_lower, ci_upper];
    end
end

%% Create comprehensive comparison table
fprintf('\n');
fprintf('================================================================================\n');
fprintf('COMPREHENSIVE STATISTICAL COMPARISON TABLE\n');
fprintf('================================================================================\n');

for ind_window = 2:length(window_list)
    fprintf('--- %s Window ---\n', upper(window_list_label{ind_window}));
    fprintf('%-8s | %-6s | %-12s | %-20s\n', ...
        'Region', 'n', 'Bootstrap_FDR', 'Cohen''s d [CI]');
    fprintf('%.65s\n', repmat('-', 1, 65));
    
    for ind_area = 1:length(region_list)
        current_area = cell2mat(region_list(ind_area));
        current_window = cell2mat(window_list(ind_window));
        
        n_sess = session_counts(ind_area, ind_window);
        boot_p_fdr = bootstrap_pvalues_fdr(ind_area, ind_window-1);
        
        if isfield(effect_sizes, current_area) && isfield(effect_sizes.(current_area), current_window)
            d = effect_sizes.(current_area).(current_window).cohens_d;
            ci = effect_sizes.(current_area).(current_window).ci;
        else
            d = NaN;
            ci = [NaN, NaN];
        end
        
        % Format p-value for reporting (show actual value with sufficient precision)
        if isnan(boot_p_fdr)
            p_str = sprintf('%-12s', 'NaN');
        else
            p_str = sprintf('%-12.6f', boot_p_fdr);
        end
        
        fprintf('%-8s | %-6d | %s | %5.2f [%5.2f,%5.2f]\n', ...
            current_area, n_sess, p_str, d, ci(1), ci(2));
    end
    fprintf('\n');
end

%% List of mice fore each area

area_list={'A1', 'wS1', 'wS2', 'wM2', 'ALM', 'fpS1'}

for a=1:6

this_area=area_list{1,a};

Sessions_List=[];
Session_cnt=1;


for i=1:size(optomat,2)

    target_area=optomat(i).fiber_location;
    this_session=cell2mat(optomat(i).session_id);

    if strcmp(target_area, this_area)
        
        Sessions_List{Session_cnt,1}=this_session(5:9);
        Session_cnt=Session_cnt+1;
    end

end

Mouse_list=unique(Sessions_List);

All_Area_Mouse_Session.Session_list.(this_area)=Sessions_List;
All_Area_Mouse_Session.Mouse_list.(this_area)=Mouse_list;

end