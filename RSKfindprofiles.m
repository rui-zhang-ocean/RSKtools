function RSK = RSKfindprofiles(RSK, varargin)

%RSKfindprofiles - Find profiles using the pressure data. 
%
% Syntax:  [RSK] = RSKfindprofiles(RSK, [OPTIONS])
% 
% Implements the algorithm used by the logger to find upcasts or downcasts
% by looking for pressure reversals in the pressure data. It retrieves
% metadata about the profiles and puts it into the profiles field of the
% RSK. . The algorithm splits each profile into upcasts and downcasts, and
% each has tstart and tend for start times and end times.
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger metadata and thumbnail
%               
%    [Optional] - pressureThreshold - Pressure difference required to
%                       detect a profile. The logger uses 3dbar, which is
%                       the default. It may be too large for short
%                       profiles.  
%
%                 conductivityThreshold - Threshold value that indicates
%                       the sensor is out of seawater. Default is 0.05
%                       mS/cm. If the water is fresh, you may consider
%                       using a lower value.      
%
% Output: 
%   RSK - Structure containing profiles field with the profile metadata.
%         Use RSKreadprofiles to populate the profiles field with data.
%
% Ex:
%    RSK = RSKopen(fname);
%    RSK = RSKreaddata(RSK);
%    RSK = RSKfindprofiles(RSK, 'pressureThreshold', 1);
%
% See also: RSKreadprofiles, RSKgetprofiles.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-22

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profileThreshold', 3, @isnumeric);
addParameter(p, 'conductivityThreshold', 0.05, @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
profileThreshold = p.Results.profileThreshold;
conductivityThreshold = p.Results.conductivityThreshold;



if isfield(RSK, 'profiles')
    error('Profiles are already found, get data using RSKreadprofiles.m');
end



%% Set up values
Pcol = getchannelindex(RSK, 'Pressure');
pressure = RSK.data.values(:, Pcol);
timestamp = RSK.data.tstamp;

% If conductivity is present it will be used to detect when the logger is
% out of the water.
try
    Ccol = getchannelindex(RSK, 'Conductivity');
    conductivity = RSK.data.values(:, Ccol);
catch
    conductivity = [];
end



%% Run profile detection
[wwevt] = detectprofiles(pressure, timestamp, conductivity, profileThreshold, conductivityThreshold);
if size(wwevt,1) < 2
    disp('No profiles were detected in this dataset with the given parameters.')
    return
end



%% Use the events to establish profile start and end times.
% Event 1 is a downcast start
downstart = wwevt(wwevt(:,2) == 1,1);
% Event 2 is a upcast start
upstart = wwevt(wwevt(:,2) == 2,1);
% Event 3 is out of water

u=1;% up index
d=1;% down index
for ndx = 2:length(wwevt)
    t = find(timestamp == wwevt(ndx,1),1);
    if wwevt(ndx-1,2) ~= 3
        if wwevt(ndx,2) == 1
            % Upcast end is the sample of a downcast start
            upend(u) = timestamp(t);
            u = u+1;

        elseif wwevt(ndx,2) == 2
            % Downcast end is the sample of a upcast start
            downend(d) = timestamp(t);
            d = d+1;  
        end

    end
    if wwevt(ndx,2) == 3
        if wwevt(ndx-1,2) == 1
            % Event 3 ends a downcast if that was the last event
            downend(d) = timestamp(t);
            d = d+1;
            
         elseif wwevt(ndx-1,2) == 2
             % Event 3 ends a upcast if that was the last event
            upend(u) = timestamp(t);
            u = u+1;
        end
    end
end

% Finish the last profile
if wwevt(end,2) == 1
    downend(d) = timestamp(end);
elseif wwevt(end,2) == 2
    upend(u) = timestamp(end);
end



RSK.profiles.upcast.tstart = upstart;
RSK.profiles.upcast.tend = upend';
RSK.profiles.downcast.tstart = downstart;
RSK.profiles.downcast.tend = downend';
 
end
            
   




    
