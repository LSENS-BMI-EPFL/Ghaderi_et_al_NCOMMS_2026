%% =========================================================================
% Ghaderi2025_ExtendedData_Figure5_a_3DViews.m
% =========================================================================
% 
% This script generates Figure 3 Supplementary showing 3D brain views with probe locations
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making" 
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script creates 3D brain views showing probe locations across different
% brain areas from multiple viewing angles. It generates four different perspectives of the
% brain with color-coded probe tracks for each brain region.
%
% Dependencies: 
%   - psth_10ms.mat (contains trial data)
%   - tight_subplot.m (for subplot management)
%   - plotBrainGrid.m (for brain outline plotting)
%   - allenCCFbregma.m (for brain coordinate system)
%   - hex2rgb.m (for color conversion)
%
% Output: PDF figure showing 3D brain views with probe locations
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


%% Define analysis parameters
regionlist = {'A1', 'wM2', 'wS1', 'ALM', 'wS2', 'unassigned_area', 'tjM1'};  % Brain regions to plot

% Color scheme for different brain regions
colors = {'#0008FF'; '#228B22'; '#FF0000'; '#000000'; '#A020F0'; '#a89b9b'; '#a89b9b'};
label_color = {'wS1'; 'wS2'; 'ALM'; 'wM2'; 'A1'; 'unassigned_area'; 'tjM1'};
Map = horzcat(label_color, colors);

% Define viewing angles for 3D brain plots
view_list = [0, 0;
             90, 0;
             0, 89;
             -45.9898, 14.3886];

%% Generate 3D brain views from different angles
for i_view = 1:4
    % Create figure for current view
%     parent = figure('Units', 'centimeters', ...
%                    'Position', [1 1 21 29.7], ...
%                    'PaperType', 'A4', ...
%                    'PaperUnits', 'centimeters', ...
%                    'PaperSize', [21 29.7], ...
%                    'PaperPosition', [1 1 21 29.7]);

    parent = figure('Position', [200 200 1000 800])
    
    % Create subplot with tight spacing
    h = tight_subplot(1, 1, [.07 .07], [.07 .04], [.07 .01]);
    axs = findall(h, 'type', 'axes');
    axs = flipud(axs);
    hold(axs(1), 'on');
    
    % Plot brain grid outline
    [f_3, brain_outline_3] = plotBrainGrid([], axs(1), parent);
    
    % Set subplot positioning and properties
    set(axs(1), 'OuterPosition', [.5 0.1 .8 .8]);
    set(axs(1), 'InnerPosition', [.1 0.1 .8 .8]);
    set(axs(1), 'ZDir', 'reverse');
    
    % Configure 3D view
    axis(axs(1), 'vis3d', 'equal', 'off', 'manual');
    view(axs(1), view_list(i_view, :));
    set(h(1), 'CameraViewAngle', 8);
    
    % Plot bregma reference point
    bregma = allenCCFbregma();
    plot3(h(1), bregma(:, 1), ...
          bregma(:, 3), ...
          bregma(:, 2), ...
          '+', 'color', 'k', 'MarkerSize', 15, 'linewidth', 3);
    
    % Initialize annotation color array
    annotation_color = [];
    
    %% Plot probe tracks for each brain region
    for iarea = 1:length(regionlist)
        CurrentArea = cell2mat(regionlist(iarea));
        iprb = find(strcmp(CurrentArea, [psth_mat.probe_location]));
        indcolor = find(strcmp(CurrentArea, Map(:, 1)));
        annotation_color = [annotation_color; hex2rgb(cell2mat(Map(indcolor, 2)))];
        
        % Plot probe tracks for current area
        for iprobes_Ind = iprb
            points = ([psth_mat(iprobes_Ind).elec_ccf_ap, ...
                      psth_mat(iprobes_Ind).elec_ccf_dv, ...
                      psth_mat(iprobes_Ind).elec_ccf_ml]);
            
            if isempty(points)
                continue;
            end
            
            axes(axs(1));
            line(points(:, 1), points(:, 3), points(:, 2), ...
                'linewidth', 2, 'color', hex2rgb(cell2mat(Map(indcolor, 2))));
        end
    end
end


%% Export figures
directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

outputPDF = [directory name '.pdf'];

% Delete previous version if exists
if exist(outputPDF, 'file')
    delete(outputPDF);
end

% Get all figure handles
figHandles = findall(0, 'Type', 'figure');

% Sort them by figure number (optional)
[~, idx] = sort(arrayfun(@(f) f.Number, figHandles));
figHandles = figHandles(idx);

% Loop over each figure and export to PDF
for i = 1:length(figHandles)
    fig = figHandles(i);
    
    % Export to PDF and append
    exportgraphics(fig, outputPDF, 'ContentType', 'vector', 'Append', true);
end

disp(['All figures saved into: ', outputPDF]);
