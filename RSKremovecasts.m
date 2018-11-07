function RSK = RSKremovecasts(RSK,varargin)

% RSKremovecasts - Remove the data elements with either an increasing or
% decreasing pressure.
%
% Syntax:  RSK = RSKremovecasts(RSK,[OPTIONS])
%
% Remove either downcasts or upcasts in the RSK structure. Default is
% to remove upcasts.
%
% Note: When there are only downcasts in current RSK structure, request to
% remove downcasts will not take effect. The same for upcasts.
%
% Inputs: 
%    [Required] - RSK - Structure containing logger data in profile
%                 structure.
%
%    [Optional] - direction - 'up' for upcast, 'down' for downcast. Default
%                 is 'up'.
%
% Outputs:
%    RSK - Structure only containing downcast or upcast data.
%
% Examples:
%    rsk = RSKremovecasts(rsk,'direction','up');
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-11-06


validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addOptional(p, 'direction', 'up', checkDirection);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
direction = p.Results.direction;


Pcol = getchannelindex(RSK, 'Pressure');
ndata = length(RSK.data);

idx = NaN(1, ndata);
for ndx = 1:ndata
    pressure = RSK.data(ndx).values(:, Pcol);
    idx(1, ndx) = getcastdirection(pressure, direction);
end

if ~any(idx)
    disp(['There are no ' direction 'casts in this RSK structure.']);
    return;
end

if all(idx)
    disp(['There are only ' direction 'casts in this RSK structure.']);
    return;
end

if isfield(RSK.profiles,[direction 'cast'])
    RSK.profiles = rmfield(RSK.profiles,[direction 'cast']);
end

RSK.profiles.originalindex = RSK.profiles.originalindex(logical(~idx));
if strcmpi(direction,'up');
    RSK.profiles.order = {'down'};
else
    RSK.profiles.order = {'up'};
end
RSK.data = RSK.data(logical(~idx));

RSK.region(ismember([RSK.region.regionID], [RSK.regionCast(strncmpi({RSK.regionCast.type},direction,length(direction))).regionID])) = [];
if isfield(RSK.region,'label')
    RSK.region(strncmpi({RSK.region.label},direction,length(direction))) = [];
end
RSK.regionCast(strncmpi({RSK.regionCast.type},direction,length(direction))) = [];

end