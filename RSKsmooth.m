function RSK = RSKsmooth(RSK, channel, varargin)

% RSKsmooth - Apply a low pass filter on specified channels.
%
% Syntax:  [RSK] = RSKsmooth(RSK, channel, [OPTIONS])
% 
% Low-pass filter a specified channel or multiple channels with a
% running average or median.  The sample being evaluated is always in
% the centre of the filtering window to avoid phase distortion.  Edge
% effects are handled by mirroring the original time series.
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger data.
%
%                 channel - Longname of channel to filter. Can be a 
%                       single channel, a cell array for multiple 
%                       channels, or 'all' for all channels.
%               
%    [Optional] - filter - The weighting function, 'boxcar' or 'triangle'.
%                       Use 'median' to compute the running median. 
%                       Defaults to 'boxcar.'
%
%                 profile - Profile number. Defaults to operate on all
%                       available profiles.  
%
%                 direction - 'up' for upcast, 'down' for downcast, or
%                       'both' for all. Defaults to all directions available.
%
%                 windowLength - The total size of the filter window. Must
%                       be odd. Default is 3.
%
%                 diagnostic - To give a diagnostic plot on the first 
%                       profile of the first channel or not (1 or 0). 
%                       Original and processed data will be plotted to 
%                       show users how the algorithm works. Default is 0.
%
% Outputs:
%    RSK - Structure with filtered values.
%
% Example: 
%    rsk = RSKopen('file.rsk');
%    rsk = RSKreadprofiles(rsk, 'profile', 1:10); % read first 10 downcasts
%    rsk = RSKsmooth(rsk, {'Temperature', 'Salinity'}, 'windowLength', 17);
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-03-19

validFilterNames = {'median', 'boxcar', 'triangle'};
checkFilter = @(x) any(validatestring(x,validFilterNames));

validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'filter', 'boxcar', checkFilter);
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'direction', [], checkDirection);
addParameter(p, 'windowLength', 3, @isnumeric);
addParameter(p, 'diagnostic', 0, @isnumeric);
parse(p, RSK, channel, varargin{:})

RSK = p.Results.RSK;
channel = p.Results.channel;
filter = p.Results.filter;
profile = p.Results.profile;
direction = p.Results.direction;
windowLength = p.Results.windowLength;
diagnostic = p.Results.diagnostic;

if diagnostic == 1; raw = RSK; end % Save raw data if diagnostic plot is required

channelcell = cellchannelnames(RSK, channel);

castidx = getdataindex(RSK, profile, direction);
for chanName = channelcell
    channelCol = getchannelindex(RSK, chanName);
    for ndx = castidx
        in = RSK.data(ndx).values(:,channelCol);
        switch filter
            case 'boxcar'
                out = runavg(in, windowLength);
            case 'median'
                out = runmed(in, windowLength);
            case 'triangle'
                out = runtriang(in, windowLength);
        end      
        RSK.data(ndx).values(:,channelCol) = out;
        if strcmp(chanName, channelcell{1}) && ndx == castidx(1) && diagnostic == 1; 
            doDiagPlot(RSK,raw,'ndx',ndx,'channelidx',channelCol); 
        end 
    end
    logdata = logentrydata(RSK, profile, direction);
    logentry = sprintf('%s filtered using a %s filter with a %1.0f sample window on %s.', chanName{1}, filter, windowLength, logdata);
    RSK = RSKappendtolog(RSK, logentry);
end

end