function rsksettings = RSKsettings(rsksettings)
 
% RSKsettings - Set up RSKtools parameters.
%
% Syntax:  rsksettings = RSKsettings([OPTIONS])
%
% Inputs: 
%    [Optional] - rsksettings - structure that contains specified RSKtools
%    parameters
%
% Outputs:
%    rsksettings - Structure containing updated RSKtools parameters
%
% Examples:
%    rsksettings = RSKsettings; % get current setting parameters
%    rsksettings.seawaterLibrary = 'seawater'; % revise seawaterLibrary
%    rsksettings = RSKsettings(rsksettings); % set parameters
%
% See also: RSKdefaultsettings
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2020-01-10


validSeawaterLibrary = {'TEOS-10','seawater'};
checkSeawaterLibrary = @(x) any(validatestring(x,validSeawaterLibrary));

if nargin == 0
    rsksettings = getappdata(0,'rsksettings'); % return current settings
    if isempty(rsksettings) 
        rsksettings = RSKdefaultsettings; % set default if empty
    end
else    
    p = inputParser;
    p.StructExpand = true;
    addParameter(p,'seawaterLibrary','TEOS-10',checkSeawaterLibrary);
    addParameter(p,'latitude',45,@isnumeric);
    addParameter(p,'atmosphericPressure',10.1325,@isnumeric);
    addParameter(p,'hydrostaticPressure',0,@isnumeric);
    addParameter(p,'salinity',35,@isnumeric);
    addParameter(p,'temperature',15,@isnumeric);
    addParameter(p,'eventBeginUpcast',33,@isnumeric);
    addParameter(p,'eventBeginDowncast',34,@isnumeric);
    addParameter(p,'eventEndcast',35,@isnumeric);
    parse(p, rsksettings)
    
    rsksettings.seawaterLibrary = p.Results.seawaterLibrary;
    rsksettings.latitude = p.Results.latitude;
    rsksettings.atmosphericPressure = p.Results.atmosphericPressure;
    rsksettings.hydrostaticPressure = p.Results.hydrostaticPressure;
    rsksettings.salinity = p.Results.salinity;
    rsksettings.temperature = p.Results.temperature;
    rsksettings.eventBeginUpcast = p.Results.eventBeginUpcast;
    rsksettings.eventBeginDowncast = p.Results.eventBeginDowncast;
    rsksettings.eventEndcast = p.Results.eventEndcast;
    
    setappdata(0,'rsksettings',rsksettings)  
end

end
