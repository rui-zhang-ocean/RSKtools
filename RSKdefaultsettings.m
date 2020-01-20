function rsksettings = RSKdefaultsettings
 
% RSKdefaultsettings - Set up RSKtools default parameters.
%
% Syntax: rsksettings = RSKdefaultsettings
%
% See also: RSKsettings
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2020-01-10

rsksettings.RSKtoolsVersion = '3.3.0';
rsksettings.seawaterLibrary = 'TEOS-10'; 
rsksettings.latitude = 45;
rsksettings.atmosphericPressure = 10.1325;
rsksettings.hydrostaticPressure = 0;
rsksettings.salinity = 35;
rsksettings.temperature = 15;
rsksettings.pressureThreshold = 3;
rsksettings.conductivityThreshold = 0.05;
rsksettings.loopThreshold = 0.25;
rsksettings.soundSpeedAlgorithm = 'UNESCO';
 
disp('Setting default values for all RSKtools parameters')
RSKsettings(rsksettings);

end
