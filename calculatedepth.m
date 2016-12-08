function depth = calculatedepth(pressure, varargin)

% calculatedepth - Calculate depth from pressure channel
%
% Syntax:  depth = calculatedepth(pressure, latitude)
% 
% Calculate depth from pressure. If TEOS-10 toolbox is installed it will
% use it http://www.teos-10.org/software.htm#1. Otherwise it is calculated
% using the Saunders & Fofonoff method. Without a latitude it is calculated
% using standard density of seawater. 
%
% Inputs:
%    pressure - a vector of pressure values in dbar
%
%    latitude - Latitude at the location of the pressure measurement in
%        decimal degrees north. Default [], will calculate using density.
%
%    densityseawater - The density of sea water at the location of the
%        pressure measurement. Note: It is only used if TEOS-10 isn't installed
%        and a latitude is not provided. Default is 1026 kg/m^3.
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
% Last revision: 2016-12-08

%% Parse Inputs

p = inputParser;
addParameter(p, 'latitude', [], @isnumeric);
addParameter(p, 'densityseawater', 1026, @isnumeric);
parse(p, varargin{:})

% Assign each argument
latitude = p.Results.latitude;
densityseawater = p.Results.densityseawater;


%% Check if user has the TEOS-10 GSW toolbox installed
hasTEOS = exist('gsw_z_from_P') == 2;

%% Calculate depth
if hasTEOS && ~isempty(latitude)
    depth = -gsw_z_from_p(pressure, latitude);  
    
elseif ~hasTEOS && ~isempty(latitude)
    % Use Saunders and Fofonoff's method.
    x = (sin(latitude/57.29578)).^2;
    gr = 9.780318*(1.0 + (5.2788e-3 + 2.36e-5*x).*x) + 1.092e-6.*pressure;
    depth = (((-1.82e-15*pressure + 2.279e-10).*pressure - 2.2512e-5).*pressure + 9.72659).*pressure;
    depth = depth./gr;
    
else
    % If the TEOS-10 toolbox is not installed or a latitude is not given, calculated from density
    g = 9.80665;  % m/s^2
    depth = pressure*10000 ./ (densityseawater*g);
end

end