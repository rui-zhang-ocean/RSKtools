function [out] = runtriang(in, windowLength, edgepad)

% runtriang - Smooth a time series using a triangle filter.
%
% Syntax:  [out] = runtriang(in, windowLength, edgepad)
% 
% runtriang performs a triangle filter, of length windowLength over the time
% series. 
%
% Inputs:
%    in - time series
%
%    windowLength - The length of the running triangle. It must be odd,
%         will add one if it is odd.
%
%    edgepad - Describes how the filter will act at the edges. Options
%         are 'mirror', 'zeroorderhold' and 'nan'.
%
% Outputs:
%    out - the smoothed time series
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-14

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

for ndx = 1:windowLength
    if ndx <= (windowLength+1)/2
        coeff(ndx) = 2*ndx/(windowLength+1);
    else
        coeff(ndx) = 2 - (2*ndx/(windowLength+1));
    end
end
normcoeff = (coeff/sum(coeff));

for ndx = 1:n
    out(ndx) = nansum(inpadded(ndx:ndx+(windowLength-1)).*normcoeff');
end

end