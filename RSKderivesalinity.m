function [RSK] = RSKderivesalinity(RSK,varargin)

% RSKderivesalinity - Calculate practical salinity.
%
% Syntax:  [RSK] = RSKderivesalinty(RSK,[OPTIONS])
% 
% Derives salinity using either TEOS-10 library
% (http://www.teos-10.org/software.htm) or sea water library
% (http://www.cmar.csiro.au/datacentre/ext_docs/seawater.htm). 
% Default is TEOS-10. The result is added to the RSK data structure, 
% and the channel list is updated. If salinity is already in the RSK 
% data structure (i.e., from Ruskin), it will be overwritten.
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger metadata and data.
%
%    [Optional] - seawaterLibrary - Specify which library to use, should 
%                 be either 'TEOS-10' or 'seawater', default is TEOS-10
%
% Outputs:
%    RSK - Updated structure containing practical salinity.
%
% Examples:
%    rsk = RSKderivesalinity(rsk);
%    OR
%    rsk = RSKderivesalinity(rsk,'seawaterLibrary','seawater');
%
% See also: RSKcalculateCTlag.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2019-11-12


rsksettings = RSKsettings;

validSeawaterLibrary = {'TEOS-10','seawater'};
checkSeawaterLibrary = @(x) any(validatestring(x,validSeawaterLibrary));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'seawaterLibrary', rsksettings.seawaterLibrary, checkSeawaterLibrary);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
seawaterLibrary = p.Results.seawaterLibrary;


checkDataField(RSK)

hasTEOS = ~isempty(which('gsw_SP_from_C'));
hasSW = ~isempty(which('sw_salt'));

if ~hasTEOS && ~hasSW
    RSKerror('Must install TEOS-10 (recommended, download it from http://www.teos-10.org/software.htm) or seawater toolbox.');
elseif ~hasTEOS && strcmpi(seawaterLibrary,'TEOS-10')
    RSKerror('No TEOS-10 toolbox found on your MATLAB pathway. Please download it from http://www.teos-10.org/software.htm or specify seawater toolbox.')
elseif ~hasSW && strcmpi(seawaterLibrary,'seawater')
    RSKerror('No seawater toolbox found on your MATLAB pathway.')
else
    % do nothing
end
    
RSK = addchannelmetadata(RSK, 'sal_00', 'Salinity', 'PSU');
[Ccol,Tcol,Scol] = getchannelindex(RSK,{'Conductivity','Temperature','Salinity'});
[RSKsp, SPcol] = getseapressure(RSK);

castidx = getdataindex(RSK);
for ndx = castidx
    if strcmpi(seawaterLibrary,'TEOS-10')
        salinity = gsw_SP_from_C(RSK.data(ndx).values(:, Ccol), RSK.data(ndx).values(:, Tcol), RSKsp.data(ndx).values(:,SPcol));
    else
        salinity = sw_salt(RSK.data(ndx).values(:, Ccol)/sw_c3515, RSK.data(ndx).values(:, Tcol), RSKsp.data(ndx).values(:,SPcol));
    end
    RSK.data(ndx).values(:,Scol) = salinity;
end

logentry = (['Practical Salinity derived using ' seawaterLibrary ' toolbox.']);
RSK = RSKappendtolog(RSK, logentry);

end
