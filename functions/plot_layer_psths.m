function plot_layer_psths(ax, psth_hz, neuron_idx, layer_class, ...
    bin_sz, nConds, t_segment, ...
    layer_names, layer_colors, area_name)
%PLOT_LAYER_PSTHS  Grand-average PSTHs per layer for one area.

axes(ax); 
hold(ax, 'on');

rows_all = psth_hz(neuron_idx, :);
layers_all = layer_class(neuron_idx);

segLen = size(rows_all, 2) / nConds;
if mod(size(rows_all,2), nConds) ~= 0
    warning('PSTH length is not divisible by nConds in plot_layer_psths.');
end

for li = 1:numel(layer_names)
    thisLayer = layer_names{li};
    idx_layer = strcmp(layers_all, thisLayer);

    if ~any(idx_layer)
        continue;
    end

    rows_layer = rows_all(idx_layer, :);

    mean_sig = mean(rows_layer, 1, 'omitnan');
    sem_sig  = std(rows_layer, 0, 1, 'omitnan') ./ sqrt(size(rows_layer,1));
    curve_up = mean_sig + sem_sig;
    curve_dn = mean_sig - sem_sig;

    % Show all 5 segments concatenated as in the notebook
    x_seg = t_segment;  % 
    for iCond = 1
        st = (iCond-1)*segLen + 1;
        en = iCond*segLen;

        y_mean  = mean_sig(st:en);
        y_upper = curve_up(st:en);
        y_lower = curve_dn(st:en);

       hPatch= fill([x_seg, fliplr(x_seg)], ...
            [y_lower, fliplr(y_upper)], ...
            layer_colors(li,:), ...
            'FaceAlpha', 0.15, 'EdgeColor','none');
        set(hPatch, 'HandleVisibility', 'off');  
        plot(x_seg, y_mean, 'Color', layer_colors(li,:), 'LineWidth', 1);
    end
end

% Formatting
plot([0 0], ylim, 'k-', 'LineWidth', 1);
plot([1 1], ylim, 'k-', 'LineWidth', 1);
box off;
ax.XTick = [-1 0 1 2];
ax.XLim  = [-1 2];
title(ax, sprintf('%s', area_name));

% Legend on top-right panel only
if strcmp(area_name, 'A1')
    legend(ax, layer_names, 'Location','northeast', 'FontSize',6);
end

ylabel(ax, 'Firing rate (Hz)');
if strcmp(area_name, 'ALM')
    xlabel(ax, 'Time (s)');
end
end
