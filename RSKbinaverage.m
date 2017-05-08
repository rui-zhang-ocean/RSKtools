function [RSK, binCenter] = RSKbinaverage(RSK, varargin)

% RSKbinaverage - Bins the profiles of a single channel
%
% Syntax:  [RSK] = RSKbinaverage(RSK, channel, [OPTIONS])
% 
% Based on the regimes specified this function bins the profiles in the RSK
% structure of a single channel based on pressure or depth
%
% Note: The boundary takes precendence over the bin size. (Ex.
% boundary= [5 20], binSize = [10 5]. BinArray will be [5 15 20 25 30...]
%
% Inputs:
%    
%   [Required] - RSK - the input RSK structure, with profiles as read using
%                    RSKreadprofiles.
%
%                channel - Longname of channel to bin (e.g. temperature,
%                    salinity, etc).
%
%   [Optional] - profileNum - profiles included in the contour plot.
%                   Default is to do all profiles.
%            
%                direction - the profile direction to consider. Must be either
%                   'down' or 'up'. Defaults to 'down'. 
%
%                binBy - The units of the binSize and boundary. Depth (m)
%                   or Pressure (dbar). Defaults to 'Pressure'.
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
%
%    binnedValues - Binned array
%
%    binCenter - Bin center values
%
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
profileIdx = checkprofiles(RSK, profileNum, direction);
castdir = [direction 'cast'];

%% Find max profile length
profilelength = 0;
for ndx = profileIdx
    if size(RSK.profiles.(castdir).data(ndx).tstamp,1) > profilelength
        profilelength = size(RSK.profiles.(castdir).data(ndx).tstamp,1);
    end
end
Y = NaN(profilelength, length(profileIdx));


%% Set up pressure/depth of profiles in matrix
k=1;        
for ndx = profileIdx
    Pressure = RSK.profiles.(castdir).data(ndx).values(:,pCol);
    switch binBy
        case 'Pressure'
            pCol = getchannelindex(RSK, 'Pressure');
            Pressure = RSK.profiles.(castdir).data(ndx).values(:,pCol);
            Y(1:length(Pressure),k) = Pressure - 10.1325;
        case 'Depth'
            dCol = getchannelindex(RSK, 'Depth');
            Depth = RSK.profiles.(castdir).data(ndx).values(:,dCol);
            Y(1:length(Depth),k) = Depth - 10.1325;            
    end
    k = k+1;
end

%% Set up binArray
binArray = [];
switch direction
    case 'up'
        if isempty(boundary) && numRegimes == 1  
            boundary = [ceil(max(nanmax(Y))) floor(min(nanmin(Y)))];
        else
            boundary = [boundary 0];
        end
        for ndx = 1:length(boundary)-1
            binArray = [binArray boundary(ndx):-binSize(ndx):boundary(ndx+1)];
        end
        
    case 'down'
        if isempty(boundary) && numRegimes == 1       
            boundary = [floor(min(nanmin(Y))) ceil(max(nanmax(Y)))];
        else
            boundary = [boundary ceil(max(max(Y)))];
        end
        for ndx = 1:length(boundary)-1
            binArray = [binArray boundary(ndx):binSize(ndx):boundary(ndx+1)];       
        end
end
binArray = unique(binArray);



%% Binning 
channelCol = strcmpi(channel, {RSK.channels.longName});

binnedValues = NaN(length(binArray)-1, length(profileNum));
for ndx = profileIdx
    X = RSK.profiles.(castdir).data(ndx).values(:,channelCol);
    binCenter = tsmovavg(binArray, 's', 2);
    binCenter = binCenter(2:end); %Starts with NaN.
    %  initialize the binned output field         
    for k=1:length(binArray)-1
        kk = Y(1:length(X), ndx) >= binArray(k) & Y(1:length(X), ndx) < binArray(k+1);
        ind = find(diff(kk)<0);
        kk(ind:end) = 0;
        binnedValues(k, ndx) = nanmean(X(kk));
        RSK.profiles.(castdir).data(ndx).values = binnedValues(k, ndx);
    end
end

RSK.profiles.(castdir).(channel(1:4)).binValues = binnedValues;
RSK.profiles.(castdir).(channel(1:4)).binCenter = binCenter;
end


