function RSK = RSKremovecasts(RSK,varargin)

% RSKremovecasts - Remove the data elements with either an increasing or
% decreasing pressure.
%
% Syntax:  RSK = RSKremovecasts(RSK,[OPTIONS])
%
% Keeps only either downcasts or upcasts in the RSK structure. Default is
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


validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addOptional(p, 'direction', 'up', checkDirection);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
direction = p.Results.direction;


if strcmp(direction,'up')
    RSK = preservedowncast(RSK);
else
    RSK = preserveupcast(RSK);
end

end