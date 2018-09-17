function newfile = RSKwrite(RSK, varargin)

% RSKwrite - Write current rsk structure into a new rsk file.
%
% Syntax: newfile = RSKwrite(RSKfile, [OPTIONS])
%
% RSKwrite outputs a new rsk file with updated data, profiles, channels and
% metadata information in current rsk structure. It is designed to store
% data in rsk format after post-processing in RSKtools. The new rsk file is
% in EPdesktop format and readable in Ruskin. 
%
% Notes: This function is not thread safe.
%
% Inputs:
%    [Required] - RSK - rsk structure
%
%    [Optional] - outputdir - directory for output rsk file, default is
%                 current directory.
%
%               - suffix - string to append to output rsk file name, 
%                 default is current time in format of YYYYMMDDTHHMM.
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
% Last revision: 2018-08-30


p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'outputdir', pwd, @ischar);
addParameter(p, 'suffix', '', @ischar);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
outputdir = p.Results.outputdir;
suffix = p.Results.suffix;

newfile = setupOutputFilename(RSK,suffix);
data = convertProfilesIntoTimeseries(RSK);
[data, nchannel] = removeRepeatedTimestamp(data);

mksqlite('OPEN',[outputdir '/' newfile]);
createSchema(nchannel);
writeData(RSK, data, newfile);
mksqlite('CLOSE')

fprintf('Wrote: %s/%s\n', outputdir, newfile);


%% Nested functions
function newfile = setupOutputFilename(RSK,suffix)
    [~,name,~] = fileparts(RSK.toolSettings.filename);
    
    if isempty(suffix); 
        suffix = datestr(now,'yyyymmddTHHMM'); 
    end
    
    newfile = [name '_' suffix '.rsk'];
end

function data = convertProfilesIntoTimeseries(RSK)   
    data.tstamp = cat(1,RSK.data(:).tstamp);
    data.values = cat(1,RSK.data(:).values);
end

function [data, nchannel] = removeRepeatedTimestamp(data)
    [data.tstamp,idx,~] = unique(data.tstamp,'stable');
    data.values = data.values(idx,:);
    nchannel = size(data.values,2);
end

function createSchema(nchannel)
    mksqlite('CREATE TABLE IF NOT EXISTS dbInfo (version VARCHAR(50) PRIMARY KEY, type VARCHAR(50))')
    mksqlite('CREATE TABLE IF NOT EXISTS instruments (serialID INTEGER PRIMARY KEY, model TEXT NOT NULL)');
    mksqlite('CREATE TABLE IF NOT EXISTS channels (channelID INTEGER PRIMARY KEY,shortName TEXT NOT NULL,longName TEXT NOT NULL,units TEXT,isMeasured BOOLEAN,isDerived BOOLEAN)');
    mksqlite('CREATE TABLE IF NOT EXISTS deployments (deploymentID INTEGER PRIMARY KEY, serialID INTEGER, comment TEXT, loggerStatus TEXT, firmwareVersion TEXT, loggerTimeDrift long, timeOfDownload long, name TEXT, sampleSize INTEGER, hashtag INTEGER)');
    mksqlite('CREATE TABLE IF NOT EXISTS schedules (scheduleID INTEGER PRIMARY KEY, deploymentID INTEGER NOT NULL, samplingPeriod long, repetitionPeriod long, samplingCount INTEGER, mode TEXT, altitude DOUBLE, gate VARCHAR(512))');
    mksqlite('CREATE TABLE IF NOT EXISTS epochs (deploymentID INTEGER PRIMARY KEY, startTime LONG, endTime LONG)');
    mksqlite('CREATE TABLE IF NOT EXISTS events (deploymentID INTEGER NOT NULL, tstamp long NOT NULL, type INTEGER NOT NULL, sampleIndex INTEGER NOT NULL, channelIndex INTEGER)');
    mksqlite('CREATE TABLE IF NOT EXISTS errors (deploymentID INTEGER NOT NULL,tstamp long NOT NULL,type INTEGER NOT NULL,sampleIndex INTEGER NOT NULL,channelOrder INTEGER NOT NULL)');
    mksqlite('CREATE TABLE IF NOT EXISTS region (datasetID INTEGER NOT NULL,regionID INTEGER PRIMARY KEY,type VARCHAR(50),tstamp1 LONG,tstamp2 LONG,label VARCHAR(512),`description` TEXT)');
    mksqlite('CREATE TABLE IF NOT EXISTS regionCast (regionID INTEGER,regionProfileID INTEGER,type STRING,FOREIGN KEY(regionID) REFERENCES REGION(regionID) ON DELETE CASCADE )');
    mksqlite('CREATE TABLE IF NOT EXISTS regionProfile (regionID INTEGER,FOREIGN KEY(regionID) REFERENCES REGION(regionID) ON DELETE CASCADE )');
    mksqlite('CREATE TABLE IF NOT EXISTS regionGeoData (regionID INTEGER,latitude DOUBLE,longitude DOUBLE,FOREIGN KEY(regionID) REFERENCES REGION(regionID) ON DELETE CASCADE )');
    mksqlite('CREATE TABLE IF NOT EXISTS regionComment (regionID INTEGER,content VARCHAR(1024),FOREIGN KEY(regionID) REFERENCES REGION(regionID) ON DELETE CASCADE )');
    mksqlite('CREATE TABLE IF NOT EXISTS downloads (deploymentID INTEGER NOT NULL, part INTEGER NOT NULL, offset INTEGER NOT NULL, data BLOB, PRIMARY KEY (deploymentID, part))');
    createTabledata(nchannel);
