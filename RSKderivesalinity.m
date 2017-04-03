function [RSK, salinity] = RSKderivesalinity(RSK, varargin)

% RSKderivesalinity - Calculate salinity and add it or replace it in the data table
%
% Syntax:  [RSK] = RSKderivesalinty(RSK, [OPTIONS])
% 
% This function derives salinity using the TEOS-10 toolbox and fills the
% appropriate fields in channels field and data or profile field. If salinity is
% already calculated, it will recalculate it and overwrite that data
% column. 
% This function requires TEOS-10 to be downloaded and in the path
% (http://www.teos-10.org/software.htm)
%
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger metadata and data
%
%               
%    [Optional] - series - Specifies the series to be filtered. Either 'data'
%                     or 'profile'. Default is 'data'.
%            
%                 direction - 'up' for upcast, 'down' for downcast, or 'both' for
%                     all. Default is 'down'.
%
% Outputs:
%    RSK - RSK structure containing the salinity data
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-03-30


%% Check input and default arguments

validSeries = {'profile', 'data'};
checkSeriesName = @(x) any(validatestring(x,validSeries));

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'series', 'data', checkSeriesName)
addParameter(p, 'direction', 'down', checkDirection);
parse(p, RSK, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
series = p.Results.series;
direction = p.Results.direction;


%% Determine if the structure has downcasts and upcasts

if strcmpi(series, 'profile')
    profileNum = [];
    profileIdx = checkprofiles(RSK, profileNum, direction);
    castdir = [direction 'cast'];
end


%% Check TEOS-10 and CTP data are available.
 
if isempty(which('gsw_SP_from_C'))
    error('RSKtools requires TEOS-10 toolbox to derive salinity. Download it here: http://www.teos-10.org/software.htm');
end
    
if length(RSK.channels) < 3 || ~any(strcmpi({RSK.channels.longName}, 'Conductivity')) || ~any(strcmpi({RSK.channels.longName}, 'Temperature')) || ~any(strcmpi({RSK.channels.longName}, 'Pressure'))
    error('Conductivity, Temperature and Pressure are required to calculate Salinity');
end


%% Calculate Salinity
hasS = any(strcmp({RSK.channels.longName}, 'Salinity'));
nchannels = length(RSK.channels);

if ~hasS
    RSK.channels(nchannels+1).longName = 'Salinity';
    RSK.channels(nchannels+1).units = 'PSU';
    % update the instrumentChannels info for the new "channel"
    if isfield(RSK, 'instrumentChannels')
        if isfield(RSK.instrumentChannels, 'instrumentID')
            RSK.instrumentChannels(nchannels+1).instrumentID = RSK.instrumentChannels(1).instrumentID;
        end
        if isfield(RSK.instrumentChannels, 'channelStatus')
            RSK.instrumentChannels(nchannels+1).channelStatus = 0;
        end
        RSK.instrumentChannels(nchannels+1).channelID = RSK.instrumentChannels(nchannels).channelID+1;
        RSK.instrumentChannels(nchannels+1).channelOrder = RSK.instrumentChannels(nchannels).channelOrder+1;
    end
end



Scol = strcmpi({RSK.channels.longName}, 'Salinity');
Ccol = strcmpi({RSK.channels.longName}, 'Conductivity');
Tcol = strcmpi({RSK.channels.longName}, 'Temperature');
Pcol = strcmpi({RSK.channels.longName}, 'Pressure');

switch series
    case 'data'
        data = RSK.data;
        salinity = gsw_SP_from_C(data.values(:, Ccol), data.values(:, Tcol), data.values(:, Pcol)- 10.1325);
        RSK.data.values(:,Scol) = salinity;
    case 'profile'
        for ndx = profileIdx
            data = RSK.profiles.(castdir).data(ndx);
            salinity = gsw_SP_from_C(data.values(:, Ccol), data.values(:, Tcol), data.values(:, Pcol)- 10.1325);
            RSK.profiles.(castdir).data(ndx).values(:,Scol) = salinity;
        end
end

end


