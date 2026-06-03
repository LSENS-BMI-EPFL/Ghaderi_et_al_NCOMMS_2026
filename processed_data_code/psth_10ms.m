%% =========================================================================
% psth_10ms.m
% =========================================================================
% 
% This script processes NWB files to extract PSTH data with 10ms time bins
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making" 
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script loads NWB files, extracts behavioral and neural data,
% calculates PSTHs with 10ms bins, identifies quiet trials, and organizes data
% into a structured format for further analysis.
%
% Dependencies: 
%   - matnwb package (for reading NWB files)
%   - PSTHBehavior.m (for behavioral PSTH calculation)
%   - nwb_findQuietTrial.m (for quiet trial identification)
%   - trial_typeMaker.m (for trial type classification)
%   - PSTH_Simple.m (for spike PSTH calculation)
%
% Input: NWB files in ../data_electrophysiology/ directory
% Output: psth_10ms.mat containing processed PSTH data
% =========================================================================

%% Initialize workspace and load required packages

clear all
close all
clc

% Load the matnwb package for reading NWB files
% Note: Ensure matnwb is properly installed and in MATLAB path

%% Define data directory and parameters
% Directory containing NWB files

CurrentDir=pwd;
directory=[CurrentDir filesep 'data_electrophysiology' filesep];

% PSTH calculation parameters
[pre_time, post_time, bin_width, bin_step] = deal(-1, 2, 0.01, 0.01);  % Time windows and bin sizes

%% Initialize variables
Iprb = 1;  % Probe counter
psth_mat = [];  % Main data structure

%% Get list of NWB files
nwb_file_address = dir([directory '\*.nwb']);

