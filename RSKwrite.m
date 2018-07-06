function newfile = RSKwrite(RSK, varargin)

% RSKwrite - Write modified rsk structure into a new rsk file.
%
% Syntax: newfile = RSKwrite(RSKfile, [OPTIONS])
%
% RSKwrite outputs a new rsk file with updated data, profiles, channels and
% metadata information in current rsk structure. It is designed to store
% data after post-processing in RSKtools in rsk format which is also
% readable in Ruskin. The new rsk file will be in EPdesktop format.
%
% Inputs:
%    [Required] - RSK - rsk structure
%
%    [Optional] - outputdir - directory for output rsk file, default is
%                 current directory.
%
%               - suffix - suffix for output rsk file name, default is
%                 current time in format of YYYYMMDDTHHMM.
%
% Outputs:
%    newfile - file name of output rsk file
%
% Example:
%    RSK = RSKopen('fname');
%    RSK = RSKreadprofiles(RSK);
%    RSK = RSKaddmetadata(RSK,'profile',1:3,'latitude',[45,44,46],'longitude',[-25,-24,-23]});
%    outputdir = '/Users/Tom/Jerry';
%    newfile = RSKwrite(RSK,'outputdir',outputdir,'suffix','processed');
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-06-06


p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'outputdir', pwd, @ischar);
addParameter(p, 'suffix', '', @ischar);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
outputdir = p.Results.outputdir;
suffix = p.Results.suffix;


% Copy original rsk file and rename it
[inputdir,name,ext] = fileparts(RSK.toolSettings.filename);
if isempty(inputdir); inputdir = pwd; end
newfile = RSKclone(inputdir, outputdir, [name ext], suffix);

% Open the file
mksqlite('OPEN',[outputdir '/' newfile]);

% Change dbinfo type into EPdesktop
mksqlite('UPDATE dbinfo SET type = "EPdesktop"')

% Drop table data/downsampleXX/downsample_caches/breaksdata/downloads
if ~isempty(mksqlite('SELECT name FROM sqlite_master WHERE type="table" AND name="downsample_caches"'))
    tablename = mksqlite('SELECT tablename from downsample_caches');
    for i = 1:length(tablename)
        mksqlite(['DROP table if exists ' tablename(i).tablename]); 
    end
end
mksqlite('DROP table if exists data');
mksqlite('DROP table if exists downsample_caches');
mksqlite('DROP table if exists breaksdata');
mksqlite('DROP table if exists downloads');
mksqlite('DROP table if exists thumbnailData');

% Create table data
nchannel = size(RSK.data(1).values,2);
tempstr = cell(nchannel,1);
for i = 1:nchannel
    tempstr{i} = strcat(', channel', sprintf('%02d',i), ' DOUBLE');
end
mksqlite(['CREATE table data (tstamp BIGINT PRIMARY KEY ASC' tempstr{:} ')']);

% Convert profiles into time series, if rsk is profile structured
datanew.tstamp = cat(1,RSK.data(1:end).tstamp);
datanew.values = cat(1,RSK.data(1:end).values);

% Remove repeated values time stamp
[datanew.tstamp,idx,~] = unique(datanew.tstamp,'stable');
datanew.values = datanew.values(idx,:);

% Populate table data
fmt = strcat(repmat(',%f',[1,nchannel]));
mksqlite('begin');
for i = 1:length(datanew.tstamp)
    temptime = round(datenum2RSKtime(datanew.tstamp(i,1)));
    mksqlite(strrep(sprintf(['INSERT INTO data VALUES (%i' fmt ')'],temptime,datanew.values(i,:)),'NaN','null'));
end
mksqlite('commit');

% Populate table region/regionCast/regionProfile/regionGeoData/regionComment
mksqlite('begin');

