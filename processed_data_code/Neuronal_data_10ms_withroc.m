%% =========================================================================
% Neuronal_data_10ms_withroc.m
% =========================================================================
% 
% This script processes neural spike data and creates a comprehensive dataset
% for clustering analysis with 10ms temporal resolution, including ROC analysis
% for the manuscript "Contextual gating of whisker-evoked responses by frontal 
% cortex supports flexible decision making" (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script processes raw PSTH data to create a neural activity
% matrix suitable for clustering analysis with 10ms resolution. It filters trials 
% based on behavioral conditions, applies baseline subtraction, performs ROC 
% analysis for selectivity assessment, and normalizes the data. The output includes 
% neural activity matrices along with comprehensive metadata (brain areas, cell types, 
% depths, layers, CCF coordinates) and ROC analysis results for downstream analysis.
%
% Dependencies: 
%   - Area_list.mat (contains brain area information)
%   - selectivity_index_calculation.m (for ROC analysis)
%
% Input: psth_10ms (psth_mat structure)
% Output: concatenated neuronal data for 5 trial type neural data with ROC analysis saved to Neuronal_data_10ms_withroc.mat
% =========================================================================


%% Initialize workspace and load required packages

clear all
close all
clc

% Load required data
CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'psth_10ms.mat'])
load([directory filesep 'data_helpers' filesep 'Area_list.mat'])

rng(0)

%% Define analysis parameters
% Trial selection and behavioral parameters
params.QuietState = 'Quiet_(jaw & whisker)';   % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trials'
params.normalization = 1;                      % Enable normalization (0: disabled, 1: enabled)
params.completion_state = 'completed_trials';  % Options: 'early_licks', 'completed_trials'
params.TrialType = [1, 2, 3, 4, 5];            % 1: gotone/whisker, 2: gotone/nowhisker, 3: nogotone/whisker, 4: nogotone/nowhisker, 5: notone/whisker
params.LickState = [1, 0, 0, 0, 0];            % lick 1: lick, 0: nolick
params.CellType = 'All';                        % Options: 'RS', 'FS', 'RS_FS', 'All'
params.regionlist = {'A1', 'wM2', 'wS1', 'ALM', 'wS2'};  % Brain regions to analyze

% Data quality filters
params.min_cells_per_session = 5;              % Minimum cells required per session
params.min_trials_per_condition = 3;           % Minimum trials required per condition

% Time window parameters
t_start = -1;  % Start time (seconds)
t_end = 2;     % End time (seconds)
bin_width = 0.01;  % 10ms bins
XTickLabel = {'-1'; '0'; '1'; '2'};
xtick = [-1; 0; 1; 2];

% ROC analysis parameters
windows_list = {[181:200]};  % 200ms pre-whisker window for ROC analysis
params.roc_method = 'permut';  % ROC calculation method
params.roc_permutations = 200; % Number of permutations for ROC analysis
params.roc_iterations = 200;   % Number of iterations for ROC analysis

% Movement signals and analysis parameters
movements_signals = {'whisker_speed', 'snout_angle', 'piezo_lick_trace', 'jaw_movement', 'tongue_movement'};
movements_signals_tag = {'Whisker', 'Snout', 'Piezo lick', 'Jaw', 'Tongue'};
params.movement_baselineSubtraction = 1;  % Enable baseline subtraction for movement signals
params.movement_normalization = 0;       % Disable normalization for movement signals

% Color scheme for visualization
colorcodes = [0 0 1; 0 .5 1; 1 0 0; 1 .5 0; 0 0 0;];
params.colormap = {'#0008FF'; '#228B22'; '#00C3FF'; '#FF0000'; '#FF7F00'; '#000000'; '#00C3FF'; '#FF7F00'; '#FF7F00'; '#808080'; '#6B3686'; '#74B99A'; '#A020F0'; '#FFD700'};
params.colortype = {'wS1'; 'wS2'; 'CR2'; 'ALM'; 'CR4'; 'wM2'; 'FA2'; 'FA3'; 'FA4'; 'FA5'; 'Lick'; 'NoLick'; 'A1'; 'tjM1'};
params.Map = horzcat(params.colortype, params.colormap);

% Data processing parameters
resolution_change = 0;  % Maintain 10ms resolution (no temporal smoothing)

%% Initialize output variables
Area = [];                    % Brain area labels for each neuron
Type = [];                    % Cell type labels (RS, FS, etc.)
Layer = [];                   % Cortical layer information
Depth = [];                   % Recording depth information
CCF_xyz = [];                 % CCF coordinate system positions
CCF_location = [];           % CCF location labels
Unit_ids = [];                % Unique unit identifiers
Neurons_activity_condition_area = [];  % Main neural activity matrix
Discrimination_index = [];    % ROC discrimination indices
P_value = [];                 % ROC p-values

