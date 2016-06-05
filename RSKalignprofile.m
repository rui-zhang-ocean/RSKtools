function [RSK, lags] = RSKalignprofile(RSK, profileNum, nsmooth, despike)

% RSKalignprofile - Align conductivity and temperature in CTD profiles
%     to minimize salinity spiking
%
% Syntax:  [RSK, lags] = RSKalignprofile(RSK, profileNum, nsmooth, despike)
% 
% Calculates, and applies, the optimal conductivity/temperature lag to
% minimize salinity "spikes". Salinity spikes typically result from
% C/T mismatch in time when the sensors are moving through regions of
% high gradients. The optimal lag is determined by constructing a
% smoothed reference salinity by running the calculated salinity
% through an `nsmooth`-point boxcar filter, then comparing the standard
% deviations of the residuals for a range of lags from -20 to +20
% samples.
%
% Requires the TEOS-10 toolbox to be installed, to allow salinity to
% be calculated using gsw_SP_from_C.
%
% Inputs:
%    RSK - the input RSK structure, with profiles
%
%    profileNum - the profiles to which to apply the correction
%
%    nsmooth - the length of the smoothing windown to use for the
%        reference salinity. Defaults to 30 samples
%
%    despike - optional flag indicating whether to despike the lagged
%        salinity using RSKdespike. If 0 do not despike, if a positive
%        integer is the length of the despike window to use in
%        RSKdespike.
%
% Outputs:
%    RSK - the RSK structure with corrected salinities
%
%    lags - the optimal values of the lags for each profile
%
% Example: 
%   
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-06-03

if nargin == 1
    profileNum = 1:length(RSK.profiles.downcast.data);
    nsmooth = 21;
    despike = 0;
elseif nargin == 2
    nsmooth = 21;
    despike = 0;
elseif nargin == 3
    despike = 0;
end
hasTEOS = exist('gsw_SP_from_C') == 2;

if (~hasTEOS) error('Error: Must install TEOS-10 toolbox'); end

% find column number of C and T
Scol = find(strncmp('salinity', lower({RSK.channels.longName}), 4));
Ccol = find(strncmp('conductivity', lower({RSK.channels.longName}), 4));
Tcol = find(strncmp('temperature', lower({RSK.channels.longName}), 4));
pcol = find(strncmp('pressure', lower({RSK.channels.longName}), 4));

bestlag = [];
for i=profileNum
    C = RSK.profiles.downcast.data(i).values(:, Ccol);
    T = RSK.profiles.downcast.data(i).values(:, Tcol);
    p = RSK.profiles.downcast.data(i).values(:, pcol);
    S = gsw_SP_from_C(C, T, p);
    lags = -20:20;
    dSsd = [];
    for lag=lags
        Cshift = RSKshift(C, lag);
        SS = gsw_SP_from_C(Cshift, T, p);
        Ssmooth = smooth(SS, nsmooth);
        dS = SS - Ssmooth;
        dSsd = [dSsd std(dS)];
    end
    bestlag = [bestlag lags(find(dSsd == min(dSsd)))];
    Sbest = gsw_SP_from_C(RSKshift(C, bestlag(end)), T, p);
    switch despike
      case 0
        RSK.profiles.downcast.data(i).values(:, Scol) = Sbest;
      otherwise
        RSK.profiles.downcast.data(i).values(:, Scol) = RSKdespike(Sbest, 1, despike);
    end
end

lags = bestlag;

end

function out = smooth(in, nsmooth)
    
% smooths an input vector with a boxcar filter of length nsmooth
    
n = length(in);
out = NaN*in;

if mod(nsmooth, 2) == 0
    warning('nsmooth must be odd; adding 1');
    nsmooth = nsmooth + 1;
end

for i = 1:n
    if i <= (nsmooth-1)/2
        out(i) = mean(in(1:i+(nsmooth-1)/2));
    elseif i >= n-(nsmooth-1)/2
        out(i) = mean(in(i-(nsmooth-1)/2:n));
    else
        out(i) = mean(in(i-(nsmooth-1)/2:i+(nsmooth-1)/2));
    end
end
    
end