function handles = RSKplotprofiles(RSK, varargin)

%RSKplotprofiles - Plot summaries of logger data as profiles.
%
% Syntax:  [handles] = RSKplotprofiles(RSK, [OPTIONS])
% 
% Plots profiles from automatically detected casts. The default is to plot
% all the casts of all channels available (excluding Pressure, Sea Pressure
% and Depth) against sea pressure (options to plot against depth).
% Optionally outputs a matrix of handles to the line objects.
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger metadata and data.
%
%    [Optional] - profile - Profile number to plot. Default is to plot 
%                        all detected profiles.
%
%                 channel - Variables to plot (e.g. temperature, salinity,
%                        etc). Default is all channel (excluding Pressure
%                        and Sea pressure).
% 
%                 direction - 'up' for upcast, 'down' for downcast or
%                        'both'. Default is to use all directions
%                        available.
% 
%                 reference - Channel plotted on the y axis for each
%                        subplot.
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
<<<<<<< HEAD
% Last revision: 2017-08-03
=======
% Last revision: 2017-07-20
>>>>>>> ac72076... Add option to plot against depth

validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

validReference = {'sea pressure', 'depth'};
checkReference = @(x) any(validatestring(x,validReference));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'channel', 'all')
addParameter(p, 'direction', [], checkDirection);
addParameter(p, 'reference', 'sea pressure', checkReference)
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
if strcmpi(reference, 'depth')
    ycol = getchannelindex(RSK, 'depth');
    RSKy = RSK;
else
    [RSKy, ycol] = getseapressure(RSK);
end

% In 2014a and earlier, lines plotted after calling 'hold on' results
% in are the same color as the original.  To overcome this, specify
% colors manually to overcome this behaviour.  Default in 2014b and
% later is to use the next color in axescolororder, but we proceed
% with the following fix anyway because it is compatible with 2014b
% and later.
clrs = get(0,'defaultaxescolororder');
ncast = length(castidx); % up and down are both casts
clrs = repmat(clrs,ceil(ncast/7),1);
clrs = clrs(1:ncast,:);



pmax = 0;
n = 1;
for chan = chanCol
    subplot(1,numchannels,n)
    ii = 1;
    for ndx = castidx
<<<<<<< HEAD
        seapressure = RSKsp.data(ndx).values(:, SPcol);
        ydata = RSKy.data(ndx).values(:, ycol);
        handles(ii,n) = plot(RSK.data(ndx).values(:, chan), ydata,'color',clrs(ii,:));
=======
        ydata = RSKy.data(ndx).values(:, ycol);
        handles(ii,n) = plot(RSK.data(ndx).values(:, chan), ydata);
>>>>>>> ac72076... Add option to plot against depth
        hold on
        pmax = max([pmax; ydata]);
        ii = ii+1;
    end
    ylim([0 pmax])
    title(RSK.channels(chan).longName);
    xlabel(RSK.channels(chan).units);
<<<<<<< HEAD
    ylabel('Sea pressure [dbar]')
    ylabel([RSKy.channels(ycol).longName ' [' RSKy.channels(ycol).units ']'])
    n = n+1;
    grid on
=======
    ylabel([RSKy.channels(ycol).longName ' [' RSKy.channels(ycol).units ']'])
    set(gca, 'ydir', 'reverse')
    ax(n) = gca;
    ax(n).ColorOrderIndex = 1; 
    n = n+1 ;
    grid
    hold off
>>>>>>> ac72076... Add option to plot against depth
end
ax = findall(gcf,'type','axes');
set(ax, 'ydir', 'reverse')
linkaxes(ax,'y')
shg

end
