function RSK = RSKfilter(RSK, channel, varargin)

% RSKfilter - Low pass filter on specified channels
%
% Syntax:  [RSK] = RSKfilter(RSK, channel, [OPTIONS])
% 
% Applies a low pass filter to the time series in order to reduce noise,
% match time constants or...
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
%    [Optional] - filter - Default is boxcar, a simple moving average.
%                   Another option is filtfilt, requiers numerator and
%                   denomenator coefficients
%               
%                 profileNum - the profiles to which to apply the correction. If
%                    left as an empty vector, will do all profiles.
%            
%                 direction - the profile direction to consider. Must be either
%                    'down' or 'up'. Defaults to 'down'.
%
%                 span - The size of the filter window. Must be odd. Will
%                    be applied span-1/2 scans to the left and right of the
%                    center value....
%
%                 coefficients - a vector with the [numerator, denominator]
%                    as the filtfilt coefficients.
%
% Outputs:
%    RSK - the RSK structure with filtered channel values.
%
% Example: 
%   
%    rsk = RSKopen('file.rsk');
%    rsk = RSKreadprofiles(rsk, 1:10); % read first 10 downcasts
%    rsk = RSKfilter(rsk, {'Temperature', 'Salinity'}, 'span', 10);
%
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-11-30

%% Check input and default arguments

validChannelNames = {'Salinity', 'Temperature', 'Conductivity', 'Pressure', 'Chlorophyll', 'Dissolved O', 'CDOM', 'Turbidity', 'pH'};
checkChannelName = @(x) any(validatestring(x,validChannelNames));

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));

validFilterNames = {'boxcar', 'filtfilt'};
checkFilterName = @(x) any(validatestring(x,validFilterNames));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel', checkChannelName);
addParameter(p, 'filter', 'boxcar', checkFilterName);
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'span', 3, @isnumeric)
addParameter(p, 'coefficients', [1 1])

parse(p, RSK, channel, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
channel = p.Results.channel;
filter = p.Results.filter;
profileNum = p.Results.profileNum;
direction = p.Results.direction;
span = p.Results.span;
coefficients = p.Results.coefficients;



%% Determine if the structure has downcasts and upcasts
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

%% Apply filter.

castdir = [direction 'cast'];

for chanName = channel
    channelCol = find(strcmpi(chanName, {RSK.channels.longName}));
    switch filter
        case 'boxcar'
            for i = profileNum
                RSK.profiles.(castdir).data(i).values(:,channelCol) = smooth(RSK.profiles.(castdir).data(i).values(:,channelCol), span);
            end
        case 'filtfilt'
            for i = profileNum
                b = coefficients(1);
                a = coefficients(2);
                RSK.profiles.(castdir).data(i).values(:,channelCol) = filtfilt(b, a, RSK.profiles.(castdir).data(i).values(:,channelCol));
            end
    end
        
end

        
        