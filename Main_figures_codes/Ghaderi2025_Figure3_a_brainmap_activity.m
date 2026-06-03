%% =========================================================================
% Ghaderi2025_Figure3A_brainmap_activity.m
% =========================================================================
% 
% This script generates Figure 3A showing brain activity maps across different time windows
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making" 
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script creates 3D brain maps showing neural activity across different 
% time windows (audio, delay, whisker, post-whisker). It plots probe locations and 
% color-codes them based on firing rate changes during different trial periods.
%
% Dependencies: 
%   - psth_10ms.mat (contains trial data)
%   - Area_list.mat (contains brain area information)
%   - tight_subplot.m (for subplot management)
%   - allenCCFbregma.m (for brain coordinate system)
%   - tools.hex2rgb.m (for color conversion)
%   - SC_Scale2Color.m (for color scaling)
%
% Output: PDF figure showing brain activity maps across time windows
% =========================================================================

%% Clear workspace and set up environment
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

%% Initialize main figure

parent = figure('Position', [100 100 1000 600]);

% Create subplot layout (1 row, 5 columns)
h = tight_subplot(1, 5, [.01 .01], [.01 .01], [.01 .01]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);

%% Define analysis parameters
params.QuietState = 'Quiet_(jaw & whisker)';  % Options: 'Quiet_(whisker_speed)', 'Quiet_(jaw_movement)', 'Quiet_(jaw & whisker)', 'Non_quiet', 'All_trials'
params.BaselineSubtraction = 1;
params.completion_state = 'completed_trials';  % Options: 'early_licks', 'completed_trials'
params.TrialType = [1];  % 1: gotone/whisker, 2: gotone/nowhisker, 3: nogotone/whisker, 4: nogotone/nowhisker, 5: notone/whisker
params.LickState = [1];  % 1: lick, 0: nolick
params.CellType = 'All';  % Options: 'RS', 'FS', 'RS_FS', 'All'
params.regionlist = {'A1', 'wM2', 'wS1', 'ALM', 'wS2', 'unassigned_area', 'tjM1'};

% Time window parameters
t_start = -1;  % Start time
t_end = 2;     % End time
bin_width = 0.01;
XTickLabel = {'-1'; '0'; '1'; '2'};
xtick = [-1; 0; 1; 2];

% Analysis windows for different trial periods
window_list = {[0.01, .03]; [.8, 1]; [1.01, 1.03]; [1.3, 1.5]};  % Audio, delay, whisker, post-whisker periods
flg = 0;

% Color range for plotting
range = [-5 5; -1 1; -8 8; -5 5];

%% Plot location of all probes (first subplot)
hold(axs(1), 'on');

% Set 3D view properties
set(axs(1), 'ZDir', 'reverse');
axis(axs(1), 'vis3d', 'equal', 'off', 'manual');
view(axs(1), [90, 90]);
clim([0 600]);

% Set axis limits
xlim(axs(1), [0, 1000]);
ylim(axs(1), [0, 600]);
zlim(axs(1), [0, 500]);

% Plot bregma reference point
bregma = allenCCFbregma();
plot3(axs(1), bregma(:, 1), ...
    bregma(:, 3), ...
    bregma(:, 2), ...
    '+', 'color', 'k', 'MarkerSize', 15, 'linewidth', 1);

% Plot reference lines
xlin = [740 0 570;
    690 0 570];
plot3(axs(1), xlin(:, 1), ...
    xlin(:, 3), ...
    xlin(:, 2), ...
    '-', 'color', 'k', 'MarkerSize', 1, 'linewidth', 1);

ylin = [740 0 570;
    740 0 520];
plot3(axs(1), ylin(:, 1), ...
    ylin(:, 3), ...
    ylin(:, 2), ...
    '-', 'color', 'k', 'MarkerSize', 1, 'linewidth', 1);

%% Define region list and color scheme
flg = 0;
dY = 1.4;

regionlist = {'A1', 'wM2', 'wS1', 'ALM', 'wS2', 'unassigned_area', 'tjM1'};

% Color scheme for different brain regions
colors = {'#0008FF'; '#228B22'; '#FF0000'; '#000000'; '#A020F0'; '#a89b9b'; '#a89b9b'};
label_color = {'wS1'; 'wS2'; 'ALM'; 'wM2'; 'A1'; 'unassigned_area'; 'tjM1'};
Map = horzcat(label_color, colors);

hold(h(1), 'on');

