function RSK = RSKreadannotations(RSK)

% RSKreadannotations - Read annotations from Ruskin.
%
% Syntax:  [RSK] = RSKreadannotations(RSK)
%
% Reads in GPS and comment start and end time by combining information 
% from region, regionGeoData and regionComment tables and adds it to the 
% RSK structure.
%
% Inputs:
%    RSK - Structure containing logger metadata.
%
% Outputs:
%    RSK - Structure containing populated annotations, if available.
%
% See also: RSKgetprofiles.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-02-09

tables = doSelect(RSK, 'SELECT name FROM sqlite_master WHERE type="table"');

if any(strcmpi({tables.name}, 'region')) && any(strcmpi({tables.name}, 'regionGeoData')) && any(strcmpi({tables.name}, 'regionComment'))
    regioninfo = doSelect(RSK, 'PRAGMA table_info(region)');
    if any(strcmpi({regioninfo.name}, 'description')) % description column only exists after 1.13.8 
        RSK.region = doSelect(RSK, 'select regionID, type, tstamp1/1.0 as tstamp1, tstamp2/1.0 as tstamp2, description from region');
    else
        RSK.region = doSelect(RSK, 'select regionID, type, tstamp1/1.0 as tstamp1, tstamp2/1.0 as tstamp2 from region');
    end
    RSK.regionGeoData = doSelect(RSK, 'select * from regionGeoData');
    RSK.regionComment = doSelect(RSK, 'select * from regionComment');
else
    return
end


if isempty(RSK.regionGeoData)
    RSK = rmfield(RSK, 'regionGeoData');
elseif ~isempty(RSK.regionGeoData) && isfield(RSK,'geodata');
    RSK = rmfiled(RSK, 'geodata');
end

if isempty(RSK.regionComment)
    RSK = rmfield(RSK, 'regionComment');
end


end
