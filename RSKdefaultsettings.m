function rsksettings = RSKdefaultsettings
 
% RSKdefaultsettings - Set up RSKtools default parameters.
%
% Syntax: rsksettings = RSKsettings
%
% See also: RSKsettings
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2020-01-10

rsksettings.seawaterLibrary = 'TEOS-10'; 
rsksettings.latitude = 45;
rsksettings.atmosphericPressure = 10.1325;
rsksettings.hydrostaticPressure = 0;
rsksettings.salinity = 35;
rsksettings.temperature = 15;
rsksettings.eventBeginUpcast = 33;
rsksettings.eventBeginDowncast = 34;
rsksettings.eventEndcast = 35;
 
disp('Setting default values for all RSKtools settings')
RSKsettings(rsksettings);

end
