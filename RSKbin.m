function [Y, binCenter] = RSKbin(RSK, varargin)

% RSKbin - Bins the profiles in the RSK 
%
% Syntax:  [RSK] = RSKbin(RSK, channel, [OPTIONS])
% 
% Based on the regimes specified this function bins the profiles in the RSK
% srtucture of a single or many channels based on pressure or depth
%
% Inputs:
%    
%   [Required] - RSK - the input RSK structure, with profiles as read using
%                    RSKreadprofiles
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
%                boundary - First boundary crossed in the direction selected of each regime, in same units as
%                   binBy. Must have length(boundary) == regimes. Default
%                   []; whole pressure range.
%               
%                latitude - latitude at the location of sampling in degree
%                    north. Default 45.
%           
%
% Outputs:
%    Y - Binned array
%    binCenter - Bin center values
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-12-14

%% Check input and default arguments
validBinBy = {'Pressure', 'Depth'};
checkBinBy = @(x) any(validatestring(x,validBinBy));

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'binBy', 'Pressure', checkBinBy);
addParameter(p, 'numRegimes', 1, @isnumeric);
addParameter(p, 'binSize', 1, @isnumeric);
addParameter(p, 'boundary', [], @isnumeric);
addParameter(p, 'latitude', 45, @isnumeric);
parse(p, RSK,varargin{:})

% Assign each argument
RSK = p.Results.RSK;
profileNum = p.Results.profileNum;
direction = p.Results.direction;
binBy = p.Results.binBy;
numRegimes = p.Results.numRegimes;
binSize = p.Results.binSize;
boundary = p.Results.firstBoundary;
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



%% Set up pressure/depth of profiles in matrix
pressureCol = find(strcmpi('pressure', {RSK.channels.longName}));
k=1;
switch binBy
    case 'Pressure'
        for ndx = profileNum
            Y(k) = RSK.profiles.(castdir).data(ndx).values(:,pressureCol(1));
            k = k+1;
        end
    case 'Depth'
        for ndx = profileNum
            Pressure = RSK.profiles.(castdir).data(ndx).values(:,pressureCol(1));
            Y(k) = -calculatedepth(Pressure, latitude);
            k = k+1;
        end
end



%% Set up binArray
if isempty(boundary)     
    boundary = max(Y);
end

switch direction
    case 'up'
        if isempty(boundary)     
            boundary = max(Y);
        end
        binArray = [];
        boundary = [boundary 0];
        for ndx = 1:length(boundary)-1
            binArray = [binArray boundary(ndx):-binSize(ndx):boundary(ndx+1)];
        end
        binArray = unique(binArray);

        
    case 'down'
        if isempty(boundary)     
            boundary = min(Y);
        end
        binArray = boundary(end):binSize(end):max(Y)+binSize(end)-1;
        if numRegimes>1
            for ndx = numRegimes:-1:2
                binArray = [boundary(ndx-1):binSize(ndx-1):boundary(ndx)-1 binArray];
            end        
        end
        
end



%% Set up channel to bin
if strcompi(channel, 'all')
    channelCol = find(~pressureCol);
else
    for ndx = 1:length(channel)
        channelCol(ndx) = find(strcmpi(channel{ndx}, {RSK.channels.longName}));
    end
end
                
%% Binning 
for channelCol
    for ndx = profileNum
        binCenter = tsmovavg(binArray, 's', 2);
        binCenter = binCenter(2:end); %Starts with NaN.
        %  initialize the binned output field         
        binnedValues = NaN(length(binArray)-1,1);
        for ndx = 1:size(Y,2)
            for k=1:size(Y,1)-1
                kk = Y(:,ndx) >= binArray(k) & Y(:,ndx) < binArray(k+1);
                binnedValues(k) = nanmean(X(kk));
            end

        end
    end
end







