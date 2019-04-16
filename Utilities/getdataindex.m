function castidx = getdataindex(RSK, varargin)

% GETDATAINDEX - Return the index of data elements requested.
%
% Syntax:  [castidx] = GETDATAINDEX(RSK, [OPTIONS])
% 
% Selects the data elements that fulfill the requirements described by the 
% profile number and direction arguments.
%
% Inputs:
%   [Required] - RSK - Structure containing the logger data
%
%   [Optional] - profile - Profile number. Default is to use all profiles
%                      available.
% 
%                direction - Cast direction. Default is to use all
%                      directions available. 
%            
% Outputs:
%    castidx - Array containing the index of data's elements.
%
% See also: RSKplotprofile, RSKsmooth, RSKdespike.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2019-04-16


validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addOptional(p, 'profile', [], @isnumeric);
addOptional(p, 'direction', [], checkDirection);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
profile = p.Results.profile;
direction = p.Results.direction;


ndata = length(RSK.data);
isProfile = isfield(RSK.data,'direction') && isfield(RSK.data,'profilenumber');

if isProfile
    
    if isempty(direction) || strcmpi(direction,'both')        
        if isempty(profile)            
            castidx = 1:ndata;            
        else           
            castidx = find(ismember([RSK.data.profilenumber],profile));           
        end        
    elseif strcmpi(direction,'up') || strcmpi(direction,'down')       
        if isempty(profile)            
            castidx = find(ismember({RSK.data.direction},direction));            
        else           
            castidx = find(ismember([RSK.data.profilenumber],profile) & ismember({RSK.data.direction},direction));           
        end      
    end
    
else
    
    if isempty(direction) && isempty(profile)
        castidx = 1:ndata;
    else
        error('RSK has time series only, please use RSKreadprofiles or RSKtimeseries2profiles before specifying profile number and direction...')
    end          
    
end

if isempty(castidx)     
    error('The profile or direction requested does not exist in this RSK structure.');
end
     
end

