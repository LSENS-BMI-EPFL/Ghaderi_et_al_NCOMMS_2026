%% =========================================================================
% Ghaderi2025_ExtendedData_Figure13_c_vectorangle_oversession.m
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
% Code Author: Parviz Ghaderi 
% =========================================================================

%% Load attractor analysis results and original data
% clear all
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

% load([directory filesep 'processed_data' filesep 'psth_10ms.mat'])
load([directory filesep 'processed_data' filesep 'pc_projections.mat']) 

%% ----- Parameters -----
regionlist   = {'A1','wS1','wS2','wM2','ALM'};

% Time window for vector field (same as before)
analysis_start_ms = 800;   % ms relative to audio (audio = 0, whisker = 1000)
analysis_end_ms   = 1000;

audio_bin   = 100;         % index of audio time in PC time
whisker_bin = 200;         % index of whisker time in PC time

bin_size_ms      = 10;
bandwidth_factor = 0.1;    % smoothing for velocity on grid
n_grid           = 100;    % grid resolution in PC space

% Profile parameters
ext_factor = 1;   % extend before and after by this fraction of whisker distance
Nbins      = 50;    % number of bins along the line
colors     = [0 0 1; 1 0 0];   % [cond1 blue; cond2 red]

% Convert ms window to bins (relative to full PSTH time)
analysis_start_bin = max(1, round((analysis_start_ms + 1000)/bin_size_ms));
analysis_end_bin   = round((analysis_end_ms   + 1000)/bin_size_ms);

%% ----- Figure: one row × 5 columns -----
figure('Units','centimeters','Position',[1 1 60 10], ...
       'PaperType','A4','PaperUnits','centimeters', ...
       'PaperSize',[21 29.7],'PaperPosition',[1 1 20 8]);

h = tight_subplot(1,5,[.09 .04],[.18 .08],[.08 .02]);  % 1 row, 5 cols