%% Plot probe locations for each brain region
for iarea = 1:length(regionlist)
    CurrentArea = cell2mat(regionlist(iarea));
    iprb = find(strcmp(CurrentArea, [psth_mat.probe_location]));
    
    % Plot each probe in current area
    for iprobes_Ind = iprb
        points = ([psth_mat(iprobes_Ind).elec_ccf_ap(end), ...
                  psth_mat(iprobes_Ind).elec_ccf_dv(end), ...
                  psth_mat(iprobes_Ind).elec_ccf_ml(end)]);
        
        if isempty(points)
            continue;
        end
        
        indcolor = find(strcmp(CurrentArea, Map(:, 1)));
        plot3(h(1), points(1, 1), points(1, 3), 0, ...
            'o', 'color', hex2rgb(cell2mat(Map(indcolor, 2))), 'linewidth', 1, 'MarkerSize', 5);
    end
    
    % Handle special area names for display
    if strcmp(CurrentArea, 'unassigned_area')
        CurrentArea = 'Unassigned area';
        flg = flg + 1;
    end
    
    if strcmp(CurrentArea, 'tjM1')
        CurrentArea = 'unassigned area';
        continue;
    end
    
    % Add region label
    text(axs(1), 0, dY, CurrentArea, 'Color', hex2rgb(cell2mat(Map(indcolor, 2))), 'Units', 'normalized');
    dY = dY - .07;
end

%% Format text elements
childTexts = findall(axs(1), 'Type', 'Text');
for thisText = childTexts'
    set(thisText, 'FontSize', 12);
end

%% Process each time window for activity analysis
flg = 0;
colors = [];

