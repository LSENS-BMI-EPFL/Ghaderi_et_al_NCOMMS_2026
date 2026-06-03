%% =========================================================================
% pc_projections.m
% =========================================================================
%
% This script analyzes attractor state dynamics in neural trajectories
% by quantifying convergence, stability, and consistency across trials.
%
%
% Code Author: Parviz Ghaderi (with AI assistance)
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: Provides multiple quantitative measures to demonstrate
% that neural trajectories reach attractor states:
% 1. Trajectory speed (velocity) - should decrease in attractor
% 2. Cross-trial variability - should decrease as trials converge
% 3. Distance from mean trajectory - should decrease in attractor
% 4. Angular consistency - direction vectors should align
% 5. Single-trial visualization
%
% Dependencies:
%   - psth_10ms.mat (contains trial data)
%   - Area_list.mat (contains brain area information)
%   - bin_spike_counts.m
%
% Output:  pc_projections attractor dynamics
% =========================================================================

%% Initialize workspace and load data
clear all
close all
clc

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'psth_10ms.mat'])
load([directory filesep 'data_helpers' filesep 'Area_list.mat'])

rng(0)

%% Define analysis parameters (same as original PCA script)
params.QuietState = 'Quiet_(jaw & whisker)'; %All_trials  Quiet_(jaw & whisker)
params.completion_state = 'completed_trials';
params.TrialType = [1,3];  % 1: gotone/whisker (Hit trials)
params.LickState = [1,0];  % 1: lick
params.CellType = 'All';
regionlist = {'A1','wS1','wS2','wM2','ALM'};

