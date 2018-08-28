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
% Last revision: 2018-08-28


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
insertSchema(RSK, data, newfile);
mksqlite('VACUUM')
mksqlite('CLOSE')

fprintf('Wrote: %s/%s\n', outputdir, newfile);


%% Nested function
    function newfile = setupOutputFilename(RSK,suffix)
        [~,name,~] = fileparts(RSK.toolSettings.filename);
        if isempty(suffix); suffix = datestr(now,'yyyymmddTHHMM'); end
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
        mksqlite('CREATE TABLE dbInfo (version VARCHAR(50) PRIMARY KEY, type VARCHAR(50))')
        mksqlite('CREATE TABLE instruments (serialID INTEGER PRIMARY KEY, model TEXT NOT NULL)');
        mksqlite('CREATE TABLE channels (channelID INTEGER PRIMARY KEY,shortName TEXT NOT NULL,longName TEXT NOT NULL,units TEXT,isMeasured BOOLEAN,isDerived BOOLEAN)');
        mksqlite('CREATE TABLE deployments (deploymentID INTEGER PRIMARY KEY, serialID INTEGER, comment TEXT, loggerStatus TEXT, firmwareVersion TEXT, loggerTimeDrift long, timeOfDownload long, name TEXT, sampleSize INTEGER, hashtag INTEGER)');
        mksqlite('CREATE TABLE schedules (scheduleID INTEGER PRIMARY KEY, deploymentID INTEGER NOT NULL, samplingPeriod long, repetitionPeriod long, samplingCount INTEGER, mode TEXT, altitude DOUBLE, gate VARCHAR(512))');
        mksqlite('CREATE TABLE epochs (deploymentID INTEGER PRIMARY KEY, startTime LONG, endTime LONG)');
        mksqlite('CREATE TABLE events (deploymentID INTEGER NOT NULL, tstamp long NOT NULL, type INTEGER NOT NULL, sampleIndex INTEGER NOT NULL, channelIndex INTEGER)');
        mksqlite('CREATE TABLE errors (deploymentID INTEGER NOT NULL,tstamp long NOT NULL,type INTEGER NOT NULL,sampleIndex INTEGER NOT NULL,channelOrder INTEGER NOT NULL)');
        mksqlite('CREATE TABLE region (datasetID INTEGER NOT NULL,regionID INTEGER PRIMARY KEY,type VARCHAR(50),tstamp1 LONG,tstamp2 LONG,label VARCHAR(512),`description` TEXT)');
        mksqlite('CREATE TABLE regionCast (regionID INTEGER,regionProfileID INTEGER,type STRING,FOREIGN KEY(regionID) REFERENCES REGION(regionID) ON DELETE CASCADE )');
        mksqlite('CREATE TABLE regionProfile (regionID INTEGER,FOREIGN KEY(regionID) REFERENCES REGION(regionID) ON DELETE CASCADE )');
        mksqlite('CREATE TABLE regionGeoData (regionID INTEGER,latitude DOUBLE,longitude DOUBLE,FOREIGN KEY(regionID) REFERENCES REGION(regionID) ON DELETE CASCADE )');
        mksqlite('CREATE TABLE regionComment (regionID INTEGER,content VARCHAR(1024),FOREIGN KEY(regionID) REFERENCES REGION(regionID) ON DELETE CASCADE )');
        mksqlite('CREATE TABLE downloads (deploymentID INTEGER NOT NULL, part INTEGER NOT NULL, offset INTEGER NOT NULL, data BLOB, PRIMARY KEY (deploymentID, part))');
        createTabledata(nchannel);
        
        function createTabledata(nchannel)
            tempstr = cell(nchannel,1);
            for n = 1:nchannel; tempstr{n} = [', channel', sprintf('%02d',n), ' DOUBLE']; end
            mksqlite(['CREATE TABLE data (tstamp BIGINT PRIMARY KEY ASC' tempstr{:} ')']);
        end
    end

    function insertSchema(RSK,data,newfile) 
        
        firmwareVersion = RSKfirmwarever(RSK);
        samplingPeriod = RSKsamplingperiod(RSK);
        sampleSize = length(data.values);
        
        mksqlite('begin')
        mksqlite(sprintf('INSERT INTO dbInfo VALUES ("%s","EPdesktop")', RSK.dbInfo.version));
        mksqlite(sprintf('INSERT INTO instruments VALUES (%i,"%s")', RSK.instruments.serialID, RSK.instruments.model));
        mksqlite(sprintf('INSERT INTO deployments (deploymentID,serialID,firmwareVersion,timeOfDownload,name,sampleSize) VALUES (%i,%i,"%s",%f,"%s",%i)', RSK.deployments.deploymentID, RSK.instruments.serialID, firmwareVersion, RSK.deployments.timeOfDownload, newfile, sampleSize));
        mksqlite(sprintf('INSERT INTO schedules (scheduleID,deploymentID,samplingPeriod,mode,gate) VALUES (%i,%i,%i,"%s","%s")', RSK.schedules.scheduleID, RSK.deployments.deploymentID, samplingPeriod, RSK.schedules.mode, RSK.schedules.gate));
        mksqlite(sprintf('INSERT INTO epochs VALUES (%i,%f,%f)', RSK.epochs.deploymentID, round(datenum2RSKtime(data.tstamp(1))), round(datenum2RSKtime(data.tstamp(end)))));
        insertTablechannels(RSK)
        insertTabledata(data)
        if isfield(RSK,'region')   
            insertTableregion(RSK)
            insertTableregionProfile(RSK)
            if isfield(RSK,'regionCast');
                insertTableregionCast(RSK)
            end
            if isfield(RSK,'regionGeoData');
                insertTableregionGeoData(RSK)
            end
            if isfield(RSK,'regionComment');
                insertTableregionComment(RSK)
            end       
        end 
        mksqlite('commit')
        
        function insertTablechannels(RSK)
            for i = 1:length(RSK.channels)
                mksqlite(sprintf('INSERT INTO channels VALUES (%i,"%s","%s","%s",1,0)',i, RSK.channels(i).shortName, RSK.channels(i).longName, RSK.channels(i).units)); 
            end
        end
        
        function insertTabledata(data)
            N = 5000;
            seg = 1:ceil(length(data.tstamp)/N);
            for k = seg
                if k == seg(end);
                    ind = 1+N*(k-1) : length(data.tstamp);       
                else
                    ind = 1+N*(k-1) : N*k;   
                end 
                value_format = strcat('(%i', repmat(', %f', 1, size(data.values(ind,:), 2)), '),\n');
                sql_data = horzcat(round(datenum2RSKtime(data.tstamp(ind,1))), data.values(ind,:));
                values = sprintf(value_format, reshape(rot90(sql_data, 3), numel(sql_data), 1));
                values = strrep(values(1:length(values) - 2), 'NaN', 'null');
                mksqlite(['INSERT INTO data VALUES' values]);
            end           
        end
        
        function insertTableregion(RSK)
            if isfield(RSK.region,'description');
                for i = 1:length(RSK.region) 
                    mksqlite(sprintf('INSERT INTO region (datasetID,regionID,type,tstamp1,tstamp2,label,description) VALUES (%i,%i,"%s",%i,%i,"%s","%s")',RSK.region(i).datasetID, RSK.region(i).regionID, RSK.region(i).type, RSK.region(i).tstamp1, RSK.region(i).tstamp2, RSK.region(i).label, RSK.region(i).description));
                end
            else
                for i = 1:length(RSK.region)
                    mksqlite(sprintf('INSERT INTO region (datasetID,regionID,type,tstamp1,tstamp2,label) VALUES (%i,%i,"%s",%i,%i,"%s")',RSK.region(i).datasetID, RSK.region(i).regionID, RSK.region(i).type, RSK.region(i).tstamp1, RSK.region(i).tstamp2, RSK.region(i).label));
                end
            end
        end
        
        function insertTableregionCast(RSK)
            for i = 1:length(RSK.regionCast)
                mksqlite(sprintf('INSERT INTO regionCast VALUES (%i,%i,"%s")',RSK.regionCast(i).regionID, RSK.regionCast(i).regionProfileID, RSK.regionCast(i).type));
            end  
        end
        
        function insertTableregionProfile(RSK)
            profileidx = find(strcmp({RSK.region.type},'PROFILE'));
            for i = 1:length(profileidx)
                mksqlite(sprintf('INSERT INTO regionProfile VALUES (%i)', profileidx(i))); 
            end
        end
        
        function insertTableregionGeoData(RSK)
            for i = 1:length(RSK.regionGeoData)
                mksqlite(sprintf('INSERT INTO regionGeoData VALUES (%i,%f,%f)',RSK.regionGeoData(i).regionID, RSK.regionGeoData(i).latitude, RSK.regionGeoData(i).longitude));
            end
        end  
        
        function insertTableregionComment(RSK)
            for i = 1:length(RSK.regionComment)
               mksqlite(sprintf('INSERT INTO regionComment VALUES (%i,"NULL")',RSK.regionComment(i).regionID));
            end
        end       
    end
end
