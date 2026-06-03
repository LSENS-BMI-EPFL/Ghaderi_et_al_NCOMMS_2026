%% =========================================================================
% Ghaderi2025_Figure1_performance_heatmap.m
% =========================================================================
% 
% This script generates a heatmap showing lick probability across sessions
% Matrix format: 5 rows (trial types) x 35 columns (sessions)
% Color intensity represents probability of licking (0-100%)
%
% Code Author: Parviz Ghaderi
% Date: 2025
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

load([directory filesep 'processed_data' filesep 'psth_10ms.mat'])
%% Define analysis parameters
params.QuietState = 'All_trials';  
params.completion_state = 'completed_trials';  
params.TrialType = [1, 2, 3, 4, 5];  % 5 trial types

% Trial type labels
trialtype_names = {'Go-tone Whisker'; 'Go-tone'; 'Nogo-tone Whisker'; 'Nogo-tone'; 'Whisker'};

%% Get unique session IDs
[unique_session_names, unique_session_ids] = unique([psth_mat.session_id]);
n_sessions = length(unique_session_ids);

fprintf('Processing %d sessions and %d trial types...\n', n_sessions, length(params.TrialType));

%% Calculate performance matrix (5 trial types x n_sessions)
performance = nan(length(params.TrialType), n_sessions);

for icond = 1:length(params.TrialType)
    session_counter = 1;
    
    % Process each session
    for i = unique_session_ids'
        Trial = psth_mat(i).trial_type;
        Lick = psth_mat(i).lick_flag;
        
        % Apply trial type filter
        IndTrialType = Trial == params.TrialType(icond);
        
        % Determine completion state based on early lick behavior
        switch params.completion_state
            case 'completed_trials'
                completion_state = ~psth_mat(i).early_lick;
            case 'early_licks'
                early_licks_all = psth_mat(i).early_lick;
                lick_time = 0 < (psth_mat(i).lick_time - psth_mat(i).start_time);
                completion_state = lick_time & early_licks_all;
            case 'all_trials'
                completion_state = logical(ones(length(~psth_mat(i).early_lick), 1));
        end
        
        % Apply quiet state filter
        switch params.QuietState
            case 'Quiet_(whisker_speed)'
                Qind = psth_mat(i).quiet_trial_whisker_speed;
            case 'Quiet_(jaw_movement)'
                Qind = psth_mat(i).quiet_trial_jaw_movement;
            case 'Quiet_(jaw & whisker)'
                Qind = psth_mat(i).quiet_trial_jaw_movement & psth_mat(i).quiet_trial_whisker_speed;
            case 'Non_quiet'
                Qind = ~(psth_mat(i).quiet_trial_jaw_movement & psth_mat(i).quiet_trial_whisker_speed);
            case 'All_trials'
                Qind = ones(length(IndTrialType), 1);
        end
        
        % Combine trial selection criteria
        CurrTrialInd = [completion_state & IndTrialType];
        
        % Calculate probability of licking for current session and trial type
        if sum(CurrTrialInd) > 0
            plick = sum(CurrTrialInd & Lick) / sum(CurrTrialInd) * 100;
        else
            plick = NaN;  % No trials for this condition
        end
        
        performance(icond, session_counter) = plick;
        session_counter = session_counter + 1;
    end % End of session loop
end % End condition loop

fprintf('Performance matrix created: %d x %d (trial types x sessions)\n', size(performance, 1), size(performance, 2));

%% Create heatmap visualization
figure('Units', 'centimeters', ...
       'Position', [2 2 25 12], ...
       'PaperType', 'A4', ...
       'PaperUnits', 'centimeters', ...
       'Color', 'w');

% Create the heatmap using imagesc
imagesc(performance);

% Set colormap (white to red, or your preferred color scheme)
colormap(hot);  % Options: 'hot', 'jet', 'parula', 'turbo'
% colormap(flipud(gray));  % Alternative: grayscale

% Add colorbar
cb = colorbar;
cb.Label.String = 'Lick Probability (%)';
cb.Label.FontSize = 14;
cb.Label.FontWeight = 'bold';

% Set color limits
caxis([0 100]);

% Set axis labels
xlabel('Session Number', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Trial Type', 'FontSize', 14, 'FontWeight', 'bold');

% Set y-axis ticks and labels (trial types)
yticks(1:length(params.TrialType));
yticklabels(trialtype_names);

% Set x-axis ticks (sessions)
% xticks(1:n_sessions);
% xticklabels(1:n_sessions);

xticks([1 5 10 15 20 25 30 35])
xticklabels([1 5 10 15 20 25 30 35])

ax = gca;
ax.TickDir = 'out';


% Rotate x-axis labels if needed
xtickangle(0);

% Add grid for better readability
% grid on;
% set(gca, 'GridColor', [0.3 0.3 0.3], 'GridAlpha', 0.5);
% set(gca, 'XAxisLocation', 'bottom', 'YAxisLocation', 'left');
% set(gca, 'FontSize', 12);

% Add title
title(sprintf('Lick Probability Heatmap (%d Sessions)', n_sessions), ...
      'FontSize', 16, 'FontWeight', 'bold');

% Add text values on each cell (optional - comment out if too cluttered with many sessions)
% Uncomment the following lines to show exact values on heatmap:
% for irow = 1:size(performance, 1)
%     for icol = 1:size(performance, 2)
%         if ~isnan(performance(irow, icol))
%             text(icol, irow, sprintf('%.0f', performance(irow, icol)), ...
%                  'HorizontalAlignment', 'center', ...
%                  'VerticalAlignment', 'middle', ...
%                  'FontSize', 7, ...
%                  'Color', 'k');  % Black text
%         end
%     end
% end

% Make plot square-ish for better visualization
axis tight;
box on;

%% Print summary statistics
fprintf('\n=== SUMMARY STATISTICS ===\n');
fprintf('%-20s | %-12s | %-12s\n', 'Trial Type', 'Mean (%)', 'SEM (%)');
fprintf('%s\n', repmat('-', 1, 50));

for icond = 1:length(params.TrialType)
    mean_val = nanmean(performance(icond, :));
    sem_val = nanstd(performance(icond, :)) / sqrt(sum(~isnan(performance(icond, :))));
    fprintf('%-20s | %8.2f     | %8.2f\n', trialtype_names{icond}, mean_val, sem_val);
end


%% Export figure

directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');


