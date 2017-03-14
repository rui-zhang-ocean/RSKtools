function RSK = readheaderEP(RSK)

% readheaderEP - read tables that are populated in an 'EasyParse' file.
%
% Syntax:  [RSK] = readheaderEP(RSK)
%
% readheaderEP is a RSKtools helper function that opens the populated
% tables of 'EasyParse' files.
% These tables are channels, epochs, schedules and deployments. If data is
% available it will also open geodata and instruments.
%
% Inputs:
%    RSK - 'EasyParse' file opened using RSKopen.m
%
% Outputs:
%    RSK - Structure containing the logger metadata
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-03-14

%% Tables that are definitely in 'EasyParse'
RSK.channels = mksqlite('select shortName,longName,units from channels');

RSK.epochs = mksqlite('select deploymentID,startTime/1.0 as startTime, endTime/1.0 as endTime from epochs');
RSK.epochs.startTime = RSKtime2datenum(RSK.epochs.startTime);
RSK.epochs.endTime = RSKtime2datenum(RSK.epochs.endTime);

RSK.schedules = mksqlite('select * from schedules');

RSK.deployments = mksqlite('select * from deployments');


%% Remove non marine channels
results = mksqlite('select isDerived from channels');
isMeasured = ~[results.isDerived]; % some files may not have channelStatus

RSK.channels(~isMeasured) = [];  


%% Tables that could be populated in 'EasyParse'
tables = mksqlite('SELECT name FROM sqlite_master WHERE type="table"');
if any(strcmpi({tables.name}, 'instruments'))
    RSK.instruments = mksqlite('select * from instruments');
end

if any(strcmpi({tables.name}, 'geodata'))
    RSK = RSKreadgeodata(RSK);
end

end

