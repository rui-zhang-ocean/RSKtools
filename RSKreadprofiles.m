function RSK = RSKreadprofiles(RSK, varargin)

% RSKreadprofiles - Read individual profiles (e.g. upcast and downcast)
%                   from an rsk file. 
%
% Syntax:  RSK = RSKreadprofiles(RSK, [OPTIONS])
% 
% Reads profiles, including up and/or down casts, from the events
% contained in an rsk file. The profiles are written to the data field as a
% matrix for each cast; that way, they can be indexed individually.
%
% The profile events are parsed from the events table using the
% following types (see RSKconstants.m):
%   33 - Begin upcast
%   34 - Begin downcast
%   35 - End of profile cast
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger data read
%                       from the RSK file.
%
%    [Optional] - profile - vector identifying the profile numbers to
%                       read. This can be used to read only a subset of all
%                       the profiles. Default is to read all the profiles. 
% 
%                 direction - 'up' for upcast, 'down' for downcast, or
%                       `both` for all. Default is 'both'.
%
% Outputs:
%    RSK - RSK structure containing individual casts in the data field.
%
% Examples:
%
%    rsk = RSKopen('profiles.rsk');
%
%    % read all profiles
%    rsk = RSKreadprofiles(rsk);
%
%    % read selective upcasts
%    rsk = RSKreadprofiles(rsk, 'profileNum', [1 3 10], 'direction', 'up');
%
% See also: RSKreaddata, RSKfindprofiles, RSKplotprofiles
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-30

validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'direction', 'both', checkDirection);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
profile = p.Results.profile;
direction = {p.Results.direction};



if ~isfield(RSK, 'profiles') 
    error('No profiles in this RSK, try RSKreaddata or RSKfindprofiles');
end

if strcmpi(direction{1}, 'both')
    direction = {'down', 'up'};
end

alltstart = [];
alltend = [];
for dir = direction
    castdir = [dir{1} 'cast'];
    alltstart = [alltstart; RSK.profiles.(castdir).tstart];
    alltend = [alltend; RSK.profiles.(castdir).tend];
end
alltstart = sort(alltstart);
alltend = sort(alltend);

RSK.profiles.order = direction;
profilecast = size(RSK.profiles.order, 2);
if profilecast == 2 && (alltstart(1) == RSK.profiles.upcast.tstart(1))
        RSK.profiles.order = {'up', 'down'};
end



if ~isempty(profile)
    if max(profile) > length(alltstart)/profilecast
        disp('The profile selected is greater than the total amount of profiles in this file.');
        return
    end
    if profilecast == 2
        castidx = [(profile*2)-1 profile*2];
        castidx = sort(castidx);
    else
        castidx = profile;
    end
else
    castidx = 1:length(alltstart);
end

dataIdx = 1;
data(length(castidx)).tstamp = [];
data(length(castidx)).values = [];
for ndx = castidx
    tmp = RSKreaddata(RSK, 't1', alltstart(ndx), 't2', alltend(ndx));
    data(dataIdx).tstamp = tmp.data.tstamp;
    data(dataIdx).values = tmp.data.values;
    dataIdx = dataIdx + 1;
end

RSK.data = data;

end