function [RSK] = RSKaddmetadata(RSK, profile, varargin)

% RSKaddmetadata - Add metadata information for one specified profile.
%
% Syntax:  [RSK] = RSKaddmetadata(RSK, profile, [OPTIONS])
% 
% Inputs: 
%   [Required] - RSK - Structure containing data. 
%    
%                profile - Profile number to have metadata add on.
% 
%   [Optional] - lat - Profile latitude coordinate
%
%                lon - Profile longitude coordinate
%
%                comment - Comment for specified profile
%
%                description - Decription for spefified profile
%
% Outputs:
%    RSK - Updated structure containing metadata for specified profile.
%
% Example:
%    RSK = RSKaddmetadata(RSK,4,'lat',45,'lon',-25,'comment','No Comment','description','Cruise in North Atlantic with ..')
% 
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-03-07


validLatitude = @(x) isnumeric(x) && (x >= -90) && (x <= 90);
validLongitude = @(x) isnumeric(x) && (x >= -180) && (x <= 180);

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'profile', @isnumeric);
addParameter(p, 'lat', [], validLatitude);
addParameter(p, 'lon', [], validLongitude);
addParameter(p, 'comment', '', @ischar);
addParameter(p, 'description', '', @ischar);
parse(p, RSK, profile, varargin{:})

RSK = p.Results.RSK;
profile = p.Results.profile;
lat = p.Results.lat;
lon = p.Results.lon;
comment = p.Results.comment;
description = p.Results.description;

if length(RSK.data) == 1; RSK = RSKreadprofiles(RSK); end 

ind_pro = find([RSK.data.profilenumber] == profile);
if isempty(ind_pro); 
    error('The profile requested is greater than the total amount of profiles in this RSK structure.'); 
end

for i = 1:length(ind_pro);
    if ~isempty(lat); RSK.data(ind_pro(i)).latitude = lat; end
    if ~isempty(lon); RSK.data(ind_pro(i)).longitude = lon; end
    if ~isempty(comment); RSK.data(ind_pro(i)).comment = comment; end
    if ~isempty(description); RSK.data(ind_pro(i)).description = description; end
end

logentry = ['Metadata information added to profile ' num2str(profile) '.'];
RSK = RSKappendtolog(RSK, logentry);


end