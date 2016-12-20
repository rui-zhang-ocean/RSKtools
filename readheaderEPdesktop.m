function RSK = readheaderEPdesktop(RSK)

% readheaderEPdesktop - read tables that are populated in an 'EPdesktop' file.
%
% Syntax:  [RSK] = readheaderEPdesktop(RSK)
%
% readheaderEPdesktop is a RSKtools helper function that opens the populated
% tables of 'EPdesktop' files. Only to be used by RSKopen.m
% These tables are channels, epochs, schedules, deployments, instruments,
% instrumentsChannels, parameters and thumbnail. If available it will open
% appSettings, datasets, datasetDeployments, parameterKeys and geodata. 
%
% Inputs:
%    RSK - 'EPdesktop' file opened using RSKopen.m
%
% Outputs:
%    RSK - Structure containing the logger metadata and thumbnail
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-12-20

%% Set up version variables
[~, vsnMajor, vsnMinor, vsnPatch] = RSKver(RSK);

%% Tables that are definitely in 'EPdesktop'

RSK.channels = mksqlite('select shortName,longName,units from channels');

RSK.epochs = mksqlite('select deploymentID,startTime/1.0 as startTime, endTime/1.0 as endTime from epochs');
RSK.epochs.startTime = RSKtime2datenum(RSK.epochs.startTime);
RSK.epochs.endTime = RSKtime2datenum(RSK.epochs.endTime);

RSK.schedules = mksqlite('select * from schedules');

RSK.deployments = mksqlite('select * from deployments');

RSK.instruments = mksqlite('select * from instruments');
RSK.instrumentChannels = mksqlite('select * from instrumentChannels');

RSK.parameters = mksqlite('select * from parameters');

RSK.thumbnailData = RSKreadthumbnail;


%% Load calibration
%As of RSK v1.13.4 parameterKeys is a table
if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 13)) || ((vsnMajor == 1)&&(vsnMinor == 13)&&(vsnPatch >= 4))
    try
        RSK.parameterKeys = mksqlite('select * from parameterKeys');
    catch
    end
end

%% Tables that may or may not be in 'EPdesktop'
try
    RSK.appSettings = mksqlite('select * from appSettings');
catch
end

try
    RSK.datasets = mksqlite('select * from datasets');
    RSK.datasetDeployments = mksqlite('select * from datasetDeployments');
catch
end

try
    UTCdelta = mksqlite('select UTCdelta/1.0 as UTCdelta from epochs');
    RSK.epochs.UTCdelta = UTCdelta.UTCdelta;
    RSK.geodata = mksqlite('select tstamp/1.0 as tstamp, latitude, longitude, accuracy, accuracyType from geodata');
    for ndx = 1:length(RSK.geodata)
        RSK.geodata(ndx).tstamp = RSKtime2datenum(RSK.geodata(ndx).tstamp + RSK.epochs.UTCdelta);
    end
catch 
end
end

