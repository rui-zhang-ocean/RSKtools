function [RSK] = RSKaddmetadata(RSK, profile, varargin)

% RSKaddmetadata - Add metadata information for specified profile(s).
%
% Syntax:  [RSK] = RSKaddmetadata(RSK, profile, [OPTIONS])
% 
% Append station metadata to data structure with profiles, including
% latitude, longitude, station name, comment, and description. The
% function is vectorized, which allows multiple metadata inputs for
% multiple profiles. But when there is only one metadata input for
% multiple profiles, all pointed profiles will be assigned with the
% same value.
%
% Inputs: 
%   [Required] - RSK - Structure containing data. 
%    
%                profile - Profile number(s) to which metadata should be assigned.
% 
%   [Optional] - lat - Profile latitude coordinate
%
%                lon - Profile longitude coordinate
%
%                station - Cell array of strings with station name(s) 
%                 
%                comment - Comment for specified profile
%
%                description - Decription for specified profile
%
% Outputs:
%    RSK - Updated structure containing metadata for specified profile(s).
%
% Example:
%    RSK = RSKaddmetadata(RSK, 4,'lat',45,'lon',-25,'station',{'NA1'},'comment',{'NoComment'},'description',{'Cruise in North Atlantic with ..'})
%    OR
%    RSK = RSKaddmetadata(RSK, 4:6,'lat',[45,44,46],'lon',[-25,-24,-23],'comment',{'Comment1','Comment2','Comment3'});
% 
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-04-11


p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'profile', @isnumeric);
addParameter(p, 'lat', [], @isnumeric);
addParameter(p, 'lon', [], @isnumeric);
addParameter(p, 'station', '', @iscell);
addParameter(p, 'comment', '', @iscell);
addParameter(p, 'description', '', @iscell);
parse(p, RSK, profile, varargin{:})

RSK = p.Results.RSK;
profile = p.Results.profile;
lat = p.Results.lat;
lon = p.Results.lon;
station = p.Results.station;
comment = p.Results.comment;
description = p.Results.description;

if length(RSK.data) == 1; RSK = RSKreadprofiles(RSK); end 

castidx = getdataindex(RSK, profile);

directions = 1;
if isfield(RSK.profiles,'order') && length(RSK.profiles.order) ~= 1 
    directions = 2;
end

k = 1;
for i = 1:directions:length(castidx);    
    RSK = assign_metadata(RSK, lat, castidx, i, directions, profile, k, 'latitude');
    RSK = assign_metadata(RSK, lon, castidx, i, directions, profile, k, 'longitude');
    RSK = assign_metadata(RSK, station, castidx, i, directions, profile, k, 'station');
    RSK = assign_metadata(RSK, comment, castidx, i, directions, profile, k, 'comment');
    RSK = assign_metadata(RSK, description, castidx, i, directions, profile, k, 'description');
    k = k + 1;    
end

logentry = ['Metadata information added to profile ' num2str(profile) '.'];
RSK = RSKappendtolog(RSK, logentry);

    %% Nested Functions
    function RSK = assign_metadata(RSK, meta, castidx, i, directions, profile, k, name)
    % Assign metadata to data structure
    if ~isempty(meta) && length(meta) == 1; 
        RSK.data(castidx(i)).(name) = meta;
        if directions == 2
            RSK.data(castidx(i+1)).(name) = meta;
        end        
    elseif ~isempty(meta) && length(meta) ~= 1 && length(meta) == length(profile);
        RSK.data(castidx(i)).(name) = meta(k);
        if directions == 2
            RSK.data(castidx(i+1)).(name) = meta(k);
        end
    elseif isempty(meta)
        % do nothing
    else
        error('Input vectors must be either single value or the same length with profile.');
    end
    
    end
end