%% Main processing loop through NWB files
for ind_nwb = 1:length(nwb_file_address)
    % Load current NWB file
    curr_nwbfile = (nwb_file_address(ind_nwb).name);
    nwb = nwbRead([nwb_file_address(ind_nwb).folder '\' nwb_file_address(ind_nwb).name]);

    %% Extract unit information
    % Get unit tables
    units_table = [];
    for i = 1:nwb.units.id.data.dims
        units_table = [units_table; nwb.units.getRow(i)];
    end

    %% Extract electrode information
    electrodes_table = nwb.general_extracellular_ephys_electrodes.toTable;

    %% Extract trial information
    trials_table = nwb.intervals_trials.toTable;

    %% Extract behavioral time series data
    beh_timeseriesName = nwb.processing.get('behavior').nwbdatainterface.get('BehavioralTimeSeries').timeseries.keys;
    for i = beh_timeseriesName
        currname = cell2mat(i);
        eval(['behavior_strc.' currname '=nwb.processing.get("behavior").nwbdatainterface.get("BehavioralTimeSeries").timeseries.get("' currname '").data.load;']);
    end

    % Get video timestamps
    behavior_strc.video_timestamp = nwb.processing.get("behavior").nwbdatainterface.get("BehavioralTimeSeries").timeseries.get("C2Whisker_Angle").timestamps.load;

    % Get piezo sensor timestamps
    behavior_strc.piezo_timestamp = nwb.processing.get("behavior").nwbdatainterface.get("BehavioralTimeSeries").timeseries.get("Piezo_lick_trace").timestamps.load;

    %% Extract behavioral events
    beh_eventsName = nwb.processing.get('behavior').nwbdatainterface.get("BehavioralEvents").timeseries.keys;
    for i = beh_eventsName
        currname = cell2mat(i);
        eval(['behavior_strc.' currname '=nwb.processing.get("behavior").nwbdatainterface.get("BehavioralEvents").timeseries.get("' currname '").timestamps.load;']);
    end

    %% Standardize behavioral data structure
    % Ensure all behavioral data is column vectors
    for i = fieldnames(behavior_strc)'
        currname = cell2mat(i);
        if size(behavior_strc.(currname), 1) < size(behavior_strc.(currname), 2)
            behavior_strc.(currname) = behavior_strc.(currname)';
        end
    end

    %% Extract movement signals
    % Jaw and tongue coordinates
    Jaw_Coordinate = behavior_strc.Jaw_Coordinate;
    Tongue_Coordinate = behavior_strc.Tongue_Coordinate;
    snout_angle = behavior_strc.Snout_Angle;
    whisker_angle = behavior_strc.C2Whisker_Angle;
    video_timestamp = behavior_strc.video_timestamp;
    piezo_lick_trace = behavior_strc.Piezo_lick_trace;
    piezo_timestamp = behavior_strc.piezo_timestamp;

    % Filter piezo signal to remove noise
    piezo_lick_trace = sgolayfilt(double(piezo_lick_trace), 5, 11);

    %% Calculate movement metrics
    % Whisker speed (absolute difference)
    whisker_speed = [abs(diff(whisker_angle, 1, 1))];
    whisker_speed = [whisker_speed(1); whisker_speed];

    % Jaw movement (distance from mode position)
    jawcordX = Jaw_Coordinate(:, 1);
    jawcordY = Jaw_Coordinate(:, 2);
    jaw_movement = sqrt((jawcordY - mode(jawcordY)).^2 + (jawcordX - mode(jawcordX)).^2);

    % Tongue movement (distance from jaw mode position)
    TonguecordY = Tongue_Coordinate(:, 2);
    TonguecordX = Tongue_Coordinate(:, 1);
    tongue_movement = sqrt((TonguecordY - mode(jawcordY)).^2 + (TonguecordX - mode(jawcordX)).^2);
    
    % Remove outliers in tongue movements
    tongue_movement(20 * mean(tongue_movement) < tongue_movement) = nan;

    %% Organize movement signals
    MovementSignal.whisker_angle = whisker_angle;
    MovementSignal.whisker_speed = whisker_speed;
    MovementSignal.jaw_movement = jaw_movement;
    MovementSignal.snout_angle = snout_angle;
    MovementSignal.tongue_movement = tongue_movement;

    %% Calculate behavioral PSTHs
    % Determine frame rate based on file
    if any(strfind(curr_nwbfile, 'PG019'))
        frame_rate = 100;
    else
        frame_rate = 200;
    end
    
    % Calculate behavioral PSTHs
    [PSTH_Behavior, WindowCenters] = PSTHBehavior(MovementSignal, video_timestamp, trials_table.start_time, pre_time, post_time, 0.01, 0.01, frame_rate);

    % Calculate piezo PSTH
    Piezo.piezo_lick_trace = piezo_lick_trace;
    [PSTH_Piezo, WindowCentersPiezo] = PSTHBehavior(Piezo, piezo_timestamp, trials_table.start_time, pre_time, post_time, bin_width, bin_width, 2000);

    %% Combine behavioral data
    behavior_table = PSTH_Behavior;
    behavior_table.piezo_lick_trace = PSTH_Piezo.piezo_lick_trace;
    behavior_table.trial_timestamps = WindowCenters.whisker_angle';

    %% Identify quiet trials
    % Parameters for quiet trial detection
    params.prewhisk_window = [0.8, 1];      % Pre-whisker window
    params.baseline_window = [-1, 0];       % Baseline window
    params.movement_signals = {'whisker_speed', 'jaw_movement'};  % Signals to monitor
    params.selectin_method = 'mad_all';     % Method: 'mad_all' or 'one_by_one'
    
    % Find quiet trials based on movement criteria
    behavior_table = nwb_findQuietTrial(behavior_table, params);

    %% Process each brain region in the session
    % Get unique brain regions
    [arean_name, bind, cind] = unique(units_table.location);
    
    for iarea_name = 1:length(arean_name)
        % Get current area name and indices
        currarea_name = cell2mat(arean_name(iarea_name));
        ind_currarea_name = cind == iarea_name;
        
        %% Initialize probe structure
        psth_mat(Iprb).session_id{:} = nwb.identifier;
        psth_mat(Iprb).probe_location = arean_name(iarea_name);

        %% Add unit information
        columnname = fieldnames(units_table);
        columnname = columnname(1:end-3);  % Exclude last 3 columns
        for ifield = columnname'
            currfield = cell2mat(ifield);
            psth_mat(Iprb).(['unit_' currfield]) = [units_table.(currfield)(ind_currarea_name)];
        end

        %% Add electrode information
        ind_currarea_name_elec = find([strcmp(electrodes_table.location, currarea_name)]);
        columnname_elec = fieldnames(electrodes_table);
        columnname_elec = columnname_elec(1:end-3);  % Exclude last 3 columns
        for ifield = columnname_elec'
            currfield = cell2mat(ifield);
            psth_mat(Iprb).(['elec_' currfield]) = [electrodes_table.(currfield)(ind_currarea_name_elec)];
        end

        %% Add behavioral data
        columnname_behavior = fieldnames(behavior_table);
        for ifield = columnname_behavior'
            currfield = cell2mat(ifield);
            psth_mat(Iprb).(currfield) = [behavior_table.(currfield)];
        end

        %% Add trial information
        columnname_trial = fieldnames(trials_table);
        columnname_trial = columnname_trial(1:end-3);  % Exclude last 3 columns
        for ifield = columnname_trial'
            currfield = cell2mat(ifield);
            psth_mat(Iprb).(currfield) = [trials_table.(currfield)(:)];
        end

        %% Add trial type classification
        % Create trial type based on whisker stimulation and context
        psth_mat(Iprb).trial_type = [trial_typeMaker(psth_mat(Iprb).whisker_stim, psth_mat(Iprb).context)]';

        %% Calculate spike counts per trial per cell
        currspiketimes = psth_mat(Iprb).unit_spike_times;
        spikeCountsAll = [];
        
        for iCluster = 1:numel(currspiketimes)
            [spikeRates, Windowcenters, spikeCounts] = PSTH_Simple(currspiketimes{iCluster, 1}, psth_mat(Iprb).start_time, pre_time, post_time, bin_width, bin_width);
            spikeCountsAll(:, :, iCluster) = spikeCounts;
        end

        %% Store spike count data
        psth_mat(Iprb).spike_counts = spikeCountsAll;
        
        % Increment probe counter
        Iprb = Iprb + 1;
    end
end



en=0;
for SessionCounter=1:size(psth_mat,2)
    ClusterIDinsession= 1:length(psth_mat(SessionCounter).unit_cluster_id);
    index=sum(en)+ClusterIDinsession;
    en=[en;ClusterIDinsession(end)];
    psth_mat(SessionCounter).GlobalclusterID=index;
end





%% Save processed data
% Save to processed data directory

directory=[CurrentDir filesep 'processed_data' filesep];
save([directory 'psth_10ms.mat'], "psth_mat", '-v7.3');
