function [out] = runavg(in, windowLength, edgepad)

% runavg - Smooth a time series using a boxcar filter.
%
% Syntax:  [out, windowLength] = runavg(in, windowLength, edgepad)
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
%    edgepad - Describes how the filter will act at the edges. Options
%         are 'mirror', 'zeroorderhold' and 'nan'.
%
% Outputs:
%    out - the smoothed time series
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

for ndx = 1:n
    out(ndx) = nanmean(inpadded(ndx:ndx+(windowLength-1)));
end
end