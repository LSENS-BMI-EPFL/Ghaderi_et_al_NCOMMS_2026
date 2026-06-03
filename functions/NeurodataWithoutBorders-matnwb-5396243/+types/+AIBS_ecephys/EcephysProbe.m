classdef EcephysProbe < types.core.ElectrodeGroup & types.untyped.GroupClass
% ECEPHYSPROBE A group consisting of the channels on a single neuropixels probe.


% READONLY PROPERTIES
properties(SetAccess = protected)
    help; %  (char) Value is 'Metadata about a physical grouping of channels'
end
% OPTIONAL PROPERTIES
properties
    has_lfp_data; %  (logical) indicates availability of lfp data
    lfp_sampling_rate; %  (double) the (probably reduced) sampling rate at which lfp data were acquired on this probe's channels
    sampling_rate; %  (double) the sampling rate at which data were acquired on this probe's channels
end

methods
    function obj = EcephysProbe(varargin)
        % ECEPHYSPROBE Constructor for EcephysProbe
        varargin = [{'help' 'A physical grouping of channels'} varargin];
        obj = obj@types.core.ElectrodeGroup(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        addParameter(p, 'device',[]);
        addParameter(p, 'has_lfp_data',[]);
        addParameter(p, 'help',[]);
        addParameter(p, 'lfp_sampling_rate',[]);
        addParameter(p, 'location',[]);
        addParameter(p, 'sampling_rate',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        obj.device = p.Results.device;
        obj.has_lfp_data = p.Results.has_lfp_data;
        obj.help = p.Results.help;
        obj.lfp_sampling_rate = p.Results.lfp_sampling_rate;
        obj.location = p.Results.location;
        obj.sampling_rate = p.Results.sampling_rate;
        if strcmp(class(obj), 'types.AIBS_ecephys.EcephysProbe')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.has_lfp_data(obj, val)
        obj.has_lfp_data = obj.validate_has_lfp_data(val);
    end
    function set.lfp_sampling_rate(obj, val)
        obj.lfp_sampling_rate = obj.validate_lfp_sampling_rate(val);
    end
    function set.sampling_rate(obj, val)
        obj.sampling_rate = obj.validate_sampling_rate(val);
    end
    %% VALIDATORS
    
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_device(obj, val)
        val = types.util.checkDtype('device', 'types.core.Device', val);
    end
    function val = validate_has_lfp_data(obj, val)
        val = types.util.checkDtype('has_lfp_data', 'logical', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_lfp_sampling_rate(obj, val)
        val = types.util.checkDtype('lfp_sampling_rate', 'double', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_location(obj, val)
        val = types.util.checkDtype('location', 'char', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_sampling_rate(obj, val)
        val = types.util.checkDtype('sampling_rate', 'double', val);
        if isa(val, 'types.untyped.DataStub')
            if 1 == val.ndims
                valsz = [val.dims 1];
            else
                valsz = val.dims;
            end
        elseif istable(val)
            valsz = [height(val) 1];
        elseif ischar(val)
            valsz = [size(val, 1) 1];
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.ElectrodeGroup(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        io.writeAttribute(fid, [fullpath '/has_lfp_data'], obj.has_lfp_data);
        io.writeAttribute(fid, [fullpath '/help'], obj.help);
        io.writeAttribute(fid, [fullpath '/lfp_sampling_rate'], obj.lfp_sampling_rate);
        io.writeAttribute(fid, [fullpath '/sampling_rate'], obj.sampling_rate);
    end
end

end