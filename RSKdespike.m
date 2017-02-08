function [RSK, spike] = RSKdespike(RSK, channel, varargin)

% RSKdespike - De-spike a time series by comparing it to a reference time
%              series
%
% Syntax:  [RSK, spike] = RSKdespike(RSK, channel, [OPTIONS])
% 
% RSKdespike compares the time series to a reference series, a running
% median filter of length 'windowLength'. Each point in the original series
% is compared against the reference series. If a sample is further than
% 'threshold' standard deviations of the residual away from the reference
% series the sample is considered a spike. The default behaviour is to
% replace the spikes with the reference value.  
%
% Inputs:
%   [Required] - RSK - The input RSK structure
%
%                channel - Longname of channel to plot (e.g. temperature,
%                    salinity, etc). Can be cell array of many channels or
%                    'all'.
%
%   [Optional] - series - Specifies the series to be filtered. Either 'data'
%                    or 'profile'. Default is 'data'.
%
%                profileNum - Optional profile number to calculate lag.
%                    Default is to calculate the lag of all detected
%                    profiles
%            
%                direction - 'up' for upcast, 'down' for downcast, or 'both' for
%                    all. Default is 'down'.
%
%                threshold - The number of standard deviations to use for
%                    the spike criterion. Default value is 4.
%
%                windowLength - The total size of the filter window. Must
%                    be odd. Default is 3.
%
%                action - The action to perform on a spike. The default,
%                    'replace' is to replace it with the reference value.
%                    Can also be 'NaN' to leave the spike as a missing
%                    value or 'interp' to interpolate based on 'good'
%                    values. 
%
% Outputs:
%    RSK - The RSK structure with de-spiked series.
%
%    spike - A structure containing the index of the spikes; organised by channel.
%
% Example: 
%    temperatureDS = RSKdespike(RSK,  {'pressure', 'Conductivity})
%   OR
%    temperatureDS = RSKdespike(RSK, 'Temperature', 'threshold',2, 'windowLength',10, 'action','NaN');
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-02-08

%% Check input and default arguments

validSeries = {'profile', 'data'};
checkSeriesName = @(x) any(validatestring(x,validSeries));

validDirections = {'up', 'down'};
checkDirection = @(x) any(validatestring(x,validDirections));

validActions = {'replace', 'interp', 'NaN'};
checkAction = @(x) any(validatestring(x,validActions));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
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
    profileNum = checkprofiles(RSK, profileNum, direction);
    castdir = [direction 'cast'];
end


%% Ensure channel is a cell.

if strcmpi(channel, 'all')
    channel = {RSK.channels.longName};
elseif ~iscell(channel)
    channel = {channel};
end


%% Despike

for chanName = channel
    channelCol = strcmpi(chanName, {RSK.channels.longName});
    switch series
        case 'profile'
            k = 1;    
            for ndx = profileNum
                x = RSK.profiles.(castdir).data(ndx).values(:,channelCol);
                xtime = RSK.profiles.(castdir).data(ndx).tstamp;
                [RSK.profiles.(castdir).data(ndx).values(:,channelCol), index] = despike(x, xtime, threshold, windowLength, action);
                spike(k).(chanName{1}(1:4)) = index;
                k = k+1;
            end
        case 'data'
            x = RSK.data.values(:,channelCol);
            xtime = RSK.data.tstamp;
            [RSK.data.values(:,channelCol), index] = despike(x, xtime, threshold, windowLength, action); 
            spike.(chanName{1}(1:4)) = index;
    end
end
end


%% Nested Functions
function [y, I] = despike(x, t, threshold, windowLength, action)
% This helper function replaces the values that are > threshold*standard
% deviation away from the median with the median, a NaN or interpolated
% value. The output is the x series with spikes fixed and I is the index of
% the spikes.

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
