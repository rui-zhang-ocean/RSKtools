function RSK = readheaderfull(RSK)

%READHEADERFULL - Read tables that are populated in a 'full' file.
%
% Syntax:  [RSK] = READHEADERFULLRSK)
%
% Opens the non-standard tables populated in RSK 'full' files. Only to be
% used by RSKopen.m. These tables are appSettings, instrumentsChannels,
% ranging, and parameters. If data is available it will open the parameterKeys, geodata
% and thumbnailData tables. 
%
% Note: Only marine channels will be displayed.
%
% Inputs:
%    RSK - 'full' file opened using RSKopen.m
%
% Outputs:
%    RSK - Structure containing logger metadata and thumbnails
%
% See also: RSKopen
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-21

%% Tables that are definitely in 'full'
RSK.appSettings = mksqlite('select * from appSettings');

RSK.ranging = mksqlite('select * from ranging');

% NOTE : We no longer automatically read the calibrations table when
% opening a file with RSKopen. Use RSKreadcalibrations(RSK) to load the
% calibrations data.

RSK = readparameters(RSK);

if iscompatibleversion(RSK, 1, 13, 8)
    RSK = readsamplingdetails(RSK);
end

[RSK, ~] = removenonmarinechannels(RSK);



%% Tables that could be populated in 'full'
tables = mksqlite('SELECT name FROM sqlite_master WHERE type="table"');

if any(strcmpi({tables.name}, 'geodata'))
    RSK = RSKreadgeodata(RSK);
end

if any(strcmpi({tables.name}, 'thumbnailData'))
    RSK = RSKreadthumbnail(RSK);
end

end

