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
%    [Required] - RSK - Structure containing the logger metadata and data
%
%    [Optional] - pAtm - Atmospheric Pressure. Default is value stored in
%                       parameters table or 10.1325 dbar if unavailable. 
%
% Outputs:
%    RSK - Structure containing the salinity data.
%
% See also: getseapressure, RSKplotprofiles.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-07-04

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'pAtm', [], @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
pAtm = p.Results.pAtm;

if isempty(pAtm)
    pAtm = getatmosphericpressure(RSK);
end

Pcol = getchannelindex(RSK, 'Pressure');



RSK = addchannelmetadata(RSK, 'Sea Pressure', 'dbar');
SPcol = getchannelindex(RSK, 'Sea Pressure');



castidx = getdataindex(RSK);
for ndx = castidx
    seapressure = RSK.data(ndx).values(:, Pcol)- pAtm;
    RSK.data(ndx).values(:,SPcol) = seapressure;
end

end


