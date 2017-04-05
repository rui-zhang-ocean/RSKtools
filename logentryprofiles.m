function logprofile = logentryprofiles(direction, profileNum, profileIdx)

% logentryprofile - creates a log entry for profiles
%
% Syntax:  [logprofile] = logentryprofiles(profileNum)
%
% This function creates a log entry describing which profiles were changed.
%
% Inputs:
%    direction - The direction of the profiles.
%   
%    profileNum - The input given to specify which profiles to use.
%
%    profileIdx - The index of the profiles used.
%
% Outputs:
%    RSK - Structure containing the logger metadata.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-04-05


if isempty(profileNum)
    logprofile = ['all ' direction 'cast profiles'];
elseif length(profileNum) == 1
    logprofile = [direction 'cast profiles ' num2str(profileIdx, '%1.0f')];
else 
    logprofile = [direction 'cast profiles' num2str(profileIdx(1:end-1), ', %1.0f') ' and ' num2str(profileIdx(end))];
end
end