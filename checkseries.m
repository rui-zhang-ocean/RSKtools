function [series] = checkseries(RSK, series)

% checkseries - Assigns the 'series' input to 'profile' or 'data'.
%
% Syntax:  [series] = checkseries(RSK, series)
% 
% This function assigns the series to 'profile' or 'data' depending on the
% RSK structure data.
%
% Inputs: 
%    RSK - Structure containing the logger metadata and data
%
%    series - Specifies the series to evaluate. Either 'data' or 'profile'.
%
% Outputs:
%    series - The series that is specified or in the structure
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-15

isData = isfield(RSK, 'data');

isDown = isfield(RSK.profiles.downcast, 'data');
isUp   = isfield(RSK.profiles.upcast, 'data');
isProfile = isUp || isDown;

if ~isempty(series)
    if strcmpi(series, 'profile') && isProfile
       series = 'profile';
    elseif strcmpi(series, 'data') && isData
        series = 'data';
    else
        error('The specified series in not populated in the structure');
    end
    
else
    if isData && isProfile
        error('Series argument must be specified, both data and profiles are populated with data. Consider removing one of them.');
    elseif isData
        series = 'data';
    elseif isProfile
        series = 'profile';
    else
        error('No data. Use RSKreadprofiles or RSKreaddata.');
    end
end
    