function out = RSKshift(in, shift)

% RSKshift - Shift a time series by a specified number of samples
%
% Syntax:  out = RSKshift(in, shift)
% 
% Shifts a vector time series by a lag corresponding to an integer
% number of samples, e.g. for aligning temperature and conductivity
% prior to the calculation of salinity. Negative shifts correspond to
% moving the samples backwards in time (earlier), positive to forwards
% in time (later). Values at either the beginning or the end are set
% to the value of the original end point (zero order hold).
%
% Inputs:
%    in - the input time series
%
%    shift - the number of samples to shift by
%
% Outputs:
%    out - the shifted time series
%
% Example: 
%    conductivityLagged = RSKshift(rsk.data.values(:,1), -3); % shift back by 3 samples
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-06-03

n = length(in);
out = NaN*in;

I = 1:n;
Ilag = I-shift;
Ilag(Ilag<1) = 1;
Ilag(Ilag>n) = n;

out = in(Ilag);

