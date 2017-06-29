function [RSK] = RSKderiveseapressure(RSK, varargin)

%RSKderiveseapressure - Calculate sea pressure.
%
% Syntax:  [RSK] = RSKderiveseapressure(RSK, [OPTIONS])
% 
% Derives sea pressure and fills all of data's elements and channel
% metadata. If sea pressure already exists, it recalculates it and
% overwrites that data column.  
%
% Inputs: 
%    RSK - Structure containing the logger metadata and data.
%
% Outputs:
%    RSK - Structure containing the salinity data.
%
% See also: getseapressure, RSKplotprofiles.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-22

pAtm = getatmosphericpressure(RSK);
Pcol = getchannelindex(RSK, 'Pressure');



RSK = addchannelmetadata(RSK, 'Sea Pressure', 'dbar');
SPcol = getchannelindex(RSK, 'Sea Pressure');



castidx = getdataindex(RSK);
for ndx = castidx
    seapressure = RSK.data(ndx).values(:, Pcol)- pAtm;
    RSK.data(ndx).values(:,SPcol) = seapressure;
end

end


