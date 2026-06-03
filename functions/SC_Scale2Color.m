function [color]=SC_Scale2Color(value, low_range, high_range, zero)

%% this function assign an RGB color to a data value by scaling linearly
% from black to red then yellow for values above the 'zero' and from black
% to blue then cyan to values below the 'zero'. 
% Values above the 'high_range' will be assigned to yellow (positive saturation).
% Values below the 'low_range will be assigne to cyan (negative saturation).

%% INPUTS:
%% value = the data value to which we assign a color
%% low_range = the values below this threshold will be assigned to cyan
%% high_range = the values above this threshold will be assigned to yellow

if value<low_range
    color=[0.8 0.8 1];
elseif value>=low_range && value<zero
    color_ind=1.8*(zero-value)/abs(low_range);

    if color_ind<=1
        color=[0 0 color_ind];
    else
        color=[(color_ind-1) (color_ind-1) 1];
    end

elseif value>=zero && value<=high_range
    color_ind=2*(value-zero)/high_range;

    if color_ind<=1
        color=[color_ind 0 0];
    else
        color=[1 (color_ind-1) 0];
    end

elseif value> high_range
    color=[1 1 0];
end

end
