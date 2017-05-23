
function [RSK] = RSKalignchannel(RSK, channel, lag, varargin)

% RSKalignchannel - Align a channel using a specified lag.
%
% Syntax:  [RSK] = RSKalignchannel(RSK, channel, lag, [OPTIONS])
% 
% Applies a time lag to a specified channel. Typically used for
% conductivity to minimize salinity spiking from C/T mismatches when
% the sensors are moving through regions of high vertical gradients.
%
% Inputs: 
%    [Required] - RSK - The input RSK structure.
%
%                 channel - Longname of channel to align (e.g. temperature).
%
%                 lag - The lag (in samples) to apply to the channel.
%                       A negative lag shifts the channel backward in
%                       time (earlier), while a positive lag shifts
%                       the channel forward in time (later).  To apply
%                       a different lag to each data field, specify the
%                       lags in a vector.
%
%    [Optional] - profileNum - Profile(s) to which the lag(s) are applied.
%                        Default all profiles.    
%
%                  shiftfill - The values that will fill the void left
%                        at the beginning or end of the time series; 'nan',
%                        fills the removed samples of the shifted channel
%                        with NaN, 'zeroorderhold' fills the removed
%                        samples of the shifted channels with the first or
%                        last value, 'mirror' fills the removed values with
%                        the reflection of the original end point, and
%                        'union' will remove the values of the OTHER
%                        channels that do not align with the shifted
%                        channel (note: this will reduce the size of values
%                        array by "lag" samples). 
%
% Outputs:
%    RSK - The RSK structure with aligned channel values.
%
% Example: 
%    rsk = RSKopen('file.rsk');
%    rsk = RSKreadprofiles(rsk, 1:10); % read first 10 downcasts
%
%   1. Temperature channel of first four profiles with the same lag value.
%    rsk = RSKalignchannel(rsk, 'temperature', 2, 'profileNum', 1:4);
%
%   2. Oxygen channel of first 4 profiles with profile-specific lags.
%    rsk = RSKalignchannel(rsk, 'Dissolved O', [2 1 -1 0], 'profileNum',1:4);
%
%   3. Conductivity channel from all downcasts with optimal lag calculated 
%      with RSKgetCTlag.m.
%    lags = RSKgetCTlag(rsk)
%    rsk = RSKalignchannel(rsk, 'Conductivity', lags);
%
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-23

validShiftfill = {'zeroorderhold', 'union', 'nan', 'mirror'};
checkShiftfill = @(x) any(validatestring(x,validShiftfill));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel', @ischar);
addRequired(p, 'lag', @isnumeric);
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'shiftfill', 'zeroorderhold', checkShiftfill);
parse(p, RSK, channel, lag, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
channel = p.Results.channel;
lag = p.Results.lag;
profileNum = p.Results.profileNum;
shiftfill = p.Results.shiftfill;

dataIdx = setdataindex(RSK, profileNum);
lags = checklag(lag, dataIdx);
channelCol = find(strcmpi(channel, {RSK.channels.longName}));

counter = 0;
for ndx = dataIdx
    counter = counter + 1;       
    channelData = RSK.data(ndx).values(:, channelCol);
    
    if strcmpi(shiftfill, 'union')
        channelShifted = shiftarray(channelData, lags(counter), 'zeroorderhold');
        RSK.data(ndx).values(:, channelCol) = channelShifted;
        if lags(counter) > 0 
            RSK.data(ndx).values = RSK.data(ndx).values(lags(counter)+1:end,:);
            RSK.data(ndx).tstamp = RSK.data(ndx).tstamp(lags(counter)+1:end);
        elseif lags(counter) < 0 
            RSK.data(ndx).values = RSK.data(ndx).values(1:end-lags(counter),:);
            RSK.data(ndx).tstamp = RSK.data(ndx).tstamp(1:end-lags(counter));
        end
    else 
        channelShifted = shiftarray(channelData, lags(counter), shiftfill);
        RSK.data(ndx).values(:, channelCol) = channelShifted;
    end

end

%% Update log
if length(lag) == 1
    logdata = logentrydata(RSK, profileNum, dataIdx);
    logentry = [channel ' aligned using a ' num2str(lags(1)) ' sample lag and ' shiftfill ' shiftfill on ' logdata '.'];
    RSK = RSKappendtolog(RSK, logentry);
else
    for ndx = 1:length(dataIdx)
        logdata = logentrydata(RSK, profileNum, dataIdx);
        logentry = [channel ' aligned using a ' num2str(lags(ndx)) ' sample lag and ' shiftfill ' shiftfill on data field ' num2str(dataIdx(ndx)) '.'];
        RSK = RSKappendtolog(RSK, logentry);
    end
end


%% Nested function
    function lags = checklag(lag, dataIdx)
    % A helper function used to check if the lag values are intergers and
    % either one for all profiles or one for each profiles.

        if ~isequal(fix(lag),lag),
            error('Lag values must be integers.')
        end

        if length(lag) == 1 && length(dataIdx) ~= 1
            lags = repmat(lag, 1, length(dataIdx));
        elseif length(lag) > 1 && length(lag) ~= length(dataIdx)
            error(['Length of lag must equal the number of profiles or be a ' ...
                   'single value']);
        else
            lags = lag;
        end

    end
end
