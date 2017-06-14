
function [out] = runmed(in, windowLength, edgepad)

% runmed - Smooth a time series using a running median filter.
%
% Syntax:  [out, windowLength] = runmed(in, windowLength, edgepad)
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
%    edgepad - Describes how the filter will act at the edges. Options
%         are 'mirror', 'zeroorderhold' and 'nan'. If no string is input
%         it will be set to 'mirror'.
%
% Outputs:
%    out - the smoothed median time series
%
%    windowLength - The length of the running median. Must be odd.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-13

%% Check and set inputs/outputs
if nargin == 2
    edgepad = 'mirror';
end

n = length(in);
out = NaN*in;
%% Check windowLength
if mod(windowLength, 2) == 0
    error('windowLength must be odd');
end

padsize = (windowLength-1)/2;

inpadded = padseries(in, padsize, edgepad);

%% Running median
for ndx = 1:n
    out(ndx) = nanmedian(inpadded(ndx:ndx+(windowLength-1)));
end

end