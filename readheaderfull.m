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
% Last revision: 2017-03-27

%% Set up version variables
[~, vsnMajor, vsnMinor, vsnPatch] = RSKver(RSK);

%% Tables that are definitely in 'full'

RSK.appSettings = mksqlite('select * from appSettings');

RSK.channels = mksqlite('select shortName,longName,units from channels');

RSK.epochs = mksqlite('select deploymentID,startTime/1.0 as startTime, endTime/1.0 as endTime from epochs');
RSK.epochs.startTime = RSKtime2datenum(RSK.epochs.startTime);
RSK.epochs.endTime = RSKtime2datenum(RSK.epochs.endTime);

RSK.schedules = mksqlite('select * from schedules');

RSK.ranging = mksqlite('select * from ranging');

RSK.deployments = mksqlite('select * from deployments');

RSK.instruments = mksqlite('select * from instruments');
RSK.instrumentChannels = mksqlite('select * from instrumentChannels');

RSK.parameters = mksqlite('select * from parameters');
% RSK = RSKreadcalibrations(RSK);
% NOTE : We no longer automatically read the calibrations table when
% opening a file with RSKopen. Use RSKreadcalibrations(RSK) to load the
% calibrations data.

%% Load sampling details
if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 13)) || ((vsnMajor == 1)&&(vsnMinor == 13)&&(vsnPatch >= 8))
    RSK = readsamplingdetails(RSK);
end


%% Load parameter keys
if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 13)) || ((vsnMajor == 1)&&(vsnMinor == 13)&&(vsnPatch >= 4))
    RSK.parameterKeys = mksqlite('select * from parameterKeys'); 
end


%% Remove non marine channels
% channelStatus was instroduced in RSK V 1.8.9.
if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 8)) || ((vsnMajor == 1)&&(vsnMinor == 8) && (vsnPatch >= 9))
    isDerived = logical([RSK.instrumentChannels.channelStatus]);% hidden and derived channels have a non-zero channelStatus
    RSK.instrumentChannels(isDerived) = [];
else
    results = mksqlite('select isDerived from channels');
    isDerived = logical([results.isDerived]); % some files may not have channelStatus
end
RSK.channels(isDerived) = [];  


%% Tables that could be populated in 'full'
tables = mksqlite('SELECT name FROM sqlite_master WHERE type="table"');

if any(strcmpi({tables.name}, 'geodata'))
    RSK = RSKreadgeodata(RSK);
end

if any(strcmpi({tables.name}, 'thumbnailData'))
    RSK = RSKreadthumbnail(RSK);
end

end

