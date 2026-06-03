%% =========================================================================
% Ghaderi2025_Figure2_HeatmapsHit.m
% =========================================================================
%
% This script generates Figure 2 showing heatmaps for Hit trials
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script creates heatmaps showing optogenetic manipulation effects
% across all trial types and brain regions for Hit trials. It generates heatmap
% representations with color-coded performance changes during different time windows.
%
% Dependencies:
%   - psth_10ms.mat (contains trial data)
%   - Optoinhibition_mat.mat (contains optogenetic data)
%   - tight_subplot.m (for subplot management)
%   - prettify_plot.m (for plot formatting)
%
% Output: PDF figure containing heatmaps for all trial types
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc

%% Optional: Change figure name (set to 1 to enable)
close all;
change_name = 0;
newname = 'Figure3_3_3';
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
window_list = {'audio', 'delay', 'whisker'};  % Time windows for analysis
trialtype_list = [1];  % All trial types [1, 2, 3, 4, 5]
trialname_list = {'Go-tone Whisker'; 'Go-tone'; 'Nogo-tone Whisker'; 'Nogo-tone'; 'Whisker'};
region_list = {'A1', 'wS1', 'wS2', 'wM2', 'ALM', 'fpS1'};
completion_state = 'completed_trials';

% Initialize data storage
values_table = {};
All_Area_Delta_Performance=[];
a = .2;
colorcodes = [0 0 1 a; 0 .5 1 a; 1 0 0 a; 1 .5 0 a; 0 0 0 a];


%% Create custom colormap for visualization
cyn = hex2rgb('#00FFFF', 1);

% For negative values (blue to white)
vec = [100; 0];
raw = [1 1 1; 0 0 1];
map_neg = interp1(vec, raw, linspace(100, 0, 53));

% For positive values (white to red)
pink = hex2rgb('#C51B7D', 1);
vecg = [0; 100];
rawg = [1 0 0; 1, 1, 1];
map2 = interp1(vecg, rawg, linspace(100, 0, 10));

MAP = [rot90(map2'); map_neg];
map_neg = rot90(MAP');

%% Calculate performance differences for each trial type
fiberlist = [];

for ind_trialtype = 1:length(trialtype_list)

    % Initialize main figure for heatmaps
    parent = figure("Position", [200 200 600 600]);
    h = tight_subplot(1, 1, [.1 .2], [.1 .1], [.1 .1]);
    axs = findall(gcf, 'type', 'axes');
    axs = flipud(axs);



    current_trial_type = trialtype_list(ind_trialtype);
    current_trialtype_name = cell2mat(trialname_list(ind_trialtype));

    % Initialize statistics arrays
    num_mice = [];
    diff_mean = [];
    diff_sem = [];
    num_session = [];

    % Process each brain region
    for ind_area = 1:length(region_list)
        current_area = cell2mat(region_list(ind_area));
        fiberlist = find(strcmp(current_area, {optomat.fiber_location}));
        performance = [];

        % Process each time window
        for ind_window = 1:length(window_list)
            current_window = cell2mat(window_list(ind_window));
            session_counter = 1;

            % Process each session in current area
            for ind_session = fiberlist
                Trial = optomat(ind_session).trial_type;
                Lick = optomat(ind_session).lick_flag;
                Windows = optomat(ind_session).opto_window;
                mouse = optomat(ind_session).session_id{1, 1}(5:9);

                % Apply trial type filter
                current_trialtype_ind = Trial == current_trial_type;

                % Apply optogenetic window filter
                current_optocondition_ind = strcmp(Windows, current_window);
                nolight_optocondition_ind = strcmp(Windows, 'nolight');

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

                % Calculate performance difference (light vs no-light)
                CurrTrialInd = [completion_state_ind & current_trialtype_ind & current_optocondition_ind];
                nolightTrialInd = [completion_state_ind & current_trialtype_ind & nolight_optocondition_ind];
                plick = sum(CurrTrialInd & Lick) / sum(CurrTrialInd) * 100 - sum(nolightTrialInd & Lick) / sum(nolightTrialInd) * 100;

                performance(ind_window, session_counter) = plick;
                mice_name(ind_window, session_counter) = {mouse};
                session_counter = session_counter + 1;
            end % End of session loop
        end % End of window loop

        % Calculate statistics across sessions
        num_mice(ind_area, :) = [length(unique({mice_name{1, :}})), length(unique({mice_name{2, :}})), length(unique({mice_name{3, :}}))];
        diff_mean(ind_area, :) = nanmean(performance, 2)';
        diff_sem(ind_area, :) = nanstd(performance, [], 2)' / sqrt(size(performance, 2));
        num_session(ind_area, 1) = size(performance, 2)';

        All_Area_Delta_Performance.(current_area)=performance;
        
    end % End of area loop

    % Create heatmap for current trial type
    trial_name = strrep(current_trialtype_name, '-', '_');
    trial_name = strrep(trial_name, ' ', '_');
    diff_mean = single(round(diff_mean, 2, "decimals"));
    diff_sem = single(round(diff_sem, 2, "decimals"));


    % Store results in table
    values_table.(trial_name) = [table(diff_mean, diff_sem, num_session, num_mice)];

    % Create heatmap
    diff_mean = single(round(diff_mean)); % round values before plotting
    axes(axs(1));
    h_map = heatmap(diff_mean, 'YLabel', 'Areas', 'XLabel', 'Windows', 'XDisplayLabels', window_list, 'YDisplayLabels', region_list);
    title(h_map, current_trialtype_name);

    % Set up color mapping for heatmap
    MAX = 20;  % Maximum performance change
    MIN = -53; % Minimum performance change
    zero = 0;
    cyan = [0 0 255] / 255;

    % Create colormap for negative values (blue to white)
    min_max_scale = [100; 0];
    min_max_rgb_neg = [1 1 1; cyan];
    map_neg = interp1(min_max_scale, min_max_rgb_neg, linspace(100, 0, abs(MIN)));

    % Create colormap for positive values (white to red)
    pink = [255 0 00] / 255;
    min_max_scale = [100; 0];
    min_max_rgb_pos = [1, 1, 1; pink];
    map_pos = interp1(min_max_scale, min_max_rgb_pos, linspace(100, 0, abs(MAX)));

    clim([MIN, MAX]);
    MAP = [flipud(map_neg); map_pos];
    colormap(h_map, MAP);

    % Export figure
    directory=[CurrentDir filesep 'Main_figures_pdf' filesep];
    exportgraphics(gcf, [directory name '_' current_trialtype_name '.pdf'], 'ContentType', 'vector');

    
end % End of trial type loop

















