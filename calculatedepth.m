function depth = calculatedepth(pressure, varargin)

% calculatedepth - Calculate depth from pressure channel
%
% Syntax:  depth = calculatedepth(pressure, latitude)
% 
% Calculate depth from pressure. If TEOS-10 toolbox is installed it will
% use it http://www.teos-10.org/software.htm#1. Otherwise it is calculated
% based on a standard density of seawater.\
%
% Inputs:
%    pressure - a vector of pressure values in dbar
%
%    latitude - Latitude at the location of the pressure measurement in
%    decimal degrees north. Default [], will calculate using density.
%
%    densityseawater - The density of sea water at the location of the
%    pressure measurement. Note: It is only used if TEOS-10 isn't installed
%    and a latitude is not provided. Default is 1030.
%
% Outputs:
%    depth - a vector containing depths in meters
%
% Example: 
%    depth = calculatedepth(p, 'latitude', 52)
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-12-07

%% Parse Inputs

p = inputParser;
addParameter(p, 'latitude', [], @isnumeric);
addParameter(p, 'densityseawater', 1030, @isnumeric);
parse(p, varargin{:})

% Assign each argument
latitude = p.Results.latitude;
densityseawater = p.Results.densityseawater;


%% Check if user has the TEOS-10 GSW toolbox installed
hasTEOS = exist('gsw_z_from_P') == 2;

%% Calculate depth
if hasTEOS && ~isempty(latitude)
    depth = -gsw_z_from_p(pressure, latitude);    
else
    % If the toolbox is not installed or a latitude is not given, calculated from density
    g = 9.80665;  % m/s^2
    depth = pressure ./ (densityseawater*g);
end

end