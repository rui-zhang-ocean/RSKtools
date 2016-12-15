function RSK = RSKreadgeodata(RSK)

% RSKreadgeodata - Opens an RBR RSK file and reads the geodata.
%
% Syntax:  [RSK] = RSKreadgeodata(RSK)
% 
% RSKopen makes a connection to an RSK (sqlite format) database as
% obtained from an RBR logger and reads in the geodata information. RSKopen assumes only a
% single instrument deployment is contained in the RSK file.
%
% Inputs:
%    RSK - Structure containing the logger metadata returned by RSKopen.
%
% Outputs:
%    RSK - Structure containing the logger metadata and thumbnails
%
% Example: 
%    RSK = RSKopen('sample.rsk'); 
%    RSK = RSKreadgeodata(RSK);
%
% See also: RSKplotthumbnail, RSKreaddata, RSKreadevents, RSKreadburstdata
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-12-15

%Note: Needs to be updated when Ruskin populated regionGeoData
%Load in geodata table if present. Could be in any version of RSK.
try
    RSK.geodata = mksqlite('select * from geodata');
    for ndx = 1:length(RSK.geodata)
        RSK.geodata(ndx).tstamp = RSKtime2datenum(RSK.geodata(ndx).tstamp);
    end
catch 
end
end