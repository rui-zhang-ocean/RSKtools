function [RSK, flagidx] = RSKremoveheave(RSK, varargin)

% RSKremoveheave - Remove values exceeding a threshold CTD profiling
%                  rate.  Variations in profiling rate, such as might
%                  be caused by profiling from a vessel in wavy
%                  conditions with a taut wire, can negatively impact
%                  data quality.  If the heaving is large enough, the
%                  pressure can even reverse, or loop, causing the CTD
%                  to sample its own wake.
%
% Syntax:  [RSK, flagidx] = RSKremoveheave(RSK, [OPTIONS])
% 
% RSKremoveheave - This function filters the pressure channel with a
% lowpass boxcar to reduce the effect of noise, then finds the samples
% that exceed a threshold profiling velocity and replaces them with a
% NaN. Profiling rate is computed by differencing the depth time series.
% 
% Inputs:
%   [Required] - RSK - The input RSK structure, with profiles as read using
%                    RSKreadprofiles.
%
%   [Optional] - profileNum - Optional profile number(s) on which to operate.
%                    Default is to work on all profiles.
%
%                direction - 'up' for upcast, 'down' for downcast, or 'both' for
%                    all. Default is 'down'.
% 
%                threshold - The minimum speed at which the profile must be
%                    taken. Default is 0.25 m/s 
%
%                latitude - Latitude at which the profile was taken for depth
%                           calculation.  Default is 45.
%
% Outputs:
%    RSK - The structure without pressure reversal or slowdowns.
%
%    flagidx - The index of the samples that did not meet the profiling velocity criteria.
%
% Example: 
%    RSK = RSKopen(RSK)
%    RSK = RSKreadprofiles(RSK)
%    RSK = RSKremoveheave(RSK)
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-04-05

%% Check input and default arguments

validDirections = {'up', 'down'};
checkDirection = @(x) any(validatestring(x,validDirections));

classes = {'double'};
attributes = {'>=',-90,'<=',90};
checkLatitude = @(x) any(validateattributes(x, classes, attributes));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'threshold', 0.25, @isnumeric);
addParameter(p, 'latitude', 45, checkLatitude); 
parse(p, RSK, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
direction = p.Results.direction;
profileNum = p.Results.profileNum;
threshold = p.Results.threshold;
latitude = p.Results.latitude;


%% Determine if the structure has downcasts and upcasts

profileIdx = checkprofiles(RSK, profileNum, direction);
castdir = [direction 'cast'];


%% Edit one cast at a time.
data = RSK.profiles.(castdir).data;
pCol = strcmpi('pressure', {RSK.channels.longName});
secondsperday = 86400;

for ndx = profileIdx
    %% Filter pressure before taking the diff    
    pressure = RSK.profiles.(castdir).data(ndx).values(:,pCol);
    pressuresmooth = runavg(pressure, 3, 'nanpad');
    depth = calculatedepth(pressuresmooth, 'latitude', latitude);
    time = data(ndx).tstamp;

    %% Caculate Velocity.
    deltaD = diff(depth);
    deltaT = diff(time * secondsperday);
    dDdT = deltaD ./ deltaT;
    %The descent velocity is measured between time stamps. Must interpolate
    %to realign, interpolate starting on the second time to use the second
    %sample of a velocity as the possibly flagged value.
    midtime = time(2:end) + deltaT/(2*secondsperday);
    velocity = interp1(midtime, dDdT, time, 'linear', 'extrap');
    switch direction
        case 'up'
            flag = velocity > -threshold; 
        case 'down'
            flag = velocity < threshold;    
    end  
   
    %% Perform the action on flagged scans.
    flagChannels = ~strcmpi('pressure', {RSK.channels.longName});    
    data(ndx).values(flag,flagChannels) = NaN;
    flagidx(ndx).index = find(flag);
end

RSK.profiles.(castdir).data = data;

%% Udate log
logprofile = logentryprofiles(direction, profileNum, profileIdx);
logentry = ['Samples measured at a profiling velocity less than ' num2str(threshold) 'm/s were replaced with NaN on ' logprofile '.'];

RSK = RSKappendtolog(RSK, logentry);

end






