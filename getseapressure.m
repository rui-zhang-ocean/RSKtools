function [RSKsp, SPcol] = getseapressure(RSK)

% getseapressure - Checks if the RSK has sea pressure. If not it derives
% it, output the RSK structure with sea pressure and the column index.
%
% Syntax:  [RSKsp, SPcol] = getseapressure(RSK)

%
% Inputs: 
%    RSK - Structure containing the logger metadata and data
%
% Outputs:
%    RSKsp - RSK structure containing the sea pressure data
%
%    SPcol - Channel index for sea pressure.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-19

try
    SPcol = getchannelindex(RSK, 'Sea Pressure');
    RSKsp = RSK;
catch
    RSKsp = RSKderiveseapressure(RSK);
    SPcol = getchannelindex(RSKsp, 'Sea Pressure');
end