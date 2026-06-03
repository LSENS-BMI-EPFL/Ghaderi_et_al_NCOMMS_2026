%% =========================================================================
% Ghaderi2025_Figure2_Brainmap.m
% =========================================================================
% 
% This script generates Figure 2 showing brain maps with optogenetic manipulation effects
% for the manuscript "Contextual gating of whisker-evoked responses by frontal cortex supports flexible decision making" 
% (Parviz Ghaderi, Sylvain Crochet, Carl Petersen, 2025)
% 
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
%
% Description: This script creates brain maps showing the effects of optogenetic 
% manipulation across different brain regions and time windows for Hit trials. It plots probe 
% locations and color-codes them based on performance changes during different 
% trial periods (audio, delay, whisker).
%
% Dependencies: 
%   - psth_10ms.mat (contains trial data)
%   - Optoinhibition_mat.mat (contains optogenetic data)
%   - Area_list.mat (contains brain area information)
%   - tight_subplot.m (for subplot management)
%   - allenCCFbregma.m (for brain coordinate system)
%   - tools.hex2rgb.m (for color conversion)
%
% Output: PDF figure showing brain maps with optogenetic effects across time windows
% =========================================================================


%% Clear workspace and set up environment
clear all
close all
clc

%% Load required data

CurrentDir=pwd;
directory=[CurrentDir];

load([directory filesep 'processed_data' filesep 'Optoinhibition_mat.mat'])
load([directory filesep 'data_helpers' filesep 'Area_Top_Coordinates.mat'])


%% Initialize variables and trial type parameters
fiberlist = [];
trialtype_list = [1]; % List of trial types: 1= Go-tone Whisker; 2= Go-tine; 3= Nogo-tone Whisker; 4=Nogo-tone; 5=Whisker
trialname_list = {'Go-tone Whisker'; 'Go-tone'; 'Nogo-tone Whisker'; 'Nogo-tone'; 'Whisker'};


%% Define analysis parameters
    
    % Time window parameters
    t_start = -1;  % Start time
    t_end = 2;     % End time
    bin_width = 0.01;
    XTickLabel = {'-1'; '0'; '1'; '2'};
    xtick = [-1; 0; 1; 2];
    
    % Analysis windows for different trial periods
    window_list = {[0.01, .03]; [.8, 1]; [1.01, 1.03]};  % Audio, delay, whisker periods
    flg = 0;
    
    % Color range for plotting
    range = [-50 20;
             -50 20;
             -50 20];

 %% Define region list coordinates and color scheme
   
    region_list = {'A1', 'wS1', 'wS2', 'wM2', 'ALM', 'fpS1'};
    period_list = {'audio', 'delay', 'whisker'};
    completion_state = 'completed_trials';

    % Color scheme for different brain regions
    colors = {'#0008FF'; '#228B22'; '#FF0000'; '#000000'; '#A020F0'; '#a89b9b'; '#a89b9b'};
    label_color = {'wS1'; 'wS2'; 'ALM'; 'wM2'; 'A1'; 'fpS1'; 'tjM1'};
    Map = horzcat(label_color, colors);
      
    % coordinates for the areas to be plotted
    POINTS = [];

    for i=1:size(region_list,2)
        eval(['POINTS(i,:)=area_top_coordinates.' region_list{1,i} ';'])

    end

%% Loop through trial types (currently only processing trial type 1)

for ind_trialtype = trialtype_list

