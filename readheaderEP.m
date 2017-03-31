function RSK = readheaderEP(RSK)

% readheaderEP - read tables that are populated in an 'EasyParse' file.
%
% Syntax:  [RSK] = readheaderEP(RSK)
%
% readheaderEP is a RSKtools helper function that opens the populated
% tables of 'EasyParse' files.
% These tables are channels, epochs, schedules, deployments and instruments. If data is
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
% Last revision: 2017-03-31

%% Remove non marine channels
results = mksqlite('select isDerived from channels');
isDerived = logical([results.isDerived]); 

RSK.channels(isDerived) = [];  


%% Tables that could be populated in 'EasyParse'
tables = mksqlite('SELECT name FROM sqlite_master WHERE type="table"');

if any(strcmpi({tables.name}, 'geodata'))
    RSK = RSKreadgeodata(RSK);
end


end

