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
% Last revision: 2017-03-31

%% Set up version variables
[~, vsnMajor, vsnMinor, vsnPatch] = RSKver(RSK);

RSK.thumbnailData = RSKreadthumbnail;


%% Load sampling details
if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 13)) || ((vsnMajor == 1)&&(vsnMinor == 13)&&(vsnPatch >= 8))
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

