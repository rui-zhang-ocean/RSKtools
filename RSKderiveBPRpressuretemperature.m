function [RSK] = RSKderiveBPRpressuretemperature(RSK)

% RSKderivepressuretemperature
%
% Syntax:  [RSK] = RSKderiveBPRpressuretemperature(RSK)
% 
% Derives BPR pressure and temperature from period data.
%
% Inputs: 
%    RSK - Structure containing the logger metadata and data
%
% Outputs:
%    RSK - Structure containing the derived BPR pressure and temperature.
%
% See also: RSKderiveseapressure, RSKderivedepth.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-11-13

p = inputParser;
addRequired(p, 'RSK', @isstruct);
parse(p, RSK)

RSK = p.Results.RSK;

if ~isstruct(RSK.calibrations)
    error('RSKderiveBPRpressuretemperature requires calibrations field. Use RSKreadcalibrations...')
end
    
if ~strcmp(RSK.dbInfo(end).type, 'full')
    error('Only files of type "full" needs derivation for BPR pressure and temperature');
end

% Find pressure and temperature period data column
TempPeriCol = strcmp({RSK.channels.shortName},'peri01') == 1;
PresPeriCol = strcmp({RSK.channels.shortName},'peri00') == 1;

% Get coefficients
PresCaliCol = find(strcmp({RSK.calibrations.equation},'deri_bprpres') == 1);
TempCaliCol = find(strcmp({RSK.calibrations.equation},'deri_bprtemp') == 1);

u0 = RSK.calibrations(TempCaliCol).x0;
y1 = RSK.calibrations(TempCaliCol).x1;
y2 = RSK.calibrations(TempCaliCol).x2;
y3 = RSK.calibrations(TempCaliCol).x3;
c1 = RSK.calibrations(PresCaliCol).x1;
c2 = RSK.calibrations(PresCaliCol).x2;
c3 = RSK.calibrations(PresCaliCol).x3;
d1 = RSK.calibrations(PresCaliCol).x4;
d2 = RSK.calibrations(PresCaliCol).x5;
t1 = RSK.calibrations(PresCaliCol).x6;
t2 = RSK.calibrations(PresCaliCol).x7;
t3 = RSK.calibrations(PresCaliCol).x8;
t4 = RSK.calibrations(PresCaliCol).x9;
t5 = RSK.calibrations(PresCaliCol).x10;

RSK = addchannelmetadata(RSK, 'BPR pressure', 'dbar');
BPRPrescol = getchannelindex(RSK, 'BPR pressure');

RSK = addchannelmetadata(RSK, 'BPR temperature', '°C');
BPRTempcol = getchannelindex(RSK, 'BPR temperature');

castidx = getdataindex(RSK);
for ndx = castidx
    temperature_period = RSK.data(ndx).values(:,TempPeriCol);
    pressure_period = RSK.data(ndx).values(:,PresPeriCol);
    [temperature, pressure] = BPRderive(temperature_period, pressure_period, u0, y1, y2, y3, c1, c2, c3, d1, d2, t1, t2, t3, t4, t5);
    RSK.data(ndx).values(:,BPRPrescol) = pressure;
    RSK.data(ndx).values(:,BPRTempcol) = temperature;
end

logentry = ('BPR temperature and pressure were derived from period data.');
RSK = RSKappendtolog(RSK, logentry);

    %% Nested Functions
    function [temperature, pressure] = BPRderive(temperature_period, pressure_period, u0, y1, y2, y3, c1, c2, c3, d1, d2, t1, t2, t3, t4, t5)
    % Equations for deriving BPR temperature and pressure, period unit convert from picoseconds to microseconds (/1e6)

    U = (temperature_period/(1e6)) - u0;
    temperature = y1 .* U + y2 .* U .*U + y3 .* U .* U .* U;

    C = c1 + c2 .* U + c3 .* U .* U;
    D = d1 + d2 .* U;
    T0 = t1 + t2 .* U + t3 .* U .* U + t4 .* U .* U .* U + t5 .* U .* U .* U .* U;
    Tsquare = (pressure_period/(1e6)) .* (pressure_period/(1e6));
    Pres = C .* (1 - ((T0 .* T0) ./ (Tsquare))) .* (1 - D .* (1 - ((T0 .* T0) ./ (Tsquare))));
    pressure = Pres* 0.689475; % convert from PSI to dBar
    
    end

end
