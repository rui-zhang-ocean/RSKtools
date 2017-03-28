function RSK = readcalibrations(RSK)

% readcalibrations - Reads the calibrations table of a rsk file
%
% Syntax:  RSK = readcalibrations(RSK)
%
% readcalibrations will return the calibrations table of a file including
% the coefficients. In version 1.13.4 of the RSK schema the coefficients
% table was seperated from the calibrations table. Here we recombine them
% into one table or simple open the calibrations table and adjust the time
% stamps if it was create before 1.13.4
%
% Inputs:
%    RSK - Structure containing the logger metadata and thumbnails
%          returned by RSKopen.
%
% Output:
%    RSK - Structure containing previously present logger metadata as well
%          as calibrations including coefficients
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-03-28

[~, vsnMajor, vsnMinor, vsnPatch] = RSKver(RSK);

%As of RSK v1.13.4 coefficients is it's own table. We add it back into calibration to be consistent with previous versions.
if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 13)) || ((vsnMajor == 1)&&(vsnMinor == 13)&&(vsnPatch >= 4))
    RSK = coef2cal(RSK);
else
    if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 12)) || ((vsnMajor == 1)&&(vsnMinor == 12)&&(vsnPatch >= 2))
        RSK.calibrations = mksqlite('select `calibrationID`, `channelOrder`, `instrumentID`, `type`, `tstamp`/1.0 as tstamp, `equation` from calibrations');
    else
        RSK.calibrations = mksqlite('select `calibrationID`, `channelOrder`, `type`, `tstamp`/1.0 as tstamp, `equation` from calibrations');
    end
    
    for ndx = 1:length(RSK.calibrations)
        RSK.calibrations(ndx).tstamp = RSKtime2datenum(RSK.calibrations(ndx).tstamp);
    end
end

end
