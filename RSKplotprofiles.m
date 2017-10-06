function handles = RSKplotprofiles(RSK, varargin)

%RSKplotprofiles - Plot summaries of logger data as profiles.
%
% Syntax:  [handles] = RSKplotprofiles(RSK, [OPTIONS])
% 
% Plots profiles from automatically detected casts. The default is to
% plot all the casts of all channels available (excluding pressure,
% sea pressure and depth) against sea pressure or, optionally, depth.
% Optionally outputs a matrix of handles to the line objects.
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger metadata and data.
%
%    [Optional] - profile - Profile number to plot. Default is to plot 
%                        all detected profiles.
%
%                 channel - Variables to plot (e.g., temperature, salinity,
%                        etc). Default is all channel (excluding pressure
%                        and sea pressure).
% 
%                 direction - 'up' for upcast, 'down' for downcast or
%                        'both'. Default is to use all directions
%                        available. When choosing 'both', downcasts are
%                        plotted with solid lines and upcasts are plotted
%                        with dashed lines.
% 
%                 reference - Channel plotted on the y axis for each
%                        subplot. Default is sea pressure, option for
%                        depth.
%
% Output:
%     handles - Line object of the plot.
%
% Examples:
%    rsk = RSKopen('profiles.rsk');
%    rsk = RSKreadprofiles(rsk, 'direction', 'down');
%    % plot selective downcasts and output handles for customization 
%    hdls = RSKplotprofiles(rsk, 'profile', [1 5 10], 'channel', {'Conductivity', 'Temperature'});
%
% See also: RSKreadprofiles, RSKreaddata.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-10-03

validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

validReference = {'Sea Pressure', 'Depth'};
checkReference = @(x) any(validatestring(x,validReference));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'channel', 'all')
addParameter(p, 'direction', [], checkDirection);
addParameter(p, 'reference', 'Sea Pressure', checkReference)
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
profile = p.Results.profile;
channel = p.Results.channel;
direction = p.Results.direction;
reference = p.Results.reference;



chanCol = [];
channels = cellchannelnames(RSK, channel);
for chan = channels
    if ~(strcmp(chan, 'Pressure') || strcmp(chan, 'Sea Pressure') || strcmp(chan, 'Depth'))
        chanCol = [chanCol getchannelindex(RSK, chan{1})];
    end
end
numchannels = length(chanCol);

castidx = getdataindex(RSK, profile, direction);
if strcmpi(reference, 'Depth')
    ycol = getchannelindex(RSK, 'Depth');
    RSKy = RSK;
else
    [RSKy, ycol] = getseapressure(RSK);
end

% In 2014a and earlier, lines plotted after calling 'hold on' are
% drawn with the first colour in defaultaxescolororder, whereas we
% prefer to use a different colour for each cast.  Although the
% default behaviour in 2014b is to step through defaultaxescolororder,
% we proceed with the following fix anyway because it is compatible
% with 2014b and later.
clrs = get(0,'defaultaxescolororder');
ncast = length(castidx); % up and down are both casts
clrs = repmat(clrs,ceil(ncast/7),1);
clrs = clrs(1:ncast,:);



pmax = 0;
n = 1;
for chan = chanCol
    subplot(1,numchannels,n)
    
    if strcmp(direction, 'both') % downcast in solid and upcast in dashed line with the same color
        ii = 1;
        for ndx = castidx(1:2:end) 
            
            if strcmp(RSKy.data(1).direction,'down') % first cast is downcast
                ydata = RSKy.data(ndx).values(:, ycol);
                handles(ii,n) = plot(RSK.data(ndx).values(:, chan), ydata,'color',clrs(ii,:),'linestyle','-');
                hold on
                ydata = RSKy.data(ndx+1).values(:, ycol);
                handles(ii,n) = plot(RSK.data(ndx+1).values(:, chan), ydata,'color',clrs(ii,:),'linestyle','--');
            else % first cast is upcast
                ydata = RSKy.data(ndx).values(:, ycol);
                handles(ii,n) = plot(RSK.data(ndx).values(:, chan), ydata,'color',clrs(ii,:),'linestyle','--');
                hold on
                ydata = RSKy.data(ndx+1).values(:, ycol);
                handles(ii,n) = plot(RSK.data(ndx+1).values(:, chan), ydata,'color',clrs(ii,:),'linestyle','-');
            end
            
            pmax = max([pmax; ydata]);
            ii = ii+1;
        end
    else  % all solid line if only downcast or upcast is chosen
        ii = 1;
        for ndx = castidx 
            ydata = RSKy.data(ndx).values(:, ycol);
            handles(ii,n) = plot(RSK.data(ndx).values(:, chan), ydata,'color',clrs(ii,:));
            hold on
            pmax = max([pmax; ydata]);
            ii = ii+1;
        end
    end
    
    ylim([0 pmax])
    title(RSK.channels(chan).longName);
    xlabel(RSK.channels(chan).units);
    ylabel([RSKy.channels(ycol).longName ' [' RSKy.channels(ycol).units ']'])
    n = n+1;
    grid on
end
ax = findall(gcf,'type','axes');
set(ax, 'ydir', 'reverse')
linkaxes(ax,'y')
shg

end