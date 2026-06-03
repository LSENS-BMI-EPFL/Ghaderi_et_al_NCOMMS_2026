%% =========================================================================
% Temporal_corrrelation_100ms.m
% =========================================================================
% 
% This script calculates temporal correlations between neural activity across
% different time bins using 100ms binning for the manuscript "Contextual gating of whisker-evoked 
% responses by frontal cortex supports flexible decision making" 
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script computes temporal correlation matrices between
% different time bins for various trial conditions using 100ms time windows.
% It analyzes correlations between neural responses across time and compares
% them to shuffled data to assess the significance of temporal relationships.
% This version uses larger time bins for lower temporal resolution analysis.
%
% Dependencies: 
%   - psth_10ms.mat (contains trial data)
%   - area_list.mat (contains brain area information)
%   - angleBtwNDVectors.m (for calculating angles between vectors)
%
% Input: Processed PSTH data
% Output: Temporal correlation analysis results saved to Temporal_corrrelation_100ms.mat
% =========================================================================

%% Initialize workspace and load data
clear all
close all
clc

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'psth_10ms.mat'])
load([directory filesep 'data_helpers' filesep 'area_list.mat'])

%% Define analysis parameters
% Brain regions to analyze
params.regionlist = {'A1', 'wS1', 'wS2', 'wM2', 'ALM'};

% Trial types and lick states (10 conditions total)
params.TrialType = [1, 2, 3, 4, 5, 1, 2, 3, 4, 5];
params.LickState = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1];

% Trial type names based on combination of trial types and lick states
params.trialtype_names = {'gotone_whisker'; 'gotone'; 'nogotone_whisker'; 'nogotone'; 'whisker'; ...
                          'gotone_whisker_lick'; 'gotone_lick'; 'nogotone_whisker_lick'; 'nogotone_lick'; 'whisker_lick'};

% Analysis parameters
params.completion_state = 'completed_trials';
params.QuietState = 'Quiet_(jaw & whisker)';   % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trials'
params.CellType = 'All';  % Options: 'RS', 'FS', 'FS_RS', 'All'

% Time parameters
trial_time = psth_mat(1).trial_timestamps;
bin_width = 10;   % Window length (number of bins to concatenate)

