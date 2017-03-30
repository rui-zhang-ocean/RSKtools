function samplingperiod = RSKsamplingperiod(RSK)

% RSKsamplingperiod - Returns the sampling period information
%
% Syntax:  [v, vsnMajor, vsnMinor, vsnPatch] = RSKsamplingperiod(RSK)
%
% RSKsamplingperiod will return the sampling period of the file
%
% Inputs:
%    RSK - Structure containing the logger metadata and thumbnails
%          returned by RSKopen.
%
% Output:
%    samplingperiod - the sampling period information
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-03-30

mode = RSK.schedules.mode;
if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 13)) || ((vsnMajor == 1)&&(vsnMinor == 13)&&(vsnPatch >= 8))
    if strcmpi(mode, 'ddsampling')
        samplingperiod.fastThreshold = RSK.directional.fastThreshold/1000;
        samplingperiod.slowThreshold = RSK.directional.slowThreshold/1000;
    elseif strcmpi(mode, 'fetching')
        error('"Fetching" files do not have a sampling period');
    else 
        samplingperiod = RSK.(mode).samplingPeriod/1000;
    end
else
    samplingperiod = RSK.schedules.samplingPeriod/1000;
end

end