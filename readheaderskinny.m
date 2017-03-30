function RSK = readheaderskinny(RSK)

% readheaderskinny - read tables that are populated in an 'skinny' file.
%
% Syntax:  [RSK] = readheaderskinny(RSK)
%
% readheaderskinny is a RSKtools helper function that opens the populated
% tables of 'skinny' files. Only to be used by RSKopen.m.
% These tables are channels, epochs, schedules, deployments and instruments. If data is
% available it will also open geodata.
%
% Note: The data is stored in raw bin file, this file type must be opened in
%     Ruskin in order to read the data.
%
% Inputs:
%    RSK - 'skinny' file opened using RSKopen.m
%
% Outputs:
%    RSK - Structure containing the logger metadata and thumbnails
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-03-29

%% Tables that are definitely in 'skinny'
RSK.channels = mksqlite('select shortName,longName,units from channels');

RSK.epochs = mksqlite('select deploymentID,startTime/1.0 as startTime, endTime/1.0 as endTime from epochs');
RSK.epochs.startTime = RSKtime2datenum(RSK.epochs.startTime);
RSK.epochs.endTime = RSKtime2datenum(RSK.epochs.endTime);

RSK.schedules = mksqlite('select * from schedules');

RSK.deployments = mksqlite('select * from deployments');

RSK.instruments = mksqlite('select * from instruments');


%% Tables that may or may not be in 'skinny'
tables = mksqlite('SELECT name FROM sqlite_master WHERE type="table"');

if any(strcmpi({tables.name}, 'geodata'))
    RSK = RSKreadgeodata(RSK);
end


end