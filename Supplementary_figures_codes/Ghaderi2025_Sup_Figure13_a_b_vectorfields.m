%% =========================================================================
% revision_Figure6A_Sup1.m
% =========================================================================
%
% This script creates vector field visualizations to demonstrate attractor
% dynamics during the delay period.
%
% Vector fields show the flow of neural trajectories in PC space:
% - Arrows: Direction and magnitude of movement
% - Color: Divergence (blue = convergent/attractor, red = divergent)
% - Trajectories: Individual trials overlaid
%
% Code Author: Parviz Ghaderi
% Email: parviz.ghaderi7@gmail.com
% Date: 2025
% =========================================================================

%% Load attractor analysis results and original data
clear all
close all
clc

%% Optional: Change figure name (set to 1 to enable)
change_name = 0;
newname = 'Figure4A_ROC_PSTH_Combined';
fullname = mfilename('fullpath');
inds = regexp(fullname, '\', 'all');
name = fullname(inds(end)+1:end);

if change_name
    movefile([name '.m'], [newname '.m']);
end

%% Load required data

CurrentDir=pwd;
directory=CurrentDir;

load([directory filesep 'processed_data' filesep 'psth_10ms.mat'])
load([directory filesep 'processed_data' filesep 'pc_projections.mat']) 

% Verify data loaded
fprintf('Loaded %d probes from psth_mat\n', length(psth_mat));

%% Parameters
regionlist = {'A1','wS1','wS2','wM2','ALM'};
chosen_simultaneous_session = 3;   % pick 1..9 as you like

%% --- Find simultaneous sessions across areas using sessionID ---

regionlist = {'A1','wS1','wS2','wM2','ALM'};   % keep your list
nAreas     = numel(regionlist);

% 1) Collect all sessionID strings for each area
allSessionIDs = cell(nAreas,1);   % allSessionIDs{ia}{isess} = 'sub-...'

for ia = 1:nAreas
    areaName   = regionlist{ia};
    sessStruct = attractor_results.(areaName).sessions;
    nSess      = numel(sessStruct);

    ids = cell(nSess,1);
    for isess = 1:nSess
        % cond(1) and cond(2) have the same sessionID, so just use cond(1)
        ids{isess} = sessStruct(isess).conditions(1).sessionID;
    end
    allSessionIDs{ia} = ids;
end

% 2) Find sessionIDs that are present in *all* areas
commonIDs = allSessionIDs{1};
for ia = 2:nAreas
    % 'stable' keeps the order of the first input (area 1)
    commonIDs = intersect(commonIDs, allSessionIDs{ia}, 'stable');
end

% 3) Print them so you can see which "global session" is which
fprintf('\nSimultaneous sessions present in ALL areas:\n');
for k = 1:numel(commonIDs)
    fprintf('  %2d: %s\n', k, commonIDs{k});
end
fprintf('\n');


chosenID = commonIDs{chosen_simultaneous_session};

session_list = zeros(1, numel(regionlist));
for ia = 1:numel(regionlist)
    ids = allSessionIDs{ia};                 % sessionID list for this area
    idx = find(strcmp(ids, chosenID), 1);    % local session index
    session_list(ia) = idx;
    fprintf('Area %-3s -> local session %d (ID %s)\n', ...
        regionlist{ia}, idx, chosenID);
end

fprintf('\nUsing GLOBAL session #%d (ID %s)\n\n', ...
    chosen_simultaneous_session, chosenID);


%%
 %close all

    % Focused window: -150ms before audio to +150ms after whisker
    % Audio at 0ms, Whisker at 1000ms
    analysis_start_ms =800;   % 150ms before audio
    analysis_end_ms = 1000;     % 150ms after whisker (1000ms + 150ms)
    audio_bin=[100]
    whisker_bin=200
    period_label = 'Delay Period';
params.plot_full_period=false
bin_size_ms = 10;
colors=[0 0 1;1 0 0]
analysis_start_bin = max(1, round((analysis_start_ms + 1000) / bin_size_ms) );
analysis_end_bin = round((analysis_end_ms + 1000) / bin_size_ms);
bandwidth_factor = 0.1;  % ← CHANGE THIS to test smoothing effect