if isfield(RSK,'region')
    
    mksqlite('DROP table if exists region');
    if isfield(RSK.region,'description');
        mksqlite('CREATE table region (datasetID INTEGER NOT NULL,regionID INTEGER PRIMARY KEY,type VARCHAR(50),tstamp1 LONG,tstamp2 LONG,label VARCHAR(512),`description` TEXT)');
        for i = 1:length(RSK.region) % Replace double quote in description field before inserting into DB!!!
            mksqlite(sprintf('INSERT INTO region VALUES (%i,%i,"%s",%i,%i,"%s","%s")',RSK.region(i).datasetID, RSK.region(i).regionID, RSK.region(i).type, RSK.region(i).tstamp1, RSK.region(i).tstamp2, RSK.region(i).label, RSK.region(i).description));
        end
    else
        mksqlite('CREATE table region (datasetID INTEGER NOT NULL,regionID INTEGER PRIMARY KEY,type VARCHAR(50),tstamp1 LONG,tstamp2 LONG,label VARCHAR(512))'); 
        for i = 1:length(RSK.region)
            mksqlite(sprintf('INSERT INTO region VALUES (%i,%i,"%s",%i,%i,"%s")',RSK.region(i).datasetID, RSK.region(i).regionID, RSK.region(i).type, RSK.region(i).tstamp1, RSK.region(i).tstamp2, RSK.region(i).label));
        end
    end
    
    mksqlite('DROP table if exists regionCast');
    if isfield(RSK,'regionCast');
        mksqlite('CREATE table regionCast (regionID INTEGER,regionProfileID INTEGER,type STRING,FOREIGN KEY(regionID) REFERENCES REGION(regionID) ON DELETE CASCADE )');
        for i = 1:length(RSK.regionCast)
            mksqlite(sprintf('INSERT INTO regionCast VALUES (%i,%i,"%s")',RSK.regionCast(i).regionID, RSK.regionCast(i).regionProfileID, RSK.regionCast(i).type));
        end    
    end
    
    mksqlite('DROP table if exists regionProfile');
    mksqlite('CREATE table regionProfile (regionID INTEGER,FOREIGN KEY(regionID) REFERENCES REGION(regionID) ON DELETE CASCADE )');
    profileidx = find(strcmp({RSK.region.type},'PROFILE'));
    for i = 1:length(profileidx)
        mksqlite(sprintf('INSERT INTO regionProfile VALUES (%i)',profileidx(i))); 
    end
    
    mksqlite('DROP table if exists regionGeoData');
    if isfield(RSK,'regionGeoData');
        mksqlite('CREATE TABLE regionGeoData (regionID INTEGER,latitude DOUBLE,longitude DOUBLE,FOREIGN KEY(regionID) REFERENCES REGION(regionID) ON DELETE CASCADE )');
        for i = 1:length(RSK.regionGeoData)
            mksqlite(sprintf('INSERT INTO regionGeoData VALUES (%i,%f,%f)',RSK.regionGeoData(i).regionID, RSK.regionGeoData(i).latitude, RSK.regionGeoData(i).longitude));
        end
    end

    mksqlite('DROP table if exists regionComment');
    if isfield(RSK,'regionComment');
       mksqlite('CREATE TABLE regionComment (regionID INTEGER,content VARCHAR(1024),FOREIGN KEY(regionID) REFERENCES REGION(regionID) ON DELETE CASCADE )');
       for i = 1:length(RSK.regionComment)
           mksqlite(sprintf('INSERT INTO regionComment VALUES (%i,"NULL")',RSK.regionComment(i).regionID));
       end
    end    
    
end
mksqlite('commit');

% Remove rows in events and errors table where data is removed
if ~isempty(mksqlite('SELECT name FROM sqlite_master WHERE type="table" AND name="events"'))
    mksqlite('DELETE from events WHERE tstamp NOT IN (SELECT tstamp FROM data)');
end
if ~isempty(mksqlite('SELECT name FROM sqlite_master WHERE type="table" AND name="errors"'))
    mksqlite('DELETE from errors WHERE tstamp NOT IN (SELECT tstamp FROM data)');
end

% Populate table channel and instrumentChannel
mksqlite('DROP table if exists channels');
mksqlite('CREATE TABLE channels (channelID INTEGER PRIMARY KEY,shortName TEXT NOT NULL,longName TEXT NOT NULL,units TEXT,isMeasured BOOLEAN,isDerived BOOLEAN)');

mksqlite('DROP table if exists instrumentChannels');
if isfield(RSK.deployments,'serialID')
    mksqlite('CREATE TABLE instrumentChannels (serialID INTEGER,channelID INTEGER,channelOrder INTEGER,channelStatus INTEGER,PRIMARY KEY (serialID, channelID, channelOrder))');
else
    mksqlite('CREATE TABLE instrumentChannels (instrumentID INTEGER,channelID INTEGER,channelOrder INTEGER,channelStatus INTEGER,PRIMARY KEY (instrumentID, channelID, channelOrder))')
end

mksqlite('begin');
for i = 1:length(RSK.channels)
    mksqlite(sprintf('INSERT INTO channels VALUES (%i,"%s","%s","%s",1,0)',i, RSK.channels(i).shortName, RSK.channels(i).longName, RSK.channels(i).units)); 
    if isfield(RSK.deployments,'serialID')
        mksqlite(sprintf('INSERT INTO instrumentChannels VALUES (%i,%i,%i,0)', RSK.deployments.serialID, i, i)); 
    else
        mksqlite(sprintf('INSERT INTO instrumentChannels VALUES (1,%i,%i,0)', i, i)); 
    end
end
mksqlite('commit');

% Delete table calibrations
if ~isempty(mksqlite('SELECT name FROM sqlite_master WHERE type="table" AND name="calibrations"'))
    mksqlite('DELETE from calibrations');
end

mksqlite('close')

fprintf('Wrote: %s/%s\n', outputdir, newfile);

end
