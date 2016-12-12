function varargout = RSKremoveheave(RSK, varargin)

% RSKvelocityflag - Flags values that have pressure reversal or slowdows during
%               the profile.
%
% Syntax:  varargout = RSKremoveheave(RSK, [OPTIONS])
% 
% RSKremoveheave - This function filters the pressure channel with a lowpass
% boxcar to reduce the effect of noise then flags samples that have a low profiling 
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
%                   value. Other options include 'delete', deletes the
%                   value and 'nothing' simply returns the same RSK as was
%                   input and returns a vector of flagged samples.
%
%                latitude - Latitude at which the profile was taken.
%                   Default is [].
%
%                flagindex - Output the index of the values that were part of
%                  the pressure reversal. Default false.
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
% Last revision: 2016-12-07

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
addParameter(p, 'latitude', [], checkLatitude); 
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
data = RSK.profiles.(castdir).data;

%Find length of longest profile to set up flag matrix.
maxproflength = 0;
for ndx = profileNum
    proflength = length(data(ndx).tstamp);
    if proflength > maxproflength
    maxproflength = proflength;
    end
end
flagmat = NaN(maxproflength, length(profileNum));

pressureCol = find(strcmpi('pressure', {RSK.channels.longName}));
secondsperday = 86400;
for ndx = profileNum
    %% Filter pressure before taking the diff    
    RSKsmoothPressure = RSKfilter(RSK, 'Pressure', 'direction', direction);    
    depth = -calculatedepth(RSKsmoothPressure.profiles.(castdir).data(ndx).values(:,pressureCol), 'latitude', latitude);
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
            flagidx = velocity < -minVelocity; 
        case 'down'
            flagidx = velocity > minVelocity;    
    end  
    
    
    %% Calculate Acceleration.
    if ~strcmp(minDecel, 'None')
        d2DdT2 = diff(dDdT) ./ deltaT(1:end-1);
        acceleration = interp1(midtime(1:end-1), d2DdT2, time, 'linear', 'extrap');
        flagA = acceleration < minDecel; 
        flagidx = flagA & flagidx;
    end
   
    %% Perform the action on flagged scans.
    flagChannels = ~strcmpi('pressure', {RSK.channels.longName});    
    switch action
        case 'NaN' 
            data(ndx).values(flagidx,flagChannels) = NaN;
        case 'delete'
            data(ndx).tstamp(flagidx) = [];
            data(ndx).values(flagidx,:) = [];
    end                 
    flagmat(1:length(flagidx),ndx) = flagidx;
end
varargout{1} = RSK;
varargout{2} = find(flagmat);
end


function diagnosticremoveheave(data, RSKsmoothPressure, flagmat)

% diagnosticremoveheave - Highlight the samples that have pressure reversal
% or were taken while the profiling was too slow.
pressureCol


plot(RSK)

end







