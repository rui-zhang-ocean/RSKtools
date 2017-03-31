function RSK = readheaderlive(RSK)

% readheaderlive - read tables that are populated in an 'live' file.
%
% Syntax:  [RSK] = readheaderlive(RSK)
%
% readheaderlive is a RSKtools helper function that opens the non-standars
% populated tables of RSK 'live' files.
% These tables are appSettings, instrumentsChannels and parameters.
% If data is available it will open parameterKeys and thumbnailData.  
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
% Last revision: 2017-03-27

%% Set up version variables
[~, vsnMajor, vsnMinor, vsnPatch] = RSKver(RSK);


%% Tables that are definitely in 'live'
RSK.appSettings = mksqlite('select * from appSettings');

RSK.instrumentChannels = mksqlite('select * from instrumentChannels');

RSK.parameters = mksqlite('select * from parameters');


%% Load sampling details
if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 13)) || ((vsnMajor == 1)&&(vsnMinor == 13)&&(vsnPatch >= 8))
    RSK = readsamplingdetails(RSK);
end


%% Load calibration
%As of RSK v1.13.4 parameterKeys is a table
if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 13)) || ((vsnMajor == 1)&&(vsnMinor == 13)&&(vsnPatch >= 4))
    RSK.parameterKeys = mksqlite('select * from parameterKeys'); 
end


%% Remove non marine channels
results = mksqlite('select isDerived from channels');
% channelStatus was instroduced in RSK V 1.8.9.
if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 8)) || ((vsnMajor == 1)&&(vsnMinor == 8) && (vsnPatch >= 9))
   isDerived = logical([RSK.instrumentChannels.channelStatus]); % hidden and derived channels have a non-zero channelStatus
else
   isDerived = logical([results.isDerived]); % some files may not have channelStatus
end
RSK.channels(isDerived) = [];  
RSK.instrumentChannels(isDerived) = []; 


%% Tables that may or may not be in 'live'
tables = mksqlite('SELECT name FROM sqlite_master WHERE type="table"');

if any(strcmpi({tables.name}, 'geodata'))
    RSK = RSKreadgeodata(RSK);
end

if any(strcmpi({tables.name}, 'thumbnailData'))
    RSK = RSKreadthumbnail(RSK);
end


end
