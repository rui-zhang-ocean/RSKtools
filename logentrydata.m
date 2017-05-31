function logdata = logentrydata(RSK, profile, direction)

% logentrydata - creates a log entry describing the data used in the fields
%
% Syntax:  [logdata] = logentrydata(RSK, profileNum, dataIdx)
%
% This function creates a log entry describing which profiles were changed.
%
% Inputs:
%    RSK - The input RSK structure
%
%    profile - The input given to specify which profiles to use.
%
%    direction - The direction of the profiles.
%
% Outputs:
%    logdata - a string describing which data fields were modified.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-31

if size(RSK.data, 2) == 1
    logdata = 'the data';
    return
end

profilecast = size(RSK.profiles.order, 2);
if isempty(profile)
    if profilecast == 2 && ~strcmp(direction, 'both') && ~isempty(direction)
        logdata = ['all ' direction 'cast'];
    else
        logdata = 'all profiles';
    end
elseif length(profile) == 1
    if profilecast == 2 && ~strcmp(direction, 'both') && ~isempty(direction)
        logdata = [direction 'cast of profile ' num2str(profile, '%1.0f')];
    else
        logdata = ['profile ' num2str(profile, '%1.0f')];
    end
else
    if profilecast == 2 && ~strcmp(direction, 'both') && ~isempty(direction)
        logdata = [direction 'cast of profiles ' num2str(profile(1:end-1), '%1.0f, ') ' and ' num2str(profile(end))];
    else
        logdata = ['profiles ' num2str(profile(1:end-1), '%1.0f, ') ' and ' num2str(profile(end))];
    end
end

end