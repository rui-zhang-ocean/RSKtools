function RSKplot2D(RSK, channel, varargin)

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
%   [Optional] - direction - the profile direction to consider. Must be either
%                   'down' or 'up'. Only needed if series is profile. Defaults to 'down'
%
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-04

%% Check input and default arguments

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));


%% Parse Inputs
p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'direction', 'down', checkDirection);
parse(p, RSK, channel, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
channel = p.Results.channel;
direction = p.Results.direction;

%% Determine if the structure has downcasts and upcasts & set profileNum accordingly
profileIdx = checkprofiles(RSK, [], direction);
castdir = [direction 'cast'];
binCenter = RSK.profiles.(castdir).(channel).binCenter;
binValues = RSK.profiles.(castdir).(channel).binValues;

t = RSK.profiles.(castdir).tstart;
b = imagesc(t, binCenter, binValues);
set(b, 'AlphaData', ~isnan(binValues)) %plot NaN values in white.
%daspect([2 80 1]); %There are 2 bins per y unit and approximately 80 profiles per day(x units)

% Set colorbar
chanCol = strcmpi(channel, {RSK.channels.longName});
cb = colorbar;
if exist('cmocean', 'file')==2 
    cb = colorbar;
    cmocean('haline');
    if strcmpi(channel, 'temperature')
        cmocean('thermal'); 
    elseif strcmpi(channel, 'chlorophyll')
        cmocean('algae'); 
    elseif strcmpi(channel, 'backscatter')
        cmocean('matter');
    elseif strcmpi(channel, 'phycoerythrin')
        cmocean('turbid');
    end
end
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



chanCol = strcmpi(channel, {RSK.channels.longName});
ylabel(cb, RSK.channels(chanCol).units, 'FontSize', 12)
title(sprintf('%s on %s', RSK.channels(chanCol).longName, date));
xlabel(sprintf('Time (UTC)'))
ylabel('Pressure(dbar)')
set(gca, 'YDir', 'reverse')
set(gcf, 'Renderer', 'painters')
set(h, 'EdgeColor', 'none');
datetick('x')

end

