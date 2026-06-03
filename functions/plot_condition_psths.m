function plot_condition_psths(ax, psth_hz, neuron_idx, ...
    bin_sz, nConds, t_segment, ...
    colorcodes, condition_labels, area_name)

axes(ax); 
hold(ax, 'on');

rows = psth_hz(neuron_idx, :);
if isempty(rows)
    title(ax, sprintf('%s (no data)', area_name));
    return;
end

mean_sig = mean(rows, 1, 'omitnan');                % 1 x total_bins
sem_sig  = std(rows, 0, 1, 'omitnan') ./ sqrt(size(rows,1));
curve_up = mean_sig + sem_sig;
curve_dn = mean_sig - sem_sig;

segLen = numel(mean_sig) / nConds;
if mod(numel(mean_sig), nConds) ~= 0
    warning('PSTH length is not divisible by nConds in plot_condition_psths.');
end

for iCond = 1:nConds
    st = (iCond-1)*segLen + 1;
    en = iCond*segLen;

    y_mean  = mean_sig(st:en);
    y_upper = curve_up(st:en);
    y_lower = curve_dn(st:en);

    x_seg = t_segment;  % length segLen

    % Shaded error
    hPatch=fill([x_seg, fliplr(x_seg)], ...
        [y_lower, fliplr(y_upper)], ...
        colorcodes(iCond,:), ...
        'FaceAlpha', 0.2, 'EdgeColor','none');
    set(hPatch, 'HandleVisibility', 'off');  
    % Mean curve
    plot(x_seg, y_mean, 'Color', colorcodes(iCond,:), 'LineWidth', 1);
end

% Formatting
plot([0 0], ylim, 'k-', 'LineWidth', 1);
plot([1 1], ylim, 'k-', 'LineWidth', 1);
box off;
ax.XTick = [-1 0 1 2];
ax.XLim  = [-1 2];
title(ax, sprintf('%s', area_name));
ylabel(ax, 'Firing rate (Hz)');
if strcmp(area_name, 'ALM')
    xlabel(ax, 'Time (s)');
end

% Legend only on the top-left panel
if strcmp(area_name, 'A1')
    legend(ax, condition_labels, 'Location','northeast', 'FontSize',6);
end
end