%% Main analysis loop across trial conditions and brain regions
for ind_cond = 1:length(params.TrialType)
    for ind_area = 1:length(params.regionlist)
        curr_area = cell2mat(params.regionlist(ind_area));
        list_probes = find(strcmp(curr_area, [psth_mat.probe_location]));
        session_counter = 0;
        
        % Initialize storage variables
        mean_activity = [];
        mean_activity_shuffled = [];
        active_cells = [];
        R2_all = [];
        Pvalue_all = [];
        angle_all = [];
        R2_all_shuffled = [];

        %% Process each probe in current area
        for ind_probes = list_probes
            session_counter = session_counter + 1;
            
            % Extract trial information
            trial = psth_mat(ind_probes).trial_type == params.TrialType(ind_cond);
            lick = psth_mat(ind_probes).lick_flag == params.LickState(ind_cond);
            
            %% Determine trial completion status
            switch params.completion_state
                case 'completed_trials'
                    completed_trials_ind = ~psth_mat(ind_probes).early_lick;
                case 'early_licks'
                    early_licks_all = psth_mat(ind_probes).early_lick;
                    lick_time = 0 < (psth_mat(ind_probes).lick_time - psth_mat(ind_probes).start_time);
                    completed_trials_ind = lick_time & early_licks_all;
            end
            
            %% Determine quiet trial status
            switch params.QuietState
                case 'Quiet_(whisker_speed)'
                    Qind = psth_mat(ind_probes).quiet_trial_whisker_speed;
                case 'Quiet_(jaw_movement)'
                    Qind = psth_mat(ind_probes).quiet_trial_jaw_movement;
                case 'Quiet_(jaw & whisker)'
                    Qind = psth_mat(ind_probes).quiet_trial_jaw_movement & psth_mat(ind_probes).quiet_trial_whisker_speed;
                case 'Non_quiet'
                    Qind = ~(psth_mat(ind_probes).quiet_trial_jaw_movement & psth_mat(ind_probes).quiet_trial_whisker_speed);
                case 'All_trials'
                    Qind = ones(length(trial), 1);
            end
            
            % Combine all trial filters
            ind_trials = trial & lick & Qind & completed_trials_ind;
            
            %% Determine cell type filter
            switch params.CellType
                case 'RS'
                    CelltypeInd = psth_mat(ind_probes).unit_rsUnits;
                case 'FS'
                    CelltypeInd = psth_mat(ind_probes).unit_fsUnits;
                case 'FS_RS'
                    CelltypeInd = (psth_mat(ind_probes).unit_fsUnits | psth_mat(ind_probes).unit_rsUnits);
                case 'All'
                    CelltypeInd = logical(ones(length(psth_mat(ind_probes).unit_rsUnits), 1));
            end

            %% Apply CCF location filter
            ind_ccf_filter = ismember(psth_mat(ind_probes).unit_ccf_location, area_list.(curr_area));
            CurrCellInd = (CelltypeInd & ind_ccf_filter);

            %% Extract and process neural data
            current_sc = psth_mat(ind_probes).spike_counts;
            
            % Concatenate time bins if bin_width > 1
            if bin_width ~= 1
                st = 1;
                en = bin_width;
                bin_flg = 1;
                current_sp_binchanged = [];
                
                % Concatenate bins
                for i_bin = 1:size(current_sc, 1) / bin_width
                    current_sp_binchanged(bin_flg, :, :) = sum(current_sc(st:en, :, :));
                    trial_time_binchanged(bin_flg) = trial_time(en);
                    st = en + 1;
                    en = st + bin_width - 1;
                    bin_flg = bin_flg + 1;
                end
                current_sc = current_sp_binchanged;
            end
            
            % Extract data for current cells and trials
            current_sc_currCellInd = current_sc(:, :, CurrCellInd);
            current_sc_currCellInd_currTrialInd = current_sc_currCellInd(:, ind_trials, :);

            %% Calculate temporal correlations if sufficient trials exist
            if 1 < sum(ind_trials)
                % Restructure matrix (X [trials X neurons X bins])
                current_sc_currCellInd_currTrialInd = permute(current_sc_currCellInd_currTrialInd, [2, 3, 1]);
                
                % Initialize storage for current session
                current_TC = [];
                current_TV = [];
                current_TC_shuffled = [];
                current_Pval = [];
                shuffled = [];
                
                %% Loop over trials and compute cross-correlation between time bins
                for ind_trial = 1:size(current_sc_currCellInd_currTrialInd, 1)
                    curr_trial = squeeze(current_sc_currCellInd_currTrialInd(ind_trial, :, :));
                    
                    % Calculate correlation matrix for current trial
                    [R, P, ~, ~] = corrcoef(curr_trial);
                    ThetaInRadians = angleBtwNDVectors(curr_trial');
                    
                    % Store results
                    current_TC(:, :, ind_trial) = R;
                    current_Pval(:, :, ind_trial) = P;
                    current_TV(:, :, ind_trial) = ThetaInRadians;

                    %% Generate shuffled data for comparison
                    curr_trial_shuffle = []; % Shuffling over neurons while preserving mean activity in each bin
                    for ind_timebin = 1:size(curr_trial, 2)
                        curr_trial_shuffle(:, ind_timebin) = curr_trial(randperm(size(curr_trial, 1)), ind_timebin);
                    end
                    shuffled(ind_trial, :, :) = curr_trial_shuffle;
                    
                    % Calculate correlation matrix for shuffled data
                    [RShuffle, P, ~, ~] = corrcoef(curr_trial_shuffle);
                    current_TC_shuffled(:, :, ind_trial) = RShuffle;
                end
                
                %% Average results across trials
                R2_all(:, :, session_counter) = nanmean(current_TC, 3);
                Pvalue_all(:, :, session_counter) = nanmean(current_Pval, 3);
                angle_all(:, :, session_counter) = nanmean(current_TV, 3);
                R2_all_shuffled(:, :, session_counter) = nanmean(current_TC_shuffled, 3);
                
                %% Calculate neuronal activity metrics
                mean_activity = [mean_activity; squeeze(mean(current_sc_currCellInd_currTrialInd, 1))];
                mean_activity_shuffled = [mean_activity_shuffled; squeeze(mean(shuffled, 1))];
                
                % Calculate percentage of active cells (binary measure)
                active_cells = [active_cells; ((squeeze(sum(current_sc_currCellInd_currTrialInd, 2)) / size(current_sc_currCellInd_currTrialInd, 2)) * 100)];
            else
                % Fill with NaN if insufficient trials
                R2_all(:, :, session_counter) = nan(size(current_sc, 1), size(current_sc, 1));
                angle_all(:, :, session_counter) = nan(size(current_sc, 1), size(current_sc, 1));
                Pvalue_all(:, :, session_counter) = nan(size(current_sc, 1), size(current_sc, 1));
                R2_all_shuffled(:, :, session_counter) = nan(size(current_sc, 1), size(current_sc, 1));
            end
        end % End of probe loop
        
        %% Store results for current condition and area
        % Correlation matrices
        correlation_matrix.(cell2mat(params.trialtype_names(ind_cond))).(curr_area) = R2_all;
        correlation_matrix_shuffled.(cell2mat(params.trialtype_names(ind_cond))).(curr_area) = R2_all_shuffled;
        
        % Vector angles
        angle_matrix.(cell2mat(params.trialtype_names(ind_cond))).(curr_area) = angle_all;
        
        % P-values
        pvalue_matrix.(cell2mat(params.trialtype_names(ind_cond))).(curr_area) = Pvalue_all;
        
        % Neuronal activity
        neuronal_activity.(cell2mat(params.trialtype_names(ind_cond))).(curr_area) = mean_activity;
        neuronal_activity_shuffled.(cell2mat(params.trialtype_names(ind_cond))).(curr_area) = mean_activity_shuffled;
        
        % Active cells percentage
        active_cells_percentage.(cell2mat(params.trialtype_names(ind_cond))).(curr_area) = active_cells;
    end % End of area loop
end % End of condition loop

%% Prepare output variables
if bin_width ~= 1
    windowCenters = trial_time_binchanged;
else
    windowCenters = trial_time;
end

%% Save results

directory=[CurrentDir filesep 'processed_data' filesep];
save([directory 'Temporal_corrrelation_100ms.mat'], "correlation_matrix", "angle_matrix", "correlation_matrix_shuffled", ...
     "pvalue_matrix", "neuronal_activity", "neuronal_activity_shuffled", "active_cells_percentage", "windowCenters", '-v7.3');

