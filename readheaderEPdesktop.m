function RSK = readheaderEPdesktop(RSK)

% readheaderEPdesktop - read tables that are populated in an 'EPdesktop' file.
%
% Syntax:  [RSK] = readheaderEPdesktop(RSK)
%
% readheaderEPdesktop is a RSKtools helper function that opens the populated
% tables of 'EPdesktop' files. 
% These tables are channels, epochs, schedules, deployments, instruments,
% instrumentsChannels and thumbnailData. If data is available it
% will open appSettings, datasets, datasetDeployments, parameters,
% parameterKeys and geodata. 
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


RSK.thumbnailData = RSKreadthumbnail;

%% Remove non marine channels

try
    isMeasured = ~[RSK.instrumentChannels.channelStatus];% hidden and derived channels have a non-zero channelStatus
catch
    results = mksqlite('select isDerived from channels');
    isMeasured = ~[results.isDerived]; % some files may not have channelStatus
end
RSK.channels(~isMeasured) = [];  
RSK.instrumentChannels(~isMeasured) = []; 


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

% Parameter table is empty if data is from Mobile Ruskin.
if ~strcmpi(RSK.dbInfo(1).type, 'EasyParse') && ~strcmpi(RSK.dbInfo(1).type, 'skinny') 
    RSK.parameters = mksqlite('select * from parameters');
end
if ~strcmpi(RSK.dbInfo(1).type, 'EasyParse')
    RSK.datasets = mksqlite('select * from datasets');
    RSK.datasetDeployments = mksqlite('select * from datasetDeployments');     
end

try
    RSK = RSKreadgeodata(RSK);
catch
end
end
