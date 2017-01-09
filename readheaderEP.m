function RSK = readheaderEP(RSK)

% readheaderEP - read tables that are populated in an 'EasyParse' file.
%
% Syntax:  [RSK] = readheaderEP(RSK)
%
% readheaderEP is a RSKtools helper function that opens the populated
% tables of 'EasyParse' files.
% These tables are channels, epochs, schedules and deployments. If data is
% available it will also open geodata.
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
% Last revision: 2016-12-20

%% Tables that are definitely in 'EasyParse'
RSK.channels = mksqlite('select shortName,longName,units from channels');

RSK.epochs = mksqlite('select deploymentID,startTime/1.0 as startTime, endTime/1.0 as endTime from epochs');
RSK.epochs.startTime = RSKtime2datenum(RSK.epochs.startTime);
RSK.epochs.endTime = RSKtime2datenum(RSK.epochs.endTime);

RSK.schedules = mksqlite('select * from schedules');

RSK.deployments = mksqlite('select * from deployments');

%% Tables that could be populated in 'EasyParse'
try
    RSK = RSKreadgeodata(RSK);
catch 
end
end

