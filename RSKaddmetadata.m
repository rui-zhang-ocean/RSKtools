function [RSK] = RSKaddmetadata(RSK, varargin)

% RSKaddmetadata - Add metadata information for specified profile(s).
%
% Syntax:  [RSK] = RSKaddmetadata(RSK, [OPTIONS])
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
%   [Optional] - profile - Profile number(s) to which metadata should be 
%                assigned. Default to all profiles
%
%                latitude - Profile latitude coordinate
%
%                longitude - Profile longitude coordinate
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
%    RSK = RSKaddmetadata(RSK,'latitude',45,'longitude',-25,'station',...
%    {'NA1'},'comment',{'NoComment'},'description',{'Cruise in North Atlantic with ..'})
%    -OR-
%    RSK = RSKaddmetadata(RSK,'profile',4:6,'latitude',[45,44,46],'longitude',...
%    [-25,-24,-23],'comment',{'Comment1','Comment2','Comment3'});
% 
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-04-13


p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'latitude', [], @isnumeric);
addParameter(p, 'longitude', [], @isnumeric);
addParameter(p, 'station', '', @iscell);
addParameter(p, 'comment', '', @iscell);
addParameter(p, 'description', '', @iscell);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
profile = p.Results.profile;
latitude = p.Results.latitude;
longitude = p.Results.longitude;
station = p.Results.station;
comment = p.Results.comment;
description = p.Results.description;


if isempty([latitude longitude station comment description])
    warning('No metadata input is found. Please specify at least one metadata field.')
    return
end
    
if length(RSK.data) == 1; RSK = RSKreadprofiles(RSK); end 

castidx = getdataindex(RSK, profile);

directions = 1;
if isfield(RSK.profiles,'order') && length(RSK.profiles.order) ~= 1 
    directions = 2;
end

k = 1;
for i = 1:directions:length(castidx);    
    RSK = assign_metadata(RSK, latitude, castidx, i, directions, profile, k, 'latitude');
    RSK = assign_metadata(RSK, longitude, castidx, i, directions, profile, k, 'longitude');
    RSK = assign_metadata(RSK, station, castidx, i, directions, profile, k, 'station');
    RSK = assign_metadata(RSK, comment, castidx, i, directions, profile, k, 'comment');
    RSK = assign_metadata(RSK, description, castidx, i, directions, profile, k, 'description');
    k = k + 1;    
end

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