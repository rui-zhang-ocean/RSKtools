function [RSK] = RSKalignchannel(RSK, channel, lag, varargin)

% RSKalignchannel - Align a channel profiles using a specified lag.
%
% Syntax:  [RSK] = RSKalignchannel(RSK, channel, lag, [OPTIONS])
% 
% Applies the lag to minimize  "spikes". Typically used for salinity
% to reverse the effects from temporal C/T mismatches when the
% sensors are moving through regions of high vertical gradients.
%
% Inputs: 
%    [Required] - RSK - The input RSK structure, with profiles as read using
%                     RSKreadprofiles.
%
%                 channel - Longname of channel to align (e.g. temperature)
%
%                 lag - The lag for each profile, or one lag for all.
%
%    [Optional] - profileNum - Optional profile number to calculate lag.
%                     Default is to calculate the lag of all detected
%                     profiles.
%
%                 direction - 'up' for upcast, 'down' for downcast, or 'both' for
%                     all. Default is 'down'.
%
% Outputs:
%    RSK - The RSK structure with aligned channel values.
%
% Example: 
%    rsk = RSKopen('file.rsk');
%    rsk = RSKreadprofiles(rsk, 1:10); % read first 10 downcasts
%
%   1. All downcast profiles with calculated optimal C/T lag.
%    lags = RSKgetCTlag(rsk)
%    rsk = RSKalignchannel(rsk, 'Conductivity', lags);
%
%   2. Specified profiles (first 4) and  lag values (one for each profile)
%    rsk = RSKalignchannel(rsk, 'Dissolved O', [2 1 -1 0], 'profileNum',1:4);
%
%   3. Specified profiles (first 4) and lag value (one for ALL profiles being aligned).
%    rsk = RSKalignchannel(rsk, 'temperature', [2], 'profileNum', 1:4);;
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-03-22

%% Check input and default arguments

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel', @ischar);
addRequired(p, 'lag', @isnumeric);
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
parse(p, RSK, channel, lag, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
channel = p.Results.channel;
lag = p.Results.lag;
profileNum = p.Results.profileNum;
direction = p.Results.direction;


%% Determine if the structure has downcasts and upcasts

profileIdx = checkprofiles(RSK, profileNum, direction);
castdir = [direction 'cast'];


%% Check to make sure that lags are integers & one value of CTlag or one for each profile

if ~isequal(fix(lag),lag),
    error('Lag values must be integers.')
end

if length(lag) == 1
    if length(profileIdx) == 1
        lags = lag;
    else
        lags = repmat(lag, 1, length(profileIdx));
    end
elseif length(lag) > 1
    if length(lag) ~= length(profileIdx)
        error(['Length of lag must match number of profiles or be a ' ...
               'single value']);
    else 
        lags = lag;
    end
else
    lags = lag;
end


%% Apply lag to any other channel.
counter = 0;
channelCol = find(strcmpi(channel, {RSK.channels.longName}));

for ndx = profileIdx
    counter = counter + 1;       
    channelData = RSK.profiles.(castdir).data(ndx).values(:, channelCol);
    channelShifted = shiftarray(channelData, lags(counter));
    RSK.profiles.(castdir).data(ndx).values(:, channelCol) = channelShifted;
end


%% Update log

if isempty(profileNum)
    logprofiles = ['all ' direction 'cast profiles'];
elseif length(profileIdx) == 1
    logprofiles = [direction 'cast profile ' num2str(profileIdx, '%1.0f')];
else 
    logprofiles = [direction 'cast profiles' num2str(profileIdx(1:end-1), ', %1.0f') ' and ' num2str(profileIdx(end)) ', respectively'];
end
logentry = sprintf('%s aligned using a %1.0f sample lag on %s .', channel, lag, logprofiles);

RSK = RSKappendtolog(RSK, logentry);
end

