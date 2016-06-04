function y = RSKdespike(x, n, k, action)

% RSKdespike - De-spike a time series using a running median filter.
%
% Syntax:  [y] = RSKdespike(x, n, k, action)
% 
% RSKdespike is a despike algorithm that utilizes a running median
% filter to create a reference series. Each point in the original
% series is compared against the reference series, with points lying
% further than n standard deviations from the mean treated as
% spikes. The default behaviour is to replace the spike wth the
% reference value.
%
% Inputs:
%    x - the input time series
%
%    n - the number of standard deviations to use for the spike criterion
%
%    k - the length of the running median
%
%    action - the "action" to perform on a spike. The default,
%    'replace' is to replace it with the reference value. Can also be
%    'NaN' to leave the spike as a missing value.
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

if nargin==1 
    n = 4;
    k = 7;
    action = 'replace';
elseif nargin==2
    k = 7;
    action = 'replace';
elseif nargin==3
    action='replace';
end

y = x;
ref = runmed(x, k);
dx = x - ref;
sd = std(dx);
I = find(dx > n*sd);

switch action
  case 'replace'
    y(I) = ref(I);
  case 'NaN'
    y(I) = NaN;
end

end

function out = runmed(in, k)
% A running median of length k. k must be odd, has one added if it's found to be even.

n = length(in);
out = NaN*in;

if mod(k, 2) == 0
    warning('k must be odd; adding 1');
    k = k + 1;
end

for i = 1:n
    if i <= (k-1)/2
        out(i) = median(in(1:i+(k-1)/2));
    elseif i >= n-(k-1)/2
        out(i) = median(in(i-(k-1)/2:n));
    else
        out(i) = median(in(i-(k-1)/2:i+(k-1)/2));
    end
end

end