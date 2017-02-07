function [RSK, flags] = RSKremoveheave(RSK, varargin)

% RSKremoveheave - Remove values that have pressure reversal or slowdows during
%               the profile.
%
% Syntax:  varargout = RSKremoveheave(RSK, [OPTIONS])
% 
% RSKremoveheave - This function filters the pressure channel with a lowpass
% boxcar to reduce the effect of noise, then finds samples that have a low profiling 
% velocity or decelerate below a specified threshold and replaces them
% with a NaN, deletes the value or ignores it. It operates on two scans to
% determine the velocity and two velocities for the acceleration.
% 
% Inputs:
%
%   [Required] - RSK - the input RSK structure, with profiles as read using
%                    RSKreadprofiles
%
%                channel - Longname of channel to plot (e.g. temperature,
%                   salinity, etc). Default is 'Temperature'
%
%   [Optional] - profileNum - the profiles to which to apply the correction. If
%                    left as an empty vector, will do all profiles.
%            
%                direction - the profile direction to consider. Must be either
%                   'down' or 'up'. Defaults to 'down'.
%
%                minVelocity - the minimum speed at which the profile must
%                   be taken. Default is 0.25 m/s
%
%                minAccel - the minimum acceleration at which the profile must
%                   be taken. Default '-0.1'.
%
%                action - the 'action' to perform on a flagged value. The
%                   default, 'NaN', is to leave the spike as a missing
%                   value. Other options include 'remove', removes the
%                   value and 'nothing' simply returns the same RSK as was
%                   input and returns a vector of flagged samples.
%
%                latitude - Latitude at which the profile was taken.
%                   Default is [].
%
% Outputs:
%    RSK - the structure without pressure reversal or slowdowns. The
%    pressure channel remains unchanged.
%
% Example: 
%    RSK = RSKopen(RSK)
%    RSK = RSKreadprofiles(RSK)
%    RSK = RSKremoveheave(RSK)
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-03-06

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
addParameter(p, 'minVelocity', 0.25, @isnumeric);
addParameter(p, 'minAccel', -0.1, @isnumeric);
addParameter(p, 'action', 'NaN', checkAction);
addParameter(p, 'latitude', 45, checkLatitude); 
parse(p, RSK, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
direction = p.Results.direction;
profileNum = p.Results.profileNum;
minVelocity = p.Results.minVelocity;
minAccel = p.Results.minAccel;
action = p.Results.action;
latitude = p.Results.latitude;



%% Determine if the structure has downcasts and upcasts & set profileNum accordingly
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



%% Edit one cast at a time.
data = RSK.profiles.(castdir).data;
pressureCol = strcmpi('pressure', {RSK.channels.longName});
secondsperday = 86400;
for ndx = profileNum
    %% Filter pressure before taking the diff    
    smoothPressure = RSKsmooth(RSK, 'pressure', 'direction', direction, 'series', 'profile');    
    depth = calculatedepth(smoothPressure.profiles.(castdir).data(ndx).values(:,pressureCol), 'latitude', latitude);
    time = RSK.profiles.(castdir).data(ndx).tstamp;
    

    %% Caculate Velocity.
    deltaD = diff(depth);
    deltaT = diff(time * secondsperday);
    dDdT = deltaD ./ deltaT;
    %The descent velocity is measured between time stamps. Must interpolate to realign.
    midtime = time(1:end-1) + deltaT/(2*secondsperday); 
    velocity = interp1(midtime, dDdT, time, 'linear', 'extrap');
    switch direction
        case 'up'
            flagidx = velocity > -minVelocity; 
        case 'down'
            flagidx = velocity < minVelocity;    
    end  
    
    
    %% Calculate Acceleration.
    if ~strcmpi(minAccel, 'None')
        d2DdT2 = diff(dDdT) ./ deltaT(1:end-1);
        acceleration = interp1(midtime(1:end-1), d2DdT2, time, 'linear', 'extrap');
        flagA = acceleration < minAccel; 
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






