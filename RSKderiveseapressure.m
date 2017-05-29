function [RSK, seapressure] = RSKderiveseapressure(RSK, varargin)

% RSKderiveseapressure - Calculate sea pressure and add or replace it in the data table
%
% Syntax:  [RSK, seapressure] = RSKderiveseapressure(RSK, [OPTIONS])
% 
% This function derives sea pressure and fills all of data's fields. If sea
% pressure is already calculated, it will recalculate it and overwrite that
% data column. 
%
% Inputs: 
%    RSK - Structure containing the logger metadata and data
%
% Outputs:
%    RSK - RSK structure containing the salinity data
%
%    seapressure - The sea pressure calculated.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-29

pAtm = getatmosphericpressure(RSK);
Pcol = getchannelindex(RSK, 'Pressure');

%% Calculate Sea Pressure
RSK = addchannelmetadata(RSK, 'Sea Pressure', 'dbar');
SPcol = getchannelindex(RSK, 'Sea Pressure');

dataIdx = setdataindex(RSK);
for ndx = dataIdx
    seapressure = RSK.data(ndx).values(:, Pcol)- pAtm;
    RSK.data(ndx).values(:,SPcol) = seapressure;
end

end
 %fix me: seapressure is the last one calculate only.


