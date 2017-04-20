function RSK = RSKfindprofiles(RSK, varargin)

% RSKfindprofiles - finds profiles in the rsk pressure data if profile events are non exist.
%
% Syntax:  [RSK] = RSKfindprofiles(RSK, varargin)
% 
% RSKfindprofiles implements the algorithm used by the logger to find upcasts
% or downcasts if they were not detected while the instument was recording.
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger metadata and thumbnails
%               
%    [Optional] - pressureThreshold - The pressure difference required to detect a
%                    profile. Standard is 3dbar, or
%                    (max(pressure)-min(pressure)/4.   
%               - conductivityThreshold - The conductivity value that indicates the
%                    sensor is out of water. Typically 0.05 mS/cm is very good. If the
%                    water is fresh it may be better to use a lower value.
%
% Output: 
%
%   RSK - Structure containing profiles field with the profile metadata.
%         Use RSKreadprofiles to populate the profiles field with data.
%
% Ex:
%    RSK = RSKopen(fname);
%    RSK = RSKreaddata(RSK);
%    RSK = RSKfindprofiles(RSK);
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-03-22


%% Parse Inputs
p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profileThreshold', [], @isnumeric);
addParameter(p, 'conductivityThreshold', 0.05, @isnumeric);
parse(p, RSK, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
profileThreshold = p.Results.profileThreshold;
conductivityThreshold = p.Results.conductivityThreshold;


%% Check if upcasts is already populated
if isfield(RSK, 'profiles')
    error('Profiles are already found, get data using RSKreadprofiles.m');
end


%% Set up values
pressureCol = find(strcmpi('pressure', {RSK.channels.longName}));
condCol = find(strcmpi('conductivity', {RSK.channels.longName}));
pressure = RSK.data.values(:, pressureCol(1));
timestamp = RSK.data.tstamp;

% If conductivity is present it will be used to detect when the logger is
% out of the water.
if isempty(condCol)
    conductivity = [];
else 
    conductivity = RSK.data.values(:, condCol(1));
end

% Profile threshold is a quarter of the max range of pressure if none is input.
if isempty(profileThreshold)
    profileThreshold = (max(pressure)-min(pressure))/4;
end


%% Run profile detection
[wwevt] = detectprofiles(pressure, timestamp, conductivity, profileThreshold, conductivityThreshold);


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
            % Upcast end is the sample before a downcast start
            upend(u) = timestamp(t-1);
            u = u+1;

        elseif wwevt(ndx,2) == 2
            % Downcast end is the sample before a upcast start
            downend(d) = timestamp(t-1);
            d = d+1;  
        end

    end
    if wwevt(ndx,2) == 3
        if wwevt(ndx-1,2) == 1
            % Event 3 ends a downcast if that was the last event
            downend(d) = timestamp(t-1);
            d = d+1;
            
         elseif wwevt(ndx-1,2) == 2
             % Event 3 ends a upcast if that was the last event
            upend(u) = timestamp(t-1);
            u = u+1;
        end
    end
end
         

%% Put profiling events into RSK profiles field.
RSK.profiles.upcast.tstart = upstart;
RSK.profiles.upcast.tend = upend';
RSK.profiles.downcast.tstart = downstart;
RSK.profiles.downcast.tend = downend';
 

end
            
   




    
