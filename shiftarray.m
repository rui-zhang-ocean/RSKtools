function out = shiftarray(in, shift, shiftval)

% shiftarray - Convenience function to shift a time series by a
% specified number of samples
%
% Syntax:  out = shiftarray(in, shift)
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
%    shiftval - The value to set the beginning or end values.
%
% Outputs:
%    out - The shifted time series
%
% Example: 
%    conductivityLagged = shiftarray(rsk.data.values(:,1), -3); % shift back by 3 samples
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-02-06

n = length(in);
out = NaN*in;

I = 1:n;
Ilag = I-shift;
switch lower(shiftval)
    case 'zeroorderhold'
        Ilag(Ilag<1) = 1;
        Ilag(Ilag>n) = n;
        out = in(Ilag);
    case 'nanpad'
        out(Ilag>=1 & Ilag <=n) = in(Ilag(Ilag>=1 & Ilag <=n));
end
end