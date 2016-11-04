function [RSK] = RSKdespike(RSK, varargin)

% RSKdespike - De-spike a time series using a running median filter.
%
% Syntax:  [RSK] = RSKdespike(RSK, [OPTIONS])
% 
% RSKdespike is a despike algorithm that utilizes a running median
% filter to create a reference series. Each point in the original
% series is compared against the reference series, with points lying
% further than n standard deviations from the mean treated as
% spikes. The default behaviour is to replace the spike wth the
% reference value.
%
% Inputs:
%    
%   [Required] - RSK - the input RSK structure, with profiles as read using
%                    RSKreadprofiles
%
%   [Optional] - channel - Longname of channel to plot (e.g. temperature,
%                   salinity, etc). Default is ;Temperature'
%
%                series - the data series to apply correction. Must be
%                   either 'data' or 'profile'. If 'data' must run RSKreaddata() 
% .                 before RSKdespike, if 'profile' must first run RSKreadprofiles().
%                   Default is 'data'.
%
%                profileNum - the profiles to which to apply the correction. If
%                    left as an empty vector, will do all profiles.
%            
%                direction - the profile direction to consider. Must be either
%                   'down' or 'up'. Only needed if series is profile. Defaults to 'down'.
%
%                n - the number of standard deviations to use for the spike criterion.
%                   Default value is 4.
%
%                k - the length of the running median. Default value is 7.
%
%                action - the "action" to perform on a spike. The default,
%                   'replace' is to replace it with the reference value. Can also be
%                   'NaN' to leave the spike as a missing value.
%
% Outputs:
%    y - the de-spiked series
%
% Example: 
%    temperatureDS = RSKdespike(RSK)
%   OR
%    temperatureDS = RSKdespike(RSK, 'n',2, 'k',10, 'action','NaN');
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-11-04

%% Check input and default arguments

validChannelNames = {'Salinity', 'Temperature', 'Conductivity', 'Chlorophyll', 'Dissolved O', 'CDOM', 'Turbidity'};
checkChannelName = @(x) any(validatestring(x,validChannelNames));

validSeries = {'profile', 'data'};
checkSeriesName = @(x) any(validatestring(x,validSeries));

validDirections = {'up', 'down'};
checkDirection = @(x) any(validatestring(x,validDirections));

validActions = {'replace','NaN'};
checkAction = @(x) any(validatestring(x,validActions));

%% Parse Inputs

p = inputParser;
addParameter(p,'channel', 'temperature', checkChannelName);
addParameter(p,'series', 'data', checkSeriesName);
addParameter(p,'profileNum', [], @isnumeric)
addParameter(p,'n', 4, @isnumeric);
addParameter(p,'k', 7, @isnumeric);
addParameter(p,'action', 'replace', checkAction);
addParameter(p,'direction', 'down', checkDirection);% Only needed if series is 'profile'
parse(p, varargin{:})

%Assign each argument
channel = p.Results.channel;
series = p.Results.series;
direction = p.Results.direction;
profileNum = p.Results.profileNum;
n = p.Results.n;
k = p.Results.k;
action = p.Results.action;

%% Select Time Series
if strcmp(series,'profile') & strcmp(p.UsingDefaults,'profileNum')
    switch direction
      case 'down'
        profileNum = 1:length(RSK.profiles.downcast.data);
      case 'up'
        profileNum = 1:length(RSK.profiles.upcast.data);
    end
end

channelCol = find(strncmpi(channel, {RSK.channels.longName}, 4));
channelCol = channelCol(1); % If there are two pick the first. Usually temp or pressure.

%% Despike
switch series
    case 'profile'
        switch direction
            case 'up'
                for i=profileNum
                    x = RSK.profiles.upcast.data(i).values(:,channelCol);
                    RSK.profiles.upcast.data(i).values(:, channelCol) = despike(x, n, k, action); 
                end
            case 'down'
                for i=profileNum
                    x = RSK.profiles.downcast.data(i).values(:,channelCol);
                    RSK.profiles.downcast.data(i).values(:, channelCol) = despike(x, n, k, action); 
                end
        end
        
    case 'data'
        x = RSK.data.values(:,channelCol);
        RSK.data.values(:, channelCol) = despike(x, n, k, action); 
end
end


%% Nested Functions
function [y] = despike(x, n, k, action)
y = x;
ref = runmed(x, k);
dx = x - ref;
sd = std(dx);
I = find(abs(dx) > n*sd);

switch action
  case 'replace'
    y(I) = ref(I);
  case 'NaN'
    y(I) = NaN;
end
end

function out = runmed(in, k)
% A running median of length k. k must be odd, has one added if it's found to be even.

n = length(in);
out = NaN*in;

if mod(k, 2) == 0
    warning('k must be odd; adding 1');
    k = k + 1;
end

for i = 1:n
    if i <= (k-1)/2
        out(i) = median(in(1:i+(k-1)/2));
    elseif i >= n-(k-1)/2
        out(i) = median(in(i-(k-1)/2:n));
    else
        out(i) = median(in(i-(k-1)/2:i+(k-1)/2));
    end
end

end