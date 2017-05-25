function logdata = logentrydata(RSK, profileNum, dataIdx)

% logentrydata - creates a log entry describing the data used in the fields
%
% Syntax:  [logdata] = logentrydata(RSK, profileNum, dataIdx)
%
% This function creates a log entry describing which profiles were changed.
%
% Inputs:
%    RSK - The input RSK structure
%
%    profileNum - The input given to specify which profiles to use.
%
%    dataIdx - The index of the profiles used.
%
% Outputs:
%    logdata - a string describing which data fields were modified.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-25

if size(RSK.data,2) == 1 || isempty(profileNum)
    logdata = 'all data fields';
elseif length(profileNum) == 1 && size(RSK.data,2) > 1 
    logdata = ['data field ' num2str(dataIdx, '%1.0f')];
else 
    logdata = ['data field ' num2str(dataIdx(1:end-1), ', %1.0f') ' and ' num2str(dataIdx(end))];
end

end