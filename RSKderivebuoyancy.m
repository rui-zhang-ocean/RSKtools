function [RSK] = RSKderivebuoyancy(RSK,varargin)

% RSKderivebuoyancy - Calculate buoyancy frequency N^2 and stability E.
%
% Syntax:  [RSK] = RSKderivebuoyancy(RSK,[OPTIONS])
% 
% Derives buoyancy frequency and stability using the TEOS-10 GSW toolbox
% (http://www.teos-10.org/software.htm). The result is added to the
% RSK data structure, and the channel list is updated. 
%
% Inputs: 
%   [Required] - RSK - Structure containing the logger metadata and data
%
%   [Optional] - latitude - Latitude in decimal degrees north [-90 ... +90]
%                If latitude is not provides, a default gravitational
%                acceleration 9.7963 will be used (see gsw_grav)
%
% Outputs:
%    RSK - Updated structure containing buoyancy frequency and stability.
%
% See also: RSKderivesalinity.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-07-17


p = inputParser;
addRequired(p, 'RSK', @isstruct);
addOptional(p, 'latitude', [], @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
latitude = p.Results.latitude;
 
hasTEOS = ~isempty(which('gsw_Nsquared'));
if ~hasTEOS
    error('Must install TEOS-10 toolbox. Download it from here: http://www.teos-10.org/software.htm');
end
    
Tcol = getchannelindex(RSK, 'Temperature');
try
    Scol = getchannelindex(RSK, 'Salinity');
catch
    error('RSKderivebuoyance requires salinity channel. Use RSKderivesalinity...');
end
try
    SPcol = getchannelindex(RSK, 'Sea Pressure');
catch
    error('RSKcalculatevelocity requires sea pressure channel. Use RSKderiveseapressure...');
end

RSK = addchannelmetadata(RSK, 'Buoyance Frequency', 's-2');
RSK = addchannelmetadata(RSK, 'Stability', 'm-1');
N2col = getchannelindex(RSK, 'Buoyance Frequency');
STcol = getchannelindex(RSK, 'Stability');


castidx = getdataindex(RSK);
for ndx = castidx
    SA = gsw_SA_from_SP(RSK.data(ndx).values(:, Scol), RSK.data(ndx).values(:, SPcol), 20, 58); % Use Baltic sea lat/lon for now
    CT = gsw_CT_from_t(SA, RSK.data(ndx).values(:,Tcol), RSK.data(ndx).values(:,SPcol));
    if isempty(latitude)
        [N2_mid, p_mid] = gsw_Nsquared(SA, CT, RSK.data(ndx).values(:,SPcol));
        grav = gsw_grav(RSK.data(ndx).values(:,SPcol));
    else
        [N2_mid, p_mid] = gsw_Nsquared(SA, CT, RSK.data(ndx).values(:,SPcol), latitude);
        grav = gsw_grav(latitude, RSK.data(ndx).values(:,SPcol));
    end
    N2 = interp1(p_mid, N2_mid, RSK.data(ndx).values(:,SPcol), 'linear', 'extrap');
    RSK.data(ndx).values(:,N2col) = N2;
    ST = -N2./grav;
    RSK.data(ndx).values(:,STcol) = ST;
end

logentry = ('Buoyancy frequency and stability derived using TEOS-10 GSW toolbox.');
RSK = RSKappendtolog(RSK, logentry);

end