%% Main processing loop across brain regions
fprintf('Processing neural data with ROC analysis from %d brain regions...\n', length(params.regionlist));

for iarea = 1:length(params.regionlist)
    CurrentArea = cell2mat(params.regionlist(iarea));
    fprintf('  Processing area: %s\n', CurrentArea);
    
    % Find all probes/sessions in current brain area
    iprb_list = find(strcmp(CurrentArea, [psth_mat.probe_location]));
    fprintf('    Found %d sessions in %s\n', length(iprb_list), CurrentArea);
    
    Neurons_activity_condition = [];
    sp_cnt_condition = cell(110, 5);  % Pre-allocate cell array for spike counts
    %% Process each trial condition
    for i_cond = 1:length(params.TrialType)
        fprintf('    Processing condition %d: Trial type %d, Lick state %d\n', i_cond, params.TrialType(i_cond), params.LickState(i_cond));
        
        % Initialize concatenation variables for current condition
        Concatsig = [];
        Concatcelltype = {};
        ConcatDepth = [];
        ConcatLayer = {};
        ConcatCCF_xyz = [];
        ConcatCCF_location = {};
        ConcatUnit_ids = [];
        
        %% Process each session/probe in current brain area
        for i_prb = iprb_list
            % Extract trial information
            Trial = psth_mat(i_prb).trial_type;
            Lick = psth_mat(i_prb).lick_flag;
            
            %% Define trial conditions
            IndTrialType = Trial == params.TrialType(i_cond);
            IndLickstate = Lick == params.LickState(i_cond);
            
            %% Determine trial completion status
            switch params.completion_state
                case 'completed_trials'
                    completion_state = ~psth_mat(i_prb).early_lick;
                case 'early_licks'
                    early_licks_all = psth_mat(i_prb).early_lick;
                    lick_time = 0 < (psth_mat(i_prb).lick_time - psth_mat(i_prb).start_time);
                    completion_state = lick_time & early_licks_all;
            end
            
            %% Determine quiet trial status
            switch params.QuietState
                case 'Quiet_(whisker_speed)'
                    Qind = psth_mat(i_prb).quiet_trial_whisker_speed;
                case 'Quiet_(jaw_movement)'
                    Qind = psth_mat(i_prb).quiet_trial_jaw_movement;
                case 'Quiet_(jaw & whisker)'
                    Qind = psth_mat(i_prb).quiet_trial_jaw_movement & psth_mat(i_prb).quiet_trial_whisker_speed;
                case 'Non_quiet'
                    Qind = ~(psth_mat(i_prb).quiet_trial_jaw_movement & psth_mat(i_prb).quiet_trial_whisker_speed);
                case 'All_trials'
                    Qind = logical(ones(length(IndLickstate), 1));
            end
            
            % Combine all trial filters
            CurrTrialInd = [Qind & completion_state & IndLickstate & IndTrialType];
            
            %% Determine cell type filter
            switch params.CellType
                case 'RS'
                    CelltypeInd = psth_mat(i_prb).unit_rsUnits;
                case 'FS'
                    CelltypeInd = psth_mat(i_prb).unit_fsUnits;
                case 'RS_FS'
                    CelltypeInd = (psth_mat(i_prb).unit_fsUnits | psth_mat(i_prb).unit_rsUnits);
                case 'All'
                    CelltypeInd = logical(ones(length(psth_mat(i_prb).unit_rsUnits), 1));
            end

            %% Apply CCF location filter
            ind_ccf_filter = ismember(psth_mat(i_prb).unit_ccf_location, area_list.(CurrentArea));
            CurrCellInd = (CelltypeInd & ind_ccf_filter);
            
            %% Extract cell metadata
            % Create cell type labels
            Typemat = [];
            Typemat(find(psth_mat(i_prb).unit_rsUnits)) = 1;  % RS cells
            Typemat(find(psth_mat(i_prb).unit_fsUnits)) = 2;  % FS cells
            Typemat(find(~psth_mat(i_prb).unit_fsUnits & ~psth_mat(i_prb).unit_rsUnits)) = 3;  % Non-classified cells
            
            celltype = repmat({''}, length(CurrCellInd), 1);
            celltype(Typemat == 1) = {'RS'};
            celltype(Typemat == 2) = {'FS'};
            celltype(Typemat == 3) = {'Nan'};
            currentcelltype = celltype(CurrCellInd);
            
            % Extract anatomical information
            currentDepth = psth_mat(i_prb).unit_ccf_depth(CurrCellInd);
            currentLayer = psth_mat(i_prb).unit_allenccf_area_layer(CurrCellInd);
            currentCCF_xyz = psth_mat(i_prb).unit_ccf_xyz(CurrCellInd);
            currentCCF_location = psth_mat(i_prb).unit_ccf_location(CurrCellInd);

            %% Extract spike data and unit IDs
            CurrSp = psth_mat(i_prb).spike_counts;
            curr_unit_ids = psth_mat(i_prb).GlobalclusterID(CurrCellInd);

            %% Apply temporal smoothing (if enabled)
            if resolution_change
                fprintf('      Applying temporal smoothing (10ms -> 100ms)...\n');
                A = double([]);
                for i_trial = 1:size(CurrSp, 2)
                    for i_unit = 1:size(CurrSp, 3)
                        A(:, i_trial, i_unit) = movsum_pg(CurrSp(:, i_trial, i_unit), 10, 10);
                    end
                end
                WindowCenters = -.9:.1:2;  % 100ms bins from -0.9s to 2s
                CurrSp = A;
            else
                WindowCenters = psth_mat(i_prb).trial_timestamps;  % Maintain 10ms resolution
            end

            %% Extract trials for current condition and average across trials
            CurrSp_CurrTrialInd = squeeze(nanmean(CurrSp(:, CurrTrialInd, :), 2));
            CurrSp_CurrTrialInd_CurrCellInd = CurrSp_CurrTrialInd(:, CurrCellInd);

            % Skip session if insufficient cells meet criteria
            if isempty(CurrSp_CurrTrialInd_CurrCellInd) || sum(CurrCellInd) < params.min_cells_per_session
                fprintf('      Insufficient cells (%d < %d), skipping session...\n', sum(CurrCellInd), params.min_cells_per_session);
                continue
            end
            
            % Check trial counts for current condition
            num_trials = sum(CurrTrialInd);
            if num_trials < params.min_trials_per_condition
                fprintf('      Insufficient trials (%d < %d), skipping session...\n', num_trials, params.min_trials_per_condition);
                continue
            end

            %% Apply baseline subtraction
            fprintf('      Applying baseline subtraction...\n');
            t1 = -1;  % Baseline start time
            t2 = 0;   % Baseline end time
            [~, b] = min(abs(WindowCenters - t1));
            baselineFirstBin = b;
            [~, b] = min(abs(WindowCenters - t2));
            baselineLastBin = b;
            
            % Calculate baseline mean for each cell
            baseline_mean = repmat(mean(CurrSp_CurrTrialInd_CurrCellInd(baselineFirstBin:baselineLastBin, :), 1), ...
                                 size(CurrSp_CurrTrialInd_CurrCellInd, 1), 1);
            CurrSp_CurrTrialInd_CurrCellInd = (CurrSp_CurrTrialInd_CurrCellInd - baseline_mean);
            
            
            %% Concatenate data from current session
            Concatsig = [Concatsig, CurrSp_CurrTrialInd_CurrCellInd];
            Concatcelltype = [Concatcelltype; currentcelltype];
            ConcatDepth = [ConcatDepth; currentDepth];
            ConcatLayer = [ConcatLayer; currentLayer];
            ConcatCCF_xyz = [ConcatCCF_xyz; currentCCF_xyz];
            ConcatCCF_location = [ConcatCCF_location; currentCCF_location];
            ConcatUnit_ids = [ConcatUnit_ids; curr_unit_ids'];
            
            %% Prepare data for ROC analysis
            % Extract spike counts for ROC analysis (all trials, not averaged)
            roc_curr_sp_trials = CurrSp(:, CurrTrialInd, :);
            roc_curr_sp_trials_cells = roc_curr_sp_trials(:, :, CurrCellInd);
            WindowCenters = psth_mat(i_prb).trial_timestamps;  % Use original timestamps for ROC
            sp_cnt_condition{i_prb, i_cond} = roc_curr_sp_trials_cells;


        end % End of session loop
        
        %% Concatenate data across conditions for current brain area
        Neurons_activity_condition = [Neurons_activity_condition, Concatsig'];
        fprintf('    Condition %d: %d neurons processed\n', i_cond, size(Concatsig, 2));
        
    end % End of condition loop

    %% Perform ROC analysis for selectivity assessment
    fprintf('  Performing ROC analysis for selectivity assessment...\n');
    cluster = [];
    discrimination_index = [];
    p_value = [];
    diff_fr = [];
    
    for i_prb = iprb_list
        cond1 = sp_cnt_condition{i_prb, 1};  % Condition 1: gotone/whisker
        cond2 = sp_cnt_condition{i_prb, 3};  % Condition 3: nogotone/whisker
        
        if isempty(cond1) || isempty(cond2)
            fprintf('    Session %d: Insufficient data for ROC analysis, skipping...\n', i_prb);
            continue
        end
        
        fprintf('    Session %d: Analyzing %d cells for ROC...\n', i_prb, size(cond2, 3));
        
        for ind_cells = 1:size(cond2, 3)
            % Define time window for ROC analysis (pre-whisker period)
            bin_range = cell2mat(windows_list);
            
            % Extract spike counts for analysis window
            sp_cnt_bin_cell = [sum(cond1(bin_range, :, ind_cells), 1), sum(cond2(bin_range, :, ind_cells), 1)];
            label = [ones(1, size(cond1, 2)), 2 * ones(1, size(cond2, 2))];
            
            % Calculate selectivity index using permutation test
            [di, p, x, y, auc] = selectivity_index_calculation(sp_cnt_bin_cell', label', ...
                                                              params.roc_method, params.roc_permutations, params.roc_iterations);
            
            % Store ROC results
            p_value = [p_value; p];
            discrimination_index = [discrimination_index; di];
            
            % Calculate firing rate difference
            diff_fr = [diff_fr; [mean(mean(cond1(bin_range, :, ind_cells) / bin_width, 1)) - ...
                                 mean(mean(cond2(bin_range, :, ind_cells) / bin_width, 1))]];
        end
    end




    Neurons_activity_condition_area=[Neurons_activity_condition_area;Neurons_activity_condition];
    Discrimination_index=[Discrimination_index;discrimination_index];
    P_value=[P_value;p_value];

    Area=[Area;repmat({CurrentArea},size(Neurons_activity_condition,1),1)];
    Type=[Type;Concatcelltype];
    Depth=[Depth;ConcatDepth];
    Layer=[Layer;ConcatLayer];
    CCF_xyz=[CCF_xyz;ConcatCCF_xyz];
    CCF_location=[CCF_location;ConcatCCF_location];
    Unit_ids=[Unit_ids;ConcatUnit_ids];
    



end % End of brain area loop

%% Data normalization and final processing
fprintf('\nApplying data normalization...\n');

% Store unnormalized data for reference
Neurons_activity_noNormalization = Neurons_activity_condition_area;

% Calculate normalization factors
max_mat = max(Neurons_activity_condition_area, [], 2);
min_mat = min(Neurons_activity_condition_area, [], 2);
norm_mat = repmat(max_mat - min_mat, 1, size(Neurons_activity_condition_area, 2));

% Apply normalization (avoid division by zero)
norm_mat(norm_mat == 0) = 1;  % Set zero ranges to 1 to avoid division by zero
Neurons_activity_condition_area = Neurons_activity_condition_area ./ norm_mat;

% Create comprehensive data structure
N_data.data = Neurons_activity_condition_area;
N_data.Area = Area;
N_data.celltype = Type;
N_data.Depth = Depth;
N_data.Layer = Layer;
N_data.CCF_xyz = CCF_xyz;
N_data.CCF_location = CCF_location;
N_data.Unit_ids = Unit_ids;

% Create cluster counter for downstream analysis
clustercounter = [1:length(Area)]';
N_data.clustercounter = clustercounter;

%% Display processing summary
fprintf('\n=== PROCESSING SUMMARY ===\n');
fprintf('Total neurons processed: %d\n', length(Area));
fprintf('Brain areas: %s\n', strjoin(params.regionlist, ', '));
fprintf('Trial conditions: %d\n', length(params.TrialType));
fprintf('Cell types: %s\n', params.CellType);
fprintf('Quiet state filter: %s\n', params.QuietState);
fprintf('Completion state: %s\n', params.completion_state);
fprintf('Temporal resolution: 10ms\n');
fprintf('Data matrix size: %d neurons × %d time bins\n', size(Neurons_activity_condition_area, 1), size(Neurons_activity_condition_area, 2));
fprintf('ROC analyses performed: %d\n', length(Discrimination_index));

% Display area-specific statistics
fprintf('\nArea-specific statistics:\n');
for i = 1:length(params.regionlist)
    area_name = params.regionlist{i};
    area_neurons = sum(strcmp(Area, area_name));
    fprintf('  %s: %d neurons\n', area_name, area_neurons);
end

% Display cell type statistics
fprintf('\nCell type distribution:\n');
unique_types = unique(Type);
for i = 1:length(unique_types)
    type_count = sum(strcmp(Type, unique_types{i}));
    fprintf('  %s: %d neurons (%.1f%%)\n', unique_types{i}, type_count, 100*type_count/length(Type));
end

%% Prepare output variables
windowCenters = WindowCenters;  % Time window centers for reference

%% Save processed data

directory=[CurrentDir filesep 'processed_data' filesep];
save([directory 'Neuronal_data_10ms_withroc.mat'], "Neurons_activity_noNormalization", "Neurons_activity_condition_area", ...
     "P_value", "Discrimination_index", "Area", "Type", "Depth", "Layer", ...
     "CCF_xyz", "CCF_location", "Unit_ids", "clustercounter", ...
     "windowCenters", "params", "N_data");


