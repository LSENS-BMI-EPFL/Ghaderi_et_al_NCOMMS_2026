%% =========================================================================
% Optoinhibition_mat.m
% =========================================================================
% 
% This script processes optogenetic inhibition data from NWB files for the
% manuscript "Contextual gating of whisker-evoked responses by frontal 
% cortex supports flexible decision making" (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script loads and processes optogenetic inhibition data
% from Neurodata Without Borders (NWB) files. It extracts trial information,
% fiber locations, and other experimental parameters from multiple NWB files
% and consolidates them into a structured MATLAB format for further analysis.
%
% Dependencies: 
%   - matnwb package (for reading NWB files)
%   - NWB files in ../data_optogenetics/ directory
%
% Input: NWB files containing optogenetic inhibition data
% Output: Processed optogenetic data saved to Optoinhibition_mat.mat
% =========================================================================

%% Initialize workspace and load required packages
% Load the matnwb package
clear all
close all
clc

%% Define data directory and parameters
CurrentDir=pwd;
directory=[CurrentDir];
directory=[CurrentDir filesep 'data_optogenetics' filesep];

rng(0)

Iprb = 1;                                 % Probe counter
optomat = [];                             % Initialize output structure

%% Process NWB files
% Get list of all NWB files in the directory
nwb_file_address = dir([directory '\*.nwb']);

% Loop through each NWB file
for ind_nwb = 1:length(nwb_file_address)
    curr_nwbfile = (nwb_file_address(ind_nwb).name);
    
    % Read current NWB file
    nwb = nwbRead([nwb_file_address(ind_nwb).folder '\' nwb_file_address(ind_nwb).name]);
    
    %% Extract trial information
    % Get trial table from NWB file
    trials_table = nwb.intervals_trials.toTable;
    
    % Extract column names for trial data (excluding first and last 3 columns)
    columnname_trial = fieldnames(trials_table);
    columnname_trial = columnname_trial(2:end-3);
    
    %% Extract area information
    % Get unique optogenetic stimulation areas
    currarea_name = unique(trials_table.opto_area);
    currarea_name(strcmp(currarea_name, 'nan')) = [];  % Remove NaN values
    
    %% Store session information
    optomat(Iprb).session_id{:} = [nwb.identifier];
    optomat(Iprb).fiber_location = cell2mat(currarea_name);
    
    %% Extract trial parameters
    % Loop through each trial field and store the data
    for ifield = columnname_trial'
        currfield = cell2mat(ifield);
        optomat(Iprb).(currfield) = [trials_table.(currfield)(:)];
    end
    
    % Increment probe counter
    Iprb = Iprb + 1;
end

%% Save processed data
% Save the consolidated optogenetic data to a MAT file

directory=[CurrentDir filesep 'processed_data' filesep];
save([directory 'Optoinhibition_mat.mat'], "optomat", '-v7.3');

