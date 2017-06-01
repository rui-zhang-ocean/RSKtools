function handles = RSKplotprofiles(RSK, varargin)

% RSKplotprofiles - Plot profiles from an RSK structure output by 
%                   RSKreadprofiles.
%
% Syntax:  [handles] = RSKplotprofiles(RSK, [OPTIONS])
% 
% Plots profiles from automatically detected casts. If called with one
% argument, will default to plotting downcasts of temperature for all
% elements in the data field.  Optionally outputs an array of handles
% to the line objects.
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger metadata and data
%
%    [Optional] - profile - Optional profile number to plot. Default is to plot 
%                        all detected profiles.
%
%                 channel - Variable to plot (e.g. temperature, salinity,
%                        etc). Default is 'Temperature'.
% 
%                 direction - 'up' for upcast, 'down' for downcast or
%                        'both'. Default is 'down'.
%
% Output:
%     handles - The line object of the plot.
%
% Examples:
%    rsk = RSKopen('profiles.rsk');
%    rsk = RSKreadprofiles(rsk);
%    % plot selective downcasts and output handles
%      for customization
%    hdls = RSKplotprofiles(rsk, 'profile', [1 5 10], 'channel', 'conductivity');
%
% See also: RSKreadprofiles, RSKreaddata.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-30

validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'channel', 'Temperature', @ischar)
addParameter(p, 'direction', 'down', checkDirection);
parse(p, RSK, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
profile = p.Results.profile;
channel = p.Results.channel;
direction = p.Results.direction;



[RSKsp, SPcol] = getseapressure(RSK);
chanCol = getchannelindex(RSK, channel);
castidx = getdataindex(RSK, profile, direction);

pmax = 0;
ii = 1;
for ndx = castidx
    seapressure = RSKsp.data(ndx).values(:, SPcol);
    handles(ii) = plot(RSK.data(ndx).values(:, chanCol), seapressure);
    hold on
    pmax = max([pmax; seapressure]);
    ii = ii+1;
end



ax = gca; 
ax.ColorOrderIndex = 1; 
grid
xlab = [RSK.channels(chanCol).longName ' [' RSK.channels(chanCol).units ']'];
ylim([0 pmax])
set(gca, 'ydir', 'reverse')
ylabel('Sea pressure [dbar]')
xlabel(xlab)
title('Profile')
hold off

end
