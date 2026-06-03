classdef IblProbes < types.core.Device & types.untyped.GroupClass
% IBLPROBES Neuro Pixels probes


% OPTIONAL PROPERTIES
properties
    id; %  (char) id
    model; %  (char) model
    trajectory_estimate; %  (char) dict containing trajectory info for each probe
end

methods
    function obj = IblProbes(varargin)
        % IBLPROBES Constructor for IblProbes
        obj = obj@types.core.Device(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'id',[]);
        addParameter(p, 'model',[]);
        addParameter(p, 'trajectory_estimate',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.id = p.Results.id;
        obj.model = p.Results.model;
        obj.trajectory_estimate = p.Results.trajectory_estimate;
        if strcmp(class(obj), 'types.ndx_ibl.IblProbes')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.id(obj, val)
        obj.id = obj.validate_id(val);
    end
    function set.model(obj, val)
        obj.model = obj.validate_model(val);
    end
    function set.trajectory_estimate(obj, val)
        obj.trajectory_estimate = obj.validate_trajectory_estimate(val);
    end
    %% VALIDATORS
    
    function val = validate_id(obj, val)
        val = types.util.checkDtype('id', 'char', val);
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
    function val = validate_model(obj, val)
        val = types.util.checkDtype('model', 'char', val);
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
    function val = validate_trajectory_estimate(obj, val)
        val = types.util.checkDtype('trajectory_estimate', 'char', val);
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
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.Device(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.id)
            if startsWith(class(obj.id), 'types.untyped.')
                refs = obj.id.export(fid, [fullpath '/id'], refs);
            elseif ~isempty(obj.id)
                io.writeDataset(fid, [fullpath '/id'], obj.id);
            end
        end
        if ~isempty(obj.model)
            if startsWith(class(obj.model), 'types.untyped.')
                refs = obj.model.export(fid, [fullpath '/model'], refs);
            elseif ~isempty(obj.model)
                io.writeDataset(fid, [fullpath '/model'], obj.model);
            end
        end
        if ~isempty(obj.trajectory_estimate)
            if startsWith(class(obj.trajectory_estimate), 'types.untyped.')
                refs = obj.trajectory_estimate.export(fid, [fullpath '/trajectory_estimate'], refs);
            elseif ~isempty(obj.trajectory_estimate)
                io.writeDataset(fid, [fullpath '/trajectory_estimate'], obj.trajectory_estimate, 'forceArray');
            end
        end
    end
end

end