% Analysis options
params.session_selection = 'best_variance';  % 'first', 'most_trials', 'best_variance'
params.use_interpolation = false;  % Use spline interpolation for smooth trajectories
params.interpolation_step_ms = 10;  % Interpolation step (10ms for smooth curves)
params.use_moving_average = false;  % Apply moving average after interpolation
params.moving_avg_window = 3;  % Window size for moving average (bins)
n_grid = 40;
%% Initialize main figure
figure('Units','centimeters','Position',[1 1 60 15],'PaperType','A4','PaperUnits','centimeters','PaperSize',[21 29.7],'PaperPosition',[1 1 20 25]);
h = tight_subplot(2,5,[.09 .09],[.08 .08],[.1 .01]);
axs = findall(gcf, 'type', 'axes');
axs = flipud(axs);
ind_figuers = [reshape([1:10]',5,2)]';


% Process each brain area
for ind_area = 1:length(regionlist)
    curr_area = cell2mat(regionlist(ind_area));
    selected_session=session_list(ind_area)
    fprintf('\n=== %s ===\n', curr_area);
trial_traj_tot=[];
for ind_condition=[1,2]
    actual_analysis_end = analysis_end_bin;
    actual_analysis_start = analysis_start_bin;

    analysis_bins = actual_analysis_start:actual_analysis_end;

    % Select session (use simultaneous session if available)
    % Get trajectories from selected session
    trial_traj = attractor_results.(curr_area).sessions(selected_session).conditions(ind_condition).trial_trajectories_pc(:,:,analysis_bins);
    trial_traj_tot=cat(1,trial_traj_tot,trial_traj);
end
[I J K]=size(trial_traj_tot)
tot_position= reshape(permute(trial_traj_tot, [1 3 2]), I*K, J);

    dpc1_grid_all = cell(1,2);  % x-component of vector field
    dpc2_grid_all = cell(1,2);  % y-component of vector field
    fixpoints=[]
    for ind_condition=[1,2]
    
    % Select session (use simultaneous session if available)
    % Get trajectories from selected session
    trial_traj = attractor_results.(curr_area).sessions(selected_session).conditions(ind_condition).trial_trajectories_pc;

    % Get actual dimensions
    traj_size = size(trial_traj);
        n_trials = traj_size(1);
        n_pcs = traj_size(2);
        n_timebins_available = traj_size(3);
    
    actual_analysis_end = min(analysis_end_bin, n_timebins_available);
    actual_analysis_start = min(analysis_start_bin, n_timebins_available - 1);

    analysis_bins = actual_analysis_start:actual_analysis_end;
    


    
    %% Collect all positions and velocities during analysis period

    all_positions = [];  % Nx2: [PC1, PC2]
    all_velocities = []; % Nx2: [dPC1/dt, dPC2/dt]
    
    for itrial = 1:n_trials
        % Loop through bins, but ensure i time+1 stays WITHIN analysis_bins
        for idx = 1:length(analysis_bins)-1
            itime = analysis_bins(idx);
            itime_next = analysis_bins(idx+1);
            
            % Verify both bins are within trajectory bounds
            if itime > n_timebins_available || itime_next > n_timebins_available
                continue;
            end
            
            % Position at time t
            pc1_t = trial_traj(itrial, 1, itime);
            pc2_t = trial_traj(itrial, 2, itime);
            
            % Position at time t+1 (WITHIN analysis period)
            pc1_next = trial_traj(itrial, 1, itime_next);
            pc2_next = trial_traj(itrial, 2, itime_next);
            
            % Velocity (change per bin)
            dpc1 = pc1_next - pc1_t;
            dpc2 = pc2_next - pc2_t;
            
            all_positions = [all_positions; pc1_t, pc2_t];
            all_velocities = [all_velocities; dpc1, dpc2];
        end
    end
    


    
    %% Create grid for vector field
    pc1_range = [min(tot_position(:,1)), max(tot_position(:,1))];
    pc2_range = [min(tot_position(:,2)), max(tot_position(:,2))];
    
    % Expand by 10% for margin
    pc1_margin = 0.1 * diff(pc1_range);
    pc2_margin = 0.1 * diff(pc2_range);
    pc1_range = pc1_range + [-pc1_margin, pc1_margin];
    pc2_range = pc2_range + [-pc2_margin, pc2_margin];
    
    pc1_range =[-3,3];
    pc2_range = [-3,3];


    % Create grid (20x20)
    [pc1_grid, pc2_grid] = meshgrid(linspace(pc1_range(1), pc1_range(2), n_grid), ...
                                      linspace(pc2_range(1), pc2_range(2), n_grid));
    
    % Estimate velocity at each grid point using Gaussian-weighted average
    dpc1_grid = zeros(n_grid, n_grid);
    dpc2_grid = zeros(n_grid, n_grid);
    
    % Smoothing parameter (bandwidth)
    % Try different values: 0.15 (less smooth), 0.25 (current), 0.35 (more smooth)
    smooth_radius = bandwidth_factor * min(diff(pc1_range), diff(pc2_range));
    
    
    % Check typical grid spacing
    grid_spacing_pc1 = (pc1_range(2) - pc1_range(1)) / (n_grid - 1);
    grid_spacing_pc2 = (pc2_range(2) - pc2_range(1)) / (n_grid - 1);

    n_insufficient_data = 0;
    neighbor_counts = zeros(n_grid, n_grid);
    
    for i = 1:n_grid
        for j = 1:n_grid
            grid_point = [pc1_grid(i,j), pc2_grid(i,j)];
            
            % Find nearby data points
            distances = sqrt(sum((all_positions - grid_point).^2, 2));
            
            % Gaussian weighting (closer points = higher weight)
            sigma = smooth_radius / 2;
            weights = exp(-(distances.^2) / (2*sigma^2));
            
            % Only use points within 3*sigma
            valid_idx = weights > exp(-4.5);  % 3*sigma threshold
            n_neighbors = sum(valid_idx);
            neighbor_counts(i,j) = n_neighbors;
            
            if n_neighbors >= 3
                weights_valid = weights(valid_idx);
                weights_valid = weights_valid / sum(weights_valid);
                
                dpc1_grid(i,j) = sum(weights_valid .* all_velocities(valid_idx, 1));
                dpc2_grid(i,j) = sum(weights_valid .* all_velocities(valid_idx, 2));
            else
                dpc1_grid(i,j) = NaN;
                dpc2_grid(i,j) = NaN;
                n_insufficient_data = n_insufficient_data + 1;
            end
        end
    end
    


    %% Plot vector field (arrows)
    hq(1,ind_area)=quiver(axs(ind_figuers(1,ind_area)),pc1_grid, ...
           pc2_grid, ...
           dpc1_grid, ...
           dpc2_grid, ...
           2, 'color',colors(ind_condition,:), 'LineWidth', 1);
    hold(axs(ind_figuers(1,ind_area)),'on')



    % axis tight equal
% axis equal
    dpc1_grid_all{ind_condition} = dpc1_grid;
    dpc2_grid_all{ind_condition} = dpc2_grid;


    mean_pc1 = squeeze(mean(trial_traj(:, 1, analysis_bins), 1));
    mean_pc2 = squeeze(mean(trial_traj(:, 2, analysis_bins), 1));
 
    mean_pc1_full = squeeze(mean(trial_traj(:, 1, :), 1));
    mean_pc2_full = squeeze(mean(trial_traj(:, 2, :), 1));
    hold (axs(ind_figuers(2,ind_area)),"on")

    % AUDIO marker at time = 0ms (ALWAYS plot this)
    % [~, audio_bin] = min(abs(all_times - audio_ms));
       plot(axs(ind_figuers(1,ind_area)),mean(mean_pc1_full(audio_bin)), mean(mean_pc2_full(audio_bin)), 's', 'MarkerSize', 10, 'MarkerFaceColor', colors(ind_condition,:),'MarkerEdgeColor',colors(ind_condition,:));
        % text(mean_pc1_full(audio_bin), mean_pc2_full(audio_bin), ' Audio(0s)', 'Color', 'w', 'FontSize', 10, 'FontWeight', 'bold');
        au(ind_condition)=  plot(axs(ind_figuers(2,ind_area)),mean_pc1_full(audio_bin), mean_pc2_full(audio_bin), 's', 'MarkerSize', 10, 'MarkerFaceColor', colors(ind_condition,:),'MarkerEdgeColor',colors(ind_condition,:));

    
% Whisker marker at time = 0ms (ALWAYS plot this)
        plot(axs(ind_figuers(1,ind_area)),mean_pc1_full(whisker_bin), mean_pc2_full(whisker_bin), 'o', 'MarkerSize', 10, 'MarkerFaceColor', colors(ind_condition,:),'MarkerEdgeColor',colors(ind_condition,:));
        % text(mean_pc1_full(whisker_bin), mean_pc2_full(whisker_bin), ' Whisker(1s)', 'Color', 'k', 'FontSize', 10, 'FontWeight', 'bold');
        wh(ind_condition)=  plot(axs(ind_figuers(2,ind_area)),mean_pc1_full(whisker_bin), mean_pc2_full(whisker_bin), 'o', 'MarkerSize', 10, 'MarkerFaceColor', colors(ind_condition,:),'MarkerEdgeColor',colors(ind_condition,:));


    end



        U1 = dpc1_grid_all{1};
        V1 = dpc2_grid_all{1};
        U2 = dpc1_grid_all{2};
        V2 = dpc2_grid_all{2};

        % valid points where both fields have data
        valid = ~isnan(U1) & ~isnan(V1) & ~isnan(U2) & ~isnan(V2);

        % dot product and magnitudes
        dot12 = U1.*U2 + V1.*V2;
        mag1  = sqrt(U1.^2 + V1.^2);
        mag2  = sqrt(U2.^2 + V2.^2);

        cosTheta = dot12 ./ (mag1 .* mag2);
        cosTheta(~valid) = NaN;        % ignore empty cells
        cosTheta = max(min(cosTheta,1),-1);  % numerical safety

        angleDeg = acosd(cosTheta);    % 0° = aligned, 180° = opposite, 90° = orthogonal

        % Simple global numbers
        all_angles = angleDeg(valid);
        mean_angle   = mean(all_angles);
        median_angle = median(all_angles);
        max_angle    = max(all_angles);

        fprintf('  %s: mean angle = %.2f°, median = %.2f°, max = %.2f°\n', ...
            curr_area, mean_angle, median_angle, max_angle);
        % Optional: make a separate map of angle difference
        hc=contourf(axs(ind_figuers(2,ind_area)),pc1_grid, pc2_grid, angleDeg, 500,'LineStyle','none');
        colormap(axs(ind_figuers(2,ind_area)),"bone")
        % colorbar;
        caxis(axs(ind_figuers(2,ind_area)),[0 130]);  % 0° (same direction) to 180° (opposite)
        xlabel(axs(ind_figuers(2,ind_area)),'PC1'); ylabel(axs(ind_figuers(2,ind_area)),'PC2');
        
        
        xlim(axs(ind_figuers(2,ind_area)),[-1 1])
        ylim(axs(ind_figuers(2,ind_area)),[-1 1])
        % axis(axs(ind_figuers(2,ind_area)),'tight') 
        % axis(axs(ind_figuers(2,ind_area)),'equal') 
        title(curr_area)

        
        xlim(axs(ind_figuers(1,ind_area)),[-1 1])
        ylim(axs(ind_figuers(1,ind_area)),[-1 1])
        % axis(axs(ind_figuers(1,ind_area)),'tight') 
        % axis(axs(ind_figuers(1,ind_area)),'equal') 

       uistack(wh(2),'top');
       uistack(wh(1),'top');
       uistack(au(2),'top');
       uistack(au(1),'top');
       % uistack(axs(ind_figuers(2,ind_area)), wh(2,2),'top');
       % % uistack(axs(ind_figuers(2,ind_area)), au(1),'top');
       % % uistack(axs(ind_figuers(2,ind_area)), au(1),'top');


    end
   


    % pick one of the angle-map axes as reference for caxis/colormap
    refAx = axs(ind_figuers(2,4));    % e.g. row 2, column 4

    % get positions of 4th and 5th angle-map axes
    ax4 = axs(ind_figuers(2,4));
    ax5 = axs(ind_figuers(2,5));
    p4  = ax4.Position;   % [x y w h]
    p5  = ax5.Position;

    % choose a rectangle between ax4 and ax5 for the colorbar
    gap   = 0.04;                             % small horizontal margin
    cb_x  = p4(1) + p4(3) + gap;              % right edge of ax4 + gap
    cb_w  = p5(1) - cb_x - gap;               % stop before ax5 - gap
    cb_y  = p4(2);                            % align vertically with row 2
    cb_h  = p4(4);

    % create colorbar, but don't let it resize the reference axis
    oldPos = refAx.Position;
    cb     = colorbar(refAx,'eastoutside');
    refAx.Position = oldPos;                  % restore ref axis size

    % manually place the colorbar in our custom rectangle
    cb.Location = 'manual';
    cb.Position = [cb_x cb_y cb_w cb_h];

    % optional: label
    ylabel(cb,'Angle difference (deg)');


%% Export figure
directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');

