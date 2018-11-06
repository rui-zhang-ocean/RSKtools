function [RSK, upidx] = preserveupcast(RSK)

% preserveupcast - Select the data elements with decreasing pressure.
%
% Syntax:  [RSK, upidx] = preserveupcast(RSK)
%
% Keeps only the upcasts in the RSK and returns the index of the upcasts from
% the input RSK structure. 
%
% Inputs:
%    RSK - Structure containing logger data.
%
% Outputs:
%    RSK - Structure only containing upcasts.
%
%    upidx - Index of the data fields from the input RSK structure that 
%          are upcasts.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-10-09


Pcol = getchannelindex(RSK, 'Pressure');
ndata = length(RSK.data);

upidx = NaN(1, ndata);
for ndx = 1:ndata
    pressure = RSK.data(ndx).values(:, Pcol);
    upidx(1, ndx) = getcastdirection(pressure, 'up');
end

if ~any(upidx ==1)
    disp('There are only downcasts in this RSK structure.');
    return;
end

if isfield(RSK.profiles,'downcast')
    RSK.profiles = rmfield(RSK.profiles,'downcast');
end

RSK.profiles.originalindex = RSK.profiles.originalindex(logical(upidx));
RSK.profiles.order = {'up'};
RSK.data = RSK.data(logical(upidx));

RSK.region([RSK.regionCast(strncmpi({RSK.regionCast.type},'Down',4)).regionID]) = [];
if isfield(RSK.region,'label')
    RSK.region(strncmpi({RSK.region.label},'Down',4)) = [];
end
RSK.regionCast(strncmpi({RSK.regionCast.type},'Down',4)) = [];

end