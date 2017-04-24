function RSK = RSKreadthumbnail(RSK)

% RSKreadthumbnail - Internal function to read thumbnail data from
%                    an opened RSK file.
%
% Syntax:  results = RSKreadthumbnail
% 
% Reads thumbnail data from an opened RSK SQLite file, called from
% within RSKopen.
%
% Inputs:
%    RSK - Structure containing the logger metadata and thumbnails
%          returned by RSKopen.
%
% Output:
%    RSK - Structure containing previously present logger metadata as well
%          as thumbnailData
%
% See also: RSKopen
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-03-14

sql = ['select tstamp/1.0 as tstamp,* from thumbnailData order by tstamp'];
results = mksqlite(sql);
if isempty(results)
    return
end
results = rmfield(results,'tstamp_1'); % get rid of the corrupted one

%% RSK version >= 1.12.2 now has a datasetID column in the data table
% Look for the presence of that column and extract it from results
if sum(strcmp('datasetID', fieldnames(results))) > 0
    datasetID = [results(:).datasetID]';
    results = rmfield(results, 'datasetID'); % get rid of the datasetID column
    hasdatasetID = 1;
else 
    hasdatasetID = 0;
end

results = RSKarrangedata(results);

if hasdatasetID
    results.datasetID = datasetID;
end

results.tstamp = RSKtime2datenum(results.tstamp'); % convert unix time to datenum

if ~strcmpi(RSK.dbInfo(end).type, 'EPdesktop')
    [~, isDerived] = removeNonMarinechannels(RSK);
    results.values = results.values(:,~isDerived);
end

RSK.thumbnailData = results;
end
