function RSK = RSKreadprofiles(RSK, varargin)

% RSKreadprofiles - Read individual profiles (e.g. upcast and
%                   downcast) from an rsk file.
%
% Syntax:  RSK = RSKreadprofiles(RSK, profileNum, direction, latency)
% 
% Reads profiles, including up and down casts, from the events
% contained in an rsk file. The profiles are written as fields in a
% structure array, divided into upcast and downcast fields, which can
% be indexed individually.
%
% The profile events are parsed from the events table using the
% following types (see RSKconstants.m):
%   33 - Begin upcast
%   34 - Begin downcast
%   35 - End of profile cast
%
% Currently the function assumes that upcasts and downcasts come in
% pairs, as would be recorded by a continuously recording
% logger. Future versions may be better at parsing more complicated
% deployments, such as thresholds or scheduled profiles.
% 
% Inputs: 
%    RSK - Structure containing the logger data read
%                     from the RSK file.
%
%    profileNum - vector identifying the profile numbers to read. This
%          can be used to read only a subset of all the profiles. Default
%          is to read all the profiles.
%
%    direction - `up` for upcast, `down` for downcast, or `both` for
%          all. Default is `down`.
%
%    latency - the latency, or time lag, in seconds, caused by the slowest
%          responding sensor. When reading profiles the event times must be
%          shifted by this value to line up with the data time stamps.
%          Default is 0.
%
% Outputs:
%    RSK - RSK structure containing individual profiles
%
% Examples:
%
%    rsk = RSKopen('profiles.rsk');
%
%    % read all profiles
%    rsk = RSKreadprofiles(rsk);
%
%    % read selective upcasts
%    rsk = RSKreadprofiles(rsk, [1 3 10], 'up');
%
% See also: RSKreaddata, RSKfindprofiles, RSKplotprofiles
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-08
%% Parse Inputs
validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addOptional(p, 'profileNum', [], @isnumeric);
addOptional(p, 'direction', 'down', checkDirection);
addOptional(p, 'latency', 0, @isnumeric);
parse(p, RSK, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
profileNum = p.Results.profileNum;
direction = p.Results.direction;
latency = p.Results.latency;

%%
if ~isfield(RSK, 'profiles') 
    error('No profiles in this RSK, try RSKfindprofiles');
end

if strcmpi(direction, 'both')
    direction = {'down', 'up'};
else
    direction = {direction};
end

alltstart = [];
alltend = [];

for dir = direction
    castdir = [dir{1} 'cast'];
    alltstart = [alltstart; RSK.profiles.(castdir).tstart];
    alltend = [alltend; RSK.profiles.(castdir).tend];
end

alltstart = sort(alltstart, 'ascend');
alltend = sort(alltend, 'ascend');

if isempty(profileNum)
    profileNum = 1:length(alltstart);
end

castidx = 1;
for ndx=profileNum
    tstart = alltstart(ndx) - latency/86400;
    tend = alltend(ndx) - latency/86400;
    tmp = RSKreaddata(RSK, tstart, tend);
    data(castidx).tstamp = tmp.data.tstamp;
    data(castidx).values = tmp.data.values;
    castidx = castidx + 1;
end

RSK.data = data;

end