function hdls = RSKplotprofiles(RSK, varargin)

% RSKplotprofiles - Plot profiles from an RSK structure output by 
%                   RSKreadprofiles.
%
% Syntax:  RSKplotprofiles(RSK, profileNum, field, direction)
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
%                 field - Variable to plot (e.g. temperature, salinity, etc).
%                          List of available variables is contained within
%                          the RSK structure (e.g. RSK.channels.longName).
%            
%                 direction - 'up' for upcast, 'down' for downcast, or
%                          'both' for all. Default is 'both'. 
%

% Examples:
%
%    rsk = RSKopen('profiles.rsk');
%
%    % read all profiles
%    rsk = RSKreadprofiles(rsk);
%
%    % plot all profiles
%    RSKplotprofiles(rsk);
%
%    % plot selective downcasts
%    RSKplotprofiles(rsk, [1 5 10]);
%
%    % plot conductivity for selective downcasts and output handles
%      for customization
%    hdls = RSKplotprofiles(rsk, [1 5 10], 'conductivity');
%
% See also: RSKreadprofiles, RSKreaddata, RSKreadevents
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-08


validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));
%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addOptional(p, 'profileNum', [], @isnumeric);
addOptional(p, 'channel', 'Temperature', @ischar)
addOptional(p, 'direction', 'down', checkDirection)

parse(p, RSK, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
profileNum = p.Results.profileNum;
channel = p.Results.channel;
direction = p.Results.direction;


% find column number of field
pCol = getchannelindex(RSK, 'Pressure');
chanCol = getchannelindex(RSK, channel);

% clf
ax = gca; 
ax.ColorOrderIndex = 1;
pmax = 0;
ii = 1;
if strcmp(direction, 'up') || strcmp(direction, 'both')
    profileIdx = checkprofiles(RSK, profileNum, 'up');
    for ndx=profileIdx
        p = RSK.profiles.upcast.data(ndx).values(:, pCol) - 10.1325;
        hdls(ii) = plot(RSK.profiles.upcast.data(ndx).values(:, chanCol), p);
        hold on
        pmax = max([pmax; p]);
        ii = ii+1;
    end
end

if strcmp(direction, 'both') 
    ax = gca; 
    ax.ColorOrderIndex = 1; 
end

if strcmp(direction, 'down') || strcmp(direction, 'both')
    profileIdx = checkprofiles(RSK, profileNum, 'down');    
    for ndx=profileIdx
        p = RSK.profiles.downcast.data(ndx).values(:, pCol) - 10.1325;
        hdls(ii) = plot(RSK.profiles.downcast.data(ndx).values(:, chanCol), p);
        hold on
        pmax = max([pmax; p]);
        ii = ii+1;
    end
end
grid

xlab = [RSK.channels(chanCol).longName ' [' RSK.channels(chanCol).units, ']'];
ylim([0 pmax])
set(gca, 'ydir', 'reverse')
ylabel('Sea pressure [dbar]')
xlabel(xlab)
if strcmp(direction, 'down')
    title('Downcasts')
elseif strcmp(direction, 'up')
    title('Upcasts')
elseif strcmp(direction, 'both')
    title('Downcasts and Upcasts')
end
hold off
