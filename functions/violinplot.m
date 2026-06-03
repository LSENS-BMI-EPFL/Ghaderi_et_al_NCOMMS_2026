function violinplot(data, groupLabels,bandwidth)
    % VIOLINPLOT - Custom implementation of a violin plot with non-intersecting groups
    % Inputs:
    %   data: Matrix of data, where each column is a group.
    %   groupLabels: Cell array of group labels for the x-axis.

    % Check inputs
    if nargin < 2
        groupLabels = cellstr(num2str((1:size(data, 2))'));
    end

    % Initialize the plot
    hold on;
    colors = lines(size(data, 2)); % Use a different color for each group

    % Adjust group positions on the x-axis for spacing
    xPositions = linspace(1, size(data, 2) * 2, size(data, 2)); % Spread violins further apart

    for i = 1:size(data, 2)
        % Get data for the current group
        groupData = data(:, i);
        groupData = groupData(~isnan(groupData)); % Remove NaN values

        % Adjust the bandwidth for smoother density

        % Compute KDE for the density
        [density, value] = ksdensity(groupData, 'Bandwidth', bandwidth);
        density = density / max(density); % Normalize density

        % Plot the violin shape
        fill([xPositions(i) - density, flip(xPositions(i) + density)], ...
             [value, flip(value)], colors(i, :), ...
             'FaceAlpha', 0.5, 'EdgeColor', 'none');

        % Overlay data points (scatter plot)
        jitter = (rand(size(groupData)) - 0.5) * 0.4; % Add jitter for visibility
        scatter(xPositions(i) + jitter, groupData, 15, 'k', 'filled', 'MarkerFaceAlpha', 0.5);

        % Plot summary statistics (median and IQR)
        med = median(groupData);
        q1 = prctile(groupData, 25);
        q3 = prctile(groupData, 75);
        plot([xPositions(i) - 0.2, xPositions(i) + 0.2], [med, med], 'w', 'LineWidth', 2); % Median
        plot([xPositions(i), xPositions(i)], [q1, q3], 'w', 'LineWidth', 2); % IQR line
    end

    % Formatting
    xlim([min(xPositions) - 3, max(xPositions) + 3]); % More space on the left and right sides
    xticks(xPositions);
    xticklabels(groupLabels);
end
