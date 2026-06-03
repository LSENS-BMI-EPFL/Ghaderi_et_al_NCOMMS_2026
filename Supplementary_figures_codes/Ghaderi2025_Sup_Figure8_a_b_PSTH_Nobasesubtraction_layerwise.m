
%% =========================================================================
% Neuronal_data_10ms.m
% =========================================================================
% 
% This script processes neural spike data and creates a comprehensive dataset
% for clustering analysis with 100ms temporal resolution for the manuscript 
% "Contextual gating of whisker-evoked responses by frontal cortex supports 
% flexible decision making" (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script processes raw PSTH data to create a neural activity
% matrix suitable for clustering analysis. It filters trials based on behavioral
% conditions, applies baseline subtraction, performs temporal smoothing with
% 100ms resolution, and normalizes the data. The output includes neural activity
% matrices along with comprehensive metadata (brain areas, cell types, depths,
% layers, CCF coordinates) for downstream clustering analysis.
%
% Dependencies: 
%   - Area_list.mat (contains brain area information)
%   - movsum_pg.m (custom moving sum function)
%
% Input: psth_10ms (psth_mat structure)
% Output: concatenated neuronal data for 5 trial type neural data saved to Neuronal_data_100ms.mat
% =========================================================================

%% Initialize workspace and load data
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
load([directory filesep 'data_helpers' filesep 'Area_list.mat'])

%% Define analysis parameters
% Trial selection and behavioral parameters
params.QuietState = 'Quiet_(whisker_speed)';   % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trials'
params.normalization = 0;                     % Enable normalization (0: disabled, 1: enabled)
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

% Movement signals and analysis parameters
movements_signals = {'whisker_speed', 'snout_angle', 'piezo_lick_trace', 'jaw_movement', 'tongue_movement'};
movements_signals_tag = {'Whisker', 'Snout', 'Piezo lick', 'Jaw', 'Tongue'};
params.movement_baselineSubtraction = 0;  % Enable baseline subtraction for movement signals
params.movement_normalization = 0;       % Disable normalization for movement signals

% Color scheme for visualization
colorcodes = [0 0 1; 0 .5 1; 1 0 0; 1 .5 0; 0 0 0;];
params.colormap = {'#0008FF'; '#228B22'; '#00C3FF'; '#FF0000'; '#FF7F00'; '#000000'; '#00C3FF'; '#FF7F00'; '#FF7F00'; '#808080'; '#6B3686'; '#74B99A'; '#A020F0'; '#FFD700'};
params.colortype = {'wS1'; 'wS2'; 'CR2'; 'ALM'; 'CR4'; 'wM2'; 'FA2'; 'FA3'; 'FA4'; 'FA5'; 'Lick'; 'NoLick'; 'A1'; 'tjM1'};
params.Map = horzcat(params.colortype, params.colormap);

% Data processing parameters
resolution_change = 0;  % Enable temporal smoothing to 100ms resolution

%% Initialize output variables
Area = [];                    % Brain area labels for each neuron
Type = [];                    % Cell type labels (RS, FS, etc.)
Layer = [];                   % Cortical layer information
Depth = [];                   % Recording depth information
CCF_xyz = [];                 % CCF coordinate system positions
CCF_location = [];           % CCF location labels
Unit_ids = [];                % Unique unit identifiers
Neurons_activity_condition_area = [];  % Main neural activity matrix
Neurons_activity_condition_area_noNorm=[];
%% Main processing loop across brain regions
for iarea = 1:length(params.regionlist)
    CurrentArea = cell2mat(params.regionlist(iarea));
    fprintf('  Processing area: %s\n', CurrentArea);
    
    % Find all probes/sessions in current brain area
    iprb_list = find(strcmp(CurrentArea, [psth_mat.probe_location]));
    fprintf('    Found %d sessions in %s\n', length(iprb_list), CurrentArea);
    
    Neurons_activity_condition = [];
    Neurons_activity_condition_noNorm=[]
    %% Process each trial condition
    for i_cond = 1:length(params.TrialType)
        % Initialize concatenation variables for current condition
        Concatsig = [];
        Concatsig_noNorm=[];
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

            %% Apply temporal smoothing (10ms -> 100ms resolution)
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
                WindowCenters = psth_mat(i_prb).trial_timestamps;
            end

            %% Extract trials for current condition and average across trials
            CurrSp_CurrTrialInd = squeeze(nanmean(CurrSp(:, CurrTrialInd, :), 2));
            CurrSp_CurrTrialInd_CurrCellInd = CurrSp_CurrTrialInd(:, CurrCellInd);

            % Skip session if insufficient cells meet criteria
            if isempty(CurrSp_CurrTrialInd_CurrCellInd) || sum(CurrCellInd) < params.min_cells_per_session
                fprintf('      Insufficient cells (%d < %d), skipping session...\n', sum(CurrCellInd), params.min_cells_per_session);
                continue
            end 
            num_trials = sum(CurrTrialInd);

            %% Apply baseline subtraction
