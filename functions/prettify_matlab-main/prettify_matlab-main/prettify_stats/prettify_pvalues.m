function prettify_pvalues(ax, x1, x2, pvals, varargin)
% prettify_pvalues: Draw lines and add text for multiple p-values on a plot, with optimal stacking or manual Y-position.
%
% Usage:
%   prettify_pvalues(ax, [x1_1, ...], [x2_1, ...], [pval1, ...], 'param', value, ...)
%
% Inputs:
%   - ax: Axes handle
%   - x1, x2: Vectors of X-coordinates for the start and end of the lines
%   - pvals: Vector of P-values to be displayed
%   - Optional parameters (see below for default values)
%
% Optional Parameters:
%   'Yposition' - scalar or vector of y-positions for the annotation lines/text

% Parse optional parameters
p = inputParser;
addParameter(p, 'TextRotation', 0, @isnumeric);
addParameter(p, 'TextFontSize', 8, @isnumeric);
addParameter(p, 'LineColor', 'k');
addParameter(p, 'LineWidth', 1, @isnumeric);
addParameter(p, 'LineMargin', 0.04, @isnumeric); % vertical margin between lines
addParameter(p, 'TickLength', 0.01, @isnumeric);
addParameter(p, 'TextMargin', 0.01, @isnumeric);
addParameter(p, 'PlotNonSignif', true);
addParameter(p, 'NaNCutoff', 0.05, @isnumeric);
addParameter(p, 'FullDisplayCutoff', 0.001, @isnumeric);
addParameter(p, 'OnlyStars', false);
addParameter(p, 'StarsLevel_1', 0.050, @isnumeric);
addParameter(p, 'StarsLevel_2', 0.010, @isnumeric);
addParameter(p, 'StarsLevel_3', 0.001, @isnumeric);
addParameter(p, 'Yposition', [], @(x) isnumeric(x) && (isempty(x) || numel(x) == numel(pvals) || numel(x) == 1));
parse(p, varargin{:});
params = p.Results;

% Remove non-significant if requested
if ~params.PlotNonSignif
    mask = pvals < params.NaNCutoff & ~isnan(pvals);
    pvals = pvals(mask);
    x1 = x1(mask);
    x2 = x2(mask);
end

hold(ax, 'on');

% Sort by width (widest first)
[~, sortIdx] = sort(abs(x2-x1), 'descend');
x1 = x1(sortIdx);
x2 = x2(sortIdx);
pvals = pvals(sortIdx);

% Find the top of each bar (assume bar plot, get YData from children)
barObjs = findobj(ax, 'Type', 'Bar');
if isempty(barObjs)
    % fallback: use current y-limits
    getBarTop = @(x) ax.YLim(2);
else
    % get all bar tops
    barX = [];
    barY = [];
    for b = 1:length(barObjs)
        barX = [barX; barObjs(b).XData(:)];
        barY = [barY; barObjs(b).YData(:)];
    end
    getBarTop = @(x) getBarTopSafe(x, barX, barY, ax);
end

% For each comparison, stack above the highest involved bar, with margin,
% unless Yposition is provided
if ~isempty(params.Yposition)
    % Start stacking from the user-specified Y0
    y_starts = zeros(size(pvals));
    y_starts(1) = params.Yposition;
    for i = 2:length(pvals)
        y_starts(i) = y_starts(i-1) + params.LineMargin * range(ax.YLim);
    end
else
    y_starts = zeros(size(pvals));
    for i = 1:length(pvals)
        involved_x = linspace(x1(i), x2(i), 10);
        bar_tops = arrayfun(getBarTop, involved_x);
        bar_tops = bar_tops(~isnan(bar_tops));
        if isempty(bar_tops)
            base_y = ax.YLim(2);
        else
            base_y = max(bar_tops);
        end
        if i == 1
            y_starts(i) = base_y + params.LineMargin * range(ax.YLim);
        else
            y_starts(i) = max(base_y + params.LineMargin * range(ax.YLim), y_starts(i-1) + params.LineMargin * range(ax.YLim));
        end
    end
end

% Draw lines and text
for i = 1:length(pvals)
    % Draw main line
    line(ax, [x1(i), x2(i)], [y_starts(i), y_starts(i)], 'Color', params.LineColor, 'LineWidth', params.LineWidth);
    % Draw ticks
    line(ax, [x1(i), x1(i)], [y_starts(i), y_starts(i)-params.TickLength*range(ax.YLim)], 'Color', params.LineColor, 'LineWidth', params.LineWidth);
    line(ax, [x2(i), x2(i)], [y_starts(i), y_starts(i)-params.TickLength*range(ax.YLim)], 'Color', params.LineColor, 'LineWidth', params.LineWidth);

    % Format p-value text
    if pvals(i) >= params.NaNCutoff || isnan(pvals(i))
        pval_text = 'n.s.';
    elseif params.OnlyStars
        if pvals(i) < params.StarsLevel_3
            pval_text = '***';
        elseif pvals(i) < params.StarsLevel_2
            pval_text = '**';
        elseif pvals(i) < params.StarsLevel_1
            pval_text = '*';
        else
            pval_text = '';
        end
    else
        if pvals(i) < params.FullDisplayCutoff
            pval_text = ['p < ', num2str(params.FullDisplayCutoff)];
        else
            pval_text = sprintf('p = %.3f', pvals(i));
        end
    end

    % Add text
    text(mean([x1(i), x2(i)]), y_starts(i) + params.TextMargin*range(ax.YLim), pval_text, ...
        'HorizontalAlignment', 'center', 'Rotation', params.TextRotation, ...
        'FontSize', params.TextFontSize, 'Parent', ax);
end

% Expand ylim if needed
ylim(ax, [ax.YLim(1), max([ax.YLim(2), max(y_starts) + 2*params.TextMargin*range(ax.YLim)])]);
hold(ax, 'off');
end

function y = getBarTopSafe(x, barX, barY, ax)
idx = abs(barX - x) < 1e-6;
if any(idx)
    y = max(barY(idx));
else
    y = NaN; % fallback if no bar at this x
end
end