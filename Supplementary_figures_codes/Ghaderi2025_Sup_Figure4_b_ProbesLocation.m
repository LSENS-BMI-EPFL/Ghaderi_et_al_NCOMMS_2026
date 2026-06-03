%% =========================================================================
% Ghaderi2025_Figure3Sup1_b.m
% =========================================================================
%
% This script generates Figure 3Sup1B showing brain probe locations and 3D brain maps
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making"
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script creates 3D brain maps showing probe locations across different
% brain areas. It plots probe positions in both top-down and angled views, with color-coded
% regions and reference markers for anatomical orientation.
%
% Dependencies: 
%   - psth_10ms.mat (contains trial data)
%   - psth_sub_PG082_ses_20221113T145317.mat (contains session-specific data)
%   - tight_subplot.m (for subplot management)
%   - plotBrainGrid.m (for brain outline plotting)
%   - allenCCFbregma.m (for brain coordinate system)
%   - tools.hex2rgb.m (for color conversion)
%
% Output: PDF figure showing 3D brain maps with probe locations
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

load([directory filesep 'processed_data' filesep 'psth_sub_PG082_ses_20221113T145317.mat'])

%% Initialize main figure
parent = figure("Position", [500 50 1000 950]);

% Create subplot layout (2 rows, 1 column)
h = tight_subplot(2, 1, [.07 .07], [.07 .04], [.07 .01]);

% Define brain regions and color scheme
regionlist = {'A1', 'wM2', 'wS1', 'ALM', 'wS2'};  % Brain areas to plot
colors = {'#0008FF'; '#228B22'; '#00C3FF'; '#FF0000'; '#FF7F00'; '#000000'; '#00C3FF'; '#FF7F00'; '#FF7F00'; '#808080'; '#6B3686'; '#74B99A'; '#A020F0'; '#FFC0CB'; '#FFD700'};
label_color = {'wS1'; 'wS2'; 'CR2'; 'ALM'; 'CR4'; 'wM2'; 'FA2'; 'FA3'; 'FA4'; 'FA5'; 'Lick'; 'NoLick'; 'A1'; 'unassigned_area'; 'tjM1'};
Map = horzcat(label_color, colors);

% Get all axes handles
axs = findall(gcf, 'type', 'axes');

%% Plot top-down view (first subplot)
hold(h(1), 'on');

% Plot brain grid outline
[f, brain_outline] = plotBrainGrid([], h(1));

% Set subplot positioning and properties
set(h(1), 'OuterPosition', [0 .2 1 1]);
set(h(1), 'InnerPosition', [0 .2 1 1]);
set(h(1), 'ZDir', 'reverse');

% Configure 3D view properties
axis(h(1), 'vis3d', 'equal', 'off', 'manual');
view(h(1), [0, 90]);
set(h(1), 'CLim', [0 600]);

% Set axis limits
xlim(h(1), [0, 900]);
ylim(h(1), [0, 600]);

% Plot bregma reference point
bregma = allenCCFbregma();
plot3(h(1), bregma(:, 1), ...
    bregma(:, 3), ...
    bregma(:, 2), ...
    '+', 'color', 'k', 'MarkerSize', 15, 'linewidth', 3);

%% Plot probe locations for each brain region (top-down view)
dY = 2;

for iarea = 1:length(regionlist)
    CurrentArea = cell2mat(regionlist(iarea));
    iprb = find(strcmp(CurrentArea, [psth_mat_session.probe_location]));

    % Plot each probe in current area
    for iprobes_Ind = iprb
        % Calculate mean probe position
        points = mean([psth_mat_session(iprobes_Ind).elec_ccf_ap, ...
                      psth_mat_session(iprobes_Ind).elec_ccf_dv, ...
                      psth_mat_session(iprobes_Ind).elec_ccf_ml]);
        
        if isempty(points)
            continue;
        end
        
        % Get color for current area
        indcolor = find(strcmp(CurrentArea, Map(:, 1)));
        plot3(h(1), points(1, 1), points(1, 3), points(1, 2), ...
            '.', 'color', hex2rgb(cell2mat(Map(indcolor, 2))), ...
            'linewidth', 1.5, 'MarkerSize', 50);
    end
    
    % Add region label
    text(axs(2), 0.1, dY, CurrentArea, 'Color', hex2rgb(cell2mat(Map(indcolor, 2))));
    dY = dY - 40;
end

%% Format text elements
childTexts = findall(axs(2), 'Type', 'Text');
for thisText = childTexts'
    set(thisText, 'FontSize', 14);
end

%% Plot angled view (second subplot)
hold(h(2), 'on');

% Plot brain grid outline for angled view
[f_3, brain_outline_3] = plotBrainGrid([], h(2));

% Set subplot positioning and properties
set(h(2), 'OuterPosition', [.1 -.1 .7 .7]);
set(h(2), 'InnerPosition', [.1 -.1 .7 .7]);
set(h(2), 'ZDir', 'reverse');

% Configure 3D view properties for angled view
axis(h(2), 'vis3d', 'equal', 'off', 'manual');
view(h(2), [-45.9898, 14.3886]);
set(h(2), "CameraViewAngle", 8);

% Plot bregma reference point
bregma = allenCCFbregma();
plot3(h(2), bregma(:, 1), ...
    bregma(:, 3), ...
    bregma(:, 2), ...
    '+', 'color', 'k', 'MarkerSize', 25, 'linewidth', 4);

%% Plot probe trajectories for each brain region (angled view)
annotation_color = [];

for iarea = 1:length(regionlist)
    CurrentArea = cell2mat(regionlist(iarea));
    iprb = find(strcmp(CurrentArea, [psth_mat_session.probe_location]));
    indcolor = find(strcmp(CurrentArea, Map(:, 1)));
    annotation_color = [annotation_color; hex2rgb(cell2mat(Map(indcolor, 2)))];
    
    % Plot each probe trajectory
    for iprobes_Ind = iprb
        points = ([psth_mat_session(iprobes_Ind).elec_ccf_ap, ...
                  psth_mat_session(iprobes_Ind).elec_ccf_dv, ...
                  psth_mat_session(iprobes_Ind).elec_ccf_ml]);
        
        if isempty(points)
            continue;
        end
        
        % Plot probe trajectory line
        line(points(:, 1), points(:, 3), points(:, 2), ...
            'linewidth', 3, 'color', hex2rgb(cell2mat(Map(indcolor, 2))));
    end
end

%% Export figure
directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');

















