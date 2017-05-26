function dataIdx = setdataindex(RSK, profileNum)

% checkprofile - Determined which data field index are selected
%
% Syntax:  [dataIdx] = setdataindex(RSK, profileNum)
% 
% A helper function used to select the data fields that are selected.
%
% Inputs:
%   RSK - Structure containing the logger data read
%         from the RSK file.
%
%   profileNum - Optional profile number. Default is to use all data
%         fields.
%            
% Outputs:
%    dataIdx - An array containing the index of the data fields.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-26

ndata = length(RSK.data);

if exist('profileNum', 'var') && ~isempty(profileNum)
    if max(profileNum) > length(ndata)
        error('The profileNum selected is greater than the total amount of profiles in this file.');
    else
        dataIdx = profileNum;
    end
else
    dataIdx = 1:length(ndata);
end