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
%                regimes - Amount of sections with different sizes of bins.
%                   Default 1, all bins are the same width
%
%                binSize - Size of bins. Must have length(binSize) ==
%                   regimes. Default 1.
%
%                Boundary - Bottom bounday of each regime, in same units as
%                binBy. Must have length(boundary) == regimes. Default
%                max(Pressure).
%               
%                latitude - latitude at the location of sampling.
%           
%
% Outputs:
%    Y - Binned array
%    binCenter - Bin center values
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-12-06

%% Input Parse
validBinBy = {'Pressure', 'Depth'};
checkBinBy = @(x) any(validatestring(x,validBinBy));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'binBy', 'Pressure', checkBinBy);
addParameter(p, 'Regimes', (0.5:1:100), @isnumeric);
addParameter(p, 'binSize', 1, @isnumeric);
addParameter(p, 'boundary', 1, @isnumeric);
addParameter(p, 'laititude', [], @isnumeric);
parse(p, RSK,varargin{:})

% Assign each argument
X = p.Results.X;
Method = p.Results.Method;
binBy = p.Results.binBy;
binArray = p.Results.binArray;
binWidth = p.Results.binWidth;
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



%% Binning 
pressureCol = strcmpi('pressure', {RSK.channels.longName});

for ndx = profileNum
    Pressure = RSK.profiles.(castdir).data(ndx).values(:,pressureCol);
    Depth = -calculatedepth(Pressure,'latitude', latitude);

    switch Method
        case 'Width' %Should output bins for this case
            switch binBy
              case 'Pressure'
                binCenter = (binWidth:binWidth:ceil(max(Pressure)))';
              case 'Depth'
                binCenter = (binWidth:binWidth:ceil(max(Depth)))';
            end

            %  initialize the binned output field  
            Y = NaN(length(binCenter),1);

            for k=1:length(binCenter)

              switch binBy
                case 'Pressure'
                  kk = (Pressure >= binCenter(k)-binWidth/2) & (Pressure < binCenter(k)+binWidth/2);
                case 'Depth'
                  kk = (Depth >= binCenter(k)-binWidth/2) & (Depth < binCenter(k)+binWidth/2);
              end
              Y(k) = nanmean(X(kk));
            end

        case 'Array'
            bins = binArray;
            binCenter = tsmovavg(bins, 's', 2);
            binCenter = binCenter(2:end); %Starts with NaN.
            %  initialize the binned output field         
            Y = NaN(length(bins)-1,1);
            for k=1:length(bins)-1
              switch binBy
                case 'Pressure'            
                    kk = Pressure >= bins(k) & Pressure < bins(k+1);
                case 'Depth'
                    kk = Depth >= bins(k) & Depth < bins(k+1);
              end
                Y(k) = nanmean(X(kk));
            end

        case 'ArgoRegimes'
            if strcmp(binBy, 'Depth'), warning('Must be binned by Pressure...will bin by pressure'); end
            bins = [10, 50, 60:20:200, 250:50:500];
            binCenter = tsmovavg(bins, 's', 2);
            binCenter = binCenter(2:end); %Starts with NaN.

            %  initialize the binned output field         
            Y = NaN(length(bins)-1,1);
            for k=1:length(bins)-1
                kk = Pressure >= bins(k) & Pressure < bins(k+1);
                Y(k) = nanmean(X(kk));
            end

            %Regimes
            
            
            
            
    end
  
end






