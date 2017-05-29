function [RSK, spike] = RSKdespike(RSK, channel, varargin)

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
%   [Optional] - profileNum - Optional profile number. Default is to
%                    despike all profiles.
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
%    spike - A structure containing the index of the spikes; if many
%                    data fields were despiked, spike is a structure
%                    with a field for each profile. 
%
% Example: 
%    [RSK, spikesidx] = RSKdespike(RSK,  'Pressure')
%   OR
%    [RSK, spikesidx] = RSKdespike(RSK, 'Temperature', 'threshold',2, 'windowLength',10, 'action','NaN');
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-24

validActions = {'replace', 'interp', 'NaN'};
checkAction = @(x) any(validatestring(x,validActions));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'threshold', 4, @isnumeric);
addParameter(p, 'windowLength', 3, @isnumeric);
addParameter(p, 'action', 'NaN', checkAction);
parse(p, RSK, channel, varargin{:})

RSK = p.Results.RSK;
channel = p.Results.channel;
profileNum = p.Results.profileNum;
windowLength = p.Results.windowLength;
threshold = p.Results.threshold;
action = p.Results.action;


%% Despike
channelCol = getchannelindex(RSK, channel);
dataIdx = setdataindex(RSK, profileNum);
k = 1;
for ndx = dataIdx
    x = RSK.data(ndx).values(:,channelCol);
    xtime = RSK.data(ndx).tstamp;
    [out, index] = despike(x, xtime, threshold, windowLength, action);
    RSK.data(ndx).values(:,channelCol) = out;
    spike(k).index = index;
    k = k+1;
end

logdata = logentrydata(RSK, profileNum, dataIdx);
logentry = sprintf('%s de-spiked using a %1.0f sample window and %1.0f sigma threshold on %s. Spikes were treated with %s.',...
    channel, windowLength, threshold, logdata, action);
RSK = RSKappendtolog(RSK, logentry);


    %% Nested Functions
    function [y, I] = despike(x, t, threshold, windowLength, action)
    % This helper function replaces the values that are > threshold*standard
    % deviation away from the residual between the original time series and the
    % running median with the median, a NaN or interpolated value using the
    % non-spike values. The output is the x series with spikes fixed and I is
    % the index of the spikes.

        y = x;
        ref = runmed(x, windowLength);
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
end