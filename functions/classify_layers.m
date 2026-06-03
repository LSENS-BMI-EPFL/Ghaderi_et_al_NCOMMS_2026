function layer_out = classify_layers(layer_raw)
%CLASSIFY_LAYERS  Map Allen-style layer strings to
% 'supragranular', 'granular', 'infragranular'.
%
% Input:
%   layer_raw : cell array of strings (original Layer)
% Output:
%   layer_out : cell array of strings ('supragranular' / 'granular' / 'infragranular')

n = numel(layer_raw);
layer_out = cell(n,1);

for i = 1:n
    if iscell(layer_raw)
        s = char(layer_raw{i});
    else
        s = char(layer_raw(i));
    end

    % Clean brackets and spaces
    s = strrep(s,'[','');
    s = strrep(s,']','');
    s = strtrim(s);

    % Apply similar replacements as in the Python notebook
    if contains(s,'6a') || contains(s,'6b') || strcmp(s,'6') || contains(s,'5')
        layer_out{i} = 'infragranular';
    elseif contains(s,'4')
        layer_out{i} = 'granular';
    elseif contains(s,'2/3') || contains(s,'1')
        layer_out{i} = 'supragranular';
    else
        % Fallback if label is weird or missing
        layer_out{i} = 'infragranular';  % or 'unknown'
    end
end
end
