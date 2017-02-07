function RSKplotcontour(RSK, channel, varargin)

% RSKplotcontour - Plot profiles in a contour plot
%
% Syntax:  RSKplotcontour(RSK, channel, direction)
% 
% This generates a plot of the profiles over time. It bins the
% data for any specified channel.
% 
% Inputs:
%    
%   [Required] - RSK - the input RSK structure, with profiles as read using
%                    RSKreadprofiles.
%
%                channel - Longname of channel to plot (e.g. temperature,
%                    salinity, etc). Can be cell array of many channels or
%                    'all', will despike all channels.
%
%   [Optional] - profileNum - the profiles to which to apply the correction. If
%                    left as an empty vector, will do all profiles.
%            
%                direction - the profile direction to consider. Must be either
%                   'down' or 'up'. Only needed if series is profile. Defaults to 'down'.
%
%                binBy - The array it will be bin wrt... Depth or Pressure.
%                   Defaults to 'Pressure'.
%
%                numRegimes - Amount of sections with different sizes of bins.
%                   Default 1, all bins are the same width.
%
%                binSize - Size of bins in each regime. Must have length(binSize) ==
%                   numRegimes. Default 1.
%
%                boundary - First boundary crossed in the direction
%                   selected of each regime, in same units as binBy. Must
%                   have length(boundary) == regimes. Default[]; whole
%                   pressure range.
%               
%                latitude - latitude at the location of sampling in degree
%                    north. Default 45.
%           
%
% Outputs:
%
%    binnedValues - Binned array
%
%    binCenter - Bin center values
%
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-02-07

%% Check input and default arguments
validBinBy = {'Pressure', 'Depth'};
checkBinBy = @(x) any(validatestring(x,validBinBy));

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'binBy', 'Pressure', checkBinBy);
addParameter(p, 'numRegimes', 1, @isnumeric);
addParameter(p, 'binSize', 1, @isnumeric);
addParameter(p, 'boundary', [], @isnumeric);
addParameter(p, 'latitude', 45, @isnumeric);
parse(p, RSK, channel, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
channel = p.Results.channel;
profileNum = p.Results.profileNum;
direction = p.Results.direction;
binBy = p.Results.binBy;
numRegimes = p.Results.numRegimes;
binSize = p.Results.binSize;
boundary = p.Results.boundary;
latitude = p.Results.latitude;



%% Determine if the structure has downcasts and upcasts & set profileNum accordingly
castdir = [direction 'cast'];
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



%% Bin Average each cast
[binnedValues, binCenter] = RSKbin(RSK, channel, 'profileNum', profileNum, ...
    'direction', direction, 'binBy', binBy, 'numRegimes', numRegimes, ...
    'binSize', binSize, 'boundary', boundary, 'latitude', latitude);



%% Interpolate bin Centers through time
t = RSK.profiles.(castdir).tstart(profileNum);
z = binCenter;
grid = 50;
dt = linspace(t(1),t(end), grid);
dz = linspace(z(1),z(end), grid);

[Xq,Yq] = meshgrid(dt, dz);
vq = interp2(t, z, binnedValues, Xq, Yq);

date = datestr(t(1), 'dd-mmm-yyyy');
if strcmp(binBy, 'Pressure')
    units = '(dbar)';
else
    units = '(m)';
end


[~,h] = contourf(dt, dz, vq, 90);


cb = colorbar;
cmocean('haline');
if strcmpi(channel, 'chlorophyll'), 
    cmocean('algae'); 
elseif strcmpi(channel, 'dissolved o'), 
    cmocean('oxy');
end
chanCol = strcmpi(channel, {RSK.channels.longName});
ylabel(cb, RSK.channels(chanCol).units, 'FontSize', 12)
title(sprintf('%s on %s', RSK.channels(chanCol).longName, date));
xlabel(sprintf('Time (UTC)'))
ylabel(sprintf('%s %s', binBy, units))
set(gca, 'YDir', 'reverse')
set(h, 'EdgeColor', 'none');
datetick('x')
end

