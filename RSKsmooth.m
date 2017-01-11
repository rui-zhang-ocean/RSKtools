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
%
% Outputs:
%    RSK - the RSK structure with filtered channel values.
%
% Example: 
%   
%    rsk = RSKopen('file.rsk');
%    rsk = RSKreadprofiles(rsk, 1:10); % read first 10 downcasts
%    rsk = RSKsmooth(rsk, {'Temperature', 'Salinity'}, 'span', 10);
%
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-11-30

%% Check input and default arguments

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));

validTypeNames = {'median', 'average'};
checkType = @(x) any(validatestring(x,validTypeNames));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'type', 'median', checkType);
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'span', 3, @isnumeric)

parse(p, RSK, channel, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
channel = p.Results.channel;
type = p.Results.type;
profileNum = p.Results.profileNum;
direction = p.Results.direction;
span = p.Results.span;



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
    switch type
        case 'average'
            for ndx = profileNum
                RSK.profiles.(castdir).data(ndx).values(:,channelCol) = smooth(RSK.profiles.(castdir).data(ndx).values(:,channelCol), span);
            end
        case 'median'
            for ndx = profileNum
                b = coefficients(1);
                a = coefficients(2);
                RSK.profiles.(castdir).data(ndx).values(:,channelCol) = RSKdespike(b, a, RSK.profiles.(castdir).data(ndx).values(:,channelCol));
            end
    end
        
end

        
        