for window_ind = 1:length(window_list)
    
    % Get current analysis window
    W_aud = cell2mat(window_list(window_ind));
    trial_time = psth_mat(1).trial_timestamps;
    [a, b] = min(abs(trial_time - W_aud(1))); W_audFirstBin = (b);
    [a, b] = min(abs(trial_time - W_aud(2))); W_audLastBin = (b);
    
    % Set up color mapping
    params.colormap = {'#0008FF'; '#228B22'; '#00C3FF'; '#FF0000'; '#FF7F00'; '#000000'; '#00C3FF'; '#FF7F00'; '#FF7F00'; '#808080'; '#6B3686'; '#74B99A'; '#A020F0'; '#FFD700'};
    params.colortype = {'wS1'; 'wS2'; 'CR2'; 'ALM'; 'CR4'; 'wM2'; 'FA2'; 'FA3'; 'FA4'; 'FA5'; 'Lick'; 'NoLick'; 'A1'; 'tjM1'};
    params.Map = horzcat(params.colortype, params.colormap);
    
    % Set up subplot for current time window
    hold(axs(window_ind + 1), 'on');
    
    % Configure 3D view
    set(axs(window_ind + 1), 'ZDir', 'reverse');
    axis(axs(window_ind + 1), 'vis3d', 'equal', 'off', 'manual');
    view(axs(window_ind + 1), [90, 90]);
    clim([0 600]);
    
    % Set axis limits
    xlim(axs(window_ind + 1), [0, 1000]);
    ylim(axs(window_ind + 1), [0, 600]);
    zlim(axs(window_ind + 1), [0, 500]);
    
    % Plot bregma reference
    bregma = allenCCFbregma();
    plot3(axs(window_ind + 1), bregma(:, 1), ...
        bregma(:, 3), ...
        bregma(:, 2), ...
        '+', 'color', 'k', 'MarkerSize', 10, 'linewidth', 1);
    
    % Plot reference lines
    xlin = [740 0 570;
        690 0 570];
    plot3(axs(window_ind + 1), xlin(:, 1), ...
        xlin(:, 3), ...
        xlin(:, 2), ...
        '-', 'color', 'k', 'MarkerSize', 1, 'linewidth', 1);
    
    ylin = [740 0 570;
        740 0 520];
    plot3(axs(window_ind + 1), ylin(:, 1), ...
        ylin(:, 3), ...
        ylin(:, 2), ...
        '-', 'color', 'k', 'MarkerSize', 1, 'linewidth', 1);
    
    % Calculate neural activity for each probe
    currsig = nan(length(psth_mat), 1);
    
    % Process each trial condition
    for ind_cond = 1:length(params.TrialType)
        % Process each brain area
        for iarea = 1:length(params.regionlist)
            current_area = cell2mat(params.regionlist(iarea));
            iprb = find(strcmp(current_area, [psth_mat.probe_location]));
            
            % Process each probe in current area
            for ind_probe = iprb
                Trial = psth_mat(ind_probe).trial_type;
                Lick = psth_mat(ind_probe).lick_flag;
                
                % Apply trial type filter
                IndTrialType = Trial == params.TrialType(ind_cond);
                IndLickstate = Lick == params.LickState(ind_cond);
                
                % Determine completion state
                switch params.completion_state
                    case 'completed_trials'
                        completion_state = ~psth_mat(ind_probe).early_lick;
                    case 'early_licks'
                        early_licks_all = psth_mat(ind_probe).early_lick;
                        lick_time = 0 < (psth_mat(ind_probe).lick_time - psth_mat(ind_probe).start_time);
                        completion_state = lick_time & early_licks_all;
                end
                
                % Apply quiet state filter
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
                        Qind = ones(length(IndLickstate), 1);
                end
                
                current_trial_ind = [Qind & completion_state & IndLickstate & IndTrialType];
                
                % Apply cell type filter
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
                
                % Apply CCF filter on cell location
                if strcmp(current_area, 'unassigned_area') | strcmp(current_area, 'tjM1')
                    current_cell_ind = CelltypeInd;
                else
                    ind_ccf_filter = ismember(psth_mat(ind_probe).unit_ccf_location, area_list.(current_area));
                    current_cell_ind = (CelltypeInd & ind_ccf_filter);
                end
                
                if sum(current_cell_ind) == 0
                    current_cell_ind = (CelltypeInd);
                end
                
                % Calculate firing rate changes
                % Get current spike counts
                curr_sp = psth_mat(ind_probe).spike_counts;
                
                % Average over specific trial conditions
                curr_sp_trials = squeeze(nanmean(curr_sp(:, current_trial_ind, :), 2));
                
                % Filter for specified cell types
                curr_sp_trials_cells = curr_sp_trials(:, current_cell_ind);
                
                % Calculate baseline
                WindowCenters = psth_mat(ind_probe).trial_timestamps;
                t1 = -1;
                t2 = 0;
                [a, b] = min(abs(WindowCenters - t1)); baselineFirstBin = (b);
                [a, b] = min(abs(WindowCenters - t2)); baselineLastBin = (b);
                
                baseline_mean = repmat(mean(curr_sp_trials_cells(baselineFirstBin:baselineLastBin, :), 1), size(curr_sp_trials_cells, 1), 1);
                baseline_std = repmat(std(curr_sp_trials_cells(baselineFirstBin:baselineLastBin, :), 1), size(curr_sp_trials_cells, 1), 1);
                baseline_std(find(baseline_std == 0)) = 1e-10;
                
                % Apply baseline subtraction if requested
                if params.BaselineSubtraction
                    curr_sp_trials_cells = (curr_sp_trials_cells - baseline_mean);
                end
                
                % Calculate mean activity in current window
                currsig(ind_probe, ind_cond) = mean(mean(curr_sp_trials_cells(W_audFirstBin:W_audLastBin, :), 2)) / bin_width;
                points(ind_probe, :) = [psth_mat(ind_probe).elec_ccf_ap(end), ...
                                      psth_mat(ind_probe).elec_ccf_dv(end), ...
                                      psth_mat(ind_probe).elec_ccf_ml(end)];
            end % End of probe loop
        end % End of area loop
    end % End of condition loop
    
    % Create color mapping for activity visualization
    % Sort signals and corresponding points
    [sortedcurrsig, sortIdx] = sort(currsig);
    points = points(sortIdx, :);
    currsig = sortedcurrsig;
    
    % Plot probes with color-coded activity
    for i = 1:length(points)
        [C] = SC_Scale2Color(currsig(i), range(window_ind, 1), range(window_ind, 2), 0);
        plot3(axs(window_ind + 1), points(i, 1), points(i, 3), 0, ...
            'o', 'color', 'k', 'MarkerFaceColor', C, 'MarkerSize', 5);
        colors(i, :) = C;
    end
    
    % Create colorbar
    % Generate values for colorbar
    values_vector = linspace(range(window_ind, 1), range(window_ind, 2), 110);
    
    % Sort values and corresponding colors
    [sortedValues, sortIdx] = sort(values_vector);
    for i = 1:length(values_vector)
        [C] = SC_Scale2Color(values_vector(i), range(window_ind, 1), range(window_ind, 2), 0);
        colors(i, :) = C;
    end
    
    sortedColors = colors(sortIdx, :);
    
    % Create colorbar matrix
    thickness = 20;  % Colorbar thickness
    colorBarMatrix = repmat(reshape(sortedColors, [110, 1, 3]), [1, thickness, 1]);
    
    % Position colorbar
    newAxesPosition = [0.35 + flg, 0.8, .02, .09];
    colorBarAxes = axes('Position', newAxesPosition, 'Units', 'normalized');
    imagesc(colorBarMatrix, 'Parent', colorBarAxes);
    
    % Configure colorbar appearance
    set(colorBarAxes, 'YDir', 'normal');
    numTicks = 2;
    tickIndices = round(linspace(1, 110, numTicks));
    tickLabels = [arrayfun(@(x) sprintf('%.2f', sortedValues(x)), tickIndices, 'UniformOutput', false)]';
    
    set(colorBarAxes, 'YTick', tickIndices);
    set(colorBarAxes, 'YTicklabels', tickLabels);
    set(colorBarAxes, 'XTick', []);
    set(colorBarAxes, 'FontSize', 10, 'TickLength', [0 0]);
    set(colorBarAxes, 'YColor', 'k');
    
    flg = flg + .2;

end % End of window loop

%% Export figure
directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');





