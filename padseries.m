function inpadded = padseries(in, padsize, edgepad)

% padseries - add padsize amount of values of either side of the in vector
%
% Syntax:  [inpadded] = padseries(in, padsize, edgepad)
% 
% padseries add values to either side of the in vector
%
% Inputs:
%    in - time series
%
%    padsize - The amount of values added to either end of the vector.
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

switch edgepad
    case 'mirror'
        inpadded = mirrorpad(in, padsize);
    case 'nan'
        inpadded = nanpad(in, padsize);
    case 'zeroorderhold'
        inpadded = zeroorderholdpad(in, padsize);
    otherwise
        error('edgepad argument is not recognized. Must be `mirror`, `nan` or `zeroorderhold`');
end
end