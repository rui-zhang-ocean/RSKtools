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
%   [Required] - RSK - the input RSK structure, with profiles but no
%                   profile events
%
%   [Optional] - direction - the profile direction to consider. Must be either
%                   'down' or 'up'. Only needed if series is profile. Defaults to 'down'.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-01-09

%% Check input and default arguments
validDirections = {'up', 'down'};
checkDirection = @(x) any(validatestring(x,validDirections));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'direction', 'down', checkDirection);
parse(p, RSK, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
direction = p.Results.direction;

castdir = [direction 'cast'];

%% Check if upcasts is already populated
if isfield(RSK.profiles.(castdir). tstart)
    error('Profiles are already found, get data using RSKreadprofiles.m');
end
% Check regionCast once this table is used to find casts...populate with
% results if it is not filled.






    
