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
%                      Default is to work on all data's fields.
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
% Last revision: 2017-05-23

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'threshold', 0.25, @isnumeric);
parse(p, RSK, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
profileNum = p.Results.profileNum;
threshold = p.Results.threshold;

Dcol = getchannelindex(RSK, 'Depth');

dataIdx = setdataindex(RSK, profileNum);
for ndx = dataIdx 
    d = RSK.data(ndx).values(:,Dcol);
    depth = runavg(d, 3, 'nan');
    time = RSK.data(ndx).tstamp;

    velocity = calculatevelocity(depth, time);
    if getcastdirection(depth, 'up')
            flag = velocity > -threshold; 
    else
            flag = velocity < threshold;    
    end  

    flagChannels = ~strcmpi('pressure', {RSK.channels.longName});    
    data(ndx).values(flag,flagChannels) = NaN;
    flagidx(ndx).index = find(flag);
end

RSK.data = data;

logdata = logentrydata(RSK, profileNum, dataIdx);
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
