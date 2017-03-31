function [RSK, dbid] = RSKopen(fname)

% RSKopen - Opens an RBR RSK file and reads metadata and thumbnails.
%
% Syntax:  [RSK, dbid] = RSKopen(fname)
% 
% RSKopen makes a connection to an RSK (sqlite format) database as
% obtained from an RBR logger and reads in the instrument metadata as
% well as a thumbnail of the stored data. RSKopen assumes only a
% single instrument deployment is contained in the RSK file. The
% thumbnail usually contains about 4000 points, and thus avoids
% reading large amounts of data that can be contained in the
% database. Each time value has a maximum and a minimum data value so
% that all spikes are visible even though the dataset is down-sampled.
%
% RSKopen requires a working mksqlite library. We have included a
% couple of versions here for Windows (32/64 bit), Linux (64 bit) and
% Mac (64 bit), but you might need to compile another version.  The
% mksqlite-src directory contains everything you need and some
% instructions from the original author.  You can also find the source
% through Google.
%
% Note: If the file was recorded from an |rt instrument there is no thumbnail data.
%
% Inputs:
%    fname - filename of the RSK file
%
% Outputs:
%    RSK - Structure containing the logger metadata and thumbnails
%    dbid - database id returned from mksqlite
%
% Example: 
%    RSK=RSKopen('sample.rsk');  
%
% See also: RSKplotthumbnail, RSKreaddata, RSKreadevents, RSKreadburstdata
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-03-31

RSKconstants

if nargin==0
    fname=uigetfile({'*.rsk','*.RSK'},'Choose an RSK file');
end

if exist(fullfile(cd, fname),'file') ~= 2
    disp('File cannot be found')
    RSK=[];dbid=[];
    return
end

dbid = mksqlite('open',fname);

RSK.dbInfo = mksqlite('select version,type from dbInfo');

if iscompatibleversion(RSK, latestRSKversionMajor, latestRSKversionMinor, latestRSKversionPatch+1)
    warning(['RSK version ' vsnString ' is newer than your RSKtools version. It is recommended to update RSKtools at https://rbr-global.com/support/matlab-tools']);
end

RSK = readstandardtables(RSK);

switch RSK.dbInfo(end).type
    case 'EasyParse'
        RSK = readheaderEP(RSK);
    case 'EPdesktop'
        RSK = readheaderEPdesktop(RSK);
    case 'skinny'
        RSK = readheaderskinny(RSK);
    case 'full'
        RSK = readheaderfull(RSK);
    case 'live'
        RSK = readheaderlive(RSK);
    otherwise
        disp('Not recognised')
        return
end


%% Channel name check.
% Some channels require a more descriptive name if they are present.
if strcmpi({RSK.channels.shortName}, 'temp04')
    idx = find(strcmpi({RSK.channels.shortName}, 'temp04'));
    for ndx = 1:length(idx)
        RSK.channels(idx(ndx)).longName = ['Temperature' num2str(ndx)];
    end
end

if any(strcmpi({RSK.channels.shortName}, 'temp05'))   
    idx = find(strcmpi({RSK.channels.shortName}, 'temp05'));
    RSK.channels(idx(ndx)).longName = 'Pressure Gauge Temperature';
elseif any(strcmpi({RSK.channels.shortName}, 'temp10'))
    idx = strcmpi({RSK.channels.shortName}, 'temp10');
    RSK.channels(idx).longName = 'Pressure Gauge Temperature';
end    

if any(strcmpi({RSK.channels.shortName}, 'temp13'))
    idx = strcmpi({RSK.channels.shortName}, 'temp13');
    RSK.channels(idx).longName = 'External Cabled Temperature';
end


%% Read in events so that we can get the profile event metadata

RSK = RSKgetprofiles(RSK);


end