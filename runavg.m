function [out, windowLength] = runavg(in, windowLength, edgevalues)

% runavg - Smooth a time series using a boxcar filter.
%
% Syntax:  [out, windowLength] = runavg(in, windowLength, adgevalues)
% 
% runavg performs a running average, also known as boxcar filter, of length
% windowLength over the time series.
%
% Inputs:
%    in - time series
%
%    windowLength - The length of the running median. It must be odd, will
%         add one if it is odd.
%
%    edgevalues - Describes how the filter will act at the edges. Options
%         are 'mirrorpad', 'zeroOrderhold' and 'nanpad'.
%
% Outputs:
%    out - the smoothed time series
%
%    windowLength - The length of the running median. Could be different
%        than the input if it was an even number.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-04-03


n = length(in);
out = NaN*in;


%% Check windowLength
if mod(windowLength, 2) == 0
    warning('windowLength must be odd; adding 1');
    windowLength = windowLength + 1;
end

padsize = (windowLength-1)/2;
%% Mirror pad the time series
switch edgevalues
    case 'mirrorpad'
        inpadded = mirrorpad(in, padsize);
    case 'nanpad'
        inpadded = nanpad(in, padsize);
    case 'zeroOrderhold'
        inpadded = zeroOrderholdpad(in, padsize);
end

for ndx = 1:n
    out(ndx) = nanmean(inpadded(ndx:ndx+(windowLength-1)));
end
end