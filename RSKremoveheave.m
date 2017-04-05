function [RSK, flagidx] = RSKremoveheave(RSK, varargin)

% RSKremoveheave - Remove values that have pressure reversal or slowdows during
%                  the profiling.
%
% Syntax:  [RSK, flagidx] = RSKremoveheave(RSK, [OPTIONS])
% 
% RSKremoveheave - This function filters the pressure channel with a lowpass
% boxcar to reduce the effect of noise, then finds samples that have a low
% profiling velocity and replaces them with a NaN. It operates on two scans
% to determine the velocity.     
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
%                latitude - Latitude at which the profile was taken.
%                    Default is 45.
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

profileNum = checkprofiles(RSK, profileNum, direction);
castdir = [direction 'cast'];


%% Edit one cast at a time.
data = RSK.profiles.(castdir).data;
pCol = strcmpi('pressure', {RSK.channels.longName});
secondsperday = 86400;

for ndx = profileNum
    %% Filter pressure before taking the diff    
    pressure = RSK.profiles.(castdir).data(ndx).values(:,pCol);
    pressuresmooth = runavg(pressure, 3, 'nanpad');
    depth = calculatedepth(pressuresmooth, 'latitude', latitude);
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

end






