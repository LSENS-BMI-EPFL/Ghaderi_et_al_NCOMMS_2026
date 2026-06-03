function [cmap, norm_values] = custom_cmap(low_range, high_range, zero, n_colors)
    if nargin < 4
        n_colors = 256;
    end

    % Preallocate color map
    cmap = zeros(n_colors, 3);
    values = linspace(low_range, high_range, n_colors);
    
    for i = 1:n_colors
        cmap(i, :) = PG_Scale2Color(values(i), low_range, high_range, zero);
    end
    
    % Also return normalized values (optional)
    norm_values = linspace(0, 1, n_colors);
end


function color = PG_Scale2Color(value, low_range, high_range, zero)
    % Define the base colors
    colors = [
        0, 230, 230;  % Cyan for very negative
        0, 25.5, 255; % Dark blue
        0, 0, 0;      % Black at zero
        255, 25.5, 0; % Dark red
        255, 255, 0   % Yellow
    ] / 255; % Normalize to [0,1]
    
    positions = [0.0, 0.3, 0.5, 0.7, 1.0];
    
    % Normalize value to [0, 1]
    if value <= low_range
        norm_val = 0.0;
    elseif value >= high_range
        norm_val = 1.0;
    else
        norm_val = (value - low_range) / (high_range - low_range);
    end

    % Interpolate R, G, and B channels separately
    r = interp1(positions, colors(:,1), norm_val, 'linear');
    g = interp1(positions, colors(:,2), norm_val, 'linear');
    b = interp1(positions, colors(:,3), norm_val, 'linear');
    
    color = [r, g, b];
end
