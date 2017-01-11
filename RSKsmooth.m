function RSK = RSKsmooth(RSK, channel, varargin)

% RSKsmooth - Low pass filter on specified channels
%
% Syntax:  [RSK] = RSKsmooth(RSK, channel, [OPTIONS])
% 
% Applies a smoothing filter either median or average.
%
%
% Inputs: 
%    
%    [Required] - RSK - The input RSK structure, with profiles as read using
%                    RSKreadprofiles
%
%                 channel - Longname of channel to filter, Can be cell
%                    array of many channels
%               
%    [Optional] - type - The type of smoothing filter that will be used.
%                   Either median or average. Default median.
%
%                 series - the data series to apply correction. Must be
%                   either 'data' or 'profile'. If 'data' must run RSKreaddata() 
%                   before RSKsmooth, if 'profile' must first run RSKreadprofiles().
%                   Default is 'data'.
%               
%                 profileNum - the profiles to which to apply the correction. If
%                    left as an empty vector, will do all profiles.
%            
%                 direction - the profile direction to consider. Must be either
%                    'down' or 'up'. Defaults to 'down'.
%
%                 windowLength - The size of the filter window. Must be odd. Will
%                    be applied (windowLength-1)/2 samples to the left and right of the
%                    center value....
%
%
% Outputs:
%    RSK - the RSK structure with filtered channel values.
%
% Example: 
%   
%    rsk = RSKopen('file.rsk');
%    rsk = RSKreadprofiles(rsk, 1:10); % read first 10 downcasts
%    rsk = RSKsmooth(rsk, {'Temperature', 'Salinity'}, 'windowLength', 10);
%
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-01-11

%% Check input and default arguments

validSeries = {'profile', 'data'};
checkSeriesName = @(x) any(validatestring(x,validSeries));

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));

validTypeNames = {'median', 'average'};
checkType = @(x) any(validatestring(x,validTypeNames));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'type', 'median', checkType);
addParameter(p, 'series', 'data', checkSeriesName)
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'windowLength', 3, @isnumeric)

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

%% Nested function
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
