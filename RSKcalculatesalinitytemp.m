function RSK = RSKcalculatesalinitytemp(RSK, varargin)

% RSKcalculatesalinity - Calculate salinity using TEOS-10, conductivity,
%                        temperature and pressure.
%
% Syntax:  [RSK] = RSKcalculatesalintyout(RSK, [OPTIONS])
% 
% This function calculates salinity using the TEOS-10 toolbox and fills the
% appropriate fields in channels field. If salinity is already calculated,
% it will recalculate it and overwrite that data column.
%
% Inputs:
%   [Required] - RSK - the input RSK structure
%
%   [Optional] - series - The series that will be despiked. Must be
%                   either 'data' or 'profile'. If 'data' must run RSKreaddata() 
%                   before RSKdespike, if 'profile' must first run RSKreadprofiles().
%                   Default is 'data'.
%
%                profileNum - Optional profile number to calculate lag.
%                    Default is to calculate the lag of all detected
%                    profiles
%            
%                direction - 'up' for upcast, 'down' for downcast, or 'both' for
%                    all. Default is 'down'.
%
% Outputs:
%    RSK - RSK structure containing the salinity data
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-02-09

%% Check input and default arguments

validSeries = {'profile', 'data'};
checkSeriesName = @(x) any(validatestring(x,validSeries));

validDirections = {'up', 'down'};
checkDirection = @(x) any(validatestring(x,validDirections));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'series', 'data', checkSeriesName);
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);% Only needed if series is 'profile'
parse(p, RSK, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
series = p.Results.series;
profileNum = p.Results.profileNum;
direction = p.Results.direction;


%% For Profiles: determine if the structure has downcasts and upcasts & set profileNum accordingl
if strcmp(series, 'profile')
    profileNum = checkprofiles(RSK, profileNum, direction);
    castdir = [direction 'cast'];
end


%% Check if Salinity ,TEOS-10 and CTD data are available.

hasS = any(strcmp({RSK.channels.longName}, 'Salinity'));
 
hasTEOS = exist('gsw_SP_from_C', 'file') == 2;
nchannels = length(RSK.channels);
if nchannels >= 3
    hasCTP = strcmpi(RSK.channels(1).longName, 'Conductivity') & strcmpi(RSK.channels(2).longName, 'Temperature') & strcmpi(RSK.channels(3).longName, 'Pressure');
else 
    hasCTP = 0;
end

if ~hasTEOS || ~hasCTP
    error('Missing TEOS-10 toolbox and/or CTP data');
end


%% Calculate Salinity

% Does the RSK have all 3 of conductivity, temperature, and pressure, but
% not salinity?
% First update all affected tables for a new channel.
if ~hasS
    if sum(strcmpi({RSK.channels.longName}, 'Salinity')) == 0
        RSK.channels(nchannels+1).longName = 'Salinity';
        RSK.channels(nchannels+1).units = 'PSU';
        % update the instrumentChannels info for the new "channel"
        if ~strcmpi(RSK.dbInfo(end).type, 'EasyParse')
            try
                RSK.instrumentChannels(nchannels+1).instrumentID = RSK.instrumentChannels(1).instrumentID;
            catch
            end
            if isfield(RSK.instrumentChannels, 'channelStatus')
                RSK.instrumentChannels(nchannels+1).channelStatus = 0;
            end
            RSK.instrumentChannels(nchannels+1).channelID = RSK.instrumentChannels(nchannels).channelID+1;
            RSK.instrumentChannels(nchannels+1).channelOrder = RSK.instrumentChannels(nchannels).channelOrder+1;
        end
    end
end


%% Second calculate Salinity, add to appropriate series.

Scol = strcmp({RSK.channels.longName}, 'Salinity');
switch series
    case 'profile'
        for ndx = profileNum
            data = RSK.profiles.(castdir).data(ndx);
            salinity = gsw_SP_from_C(data.values(:, 1), data.values(:, 2), data.values(:, 3)- 10.1325);
            RSK.profiles.(castdir).data(ndx).values(:,Scol) = salinity;
        end
    case 'data'
        data = RSK.data;
        salinity = gsw_SP_from_C(data.values(:, 1), data.values(:, 2), data.values(:, 3)- 10.1325);
        RSK.data.values(:,Scol) = salinity;
end


end



