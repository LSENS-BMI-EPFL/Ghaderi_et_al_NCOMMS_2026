%% =========================================================================
% Movement_subspace.m
% =========================================================================
% 
% This script decomposes neural activity into movement-related (potent) and
% movement-independent (null) subspaces for the manuscript "Contextual gating 
% of whisker-evoked responses by frontal cortex supports flexible decision making" 
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script applies neural manifold decomposition to separate
% neural activity into subspaces that are related to movement (potent) and
% those that are independent of movement (null). It uses whisker speed as
% the movement signal and applies a threshold-based movement detection.
%
% Dependencies: 
%   - psth_10ms.mat (contains trial data)
%   - area_list.mat (contains brain area information)
%   - pg_decompose.m (for neural manifold decomposition)
%
% Input: Processed PSTH data
% Output: Movement subspace data saved to Movement_subspace.mat
% =========================================================================

%% Initialize workspace and load data
clear all
close all
clc

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'data_helpers' filesep 'area_list.mat'])
load([directory filesep 'processed_data' filesep 'psth_10ms.mat'])
rng(0)

%% Force MATLAB to be in this file's location
[filepath, ~, ~] = fileparts(mfilename('fullpath'));
cd(filepath);

%% Optional: Change figure name (set to 1 to enable)
change_name = 0;
newname = 'Figure3_4_1';
fullname = mfilename('fullpath');
inds = regexp(fullname, '\', 'all');
name = fullname(inds(end) + 1:end);

if change_name
    movefile([name '.m'], [newname '.m']);
end

%% Define analysis parameters
% Trial selection and behavioral parameters
params.QuietState = 'All_trials';   % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trials'
params.BaselineSubtraction = 0;
params.completion_state = 'completed_trials';   % Options: 'early_licks', 'completed_trials'
params.TrialType = [1, 3];   % 1: gotone/whisker, 3: nogotone/whisker
params.LickState = [1, 0];  % lick 1: lick, 0: nolick
params.CellType = 'All';           % Options: 'RS', 'FS', 'RS_FS', 'All'

% Brain regions to analyze
regionlist = {'A1', 'wS1', 'wS2', 'wM2', 'ALM'};

% Time window parameters
t_start = -1;  % Start time (seconds)
t_end = 2;     % End time (seconds)
bin_width = 0.01;  % 10ms bins
XTickLabel = {'-1'; '0'; '1'; '2'};
xtick = [-1; 0; 1; 2];

% Movement signals to analyze
movements_signals = {'whisker_speed', 'snout_angle', 'piezo_lick_trace', 'jaw_movement', 'tongue_movement'};
movements_signals_tag = {'Whisker speed (pixel/s)', 'Snout angle (degree)', 'Piezo lick (mv)', 'Jaw (pixel)', 'Tongue (pixel)'};

%% Main analysis loop across brain regions
for iarea = 1:length(regionlist)
    CurrentArea = cell2mat(regionlist(iarea));
    probe_list = find(strcmp(CurrentArea, [psth_mat.probe_location]));

    session_counter = 1;
    
    for ind_probe = probe_list
        % Extract trial information
        Trial = psth_mat(ind_probe).trial_type;
        Lick = psth_mat(ind_probe).lick_flag;

        %% Determine trial completion status
        switch params.completion_state
            case 'completed_trials'
                completion_state = ~psth_mat(ind_probe).early_lick;
            case 'early_licks'
                early_licks_all = psth_mat(ind_probe).early_lick;
                lick_time = 0 < (psth_mat(ind_probe).lick_time - psth_mat(ind_probe).start_time);
                completion_state = lick_time & early_licks_all;
        end

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
        
        %% Apply CCF location filter
        ind_ccf_filter = ismember(psth_mat(ind_probe).unit_ccf_location, area_list.(CurrentArea));
        CurrCellInd = (CelltypeInd & ind_ccf_filter);
        
        % Skip sessions with insufficient cells
        if sum(CurrCellInd) <= 20
            continue
        end

        %% Extract neural data for current session
        CurrSp = psth_mat(ind_probe).spike_counts;
        CurrSp_CurrCellInd = CurrSp(:, :, CurrCellInd);

        %% Prepare data for decomposition
        myexampleData.seq = CurrSp_CurrCellInd;
        myexampleData.time = psth_mat(ind_probe).trial_timestamps';

        %% Calculate movement threshold and mask
        % Use whisker speed as the primary movement signal
        CurrMovement = psth_mat(ind_probe).whisker_speed;
        
        % Calculate baseline statistics (first 99 time bins)
        baseline_mean = nanmean(nanmean(CurrMovement(1:99, :), 1));
        baseline_std = nanmean(nanstd(CurrMovement(1:99, :), 1));
        
        % Set threshold for movement detection (baseline + 1 std)
        thereshold = baseline_mean + 1 * baseline_std;
        moveMask = thereshold < CurrMovement;
        
        % Store movement data
        myexampleData.moveMask = moveMask;
        myexampleData.motionEnergy = CurrMovement;

        %% Perform neural manifold decomposition
        [rez] = pg_decompose(myexampleData);

        %% Extract potent and null subspaces
        Curr_potent = rez.proj.potent;
        Curr_null = rez.proj.null;

        %% Store results for current probe
        mov_potent_null(ind_probe).potent = [Curr_potent];
        mov_potent_null(ind_probe).null = [Curr_null];
        mov_potent_null(ind_probe).movement_mask = [moveMask];
        
        session_counter = session_counter + 1;
    end % End of session loop
end % End of area loop

%% Save movement subspace data

directory=[CurrentDir filesep 'processed_data' filesep];
save([directory 'Movement_subspace.mat'], "mov_potent_null", '-v7.3');


%% Optional: Export figure (commented out in original)
% fullname = mfilename('fullpath');
% inds = regexp(fullname, '\', 'all');
% name = fullname(inds(end) + 1:end);
% export_fig([name], '-tiff', '-painters');





