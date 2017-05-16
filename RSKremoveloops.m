function [RSK, flagidx] = RSKremoveloops(RSK, varargin)

% RSKremoveloop - Remove values exceeding a threshold CTD profiling
%                  rate. 
% Syntax:  [RSK, flagidx] = RSKremoveloop(RSK, [OPTIONS])
% 
% This function filters the pressure channel with a lowpass boxcar to
% reduce the effect of noise, then finds the samples that exceed a
% threshold profiling velocity and replaces them with a NaN. Profiling rate
% is computed by differencing the depth time series. 
% 
% Inputs:
%   [Required] - RSK - The input RSK structure.
%
%   [Optional] - profileNum - Optional profile number(s) on which to operate.
%                      Default is to work on all profiles.
%
%                direction - 'up' for upcast,'down' for downcast or 'both'
%                      for up and downcast. Default is 'down'. 
% 
%                threshold - The minimum speed at which the profile must be
%                      taken. Default is 0.25 m/s 
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
% Last revision: 2017-05-10

%% Check input and default arguments

validDirections = {'up', 'down', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'threshold', 0.25, @isnumeric);
parse(p, RSK, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
direction = p.Results.direction;
profileNum = p.Results.profileNum;
threshold = p.Results.threshold;

if strcmpi(direction, 'both')
    direction = {'down', 'up'};
else
    direction = {direction};
end

Dcol = getchannelindex(RSK, 'Depth');

secondsperday = 86400;

for dir = direction
    profileIdx = checkprofiles(RSK, profileNum, dir{1});
    castdir = [dir{1} 'cast'];
    data = RSK.profiles.(castdir).data;
    for ndx = profileIdx
        %% Filter pressure before taking the diff    
        d = data(ndx).values(:,Dcol);
        depth = runavg(d, 3, 'nan');
        time = data(ndx).tstamp;

        %% Caculate Velocity.
        deltaD = diff(depth);
        deltaT = diff(time * secondsperday);
        dDdT = deltaD ./ deltaT;
        midtime = time(2:end) + deltaT/(2*secondsperday);
        velocity = interp1(midtime, dDdT, time, 'linear', 'extrap');
        switch dir{1}
            case 'up'
                flag = velocity > -threshold; 
            case 'down'
                flag = velocity < threshold;    
        end  

        %% Perform the action on flagged scans.
        flagChannels = ~strcmpi('pressure', {RSK.channels.longName});    
        data(ndx).values(flag,flagChannels) = NaN;
        flagidx(ndx).(castdir).index = find(flag);
    end

    RSK.profiles.(castdir).data = data;

    %% Udate log
    logprofile = logentryprofiles(dir{1}, profileNum, profileIdx);
    logentry = ['Samples measured at a profiling velocity less than ' num2str(threshold) 'm/s were replaced with NaN on ' logprofile '.'];

    RSK = RSKappendtolog(RSK, logentry);
end
end







