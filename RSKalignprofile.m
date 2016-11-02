function [RSK, lags] = RSKalign(RSK, varargin)

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
% Last revision: 2016-11-02

p = inputParser;

defaultprofileNum = 1:length(RSK.profiles.downcast.tstart) ;

defaultDirection = 'down';
validDirections = {'down','up'};
checkDirection = @(x) any(validatestring(x,validDirections));

defaultCTlag = [];
defaultnsmooth = 21;

addRequired(p,'RSK', @isstruct);
addParameter(p,'profileNum', defaultprofileNum, @isnumeric);
addParameter(p,'direction', defaultDirection, checkDirection);
addParameter(p,'CTlag', defaultCTlag, @isnumeric);
addParameter(p,'nsmooth', defaultnsmooth, @isnumeric);
 
if ~isequal(fix(lags),lags),
    error('Lag values must be integers.')
end

 
 
parse(p,RSK,varargin{:})

%Assign each argument
profileNum = p.Results.profileNum;
direction = p.Results.direction;
CTlag = p.Results.CTlag;
nsmooth = p.Results.nsmooth;

%Default ProfileNum is dependent on direction of cast
checkProfileNum = strcmp(p.UsingDefaults,'profileNum');
if sum(checkProfileNum)==1
    switch direction
      case 'down'
        profileNum = 1:length(RSK.profiles.downcast.data);
      case 'up'
        profileNum = 1:length(RSK.profiles.upcast.data);
    end
end

% Check for one value of CTlag or one for each profile
if length(CTlag) == 1
    if length(profileNum) == 1
    else
        CTlag = repmat(CTlag, 1, length(profileNum));
    end
elseif length(CTlag) > 1
    if length(CTlag) ~= length(profileNum)
        error('Length of CTlag must match number of profiles');
    end
end

hasTEOS = exist('gsw_SP_from_C') == 2;

if (~hasTEOS) error('Error: Must install TEOS-10 toolbox'); end

% find column number of C and T
Scol = find(strncmp('salinity', lower({RSK.channels.longName}), 4));
Ccol = find(strncmp('conductivity', lower({RSK.channels.longName}), 4));
Tcol = find(strncmp('temperature', lower({RSK.channels.longName}), 4));
Tcol = Tcol(1); % only take the first one
pcol = find(strncmp('pressure', lower({RSK.channels.longName}), 4));

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
        Sbest = gsw_SP_from_C(RSKshift(C, CTlag(counter)), T, p);
        RSK.profiles.downcast.data(i).values(:, Scol) = Sbest;
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