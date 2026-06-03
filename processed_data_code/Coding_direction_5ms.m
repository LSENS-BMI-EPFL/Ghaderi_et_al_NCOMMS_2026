%% =========================================================================
% Coding_direction_5ms.m
% =========================================================================
% 
% This script calculates coding directions for different behavioral variables
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making" 
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script computes coding directions for context, stimulus, and lick
% responses using 5ms time bins. It performs cross-validation, orthogonalizes
% coding directions, and projects single-trial responses onto these directions.
% This version includes additional stimulus information compared to the 10ms version.
%
% Dependencies: 
%   - psth_5ms.mat (contains trial data with 5ms bins)
%   - area_list.mat (contains brain area information)
%   - fn_gram_schmidt_process.m (for orthogonalization)
%
% Output: coding_direction_matrix.mat containing projections and indices
% =========================================================================

%% Initialize workspace and load data
clear all
close all
clc

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'data_helpers' filesep 'area_list.mat'])
load([directory filesep 'processed_data' filesep 'psth_5ms.mat'])



%% Define analysis parameters
% Trial selection and behavioral parameters
params.quietstate = 'Quiet_(jaw & whisker)';   % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trial'
params.BaselineSubtraction = 0;
params.completion_state = 'completed_trial';   % Options: 'early_licks', 'completed_trial'
params.trialType = [1, 2, 3, 4, 5];   % 1: gotone/whisker, 2: gotone/nowhisker, 3: nogotone/whisker, 4: nogotone/nowhisker, 5: notone/whisker
params.lickState = [1, 0, 0, 0, 0];  % lick 1: lick, 0: nolick
params.celltype = 'All';           % Options: 'RS', 'FS', 'RS-FS', 'All'
params.regionlist = {'ALM', 'wM2', 'wS2', 'wS1', 'A1'};       % Brain regions to analyze
rng(0)
% Time window parameters
params.t_start = -1;  % Start time (seconds)
params.t_end = 2;     % End time (seconds)
params.bin_width = 0.005;  % 5ms bins
params.XTickLabel = {'-1'; '0'; '1'; '2'};
params.xtick = [-1; 0; 1; 2];

% Analysis parameters
params.balance_method = 'downsample';
params.mintrial = 5;
params.Folds = 10;
params.preTime = -1;
params.postTime = 2;
params.BinSize = 0.005;
params.BinStep = 0.005;
params.normalization = 0;
params.Separation = 0;
params.spikecount = 1;    % 1: spike count, 0: rate
params.windowCenters = [-1 + params.BinSize:params.BinSize:2];

% Analysis windows for different behavioral periods
params.Win_context = [0.8, 1];      % Context coding direction window
params.Win_lick = [1.1, 1.3];      % Lick coding direction window (adjusted for 5ms bins)
params.Win_stim = [1.005, 1.03];   % Stimulus coding direction window
params.Win_base = [-1, 0];          % Baseline window for stimulus


% Set random seed for reproducibility
rng(0)

%% Define trial classification expressions
% Context classification (trial type 1 vs 3)
expr1 = 'Ind.Class1 = [(trial == 1 & lick == 1)];';   % Go-tone with whisker and lick
expr2 = 'Ind.Class2 = [(trial == 3 & lick == 0)];';   % No-go-tone with whisker, no lick

% Stimulus classification (all trials with whisker stimulation)
expr3 = 'Ind.Class3 = [(trial == 5 & lick == 0)];';   % All trials with whisker stimulation

% Lick classification (all trials)
expr4 = 'Ind.Class4 = [(trial == 1 & lick == 1) | (trial == 3 & lick == 1) | (trial == 5 & lick == 1)];';  % All lick trials
expr5 = 'Ind.Class5 = [(trial == 1 & lick == 0) | (trial == 3 & lick == 0) | (trial == 5 & lick == 0)];';  % All no-lick trials

