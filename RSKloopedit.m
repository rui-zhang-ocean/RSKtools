function [RSK] = RSKloopedit(RSK, varargin)

% RSKloopedit - Flags values that have pressure reversal or slowdows during
%               the profile.
%
% Syntax:  [RSK] = RSKloopedit(RSK, [OPTIONS])
% 
% RSKloopedit - This function flags scans that have a low profiling
% velocity or decelerating below a specified threshold and replaces them
% with a NaN or an interpolated value. It operates on two scans to
% determine the velocity and two velocities for the acceleration.
%
% Note: It is VERY important to run RSKfilter.m on the
% pressure channel to filter out the noise before running RSKloopedit
% because the noise will be amplified by this function. 
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
%                   be taken. Default 'None'.
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
%    RSK - the structure without pressure reversal or slowdowns
%
% Example: 
%    RSK = RSKopen(RSK)
%    RSK = RSKreadprofiles(RSK)
%    RSK = RSKfilter(RSK, 'pressure')
%    RSK = RSKalignchannel(RSK, 'salinity')
%    RSK = RSKloopedit(RSK)
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-11-28

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
addParameter(p, 'minDecel', 'None', @isnumeric);
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
    depth = -gsw_z_from_p(RSK.profiles.(castdir).data(i).values(:,pressureCol), latitude);
    time = RSK.profiles.(castdir).data(i).tstamp;
    
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