% Get current trial type information
    current_trial_type = trialtype_list(ind_trialtype);
    current_trialtype_name = cell2mat(trialname_list(ind_trialtype));
    
  
    %% Optional: Change figure name (set to 1 to enable)
    change_name = 0;
    newname = 'Figure3_4_1';
    fullname = mfilename('fullpath');
    inds = regexp(fullname, '\', 'all');
    name = fullname(inds(end)+1:end);
    
    if change_name
        movefile([name '.m'], [newname '.m']);
    end
    
   
    %% Initialize figure and subplot layout    

    parent = figure('Position', [100 100 1200 800]);

    % Create subplot with tight spacing (1 row, 4 columns)
    h = tight_subplot(1, 4, [.01 .01], [.01 .01], [.01 .01]);
    axs = findall(gcf, 'type', 'axes');
    axs = flipud(axs);
   
    
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
          '+', 'color', 'k', 'MarkerSize', 15, 'linewidth', 2);
    
    % Plot reference lines
    xlin = [740 0 570;
            690 0 570];
    plot3(axs(1), xlin(:, 1), ...
          xlin(:, 3), ...
          xlin(:, 2), ...
          '-', 'color', 'k', 'MarkerSize', 1, 'linewidth', 2);
    
    ylin = [740 0 570;
            740 0 520];
    plot3(axs(1), ylin(:, 1), ...
          ylin(:, 3), ...
          ylin(:, 2), ...
          '-', 'color', 'k', 'MarkerSize', 1, 'linewidth', 2);

    flg = 0;
    dY = 1.4;

    hold(h(1), 'on');
          
  %% Plot probe locations for each brain region

    for iarea = 1:length(region_list)
        CurrentArea = cell2mat(region_list(iarea));

        points = POINTS(iarea,:);

        indcolor = find(strcmp(CurrentArea, Map(:, 1)));
        plot3(h(1), points(1, 1), points(1, 3), 0, ...
            'o', 'color', hex2rgb(cell2mat(Map(indcolor, 2))), 'linewidth', 1, 'MarkerSize', 10);


        % Add region label
        text(axs(1), 0, dY, CurrentArea, 'Color', hex2rgb(cell2mat(Map(indcolor, 2))), 'Units', 'normalized');
        dY = dY - .07;
    end
    
    %% Format text elements
    childTexts = findall(axs(1), 'Type', 'Text');
    for thisText = childTexts'
        set(thisText, 'FontSize', 12);
    end
    
    %% Process each time window for optogenetic effects
    flg = 0;
    colors = [];
    
   for window_ind = 1:length(window_list)
    
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
              '+', 'color', 'k', 'MarkerSize', 10, 'linewidth', 2);
        
        % Plot reference lines
        xlin = [740 0 570;
                690 0 570];
        plot3(axs(window_ind + 1), xlin(:, 1), ...
              xlin(:, 3), ...
              xlin(:, 2), ...
              '-', 'color', 'k', 'MarkerSize', 1, 'linewidth', 2);
        
        ylin = [740 0 570;
                740 0 520];
        plot3(axs(window_ind + 1), ylin(:, 1), ...
              ylin(:, 3), ...
              ylin(:, 2), ...
              '-', 'color', 'k', 'MarkerSize', 1, 'linewidth', 2);
            
        
        % Create custom colormap for visualization
        cyn = hex2rgb('#00FFFF', 1);
        
        % For negative values (blue to white)
        vec = [100; 0];
        raw = [1 1 1; 0 0 1];
        map_neg = interp1(vec, raw, linspace(100, 0, 53));
        
        % For positive values (white to red)
        red = hex2rgb('#C51B7D', 1);
        vecg = [0; 100];
        rawg = [1 0 0; 1, 1, 1];
        map2 = interp1(vecg, rawg, linspace(100, 0, 10));
        
        MAP = [rot90(map2'); map_neg];
        map_neg = rot90(MAP');
        
        % Calculate performance differences for each brain region
        num_mice = [];
        diff_mean = [];
        diff_sem = [];
        num_session = [];
        
        for ind_area = 1:length(region_list)
            current_area = cell2mat(region_list(ind_area));
            fiberlist = find(strcmp(current_area, {optomat.fiber_location}));
            performance = [];
            ind_window = window_ind;
            current_window = cell2mat(period_list(ind_window));
            session_counter = 1;
            
            % Process each session in current area
            for ind_session = fiberlist
                Trial = optomat(ind_session).trial_type;
                Lick = optomat(ind_session).lick_flag;
                Windows = optomat(ind_session).opto_window;
                mouse = optomat(ind_session).session_id{1, 1}(5:9);
                
                % Apply trial type filter
                current_trialtype_ind = Trial == current_trial_type;
                
                % Apply optogenetic window filter
                current_optocondition_ind = strcmp(Windows, current_window);
                nolight_optocondition_ind = strcmp(Windows, 'nolight');
                
                % Determine completion state
                switch completion_state
                    case 'completed_trials'
                        completion_state_ind = ~optomat(ind_session).early_lick;
                    case 'early_licks'
                        early_licks_all = optomat(ind_session).early_lick;
                        lick_time = 0 < (optomat(ind_session).lick_time - optomat(ind_session).start_time);
                        completion_state_ind = lick_time & early_licks_all;
                    case 'all_trials'
                        completion_state_ind = ones(length(~optomat(ind_session).early_lick), 1);
                end
                
                % Calculate performance difference (light vs no-light)
                CurrTrialInd = [completion_state_ind & current_trialtype_ind & current_optocondition_ind];
                nolightTrialInd = [completion_state_ind & current_trialtype_ind & nolight_optocondition_ind];
                plick = sum(CurrTrialInd & Lick) / sum(CurrTrialInd) * 100 - sum(nolightTrialInd & Lick) / sum(nolightTrialInd) * 100;
                
                performance(ind_window, session_counter) = plick;
                mice_name(ind_window, session_counter) = {mouse};
                session_counter = session_counter + 1;
            end % End of session loop
            
            % Calculate statistics across sessions
            num_mice(ind_area, :) = [length(unique({mice_name{1, :}}))];
            diff_mean(ind_area, :) = nanmean(performance, 2)';
            diff_sem(ind_area, :) = nanstd(performance, [], 2)' / sqrt(size(performance, 2));
            num_session(ind_area, 1) = size(performance, 2)';
        end % End of area loop
        
        %% Prepare data for plotting
        
        trial_name = strrep(current_trialtype_name, '-', '_');
        trial_name = strrep(trial_name, ' ', '_');
        diff_mean = single(round(diff_mean, 2, "decimals"));
        diff_sem = single(round(diff_sem, 2, "decimals"));
        
        %% Set up color mapping for brain regions
       
        MAX = 20;  % Maximum performance change
        MIN = -50; % Minimum performance change
        zero = 0;
        blue = [0 0 255] / 255;
        
        % Create colormap for negative values (blue to white)
        min_max_scale = [100; 0];
        min_max_rgb_neg = [1 1 1; blue];
        map_neg = interp1(min_max_scale, min_max_rgb_neg, linspace(100, 0, abs(MIN)));
        
        % Create colormap for positive values (white to red)
        red = [255 0 00] / 255;
        min_max_scale = [100; 0];
        min_max_rgb_pos = [1, 1, 1; red];
        map_pos = interp1(min_max_scale, min_max_rgb_pos, linspace(100, 0, abs(MAX)));
        
        clim([MIN, MAX]);
        MAP = [flipud(map_neg); map_pos];
        
        %% Get performance data for current window
        currsig = diff_mean(1:6, ind_window);
        points = POINTS;
        
        %% Plot brain regions with color-coded performance
       
        for i = 1:length(points)
            % Define value range for color mapping
            vmin = MIN;
            vmax = MAX;
            
            % Get performance value for current region
            value = currsig(i);
            
            % Normalize value to [0, 1] range
            normalized_value = (value - vmin) / (vmax - vmin);
            
            % Map to colormap
            cmap = MAP;
            nColors = size(cmap, 1);
            colorIndex = round(normalized_value * (nColors - 1)) + 1;
            colorIndex = max(min(colorIndex, nColors), 1);
            C = cmap(colorIndex, :);
            
            % Plot region with color-coded performance
            plot3(axs(window_ind + 1), points(i, 1), points(i, 3), 0, ...
                  'o', 'color', 'k', 'MarkerFaceColor', C, 'MarkerSize', 10);
            colors(i, :) = C;
        end
        
        %% Create colorbar
        values_vector = linspace(range(window_ind, 1), range(window_ind, 2), MAX - MIN);
        
        % Map colors for colorbar

       for i = 1:length(values_vector)
            value = values_vector(i);
            normalized_value = (value - vmin) / (vmax - vmin);
            cmap = MAP;
            nColors = size(cmap, 1);
            colorIndex = round(normalized_value * (nColors - 1)) + 1;
            colorIndex = max(min(colorIndex, nColors), 1);
            C = cmap(colorIndex, :);
            colors(i, :) = C;
        end
        
        % Create colorbar matrix
        sortedColors = colors;
        thickness = 20;  % Colorbar thickness
        colorBarMatrix = repmat(reshape(sortedColors, [MAX - MIN, 1, 3]), [1, thickness, 1]);
        
        % Position colorbar
        newAxesPosition = [0.35 + flg, 0.85, .02, .09];
        colorBarAxes = axes('Position', newAxesPosition, 'Units', 'normalized');
        imagesc(colorBarMatrix, 'Parent', colorBarAxes);
        
        % Configure colorbar appearance
        set(colorBarAxes, 'YDir', 'normal');
        numTicks = 2;
        tickIndices = round(linspace(1, MAX - MIN, numTicks));
        tickLabels = [arrayfun(@(x) sprintf('%.2f', values_vector(x)), tickIndices, 'UniformOutput', false)]';
        
        set(colorBarAxes, 'YTick', tickIndices);
        set(colorBarAxes, 'YTicklabels', tickLabels);
        set(colorBarAxes, 'XTick', []);
        set(colorBarAxes, 'FontSize', 10, 'TickLength', [0 0]);
        set(colorBarAxes, 'YColor', 'k');
        
        % Add title for current time window
        title(axs(window_ind + 1), period_list(ind_window));
        flg = flg + .3;

    end % End of window loop
    
    %% Add overall title
    sgtitle(current_trialtype_name);

end % End of trial type loop


%% Export figures

directory=[CurrentDir filesep 'Main_figures_pdf' filesep];

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

