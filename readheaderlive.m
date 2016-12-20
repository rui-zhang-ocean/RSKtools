function RSK = readheaderlive(RSK)

% readheaderlive - read tables that are populated in an 'live' file.
%
% Syntax:  [RSK] = readheaderlive(RSK)
%
% readheaderlive is a RSKtools helper function that opens the populated
% tables of RSK 'live' files.
% These tables are channels, datasets, datasetDeployments, epochs,
% schedules, deployments, instruments ,instrumentsChannels and parameters.
% If data is available it will open appSettings, parameterKeys and thumbnail.  
%
% Note: Only marine channels will be displayed.
%
% Inputs:
%    RSK - 'live' file opened using RSKopen.m
%
% Outputs:
%    RSK - Structure containing the logger metadata and thumbnails
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-12-20

%% Set up version variables
[~, vsnMajor, vsnMinor, vsnPatch] = RSKver(RSK);

%% Tables that are definitely in 'live'

RSK.channels = mksqlite('select shortName,longName,units from channels');

RSK.datasets = mksqlite('select * from datasets');
RSK.datasetDeployments = mksqlite('select * from datasetDeployments');

RSK.epochs = mksqlite('select deploymentID,startTime/1.0 as startTime, endTime/1.0 as endTime from epochs');
RSK.epochs.startTime = RSKtime2datenum(RSK.epochs.startTime);
RSK.epochs.endTime = RSKtime2datenum(RSK.epochs.endTime);

RSK.schedules = mksqlite('select * from schedules');

RSK.deployments = mksqlite('select * from deployments');

RSK.instruments = mksqlite('select * from instruments');
RSK.instrumentChannels = mksqlite('select * from instrumentChannels');

RSK.parameters = mksqlite('select * from parameters');

%% Load calibration
%As of RSK v1.13.4 parameterKeys is a table
if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 13)) || ((vsnMajor == 1)&&(vsnMinor == 13)&&(vsnPatch >= 4))
    RSK.parameterKeys = mksqlite('select * from parameterKeys'); 
end


%% Remove non marine channels

% channelStatus was instroduced in RSK V 1.8.9.
if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 8)) || ((vsnMajor == 1)&&(vsnMinor == 8) && (vsnPatch >= 9))
    isMeasured = ~[RSK.instrumentChannels.channelStatus];% hidden and derived channels have a non-zero channelStatus
else
    results = mksqlite('select isDerived from channels');
    isMeasured = ~[results.isDerived]; % some files may not have channelStatus
end
RSK.channels(~isMeasured) = [];  
RSK.instrumentChannels(~isMeasured) = []; 

%% Tables that may or may not be in 'live'
try
    RSK.appSettings = mksqlite('select * from appSettings');
catch
end

try
    RSK.thumbnailData = RSKreadthumbnail;
catch
end

end

