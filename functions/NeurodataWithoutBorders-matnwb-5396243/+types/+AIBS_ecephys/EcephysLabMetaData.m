classdef EcephysLabMetaData < types.core.LabMetaData & types.untyped.GroupClass
% ECEPHYSLABMETADATA metadata for ecephys sessions


% OPTIONAL PROPERTIES
properties
    age_in_days; %  (single) age of this subject, in days
    full_genotype; %  (char) long-form description of this subjects genotype
    sex; %  (char) this subjects sex
    specimen_name; %  (char) full name of this specimen
    stimulus_name; %  (char) the name of the stimulus set used for this session
    strain; %  (char) this subjects strain
end

methods
    function obj = EcephysLabMetaData(varargin)
        % ECEPHYSLABMETADATA Constructor for EcephysLabMetaData
        obj = obj@types.core.LabMetaData(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'age_in_days',[]);
        addParameter(p, 'full_genotype',[]);
        addParameter(p, 'sex',[]);
        addParameter(p, 'specimen_name',[]);
        addParameter(p, 'stimulus_name',[]);
        addParameter(p, 'strain',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.age_in_days = p.Results.age_in_days;
        obj.full_genotype = p.Results.full_genotype;
        obj.sex = p.Results.sex;
        obj.specimen_name = p.Results.specimen_name;
        obj.stimulus_name = p.Results.stimulus_name;
        obj.strain = p.Results.strain;
        if strcmp(class(obj), 'types.AIBS_ecephys.EcephysLabMetaData')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.age_in_days(obj, val)
        obj.age_in_days = obj.validate_age_in_days(val);
    end
    function set.full_genotype(obj, val)
        obj.full_genotype = obj.validate_full_genotype(val);
    end
    function set.sex(obj, val)
        obj.sex = obj.validate_sex(val);
    end
    function set.specimen_name(obj, val)
        obj.specimen_name = obj.validate_specimen_name(val);
    end
    function set.stimulus_name(obj, val)
        obj.stimulus_name = obj.validate_stimulus_name(val);
    end
    function set.strain(obj, val)
        obj.strain = obj.validate_strain(val);
    end
    %% VALIDATORS
    
    function val = validate_age_in_days(obj, val)
        val = types.util.checkDtype('age_in_days', 'single', val);
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
    function val = validate_full_genotype(obj, val)
        val = types.util.checkDtype('full_genotype', 'char', val);
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
    function val = validate_sex(obj, val)
        val = types.util.checkDtype('sex', 'char', val);
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
    function val = validate_specimen_name(obj, val)
        val = types.util.checkDtype('specimen_name', 'char', val);
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
    function val = validate_stimulus_name(obj, val)
        val = types.util.checkDtype('stimulus_name', 'char', val);
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
    function val = validate_strain(obj, val)
        val = types.util.checkDtype('strain', 'char', val);
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
        refs = export@types.core.LabMetaData(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        io.writeAttribute(fid, [fullpath '/age_in_days'], obj.age_in_days);
        io.writeAttribute(fid, [fullpath '/full_genotype'], obj.full_genotype);
        io.writeAttribute(fid, [fullpath '/sex'], obj.sex);
        io.writeAttribute(fid, [fullpath '/specimen_name'], obj.specimen_name);
        io.writeAttribute(fid, [fullpath '/stimulus_name'], obj.stimulus_name);
        io.writeAttribute(fid, [fullpath '/strain'], obj.strain);
    end
end

end