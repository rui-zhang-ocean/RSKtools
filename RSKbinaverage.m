function [RSK, binArray] = RSKbinaverage(RSK, varargin)

% RSKbinaverage - Average the profile data by a quantized reference
% channel.
%
% Syntax:  [RSK] = RSKbinaverage(RSK, [OPTIONS])
% 
% This function averages data in each profile using a averaging intervals
% defined by the binSizes and boundaries of the binBy channel.
%
% Note: The boundary takes precendence over the bin size. (Ex.
% boundary= [5 20], binSize = [10 20]. BinArray will be [5 15 20 40 60...].
% They should be ordered in the way the regimes would come up in that
% profiling direction. 
%
% Inputs:
%    
%   [Required] - RSK - The input RSK structure, with profiles as read using
%                      RSKreadprofiles.
%
%   [Optional] - profileNum - Optional profile number. Default is to
%                      operate on all detected profiles.
%            
%                direction - the profile cast direction of the data fields
%                      selected. Must be either 'down' or 'up'. Defaults to
%                      'down'.  
%
%                binBy - A reference channel that determines the samples in
%                      each bin , can be any channel or time. Default is
%                      Pressure.
%
%                binSize - Size of bins in each regime. Default [1] (units 
%                      of binBy channel). 
%
%                boundary - First boundary crossed in the direction
%                      selected of each regime, in same units as binBy.
%                      Must have length(boundary) == length(binSize) or one
%                      greater. Default[]; whole pressure range.       
%
% Outputs:
%    RSK - The structure with binned data.
%
%    samplesinbin - The amount of samples in each bin.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-24

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));

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

%% Find max profile length
dataIdx = setdataindex(RSK, profileNum);

alltstamp = {RSK.data(dataIdx).tstamp};
maxlength = max(cellfun('size', alltstamp, 1));
Y = NaN(maxlength, length(dataIdx));

k=1;
for ndx = dataIdx;
    if strcmpi(binBy, 'Time')
        ref = RSK.data(ndx).tstamp;
        Y(1:length(ref),k) = ref-ref(1);
    else
        chanCol = getchannelindex(RSK, binBy);
        ref = RSK.data(ndx).values(:,chanCol);
        Y(1:length(ref),k) = ref;
    end
    k = k+1;
end

[binArray, binCenter, boundary] = setupbins(Y, boundary, binSize, direction);

samplesinbin = NaN(maxlength, length(binArray)-1);
k = 1;
for ndx = dataIdx
    % Binning
    X = [RSK.data(ndx).tstamp, RSK.data(ndx).values];
    binnedValues = NaN(length(binArray)-1, size(X,2));
    
    for bin=1:length(binArray)-1
        binidx = findbinindices(Y(:,k), binArray(bin), binArray(bin+1));
        samplesinbin(:,bin) = binidx;
        binnedValues(bin,:) = nanmean(X(binidx,:),1);
    end
    
    RSK.data(ndx).values = binnedValues(:,2:end);
    RSK.data(ndx).samplesinbin = samplesinbin;
    if strcmpi(binBy, 'Time')
        RSK.data(ndx).tstamp = binCenter;
    else
        RSK.data(ndx).tstamp = binnedValues(:,1);
        RSK.data(ndx).values(:,chanCol) = binCenter;
    end
    k = k+1;
end

% Log
unit = RSK.channels(chanCol).units;
logdata = logentrydata(RSK, profileNum, dataIdx);
logentry = sprintf('Binned with respect to %s using [%s] boundaries with %s %s bin size on %s.', binBy, num2str(boundary), num2str(binSize), unit, logdata);
RSK = RSKappendtolog(RSK, logentry);



%% Nested functions
    function [binArray, binCenter, boundary] = setupbins(Y, boundary, binSize, direction)
    % Set up binArray based on the boundaries any binSize given. Boundaries
    % are hard set and binSize fills the space between the boundaries in
    % the same direction as the cast.  
    
        binArray = [];
        if length(binSize) > length(boundary)+1 || (length(binSize) < length(boundary)-1 && ~isempty(boundary))
            disp('Boundary must be of length 0, length(binSize) or length(binSize)+1')
            return
        end

        if isempty(boundary)
            boundary = [ceil(max(nanmax(Y))) floor(min(nanmin(Y)))];
        elseif length(boundary) == length(binSize)
            if strcmp(direction, 'up')
                boundary = [boundary floor(min(nanmin(Y)))];
            else
                boundary = [boundary ceil(max(nanmax(Y)))];
            end
        elseif length(boundary) == length(binSize)+1
        end
        if strcmpi(direction, 'up')
            binSize = -binSize;
            boundary  = sort(boundary, 'descend');
        else
            boundary = sort(boundary, 'ascend');
        end  

        for nregime = 1:length(boundary)-1
            binArray = [binArray boundary(nregime):binSize(nregime):boundary(nregime+1)];       
        end
        binArray = [binArray, binArray(end)+binSize(end)];
        binArray = unique(binArray);
        
        binCenter = tsmovavg(binArray, 's', 2);
        binCenter = binCenter(2:end);
    end

    
    function [binidx] = findbinindices(binByvalues, lowerboundary, upperboundary)
    % Selects the indices of the binBy channel that are within the lower
    % and upper boundaries of the evaluated bin to establish which values
    % from the other channel need to be averaged.
    
        binidx = binByvalues >= lowerboundary & binByvalues < upperboundary;
        ind = find(diff(binidx)<0);
        if ~isempty(ind) && any(binByvalues(ind+1) > upperboundary)
            discardedindex = find(binByvalues(ind+1) > upperboundary, 1);
            binidx(ind(discardedindex)+1:end) = 0;
        end
    end
    
end
    