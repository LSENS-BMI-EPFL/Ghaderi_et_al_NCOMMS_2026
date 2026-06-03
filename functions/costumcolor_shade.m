function custom_map=costumcolor_shade(start_c,end_c,n)

% Create a custom blue colormap with 1000 points
% n = 1000;

% Start color: light blue (e.g., RGB [0.8, 0.9, 1])
% start_c = [0.8, 0.9, 1];  

% End color: deep blue (e.g., RGB [0, 0, 1])
% end_c = [0, 0, 1];

% Interpolate each channel (R, G, B) from start to end
r = linspace(start_c(1), end_c(1), n)';
g = linspace(start_c(2), end_c(2), n)';
b = linspace(start_c(3), end_c(3), n)';

% Combine into one colormap
custom_map = [r, g, b];