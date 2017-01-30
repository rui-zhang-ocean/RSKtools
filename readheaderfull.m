function RSK = readheaderfull(RSK)

% readheaderfull - read tables that are populated in an 'full' file.
%
% Syntax:  [RSK] = readheaderfull(RSK)
%
% readheaderfull is a RSKtools helper function that opens the populated
% tables of RSK 'full' files. Only to be used by RSKopen.m
% These tables are appSettings, channels, epochs, schedules, deployments,
% instruments, instrumentsChannels, ranging, calibrations and parameters. If data is
% available it will open datasets, datasetDeployments, coefficients,
% parameterKeys, geodata and thumbnail.
%
% Note: Only marine channels will be displayed.
%
% Inputs:
%    RSK - 'full' file opened using RSKopen.m
%
% Outputs:
%    RSK - Structure containing the logger metadata and thumbnails
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-01-25

%% Set up version variables
[~, vsnMajor, vsnMinor, vsnPatch] = RSKver(RSK);

%% Tables that are definitely in 'full'

RSK.appSettings = mksqlite('select * from appSettings');

RSK.channels = mksqlite('select shortName,longName,units from channels');

RSK.datasets = mksqlite('select * from datasets');
RSK.datasetDeployments = mksqlite('select * from datasetDeployments');


RSK.epochs = mksqlite('select deploymentID,startTime/1.0 as startTime, endTime/1.0 as endTime from epochs');
RSK.epochs.startTime = RSKtime2datenum(RSK.epochs.startTime);
RSK.epochs.endTime = RSKtime2datenum(RSK.epochs.endTime);

RSK.schedules = mksqlite('select * from schedules');

RSK.ranging = mksqlite('select * from ranging');

RSK.deployments = mksqlite('select * from deployments');

RSK.instruments = mksqlite('select * from instruments');
RSK.instrumentChannels = mksqlite('select * from instrumentChannels');

%% Load calibration
%As of RSK v1.13.4 coefficients is it's own table. We add it back into calibration to be consistent with previous versions.
if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 13)) || ((vsnMajor == 1)&&(vsnMinor == 13)&&(vsnPatch >= 4))
    RSK.parameters = mksqlite('select * from parameters');
    RSK.parameterKeys = mksqlite('select * from parameterKeys'); 
    RSK.calibrations = mksqlite('select * from calibrations');
    RSK.coefficients = mksqlite('select * from coefficients');
    RSK = coef2cal(RSK);
else
    RSK.calibrations = mksqlite('select * from calibrations');
    RSK.parameters = mksqlite('select * from parameters');
end


%% Remove non marine channels
results = mksqlite('select isDerived from channels');
% channelStatus was instroduced in RSK V 1.8.9.
if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 8)) || ((vsnMajor == 1)&&(vsnMinor == 8) && (vsnPatch >= 9))
    isMeasured = (~[RSK.instrumentChannels.channelStatus] & ~[results.isDerived]);% hidden and derived channels have a non-zero channelStatus
else
    isMeasured = ~[results.isDerived]; % some files may not have channelStatus
end
RSK.channels(~isMeasured) = [];  
RSK.instrumentChannels(~isMeasured) = []; 

%% Tables that could be populated in 'full'

try
    RSK = RSKreadgeodata(RSK);
catch 
end

try
    RSK.thumbnailData = RSKreadthumbnail;
catch
end

if isempty(RSK.datasets) && isempty(RSK.datasetDeployments)
    RSK = rmfield(RSK, 'datasets');
    RSK = rmfield(RSK, 'datasetDeployments');
end

end

