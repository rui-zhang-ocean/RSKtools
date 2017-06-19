function castidx = getdataindex(RSK, varargin)

% checkprofile - Determines which of data's elements are selected
%
% Syntax:  [castIdx] = getdataindex(RSK, profile)
% 
% A helper function used to select the data elements that are selected
% based on profile number and direction.
%
% Inputs:
%   [Required] - RSK - Structure containing the logger data read
%                      from the RSK file.
%
%   [Optional] - profile - Optional profile number. Default is to use all of data's
%                      elements.
%
%                direction - Optional cast direction.
%            
% Outputs:
%    castidx - An array containing the index of data's elements.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-30

validationFcn = @(x) ischar(x) || isempty(x);

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addOptional(p, 'profile', [], @isnumeric);
addOptional(p, 'direction', [], validationFcn);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
profile = p.Results.profile;
direction = p.Results.direction;


if size(RSK.data,2) == 1
    castidx = 1;
    if ~isempty(profile) && profile ~= 1  
        error('The profile requested is greater than the total amount of profiles in this file.');
    end 
    return
end

profilecast = size(RSK.profiles.order,2);
ndata = length(RSK.data);

if ~isempty(direction) && profilecast == 1 && ~strcmp(RSK.profiles.order, direction)
    error(['There is no ' direction 'cast in this RSK structure.']);
end



if isempty(profile) && isempty(direction)
    castidx = 1:ndata;
elseif ~isempty(profile)
    if max(profile) > ndata/profilecast
        error('The profile requested is greater than the total amount of profiles in this file.');
    end
    
    if profilecast == 2
        if isempty(direction) || strcmp(direction, 'both')
            castidx = [(profile*2)-1 profile*2];
            castidx = sort(castidx);
        elseif strcmp(RSK.profiles.order{1}, direction)
            castidx = (profile*2)-1;
        else
            castidx = profile*2;
        end
    else
        castidx = profile;
    end
else
    if profilecast == 2
        if strcmp(direction, 'both')
            castidx = 1:ndata;
        elseif strcmp(RSK.profiles.order{1}, direction)
            castidx = 1:2:ndata;
        else
            castidx = 2:2:ndata;
        end
    else
        castidx = 1:ndata;
    end
end

        
        
end

