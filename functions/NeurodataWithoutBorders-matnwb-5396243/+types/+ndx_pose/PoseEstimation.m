classdef PoseEstimation < types.core.NWBDataInterface & types.untyped.GroupClass
% POSEESTIMATION Group that holds estimated position data for multiple body parts, computed from the same video with the same tool/algorithm. The timestamps of each child PoseEstimationSeries type should be the same.


% OPTIONAL PROPERTIES
properties
    description; %  (char) Description of the pose estimation procedure and output.
    dimensions; %  (uint8) Dimensions of each labeled video file.
    edges; %  (uint8) Array of pairs of indices corresponding to edges between nodes. Index values correspond to row indices of the 'nodes' dataset. Index values use 0-indexing.
    labeled_videos; %  (char) Paths to the labeled video files. The number of files should equal the number of camera devices.
    nodes; %  (char) Array of body part names corresponding to the names of the PoseEstimationSeries objects within this group.
    original_videos; %  (char) Paths to the original video files. The number of files should equal the number of camera devices.
    poseestimationseries; %  (PoseEstimationSeries) Estimated position data for each body part.
    scorer; %  (char) Name of the scorer / algorithm used.
    source_software; %  (char) Name of the software tool used. Specifying the version attribute is strongly encouraged.
    source_software_version; %  (char) Version string of the software tool used.
end

