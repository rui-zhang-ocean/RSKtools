function RSK = readheaderskinny(RSK)

% readheaderskinny - read tables that are populated in an 'skinny' file.
%
% Syntax:  [RSK] = readheaderskinny(RSK)
%
% readheaderskinny is a RSKtools helper function that opens the populated
% tables of 'skinny' files. Only to be used by RSKopen.m.
% These tables are channels, epochs, schedules and deployments. If data is
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
% Last revision: 2016-12-20

%% Tables that are definitely in 'skinny'
RSK.channels = mksqlite('select shortName,longName,units from channels');

RSK.epochs = mksqlite('select deploymentID,startTime/1.0 as startTime, endTime/1.0 as endTime from epochs');
RSK.epochs.startTime = RSKtime2datenum(RSK.epochs.startTime);
RSK.epochs.endTime = RSKtime2datenum(RSK.epochs.endTime);

RSK.schedules = mksqlite('select * from schedules');

RSK.deployments = mksqlite('select * from deployments');

%% Tables that may or may not be in 'skinny'
try
    UTCdelta = mksqlite('select UTCdelta/1.0 as UTCdelta from epochs');
    RSK.epochs.UTCdelta = UTCdelta.UTCdelta;
    RSK.geodata = mksqlite('select tstamp/1.0 as tstamp, latitude, longitude, accuracy, accuracyType from geodata');
    if isempty(RSK.geodata)
        RSK = rmfield(RSK, 'geodata');
    else
        for ndx = 1:length(RSK.geodata)
            RSK.geodata(ndx).tstamp = RSKtime2datenum(RSK.geodata(ndx).tstamp + RSK.epochs.UTCdelta);
        end
    end
catch 
end

end