%% Analysis parameters
min_trials_per_session = 5;  % Minimum trials needed per session
sz=size(psth_mat(1).spike_counts,1);  % in ms
if sz==600
    time_axis=[-1+0.005:0.005:2];
    pca_endbin = 600;       % PCA calculation end bin (30 bins × 100ms = 3 seconds
else
    time_axis=[-1+0.01:0.01:2];
    pca_endbin = 300;       % PCA calculation end bin (30 bins × 100ms = 3 seconds)
end
trial_averagedpca=1
time_axis_full = time_axis;
%% Storage for results - NOW SESSION-WISE!
attractor_results = struct();
for iarea = 1:length(regionlist)
    CurrentArea = cell2mat(regionlist(iarea));
    iprb = find(strcmp(CurrentArea, [psth_mat.probe_location]));
    session_counter=0;
    % Process each probe in current area
    for i = iprb
        sessionID=cell2mat(psth_mat(i).session_id);
        session_counter=session_counter+1;
        Trial = psth_mat(i).trial_type;
        Lick = psth_mat(i).lick_flag;
        % Process each trial condition
        concat_all_trials_data=[];
        cond_id=[];
        data_for_neuron_pca=[];
        for icond = 1:length(params.TrialType)
            Concatsig = [];
            % Apply trial type filter
            IndTrialType = Trial == params.TrialType(icond);
            IndLickstate = Lick == params.LickState(icond);
            % Determine completion state
            switch params.completion_state
                case 'completed_trials'
                    completion_state = ~psth_mat(i).early_lick;
                case 'early_licks'
                    early_licks_all = psth_mat(i).early_lick;
                    lick_time = 0 < (psth_mat(i).lick_time - psth_mat(i).start_time);
                    completion_state = lick_time & early_licks_all;
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
                    Qind = ones(length(IndLickstate), 1);
            end

            CurrTrialInd = [Qind & completion_state & IndLickstate & IndTrialType];

            % Apply cell type filter
            switch params.CellType
                case 'RS'
                    CelltypeInd = psth_mat(i).unit_rsUnits;
                case 'FS'
                    CelltypeInd = psth_mat(i).unit_fsUnits;
                case 'RS_FS'
                    CelltypeInd = (psth_mat(i).unit_fsUnits | psth_mat(i).unit_rsUnits);
                case 'All'
                    CelltypeInd = logical(ones(length(psth_mat(i).unit_rsUnits), 1));
            end

            % Apply CCF filter on cell location
            ind_ccf_filter = ismember(psth_mat(i).unit_ccf_location, area_list.(CurrentArea));
            CurrCellInd = (CelltypeInd & ind_ccf_filter);
            if ~sum(CurrCellInd)
                continue;
            end
            %% Calculate PSTH for current condition
            % Get current spike counts
            CurrSC = psth_mat(i).spike_counts;
            % Apply resolution change
       
                WindowCenters = psth_mat(i).trial_timestamps;
     

            % Get INDIVIDUAL trials for THIS SESSION ONLY
            trial_indices = find(CurrTrialInd);
            n_trials = length(trial_indices);

            % Extract neural data: neurons × time × trials
            all_trials_data = [];

            for itrial = 1:n_trials
                trial_idx = trial_indices(itrial);
                CurrSp_trial = squeeze(CurrSC(:,trial_idx,CurrCellInd));

                % Baseline subtraction
                t1 = -1; t2 = 0;
                [~,b] = min(abs(WindowCenters-t1)); baselineFirstBin = b;
                [~,b] = min(abs(WindowCenters-t2)); baselineLastBin = b;
                baseline_mean = repmat(mean(CurrSp_trial(baselineFirstBin:baselineLastBin,:),1),size(CurrSp_trial,1),1);
                CurrSp_trial = CurrSp_trial - baseline_mean;
                % Store this trial
                all_trials_data(:, :, itrial) = CurrSp_trial';  % neurons × time
            end

            data_for_neuron_pca = [data_for_neuron_pca;[mean(all_trials_data,3)]'];
            concat_all_trials_data=cat(3, concat_all_trials_data, all_trials_data);
            cond_id=[cond_id;repmat(icond,[size(all_trials_data,3),1])];
        end  % over condition

        %% Get dimensions
        n_neurons = size(concat_all_trials_data, 1);
        n_timebins = size(concat_all_trials_data, 2);

     
        if ~sum(data_for_neuron_pca)
            session_counter=session_counter-1;
            continue;
        end






        [coeff_neuron, ~, ~, ~, explained_neuron, mu_neuron] = pca(data_for_neuron_pca);

        fprintf('    -> Neuron-space PCA: PC1: %.1f%%, PC2: %.1f%%\n', explained_neuron(1), explained_neuron(2));

        %% Project each trial onto PCs to get trajectories
        trial_trajectories_pc =[];
        for itrial = 1:size(concat_all_trials_data,3)
            % Get neural activity for this trial: timebins × neurons
            trial_data = concat_all_trials_data(:, :, itrial)';  % timebins × neurons
            % Project onto first 2 PCs
            projected_trial = (trial_data - mu_neuron) * coeff_neuron(:, 1:2);  % timebins × 2
            % Store: trial × PC × time
            trial_trajectories_pc(itrial, 1, :) = projected_trial(:, 1)';  % PC1 over time
            trial_trajectories_pc(itrial, 2, :) = projected_trial(:, 2)';  % PC2 over time
        end




        for i_condition=1:length(params.TrialType)
            curr_trial_id=find(cond_id==i_condition);
            % Analysis 1: Trajectory Speed (velocity)
            curr_trial_trajectories_pc=trial_trajectories_pc(curr_trial_id,:,:);       
            %% Store SESSION-level results
            attractor_results.(CurrentArea).sessions(session_counter).conditions(i_condition).probe_id = i;
            attractor_results.(CurrentArea).sessions(session_counter).conditions(i_condition).condition = i_condition;
            attractor_results.(CurrentArea).sessions(session_counter).conditions(i_condition).n_trials = length(curr_trial_id);
            attractor_results.(CurrentArea).sessions(session_counter).conditions(i_condition).n_neurons = n_neurons;
            attractor_results.(CurrentArea).sessions(session_counter).conditions(i_condition).trial_trajectories_pc = curr_trial_trajectories_pc;
            attractor_results.(CurrentArea).sessions(session_counter).conditions(i_condition).explained_variance = explained_neuron(1:2);
            attractor_results.(CurrentArea).sessions(session_counter).conditions(i_condition).sessionID = sessionID;
        end

    end % End of session (probe) loop

    for i_condition=1:length(params.TrialType)
        attractor_results.(CurrentArea).area_avg.conditions(i_condition).n_sessions = session_counter;
    end

end % End of area loop

%% Save results
directory=[CurrentDir filesep 'processed_data' filesep];

save( [directory 'pc_projections.mat'], 'attractor_results', 'params', 'pca_endbin');