%             fprintf('      Applying baseline subtraction...\n');
%             t1 = -1;  % Baseline start time
%             t2 = 0;   % Baseline end time
%             [~, b] = min(abs(WindowCenters - t1));
%             baselineFirstBin = b;
%             [~, b] = min(abs(WindowCenters - t2));
%             baselineLastBin = b;
%             
%             % Calculate baseline mean for each cell
%             baseline_mean = repmat(mean(CurrSp_CurrTrialInd_CurrCellInd(baselineFirstBin:baselineLastBin, :), 1), ...
%                                  size(CurrSp_CurrTrialInd_CurrCellInd, 1), 1);
% 
%             CurrSp_CurrTrialInd_CurrCellInd = (CurrSp_CurrTrialInd_CurrCellInd);


        %% Concatenate data from current session
        Concatsig = [Concatsig, CurrSp_CurrTrialInd_CurrCellInd];

        Concatcelltype = [Concatcelltype; currentcelltype];
        ConcatDepth = [ConcatDepth; currentDepth];
        ConcatLayer = [ConcatLayer; currentLayer];
        ConcatCCF_xyz = [ConcatCCF_xyz; currentCCF_xyz];
        ConcatCCF_location = [ConcatCCF_location; currentCCF_location];
        ConcatUnit_ids = [ConcatUnit_ids; curr_unit_ids'];
        
        % Store session metadata for quality control
        session_info.(CurrentArea)(i_prb).num_cells = sum(CurrCellInd);
        session_info.(CurrentArea)(i_prb).num_trials = num_trials;
        session_info.(CurrentArea)(i_prb).session_id = psth_mat(i_prb).session_id;
        session_info.(CurrentArea)(i_prb).probe_location = psth_mat(i_prb).probe_location;

        end % End of session loop

        %% Concatenate data across conditions for current brain area
        Neurons_activity_condition = [Neurons_activity_condition, Concatsig'];

        fprintf('    Condition %d: %d neurons processed\n', i_cond, size(Concatsig, 2));
        
    end % End of condition loop
    
    %% Store data for current brain area
    Neurons_activity_condition_area = [Neurons_activity_condition_area; Neurons_activity_condition];
    Area = [Area; repmat({CurrentArea}, size(Neurons_activity_condition, 1), 1)];
    Type = [Type; Concatcelltype];
    Depth = [Depth; ConcatDepth];
    Layer = [Layer; ConcatLayer];
    CCF_xyz = [CCF_xyz; ConcatCCF_xyz];
    CCF_location = [CCF_location; ConcatCCF_location];
    Unit_ids = [Unit_ids; ConcatUnit_ids];
    
    fprintf('  Area %s completed: %d total neurons\n', CurrentArea, size(Neurons_activity_condition, 1));

end % End of brain area loop
clustercounter = [1:length(Area)]';


%% Prepare output variables
windowCenters = WindowCenters;  % Time window centers for reference

% save('../processed_data/Neuronal_data_10ms.mat', ...
%     "Neurons_activity_condition_area", "CCF_location", "CCF_xyz", ...
%     "Depth", "Layer", "clustercounter", "Area", "Type", ...
%     "windowCenters", "params", "session_info");

%%
fprintf('\nGenerating depth-resolved PSTH figure (Figure 3D style)...\n');

% Basic definitions
psth_mat_all = Neurons_activity_condition_area;   % neurons x all_time_bins

[nNeurons, nTimeBinsTotal] = size(psth_mat_all);

nConds   = numel(params.TrialType);               % should be 5
segLen   = nTimeBinsTotal / nConds;               % number of bins per condition
bin_sz   = 0.01;                                  % 10 ms
t_segment = (0:segLen-1) * bin_sz;                % 0 .. 3 s (300 bins)

% Check segmentation
if mod(nTimeBinsTotal, nConds) ~= 0
    warning('Total time bins (%d) not divisible by number of conditions (%d).', ...
            nTimeBinsTotal, nConds);
end

% Convert PSTH to Hz (same as in Python notebook: divide by bin size)
psth_hz = psth_mat_all / bin_sz;                  % neurons x time

% Depth, area and layer as convenient variables
depth_all   = Depth(:);                           % N x 1 numeric
area_all    = Area(:);                            % N x 1 cellstr
layer_raw   = Layer(:);                           % N x 1 cellstr

% Standardise layers into 'supragranular', 'granular', 'infragranular'
layer_class = classify_layers(layer_raw);

% Define trial condition labels (order must match your params.TrialType)
condition_labels = { ...
    'Go-tone whisker', ...
    'Go-tone', ...
    'Nogo-tone whisker', ...
    'Nogo-tone', ...
    'No-tone whisker'};

% Brain areas to show (order of rows)
unique_areas = {'A1','wS1','wS2','wM2','ALM'};

% Color limits for heatmaps (as in notebook)
cmin = 0;
cmax =  7;

% Layer colors for right-column PSTHs
layer_names  = {'supragranular','granular','infragranular'};
layer_colors = [ ...
    184 115  51;  ... % supragranular  ~ #B87333
      0 128 128;  ... % granular       ~ #008080
     75   0 130]  / 255; % infragranular ~ #4B0082

% -------------------------------------------------------------------------
% Create figure and layout
% -------------------------------------------------------------------------
fig = figure('Units','centimeters','Position',[0 0 20 25]);
tlo = tiledlayout(5,2,'TileSpacing','compact','Padding','compact');


% Loop over areas (rows)
for iRow = 1:numel(unique_areas)

    thisArea = unique_areas{iRow};
    neuron_idx = find(strcmp(area_all, thisArea));    % neurons in this area



    % ---------------------------------------------------------------------
    % LEFT COLUMN: condition-specific PSTHs (all neurons in this area)
    % ---------------------------------------------------------------------
    ax_left = nexttile(tlo, (iRow-1)*2 +1);
    plot_condition_psths(ax_left, psth_hz, neuron_idx, ...
                         bin_sz, nConds, windowCenters', ...
                         colorcodes, condition_labels, thisArea);
    ax_left.YLim=[0,16]
  
    % ---------------------------------------------------------------------
    % RIGHT COLUMN: layer-specific PSTHs (supra / gran / infra)
    % ---------------------------------------------------------------------
    ax_right = nexttile(tlo, (iRow)*2 );
    plot_layer_psths(ax_right, psth_hz, neuron_idx, layer_class, ...
                     bin_sz, nConds, windowCenters', ...
                     layer_names, layer_colors, thisArea);
    ax_right.YLim=[0,16]

end



%% =========================================================================
% Layer-specific statistics (1.8–2.0 s window)
% =========================================================================



area_all = Area(:);  % just rename for clarity

[layer_activity_results, statistical_results, summary_table, comparison_table] = ...
    compute_layer_stats_pg(psth_hz, area_all, layer_class, bin_sz);

%% Export figure
directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');
