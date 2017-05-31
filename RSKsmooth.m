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
%                       array of many channels or 'all'.
%               
%    [Optional] - filter - The type of smoothing filter that will be used.
%                       Either median, boxcar or triangle. Default is boxcar.
%
%                 profile - Optional profile number. Default is to operate
%                       on all of data's elements. 
%
%                 direction - 'up' for upcast, 'down' for downcast, or
%                       `both` for all. Default all directions available.
%
%                 windowLength - The total size of the filter window. Must
%                       be odd. Default is 3.
%
% Outputs:
%    RSK - The RSK structure with filtered channel values.
%
% Example: 
%    rsk = RSKopen('file.rsk');
%    rsk = RSKreadprofiles(rsk, 'profile', 1:10); % read first 10 downcasts
%    rsk = RSKsmooth(rsk, {'Temperature', 'Salinity'}, 'windowLength', 17);
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-30

validFilterNames = {'median', 'boxcar', 'triangle'};
checkFilter = @(x) any(validatestring(x,validFilterNames));

validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'filter', 'boxcar', checkFilter);
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'direction', [], checkDirection);
addParameter(p, 'windowLength', 3, @isnumeric);
parse(p, RSK, channel, varargin{:})

RSK = p.Results.RSK;
channel = p.Results.channel;
filter = p.Results.filter;
profile = p.Results.profile;
direction = p.Results.direction;
windowLength = p.Results.windowLength;



channelcell = cellchannelnames(RSK, channel);

castidx = getdataindex(RSK, profile, direction);
for chanName = channelcell
    channelCol = getchannelindex(RSK, chanName);
    for ndx = castidx
        in = RSK.data(ndx).values(:,channelCol);
        switch filter
            case 'boxcar'
                out = runavg(in, windowLength);
            case 'median'
                out = runmed(in, windowLength);
            case 'triangle'
                out = runtriang(in, windowLength);
        end      
        RSK.data(ndx).values(:,channelCol) = out;
    end
    logdata = logentrydata(RSK, profile, direction);
    logentry = sprintf('%s filtered using a %s filter with a %1.0f sample window on %s.', chanName{1}, filter, windowLength, logdata);
    RSK = RSKappendtolog(RSK, logentry);
end

end