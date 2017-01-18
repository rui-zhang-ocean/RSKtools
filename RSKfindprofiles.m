function RSK = RSKfindprofiles(RSK, varargin)

% RSKfindprofiles - finds profiles in the rsk pressure data if profile events are non exist.
%
% Syntax:  [RSK] = RSKfindprofiles(RSK, varargin)
% 
% RSKfindprofiles implements the algorithm used by the logger to find upcasts
% or downcasts if they were not detected while the instument was recording.
%
% Inputs:
%    
%   RSK - the input RSK structure, with profiles but no
%                   profile events
%
% Ex:
%    RSK = RSKopen(fname);
%    RSK = RSKreaddata(RSK);
%    RSK = RSKfindprofiles(RSK);
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-01-16


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profileThreshold', [], @ isnumeric);
parse(p, RSK, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
profileThreshold = p.Results.profileThreshold;

%% Check if upcasts is already populated
if isfield(RSK, 'profiles')
    error('Profiles are already found, get data using RSKreadprofiles.m');
end


%% Set up values
pressureCol = find(strcmpi('pressure', {RSK.channels.longName}));
condCol = find(strcmpi('conductivity', {RSK.channels.longName}));
pressure = RSK.data.values(:, pressureCol(1));
if isempty(condCol)
    conductivity = [];
else 
    conductivity = RSK.data.values(:, condCol(1));
end
timestamp = RSK.data.tstamp;
if isempty(profileThreshold)
    profileThreshold = (max(pressure)-min(pressure))/4;
end



%% Run profile detection
[upcaststart, downcaststart] = detectprofiles(pressure, timestamp, conductivity, profileThreshold);
if ~any(size(upcaststart)>1 & size(downcaststart)>1)
    return;
elseif upcaststart(1) < downcaststart(1)
    RSK.profiles.upcast.tstart = upcaststart;
    RSK.profiles.upcast.tend = downcaststart;
    RSK.profiles.downcast.tstart = downcaststart;
    RSK.profiles.downcast.tend = upcaststart(2:end);
    RSK.profiles.downcast.tend(end+1) = RSK.data.tstamp(end);
else
    RSK.profiles.upcast.tstart = upcaststart;
    RSK.profiles.upcast.tend = downcaststart(2:end);
    RSK.profiles.upcast.tend(end+1) = RSK.data.tstamp(end);
    RSK.profiles.downcast.tstart = downcaststart;
    RSK.profiles.downcast.tend = upcaststart;
end
    

end
            
   




    
