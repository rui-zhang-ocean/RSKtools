function [RSK, depth] = RSKderivedepth(RSK, varargin)

%RSKderivedepth - Calculate depth from pressure.
%
% Syntax:  [RSK, depth] = RSKderivedepth(RSK, [OPTION])
% 
% Calculates depth from pressure and adds the channel metadata in the
% appropriate fields. If the data elements already have a 'depth' channel,
% it will be replaced. If TEOS-10 toolbox is installed it will use it
% http://www.teos-10.org/software.htm#1. Otherwise it is calculated using
% the Saunders & Fofonoff method.  
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger metadata and data
%
%    [Optional] - latitude - Location of the pressure measurement in
%                       decimal degrees north. Default is 45. 
%
% Outputs:
%    RSK - RSK structure containing the depth data
%
%    depth - Vector containing depth in meters.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-22

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addOptional(p, 'latitude', 45, @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
latitude = p.Results.latitude;



RSK = addchannelmetadata(RSK, 'Depth', 'm');
Dcol = getchannelindex(RSK, 'Depth');
[RSKsp, SPcol] = getseapressure(RSK);



castidx = getdataindex(RSK);
for ndx = castidx
    seapressure = RSKsp.data(ndx).values(:, SPcol);
    depth = calculatedepth(seapressure, latitude);
    RSK.data(ndx).values(:,Dcol) = depth;
end

end