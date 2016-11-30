function lags = RSKgetCTlag(RSK,varargin)

% RSKgetCTlag - Calculate a conductivity lag by minimizing salinity
% spikes.  Spikes are causes by misaligned conductivity and
% temperature channels.
%
% Syntax: [lags] = RSKgetCTlag(RSK, [OPTIONS])
%
% Calculates the optimal conductivity time shift relative to
% temperature to minimize salinity spiking.  The shift is made in
% time, but if temperature is not shifted then it is effectively
% aligned to temperature.  The optimal lag is determined by
% constructing a smoothed reference salinity by running the calculated
% salinity through a boxcar filter, then comparing the standard
% deviations of the residuals for a range of lags from -20 to +20
% samples.
%
% Requires the TEOS-10 GSW toobox to compute salinity.
%
% Inputs:
%
%    [Required] - RSK - the input RSK structure, with profiles as read using
%                    RSKreadprofiles.
%
%    [Optional] - profileNum - the profiles to which to apply the
%                    correction. If left as an empty vector, the lag
%                    is calculated for all profiles.
%
%                direction - the profile direction to consider. Must be either
%                   'down' or 'up'. Defaults to 'down'.
%
%                 nsmooth - the length of the smoothing window to use for the
%                     reference salinity. Defaults to 21 samples.
%
%
% Outputs:
%
%    lags - the optimal lags of conductivity for each profile.  These
%    can serve as inputs into RSKalignchannel.m
%
% Example usage:
%
%    rsk = RSKopen('file.rsk');
%    rsk = RSKreadprofiles(rsk, 1:10); % read first 10 downcasts
%
%   1. All downcast profiles with default smoothing
%    lags = RSKgetCTlag(rsk);
%
%   2. Specified profiles (first 4), reference salinity found with 13 pt boxcar.
%    rsk = RSKgetCTlag(rsk, 'profileNum',1:4, 'nsmooth',13);
%
%   3. All upcast profiles
%    rsk = RSKgetCTlag(rsk, 'direction','up');
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-11-03
    
    
%% check if user has the TEOS-10 GSW toolbox installed
hasTEOS = exist('gsw_SP_from_C') == 2;
if (~hasTEOS) error('Error: Must install TEOS-10 toolbox'); end


%% input handling

% set the defaults
p = inputParser;
defaultDirection = 'down';
defaultProfileNum = []; % will determine this later
defaultNsmooth = 21;
validDirections = {'down','up'};
checkDirection = @(x) any(validatestring(x,validDirections));
   
addRequired(p,'rsk',@isstruct);
addParameter(p,'direction', defaultDirection, checkDirection);
addParameter(p,'profileNum',defaultProfileNum)   
addParameter(p,'nsmooth',defaultNsmooth)

% Parse Inputs
parse(p,RSK,varargin{:})

% Assign each input argument
profileNum = p.Results.profileNum;
direction  = p.Results.direction;
nsmooth    = p.Results.nsmooth;


%% determine if the structure has downcasts and upcasts
castdir = [direction 'cast'];
isDown = isfield(RSK.profiles.downcast, 'data');
isUp   = isfield(RSK.profiles.upcast, 'data');
switch direction
    case 'up'
        if ~isUp
            error('Structure does not contain upcasts')
        elseif isempty(profileNum)
            profileNum = 1:length(RSK.profiles.upcast.data);
        end
    case 'down'
        if ~isDown
            error('Structure does not contain downcasts')
        elseif isempty(profileNum)
            profileNum = 1:length(RSK.profiles.downcast.data);
        end
end


%% find column number of channels
pcol = find(strncmpi('pressure', {RSK.channels.longName}, 4));
Ccol = find(strncmpi('conductivity', {RSK.channels.longName}, 4));
Tcol = find(strncmpi('temperature', {RSK.channels.longName}, 4));
Tcol = Tcol(1); % only take the first temperature channel
pcol = pcol(1); % Some files (WireWalker) have 'Pressure (sea)' as second pressure channel.

% only needed for if replacing current salinity estimate with new calc.
Scol = find(strncmpi('salinity', {RSK.channels.longName}, 4));


bestlag = [];
for k=profileNum
    disp(['Processing profile: ' num2str(k)])
    C = RSK.profiles.(castdir).data(k).values(:, Ccol);
    T = RSK.profiles.(castdir).data(k).values(:, Tcol);
    p = RSK.profiles.(castdir).data(k).values(:, pcol);
    S = gsw_SP_from_C(C, T, p);
    lags = -20:20;
    dSsd = [];
    for lag=lags
        Cshift = shiftarray(C, lag);
        SS = gsw_SP_from_C(Cshift, T, p);
        Ssmooth = smooth(SS, nsmooth);
        dS = SS - Ssmooth;
        dSsd = [dSsd std(dS)];
    end
    bestlag = [bestlag lags(find(dSsd == min(dSsd)))];
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


