function [RSK, lags] = RSKalignprofiles(RSK, varargin)

% RSKalignprofile - Align conductivity and temperature in CTD profiles
%     to minimize salinity spiking
%
% Syntax:  [RSK, lags] = RSKalignprofile(RSK, [OPTIONS])
% 
% Calculates, and applies, the optimal conductivity/temperature lag to
% minimize salinity "spikes". Salinity spikes typically result from
% temporal C/T mismatches when the sensors are moving through regions
% of high vertical gradients. Either the value of CTlag is used for
% the alignment, or if left empty the optimal lag is determined by
% constructing a smoothed reference salinity by running the calculated
% salinity through an `nsmooth`-point boxcar filter, then comparing
% the standard deviations of the residuals for a range of lags from
% -20 to +20 samples.
%
% Requires the TEOS-10 toolbox to be installed, to allow salinity to
% be calculated using gsw_SP_from_C.
%
% Inputs: 
%    
%    [Required] - RSK - the input RSK structure, with profiles as read using
%                    RSKreadprofiles
%
%    [Optional] - profileNum - the profiles to which to apply the correction. If
%                    left as an empty vector, will do all profiles.
%            
%                direction - the profile direction to consider. Must be either
%                   'down' or 'up'. Defaults to 'down'.
%                    
%                 CTlag - optional value of C/T lag to apply to all profiles. If
%                     not provided or left empty will attempt to infer optimal C/T
%                     lag for each profile (see above).
%             
%                 nsmooth - the length of the smoothing windown to use for the
%                     reference salinity. Defaults to 21 samples
%
%
% Outputs:
%    RSK - the RSK structure with corrected salinities
%
%    lags - the optimal values of the lags for each profile
%
% Example: 
%   
%    rsk = RSKopen('file.rsk');
%    rsk = RSKreadprofiles(rsk, 1:10); % read first 10 downcasts
%
%   1. All downcast profiles with infered optimal C/T lag.
%    rsk = RSKalignprofile(rsk);
%   2. Specified profiles (first 4) and C/T lag values (one for each profile)
%    rsk = RSKalignprofile(rsk, 'profileNum',1:4, 'CTlag',[2 1 -1 0]);
%   3. Specified profiles (first 4) and C/T lag value (one for ALL profiles being aligned).
%    rsk = RSKalignprofile(rsk, 'profileNum',1:4, 'CTlag',[2]);
%   4. All upcast profiles
%    rsk = RSKalignprofile(rsk, 'direction','up');
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-11-15

%% Check input and default arguments
validDirections = {'down','up'};
checkDirection = @(x) any(validatestring(x,validDirections));

% Parse Inputs
p = inputParser;
addParameter(p,'profileNum', [], @isnumeric);
addParameter(p,'direction', 'down', checkDirection);
addParameter(p,'CTlag', [], @isnumeric);
addParameter(p,'nsmooth', 21, @isnumeric);
parse(p,varargin{:})

% Assign each input argument
profileNum = p.Results.profileNum;
direction = p.Results.direction;
CTlag = p.Results.CTlag;
nsmooth = p.Results.nsmooth;

%% determine if the structure has downcasts and upcasts
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


%% Check to make sure that lags are integers
if ~isequal(fix(CTlag),CTlag),
    error('Lag values must be integers.')
end


%% Check for one value of CTlag or one for each profile
if length(CTlag) == 1
    if length(profileNum) == 1
    else
        CTlag = repmat(CTlag, 1, length(profileNum));
    end
elseif length(CTlag) > 1
    if length(CTlag) ~= length(profileNum)
        error(['Length of CTlag must match number of profiles or be a ' ...
               'single value']);
    end
end

hasTEOS = exist('gsw_SP_from_C') == 2;

if (~hasTEOS) error('Error: Must install TEOS-10 toolbox'); end

% find column number of C and T
Scol = find(strncmpi('salinity', {RSK.channels.longName}, 4));
Ccol = find(strncmpi('conductivity', {RSK.channels.longName}, 4));
Tcol = find(strncmpi('temperature', {RSK.channels.longName}, 4));
Tcol = Tcol(1); % only take the first one
pcol = find(strncmpi('pressure', {RSK.channels.longName}, 4));
pcol = pcol(1);% some files also have sea pressure.

bestlag = [];
lags = [];
counter = 0;
if ~isempty(CTlag)
    for i=profileNum
        counter = counter + 1;
        disp(['Processing profile: ' num2str(i)])
        switch direction
          case 'down'
            C = RSK.profiles.downcast.data(i).values(:, Ccol);
            T = RSK.profiles.downcast.data(i).values(:, Tcol);
            p = RSK.profiles.downcast.data(i).values(:, pcol);
          case 'up'
            C = RSK.profiles.upcast.data(i).values(:, Ccol);
            T = RSK.profiles.upcast.data(i).values(:, Tcol);
            p = RSK.profiles.upcast.data(i).values(:, pcol);
        end
        Sbest = gsw_SP_from_C(shiftarray(C, CTlag(counter)), T, p);
        switch direction
          case 'down'
            RSK.profiles.downcast.data(i).values(:, Scol) = Sbest;
          case 'up'
            RSK.profiles.upcast.data(i).values(:, Scol) = Sbest;
        end
    end
    lags = CTlag;
else
    disp('No CTlag specified -- attemping to find optimal CT lag')
    for i=profileNum
        disp(['Processing profile: ' num2str(i)])
        switch direction
          case 'down'
            C = RSK.profiles.downcast.data(i).values(:, Ccol);
            T = RSK.profiles.downcast.data(i).values(:, Tcol);
            p = RSK.profiles.downcast.data(i).values(:, pcol);
          case 'up'
            C = RSK.profiles.upcast.data(i).values(:, Ccol);
            T = RSK.profiles.upcast.data(i).values(:, Tcol);
            p = RSK.profiles.upcast.data(i).values(:, pcol);
        end
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
        Sbest = gsw_SP_from_C(shiftarray(C, bestlag(end)), T, p);
        switch direction
          case 'down'
            RSK.profiles.downcast.data(i).values(:, Scol) = Sbest;
          case 'up'
            RSK.profiles.upcast.data(i).values(:, Scol) = Sbest;
        end
    end
    lags = bestlag;
end

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