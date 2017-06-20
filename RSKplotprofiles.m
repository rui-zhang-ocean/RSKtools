function handles = RSKplotprofiles(RSK, varargin)

% RSKplotprofiles - Plot summaries of logger data as profiles.
%
% Syntax:  [handles] = RSKplotprofiles(RSK, [OPTIONS])
% 
% Plots profiles from automatically detected casts. If called with one
% argument, will default to plotting dowall the casts of all channels
% available. Optionally outputs an array of handles to the line objects. 
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger metadata and data
%
%    [Optional] - profile - Optional profile number to plot. Default is to plot 
%                        all detected profiles.
%
%                 channel - Variables to plot (e.g. temperature, salinity,
%                        etc). Default is all.
% 
%                 direction - 'up' for upcast, 'down' for downcast or
%                        'both'.
%
% Output:
%     handles - The line object of the plot.
%
% Examples:
%    rsk = RSKopen('profiles.rsk');
%    rsk = RSKreadprofiles(rsk, 'direction', 'down');
%    % plot selective downcasts and output handles
%      for customization
%    hdls = RSKplotprofiles(rsk, 'profile', [1 5 10], 'channel', {'Conductivity', 'Temperature'});
%
% See also: RSKreadprofiles, RSKreaddata.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-20

validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'channel', 'all')
addParameter(p, 'direction', [], checkDirection);
parse(p, RSK, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
profile = p.Results.profile;
channel = p.Results.channel;
direction = p.Results.direction;



[RSKsp, SPcol] = getseapressure(RSK);
if strcmp(channel, 'all')
    chanCol = 1:length({RSK.channels.longName});
else
    chanCol = [];
    channels = cellchannelnames(RSK, channel);
    for chan = channels
        chanCol = [chanCol getchannelindex(RSK, chan{1})];
    end
end
numchannels = length(chanCol);
castidx = getdataindex(RSK, profile, direction);


pmax = 0;
n = 1;
for chan = chanCol
    subplot(1,numchannels,n)
    ii = 1;
    for ndx = castidx
        seapressure = RSKsp.data(ndx).values(:, SPcol);
        handles(ii,n) = plot(RSK.data(ndx).values(:, chan), seapressure);
        hold on
        pmax = max([pmax; seapressure]);
        ii = ii+1;
    end
    ylim([0 pmax])
    title(RSK.channels(chan).longName);
    xlabel(RSK.channels(chan).units);
    ylabel('Sea pressure [dbar]')
    set(gca, 'ydir', 'reverse')
    ax(n) = gca;
    ax(n).ColorOrderIndex = 1; 
    n = n+1 ;
    grid
    hold off
end
linkaxes(ax,'y')
shg


end
