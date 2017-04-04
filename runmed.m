function [out, windowLength] = runmed(in, windowLength, edgevalues)

% runmed - Smooth a time series using a running median filter.
%
% Syntax:  [out, windowLength] = runmed(in, windowLength, edgevalues)
% 
% runmed is helper function that performs a running median of length
% windowLength. The time series is mirror padded, nan padded or zero
% order hold padded
%
% Inputs:
%    in - time series
%
%    windowLength - The length of the running median. It must be odd, has
%        one added if it's found to be even. 
%
%    edgevalues - Describes how the filter will act at the edges. Options
%         are 'mirrorpad', 'zeroOrderhold' and 'nanpad'.
%
% Outputs:
%    out - the smoothed median time series
%
%    windowLength - The length of the running median. Could be different
%        than the input if it was an even number.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-04-04

n = length(in);
out = NaN*in;
%% Check windowLength
if mod(windowLength, 2) == 0
    warning('windowLength must be odd; adding 1');
    windowLength = windowLength + 1;
end

%% Mirror pad the time series
switch edgevalues
    case 'mirrorpad'
        inpadded = mirrorpad(in, padsize);
    case 'nanpad'
        inpadded = nanpad(in, padsize);
    case 'zeroOrderhold'
        inpadded = zeroOrderholdpad(in, padsize);
end

%% Running median
for ndx = 1:n
    out(ndx) = nanmedian(inpadded(ndx:ndx+(windowLength-1)));
end

end