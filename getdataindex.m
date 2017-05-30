function castIdx = getdataindex(RSK, profile)

% checkprofile - Determines which of data's elements are selected
%
% Syntax:  [castIdx] = getdataindex(RSK, profile)
% 
% A helper function used to select the data fields that are selected.
%
% Inputs:
%   RSK - Structure containing the logger data read
%         from the RSK file.
%
%   profile - Optional profile number. Default is to use all of data's
%         elements.
%            
% Outputs:
%    castIdx - An array containing the index of data's elements.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-30

profilecasts = size(RSK.profiles.order,2);
ndata = length(RSK.data);

if exist('profile', 'var') && ~isempty(profile)
    if max(profile) > ndata
        error('The profileNum selected is greater than the total amount of profiles in this file.');
    end
    if 
        dataIdx = profile;
    end
else
    dataIdx = 1:ndata;
end