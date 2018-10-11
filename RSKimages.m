function [handles, data2D, X, Y] = RSKimages(RSK, channel, varargin)

% RSKimages - Plot profiles in a 2D plot.
%
% Syntax:  [handles, data2D, X, Y] = RSKimages(RSK, channel, [OPTIONS])
% 
% Generates a plot of the profiles over time. The x-axis is time; the
% y-axis is a reference channel. All data elements must have identical
% reference channel samples. Use RSKbinaverage.m to achieve this. 
%
% Note: If installed, RSKimages will use the perceptually uniform 
%       oceanographic colourmaps in the cmocean toolbox:
%       https://www.mathworks.com/matlabcentral/fileexchange/57773-cmocean-perceptually-uniform-colormaps
%        
%       http://dx.doi.org/10.5670/oceanog.2016.66        
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
%                showgap - Plotting with interpolated profiles onto a 
%                      regular time grid, so that gaps between each
%                      profile can be shown when set as true. Default is 
%                      false. 
%          
%                threshold - Time threshold in seconds to determine the
%                      maximum  gap length shown on the plot. Any gap 
%                      smaller than the threshold will not show. 
%
% Output:
%     handles - Image object created, use to set properties.
%
%     data2D - Plotted data matrix.
%
%     X - X axis vector in time.
%
%     Y - Y axis vector in sea pressure.
%
% Example: 
%     handles = RSKimages(RSK,'Temperature','direction','down'); 
%     OR
%     [handles, data2D, X, Y] = RSKimages(RSK,'Temperature','direction','down','interp',true,'threshold',1);
%
% See also: RSKbinaverage, RSKplotprofiles.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-09-25

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'reference', 'Sea Pressure', @ischar);
addParameter(p,'showgap', false, @islogical)
addParameter(p,'threshold', [], @isnumeric)
parse(p, RSK, channel, varargin{:})

RSK = p.Results.RSK;
channel = p.Results.channel;
profile = p.Results.profile;
direction = p.Results.direction;
reference = p.Results.reference;
showgap = p.Results.showgap;
threshold = p.Results.threshold;


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
Y = binCenter;

binValues = NaN(length(binCenter), length(castidx));
for ndx = 1:length(castidx)
    binValues(:,ndx) = RSK.data(castidx(ndx)).values(:,chanCol);
end
t = cellfun( @(x)  min(x), {RSK.data(castidx).tstamp});

if ~showgap
    data2D = binValues;
    X = t;
    handles = pcolor(t, binCenter, binValues);
    shading interp
    set(handles, 'AlphaData', isfinite(binValues)); % plot NaN values in white.
else
    unit_time = (t(2)-t(1)); 
    N = round((t(end)-t(1))/unit_time);
    t_itp = linspace(t(1), t(end), N);
    X = t_itp;
    
    ind_mt = bsxfun(@(x,y) abs(x-y), t(:), reshape(t_itp,1,[]));
    [~, ind_itp] = min(ind_mt,[],2); 
    ind_nan = setxor(ind_itp, 1:length(t_itp));

    binValues_itp = interp1(t,binValues',t_itp)';
    binValues_itp(:,ind_nan) = NaN;
    data2D = binValues_itp;
    
    if ~isempty(threshold);
        diff_idx = diff(ind_itp);
        gap_idx = find(diff_idx > 1);

        remove_gap_idx = [];
        for g = 1:length(gap_idx)
            temp_idx = ind_itp(gap_idx(g))+1 : ind_itp(gap_idx(g))+1+diff_idx(gap_idx(g))-2;
            if length(temp_idx)*unit_time*86400 < threshold; % seconds
                remove_gap_idx = [remove_gap_idx, temp_idx];
            end
        end

        binValues_itp(:,remove_gap_idx) = [];
        t_itp(remove_gap_idx) = [];
        
        handles = pcolor(t_itp, binCenter, binValues_itp);
        shading interp
    else
        handles = imagesc(t_itp, binCenter, binValues_itp);       
    end 
    set(handles, 'AlphaData', isfinite(binValues_itp)); 
end

setcolormap(channel);
cb = colorbar;
ylabel(cb, RSK.channels(chanCol).units, 'FontSize', 12)
ylabel(sprintf('%s (%s)', RSK.channels(YCol).longName, RSK.channels(YCol).units));
set(gca, 'YDir', 'reverse')
h = title(RSK.channels(chanCol).longName);
set(gcf, 'Renderer', 'painters')
set(h, 'EdgeColor', 'none');
datetick('x')
axis tight

end

