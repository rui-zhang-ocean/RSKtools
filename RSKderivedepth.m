function [RSK, depth] = RSKderivedepth(RSK, latitude)

% RSKderivedepth - Calculate depth from pressure and add it or replace it
% in the data table.
%
% Syntax:  [RSK, depth] = RSKderivedepth(RSK, latitude, latitude)
% 
% 
% Calculate depth from pressure. If TEOS-10 toolbox is installed it will
% use it http://www.teos-10.org/software.htm#1. Otherwise it is calculated
% using the Saunders & Fofonoff method. 
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger metadata and data
%
%    [Optional] - latitude - Latitude at the location of the pressure measurement in
%                       decimal degrees north. Default is 45. 
%
% Outputs:
%    RSK - RSK structure containing the depth data.
%
%    depth - depth - a vector containing depths in meters.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-19

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addOptional(p, 'latitude', 45, @isnumeric);
parse(p, RSK, latitude)

% Assign each input argument
RSK = p.Results.RSK;
latitude = p.Results.latitude;

RSK = addchannelmetadata(RSK, 'Depth', 'm');
Dcol = getchannelindex(RSK, 'Depth');
[RSKsp, SPcol] = getseapressure(RSK);

dataIdx = setdataindex(RSK);
for ndx = dataIdx
    seapressure = RSKsp.data(ndx).values(:, SPcol);
    depth = calculatedepth(seapressure, latitude);
    RSK.data(ndx).values(:,Dcol) = depth;
end

end