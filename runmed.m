function out = runmed(in, windowLength)

% runmed - Smooth a time series using a running median filter.
%
% Syntax:  [out] = runmed(in, windowLength)
% 
% runmed is helper function that performs a running median of length
% windowLength. The time series is mirror padded to have values at the
% edges.
%
% Inputs:
%    in - time series
%
%    windowLength - The length of the running median. It must be odd, has
%        one added if it's found to be even. 
%
% Outputs:
%    out - the smoothed median time series
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-01-11

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
    out(ndx) = median(inpadded(ndx:ndx+(windowLength-1)));
end

end