function [out, windowLength] = runavg(in, windowLength)

% runavg - Smooth a time series using a boxcar filter.
%
% Syntax:  [out, windowLength] = runavg(in, windowLength)
% 
% runavg performs a running average, also known as boxcar filter, of length
% windowLength over the mirrorpadded time series.
%
% Inputs:
%    in - time series
%
%    windowLength - The length of the running median. It must be odd, will
%         add one if it is odd.
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
% Last revision: 2017-04-02


n = length(in);
out = NaN*in;


%% Check windowLength
if mod(windowLength, 2) == 0
    warning('windowLength must be odd; adding 1');
    windowLength = windowLength + 1;
end


%% Mirror pad the time series
padsize = (windowLength-1)/2;
inpadded = mirrorpad(in, padsize);


%% Running median
for ndx = 1:n
    out(ndx) = mean(inpadded(ndx:ndx+(windowLength-1)));
end
end