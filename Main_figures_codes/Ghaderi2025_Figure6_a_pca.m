%% =========================================================================
% Ghaderi2025_Figure6A_pca.m
% =========================================================================
%
% This script generates Figure 6A showing PCA analysis of neural activity
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script performs Principal Component Analysis (PCA) on neural activity
% across different brain areas and trial conditions. It plots neural trajectories in
% the first two principal components, showing how neural activity evolves over time
% for different trial types.
%
% Dependencies:
%   - psth_10ms.mat (contains trial data)
%   - Area_list.mat (contains brain area information)
%   - tight_subplot.m (for subplot management)
%   - bin_spike_counts.m (for spike count binning)
%   - costumcolor_shade.m (for custom color gradients)
%
% Output: PDF figure showing PCA analysis of neural activity
% =========================================================================

%% Clear workspace and set up environment
clear all
close all
clc

%% Load required data

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'psth_10ms.mat'])
load([directory filesep 'data_helpers' filesep 'Area_list.mat'])

%% Optional: Change figure name

change_name = 0;
newname = 'Figure6A_pca';
fullname = mfilename('fullpath');
inds = regexp(fullname,'\','all');
name = fullname(inds(end)+1:end);
if change_name
    movefile([name '.m'],[newname '.m']);
end


%% Initialize main figure

parent = figure('Position', [100 100 1400 400]);
h = tight_subplot(1,5,[.08 .04],[.15 .15],[.05 .01]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters

params.QuietState = 'Quiet_(jaw & whisker)';  % 'Quiet_(whisker_speed)' 'Quiet_(jaw_movement)' 'Quiet_(jaw & whisker)' 'Non_quiet' 'All_trials'
params.normalization = 1;
params.completion_state = 'completed_trials';  % Options: 'early_licks' 'completed_trials'
params.TrialType = [1,3,2,1];  % 1: gotone/whisker  2: gotone/nowhisker 3: nogotone/whisker  4: nogotone/nowhisker  5: notone/whisker
params.LickState = [1,0,0,0];  % lick 1: lick  0:nolick
params.CellType = 'All';  % 'R' 'FS' 'RS_FS' 'All'
regionlist = {'A1','wS1','wS2','wM2','ALM'};  % Brain regions
t_start = -1;  % Start time
t_end = 2;     % End time
bin_width = 0.01;
XTickLabel = {'-1';'0';'1';'2'};
xtick = [-1;0;1;2];

%% Plotting parameters

resolution_change = 1;
new_bin_size = 50;     % in ms
scale = 5;             % scaled according to 10
pca_endbin = 60;       % PCA calculation end bin

interpolation = 1;
interploation_step = 1;   % in ms


%% Define movement signals

movements_signals = {'whisker_speed','snout_angle','piezo_lick_trace','jaw_movement','tongue_movement'};
movements_signals_tag = {'Whisker','Snout','Piezo lick','Jaw','Tongue'};
params.movement_baselineSubtraction = 1;
params.movement_normalization = 0;


%% Process each brain area
Neurons_activity_condition_area = [];

for ind_area = 1:length(regionlist)

    curr_area = cell2mat(regionlist(ind_area));
    prb_list = find(strcmp(curr_area,[psth_mat.probe_location]));
    Neurons_activity_condition = [];
    Neurons_activity_condition_area = [];

    % Process each trial condition

    for i_cond = 1:length(params.TrialType)
        Concatsig = [];

        % Process each probe

        for i_prb = prb_list
            Trial = psth_mat(i_prb).trial_type;
            Lick = psth_mat(i_prb).lick_flag;

            % Define conditions
            IndTrialType = Trial == params.TrialType(i_cond);
            IndLickstate = Lick == params.LickState(i_cond);

            % Define completion state
            switch params.completion_state
                case 'completed_trials'
                    completion_state = ~psth_mat(i_prb).early_lick;
                case 'early_licks'
                    early_licks_all = psth_mat(i_prb).early_lick;
                    lick_time = 0 < (psth_mat(i_prb).lick_time - psth_mat(i_prb).start_time);
                    completion_state = lick_time & early_licks_all;
            end

            % Define quiet state
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
                    Qind = logical(ones(length(IndLickstate),1));
            end

            CurrTrialInd = [Qind & completion_state & IndLickstate & IndTrialType];

            % Define cell type
            switch params.CellType
                case 'RS'
                    CelltypeInd = psth_mat(i_prb).unit_rsUnits;
                case 'FS'
                    CelltypeInd = psth_mat(i_prb).unit_fsUnits;
                case 'RS_FS'
                    CelltypeInd = (psth_mat(i_prb).unit_fsUnits | psth_mat(i_prb).unit_rsUnits);
                case 'All'
                    CelltypeInd = logical(ones(length(psth_mat(i_prb).unit_rsUnits),1));
            end

            % CCF filter on cell location

            ind_ccf_filter = ismember(psth_mat(i_prb).unit_ccf_location,area_list.(curr_area));
            CurrCellInd = (CelltypeInd & ind_ccf_filter);

            % Current PSTH of selected session

            CurrSp = psth_mat(i_prb).spike_counts;

            % Apply resolution change if requested

            if resolution_change
                CurrSp = bin_spike_counts(CurrSp, new_bin_size, 10);
                WindowCenters = psth_mat(i_prb).trial_timestamps;
                WindowCenters = -1 + new_bin_size/1000:new_bin_size/1000:2;
            else
                WindowCenters = psth_mat(i_prb).trial_timestamps;
            end

            % Take the average over specific trial conditions

            CurrSp_CurrTrialInd = squeeze(nanmean(CurrSp(:,CurrTrialInd,:),2));
            CurrSp_CurrTrialInd_CurrCellInd = CurrSp_CurrTrialInd(:,CurrCellInd);

            if isempty(CurrSp_CurrTrialInd_CurrCellInd)
                continue;
            end

            % Apply baseline subtraction

            t1 = -1;
            t2 = 0;
            [a,b] = min(abs(WindowCenters-t1)); baselineFirstBin = (b);
            [a,b] = min(abs(WindowCenters-t2)); baselineLastBin = (b);
            baseline_mean = repmat(mean(CurrSp_CurrTrialInd_CurrCellInd(baselineFirstBin:baselineLastBin,:),1),size(CurrSp_CurrTrialInd_CurrCellInd,1),1);
            CurrSp_CurrTrialInd_CurrCellInd = (CurrSp_CurrTrialInd_CurrCellInd - baseline_mean);

            Concatsig = [Concatsig,CurrSp_CurrTrialInd_CurrCellInd];

        end % End of probe loop

        Neurons_activity_condition = [Neurons_activity_condition,Concatsig(1:pca_endbin,:)'];
        trial_type_size = size(Concatsig(1:pca_endbin,:),1);

    end % End of condition loop


    % Prepare data for PCA
    Neurons_activity_condition_area = [Neurons_activity_condition];

    % Apply normalization if requested

    if params.normalization

        % remove units with constant activity
        max_mat = max(Neurons_activity_condition_area,[],2);
        min_mat = min(Neurons_activity_condition_area,[],2);

        Min_Max_Diff=max_mat-min_mat;
        Unit_Ind=~isnan(Min_Max_Diff./Min_Max_Diff);
        Neurons_activity_condition_area=Neurons_activity_condition_area(Unit_Ind,:);

        max_mat = max(Neurons_activity_condition_area,[],2);
        min_mat = min(Neurons_activity_condition_area,[],2);        
        norm_mat = repmat(max_mat-min_mat,1,size(Neurons_activity_condition_area,2));
        Neurons_activity_condition_area = [Neurons_activity_condition_area./norm_mat]';
    end

    % Split data for training and testing

    main_neuronaldata = Neurons_activity_condition_area([1:2*trial_type_size],:);
    test_neuronaldata = Neurons_activity_condition_area([(2*trial_type_size+1):end],:);
    all_neuronaldata = Neurons_activity_condition_area;

    % Perform PCA

    [coeff,score,latent,tsquared,explained,mu] = pca(all_neuronaldata); % PCA along neuron dimension

    All_Area_PCA_Explained_Variance.(curr_area)=explained;

    % Project data onto principal components

    main_projected = (main_neuronaldata-mean(main_neuronaldata))*coeff;
    test_projected = (test_neuronaldata-mean(test_neuronaldata))*coeff;
    all_projected = (all_neuronaldata-mean(all_neuronaldata))*coeff;

    % Define colors for different conditions

    condition_colors = {[0 0 1], [1 0 0], [0 0 1], [1 0 0]}; % Blue, Red, Blue, Red

    hold(axs(ind_area),'on');
    num_segments = size(all_projected, 1) / trial_type_size;

    % Plot each condition

    for i = [1:4]
        % Define time ranges for customization
        delay_start = 100/scale;  % Adjust start of baseline
        delay_end = 200/scale;    % Default: 100

        % Define the row indices for this segment

        start_idx = (i-1) * trial_type_size + 1;
        end_idx = i * trial_type_size;

        % Extract PCA scores for this segment

        segmentData = all_projected(start_idx:end_idx, 1:2);
        segmentData = segmentData(delay_start:delay_end, 1:2);
        segmentData_copy = segmentData;

        % Apply interpolation if requested

        segmentData_s = [];
        if interpolation
            windowCenters = 0:new_bin_size/1000:1;
            segmentData_s(:,1) = spline(windowCenters,segmentData(:,1),[0:interploation_step/1000:1]);
            segmentData_s(:,2) = spline(windowCenters,segmentData(:,2),[0:interploation_step/1000:1]);
            segmentData = segmentData_s;
        end

        % Get color for this condition

        segment_color = condition_colors{i};

        c = 1:length(segmentData(:,1)); % Color based on time
        x = segmentData(:,1)';
        y = segmentData(:,2)';

        % Create custom color maps

        blue_map = costumcolor_shade([0.8, 0.9, 1],[0, 0, 1],length(x)-1);
        red_map = costumcolor_shade([1, 0.8, 0.8],[1, 0, 0],length(x)-1);
        mint_map = costumcolor_shade([161,226,224]/255,[1, 150,150]/255,length(x)-1);
        purple_map = costumcolor_shade([246,210,247]/255,[255, 0,255]/255,length(x)-1);

        cmap = {blue_map, red_map, mint_map, purple_map};
        color_i = cell2mat(cmap(i));

        % Plot trajectory with color gradient

        for ii = 1:length(x)-1
            plot(axs(ind_area),x(ii:ii+1), y(ii:ii+1), 'Color', color_i(ii,:), 'LineWidth', 2);
        end

        % Plot original data points

        c_o = 1:length(segmentData_copy(:,1));
        x_o = segmentData_copy(:,1)';
        y_o = segmentData_copy(:,2)';

        blue_map = costumcolor_shade([0.8, 0.9, 1],[0, 0, 1],length(x_o)-1);
        red_map = costumcolor_shade([1, 0.8, 0.8],[1, 0, 0],length(x_o)-1);
        mint_map = costumcolor_shade([161,226,224]/255,[1, 150,150]/255,length(x_o)-1);
        purple_map = costumcolor_shade([246,210,247]/255,[255, 0,255]/255,length(x_o)-1);

        cmap_o = {blue_map, red_map, mint_map, purple_map};
        color_i_o = cell2mat(cmap_o(i));

        for ii_o = 1:length(x_o)-1
            plot(axs(ind_area),x_o(ii_o:ii_o+1), y_o(ii_o:ii_o+1),'o', 'MarkerFaceColor', color_i_o(ii_o,:),'MarkerEdgeColor',color_i_o(ii_o,:),'MarkerSize',8);
        end

        % Mark start and end points

        plot(axs(ind_area),segmentData(1,1), segmentData(1,2), 'o', 'MarkerSize', 10, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'none');
        plot(axs(ind_area),segmentData(end,1), segmentData(end,2), 'o', 'MarkerSize', 10, 'MarkerFaceColor', [1, .6, 0], 'MarkerEdgeColor', 'none');
        cond_segment{i} = segmentData_copy;

    end

    % Format plot
    colormap = {cmap{2}(100,:);cmap{3}(100,:);cmap{4}(100,:)};
    ylim(axs(ind_area),[-3 6]);
    xlim(axs(ind_area),[-6 6]);
    yticklabels(axs(ind_area),get(axs(ind_area),"YTick"));
    xticklabels(axs(ind_area),get(axs(ind_area),"XTick"));
    title(axs(ind_area),curr_area);

end % End of area loop

%% Add axis labels
xlabel(axs(1),'PC1 (a.u)');
ylabel(axs(1),'PC2 (a.u)');

%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');