%% ===== Loop over areas =====
for ind_area = 1:length(regionlist)

    curr_area  = regionlist{ind_area};
    sessions   = attractor_results.(curr_area).sessions;
    n_sessions = numel(sessions);

    fprintf('\n=== %s: %d sessions ===\n', curr_area, n_sessions);

    % Store one profile per session (rows = sessions, cols = bins)
    all_profiles = NaN(n_sessions, Nbins);

    %% --- Loop over sessions in this area ---
    for isess = 1:n_sessions

        sess = sessions(isess);

        % Use condition 1 to define time range (all conditions share same length)
        trial_traj_example = sess.conditions(1).trial_trajectories_pc;
        [~, ~, n_timebins_example] = size(trial_traj_example);

       

        actual_end   = min(analysis_end_bin, n_timebins_example);
        actual_start = min(analysis_start_bin, n_timebins_example - 1);
        analysis_bins = actual_start:actual_end;

        % --- Collect trajectories of both conditions in this session ---
        trial_traj_tot = [];
        for cond = 1:2
            trial_traj_cond = sess.conditions(cond).trial_trajectories_pc(:,:,analysis_bins);
            trial_traj_tot  = cat(1, trial_traj_tot, trial_traj_cond);
        end

        [I,J,K] = size(trial_traj_tot);
        tot_position = reshape(permute(trial_traj_tot,[1 3 2]), I*K, J); % (samples x 2)

        % --- Build PC grid for this session ---
        pc1_range = [min(tot_position(:,1)), max(tot_position(:,1))];
        pc2_range = [min(tot_position(:,2)), max(tot_position(:,2))];

        % small margin
        pc1_margin = 0.1 * diff(pc1_range);
        pc2_margin = 0.1 * diff(pc2_range);
        pc1_range  = pc1_range + [-pc1_margin pc1_margin];
        pc2_range  = pc2_range + [-pc2_margin pc2_margin];

        % clamp (optional, same as before)
        % pc1_range = [-3 3];
        % pc2_range = [-3 3];

        [pc1_grid, pc2_grid] = meshgrid( ...
            linspace(pc1_range(1), pc1_range(2), n_grid), ...
            linspace(pc2_range(1), pc2_range(2), n_grid));

        grid_spacing_pc1 = (pc1_range(2) - pc1_range(1)) / (n_grid - 1);
        grid_spacing_pc2 = (pc2_range(2) - pc2_range(1)) / (n_grid - 1);
        band_width       = 2 * mean([grid_spacing_pc1, grid_spacing_pc2]);  % strip width

        % Containers for vector fields and whisker positions
        dpc1_grid_all = cell(1,2);
        dpc2_grid_all = cell(1,2);
        whisker_pos   = NaN(2,2);   % [cond, (PC1 PC2)]

        %% --- Build vector fields for both conditions in this session ---
        for cond = 1:2

            trial_traj = sess.conditions(cond).trial_trajectories_pc;
            [n_trials, ~, n_timebins_cond] = size(trial_traj);

            % ensure analysis bins valid for this condition
            actual_end_c   = min(actual_end,   n_timebins_cond);
            actual_start_c = min(actual_start, n_timebins_cond - 1);
            bins_c         = actual_start_c:actual_end_c;

            % Collect positions and velocities
            all_positions  = [];
            all_velocities = [];

            for itrial = 1:n_trials
                for idx = 1:length(bins_c)-1
                    itime      = bins_c(idx);
                    itime_next = bins_c(idx+1);
                    pc1_t    = trial_traj(itrial,1,itime);
                    pc2_t    = trial_traj(itrial,2,itime);
                    pc1_next = trial_traj(itrial,1,itime_next);
                    pc2_next = trial_traj(itrial,2,itime_next);

                    dpc1 = pc1_next - pc1_t;
                    dpc2 = pc2_next - pc2_t;

                    all_positions  = [all_positions;  pc1_t, pc2_t];
                    all_velocities = [all_velocities; dpc1, dpc2];
                end
            end

            % Kernel-weighted velocity field
            dpc1_grid = NaN(n_grid,n_grid);
            dpc2_grid = NaN(n_grid,n_grid);

            smooth_radius = bandwidth_factor * min(diff(pc1_range), diff(pc2_range));
            sigma         = smooth_radius / 2;

            for i = 1:n_grid
                for j = 1:n_grid
                    gp = [pc1_grid(i,j), pc2_grid(i,j)];

                    distances = sqrt(sum((all_positions - gp).^2, 2));
                    weights   = exp(-(distances.^2)/(2*sigma^2));

                    valid_idx   = weights > exp(-4.5);   % within about 3*sigma
                    n_neighbors = sum(valid_idx);

                    if n_neighbors >= 3
                        wv = weights(valid_idx);
                        wv = wv / sum(wv);
                        dpc1_grid(i,j) = sum(wv .* all_velocities(valid_idx,1));
                        dpc2_grid(i,j) = sum(wv .* all_velocities(valid_idx,2));
                    end
                end
            end

            dpc1_grid_all{cond} = dpc1_grid;
            dpc2_grid_all{cond} = dpc2_grid;

            % Mean trajectory to locate whisker point
            mean_pc1_full = squeeze(mean(trial_traj(:,1,:),1));
            mean_pc2_full = squeeze(mean(trial_traj(:,2,:),1));

            idx_whisker = whisker_bin;
            whisker_pos(cond,:) = [mean_pc1_full(idx_whisker), ...
                                   mean_pc2_full(idx_whisker)];
        end % cond loop

 
        %% --- Angle map between vector fields for this session ---
        U1 = dpc1_grid_all{1};
        V1 = dpc2_grid_all{1};
        U2 = dpc1_grid_all{2};
        V2 = dpc2_grid_all{2};

        valid = ~isnan(U1) & ~isnan(V1) & ~isnan(U2) & ~isnan(V2);
        if ~any(valid(:))
            fprintf('  %s: session %d skipped (no valid grid points)\n', ...
                    curr_area, isess);
            continue;
        end

        dot12 = U1.*U2 + V1.*V2;
        mag1  = sqrt(U1.^2 + V1.^2);
        mag2  = sqrt(U2.^2 + V2.^2);

        cosTheta = dot12 ./ (mag1 .* mag2);
        cosTheta(~valid) = NaN;
        % cosTheta = max(min(cosTheta,1),-1);
        angleDeg = acosd(cosTheta);           % 0..180

        %% --- 1D profile along line between whisker points (this session) ---
        p1 = whisker_pos(1,:);      % cond1 whisker
        p2 = whisker_pos(2,:);      % cond2 whisker
        v  = p2 - p1;
        L  = norm(v);

        % if L <= 0
        %     fprintf('  %s: session %d skipped (zero whisker distance)\n', ...
        %             curr_area, isess);
        %     continue;
        % end

        u = v / L;   % unit direction

        % Flatten grid and angle map
        gx        = pc1_grid(:);
        gy        = pc2_grid(:);
        ang_flat  = angleDeg(:);

        mask_valid = ~isnan(ang_flat);
        gx        = gx(mask_valid);
        gy        = gy(mask_valid);
        ang_flat  = ang_flat(mask_valid);

        % Vector from p1 to each grid point
        diff_vec = [gx - p1(1), gy - p1(2)];

        % Distance along the line (can be <0, >L)
        s = diff_vec * u';

        % Extended segment: [-ext_factor*L, (1+ext_factor)*L]
        s_min = -ext_factor * L;
        s_max = (1 + ext_factor) * L;

        mask_ext = (s >= s_min) & (s <= s_max);
        diff_vec = diff_vec(mask_ext,:);
        ang_flat = ang_flat(mask_ext);
        s        = s(mask_ext);

        if isempty(s)
            fprintf('  %s: session %d skipped (no points in strip along line)\n', ...
                    curr_area, isess);
            continue;
        end

        % Perpendicular distance to line
        proj      = s * u;
        diff_perp = diff_vec - proj;
        d_perp    = sqrt(sum(diff_perp.^2,2));

        % Keep points inside strip
        mask_strip = d_perp <= band_width;
        s_strip    = s(mask_strip);
        ang_strip  = ang_flat(mask_strip);

        if isempty(s_strip)
            fprintf('  %s: session %d skipped (strip empty)\n', ...
                    curr_area, isess);
            continue;
        end

        % Normalise by L → whisker1 at 0, whisker2 at 1
        s_norm = s_strip / L;

        edges  = linspace(-ext_factor, 1+ext_factor, Nbins+1);
        binIdx = discretize(s_norm, edges);

        mean_angle_profile = accumarray(binIdx(~isnan(binIdx)), ...
                                        ang_strip(~isnan(binIdx)), ...
                                        [Nbins 1], @mean, NaN);

        all_profiles(isess,:) = mean_angle_profile(:).';   % 1 × Nbins

    end % session loop

    %% --- Average profiles across sessions for this area ---
    % n_eff        = sum(~isnan(all_profiles), 1);  % how many sessions per bin
    mean_profile = mean(all_profiles, 1, 'omitnan');
    sem_profile  = (std(all_profiles, 0, 1, 'omitnan'))/sqrt(n_sessions);

        s_centers = 0.5 * (edges(1:end-1) + edges(2:end));


    % MATLAB cannot index like that in one line, so recompute cleanly:
    edges = linspace(-ext_factor, 1+ext_factor, Nbins+1);
    s_centers = 0.5 * (edges(1:end-1) + edges(2:end));

    %% --- Plot mean ± SEM profile for this area ---
    ax = h(ind_area);
    cla(ax); hold(ax,'on');

    mask = ~isnan(mean_profile);
    x_plot = s_centers(mask);
    y_mean = mean_profile(mask);
    y_up   = (mean_profile + sem_profile);
    y_low  = (mean_profile - sem_profile);

    y_up  = y_up(mask);
    y_low = y_low(mask);

    if ~isempty(x_plot)
        % shaded SEM
        fill(ax, [x_plot fliplr(x_plot)], [y_up fliplr(y_low)], ...
             [0 0 0], 'EdgeColor','none', 'FaceAlpha',0.3);

        % mean line
        plot(ax, x_plot, y_mean, 'k-', 'LineWidth',2);
    end

    % baseline
    % yline(ax, 0);

    % whisker markers at x=0 and x=1 (on baseline)
    plot(ax, 0, 0, 'ro', 'MarkerSize',8, 'MarkerFaceColor','r');
    plot(ax, 1, 0, 'bo', 'MarkerSize',8, 'MarkerFaceColor','b');

    xlabel(ax, 'normalised distance (0=whisker cond1, 1=whisker cond2)');
    ylabel(ax, 'mean angle difference (deg)');
    xlim(ax, [-ext_factor, 1+ext_factor]);
    ylim(ax,[0 180])
    title(ax, sprintf('%s (n=%d sessions)', curr_area, n_sessions));
yticklabels(ax,get(ax,'YTick'))
end % area loop

%% Export figure
directory=[CurrentDir filesep 'Supplementary_figures_pdf' filesep];

% Export as PDF with vector graphics
exportgraphics(gcf, [directory name '.pdf'], 'ContentType', 'vector');

