function y = RSKdespike(x, n, k, action)

% RSKdespike - De-spike a time series using a running median filter.
%
% Syntax:  [y] = RSKdespike(x, n, k, action)
% 
% RSKdespike is a despike algorithm that utilizes a running median
% filter to create a reference series. Each point in the original series is compared against the windowed reference series, with points lying further than n standard deviations from the mean treated as spikes. The default behaviour is to replace the spike wth the reference value.
%
% Inputs:
%    x - the input time series
%
%    n - the number of standard deviations to use for the spike criterion
%
%    k - the length of the running median
%
%    action - the "action" to perform on a spike. Default is to
%             replace it with the reference value. Can also be 'NaN'
%             to leave the spike as a missing value.
%
% Outputs:
%    y - the de-spiked series
%
% Example: 
%    temperatureDS = RSKdespike(rsk.data.values(:,2));
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-06-03

y = runmed(x, k);




function out = runmed(in, k)

% A running median of length k. k must be odd

n = length(in);
out = NaN*ones(n);

if mod(k, 2) == 1
    message('k must be odd; adding 1');
    k = k + 1;
end

for i = k:n-k
    out(i) = median(in(i-(k-1)/2:i+(k-1/2)))
end
