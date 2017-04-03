function lags = checklag(lag, profileIdx)

% checkprofile - check that lag values entered are valid
%
% Syntax:  [lags] = checklag(lag, profileIdx)
% 
% A helper function used to check if the lag values are intergers and
% either one for all profiles or one for each profiles.
%
% Inputs:
%   lag - The lag values entered in RSKalignchannel
%
%   profileIdx - The profiles that the lag will be applied on
%
% Outputs:
%    lags - The final array of lags, one for each profiles
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-04-03

if ~isequal(fix(lag),lag),
    error('Lag values must be integers.')
end

if length(lag) == 1 && length(profileIdx) ~= 1
    lags = repmat(lag, 1, length(profileIdx));
elseif length(lag) > 1 && length(lag) ~= length(profileIdx)
    error(['Length of lag must match number of profiles or be a ' ...
           'single value']);
else
    lags = lag;
end

end