function [RSK, upidx] = RSKselectupcast(RSK)

% RSKselectupcast - Selects the datafields that have a decreasing pressure.
%
% Syntax:  [RSKup, isUp] = RSKselectupcast(RSK)
%
% This function only keeps the upcasts in the RSK and returns the index of
% the upcasts from the input RSK structure.
%
% Inputs:
%    RSK - The input RSK structure
%
% Outputs:
%    RSK - The RSK structure only containing upcasts.
%
%    upidx - The index of the data fields from the input RSK structure
%          are upcasts.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-25

Pcol = getchannelindex(RSK, 'Pressure');
ndata = length(RSK.data);

upidx = NaN(1, ndata);
for ndx = 1:ndata
    pressure = RSK.data(ndx).values(:, Pcol);
    upidx(1, ndx) = getcastdirection(pressure, 'up');
end

RSK.data = RSK.data(logical(upidx));

end