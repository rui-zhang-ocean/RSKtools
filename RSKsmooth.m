function RSK = RSKsmooth(RSK, channel, varargin)

% RSKsmooth - Applies a low pass filter on specified channels.
%
% Syntax:  [RSK] = RSKsmooth(RSK, channel, [OPTIONS])
% 
% RSKsmooth is a lowpass filter function that smooths the selected channel.
% It replaces every value with the median or average of it's neighboring
% values. The windowLength parameter determines how many samples are used
% to filter, it is always sampled around the sample being evaluated.
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger metadata and thumbnails
%
%                 channel - Longname of channel to filter. Can be cell
%                    array of many channels or 'all'.
%               
%    [Optional] - filter - The type of smoothing filter that will be used.
%                    Either median or average. Default is average.
%
%                 series - Specifies the series to be filtered. Either 'data'
%                    or 'profile'. Default is 'data'.
%
%                 profileNum - Optional profile number to calculate lag.
%                    Default is to calculate the lag of all detected
%                    profiles
%            
%                 direction - 'up' for upcast, 'down' for downcast, or 'both' for
%                    all. Default is 'down'.
%
%                 windowLength - The total size of the filter window. Must
%                    be odd. Default is 3; one sample from either side of
%                    sample being evaluated.
%
% Outputs:
%    RSK - the RSK structure with filtered channel values.
%
% Example: 
%   
%    rsk = RSKopen('file.rsk');
%    rsk = RSKreadprofiles(rsk, 1:10); % read first 10 downcasts
%    rsk = RSKsmooth(rsk, {'Temperature', 'Salinity'}, 'windowLength', 17);
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-02-08

%% Check input and default arguments

validSeries = {'profile', 'data'};
checkSeriesName = @(x) any(validatestring(x,validSeries));

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));

validFilterNames = {'median', 'average'};
checkFilter = @(x) any(validatestring(x,validFilterNames));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'filter', 'average', checkFilter);
addParameter(p, 'series', 'data', checkSeriesName)
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'windowLength', 3, @isnumeric);
parse(p, RSK, channel, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
channel = p.Results.channel;
series = p.Results.series;
type = p.Results.type;
profileNum = p.Results.profileNum;
direction = p.Results.direction;
windowLength = p.Results.windowLength;


%% Determine if the structure has downcasts and upcasts

if strcmpi(series, 'profile')
    profileNum = checkprofiles(RSK, profileNum, direction);
    castdir = [direction 'cast'];
end


%% Ensure channel is a cell.

if strcmpi(channel, 'all')
    channel = {RSK.channels.longName};
elseif ~iscell(channel)
    channel = {channel};
end



%% Smooth

for chanName = channel
    channelCol = find(strcmpi(chanName, {RSK.channels.longName}));
    switch series
        case 'data'
            switch type
                case 'average'
                    RSK.data.values(:,channelCol) = runavg(RSK.data.values(:,channelCol), windowLength);
                case 'median'
                    RSK.data.values(:,channelCol) = runmed(RSK.data.values(:,channelCol), windowLength);
            end            
        case 'profile'
            for ndx = profileNum
                switch type
                    case 'average'
                            RSK.profiles.(castdir).data(ndx).values(:,channelCol) = runavg(RSK.profiles.(castdir).data(ndx).values(:,channelCol), windowLength);
                    case 'median'
                            RSK.profiles.(castdir).data(ndx).values(:,channelCol) = runmed(RSK.profiles.(castdir).data(ndx).values(:,channelCol), windowLength);
                end
            end
    end
        
end
end



%% Nested functions
function out = runavg(in, windowLength)
% runavg performs a running average of length windowLength over the
% mirrorpadded time series.

n = length(in);
out = NaN*in;


%% Check windowLength
if mod(windowLength, 2) == 0
    warning('windowLength must be odd; adding 1');
    windowLength = windowLength + 1;
end


%% Mirror pad the time series
padsize = (windowLength-1)/2;
inpadded = mirrorpad(in, padsize);


%% Running median
for ndx = 1:n
    out(ndx) = mean(inpadded(ndx:ndx+(windowLength-1)));
end
end
