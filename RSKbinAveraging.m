function [Y, binCenter] = RSKbinAveraging(X, Pressure, varargin)

% RSKbinAveraging - 
%
% Syntax:  [RSK] = RSKbinAveraging(RSK, channel, [OPTIONS])
% 
% RSKbinAveraging Is applied on a single profile for averaging.
%
% Inputs:
%    
%   [Required] - X - the profile of the channel to be binned.
%
%                P - Pressure array corresponding to X.
%   
%   [Optional] - Method - The way to find bin values. 'Width' set the bin array based on a
%                   binWidth parameter, it is the default. 'Array' sets the
%                   bin array to be the array entered in the 'binArray'
%                   parameter. 'ArgoRegimes' uses the binsize regimes
%                   that the Argo floats use, more information: 
%                   http://docs.rbr-global.com/L2commandreference/quick-start/integrating-with-a-profiling-float
% 
%                binBy - The array it will be bin wrt... Depth or Pressure.
%                   Defaults to 'Pressure'. Not applicable when 'Method' is
%                   'ArgoRegimes'.
%
%                binArray - An array that determines the bin limits.
%                   Default is [0.5:1:100]. Only used when 'Method' is
%                   'Array'.
%
%                binWidth - the width of the bin. Default is 1. Only used
%                   when 'Method' is 'Width'.
%
% Outputs:
%    Y - Binned array
%    binCenter - Bin center values
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-11-10

%% Input Parse
validBinBy = {'Pressure', 'Depth'};
checkBinBy = @(x) any(validatestring(x,validBinBy));

validMethods = {'Width', 'Array', 'ArgoRegimes'};
checkMethod = @(x) any(validatestring(x,validMethods));

%% Parse Inputs

p = inputParser;
addRequired(p, 'X', @isnumeric);
addRequired(p, 'Pressure', @isnumeric);
addParameter(p, 'Method', 'Width', checkMethod)
addParameter(p, 'binBy', 'Pressure', checkBinBy);
addParameter(p, 'binArray', (0.5:1:100), @isnumeric);
addParameter(p, 'binWidth', 1, @isnumeric);
parse(p, X, Pressure, varargin{:})

% Assign each argument
X = p.Results.X;
Pressure = p.Results.Pressure;
Method = p.Results.Method;
binBy = p.Results.binBy;
binArray = p.Results.binArray;
binWidth = p.Results.binWidth;

%% Binning 
Depth = -gsw_z_from_p(Pressure,52);

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
        
end
  
end






