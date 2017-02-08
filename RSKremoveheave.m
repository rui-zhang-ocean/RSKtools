function [RSK, flags] = RSKremoveheave(RSK, varargin)

% RSKremoveheave - Remove values that have pressure reversal or slowdows during
%               the profile.
%
% Syntax:  [RSK, flags] = RSKremoveheave(RSK, [OPTIONS])
% 
% RSKremoveheave - This function filters the pressure channel with a lowpass
% boxcar to reduce the effect of noise, then finds samples that have a low profiling 
% velocity or decelerate below a specified threshold and replaces them
% with a NaN, deletes the value or ignores it. It operates on two scans to
% determine the velocity and two velocities for the acceleration.
% 
% Inputs:
%   [Required] - RSK - The input RSK structure, with profiles as read using
%                    RSKreadprofiles.
%
%   [Optional] - profileNum - Optional profile number to calculate lag.
%                    Default is to calculate the lag of all detected
%                    profiles.
%
%                direction - 'up' for upcast, 'down' for downcast, or 'both' for
%                    all. Default is 'down'.
% 
%                velThreshold - The minimum speed at which the profile must
%                    be taken. Default is 0.25 m/s
%
%                accelThreshold - The minimum acceleration at which the profile must
%                    be taken. Default '-0.1'.
%
%                action - The 'action' to perform on a flagged value. The
%                    default, 'NaN', is to leave the spike as a missing
%                    value. Other options include 'remove', removes the
%                    value and 'nothing' simply returns the same RSK as was
%                    input and returns a vector of flagged samples.
%
%                latitude - Latitude at which the profile was taken.
%                    Default is 45.
%
% Outputs:
%    RSK - The structure without pressure reversal or slowdowns. The
%          pressure channel remains unchanged.
%
% Example: 
%    RSK = RSKopen(RSK)
%    RSK = RSKreadprofiles(RSK)
%    RSK = RSKremoveheave(RSK)
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-02-08

%% Check input and default arguments

validDirections = {'up', 'down'};
checkDirection = @(x) any(validatestring(x,validDirections));

validActions = {'NaN', 'remove', 'nothing'};
checkAction = @(x) any(validatestring(x,validActions));

classes = {'double'};
attributes = {'>=',-90,'<=',90};
checkLatitude = @(x) any(validateattributes(x, classes, attributes));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'velThreshold', 0.25, @isnumeric);
addParameter(p, 'accelThreshold', -0.1, @isnumeric);
addParameter(p, 'action', 'NaN', checkAction);
addParameter(p, 'latitude', 45, checkLatitude); 
parse(p, RSK, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
direction = p.Results.direction;
profileNum = p.Results.profileNum;
velThreshold = p.Results.velThreshold;
accelThreshold = p.Results.accelThreshold;
action = p.Results.action;
latitude = p.Results.latitude;


%% Determine if the structure has downcasts and upcasts

profileNum = checkprofiles(RSK, profileNum, direction);
castdir = [direction 'cast'];


%% Edit one cast at a time.

data = RSK.profiles.(castdir).data;
pressureCol = strcmpi('pressure', {RSK.channels.longName});
secondsperday = 86400;
for ndx = profileNum
    %% Filter pressure before taking the diff    
    smoothPressure = RSKsmooth(RSK, 'pressure', 'direction', direction, 'series', 'profile');    
    depth = calculatedepth(smoothPressure.profiles.(castdir).data(ndx).values(:,pressureCol), 'latitude', latitude);
    time = data(ndx).tstamp;

    %% Caculate Velocity.
    deltaD = diff(depth);
    deltaT = diff(time * secondsperday);
    dDdT = deltaD ./ deltaT;
    %The descent velocity is measured between time stamps. Must interpolate to realign.
    midtime = time(1:end-1) + deltaT/(2*secondsperday); 
    velocity = interp1(midtime, dDdT, time, 'linear', 'extrap');
    switch direction
        case 'up'
            flagidx = velocity > -velThreshold; 
        case 'down'
            flagidx = velocity < velThreshold;    
    end  
    
    %% Calculate Acceleration.
    if ~strcmpi(minAccel, 'None')
        d2DdT2 = diff(dDdT) ./ deltaT(1:end-1);
        acceleration = interp1(midtime(1:end-1), d2DdT2, time, 'linear', 'extrap');
        flagA = acceleration < accelThreshold; 
        flagidx = flagA | flagidx;
    end
   
    %% Perform the action on flagged scans.
    flagChannels = ~strcmpi('pressure', {RSK.channels.longName});    
    switch action
        case 'NaN' 
            data(ndx).values(flagidx,flagChannels) = NaN;
        case 'remove'
            data(ndx).tstamp(flagidx) = [];
            data(ndx).values(flagidx,:) = [];
    end                 
    flags(ndx).index = find(flagidx);
end

RSK.profiles.(castdir).data = data;

end






