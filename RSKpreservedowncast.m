function [RSK, downidx] = RSKpreservedowncast(RSK)

% RSKpreservedowncast - Keep the data elements with an increasing pressure.
%
% Syntax:  [RSK, downidx] = RSKpreservedowncast(RSK)
%
% Keeps only the downcasts in the RSK and returns the index of the downcasts
% from the input RSK structure. 
%
% Inputs:
%    RSK - Structure containing logger data.
%
% Outputs:
%    RSK - Structure only containing downcast data.
%
%    downidx - Index of the data fields from the input RSK structure that
%          are downcasts. 
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-10-09


Pcol = getchannelindex(RSK, 'Pressure');
ndata = length(RSK.data);

downidx = NaN(1, ndata);
for ndx = 1:ndata
    pressure = RSK.data(ndx).values(:, Pcol);
    downidx(1, ndx) = getcastdirection(pressure, 'down');
end

if ~any(downidx ==1)
    disp('No downcasts in this RSK structure.');
    return;
end

RSK.profiles.originalindex = RSK.profiles.originalindex(logical(downidx));
RSK.profiles.order = {'down'};
RSK.data = RSK.data(logical(downidx));

RSK.regionCast(strncmpi({RSK.regionCast.type},'Up',2)) = [];
RSK.region([RSK.regionCast(strncmpi({RSK.regionCast.type},'Up',2)).regionID]) = [];


end