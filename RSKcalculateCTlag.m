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
%                       RSKreadprofiles.
%
%    [Optional] - pressureRange - Set the limits of the pressure range used
%                       to obtain the lag. Specify as a two-element vector,
%                       [pressureMin, pressureMax]. Default is [0,
%                       max(Pressure)]
%
%                 profile - Optional profile number. Default is to
%                       calculate the lag of all available
%                       profiles.
%
%                 direction - 'up' for upcast, 'down' for downcast, or
%                       `both` for all. Default all directions available.
%
%                 windowLength - The length of the filter window used for the
%                       reference salinity. Default is 21 samples.
%
% Outputs:
%    lag - The optimal lags of conductivity for each profile.  These
%          can serve as inputs into RSKalignchannel.m.
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
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-31

hasTEOS = exist('gsw_SP_from_C', 'file') == 2;
if ~hasTEOS
    error('Error: Must install TEOS-10 toolbox'); 
end



validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p,'RSK', @isstruct);
addParameter(p, 'pressureRange', [], @isvector);
addParameter(p,'profile', []) 
addParameter(p, 'direction', [], checkDirection);
addParameter(p,'windowLength', 21, @isnumeric)
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
pressureRange = p.Results.pressureRange;
profile = p.Results.profile;
direction = p.Results.direction;
windowLength = p.Results.windowLength;



Pcol = getchannelindex(RSK, 'pressure');
Ccol = getchannelindex(RSK, 'conductivity');
Tcol = getchannelindex(RSK, 'temperature');



bestlag = [];
castidx = getdataindex(RSK, profile, direction);
for ndx = castidx
    disp(['Processing profile: ' num2str(ndx)]) %fixme, processing cast/ data element.
    C = RSK.data(ndx).values(:, Ccol);
    T = RSK.data(ndx).values(:, Tcol);
    P = RSK.data(ndx).values(:, Pcol);
    
    if ~isempty(pressureRange)
        selectValues = (P >= pressureRange(1) & P <= pressureRange(2)); 
        C = C(selectValues);
        T = T(selectValues);
        P = P(selectValues);
    end
    
    lags = -20:20;
    dSsd = [];
    for l = lags
        Cshift = shiftarray(C, l, 'nan');
        SS = gsw_SP_from_C(Cshift, T, P);
        Ssmooth = runavg(SS, windowLength, 'nan');
        dS = SS - Ssmooth;
        dSsd = [dSsd std(dS, 'omitnan')];
    end
    minlag = min(abs(lags(dSsd == min(dSsd))));
    bestlag = [bestlag minlag];
end
lag = bestlag;

end


