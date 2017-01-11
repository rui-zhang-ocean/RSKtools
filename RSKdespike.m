function [RSK] = RSKdespike(RSK, channel, varargin)

% RSKdespike - De-spike a time series by comparing it to a reference time
%              series
%
% Syntax:  [RSK] = RSKdespike(RSK, channel, [OPTIONS])
% 
% RSKdespike is a despike algorithm that compares the time series to a
% reference series. Each point in the original series is compared against
% the reference series, with points lying further than 'threshold' standard
% deviations from the mean treated as spikes. The default behaviour is to
% replace the spike with the reference value. 
%
% Inputs:
%    
%   [Required] - RSK - the input RSK structure, with profiles as read using
%                    RSKreadprofiles
%
%                channel - Longname of channel to plot (e.g. temperature,
%                    salinity, etc). Default is 'Temperature'. Can be cell 
%                    array of many channels
%
%   [Optional] - series - the data series to apply correction. Must be
%                   either 'data' or 'profile'. If 'data' must run RSKreaddata() 
%                   before RSKdespike, if 'profile' must first run RSKreadprofiles().
%                   Default is 'data'.
%
%                profileNum - the profiles to which to apply the correction. If
%                    left as an empty vector, will do all profiles.
%            
%                direction - the profile direction to consider. Must be either
%                   'down' or 'up'. Only needed if series is profile. Defaults to 'down'.
%
%                threshold - the number of standard deviations to use for the spike criterion.
%                   Default value is 4.
%
%                windowLength - the length of the running median. Default value is 7.
%
%                action - the 'action' to perform on a spike. The default,
%                   'replace' is to replace it with the reference value. Can also be
%                   'NaN' to leave the spike as a missing value or
%                   'interp' to interpolate based on 'good' values.
%
% Outputs:
%    y - the de-spiked series
%
% Example: 
%    temperatureDS = RSKdespike(RSK)
%   OR
%    temperatureDS = RSKdespike(RSK, 'threshold',2, 'windowLength',10, 'action','NaN');
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-01-11

%% Check input and default arguments

validChannelNames = {'Salinity', 'Temperature', 'Conductivity', 'Chlorophyll', 'Dissolved O', 'CDOM', 'Turbidity', 'pH'};
checkChannelName = @(x) any(validatestring(x,validChannelNames));

validSeries = {'profile', 'data'};
checkSeriesName = @(x) any(validatestring(x,validSeries));

validDirections = {'up', 'down'};
checkDirection = @(x) any(validatestring(x,validDirections));

validActions = {'replace', 'interp', 'NaN'};
checkAction = @(x) any(validatestring(x,validActions));

%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel', checkChannelName);
addParameter(p, 'series', 'data', checkSeriesName);
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'threshold', 4, @isnumeric);
addParameter(p, 'windowLength', 7, @isnumeric);
addParameter(p, 'action', 'replace', checkAction);
addParameter(p, 'direction', 'down', checkDirection);% Only needed if series is 'profile'
parse(p, RSK, channel, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
channel = p.Results.channel;
series = p.Results.series;
direction = p.Results.direction;
profileNum = p.Results.profileNum;
windowLength = p.Results.windowLength;
threshold = p.Results.threshold;
action = p.Results.action;


%% For Profiles: determine if the structure has downcasts and upcasts & set profileNum accordingly
if strcmp(series, 'profile')
    isDown = isfield(RSK.profiles.downcast, 'data');
    isUp   = isfield(RSK.profiles.upcast, 'data');
    switch direction
        case 'up'
            if ~isUp
                error('Structure does not contain upcasts')
            elseif isempty(profileNum)
                profileNum = 1:length(RSK.profiles.upcast.data);
            end
        case 'down'
            if ~isDown
                error('Structure does not contain downcasts')
            elseif isempty(profileNum)
                profileNum = 1:length(RSK.profiles.downcast.data);
            end
    end
    castdir = [direction 'cast'];
end
%% Despike
for chanName = channel
    channelCol = find(strcmpi(chanName, {RSK.channels.longName}));
    switch series
        case 'profile'
                for i = profileNum
                    x = RSK.profiles.(castdir).data(i).values(:,channelCol);
                    xtime = RSK.profiles.(castdir).data(i).tstamp;
                    RSK.profiles.(castdir).data(i).values(:,channelCol) = despike(x, xtime, threshold, windowLength, action); 
                end
        case 'data'
            x = RSK.data.values(:,channelCol);
            xtime = RSK.data.tstamp;
            RSK.data.values(:,channelCol) = despike(x, xtime, threshold, windowLength, action); 
    end
end


%% Nested Functions
function [y] = despike(x, t, threshold, windowLength, action)
y = x;
ref = runmed(x, windowLength);
dx = x - ref;
sd = std(dx);
I = find(abs(dx) > threshold*sd);
good = find(abs(dx) <= threshold*sd);

switch action
  case 'replace'
    y(I) = ref(I);
  case 'NaN'
    y(I) = NaN;
  case 'interp'
    y(I) = interp1(t(good), x(good), t(I)) ;
end
end
