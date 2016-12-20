function RSK = readheaderEP(RSK)

% readheaderEP - read tables that are populated in an 'EasyParse' file.
%
% Syntax:  [RSK] = readheaderEP(RSK)
%
% readheaderEP is a RSKtools helper function that opens the populated
% tables of 'EasyParse' files. Only to be used by RSKopen.m.
% These tables are channels, epochs, schedules and deployments. If available
% there will also be geodata.
%
% Inputs:
%    RSK - 'EasyParse' file opened using RSKopen.m
%
% Outputs:
%    RSK - Structure containing the logger metadata and thumbnails
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-12-20

%% Tables that are definitely in 'EasyParse'
RSK.channels = mksqlite('select shortName,longName,units from channels');

RSK.epochs = mksqlite('select deploymentID,startTime/1.0 as startTime, endTime/1.0 as endTime from epochs');
RSK.epochs.startTime = RSKtime2datenum(RSK.epochs.startTime);
RSK.epochs.endTime = RSKtime2datenum(RSK.epochs.endTime);

RSK.schedules = mksqlite('select * from schedules');

RSK.deployments = mksqlite('select * from deployments');

%% Tables that may or may not be in 'EasyParse'
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

