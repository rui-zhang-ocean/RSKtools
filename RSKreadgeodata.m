function RSK = RSKreadgeodata(RSK)

% RSKreadgeodata - Reads the geodata of a rsk file
%
% Syntax:  RSK = RSKreadgeodata(RSK)
%
% RSKreadgeodata will return the geodata of a file
%
% Inputs:
%    RSK - Structure containing the logger metadata and thumbnails
%          returned by RSKopen.
%
% Output:
%    RSK - Structure containing previously present logger metadata as well
%          as geodata.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-12-22


RSK.geodata = mksqlite('select tstamp/1.0 as tstamp, latitude, longitude, accuracy, accuracyType from geodata');
if isempty(RSK.geodata)
    RSK = rmfield(RSK, 'geodata');
else
    try
        UTCdelta = mksqlite('select UTCdelta/1.0 as UTCdelta from epochs');
        RSK.epochs.UTCdelta = UTCdelta.UTCdelta;
    catch
        warning('No UTCdelta value, the timestamps in geodata cannot be adjust to the logger time, will use 0');
        UTCdelta.UTCdelta = 0;
    end
    for ndx = 1:length(RSK.geodata)
        RSK.geodata(ndx).tstamp = RSKtime2datenum(RSK.geodata(ndx).tstamp + UTCdelta.UTCdelta);
    end
end
end
