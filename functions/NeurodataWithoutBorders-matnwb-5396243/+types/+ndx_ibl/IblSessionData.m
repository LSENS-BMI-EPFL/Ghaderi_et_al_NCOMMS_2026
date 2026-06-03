classdef IblSessionData < types.core.LabMetaData & types.untyped.GroupClass
% IBLSESSIONDATA IBL sessions metadata


% OPTIONAL PROPERTIES
properties
    end_time; %  (char) session end time
    extended_qc; %  (char) extended_qc
    json; %  (char) json
    location; %  (char) location
    notes; %  (char) notes dictionary from sessions file
    number; %  (int8) session number
    parent_session; %  (char) parent session
    project; %  (char) project this session is part of
    qc; %  (char) qc
    type; %  (char) type of session
    url; %  (char) url of the session metadata
    wateradmin_session_related; %  (char) wateradmin_session_related
end

methods
    function obj = IblSessionData(varargin)
        % IBLSESSIONDATA Constructor for IblSessionData
        obj = obj@types.core.LabMetaData(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'end_time',[]);
        addParameter(p, 'extended_qc',[]);
        addParameter(p, 'json',[]);
        addParameter(p, 'location',[]);
        addParameter(p, 'notes',[]);
        addParameter(p, 'number',[]);
        addParameter(p, 'parent_session',[]);
        addParameter(p, 'project',[]);
        addParameter(p, 'qc',[]);
        addParameter(p, 'type',[]);
        addParameter(p, 'url',[]);
        addParameter(p, 'wateradmin_session_related',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.end_time = p.Results.end_time;
        obj.extended_qc = p.Results.extended_qc;
        obj.json = p.Results.json;
        obj.location = p.Results.location;
        obj.notes = p.Results.notes;
        obj.number = p.Results.number;
        obj.parent_session = p.Results.parent_session;
        obj.project = p.Results.project;
        obj.qc = p.Results.qc;
        obj.type = p.Results.type;
        obj.url = p.Results.url;
        obj.wateradmin_session_related = p.Results.wateradmin_session_related;
        if strcmp(class(obj), 'types.ndx_ibl.IblSessionData')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.end_time(obj, val)
        obj.end_time = obj.validate_end_time(val);
    end
    function set.extended_qc(obj, val)
        obj.extended_qc = obj.validate_extended_qc(val);
    end
    function set.json(obj, val)
        obj.json = obj.validate_json(val);
    end
    function set.location(obj, val)
        obj.location = obj.validate_location(val);
    end
    function set.notes(obj, val)
        obj.notes = obj.validate_notes(val);
    end
    function set.number(obj, val)
        obj.number = obj.validate_number(val);
    end
    function set.parent_session(obj, val)
        obj.parent_session = obj.validate_parent_session(val);
    end
    function set.project(obj, val)
        obj.project = obj.validate_project(val);
    end
    function set.qc(obj, val)
        obj.qc = obj.validate_qc(val);
    end
    function set.type(obj, val)
        obj.type = obj.validate_type(val);
    end
    function set.url(obj, val)
        obj.url = obj.validate_url(val);
    end
    function set.wateradmin_session_related(obj, val)
        obj.wateradmin_session_related = obj.validate_wateradmin_session_related(val);
    end
    %% VALIDATORS
    
    function val = validate_end_time(obj, val)
        val = types.util.checkDtype('end_time', 'char', val);
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
    function val = validate_extended_qc(obj, val)
        val = types.util.checkDtype('extended_qc', 'char', val);
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
    function val = validate_json(obj, val)
        val = types.util.checkDtype('json', 'char', val);
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
    function val = validate_notes(obj, val)
        val = types.util.checkDtype('notes', 'char', val);
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
    function val = validate_number(obj, val)
        val = types.util.checkDtype('number', 'int8', val);
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
    function val = validate_parent_session(obj, val)
        val = types.util.checkDtype('parent_session', 'char', val);
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
    function val = validate_project(obj, val)
        val = types.util.checkDtype('project', 'char', val);
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
    function val = validate_qc(obj, val)
        val = types.util.checkDtype('qc', 'char', val);
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
    function val = validate_type(obj, val)
        val = types.util.checkDtype('type', 'char', val);
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
    function val = validate_url(obj, val)
        val = types.util.checkDtype('url', 'char', val);
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
    function val = validate_wateradmin_session_related(obj, val)
        val = types.util.checkDtype('wateradmin_session_related', 'char', val);
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
        refs = export@types.core.LabMetaData(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.end_time)
            if startsWith(class(obj.end_time), 'types.untyped.')
                refs = obj.end_time.export(fid, [fullpath '/end_time'], refs);
            elseif ~isempty(obj.end_time)
                io.writeDataset(fid, [fullpath '/end_time'], obj.end_time);
            end
        end
        if ~isempty(obj.extended_qc)
            if startsWith(class(obj.extended_qc), 'types.untyped.')
                refs = obj.extended_qc.export(fid, [fullpath '/extended_qc'], refs);
            elseif ~isempty(obj.extended_qc)
                io.writeDataset(fid, [fullpath '/extended_qc'], obj.extended_qc);
            end
        end
        if ~isempty(obj.json)
            if startsWith(class(obj.json), 'types.untyped.')
                refs = obj.json.export(fid, [fullpath '/json'], refs);
            elseif ~isempty(obj.json)
                io.writeDataset(fid, [fullpath '/json'], obj.json);
            end
        end
        if ~isempty(obj.location)
            if startsWith(class(obj.location), 'types.untyped.')
                refs = obj.location.export(fid, [fullpath '/location'], refs);
            elseif ~isempty(obj.location)
                io.writeDataset(fid, [fullpath '/location'], obj.location);
            end
        end
        if ~isempty(obj.notes)
            if startsWith(class(obj.notes), 'types.untyped.')
                refs = obj.notes.export(fid, [fullpath '/notes'], refs);
            elseif ~isempty(obj.notes)
                io.writeDataset(fid, [fullpath '/notes'], obj.notes, 'forceArray');
            end
        end
        if ~isempty(obj.number)
            if startsWith(class(obj.number), 'types.untyped.')
                refs = obj.number.export(fid, [fullpath '/number'], refs);
            elseif ~isempty(obj.number)
                io.writeDataset(fid, [fullpath '/number'], obj.number);
            end
        end
        if ~isempty(obj.parent_session)
            if startsWith(class(obj.parent_session), 'types.untyped.')
                refs = obj.parent_session.export(fid, [fullpath '/parent_session'], refs);
            elseif ~isempty(obj.parent_session)
                io.writeDataset(fid, [fullpath '/parent_session'], obj.parent_session);
            end
        end
        if ~isempty(obj.project)
            if startsWith(class(obj.project), 'types.untyped.')
                refs = obj.project.export(fid, [fullpath '/project'], refs);
            elseif ~isempty(obj.project)
                io.writeDataset(fid, [fullpath '/project'], obj.project);
            end
        end
        if ~isempty(obj.qc)
            if startsWith(class(obj.qc), 'types.untyped.')
                refs = obj.qc.export(fid, [fullpath '/qc'], refs);
            elseif ~isempty(obj.qc)
                io.writeDataset(fid, [fullpath '/qc'], obj.qc);
            end
        end
        if ~isempty(obj.type)
            if startsWith(class(obj.type), 'types.untyped.')
                refs = obj.type.export(fid, [fullpath '/type'], refs);
            elseif ~isempty(obj.type)
                io.writeDataset(fid, [fullpath '/type'], obj.type);
            end
        end
        if ~isempty(obj.url)
            if startsWith(class(obj.url), 'types.untyped.')
                refs = obj.url.export(fid, [fullpath '/url'], refs);
            elseif ~isempty(obj.url)
                io.writeDataset(fid, [fullpath '/url'], obj.url);
            end
        end
        if ~isempty(obj.wateradmin_session_related)
            if startsWith(class(obj.wateradmin_session_related), 'types.untyped.')
                refs = obj.wateradmin_session_related.export(fid, [fullpath '/wateradmin_session_related'], refs);
            elseif ~isempty(obj.wateradmin_session_related)
                io.writeDataset(fid, [fullpath '/wateradmin_session_related'], obj.wateradmin_session_related, 'forceArray');
            end
        end
    end
end

end