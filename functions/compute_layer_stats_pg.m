function [layer_activity_results, statistical_results, summary_table, comparison_table] = ...
    compute_layer_stats_pg(psth_hz, area_all, layer_class, bin_sz)
% COMPUTE_LAYER_STATS_PG
%   MATLAB version of your Python layer-specific statistics.
%
% Inputs:
%   psth_hz      : [N_neurons x N_timebins] firing rates (Hz)
%   area_all     : {N_neurons x 1} area names ('A1','wS1','wS2','wM2','ALM',...)
%   layer_class  : {N_neurons x 1} 'supragranular'/'granular'/'infragranular'
%   bin_sz       : scalar, bin width in seconds (e.g. 0.01)
%
% Outputs:
%   layer_activity_results : struct(area).(layer) -> vector of neuron means
%   statistical_results    : struct(area).comparison -> stats (t,p,d,means,n)
%   summary_table          : table with mean ± SEM per layer & region
%   comparison_table       : table with t, p, d, significance for each pair

%% Time window for analysis (1.8–2.0 s)
time_window_start = 1.8;   % seconds
time_window_end   = 2.0;   % seconds

% Approximate bin indices (similar spirit to Python code)
% We want ~bins 180..200 for bin_sz=0.01
start_bin = round(time_window_start / bin_sz);   % ≈ 180
end_bin   = round(time_window_end   / bin_sz);   % ≈ 200

% MATLAB uses 1-based indexing; we'll use these directly:
fprintf('Analyzing time window: %.2fs to %.2fs\n', ...
        time_window_start, time_window_end);
fprintf('Bin range (MATLAB 1-based): %d to %d\n', start_bin, end_bin);

%% Definitions
brain_areas = {'A1','wS1','wS2','wM2','ALM'};
layer_types = {'supragranular','granular','infragranular'};

layer_activity_results = struct();
statistical_results    = struct();

%% Storage for summary tables
region_col = {};
supra_col  = {};
gran_col   = {};
infra_col  = {};

comp_region_col     = {};
comp_name_col       = {};
comp_t_col          = [];
comp_p_col          = [];
comp_d_col          = [];
comp_signif_col     = {};
comp_n1_col         = [];
comp_n2_col         = [];

fprintf('\n=============================================\n');
fprintf('LAYER-SPECIFIC ACTIVITY ANALYSIS\n');
fprintf('=============================================\n');

