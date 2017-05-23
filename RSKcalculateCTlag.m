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
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-23
    
    
%% check if user has the TEOS-10 GSW toolbox installed

hasTEOS = exist('gsw_SP_from_C', 'file') == 2;
if ~hasTEOS
    error('Error: Must install TEOS-10 toolbox'); 
end

%% Parse Inputs

P = inputParser;
addRequired(P,'RSK', @isstruct);
addParameter(P, 'pressureRange', [], @isvector);
addParameter(P,'profileNum', [])   
addParameter(P,'windowLength', 21, @isnumeric)
parse(P,RSK,varargin{:})

% Assign each input argument
RSK = P.Results.RSK;
pressureRange = P.Results.pressureRange;
profileNum = P.Results.profileNum;
windowLength = P.Results.windowLength;

%% find column number of channels
Pcol = getchannelindex(RSK, 'pressure');
Ccol = getchannelindex(RSK, 'conductivity');
Tcol = getchannelindex(RSK, 'temperature');

%% Calculate Optimal Lag
bestlag = [];
dataIdx = setdataindex(RSK, profileNum);
for ndx = dataIdx
    disp(['Processing profile: ' num2str(ndx)])
    C = RSK.data(ndx).values(:, Ccol);
    T = RSK.data(ndx).values(:, Tcol);
    P = RSK.data(ndx).values(:, Pcol);
    
    if ~isempty(pressureRange)
        selectValues = (P >= pressureRange(1) & P<= pressureRange(2)); 
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


