function hdls = RSKplotprofiles(RSK, varargin)

% RSKplotprofiles - Plot profiles from an RSK structure output by 
%                   RSKreadprofiles.
%
% Syntax:  RSKplotprofiles(RSK, profileNum, channel, direction)
% 
% Plots profiles from automatically detected casts. If called with one
% argument, will default to plotting downcasts of temperature for all
% profiles in the structure.  Optionally outputs an array of handles
% to the line objects.
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger metadata and data
%
%    [Optional] - profileNum - Optional profile number to plot. Default is to plot 
%                          all detected profiles.
%
%                 channel - Variable to plot (e.g. temperature, salinity, etc).
%
% Output:
%     hdls - The line object of the plot.
%
% Examples:
%    rsk = RSKopen('profiles.rsk');
%    rsk = RSKreadprofiles(rsk);
%    % plot selective downcasts and output handles
%      for customization
%    hdls = RSKplotprofiles(rsk, 'profileNum', [1 5 10], 'channel', 'conductivity');
%
% See also: RSKreadprofiles, RSKreaddata.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-23

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addOptional(p, 'profileNum', [], @isnumeric);
addOptional(p, 'channel', 'Temperature', @ischar)
parse(p, RSK, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
profileNum = p.Results.profileNum;
channel = p.Results.channel;

[RSKsp, SPcol] = getseapressure(RSK);
chanCol = getchannelindex(RSK, channel);
dataIdx = setdataindex(RSK, profileNum);

pmax = 0;
ii = 1;
for ndx=dataIdx
    seapressure = RSKsp.data(ndx).values(:, SPcol);
    hdls(ii) = plot(RSK.data(ndx).values(:, chanCol), seapressure);
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
