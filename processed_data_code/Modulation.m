%% =========================================================================
% Modulation.m
% =========================================================================
% 
% This script calculates ROC analysis and modulation indices for different
% behavioral time windows for the manuscript "Contextual gating of whisker-evoked 
% responses by frontal cortex supports flexible decision making" 
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script calculates ROC analysis for Go-tone whisker trials
% across different time windows (audio, delay, whisker, lick). It computes
% discrimination indices and p-values for each cell by comparing activity
% in specific time windows to baseline periods.
%
% Dependencies: 
%   - psth_10ms.mat (contains trial data)
%   - area_list.mat (contains brain area information)
%   - selectivity_index_calculation.m (for ROC analysis)
%
% Input: Processed PSTH data
% Output: Modulation analysis results saved to Modulation.mat
% =========================================================================

%% Initialize workspace and load data

clear all
close all
clc

CurrentDir=pwd;
directory=[CurrentDir];
load([directory filesep 'processed_data' filesep 'psth_10ms.mat'])
rng(0)

%% Define analysis parameters
% Trial selection and behavioral parameters
params.QuietState = 'Quiet_(jaw & whisker)';   % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trials'
params.BaselineSubtraction = 0;
params.completion_state = 'completed_trials';   % Options: 'early_licks', 'completed_trials'
params.TrialType = [1];   % 1: gotone/whisker
params.LickState = [1];  % lick 1: lick
params.CellType = 'All';           % Options: 'RS', 'FS', 'RS_FS', 'All'
params.regionlist = {'A1', 'wS1', 'ALM', 'wM2', 'wS2'};

% Time window parameters
t_start = -1;  % Start time (seconds)
t_end = 2;     % End time (seconds)
bin_width = 0.01;  % 10ms bins
XTickLabel = {'-1'; '0'; '1'; '2'};
xtick = [-1; 0; 1; 2];

% Analysis windows for different behavioral periods
window_name = {'audio', 'delay', 'whisker', 'lick'};
windows_list1 = {[101:103], [181:200], [201:203], [231:250]};  % Time bins for analysis
windows_baseline = {[98:100], [81:100], [198:200], [81:100]};  % Baseline time bins

time_bin = 0.01;  % 10ms time resolution

% Movement signals to analyze
movements_signals = {'whisker_speed', 'snout_angle', 'piezo_lick_trace', 'jaw_movement', 'tongue_movement'};
movements_signals_tag = {'Whisker', 'Snout', 'Piezo lick', 'Jaw', 'Tongue'};

% Movement analysis parameters
params.movement_baselineSubtraction = 0;
params.movement_normalization = 0;

% Color scheme for different brain regions
params.colormap = {'#0008FF'; '#228B22'; '#00C3FF'; '#FF0000'; '#FF7F00'; '#000000'; '#00C3FF'; '#FF7F00'; '#FF7F00'; '#808080'; '#6B3686'; '#74B99A'; '#A020F0'; '#FFD700'};
params.colortype = {'wS1'; 'wS2'; 'CR2'; 'ALM'; 'CR4'; 'wM2'; 'FA2'; 'FA3'; 'FA4'; 'FA5'; 'Lick'; 'NoLick'; 'A1'; 'tjM1'};
params.Map = horzcat(params.colortype, params.colormap);

%% Initialize progress tracking
total_iterations = length(window_name) * length(params.regionlist);
progress_bar = waitbar(0, 'Processing data...');
iteration_counter = 0; % Track iterations