%% Main analysis loop across brain regions
for ind_area = 1:length(params.regionlist)
    current_area = cell2mat(params.regionlist(ind_area));
    probe_list = find(strcmp(current_area, [psth_mat.probe_location]));
    session_counter = 1;
    
    for i_prob = probe_list
        % Extract trial information
        trial = psth_mat(i_prob).trial_type;
        lick = psth_mat(i_prob).lick_flag;
        stim = psth_mat(i_prob).whisker_stim;

        %% Determine trial completion status
        switch params.completion_state
            case 'completed_trial'
                completed_trial_ind = ~psth_mat(i_prob).early_lick;
            case 'early_licks'
                early_licks_all = psth_mat(i_prob).early_lick;
                lick_time = 0 < (psth_mat(i_prob).lick_time - psth_mat(i_prob).start_time);
                completed_trial_ind = lick_time & early_licks_all;
        end
        
        %% Determine quiet trial status
        switch params.quietstate
            case 'Quiet_(whisker_speed)'
                Qind = psth_mat(i_prob).quiet_trial_whisker_speed;
            case 'Quiet_(jaw_movement)'
                Qind = psth_mat(i_prob).quiet_trial_jaw_movement;
            case 'Quiet_(jaw & whisker)'
                Qind = psth_mat(i_prob).quiet_trial_jaw_movement & psth_mat(i_prob).quiet_trial_whisker_speed;
            case 'Non_quiet'
                Qind = ~(psth_mat(i_prob).quiet_trial_jaw_movement & psth_mat(i_prob).quiet_trial_whisker_speed);
            case 'All_trial'
                Qind = ones(length(trial), 1);
        end

        %% Determine cell type filter
        switch params.celltype
            case 'RS'
                CelltypeInd = psth_mat(i_prob).unit_rsUnits;
            case 'FS'
                CelltypeInd = psth_mat(i_prob).unit_fsUnits;
            case 'RS-FS'
                CelltypeInd = (psth_mat(i_prob).unit_fsUnits | psth_mat(i_prob).unit_rsUnits);
            case 'All'
                CelltypeInd = logical(ones(length(psth_mat(i_prob).unit_rsUnits), 1));
        end

        % Apply CCF location filter
        ind_ccf_filter = ismember(psth_mat(i_prob).unit_ccf_location, area_list.(current_area));
        CurrCellInd = (CelltypeInd & ind_ccf_filter);

        % Skip sessions with insufficient cells
        if sum(CurrCellInd) < 5

            coding_direction_matrix.(current_area)(session_counter).lickproj = NaN;
            coding_direction_matrix.(current_area)(session_counter).Contextproj = NaN;
            coding_direction_matrix.(current_area)(session_counter).Stimproj = NaN;
            coding_direction_matrix.(current_area)(session_counter).index.Quiet = NaN;
            coding_direction_matrix.(current_area)(session_counter).index.lick = NaN;
            coding_direction_matrix.(current_area)(session_counter).index.trial = NaN;
            coding_direction_matrix.(current_area)(session_counter).index.stim = NaN;
            coding_direction_matrix.(current_area)(session_counter).index.completed_trial = NaN;
            session_counter = session_counter + 1;

            continue
        end

        %% Extract current session data
        Currsig = psth_mat(i_prob).spike_counts;
        Currsig_CurrCellInd = Currsig(:, :, CurrCellInd);

        %% Evaluate classification expressions
        eval(expr1);
        eval(expr2);
        eval(expr3);
        eval(expr4);
        eval(expr5);

        % Apply quiet trial and completion filters
        Ind.Class1 = Ind.Class1 & Qind & completed_trial_ind;
        Ind.Class2 = Ind.Class2 & Qind & completed_trial_ind;
        Ind.Class3 = Ind.Class3 & Qind & completed_trial_ind;
        Ind.Class4 = Ind.Class4 & Qind & completed_trial_ind;
        Ind.Class5 = Ind.Class5 & Qind & completed_trial_ind;

        % Get trial indices for each class
        id1 = find(Ind.Class1);
        id2 = find(Ind.Class2);
        id3 = find(Ind.Class3);
        id4 = find(Ind.Class4);
        id5 = find(Ind.Class5);

        %% Perform cross-validation split (70% training, 30% testing)
        cv = cvpartition(size(id1, 1), 'HoldOut', 0.7); idx = cv.test; id1Train = id1(~idx, :); id1Test = id1(idx, :);
        cv = cvpartition(size(id2, 1), 'HoldOut', 0.7); idx = cv.test; id2Train = id2(~idx, :); id2Test = id2(idx, :);
        cv = cvpartition(size(id3, 1), 'HoldOut', 0.7); idx = cv.test; id3Train = id3(~idx, :); id3Test = id3(idx, :);
        cv = cvpartition(size(id4, 1), 'HoldOut', 0.7); idx = cv.test; id4Train = id4(~idx, :); id4Test = id4(idx, :);
        cv = cvpartition(size(id5, 1), 'HoldOut', 0.7); idx = cv.test; id5Train = id5(~idx, :); id5Test = id5(idx, :);

        %% Calculate coding directions for each time bin
        % Context coding direction
        CDcontext = [];
        for ind_bin = 1:size(Currsig_CurrCellInd, 1)
            X1 = squeeze(Currsig_CurrCellInd(ind_bin, id1Train, :));
            X2 = squeeze(Currsig_CurrCellInd(ind_bin, id2Train, :));
            CDcontext(ind_bin, :) = (mean(X1) - mean(X2));
        end

        % Lick coding direction
        CDlick = [];
        for ind_bin = 1:size(Currsig_CurrCellInd, 1)
            X4 = squeeze(Currsig_CurrCellInd(ind_bin, id4Train, :));
            X5 = squeeze(Currsig_CurrCellInd(ind_bin, id5Train, :));
            CDlick(ind_bin, :) = (mean(X4) - mean(X5));
        end

        %% Extract coding directions for specific time windows
        % Context coding direction (0.8-1.0s)
        [~, b] = min(abs(params.windowCenters - params.Win_context(1))); WContextFirstBin = b;
        [~, b] = min(abs(params.windowCenters - params.Win_context(2))); WContextLasttBin = b;
        coding_direction_context = nanmean(CDcontext(WContextFirstBin:WContextLasttBin, :), 1);
        coding_direction_context = coding_direction_context ./ norm(coding_direction_context);
        
        % Lick coding direction (1.1-1.3s)
        [~, b] = min(abs(params.windowCenters - params.Win_lick(1))); WlickFirstBin = b;
        [~, b] = min(abs(params.windowCenters - params.Win_lick(2))); WlickLasttBin = b;
        coding_direction_lick = nanmean(CDlick(WlickFirstBin:WlickLasttBin, :), 1);
        coding_direction_lick = coding_direction_lick ./ norm(coding_direction_lick);
        
        % Stimulus coding direction (1.005-1.03s vs baseline -1.0-0s)
        X3 = squeeze(mean(Currsig_CurrCellInd(:, id3Train, :), 2));
        [~, b] = min(abs(params.windowCenters - params.Win_stim(1))); WStimFirstBin = b;
        [~, b] = min(abs(params.windowCenters - params.Win_stim(2))); WStimLasttBin = b;
        [~, b] = min(abs(params.windowCenters - params.Win_base(1))); WBaseFirstBin = b;
        [~, b] = min(abs(params.windowCenters - params.Win_base(2))); WBaseLasttBin = b;
        coding_direction_stim = nanmean(X3(WStimFirstBin:WStimLasttBin, :), 1) - nanmean(X3(WBaseFirstBin:WBaseLasttBin, :), 1);
        coding_direction_stim = coding_direction_stim ./ norm(coding_direction_stim);

        %% Orthogonalize coding directions using Gram-Schmidt process
        v = fn_gram_schmidt_process([coding_direction_context', coding_direction_stim', coding_direction_lick']);
        coding_direction_context = v(:, 1)';
        coding_direction_stim = v(:, 2)';
        coding_direction_lick = v(:, 3)';

        %% Project single trials onto coding directions
        % Context projection
        ProjContext = [];
        for itrial = 1:size(Currsig_CurrCellInd, 2)
            curr = squeeze(Currsig_CurrCellInd(:, itrial, :));
            ProjContext(:, itrial) = curr * coding_direction_context';
        end
        id_training_context = sort([id1Train; id2Train])';
        ProjContext(:, id_training_context) = nan;

        % Lick projection
        Projlick = [];
        for itrial = 1:size(Currsig_CurrCellInd, 2)
            curr = squeeze(Currsig_CurrCellInd(:, itrial, :));
            Projlick(:, itrial) = curr * coding_direction_lick';
        end
        id_training_lick = sort([id4Train; id5Train])';
        Projlick(:, id_training_lick) = nan;

        % Stimulus projection
        ProjStim = [];
        for itrial = 1:size(Currsig_CurrCellInd, 2)
            curr = squeeze(Currsig_CurrCellInd(:, itrial, :));
            ProjStim(:, itrial) = curr * coding_direction_stim';
        end
        id_training_stim = sort([id3Train])';
        ProjStim(:, id_training_stim) = nan;

        %% Store results for current session
        coding_direction_matrix.(current_area)(session_counter).lickproj = [Projlick];
        coding_direction_matrix.(current_area)(session_counter).Contextproj = [ProjContext];
        coding_direction_matrix.(current_area)(session_counter).Stimproj = [ProjStim];
        coding_direction_matrix.(current_area)(session_counter).index.Quiet = [Qind];
        coding_direction_matrix.(current_area)(session_counter).index.lick = [lick];
        coding_direction_matrix.(current_area)(session_counter).index.trial = [trial];
        coding_direction_matrix.(current_area)(session_counter).index.stim = [stim];
        coding_direction_matrix.(current_area)(session_counter).index.completed_trial = [completed_trial_ind];
        
        session_counter = session_counter + 1;
    end
end

%% Prepare output variables
windowCenters = params.windowCenters;

%% Save results

directory=[CurrentDir filesep 'processed_data' filesep];
save([directory 'Coding_direction_5ms.mat'], "coding_direction_matrix", "windowCenters", "params");