methods
    function obj = PoseEstimation(varargin)
        % POSEESTIMATION Constructor for PoseEstimation
        obj = obj@types.core.NWBDataInterface(varargin{:});
        [obj.poseestimationseries, ivarargin] = types.util.parseConstrained(obj,'poseestimationseries', 'types.ndx_pose.PoseEstimationSeries', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        addParameter(p, 'dimensions',[]);
        addParameter(p, 'edges',[]);
        addParameter(p, 'labeled_videos',[]);
        addParameter(p, 'nodes',[]);
        addParameter(p, 'original_videos',[]);
        addParameter(p, 'scorer',[]);
        addParameter(p, 'source_software',[]);
        addParameter(p, 'source_software_version',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        obj.dimensions = p.Results.dimensions;
        obj.edges = p.Results.edges;
        obj.labeled_videos = p.Results.labeled_videos;
        obj.nodes = p.Results.nodes;
        obj.original_videos = p.Results.original_videos;
        obj.scorer = p.Results.scorer;
        obj.source_software = p.Results.source_software;
        obj.source_software_version = p.Results.source_software_version;
        if strcmp(class(obj), 'types.ndx_pose.PoseEstimation')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    function set.dimensions(obj, val)
        obj.dimensions = obj.validate_dimensions(val);
    end
    function set.edges(obj, val)
        obj.edges = obj.validate_edges(val);
    end
    function set.labeled_videos(obj, val)
        obj.labeled_videos = obj.validate_labeled_videos(val);
    end
    function set.nodes(obj, val)
        obj.nodes = obj.validate_nodes(val);
    end
    function set.original_videos(obj, val)
        obj.original_videos = obj.validate_original_videos(val);
    end
    function set.poseestimationseries(obj, val)
        obj.poseestimationseries = obj.validate_poseestimationseries(val);
    end
    function set.scorer(obj, val)
        obj.scorer = obj.validate_scorer(val);
    end
    function set.source_software(obj, val)
        obj.source_software = obj.validate_source_software(val);
    end
    function set.source_software_version(obj, val)
        obj.source_software_version = obj.validate_source_software_version(val);
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
    function val = validate_dimensions(obj, val)
        val = types.util.checkDtype('dimensions', 'uint8', val);
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
        validshapes = {[2,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_edges(obj, val)
        val = types.util.checkDtype('edges', 'uint8', val);
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
        validshapes = {[2,Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_labeled_videos(obj, val)
        val = types.util.checkDtype('labeled_videos', 'char', val);
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
    function val = validate_nodes(obj, val)
        val = types.util.checkDtype('nodes', 'char', val);
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
    function val = validate_original_videos(obj, val)
        val = types.util.checkDtype('original_videos', 'char', val);
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
    function val = validate_poseestimationseries(obj, val)
        namedprops = struct();
        constrained = {'types.ndx_pose.PoseEstimationSeries'};
        types.util.checkSet('poseestimationseries', namedprops, constrained, val);
    end
    function val = validate_scorer(obj, val)
        val = types.util.checkDtype('scorer', 'char', val);
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
    function val = validate_source_software(obj, val)
        val = types.util.checkDtype('source_software', 'char', val);
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
    function val = validate_source_software_version(obj, val)
        val = types.util.checkDtype('source_software_version', 'char', val);
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
        refs = export@types.core.NWBDataInterface(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.description)
            if startsWith(class(obj.description), 'types.untyped.')
                refs = obj.description.export(fid, [fullpath '/description'], refs);
            elseif ~isempty(obj.description)
                io.writeDataset(fid, [fullpath '/description'], obj.description);
            end
        end
        if ~isempty(obj.dimensions)
            if startsWith(class(obj.dimensions), 'types.untyped.')
                refs = obj.dimensions.export(fid, [fullpath '/dimensions'], refs);
            elseif ~isempty(obj.dimensions)
                io.writeDataset(fid, [fullpath '/dimensions'], obj.dimensions, 'forceArray');
            end
        end
        if ~isempty(obj.edges)
            if startsWith(class(obj.edges), 'types.untyped.')
                refs = obj.edges.export(fid, [fullpath '/edges'], refs);
            elseif ~isempty(obj.edges)
                io.writeDataset(fid, [fullpath '/edges'], obj.edges, 'forceArray');
            end
        end
        if ~isempty(obj.labeled_videos)
            if startsWith(class(obj.labeled_videos), 'types.untyped.')
                refs = obj.labeled_videos.export(fid, [fullpath '/labeled_videos'], refs);
            elseif ~isempty(obj.labeled_videos)
                io.writeDataset(fid, [fullpath '/labeled_videos'], obj.labeled_videos, 'forceArray');
            end
        end
        if ~isempty(obj.nodes)
            if startsWith(class(obj.nodes), 'types.untyped.')
                refs = obj.nodes.export(fid, [fullpath '/nodes'], refs);
            elseif ~isempty(obj.nodes)
                io.writeDataset(fid, [fullpath '/nodes'], obj.nodes, 'forceArray');
            end
        end
        if ~isempty(obj.original_videos)
            if startsWith(class(obj.original_videos), 'types.untyped.')
                refs = obj.original_videos.export(fid, [fullpath '/original_videos'], refs);
            elseif ~isempty(obj.original_videos)
                io.writeDataset(fid, [fullpath '/original_videos'], obj.original_videos, 'forceArray');
            end
        end
        if ~isempty(obj.poseestimationseries)
            refs = obj.poseestimationseries.export(fid, fullpath, refs);
        end
        if ~isempty(obj.scorer)
            if startsWith(class(obj.scorer), 'types.untyped.')
                refs = obj.scorer.export(fid, [fullpath '/scorer'], refs);
            elseif ~isempty(obj.scorer)
                io.writeDataset(fid, [fullpath '/scorer'], obj.scorer);
            end
        end
        if ~isempty(obj.source_software)
            if startsWith(class(obj.source_software), 'types.untyped.')
                refs = obj.source_software.export(fid, [fullpath '/source_software'], refs);
            elseif ~isempty(obj.source_software)
                io.writeDataset(fid, [fullpath '/source_software'], obj.source_software);
            end
        end
        if ~isempty(obj.source_software) && ~isa(obj.source_software, 'types.untyped.SoftLink') && ~isa(obj.source_software, 'types.untyped.ExternalLink') && ~isempty(obj.source_software_version)
            io.writeAttribute(fid, [fullpath '/source_software/version'], obj.source_software_version);
        end
    end
end

end