end

function createTabledata(nchannel)
    tempstr = cell(nchannel,1);
    
    for n = 1:nchannel; 
        tempstr{n} = [', channel', sprintf('%02d',n), ' DOUBLE'];
    end
    
    mksqlite(['CREATE TABLE IF NOT EXISTS data (tstamp BIGINT PRIMARY KEY ASC' tempstr{:} ')']);
end

function writeData(RSK,data,newfile)       
    originalCharacterEncoding = slCharacterEncoding;
    slCharacterEncoding('UTF-8'); 
    
    insertDbInfo(RSK)
    insertInstruments(RSK)
    insertDeployments(RSK,data,newfile)
    insertSchedules(RSK)
    insertEpochs(RSK,data)
    insertChannels(RSK)
    insertData(data)
    insertRegionTables(RSK)  
    
    slCharacterEncoding(originalCharacterEncoding)
end

function insertDbInfo(RSK)
    formatAndTransact('INSERT INTO dbInfo VALUES','("%s","EPdesktop")',{RSK.dbInfo.version});
end

function insertInstruments(RSK)
    formatAndTransact('INSERT INTO instruments VALUES','(%i,"%s")',{RSK.instruments.serialID, RSK.instruments.model});
end

function insertDeployments(RSK,data,newfile)
    formatAndTransact('INSERT INTO deployments (deploymentID,serialID,firmwareVersion,timeOfDownload,name,sampleSize) VALUES','(%i,%i,"%s",%f,"%s",%i)',{RSK.deployments.deploymentID, RSK.instruments.serialID, readfirmwarever(RSK), RSK.deployments.timeOfDownload, newfile, length(data.values)});
end

function insertSchedules(RSK)
    formatAndTransact('INSERT INTO schedules (scheduleID,deploymentID,samplingPeriod,mode,gate) VALUES','(%i,%i,%i,"%s","%s")',{RSK.schedules.scheduleID, RSK.deployments.deploymentID, readsamplingperiod(RSK), RSK.schedules.mode, RSK.schedules.gate});
end

function insertEpochs(RSK,data) 
    formatAndTransact('INSERT INTO epochs VALUES','(%i,%f,%f)',num2cell([RSK.epochs.deploymentID, min([round(datenum2rsktime(data.tstamp(1))),[RSK.region.tstamp1]]), max([round(datenum2rsktime(data.tstamp(end))),[RSK.region.tstamp2]])]));
end

function insertChannels(RSK)
    formatAndTransact('INSERT INTO channels VALUES','(%i,"%s","%s","%s",1,0)',[num2cell((1:length(RSK.channels))); struct2cell(RSK.channels)])       
end

function insertData(data)
    N = 5000;
    batch = 1:ceil(length(data.tstamp)/N);
    for k = batch
        ind = 1+N*(k-1) : min(N*k, length(data.tstamp));      
        formatAndTransact('INSERT INTO data VALUES',strcat('(%i',repmat(', %f',1,size(data.values(ind,:),2)), ')'), num2cell([round(datenum2rsktime(data.tstamp(ind,1))), data.values(ind,:)])');
    end           
end

function insertRegionTables(RSK)
    if isfield(RSK,'region')   
        insertRegion(RSK)
        insertRegionProfile(RSK)
        
        if isfield(RSK,'regionCast'); 
            insertRegionCast(RSK); 
        end
        
        if isfield(RSK,'regionGeoData'); 
            insertRegionGeoData(RSK); 
        end
        
        if isfield(RSK,'regionComment'); 
            insertRegionComment(RSK); 
        end       
    end  
end

function insertRegion(RSK)
    if isfield(RSK.region,'description');
        formatAndTransact('INSERT INTO region (datasetID,regionID,type,tstamp1,tstamp2,label,description) VALUES','(%i,%i,"%s",%i,%i,"%s","%s")',struct2cell(RSK.region));       
    else
        formatAndTransact('INSERT INTO region (datasetID,regionID,type,tstamp1,tstamp2,label) VALUES','(%i,%i,"%s",%i,%i,"%s")',struct2cell(RSK.region));       
    end
end

function insertRegionCast(RSK)
    formatAndTransact('INSERT INTO regionCast VALUES','(%i,%i,"%s")',struct2cell(RSK.regionCast));
end

function insertRegionProfile(RSK)
    formatAndTransact('INSERT INTO regionProfile VALUES','(%i)',num2cell(find(strcmp({RSK.region.type},'PROFILE'))));     
end

function insertRegionGeoData(RSK)
    formatAndTransact('INSERT INTO regionGeoData VALUES','(%i,%f,%f)',struct2cell(RSK.regionGeoData));
end  

function insertRegionComment(RSK)
    formatAndTransact('INSERT INTO regionComment VALUES','(%i,"NULL")',num2cell([RSK.regionComment.regionID]));   
end 

function sql = buildSQLstring(values, sql_fmt)
    temp1 = reshape(values, numel(values), 1);
    temp2 = sprintf([sql_fmt ',\n'],temp1{:});
    sql = temp2(1:length(temp2)-2);
end

function doTransaction(SQL)
    mksqlite('begin')
    mksqlite(SQL)
    mksqlite('commit')
end

function formatAndTransact(insertString, sql_fmt, values)
    sql = buildSQLstring(values, sql_fmt);

    if strncmp(insertString,'INSERT INTO data',16)
        sql = strrep(sql, 'NaN', 'null');    
    end

    doTransaction([insertString sql]);
end

end