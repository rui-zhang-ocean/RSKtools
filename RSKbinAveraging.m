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
%   [Optional] - BinBy - The array it will be bin wrt... Depth or Pressure.
%                Defaults to 'pressure'.
%
%                binWidth - the width of the bin. Default is 1.
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

validBinBy = {'pressure', 'depth'};
checkBinBy = @(x) any(validatestring(x,validBinBy));

%% Parse Inputs

p = inputParser;
addRequired(p, 'X', @isnumeric);
addRequired(p, 'Pressure', @isnumeric);
addParameter(p, 'BinBy', 'pressure', checkBinBy);
addParameter(p, 'binWidth', 1, @isnumeric);
parse(p, X, Pressure, varargin{:})

% Assign each argument
X = p.Results.X;
Pressure = p.Results.Pressure;
BinBy = p.Results.BinBy;
binWidth = p.Results.binWidth;

%% Binning 

switch BinBy
  case 'pressure'
    binCenter = [binWidth:binWidth:ceil(max(Pressure))]';
  case 'depth'
    Depth = -gsw_z_from_p(Pressure,52);
    binCenter = [binWidth:binWidth:ceil(max(Depth))]';
end

%  initialize the binned output field  
Y = NaN(length(binCenter),1);

for k=1:length(binCenter)
    
  switch BinBy
    case 'pressure'
      kk = (Pressure >= binCenter(k)-binWidth/2) & (Pressure < binCenter(k)+binWidth/2);
    case 'depth'
      kk = (Depth >= binCenter(k)-binWidth/2) & (Depth < binCenter(k)+binWidth/2);
  end
  
  Y(k) = nanmean(X(kk));
  
end
end





