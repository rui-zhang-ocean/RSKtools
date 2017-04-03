function lag = RSKcalculateCTlag(RSK, varargin)

% RSKcalculateCTlag - Calculate a conductivity lag by minimizing salinity
%                     spikes.
%
% Syntax: [lag] = RSKcalculateCTlag(RSK, [OPTIONS])
%
% Calculates the optimal conductivity time shift relative to
% temperature to minimize salinity spiking.  The shift is made in
% time, but if temperature is not shifted then it is effectively
% aligned to temperature.  The optimal lag is determined by
% constructing a smoothed reference salinity by running the calculated
% salinity through a boxcar filter, then comparing the standard
% deviations of the residuals for a range of lags from -20 to +20
% samples. A pressure range can be determined to align with respect to a
% certain range of values (avoids large effects from surface anomalies).
%
% Requires the TEOS-10 GSW toobox to compute salinity.
%
% Inputs:
%    [Required] - RSK - The input RSK structure, with profiles as read using
%                     RSKreadprofiles.
%
%    [Optional] - pressureRange - Set the limits of the pressure range used
%                     to obtain the lag. Specify as a two-element vector,
%                     [pressureMin, pressureMax]. Default is [0,
%                     max(Pressure)]
%
%                 profileNum - Optional profile number to calculate lag.
%                     Default is to calculate the lag of all detected
%                     profiles.
%
%                 direction - 'up' for upcast, 'down' for downcast, or 'both' for
%                     all. Default is 'down'.
%
%                 windowLength - The length of the filter window used for the
%                     reference salinity. Default is 21 samples.
%
% Outputs:
%    lag - The optimal lags of conductivity for each profile.  These
%        can serve as inputs into RSKalignchannel.m.
%
% Examples:
%    rsk = RSKopen('file.rsk');
%    rsk = RSKreadprofiles(rsk, 1:10); % read first 10 downcasts
%
%   1. All downcast profiles with default smoothing
%    lag = RSKcalculateCTlag(rsk);
%
%   2. Specified profiles (first 4), reference salinity found with 13 pt boxcar.
%    lag = RSKcalculateCTlag(rsk, 'profileNum',1:4, 'windowLength',13);
%
%   3. All upcast profiles
%    lag = RSKcalculateCTlag(rsk, 'direction','up');
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-04-03
    
    
%% check if user has the TEOS-10 GSW toolbox installed

hasTEOS = exist('gsw_SP_from_C', 'file') == 2;
if ~hasTEOS
    error('Error: Must install TEOS-10 toolbox'); 
end


%% Check input and default arguments

validDirections = {'down','up'};
checkDirection = @(x) any(validatestring(x,validDirections));


%% Parse Inputs

P = inputParser;
addRequired(P,'RSK', @isstruct);
addParameter(P, 'pressureRange', [], @isvector);
addParameter(P,'direction', 'down', checkDirection);
addParameter(P,'profileNum', [])   
addParameter(P,'windowLength', 21, @isnumeric)
parse(P,RSK,varargin{:})

% Assign each input argument
RSK = P.Results.RSK;
pressureRange = P.Results.pressureRange;
direction = P.Results.direction;
profileNum = P.Results.profileNum;
windowLength = P.Results.windowLength;


%% Determine if the structure has downcasts and upcasts

profileNum = checkprofiles(RSK, profileNum, direction);
castdir = [direction 'cast'];


%% find column number of channels

Pcol = strcmpi('pressure', {RSK.channels.longName});
Ccol = strcmpi('conductivity', {RSK.channels.longName});
Tcol = strcmpi('temperature', {RSK.channels.longName});


%% Calculate Optimal Lag

bestlag = [];
for ndx = profileNum
    disp(['Processing profile: ' num2str(ndx)])
    C = RSK.profiles.(castdir).data(ndx).values(:, Ccol);
    T = RSK.profiles.(castdir).data(ndx).values(:, Tcol);
    P = RSK.profiles.(castdir).data(ndx).values(:, Pcol);
    
    if ~isempty(pressureRange)
        selectValues = (P >= pressureRange(1) & P<= pressureRange(2)); 
        C = C(selectValues);
        T = T(selectValues);
        P = P(selectValues);
    end
    
    lags = -20:20;
    dSsd = [];
    for l=lags
        Cshift = shiftarray(C, l);
        SS = gsw_SP_from_C(Cshift, T, P);
        Ssmooth = smooth(SS, windowLength);
        dS = SS - Ssmooth;
        dSsd = [dSsd std(dS)];
    end
    minlag = min(abs(lags(dSsd == min(dSsd))));
    bestlag = [bestlag minlag];
end
lag = bestlag;


    %% Nested function
    function out = smooth(in, nsmooth)

    % smooths an input vector with a boxcar filter of length nsmooth

    n = length(in);
    out = NaN*in;

    if mod(nsmooth, 2) == 0
        warning('nsmooth must be odd; adding 1');
        nsmooth = nsmooth + 1;
    end


    for ndx = 1:n
        if ndx <= (nsmooth-1)/2
            out(ndx) = mean(in(1:ndx+(nsmooth-1)/2));
        elseif ndx >= n-(nsmooth-1)/2
            out(ndx) = mean(in(ndx-(nsmooth-1)/2:n));
        else
            out(ndx) = mean(in(ndx-(nsmooth-1)/2:ndx+(nsmooth-1)/2));
        end
    end
    end
end


