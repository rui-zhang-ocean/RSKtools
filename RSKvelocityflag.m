function [RSK] = RSKvelocityflag(RSK, varargin)

% RSKvelocityflag - Flags values that have pressure reversal or slowdows during
%               the profile.
%
% Syntax:  [RSK] = RSKvelocityflag(RSK, [OPTIONS])
% 
% RSKloopedit - This function filters the pressure channel with a lowpass
% boxcar to reduce the effect of noise then flags scans that have a low profiling 
% velocity or decelerate below a specified threshold and replaces them
% with a NaN or an interpolated value. It operates on two scans to
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
%                   'down' or 'up'. Only needed if series is profile. Defaults to 'down'.
%
%                minVelocity - the minimum speed at which the profile must
%                   be taken. Default is 0.25 m/s
%
%                minDecel - the minimum deceleration at which the profile must
%                   be taken. Default '-0.1'.
%
%                action - the 'action' to perform on a flagged value. The
%                   default, 'NaN', is to leave the spike as a missing
%                   value. Another option 'interp' is to interpolate based
%                   on 'good' values. 
%
%                latitude - Latitude at which the profile was taken.
%                   Default is 52.
%
% Outputs:
%    RSK - the structure without pressure reversal or slowdowns. The
%    pressure channel remains unchanged.
%
% Example: 
%    RSK = RSKopen(RSK)
%    RSK = RSKreadprofiles(RSK)
%    RSK = RSKvelocityedit(RSK)
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-11-30

%% Check input and default arguments

validDirections = {'up', 'down'};
checkDirection = @(x) any(validatestring(x,validDirections));

validActions = {'NaN', 'interp'};
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
addParameter(p, 'minDecel', -0.1, @isnumeric);
addParameter(p, 'action', 'NaN', checkAction);
addParameter(p, 'latitude', 52, checkLatitude); 
parse(p, RSK, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
direction = p.Results.direction;
profileNum = p.Results.profileNum;
minVelocity = p.Results.minVelocity;
minDecel = p.Results.minDecel;
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
pressureCol = find(strcmpi('pressure', {RSK.channels.longName}));
secondsperday = 86400;
for i = profileNum
    smoothPressure = RSKfilter(RSK, 'Pressure', 'direction', direction);    
    depth = -gsw_z_from_p(smoothPressure, latitude);
    time = RSK.profiles.(castdir).data(i).tstamp;
    
    %% Filter pressure before taking the diff

    
    %% Caculate Velocity.
    deltaD = diff(depth);
    deltaT = diff(time * secondsperday);
    dDdT = deltaD ./ deltaT;
    %The descent velocity is measured between time stamps. Must interpolate to realign.
    midtime = time(1:end-1) + deltaT/(2*secondsperday); 
    velocity = interp1(midtime, dDdT, time, 'linear', 'extrap');
    switch direction
        case 'up'
            flag = velocity < -minVelocity; 
        case 'down'
            flag = velocity > minVelocity;    
    end  
    
    %% Calculate Acceleration.
    if ~strcmp(minDecel, 'None')
        d2DdT2 = diff(dDdT) ./ deltaT(1:end-1);
        acceleration = interp1(midtime(1:end-1), d2DdT2, time, 'linear', 'extrap');
        flagA = acceleration < minDecel; 
        flag = flagA & flag;
    end
   
    %% Perform the action on flagged scans.
    flagChannels = ~strcmpi('pressure', {RSK.channels.longName});    
    switch action
        case 'NaN' 
            RSK.profiles.(castdir).data(i).values(flag,flagChannels) = NaN;
        case 'interp'
            for k = find(flagChannels)
                RSK.profiles.(castdir).data(i).values(:,k) = interp1(time(~flag), RSK.profiles.(castdir).data(i).values(~flag,k), time, 'linear', 'extrap');
            end
    end                 

end
end



