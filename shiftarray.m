function out = shiftarray(in, shift, edgepad)

% shiftarray - Convenience function to shift a time series by a
% specified number of samples
%
% Syntax:  out = shiftarray(in, shift, edgepad)
% 
% Shifts a vector time series by a lag corresponding to an integer
% number of samples, e.g. for aligning temperature and conductivity
% prior to the calculation of salinity. Negative shifts correspond to
% moving the samples backwards in time (earlier), positive to forwards
% in time (later). Values at either the beginning or the end are set
% to the value of the original end point (zero order hold).
%
% Inputs:
%    in - The input time series
%
%    shift - The number of samples to shift by
%
%    edgepad - The values to set the beginning or end values. Options are
%    mirror (default), zeroorderhold and nan.
%
% Outputs:
%    out - The shifted time series
%
% Example: 
%    shiftedValues = shiftarray(rsk.data.values(:,1), -3); % shift back by 3 samples
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-04-19


if nargin == 2
    edgepad = 'mirror';
end

n = length(in);
out = NaN*in;

I = 1:n;
Ilag = I-shift;
switch lower(edgepad)
    case 'mirror'
        inpad = mirrorpad(in, abs(shift));  
    case 'zeroorderhold'
        inpad = zeroorderholdpad(in, abs(shift));
    case 'nan'
        inpad = nanpad(in, abs(shift)); 
end

if shift>0
    Ilag = I;
else
    Ilag = Ilag-shift;
end

out = inpad(Ilag);

end