%% Main analysis loop across time windows
for ind_window = 1:length(window_name)
    curr_win_name = cell2mat(window_name(ind_window));
    roc_mat = [];
    cnt_area = 0;
    
    for ind_area = 1:length(params.regionlist)
        current_area = cell2mat(params.regionlist(ind_area));
        probe_list = find(strcmp(current_area, [psth_mat.probe_location]));
        session_cnt = 1;
        
        for i_probe = 1:length(probe_list)
            ind_probe = probe_list(i_probe);
            sp_cnt_condition = [];
            
            %% Process each trial condition
            for ind_cond = 1:length(params.TrialType)
                % Extract trial information
                Trial = psth_mat(ind_probe).trial_type;
                Lick = psth_mat(ind_probe).lick_flag;
                
                % Define trial conditions
                IndTrialType = Trial == params.TrialType(ind_cond);
                IndLickstate = Lick == params.LickState(ind_cond);
                
                %% Determine trial completion status
                switch params.completion_state
                    case 'completed_trials'
                        completion_state = ~psth_mat(ind_probe).early_lick;
                    case 'early_licks'
                        early_licks_all = psth_mat(ind_probe).early_lick;
                        lick_time = 0 < (psth_mat(ind_probe).lick_time - psth_mat(ind_probe).start_time);
                        completion_state = lick_time & early_licks_all;
                end

                %% Determine quiet trial status
                switch params.QuietState
                    case 'Quiet_(whisker_speed)'
                        Qind = psth_mat(ind_probe).quiet_trial_whisker_speed;
                    case 'Quiet_(jaw_movement)'
                        Qind = psth_mat(ind_probe).quiet_trial_jaw_movement;
                    case 'Quiet_(jaw & whisker)'
                        Qind = psth_mat(ind_probe).quiet_trial_jaw_movement & psth_mat(ind_probe).quiet_trial_whisker_speed;
                    case 'Non_quiet'
                        Qind = ~(psth_mat(ind_probe).quiet_trial_jaw_movement & psth_mat(ind_probe).quiet_trial_whisker_speed);
                    case 'All_trials'
                        Qind = logical(ones(length(IndLickstate), 1));
                end
                
                % Combine all trial filters
                current_trial_ind = [Qind & completion_state & IndLickstate & IndTrialType];

                %% Determine cell type filter
                switch params.CellType
                    case 'RS'
                        CelltypeInd = psth_mat(ind_probe).unit_rsUnits;
                    case 'FS'
                        CelltypeInd = psth_mat(ind_probe).unit_fsUnits;
                    case 'RS_FS'
                        CelltypeInd = (psth_mat(ind_probe).unit_fsUnits | psth_mat(ind_probe).unit_rsUnits);
                    case 'All'
                        CelltypeInd = logical(ones(length(psth_mat(ind_probe).unit_rsUnits), 1));
                end
                
                %% Extract neural data for current condition
                curr_sp = psth_mat(ind_probe).spike_counts;
                current_cell_ind = CelltypeInd;
                
                % Extract trials for current condition
                curr_sp_trials = curr_sp(:, current_trial_ind, :);
                curr_sp_trials_cells = curr_sp_trials(:, :, current_cell_ind);
                
                % Store condition data
                sp_cnt_condition{ind_cond} = curr_sp_trials_cells;
            end % End of condition loop

            %% Calculate ROC analysis for each cell
            p_value = [];
            discrimination_index = [];
            cluster = [];
            diff_fr = [];
            
            for ind_cells = 1:size(sp_cnt_condition{1}, 3)
                % Define time windows for current analysis
                bins_range1 = cell2mat(windows_list1(ind_window));
                bins_baseline = cell2mat(windows_baseline(ind_window));
                
                % Extract spike counts for analysis and baseline windows
                sp_cnt_bin_cell = [sum(sp_cnt_condition{1}(bins_range1, :, ind_cells), 1), ...
                                   sum(sp_cnt_condition{1}(bins_baseline, :, ind_cells), 1)];
                
                % Create labels for ROC analysis
                label = [ones(1, size(sp_cnt_condition{1}, 2)), ...
                         2 * ones(1, size(sp_cnt_condition{1}, 2))];
                
                % Calculate selectivity index using permutation test
                [di, p, x, y, auc] = selectivity_index_calculation(sp_cnt_bin_cell', label', 'permut', 200, 200);
                
                % Store results
                cluster(ind_cells) = ind_cells;
                p_value(ind_cells, 1) = p;
                discrimination_index(ind_cells, 1) = di;
                
                % Calculate firing rate difference (analysis window - baseline)
                diff_fr(ind_cells, 1) = [mean(mean(sp_cnt_condition{1}(bins_range1, :, ind_cells) / bin_width, 1)) - ...
                                         mean(mean(sp_cnt_condition{1}(bins_baseline, :, ind_cells) / bin_width, 1))];
            end
            
            %% Store results for current probe
            roc_mat(ind_probe).diff_fr = diff_fr;
            roc_mat(ind_probe).discrimination_index = discrimination_index;
            roc_mat(ind_probe).pvalue = p_value;
        end % End of probe loop
        
        % Update progress bar
        iteration_counter = iteration_counter + 1;
        waitbar(iteration_counter / total_iterations, progress_bar, ...
            sprintf('Processing %d/%d', iteration_counter, total_iterations));
    end % End of area loop
    
    %% Store results for current time window
    modulation.(curr_win_name).roc_mat = roc_mat;
end % End of window loop

%% Close progress bar
close(progress_bar);

%% Save results

directory=[CurrentDir filesep 'processed_data' filesep];
save([directory 'Modulation.mat'], "modulation", '-v7.3' );

