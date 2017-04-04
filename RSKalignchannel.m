
function [RSK] = RSKalignchannel(RSK, channel, lag, varargin)

% RSKalignchannel - Align a channel profiles using a specified lag.
%
% Syntax:  [RSK] = RSKalignchannel(RSK, channel, lag, [OPTIONS])
% 
% Applies the lag to minimize  "spikes". Typically used for conductivity
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
%                  shiftval - The values that will fill the shifted area,
%                     Options are 'nan', fills the removed samples of
%                     the shifted channel with NaNs', 'zeroOrderhold' fills
%                     the removed samples of the shifted channels with the
%                     first or last value repeated and 'union' will deleted
%                     the values of the OTHER channels that do not align
%                     with the shifted channel (note: this will reduce the
%                     size of your values array by "lag")
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
% Last revision: 2017-04-04

%% Check input and default arguments

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));

validShiftval = {'zeroOrderhold', 'union', 'nan'};
checkShiftval = @(x) any(validatestring(x,validShiftval));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel', @ischar);
addRequired(p, 'lag', @isnumeric);
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'shiftval', 'zeroOrderhold', checkShiftval);
parse(p, RSK, channel, lag, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
channel = p.Results.channel;
lag = p.Results.lag;
profileNum = p.Results.profileNum;
direction = p.Results.direction;
shiftval = p.Results.shiftval;

%% Determine if the structure has downcasts and upcasts
profileIdx = checkprofiles(RSK, profileNum, direction);
castdir = [direction 'cast'];


%% Check to make sure that lags are integers & one value of CTlag or one for each profile
lags = checklag(lag, profileIdx);


%% Apply lag
counter = 0;
channelCol = find(strcmpi(channel, {RSK.channels.longName}));

for ndx = profileIdx
    counter = counter + 1;       
    channelData = RSK.profiles.(castdir).data(ndx).values(:, channelCol);
    if strcmpi(shiftval, 'nan')
        channelShifted = shiftarray(channelData, lags(counter), 'nanpad');
    else
        channelShifted = shiftarray(channelData, lags(counter), 'zeroOrderhold');
    end
    RSK.profiles.(castdir).data(ndx).values(:, channelCol) = channelShifted;
    
    if strcmpi(shiftval, 'union')
       if lags(counter)>0 
           RSK.profiles.(castdir).data(ndx).values = RSK.profiles.(castdir).data(ndx).values(lags(counter)+1:end,:);
           RSK.profiles.(castdir).data(ndx).tstamp = RSK.profiles.(castdir).data(ndx).tstamp(lags(counter)+1:end);
       elseif lags(counter) <0 
           RSK.profiles.(castdir).data(ndx).values = RSK.profiles.(castdir).data(ndx).values(1:end-lags(counter),:);
           RSK.profiles.(castdir).data(ndx).tstamp = RSK.profiles.(castdir).data(ndx).tstamp(1:end-lags(counter));
       end
    end

end

%% Update log
if isempty(profileNum) && length(lag) == 1
    logentry = [channel ' aligned using a ' num2str(lags(1)) ' sample lag on all ' direction 'cast profiles.'];
    RSK = RSKappendtolog(RSK, logentry);
else
    for ndx = 1:length(profileIdx)
        logentry = [channel ' aligned using a ' num2str(lags(ndx)) ' sample lag on ' direction 'cast profile ' num2str(profileIdx(ndx)) '.'];
        RSK = RSKappendtolog(RSK, logentry);
    end
end
end

