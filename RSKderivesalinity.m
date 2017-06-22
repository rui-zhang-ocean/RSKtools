function [RSK] = RSKderivesalinity(RSK)

%RSKderivesalinity - Calculate salinity.
%
% Syntax:  [RSK] = RSKderivesalinty(RSK)
% 
% Derives salinity using the TEOS-10 toolbox and fills the appropriate
% fields in channels field and data. If salinity is already calculated, it
% will recalculate it and overwrite that data column. This function
% requires TEOS-10 to be downloaded and in the path
% (http://www.teos-10.org/software.htm).
%
% Inputs: 
%    RSK - Structure containing the logger metadata and data.         
%
% Outputs:
%    RSK - Structure containing the salinity data.
%
% See also: RSKcalculateCTlag.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-22

if isempty(which('gsw_SP_from_C'))
    error('RSKtools requires TEOS-10 toolbox to derive salinity. Download it here: http://www.teos-10.org/software.htm');
end
    


Ccol = getchannelindex(RSK, 'Conductivity');
Tcol = getchannelindex(RSK, 'Temperature');



RSK = addchannelmetadata(RSK, 'Salinity', 'mS/cm');
Scol = getchannelindex(RSK, 'Salinity');
[RSKsp, SPcol] = getseapressure(RSK);



castidx = getdataindex(RSK);
for ndx = castidx
    salinity = gsw_SP_from_C(RSK.data(ndx).values(:, Ccol), RSK.data(ndx).values(:, Tcol), RSKsp.data(ndx).values(:,SPcol));
    RSK.data(ndx).values(:,Scol) = salinity;
end

end



