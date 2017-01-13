function RSK = RSKfindprofiles(RSK, varargin)

% RSKfindprofiles - finds profiles in the rsk pressure data if profile events are non exist.
%
% Syntax:  [RSK] = RSKfindprofiles(RSK, varargin)
% 
% RSKfindprofiles implements the algorithm used by the logger to find upcasts
% or downcasts if they were not detected while the instument was recording.
%
% Inputs:
%    
%   RSK - the input RSK structure, with profiles but no
%                   profile events
%
% Ex:
%    RSK = RSKopen(fname);
%    RSK = RSKreaddata(RSK);
%    RSK = RSKfindprofiles(RSK);
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-01-11


%% Check if upcasts is already populated
if isfield(RSK, 'profiles')
    error('Profiles are already found, get data using RSKreadprofiles.m');
end
% Check regionCast once this table is used to find casts...populate with
% results if it is not filled.

%% Set up values
pressureCol = find(strcmpi('pressure', {RSK.channels.longName})) ;
pressure = RSK.data.values(:, pressureCol(1));
timestamp = RSK.data.tstamp;


%% Run profile detection
[upcaststart, downcaststart] = detectprofiles(pressure, timestamp);

if upcaststart(1) < downcaststart(1)
    RSK.profiles.upcast.tstart = upcaststart;
    RSK.profiles.upcast.tend = downcaststart;
    RSK.profiles.downcast.tstart = downcaststart;
    RSK.profiles.downcast.tend = upcaststart(2:end);
    RSK.profiles.downcast.tend(end+1) = RSK.data.tstamp(end);
else
    RSK.profiles.upcast.tstart = upcaststart;
    RSK.profiles.upcast.tend = downcaststart(2:end);
    RSK.profiles.upcast.tend(end+1) = RSK.data.tstamp(end);
    RSK.profiles.downcast.tstart = downcaststart;
    RSK.profiles.downcast.tend = upcaststart;
end
end
            
   




    
