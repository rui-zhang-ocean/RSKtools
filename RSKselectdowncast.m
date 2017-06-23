function [RSK, downidx] = RSKselectdowncast(RSK)

%RSKselectdowncast - Keep the data elements that have a increasing pressure.
%
% Syntax:  [RSK, isDown] = RSKselectdowncast(RSK)
%
% Keeps the downcasts in the RSK and returns the index of the downcasts
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
% Last revision: 2017-06-23

Pcol = getchannelindex(RSK, 'Pressure');
ndata = length(RSK.data);



downidx = NaN(1, ndata);
for ndx = 1:ndata
    pressure = RSK.data(ndx).values(:, Pcol);
    downidx(1, ndx) = getcastdirection(pressure, 'down');
end



RSK.profiles.originalindex = RSK.profiles.originalindex(logical(downidx));
RSK.data = RSK.data(logical(downidx));

end