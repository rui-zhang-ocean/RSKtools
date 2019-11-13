function [RSK] = RSKderivesalinity(RSK,varargin)

% RSKderivesalinity - Calculate practical salinity.
%
% Syntax:  [RSK] = RSKderivesalinty(RSK,[OPTIONS])
% 
% Derives salinity using either TEOS-10 GSW toolbox
% (http://www.teos-10.org/software.htm) or sea water toolbox 
% (http://www.cmar.csiro.au/datacentre/ext_docs/seawater.htm). 
% Default is TEOS-10 GSW toolbox. The result is added to the 
% RSK data structure, and the channel list is updated. If 
% salinity is already in the RSK data structure (i.e., from Ruskin),
% it will be overwritten.
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger metadata and data.
%
%    [Optional] - toolbox - Specify which toolbox to use, should be either
%                 'TEOS-10' or 'seawater', default is TEOS-10
%
% Outputs:
%    RSK - Updated structure containing practical salinity.
%
% Examples:
%    rsk = RSKderivesalinity(rsk);
%    OR
%    rsk = RSKderivesalinity(rsk,'toolbox','seawater');
%
% See also: RSKcalculateCTlag.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2019-11-12


validToolbox = {'TEOS-10','seawater'};
checkToolbox = @(x) any(validatestring(x,validToolbox));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'toolbox', 'TEOS-10', checkToolbox);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
toolbox = p.Results.toolbox;


hasTEOS = ~isempty(which('gsw_SP_from_C'));
hasSW = ~isempty(which('sw_salt'));

if ~hasTEOS && ~hasSW
    error('Must install TEOS-10 or seawater toolbox. Download it from here: http://www.teos-10.org/software.htm');
end
    
RSK = addchannelmetadata(RSK, 'sal_00', 'Salinity', 'PSU');
[Ccol,Tcol,Scol] = getchannelindex(RSK,{'Conductivity','Temperature','Salinity'});
[RSKsp, SPcol] = getseapressure(RSK);

castidx = getdataindex(RSK);
for ndx = castidx
    if strcmpi(toolbox,'TEOS-10')
        salinity = gsw_SP_from_C(RSK.data(ndx).values(:, Ccol), RSK.data(ndx).values(:, Tcol), RSKsp.data(ndx).values(:,SPcol));
        logentry = ('Practical Salinity derived using TEOS-10 GSW toolbox.');
    else
        salinity = sw_salt(RSK.data(ndx).values(:, Ccol)/sw_c3515, RSK.data(ndx).values(:, Tcol), RSKsp.data(ndx).values(:,SPcol));
        logentry = ('Practical Salinity derived using seawater toolbox.');
    end
    RSK.data(ndx).values(:,Scol) = salinity;
end

RSK = RSKappendtolog(RSK, logentry);

end
