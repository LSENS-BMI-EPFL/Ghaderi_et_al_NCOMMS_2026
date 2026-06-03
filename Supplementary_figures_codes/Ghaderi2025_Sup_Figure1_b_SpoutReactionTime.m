%% =========================================================================
% Ghaderi2025_Figure1Sup_SpoutReactionTime.m
% =========================================================================
% 
% This script generates Figure 1 Supplementary showing spout reaction time analysis
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making" 
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script analyzes and plots reaction times to the spout across 
% different trial types. The analysis calculates the time between trial start and 
% first lick, with proper time alignment to whisker stimulus onset.
%
% Dependencies: 
%   - psth_10ms.mat (contains trial data)
%   - tight_subplot.m (for subplot management)
%   - prettify_plot.m (for plot formatting)
%
% Output: PDF figure showing spout reaction time analysis with proper formatting
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


%% Initialize figure and plotting parameters

parent = figure('Position', [100 100 600 800]);

% Create subplot with tight spacing
h = tight_subplot(1, 1, [.1 .1], [.2 .1], [.1 .1]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters
params.QuietState = 'All_trials';  % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trials'
params.completion_state = 'completed_trials';  % Options: 'early_licks', 'completed_trials'
params.TrialType = [1, 2, 3, 4, 5];  % 1: gotone/whisker, 2: gotone/nowhisker, 3: nogotone/whisker, 4: nogotone/nowhisker, 5: notone/whisker

% Trial type labels and formatting
trialtype_names = {'Go-tone Whisker'; 'Go-tone'; 'Nogo-tone Whisker'; 'Nogo-tone'; 'Whisker'};
xtick = [1:5];

% Color scheme
colorcodes = [0 0 1; 0 .8 1; 1 0 0; 1 .5 0; .5 .5 .5];
params.colormap = {'#0008FF'; '#228B22'; '#00C3FF'; '#FF0000'; '#FF7F00'; '#000000'; '#00C3FF'; '#FF7F00'; '#FF7F00'; '#808080'; '#6B3686'; '#74B99A'; '#A020F0'; '#FFD700'};
params.colortype = {'wS1'; 'wS2'; 'CR2'; 'ALM'; 'CR4'; 'wM2'; 'FA2'; 'FA3'; 'FA4'; 'FA5'; 'Lick'; 'NoLick'; 'A1'; 'tjM1'};
params.Map = horzcat(params.colortype, params.colormap);

% Y-axis shift values (not used in this script but kept for consistency)
shift_y_values = [0, 10, 20, 40, 65];

%% Get unique session IDs
[unique_session_names, unique_session_ids] = unique([psth_mat.session_id]);

%% Calculate reaction time for each trial type
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
        
        % Calculate reaction time (time from trial start to first lick)
        lick_time = psth_mat(i).lick_time;
        trial_start = psth_mat(i).start_time;
        rt = lick_time - trial_start;  % Lick time is 1.5 second shifted in original nwb files (Not anymore ?!)
        
        % Filter out unrealistic reaction times
        rt((rt > 2) | (rt < 1)) = nan;
        rt = rt - 1;  % Reference to whisker stimulus
        
        % Store mean reaction time for current session and trial type
        reaction_time(icond, session_counter) = nanmean(rt(CurrTrialInd));
        session_counter = session_counter + 1;
    end % End of session loop
    
    % Plot reaction time for current trial type
    hold(axs(1), "on");
    bar(axs(1), icond, nanmean(reaction_time(icond, :)), 'FaceColor', colorcodes(icond, :));
    errorbar(axs(1), icond, nanmean(reaction_time(icond, :)), nanstd(reaction_time(icond, :)) / sqrt(sum(~isnan(reaction_time(icond, :)))), 'vertical', 'Color', [0 0 0], 'CapSize', 10);

end % End condition loop

%% Plot individual session data
plot(axs(1), [1:5] + .1, reaction_time, 'o', 'color', [0 0 0 .2]);

%% Format plot
% Set x-axis ticks and labels
xticks(axs(1), xtick);
xticklabels(axs(1), trialtype_names);

% Set axis labels
xlabel(axs(1), 'Trial type');
ylabel(axs(1), 'Reaction time (s)');

% Set y-axis ticks and labels
yticklabels(axs(1), get(axs(1), "YTick"));

% Add session count text
text(axs(1), 4, 80, {[num2str(length(unique_session_names)) ' sessions']});

% Apply plot formatting
prettify_plot('LineThickness', 2, 'TickLength', [.01 .01], 'AxisTightness', 'keep', 'PointSize', 5, 'GeneralFontSize', 12);


%% Export figure

directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');






