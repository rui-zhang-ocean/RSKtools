function [handles, data, x, y] = RSKimages(RSK, varargin)

% RSKimages - Plot profiles in a 2D plot.
%
% Syntax:  [handles, data, x, y] = RSKimages(RSK, [OPTIONS])
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
%   [Optional] - channel - Longname of channel to plot, can be multiple in
%                      a cell, if no value is given it will plot all
%                      channels.
%
%                profile - Profile numbers to plot. Default is to use all
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
%     handles - Image handles object created, use to set properties
%
%     data - data matrix
%
%     x - x axis vector in time
%
%     y - y axis vector in reference channel
%
% Example: 
%     handles = RSKimages(RSK,'direction','down'); 
%     OR
%     [handles, data, x, y] = RSKimages(RSK,'channel',{'Temperature','Conductivity'},'direction','down','interp',true,'threshold',600);
%
% See also: RSKbinaverage, RSKplotprofiles.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-10-12

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'channel', 'all');
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'reference', 'Sea Pressure', @ischar);
addParameter(p,'showgap', false, @islogical)
addParameter(p,'threshold', [], @isnumeric)
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
channel = p.Results.channel;
profile = p.Results.profile;
direction = p.Results.direction;
reference = p.Results.reference;
showgap = p.Results.showgap;
threshold = p.Results.threshold;


castidx = getdataindex(RSK, profile, direction);

chanCol = [];
channels = cellchannelnames(RSK, channel);
for chan = channels
    chanCol = [chanCol getchannelindex(RSK, chan{1})];
end
YCol = getchannelindex(RSK, reference);

for ndx = 1:length(castidx)-1
    if length(RSK.data(castidx(ndx)).values(:,YCol)) == length(RSK.data(castidx(ndx+1)).values(:,YCol));
        binCenter = RSK.data(castidx(ndx)).values(:,YCol);
    else 
        error('The reference channel data of all the selected profiles must be identical. Use RSKbinaverage.m for selected cast direction.')
    end
end
y = binCenter;
x = cellfun( @(x)  min(x), {RSK.data(castidx).tstamp});

data = NaN(length(binCenter),length(castidx),length(chanCol));

k = 1;
for c = chanCol

    binValues = NaN(length(binCenter), length(castidx));
    for ndx = 1:length(castidx)
        binValues(:,ndx) = RSK.data(castidx(ndx)).values(:,c);
    end
    data(:,:,k) = binValues;
    
    subplot(length(chanCol),1,k)
    if ~showgap
        handles(k) = pcolor(x, binCenter, binValues);
        shading interp
        set(handles(k), 'AlphaData', isfinite(binValues)); % plot NaN values in white.
    else
        unit_time = (x(2)-x(1)); 
        N = round((x(end)-x(1))/unit_time);
        x_itp = linspace(x(1), x(end), N);

        ind_mt = bsxfun(@(x,y) abs(x-y), x(:), reshape(x_itp,1,[]));
        [~, ind_itp] = min(ind_mt,[],2); 
        ind_nan = setxor(ind_itp, 1:length(x_itp));

        binValues_itp = interp1(x,binValues',x_itp)';
        binValues_itp(:,ind_nan) = NaN;

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
            x_itp(remove_gap_idx) = [];

            handles(k) = pcolor(x_itp, binCenter, binValues_itp);
            shading interp
        else
            handles(k) = imagesc(x_itp, binCenter, binValues_itp);       
        end 
        set(handles(k), 'AlphaData', isfinite(binValues_itp)); 
    end

    setcolormap(channels{k});
    cb = colorbar;
    ylabel(cb, RSK.channels(c).units, 'FontSize', 12)
    ylabel(sprintf('%s (%s)', RSK.channels(YCol).longName, RSK.channels(YCol).units));
    set(gca, 'YDir', 'reverse')
    h = title(RSK.channels(c).longName);
    set(gcf, 'Renderer', 'painters')
    set(h, 'EdgeColor', 'none');
    datetick('x')
    axis tight
    
    k = k + 1;
end
end

