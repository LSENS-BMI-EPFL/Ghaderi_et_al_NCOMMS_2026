classdef IblSubject < types.core.Subject & types.untyped.GroupClass
% IBLSUBJECT IBL mice data


% OPTIONAL PROPERTIES
properties
    expected_water_ml; %  (single) The expected amount of water in ml.
    last_water_restriction; %  (char) The date of the last water restriction.
    projects; %  (char) The main projects this subject was involved in.
    remaining_water_ml; %  (single) The remaining amount of water in ml.
    responsible_user; %  (char) User ID in charge of the subject.
    session_projects; %  (char) All the other projects this subject was involved in.
    url; %  (char) Extra information about the subject can be found at this URL.
    uuid; %  (char) The full identifier of the subject from the IBL database.
end

methods
    function obj = IblSubject(varargin)
        % IBLSUBJECT Constructor for IblSubject
        obj = obj@types.core.Subject(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'expected_water_ml',[]);
        addParameter(p, 'last_water_restriction',[]);
        addParameter(p, 'projects',[]);
        addParameter(p, 'remaining_water_ml',[]);
        addParameter(p, 'responsible_user',[]);
        addParameter(p, 'session_projects',[]);
        addParameter(p, 'url',[]);
        addParameter(p, 'uuid',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.expected_water_ml = p.Results.expected_water_ml;
        obj.last_water_restriction = p.Results.last_water_restriction;
        obj.projects = p.Results.projects;
        obj.remaining_water_ml = p.Results.remaining_water_ml;
        obj.responsible_user = p.Results.responsible_user;
        obj.session_projects = p.Results.session_projects;
        obj.url = p.Results.url;
        obj.uuid = p.Results.uuid;
        if strcmp(class(obj), 'types.ndx_ibl.IblSubject')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.expected_water_ml(obj, val)
        obj.expected_water_ml = obj.validate_expected_water_ml(val);
    end
    function set.last_water_restriction(obj, val)
        obj.last_water_restriction = obj.validate_last_water_restriction(val);
    end
    function set.projects(obj, val)
        obj.projects = obj.validate_projects(val);
    end
    function set.remaining_water_ml(obj, val)
        obj.remaining_water_ml = obj.validate_remaining_water_ml(val);
    end
    function set.responsible_user(obj, val)
        obj.responsible_user = obj.validate_responsible_user(val);
    end
    function set.session_projects(obj, val)
        obj.session_projects = obj.validate_session_projects(val);
    end
    function set.url(obj, val)
        obj.url = obj.validate_url(val);
    end
    function set.uuid(obj, val)
        obj.uuid = obj.validate_uuid(val);
    end
    %% VALIDATORS
    
    function val = validate_expected_water_ml(obj, val)
        val = types.util.checkDtype('expected_water_ml', 'single', val);
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
    function val = validate_last_water_restriction(obj, val)
        val = types.util.checkDtype('last_water_restriction', 'char', val);
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
    function val = validate_projects(obj, val)
        val = types.util.checkDtype('projects', 'char', val);
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
    function val = validate_remaining_water_ml(obj, val)
        val = types.util.checkDtype('remaining_water_ml', 'single', val);
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
    function val = validate_responsible_user(obj, val)
        val = types.util.checkDtype('responsible_user', 'char', val);
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
    function val = validate_session_projects(obj, val)
        val = types.util.checkDtype('session_projects', 'char', val);
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
    function val = validate_uuid(obj, val)
        val = types.util.checkDtype('uuid', 'char', val);
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
        refs = export@types.core.Subject(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.expected_water_ml)
            if startsWith(class(obj.expected_water_ml), 'types.untyped.')
                refs = obj.expected_water_ml.export(fid, [fullpath '/expected_water_ml'], refs);
            elseif ~isempty(obj.expected_water_ml)
                io.writeDataset(fid, [fullpath '/expected_water_ml'], obj.expected_water_ml);
            end
        end
        if ~isempty(obj.last_water_restriction)
            if startsWith(class(obj.last_water_restriction), 'types.untyped.')
                refs = obj.last_water_restriction.export(fid, [fullpath '/last_water_restriction'], refs);
            elseif ~isempty(obj.last_water_restriction)
                io.writeDataset(fid, [fullpath '/last_water_restriction'], obj.last_water_restriction);
            end
        end
        if ~isempty(obj.projects)
            if startsWith(class(obj.projects), 'types.untyped.')
                refs = obj.projects.export(fid, [fullpath '/projects'], refs);
            elseif ~isempty(obj.projects)
                io.writeDataset(fid, [fullpath '/projects'], obj.projects, 'forceArray');
            end
        end
        if ~isempty(obj.remaining_water_ml)
            if startsWith(class(obj.remaining_water_ml), 'types.untyped.')
                refs = obj.remaining_water_ml.export(fid, [fullpath '/remaining_water_ml'], refs);
            elseif ~isempty(obj.remaining_water_ml)
                io.writeDataset(fid, [fullpath '/remaining_water_ml'], obj.remaining_water_ml);
            end
        end
        if ~isempty(obj.responsible_user)
            if startsWith(class(obj.responsible_user), 'types.untyped.')
                refs = obj.responsible_user.export(fid, [fullpath '/responsible_user'], refs);
            elseif ~isempty(obj.responsible_user)
                io.writeDataset(fid, [fullpath '/responsible_user'], obj.responsible_user);
            end
        end
        if ~isempty(obj.session_projects)
            if startsWith(class(obj.session_projects), 'types.untyped.')
                refs = obj.session_projects.export(fid, [fullpath '/session_projects'], refs);
            elseif ~isempty(obj.session_projects)
                io.writeDataset(fid, [fullpath '/session_projects'], obj.session_projects, 'forceArray');
            end
        end
        if ~isempty(obj.url)
            if startsWith(class(obj.url), 'types.untyped.')
                refs = obj.url.export(fid, [fullpath '/url'], refs);
            elseif ~isempty(obj.url)
                io.writeDataset(fid, [fullpath '/url'], obj.url);
            end
        end
        if ~isempty(obj.uuid)
            if startsWith(class(obj.uuid), 'types.untyped.')
                refs = obj.uuid.export(fid, [fullpath '/uuid'], refs);
            elseif ~isempty(obj.uuid)
                io.writeDataset(fid, [fullpath '/uuid'], obj.uuid);
            end
        end
    end
end

end