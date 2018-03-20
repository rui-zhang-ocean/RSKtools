function im = RSKplot2D(RSK, channel, varargin)

% RSKplot2D - Plot profiles in a 2D plot.
%
% Syntax:  [im] = RSKplot2D(RSK, channel, [OPTIONS])
% 
% Generates a plot of the profiles over time. The x-axis is time; the
% y-axis is a reference channel. All data elements must have identical
% reference channel samples. Use RSKbinaverage.m to achieve this. 
%
% Note: To have access to colormaps download the cmocean toolbox :
% https://www.mathworks.com/matlabcentral/fileexchange/57773-cmocean-perceptually-uniform-colormaps
%
% Inputs:
%   [Required] - RSK - Structure, with profiles as read using RSKreadprofiles.
%
%                channel - Longname of channel to plot (e.g. temperature,
%                      salinity, etc).
%
%   [Optional] - profile - Profile numbers to plot. Default is to use all
%                      available profiles.  
%
%                direction - 'up' for upcast, 'down' for downcast. Default
%                      is down.
%
%                reference - Channel that will be plotted as y. Default
%                      'Sea Pressure', can be any other channel.
%
% Output:
%     im - Image object created, use to set properties.
%
% See also: RSKbinaverage, RSKplotprofiles.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-07-06

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'reference', 'Sea Pressure', @ischar);
parse(p, RSK, channel, varargin{:})

RSK = p.Results.RSK;
channel = p.Results.channel;
profile = p.Results.profile;
direction = p.Results.direction;
reference = p.Results.reference;



castidx = getdataindex(RSK, profile, direction);
chanCol = getchannelindex(RSK, channel);
YCol = getchannelindex(RSK, reference);
for ndx = 1:length(castidx)-1
    if length(RSK.data(castidx(ndx)).values(:,YCol)) == length(RSK.data(castidx(ndx+1)).values(:,YCol));
        binCenter = RSK.data(castidx(ndx)).values(:,YCol);
    else 
        error('The reference channel data of all the selected profiles must be identical. Use RSKbinaverage.m for selected cast direction.')
    end
end

binValues = NaN(length(binCenter), length(castidx));
for ndx = 1:length(castidx)
    binValues(:,ndx) = RSK.data(castidx(ndx)).values(:,chanCol);
end
t = cellfun( @(x)  min(x), {RSK.data(castidx).tstamp});

% Interpolation
N = round((t(end)-t(1))/(t(2)-t(1)));
t_itp = linspace(t(1), t(end), N);

ind_mt = bsxfun(@(x,y) abs(x-y), t(:), reshape(t_itp,1,[]));
[~, ind_itp] = min(ind_mt,[],2); 
ind_nan = setxor(ind_itp, 1:length(t_itp));

binValues_itp = interp1(t,binValues',t_itp)';
binValues_itp(:,ind_nan) = NaN;

% Plot
im = imagesc(t_itp, binCenter, binValues_itp);
set(im, 'AlphaData', isfinite(binValues_itp)) %plot NaN values in white.

setcolormap(channel);
cb = colorbar;
ylabel(cb, RSK.channels(chanCol).units)
set(gcf, 'Position', [1 1 800 450]);
datetick('x', 'HH', 'keepticks')
axis tight

ylabel(cb, RSK.channels(chanCol).units, 'FontSize', 12)
xlabel(sprintf('Time (UTC)'))
ylabel(sprintf('%s (%s)', RSK.channels(YCol).longName, RSK.channels(YCol).units));
set(gca, 'YDir', 'reverse')

h = title(sprintf('%s on %s', RSK.channels(chanCol).longName, datestr(t(end))));
p = get(h,'Position');
set(h, 'Position', [t(end) p(2) p(3)], 'HorizontalAlignment', 'right')

set(gcf, 'Renderer', 'painters')
set(h, 'EdgeColor', 'none');
datetick('x')

end

