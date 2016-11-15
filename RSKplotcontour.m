
%Plots a section plot through time of the water column using profile data.
function RSKplotcontour(RSK, channel, direction)

% RSKplotcontour - Plot profiles in a contour plot
%
% Syntax:  RSKplotcontour(RSK, channel, direction)
% 
% This generates a plot of the profiles over time. It despikes and bins the
% data for any specified channel. For salinity it also calculates the optimal lag
% and aligns each profile.
% 
% Inputs:
%    RSK - Structure containing the logger metadata and data
%
%
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-11-10

RSK = RSKdespike(RSK, channel, 'series', 'profile', 'direction', direction);

% Filtering function here?

if strcmpi(channel,'salinity') % Option for DO also?
    lags = RSKgetCTlag(RSK, 'direction', direction);
    RSK = RSKalignchannel(RSK, 'salinity', lags, 'direction', direction);
end

channelCol = find(strncmpi(channel, {RSK.channels.longName}, 4));
pressureCol = find(strncmpi('pressure', {RSK.channels.longName}, 4));
pressureCol = pressureCol(1);

switch direction
    case 'up'
        cast = RSK.profiles.upcast;
    case 'down'
        cast = RSK.profiles.downcast;
end

%% Bin
% Establish binning range.
minP = 100;
maxP = 0;
binBy = 'Depth';

for i = 1:size(cast.data,2)
    profileMin = min(cast.data(i).values(:,pressureCol));
    profileMax = max(cast.data(i).values(:,pressureCol));
    if profileMin < minP, minP = profileMin; end
    if profileMax > maxP, maxP = profileMax; end
end

binWidth = 0.5;
binArray = fix(minP):binWidth:ceil(maxP);

% Bin Average each cast
for i = 1:size(cast.data,2)
    [binValues, bins] = RSKbinAveraging(cast.data(i).values(:,channelCol), cast.data(i).values(:,pressureCol), 'Method', 'Array', 'binArray', binArray, 'binBy', binBy);
    channelbin(:,i) = binValues;
end

%% Interpolate
t = cast.tstart;
z = -bins;
grid = 500;
dt = linspace(t(1),t(end), grid);
dz = linspace(z(1),z(end), grid);

[Xq,Yq] = meshgrid(dt, dz);
vq = interp2(t, z, channelbin, Xq, Yq);

date = datestr(cast.tstart(1), 'dd-mmm-yyyy');
if strcmp(binBy, 'Pressure')
    units = '(dbar)';
else
    units = '(m)';
end

figure(1);
[~,h] = contourf(dt, dz, vq, 90);
cb = colorbar;
colormap parula
ylabel(cb, RSK.channels(channelCol).units, 'FontSize', 12)
title(sprintf('%s on %s', RSK.channels(channelCol).longName, date));
xlabel(sprintf('Time (UTC)'))
ylim(-[ bins(end) bins(1)])
ylabel(sprintf('%s %s', binBy, units));
set(h, 'EdgeColor', 'none');
datetick('x')