%% Loop over brain areas
for iA = 1:numel(brain_areas)
    area_name = brain_areas{iA};
    fprintf('\n--- Analyzing %s ---\n', area_name);

    % Indices of neurons in this area
    idx_area = strcmp(area_all, area_name);
    if ~any(idx_area)
        fprintf('No neurons found in %s\n', area_name);
        continue;
    end

    % PSTH for this area
    psth_area = psth_hz(idx_area, :);          % [n_area_neurons x nTime]
    layers_area = layer_class(idx_area);       % {n_area_neurons x 1}

    layer_activities = struct();

    %% For each layer: compute mean activity per neuron in time window
    for iL = 1:numel(layer_types)
        this_layer = layer_types{iL};

        idx_layer = strcmp(layers_area, this_layer);  % subset within area

        if ~any(idx_layer)
            fprintf('  %s: No neurons found\n', this_layer);
            layer_activities.(this_layer) = [];
            continue;
        end

        psth_layer = psth_area(idx_layer, start_bin:end_bin);  % [n_layer_neurons x nBins]

        % Mean across the time window, per neuron
        neuron_activities = mean(psth_layer, 2, 'omitnan');

        % Drop NaNs
        neuron_activities = neuron_activities(~isnan(neuron_activities));

        layer_activities.(this_layer) = neuron_activities;

        if ~isempty(neuron_activities)
            mean_activity = mean(neuron_activities, 'omitnan');
            std_activity  = std(neuron_activities, 0, 'omitnan');
            fprintf('  %s: %d neurons, mean activity = %.3f ± %.3f\n', ...
                this_layer, numel(neuron_activities), mean_activity, std_activity);
        else
            mean_activity=NaN;
            std_activity=NaN;
            fprintf('  %s: all NaN activities\n', this_layer);
        end
    end

    % Store layer-wise activities
    layer_activity_results.(area_name) = layer_activities;

    %% Pairwise t-tests between layers
    area_stats = struct();

    layer_pairs = {
        'supragranular', 'granular';
        'supragranular', 'infragranular';
        'granular',      'infragranular'
    };

    for iPair = 1:size(layer_pairs,1)
        layer1 = layer_pairs{iPair,1};
        layer2 = layer_pairs{iPair,2};
        data1  = layer_activities.(layer1);
        data2  = layer_activities.(layer2);

        if isempty(data1) || isempty(data2)
            continue;
        end

        % Unpaired t-test (equal variances, like SciPy default)
        [~, p_val, ~, stats_struct] = ttest2(data1, data2, 'Vartype','equal');
        t_stat = stats_struct.tstat;

        % Cohen's d (pooled SD)
        n1 = numel(data1);
        n2 = numel(data2);
        v1 = var(data1, 0, 1);
        v2 = var(data2, 0, 1);

        pooled_std = sqrt(((n1 - 1)*v1 + (n2 - 1)*v2) / (n1 + n2 - 2));
        if pooled_std > 0
            d_val = (mean(data1) - mean(data2)) / pooled_std;
        else
            d_val = 0;
        end

        area_stats.([layer1 '_vs_' layer2]) = struct( ...
            't_stat',   t_stat, ...
            'p_value',  p_val, ...
            'cohens_d', d_val, ...
            'mean1',    mean(data1), ...
            'mean2',    mean(data2), ...
            'n1',       n1, ...
            'n2',       n2);

        % Significance stars
        if     p_val < 0.001, sig_str = '***';
        elseif p_val < 0.01,  sig_str = '**';
        elseif p_val < 0.05,  sig_str = '*';
        else,                 sig_str = '';
        end

        fprintf('    %s vs %s: t=%.3f, p=%.4f%s, d=%.3f\n', ...
            layer1, layer2, t_stat, p_val, sig_str, d_val);

        % Store in comparison table columns
        comp_region_col{end+1,1} = area_name;
        comp_name_col{end+1,1}   = sprintf('%s vs %s', capitalize(layer1), capitalize(layer2));
        comp_t_col(end+1,1)      = t_stat;
        comp_p_col(end+1,1)      = p_val;
        comp_d_col(end+1,1)      = d_val;
        comp_signif_col{end+1,1} = sig_str;
        comp_n1_col(end+1,1)     = n1;
        comp_n2_col(end+1,1)     = n2;
    end

    statistical_results.(area_name) = area_stats;

    %% Summary row for this area (mean ± SEM per layer)
    region_col{end+1,1} = area_name;

    % Helper for one layer


    supra_col{end+1,1} = layer_summary('supragranular',layer_activities);
    gran_col{end+1,1}  = layer_summary('granular',layer_activities);
    infra_col{end+1,1} = layer_summary('infragranular',layer_activities);
end

%% Build summary tables
summary_table = table( ...
    string(region_col), ...
    string(supra_col), ...
    string(gran_col), ...
    string(infra_col), ...
    'VariableNames', {'Region','Supragranular','Granular','Infragranular'});

comparison_table = table( ...
    string(comp_region_col), ...
    string(comp_name_col), ...
    comp_t_col, ...
    comp_p_col, ...
    comp_d_col, ...
    string(comp_signif_col), ...
    comp_n1_col, ...
    comp_n2_col, ...
    'VariableNames', ...
    {'Region','Comparison','t_statistic','p_value','Cohens_d','Significance','n1','n2'});

fprintf('\n=============================================\n');
fprintf('SUMMARY TABLE (mean ± SEM in %.2f–%.2fs window)\n', ...
        time_window_start, time_window_end);
fprintf('=============================================\n');
disp(summary_table);

fprintf('\n=============================================\n');
fprintf('PAIRWISE COMPARISONS (t-tests)\n');
fprintf('=============================================\n');
disp(comparison_table);

end

% ---------------------------------------------------------
function s = capitalize(str_in)
% CAPITALIZE  Make first letter upper-case, rest lower.
str_in = char(str_in);
if isempty(str_in)
    s = "";
    return;
end
s = string(upper(str_in(1)) + lower(str_in(2:end)));
end


function s = layer_summary(layer_name,layer_activities)
if isfield(layer_activities, layer_name)
    vals = layer_activities.(layer_name);
else
    vals = [];
end
if isempty(vals)
    s = "No data";
else
    mu  = mean(vals, 'omitnan');
    sem = std(vals, 0, 'omitnan') / sqrt(numel(vals));
    s = sprintf('%.3f ± %.3f (n=%d)', mu, sem, numel(vals));
end
end