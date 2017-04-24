function RSK = readheaderEPdesktop(RSK)

% readheaderEPdesktop - read tables that are populated in an 'EPdesktop' file.
%
% Syntax:  [RSK] = readheaderEPdesktop(RSK)
%
% readheaderEPdesktop is a RSKtools helper function that opens the
% non-standard populated tables of 'EPdesktop' files. 
% This table is thumbnailData. If data is available it
% will open appSettings, parameters, parameterKeys and geodata. 
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
% Last revision: 2017-04-24


%% Tables that are definitely in 'EPdesktop'

RSK.thumbnailData = RSKreadthumbnail(RSK);


%% Load sampling details
if iscompatibleversion(RSK, 1, 13, 8)
    RSK = readsamplingdetails(RSK);
end


%% Tables that may or may not be in file
tables = mksqlite('SELECT name FROM sqlite_master WHERE type="table"');

% As of RSK v1.13.4 parameterKeys is a table
if any(strcmpi({tables.name}, 'parameterKeys'))
    RSK.parameterKeys = mksqlite('select * from parameterKeys');
end

if any(strcmpi({tables.name}, 'instrumentChannels'))
    RSK.instrumentChannels = mksqlite('select * from instrumentChannels');
end

if any(strcmpi({tables.name}, 'geodata'))
    RSK = RSKreadgeodata(RSK);
end

% Parameter table is empty if data is from Mobile Ruskin.
if ~strcmpi(RSK.dbInfo(1).type, 'EasyParse')
    if ~strcmpi(RSK.dbInfo(1).type, 'skinny')
        if any(strcmpi({tables.name}, 'parameters')) 
            RSK.parameters = mksqlite('select * from parameters');
        end
    end
end

if any(strcmpi({tables.name}, 'appSettings'))
    RSK.appSettings = mksqlite('select * from appSettings');  
end


end

