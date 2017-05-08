function [RSK] = RSKbinprofile(RSK, varargin)

% RSKbinprofile - Bins the all channels and time of by any reference for a
% profile.
%
% Syntax:  [RSK] = RSKbinprofile(RSK, [OPTIONS])
% 
% Based on the regimes specified this function bins the channels in the RSK
% structure by profile based on any channel
%
% Note: The boundary takes precendence over the bin size. (Ex.
% boundary= [5 20], binSize = [10 5]. BinArray will be [5 15 20 25 30...]
%
% Inputs:
%    
%   [Required] - RSK - the input RSK structure, with profiles as read using
%                    RSKreadprofiles.
%
%   [Optional] - profileNum - profiles to bin. Default is to do all profiles.
%            
%                direction - the profile direction to consider. Must be either
%                   'down' or 'up'. Defaults to 'down'. 
%
%                binBy - Any channel in the RSK, could be time.
%
%                binSize - Size of bins in each regime. Must have length(binSize) ==
%                   numRegimes. Default 1.
%
%                boundary - First boundary crossed in the direction
%                   selected of each regime, in same units as binBy. Must
%                   have length(boundary) == regimes. Default[]; whole
%                   pressure range.      
%
% Outputs:
%    RSK
%
%    binCenter - Bin center values
%
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-08

%% Check input and default arguments

validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);
addParameter(p, 'binBy', 'Pressure', @ischar);
addParameter(p, 'binSize', 1, @isnumeric);
addParameter(p, 'boundary', [], @isnumeric);
parse(p, RSK, varargin{:})

% Assign each argument
RSK = p.Results.RSK;
profileNum = p.Results.profileNum;
direction = p.Results.direction;
binBy = p.Results.binBy;
binSize = p.Results.binSize;
boundary = p.Results.boundary;


%% Determine if the structure has downcasts and upcasts & set profileNum accordingly
profileIdx = checkprofiles(RSK, profileNum, direction);
castdir = [direction 'cast'];


for ndx = profileIdx

    % Find reference channel
    if strcmpi(binBy, 'Time')
        ref = RSK.profiles.(castdir).data(ndx).tstamp;
    else
        chanCol = getchannelindex(RSK, binBy);
        ref = RSK.profiles.(castdir).data(ndx).values(:,chanCol);
    end

    % Set up binArray
    binArray = [];
    switch direction
        case 'up'
            if isempty(boundary)
                bounds = [ceil(nanmax(ref)) floor(nanmin(ref))];
            else
                bounds = [boundary floor(nanmin(ref))];
            end
            for nregime = 1:length(bounds)-1
                binArray = [binArray bounds(nregime):-binSize(nregime):bounds(nregime+1)];
            end

        case 'down'
            if isempty(boundary)      
                bounds = [floor(nanmin(ref)) ceil(nanmax(ref))];
            else
                bounds = [boundary ceil(nanmax(ref))];
            end
            for nregime = 1:length(bounds)-1
                binArray = [binArray bounds(nregime):binSize(nregime):bounds(nregime+1)];       
            end
    end
    binArray = unique(binArray);

    % Binning 
    X = [RSK.profiles.(castdir).data(ndx).tstamp, RSK.profiles.(castdir).data(ndx).values];
    binnedValues = NaN(length(binArray)-1, size(X,2));
    binCenter = tsmovavg(binArray, 's', 2);
    binCenter = binCenter(2:end); %Starts with NaN.
    %  initialize the binned output field      
    for k=1:length(binArray)-1
        kk = ref >= binArray(k) & ref < binArray(k+1);
        if ~isempty(find(diff(kk)<0,1))
           kk(ind(1):end) = 0;
        end
        binnedValues(k,:) = nanmean(X(kk,:),1);
    end
    
    RSK.profiles.(castdir).data(ndx).values = binnedValues(:,2:end);
    if strcmpi(binBy, 'Time')
        RSK.profiles.(castdir).data(ndx).tstamp = binCenter;
    else
        RSK.profiles.(castdir).data(ndx).tstamp = binnedValues(:,1);
        RSK.profiles.(castdir).data(ndx).values(:,chanCol) = binCenter;
    end
    
end
end