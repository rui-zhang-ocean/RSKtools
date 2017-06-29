function [RSK, spike] = RSKdespike(RSK, channel, varargin)

%RSKdespike - Despike a time series series.
%
% Syntax:  [RSK, spike] = RSKdespike(RSK, channel, [OPTIONS])
% 
% Compares the time series to a reference series. The reference series is
% the time series filtered with a median filter of length 'windowLength'.
% Each point in the original series is compared against the reference
% series, if a sample is greater than 'threshold' standard deviations of
% the residual between the original series and the reference series; the
% sample is considered a spike. The default behaviour is to replace the
% spikes with the reference value. 
%
% Inputs:
%   [Required] - RSK - Structure containing logger data.
%
%                channel - Longname of channel to despike (e.g. temperature,
%                      salinity, etc)
%
%   [Optional] - profile - Profile number. Default is all available
%                      profiles.
%
%                direction - 'up' for upcast, 'down' for downcast, or
%                      'both' for all. Default all directions available.
%
%                threshold - Amount of standard deviations to use for the
%                      spike criterion. Default value is 2. 
%
%                windowLength - Total size of the filter window. Must be
%                      odd. Default is 3. 
%
%                action - Action to perform on a spike. The default is 'NaN',
%                      whereby spikes are replaced with NaN.  Other options are 
%                      'replace', whereby spikes are replaced with the 
%                      corresponding reference value, and 'interp', 
%                      whereby spikes are replaced with values calculated
%                      by linearly interpolating from the neighbouring 
%                      points.
%
% Outputs:
%    RSK - Structure with de-spiked series.
%
%    spike - Structure containing the index of the spikes; if more than one
%          channel was despiked, spike is a structure with a field for each
%          profile.   
%
% Example: 
%    [RSK, spike] = RSKdespike(RSK, 'Turbidity')
%   OR
%    [RSK, spike] = RSKdespike(RSK, 'Temperature', 'threshold', 4, 'windowLength', 11, 'action', 'NaN'); 
%
% See also: RSKremoveloops, RSKsmooth.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-28

validActions = {'replace', 'interp', 'NaN'};
checkAction = @(x) any(validatestring(x,validActions));

validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'direction', [], checkDirection);
addParameter(p, 'threshold', 2, @isnumeric);
addParameter(p, 'windowLength', 3, @isnumeric);
addParameter(p, 'action', 'NaN', checkAction);
parse(p, RSK, channel, varargin{:})

RSK = p.Results.RSK;
channel = p.Results.channel;
profile = p.Results.profile;
direction = p.Results.direction;
windowLength = p.Results.windowLength;
threshold = p.Results.threshold;
action = p.Results.action;



channelCol = getchannelindex(RSK, channel);
castidx = getdataindex(RSK, profile, direction);
k = 1;
for ndx = castidx
    in = RSK.data(ndx).values(:,channelCol);
    intime = RSK.data(ndx).tstamp;
    [out, index] = despike(in, intime, threshold, windowLength, action);
    RSK.data(ndx).values(:,channelCol) = out;
    spike(k).index = index;
    k = k+1;
end



logdata = logentrydata(RSK, profile, direction);
logentry = sprintf(['%s de-spiked using a %1.0f sample window and %1.0f sigma threshold on %s. '...
           'Spikes were treated with %s.'], channel, windowLength, threshold, logdata, action);
RSK = RSKappendtolog(RSK, logentry);



    %% Nested Functions
    function [y, I] = despike(x, t, threshold, windowLength, action)
    % Replaces the values that are > threshold*standard deviation away from
    % the residual between the original time series and the running median
    % with the median, a NaN or interpolated value using the non-spike
    % values. The output is the x series with spikes fixed and I is the
    % index of the spikes. 

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