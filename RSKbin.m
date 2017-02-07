function [binnedValues, binCenter] = RSKbin(RSK, channel, varargin)

% RSKbin - Bins the profiles of a single channel
%
% Syntax:  [RSK] = RSKbin(RSK, channel, [OPTIONS])
% 
% Based on the regimes specified this function bins the profiles in the RSK
% structure of a single or many channels based on pressure or depth
%
% Note: The boundary takes precendence over the bin size. (Ex.
% boundary= [5 20], binSize = [10 5]. BinArray will be [5 15 20 25 30...]

% Inputs:
%    
%   [Required] - RSK - the input RSK structure, with profiles as read using
%                    RSKreadprofiles.
%
%                channel - Longname of channel to plot (e.g. temperature,
%                    salinity, etc). Can be cell array of many channels or
%                    'all', will despike all channels.
%
%   [Optional] - profileNum - the profiles to which to apply the correction. If
%                    left as an empty vector, will do all profiles.
%            
%                direction - the profile direction to consider. Must be either
%                   'down' or 'up'. Only needed if series is profile. Defaults to 'down'.
%
%                binBy - The array it will be bin wrt... Depth or Pressure.
%                   Defaults to 'Pressure'.
%
%                numRegimes - Amount of sections with different sizes of bins.
%                   Default 1, all bins are the same width.
%
%                binSize - Size of bins in each regime. Must have length(binSize) ==
%                   numRegimes. Default 1.
%
%                boundary - First boundary crossed in the direction
%                   selected of each regime, in same units as binBy. Must
%                   have length(boundary) == regimes. Default[]; whole
%                   pressure range.
%               
%                latitude - latitude at the location of sampling in degree
%                    north. Default 45.
%           
%
% Outputs:
%    binnedValues - Binned array
%    binCenter - Bin center values
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-02-07

%% Check input and default arguments
validBinBy = {'Pressure', 'Depth'};
checkBinBy = @(x) any(validatestring(x,validBinBy));

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel');
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'binBy', 'Pressure', checkBinBy);
addParameter(p, 'numRegimes', 1, @isnumeric);
addParameter(p, 'binSize', 1, @isnumeric);
addParameter(p, 'boundary', [], @isnumeric);
addParameter(p, 'latitude', 45, @isnumeric);
parse(p, RSK, channel, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
channel = p.Results.channel;
profileNum = p.Results.profileNum;
direction = p.Results.direction;
binBy = p.Results.binBy;
numRegimes = p.Results.numRegimes;
binSize = p.Results.binSize;
boundary = p.Results.boundary;
latitude = p.Results.latitude;



%% Determine if the structure has downcasts and upcasts & set profileNum accordingly
castdir = [direction 'cast'];
isDown = isfield(RSK.profiles.downcast, 'data');
isUp   = isfield(RSK.profiles.upcast, 'data');
switch direction
    case 'up'
        if ~isUp
            error('Structure does not contain upcasts')
        elseif isempty(profileNum)
            profileNum = 1:length(RSK.profiles.upcast.data);
        end
    case 'down'
        if ~isDown
            error('Structure does not contain downcasts')
        elseif isempty(profileNum)
            profileNum = 1:length(RSK.profiles.downcast.data);
        end
end



%% Find max profile length
profilelength = 0;
for ndx = profileNum
    if size(RSK.profiles.(castdir).data(ndx).tstamp,1) > profilelength
        profilelength = size(RSK.profiles.(castdir).data(ndx).tstamp,1);
    end
end
Y = NaN(profilelength, length(profileNum));



%% Set up pressure/depth of profiles in matrix
pressureCol = find(strcmpi('pressure', {RSK.channels.longName}));
k=1;        
for ndx = profileNum
    Pressure = RSK.profiles.(castdir).data(ndx).values(:,pressureCol(1));
    switch binBy
        case 'Pressure'
            Y(1:length(Pressure),k) = Pressure;
        case 'Depth'
            Y(1:length(Pressure), k) = calculatedepth(Pressure, latitude);
    end
    k = k+1;
end



%% Set up binArray
binArray = [];
switch direction
    case 'up'
        if isempty(boundary) && numRegimes == 1  
            boundary = [ceil(max(max(Y))) floor(min(min(Y)))];
        else
            boundary = [boundary 0];
        end
        for ndx = 1:length(boundary)-1
            binArray = [binArray boundary(ndx):-binSize(ndx):boundary(ndx+1)];
        end
        
    case 'down'
        if isempty(boundary) && numRegimes == 1       
            boundary = [floor(min(min(Y))) ceil(max(max(Y)))];
        else
            boundary = [boundary ceil(max(max(Y)))];
        end
        for ndx = 1:length(boundary)-1
            binArray = [binArray boundary(ndx):binSize(ndx):boundary(ndx+1)];       
        end
end
binArray = unique(binArray);



%% Set up channel to bin
channelCol = strcmpi(channel, {RSK.channels.longName});


                
%% Binning 
binnedValues = NaN(length(binArray)-1, length(profileNum));
for ndx = profileNum
    X = RSK.profiles.(castdir).data(ndx).values(:,channelCol);
    binCenter = tsmovavg(binArray, 's', 2);
    binCenter = binCenter(2:end); %Starts with NaN.
    %  initialize the binned output field         
    for k=1:length(binArray)-1
        kk = Y(:, ndx) >= binArray(k) & Y(:, ndx) < binArray(k+1);
        binnedValues(k, ndx) = nanmean(X(kk));
    end
end
end


