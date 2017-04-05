function [RSK, spikeidx] = RSKdespike(RSK, channel, varargin)

% RSKdespike - De-spike a time series by comparing it to a reference time
%              series
%
% Syntax:  [RSK, spikeidx] = RSKdespike(RSK, channel, [OPTIONS])
% 
% RSKdespike compares the time series to a reference series. The reference
% series is the time series filtered with a median filter of length
% 'windowLength'. Each point in the original series is compared against the
% reference series. If a sample is greater than 'threshold' standard
% deviations of the residual between the original series and the reference
% series; the sample is considered a spike. The default behaviour is to
% replace the spikes with the reference value.
%
% Inputs:
%   [Required] - RSK - The input RSK structure
%
%                channel - Longname of channel to despike (e.g. temperature,
%                    salinity, etc).
%
%   [Optional] - series - Specifies the series to be filtered. Either 'data'
%                    or 'profile'. Default is 'data'.
%
%                profileNum - Optional profile number. Default is to
%                    calculate the lag of all detected profiles.
%            
%                direction - 'up' for upcast, 'down' for downcast, or 'both' for
%                    all. Default is 'down'.
%
%                threshold - The number of standard deviations to use for
%                    the spike criterion. Default value is 4.
%
%                windowLength - The total size of the filter window. Must
%                    be odd. Default is 3.
%
%                action - The action to perform on a spike. The default,
%                    'NaN' to leave the spike as a missing value. Can also
%                    be 'replace' is to replace it with the reference
%                    value or 'interp' to interpolate based on 'good' 
%                    values.
%
% Outputs:
%    RSK - The RSK structure with de-spiked series.
%
%    spikeidx - A structure containing the index of the spikes; if profiles
%        were despiked, spikeidx is a structure with a field for each profile.
%
% Example: 
%    [RSK, spikesidx] = RSKdespike(RSK,  'Pressure')
%   OR
%    [RSK, spikesidx] = RSKdespike(RSK, 'Temperature', 'threshold',2, 'windowLength',10, 'action','NaN');
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-03-22


%% Check input and default arguments

validSeries = {'profile', 'data'};
checkSeriesName = @(x) any(validatestring(x,validSeries));

validDirections = {'up', 'down'};
checkDirection = @(x) any(validatestring(x,validDirections));

validActions = {'replace', 'interp', 'NaN'};
checkAction = @(x) any(validatestring(x,validActions));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'series', 'data', checkSeriesName);
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'threshold', 4, @isnumeric);
addParameter(p, 'windowLength', 7, @isnumeric);
addParameter(p, 'action', 'NaN', checkAction);
addParameter(p, 'direction', 'down', checkDirection);% Only needed if series is 'profile'
parse(p, RSK, channel, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
channel = p.Results.channel;
series = p.Results.series;
direction = p.Results.direction;
profileNum = p.Results.profileNum;
windowLength = p.Results.windowLength;
threshold = p.Results.threshold;
action = p.Results.action;


%% For Profiles: determine if the structure has downcasts and upcasts & set profileNum accordingly

if strcmp(series, 'profile')
    profileIdx = checkprofiles(RSK, profileNum, direction);
    castdir = [direction 'cast'];
end


%% Despike

channelCol = strcmpi(channel, {RSK.channels.longName});
switch series
    case 'profile'  
        for ndx = profileIdx
            x = RSK.profiles.(castdir).data(ndx).values(:,channelCol);
            xtime = RSK.profiles.(castdir).data(ndx).tstamp;
            [out, index, windowLength] = despike(x, xtime, threshold, windowLength, action);
            RSK.profiles.(castdir).data(ndx).values(:,channelCol) = out;
            spikeidx.(['profile' num2str(ndx)]) = index;
        end
    case 'data'
        x = RSK.data.values(:,channelCol);
        xtime = RSK.data.tstamp;
        [out, spikeidx, windowLength] = despike(x, xtime, threshold, windowLength, action); 
        RSK.data.values(:,channelCol) = out;
end

%% Update log
switch series
    case 'data'
        logentry = sprintf('%s de-spiked using a %1.0f sample window and %1.0f threshold. Spikes were treated with %s.',...
            channel, windowLength, threshold, action);

    case 'profile'
        if isempty(profileNum)
            logprofiles = ['all ' direction 'cast profiles'];
        elseif length(profileIdx) == 1
            logprofiles = [direction 'cast profiles ' num2str(profileIdx, '%1.0f')];
        else 
            logprofiles = [direction 'cast profiles' num2str(profileIdx(1:end-1), ', %1.0f') ' and ' num2str(profileIdx(end))];
        end
        logentry = sprintf('%s de-spiked using a %1.0f sample window and %1.0f sigma threshold on %s. Spikes were treated with %s.',...
            channel, windowLength, threshold, logprofiles, action);
end

RSK = RSKappendtolog(RSK, logentry);

end


%% Nested Functions
function [y, I, windowLength] = despike(x, t, threshold, windowLength, action)
% This helper function replaces the values that are > threshold*standard
% deviation away from the residual between the original time series and the
% running median with the median, a NaN or interpolated value using the
% non-spike values. The output is the x series with spikes fixed and I is
% the index of the spikes.

y = x;
[ref, windowLength] = runmed(x, windowLength, 'mirrorpad');
dx = x - ref;
sd = std(dx, 'omitnan');
I = find(abs(dx) > threshold*sd);
good = find(abs(dx) <= threshold*sd);

switch action
  case 'replace'
    y(I) = ref(I);
  case 'NaN'
    y(I) = NaN;
  case 'interp'
    y(I) = interp1(t(good), x(good), t(I)) ;
end
end
