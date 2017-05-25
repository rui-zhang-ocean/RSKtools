
function RSK = RSKsmooth(RSK, channel, varargin)

% RSKsmooth - Applies a low pass filter on specified channels.
%
% Syntax:  [RSK] = RSKsmooth(RSK, channel, [OPTIONS])
% 
% RSKsmooth applies a lowpass filter function to the selected channel.
% It replaces every sample with the filter results. The windowLength
% parameter determines how many samples are used to filter, the sample
% being evaluated is always in the center of the filtering window. 
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger data
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
%                     operate on all detected profiles.
%            
%                 direction - 'up' for upcast, 'down' for downcast, or 'both' for
%                     all. Default is 'down'.
%
%                 windowLength - The total size of the filter window. Must
%                     be odd. Default is 3.
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
% Last revision: 2017-05-15

%% Check input and default arguments

validSeries = {'profile', 'data'};
checkSeriesName = @(x) any(validatestring(x,validSeries));

validDirections = {'down', 'up', 'both'};
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

%% Ensure channel is a cell.

channels = cellchannelnames(RSK, channel);

%% Determine if the structure has downcasts and upcasts
if strcmpi(series, 'profile')
    if strcmpi(direction, 'both')
        direction = {'down', 'up'};
    else
        direction = {direction};
    end
end

%% Smooth

for chanName = channels
    chanCol = getchannelindex(RSK, chanName);
    switch series
        case 'data'
            in = RSK.data.values(:,chanCol);
            switch filter
                case 'boxcar'
                    out = runavg(in, windowLength);
                case 'median'
                    out = runmed(in, windowLength);
            end      
            RSK.data.values(:,chanCol) = out;

            logentry = sprintf('%s filtered using a %s filter with a %1.0f sample window.', chanName{1}, filter, windowLength);
            RSK = RSKappendtolog(RSK, logentry);

        case 'profile'
            for dir = direction
                profileIdx = checkprofiles(RSK, profileNum, dir{1});
                castdir = [dir{1} 'cast'];
                for ndx = profileIdx
                    in = RSK.profiles.(castdir).data(ndx).values(:,chanCol);
                    switch filter
                        case 'boxcar'
                            out = runavg(in, windowLength);
                        case 'median'
                            out= runmed(in, windowLength);
                    end
                    RSK.profiles.(castdir).data(ndx).values(:,chanCol) = out;
                end

                logprofile = logentryprofiles(dir{1}, profileNum, profileIdx);
                logentry = sprintf('%s filtered using a %s filter with a %1.0f sample window on %s.', chanName{1}, filter, windowLength, logprofile);
                RSK = RSKappendtolog(RSK, logentry);
            end
    end
end


end

