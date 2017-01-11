function RSK = RSKreadgeodata(RSK, varargin)

% RSKreadgeodata - Reads the geodata of a rsk file
%
% Syntax:  RSK = RSKreadgeodata(RSK)
%
% RSKreadgeodata will return the geodata of a file
%
% Inputs:
%    RSK - Structure containing the logger metadata and thumbnails
%          returned by RSKopen.
%    UTCdelta - The offset of the timestamp. If a value is entered it will
%          be used. Otherwise it will use the one given in the epochs
%          table, if there is none it will use 0.
%
% Output:
%    RSK - Structure containing previously present logger metadata as well
%          as geodata.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-01-11

%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'UTCdelta', 0);
parse(p, RSK, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
UTCdelta = p.Results.UTCdelta;

%% Read geodata
RSK.geodata = mksqlite('select tstamp/1.0 as tstamp, latitude, longitude, accuracy, accuracyType from geodata');
if isempty(RSK.geodata)
    RSK = rmfield(RSK, 'geodata');
elseif strcmpi(p.UsingDefaults, 'UTCdelta')
    try
        UTCdelta = mksqlite('select UTCdelta/1.0 as UTCdelta from epochs');
        RSK.epochs.UTCdelta = UTCdelta.UTCdelta;
        for ndx = 1:length(RSK.geodata)
            RSK.geodata(ndx).tstamp = RSKtime2datenum(RSK.geodata(ndx).tstamp + RSK.epochs.UTCdelta);
        end    
    catch
        warning('No UTCdelta value, the timestamps in geodata cannot be adjust to the logger time, will use 0');
        for ndx = 1:length(RSK.geodata)
            RSK.geodata(ndx).tstamp = RSKtime2datenum(RSK.geodata(ndx).tstamp);
        end
    end
else
    for ndx = 1:length(RSK.geodata)
        RSK.geodata(ndx).tstamp = RSKtime2datenum(RSK.geodata(ndx).tstamp + UTCdelta);
    end
end
end
