function lags = RSKgetCTlag(RSK)

% RSKgetCTlag - Calculate a conductivity lag by minimizing salinity
% spikes.  Spikes are causes by mis-aligned conductivyt and
% temperatuer channels.
%
% Syntax: [lags] = RSKgetCTlag(RSK, [OPTIONS])
%
% the optimal lag is determined by constructing a smoothed reference
% salinity by running the calculated salinity through an
% `nsmooth`-point boxcar filter, then comparing the standard
% deviations of the residuals for a range of lags from -20 to +20
% samples.
%
% The RSK structure should be parsed into profiles before 
%
% Direction should be specified when both the upcast and downcast
% exist.  Default when both exist is 'downcast'.
%
% Uses upcast if it is the only thing that exists.
%
% GSW toobox must be installed to compute salinity.

% check if user has the TEOS-10 GSW toolbox installed
hasTEOS = exist('gsw_SP_from_C') == 2;

if (~hasTEOS) error('Error: Must install TEOS-10 toolbox'); end


% find column number of channels
pcol = find(strncmp('pressure', lower({RSK.channels.longName}), 4));
Ccol = find(strncmp('conductivity', lower({RSK.channels.longName}), 4));
Tcol = find(strncmp('temperature', lower({RSK.channels.longName}), 4));
Tcol = Tcol(1); % only take the first temperature channel

% only needed for if replacing current salinity estimate with new calc.
Scol = find(strncmp('salinity', lower({RSK.channels.longName}), 4));

% inputs
direction = 'down';
direction = 'up';
nsmooth = 21;

profileNum = 1:length(RSK.profiles.([direction 'cast']).data);

bestlag = [];
for k=profileNum
    disp(['Processing profile: ' num2str(k)])
    switch direction
      case 'down'
        C = RSK.profiles.downcast.data(k).values(:, Ccol);
        T = RSK.profiles.downcast.data(k).values(:, Tcol);
        p = RSK.profiles.downcast.data(k).values(:, pcol);
      case 'up'
        C = RSK.profiles.upcast.data(k).values(:, Ccol);
        T = RSK.profiles.upcast.data(k).values(:, Tcol);
        p = RSK.profiles.upcast.data(k).values(:, pcol);
    end
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
    switch direction
      case 'down'
        RSK.profiles.downcast.data(k).values(:, Scol) = Sbest;
      case 'up'
        RSK.profiles.upcast.data(k).values(:, Scol) = Sbest;
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

