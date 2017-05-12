function im = RSKplot2D(RSK, channel, varargin)

% RSKplot2D - Plot profiles in a contour plot
%
% Syntax:  RSKplot2D(RSK, channel, direction)
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
%   [Optional] - profileNum - Optional profile number(s) to plot. Default
%                    is to use all profiles. 
%
%                direction - the profile direction to consider. Must be either
%                   'down' or 'up'. Defaults to 'down'.
%
%                reference - The channel that will be plotted as y. Default
%                   'Pressure', can be 'Depth'.
%
% Output:
%     im - Image object created, use to set properties.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-12

%% Check input and default arguments
validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));

%% Parse Inputs
p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'reference', 'Pressure', @ischar);
parse(p, RSK, channel, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
channel = p.Results.channel;
profileNum = p.Results.profileNum;
direction = p.Results.direction;
reference = p.Results.reference;

%% Determine if the structure has downcasts and upcasts & set profileNum accordingly
profileIdx = checkprofiles(RSK, profileNum, direction);
castdir = [direction 'cast'];

chanCol = getchannelindex(RSK, channel);

% Check bin center reference column.
YCol = getchannelindex(RSK, reference);
for ndx = profileIdx(1:end-1)
    if RSK.profiles.(castdir).data(ndx).values(:,YCol)==RSK.profiles.(castdir).data(ndx+1).values(:,YCol);
        binCenter = RSK.profiles.(castdir).data(ndx).values(:,YCol);
    else 
        error('The refence channel`s data of all the selected profiles must be identical. Use RSKbinaverage.m')
    end
end

binValues = NaN(length(binCenter), length(profileIdx));
for ndx = profileIdx;
    binValues(:,ndx) = RSK.profiles.(castdir).data(ndx).values(:,chanCol);
end

t = RSK.profiles.(castdir).tstart;
im = imagesc(t, binCenter, binValues);
set(im, 'AlphaData', ~isnan(binValues)) %plot NaN values in white.

% Set colorbar
setcolormap(channel);
cb = colorbar;
ylabel(cb, RSK.channels(chanCol).units, 'FontSize', 14)


% Set titles with positions
h = title(sprintf('%s', RSK.channels(chanCol).longName), 'FontSize', 16);
p = get(h,'Position');
set(h, 'Position', [t(end) p(2) p(3)], 'HorizontalAlignment', 'right')
text(t(1), p(2)-0.5, sprintf('[%s - %s]', datestr(t(1), 'mmmm dd HH:MM'), datestr(t(end),'mmmm dd HH:MM')), 'FontSize', 14);


% Adjust axes
set(gcf, 'Position', [1 1 800 450]);
ax = gca;
set(ax, 'YDir', 'reverse', 'FontSize', 14)
set(gcf, 'Renderer', 'painters')
datetick('x', 'HH', 'keepticks')
axis tight

ylabel(cb, RSK.channels(chanCol).units, 'FontSize', 12)
title(sprintf('%s on %s', RSK.channels(chanCol).longName, datestr(t(end))));
xlabel(sprintf('Time (UTC)'))
ylabel(sprintf('%s (%s)', RSK.channels(YCol).longName, RSK.channels(YCol).units));
set(gca, 'YDir', 'reverse')
set(gcf, 'Renderer', 'painters')
set(h, 'EdgeColor', 'none');
datetick('x')

end

