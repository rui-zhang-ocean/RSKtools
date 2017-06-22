function [RSK, flagidx] = RSKremoveloops(RSK, varargin)

%RSKremoveloops - Remove values exceding a threshold CTD profiling rate.
%
% Syntax:  [RSK, flagidx] = RSKremoveloops(RSK, [OPTIONS])
% 
% Filters the pressure channel with a lowpass boxcar to reduce the effect
% of noise, then finds the samples that exceed a threshold profiling
% velocity and replaces them with a NaN. Profiling rate is computed by
% differencing the depth time series.  
% 
% Inputs:
%   [Required] - RSK - Structure.
%
%   [Optional] - profile - Profile number. Default is to operate on all of
%                      the elements in the data table. 
%
%                 direction - 'up' for upcast, 'down' for downcast, or
%                      `both` for all. Default all directions available.
% 
%                threshold - Minimum speed at which the profile must be
%                      taken. Default is 0.25 m/s.
%
% Outputs:
%    RSK - Structure without pressure reversal or slowdowns.
%
%    flagidx - Index of the samples that did not meet the profiling velocity criteria.
%
% Example: 
%    RSK = RSKopen(RSK)
%    RSK = RSKreadprofiles(RSK)
%    RSK = RSKremoveloops(RSK)
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-22

validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'direction', [], checkDirection);
addParameter(p, 'threshold', 0.25, @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
profile = p.Results.profile;
direction = p.Results.direction;
threshold = p.Results.threshold;



Dcol = getchannelindex(RSK, 'Depth');
castidx = getdataindex(RSK, profile, direction);
for ndx = castidx
    d = RSK.data(ndx).values(:,Dcol);
    depth = runavg(d, 3, 'nan');
    time = RSK.data(ndx).tstamp;

    velocity = calculatevelocity(depth, time);
    if getcastdirection(depth, 'up')
            flag = velocity > -threshold; 
    else
            flag = velocity < threshold;    
    end  

    flagChannels = ~strcmpi('Depth', {RSK.channels.longName});    
    RSK.data(ndx).values(flag,flagChannels) = NaN;
    flagidx(ndx).index = find(flag);
end



logdata = logentrydata(RSK, profile, direction);
logentry = ['Samples measured at a profiling velocity less than ' num2str(threshold) 'm/s were replaced with NaN on ' logdata '.'];

RSK = RSKappendtolog(RSK, logentry);



%% Nested function
    function velocity = calculatevelocity(depth, time)
    % calculate the velocity using midpoints of depth and time.
    
        secondsperday = 86400;
        deltaD = diff(depth);
        deltaT = diff(time * secondsperday);
        dDdT = deltaD ./ deltaT;
        midtime = time(2:end) + deltaT/(2*secondsperday);
        velocity = interp1(midtime, dDdT, time, 'linear', 'extrap');
    
    end

end
