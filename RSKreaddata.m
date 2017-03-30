function RSK = RSKreaddata(RSK, t1, t2)

% RSKreaddata - Reads the data tables from an RBR RSK SQLite file.
%
% Syntax:  RSK = RSKreaddata(RSK, t1, t2)
% 
% Reads the actual data tables from the RSK file previously opened
% with RSKopen(). Will either read the entire data structre, or a
% specified subset. 
%
% Note: If the file type is 'skinny' the file will have to be opened with
% Ruskin before RSKtools can read the data because the data is stored in a
% raw bin file.
% 
% Inputs: 
%    RSK - Structure containing the logger metadata and thumbnails
%          returned by RSKopen. If provided as the only argument the
%          data for the entire file is read. Depending on the amount
%          of data in your dataset, and the amount of memory in your
%          computer, you can read bigger or smaller chunks before
%          Matlab will complain and run out of memory.
%     t1 - Optional start time for range of data to be read,
%          specified using the MATLAB datenum format.
%     t2 - Optional end time for range of data to be read,
%          specified using the MATLAB datenum format.
%
% Outputs:
%    RSK - Structure containing the logger metadata, along with the
%          added 'data' fields. Note that this replaces any
%          previous data that was read this way.
%
% Example: 
%    RSK = RSKopen('sample.rsk');  
%    RSK = RSKreaddata(RSK);
%
% See also: RSKopen, RSKreadevents, RSKreadburstdata
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-03-30

%% Check if file type is skinny
if strcmp(RSK.dbInfo(end).type, 'skinny')
    error('File must be opened in Ruskin before RSKtools can read the data.');
end

%% Load data
if nargin==1 % user wants to read ALL the data
    t1 = datenum2RSKtime(RSK.epochs.startTime);
    t2 = datenum2RSKtime(RSK.epochs.endTime);
else
    t1 = datenum2RSKtime(t1);
    t2 = datenum2RSKtime(t2);
end

% Select data schema
% Determine 'channelXX' column names
% Build SQL statement from column names
sql = ['select tstamp/1.0 as tstamp,* from data where tstamp/1.0 between ' num2str(t1) ' and ' num2str(t2) ' order by tstamp'];
results = mksqlite(sql);
if isempty(results)
    disp('No data found in that interval')
    return
end
results = rmfield(results,'tstamp_1'); % get rid of the corrupted one

%% RSK version >= 1.12.2 now has a datasetID column in the data table
% Look for the presence of that column and extract it from results
names = fieldnames(results);
fieldmatch = strcmpi(names, 'datasetid');
hasdatasetID = sum(fieldmatch);

if hasdatasetID
    try
        results = rmfield(results, names(fieldmatch == 1)); % get rid of the datasetID column
    catch
    end
end


%% Organise results
results = RSKarrangedata(results);

t=results.tstamp';
results.tstamp = RSKtime2datenum(t); % convert RSK millis time to datenum


%% Remove hidden channels from data
% channelStatus was instroduced in RSK V 1.8.9.
if ~strcmpi(RSK.dbInfo(end).type, 'EPdesktop')
    if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 8)) || ((vsnMajor == 1)&&(vsnMinor == 8) && (vsnPatch >= 9))
        isDerived = logical([RSK.instrumentChannels.channelStatus]);% hidden and derived channels have a non-zero channelStatus
    else
        results = mksqlite('select isDerived from channels');
        isDerived = logical([results.isDerived]); % some files may not have channelStatus
    end
    RSK.channels(isDerived) = [];
    results.values = results.values(:,isDerived);
end


%% Put data into data field of RSK structure.
RSK.data=results;

%% Calculate Salinity  
% RSK = RSKderivesalinity(RSK); 
% NOTE : We no longer automatically derive salinity when you read data from
% database. Use RSKderivesalinity(RSK) to calculate salinity.


end
