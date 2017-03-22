function RSK = RSKsmooth(RSK, channel, varargin)

% RSKsmooth - Applies a low pass filter on specified channels.
%
% Syntax:  [RSK] = RSKsmooth(RSK, channel, [OPTIONS])
% 
% RSKsmooth is a lowpass filter function that smooths the selected channel.
% It replaces every sample with the filter results. The windowLength
% parameter determines how many samples are used to filter, the sample
% being evaluated is always in the center of the filtering window. 
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger metadata and thumbnails
%
%                 channel - Longname of channel to filter. Can be cell
%                     array of many channels or 'all'.
%               
%    [Optional] - filter - The type of smoothing filter that will be used.
%                     Either median or boxcar. Default is boxcar.
%
%                 series - Specifies the series to be filtered. Either 'data'
%                     or 'profile'. Default is 'data'.
%
%                 profileNum - Optional profile number. Default is to
%                     calculate the lag of all detected profiles.
%            
%                 direction - 'up' for upcast, 'down' for downcast, or 'both' for
%                     all. Default is 'down'.
%
%                 windowLength - The total size of the filter window. Must
%                     be odd. Default is 3; one sample from either side of
%                     sample being evaluated.
%
% Outputs:
%    RSK - The RSK structure with filtered channel values.
%
% Example: 
%    rsk = RSKopen('file.rsk');
%    rsk = RSKreadprofiles(rsk, 1:10); % read first 10 downcasts
%    rsk = RSKsmooth(rsk, {'Temperature', 'Salinity'}, 'windowLength', 17);
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-03-22

%% Check input and default arguments

validSeries = {'profile', 'data'};
checkSeriesName = @(x) any(validatestring(x,validSeries));

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));

validFilterNames = {'median', 'boxcar'};
checkFilter = @(x) any(validatestring(x,validFilterNames));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'filter', 'boxcar', checkFilter);
addParameter(p, 'series', 'data', checkSeriesName)
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'windowLength', 3, @isnumeric);
parse(p, RSK, channel, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
channel = p.Results.channel;
series = p.Results.series;
filter = p.Results.filter;
profileNum = p.Results.profileNum;
direction = p.Results.direction;
windowLength = p.Results.windowLength;


%% Determine if the structure has downcasts and upcasts

if strcmpi(series, 'profile')
    profileIdx = checkprofiles(RSK, profileNum, direction);
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
            in = RSK.data.values(:,channelCol);
            switch filter
                case 'boxcar'
                    [out, windowLength] = runavg(in, windowLength);
                case 'median'
                    [out, windowLength] = runmed(in, windowLength);
            end      
            RSK.data.values(:,channelCol) = out;
            
        case 'profile'
            for ndx = profileIdx
                in = RSK.profiles.(castdir).data(ndx).values(:,channelCol);
                switch filter
                    case 'boxcar'
                        [out, windowLength] = runavg(in, windowLength);
                    case 'median'
                        [out, windowLength] = runmed(in, windowLength);
                end
                RSK.profiles.(castdir).data(ndx).values(:,channelCol) = out;
            end
    end
end


%% Update log
for chanName = channel
    switch series
        case 'data'
            logentry = sprintf('%s filtered using a %s filter with a %1.0f sample window.', chanName{1}, filter, windowLength);

        case 'profile'
            if isempty(profileNum)
                logprofiles = ['all ' direction 'cast profiles'];
            elseif length(profileIdx) == 1
                logprofiles = [direction 'cast profiles ' num2str(profileIdx, '%1.0f')];
            else 
                logprofiles = [direction 'cast profiles' num2str(profileIdx(1:end-1), ', %1.0f') ' and ' num2str(profileIdx(end))];
            end
            logentry = sprintf('%s filtered using a %s filter with a %1.0f sample window on %s.', chanName{1}, filter, windowLength, logprofiles);
    end

    RSK = RSKappendtolog(RSK, logentry);
end

end



%% Nested functions
function [out, windowLength] = runavg(in, windowLength)
% runavg performs a running average, also known as boxcar filter, of length
% windowLength over the mirrorpadded time series.

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


