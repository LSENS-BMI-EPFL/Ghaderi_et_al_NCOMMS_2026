classdef PoseEstimationSeries < types.core.SpatialSeries & types.untyped.GroupClass
% POSEESTIMATIONSERIES Estimated position (x, y) or (x, y, z) of a body part over time.


% REQUIRED PROPERTIES
properties
    confidence; % REQUIRED (single) Confidence or likelihood of the estimated positions, scaled to be between 0 and 1.
end
% OPTIONAL PROPERTIES
properties
    confidence_definition; %  (char) Description of how the confidence was computed, e.g., 'Softmax output of the deep neural network'.
end

methods
    function obj = PoseEstimationSeries(varargin)
        % POSEESTIMATIONSERIES Constructor for PoseEstimationSeries
        varargin = [{'data_conversion' types.util.correctType(1, 'single') 'data_offset' types.util.correctType(0, 'single') 'data_resolution' types.util.correctType(-1, 'single') 'data_unit' 'pixels'} varargin];
        obj = obj@types.core.SpatialSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'confidence',[]);
        addParameter(p, 'confidence_definition',[]);
        addParameter(p, 'data',[]);
        addParameter(p, 'data_continuity',[]);
        addParameter(p, 'data_conversion',[]);
        addParameter(p, 'data_offset',[]);
        addParameter(p, 'data_resolution',[]);
        addParameter(p, 'data_unit',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.confidence = p.Results.confidence;
        obj.confidence_definition = p.Results.confidence_definition;
        obj.data = p.Results.data;
        obj.data_continuity = p.Results.data_continuity;
        obj.data_conversion = p.Results.data_conversion;
        obj.data_offset = p.Results.data_offset;
        obj.data_resolution = p.Results.data_resolution;
        obj.data_unit = p.Results.data_unit;
        if strcmp(class(obj), 'types.ndx_pose.PoseEstimationSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.confidence(obj, val)
        obj.confidence = obj.validate_confidence(val);
    end
    function set.confidence_definition(obj, val)
        obj.confidence_definition = obj.validate_confidence_definition(val);
    end
    %% VALIDATORS
    
    function val = validate_confidence(obj, val)
        val = types.util.checkDtype('confidence', 'single', val);
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
    function val = validate_confidence_definition(obj, val)
        val = types.util.checkDtype('confidence_definition', 'char', val);
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
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'single', val);
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
        validshapes = {[3,Inf], [2,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_data_continuity(obj, val)
        val = types.util.checkDtype('data_continuity', 'char', val);
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
    function val = validate_data_conversion(obj, val)
        val = types.util.checkDtype('data_conversion', 'single', val);
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
    function val = validate_data_offset(obj, val)
        val = types.util.checkDtype('data_offset', 'single', val);
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
    function val = validate_data_resolution(obj, val)
        val = types.util.checkDtype('data_resolution', 'single', val);
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
    function val = validate_data_unit(obj, val)
        val = types.util.checkDtype('data_unit', 'char', val);
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
        refs = export@types.core.SpatialSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if startsWith(class(obj.confidence), 'types.untyped.')
            refs = obj.confidence.export(fid, [fullpath '/confidence'], refs);
        elseif ~isempty(obj.confidence)
            io.writeDataset(fid, [fullpath '/confidence'], obj.confidence, 'forceArray');
        end
        if ~isempty(obj.confidence) && ~isa(obj.confidence, 'types.untyped.SoftLink') && ~isa(obj.confidence, 'types.untyped.ExternalLink') && ~isempty(obj.confidence_definition)
            io.writeAttribute(fid, [fullpath '/confidence/definition'], obj.confidence_definition);
        end
    end
end

end