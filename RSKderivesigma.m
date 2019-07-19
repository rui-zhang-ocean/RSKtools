function [RSK] = RSKderivesigma(RSK, varargin)

% RSKderivesigma - Calculate potential density anomaly.
%
% Syntax: [RSK] = RSKderivesigma(RSK, [OPTIONS])
% 
% Derives potential density anomaly using the TEOS-10 GSW toolbox
% (http://www.teos-10.org/software.htm). The result is added to the
% RSK data structure, and the channel list is updated. 
%
% Inputs: 
%   [Required] - RSK - Structure containing the logger metadata and data
%
%   [Optional] - latitude - Latitude in decimal degrees north [-90 ... +90]
%
%              - longitude - Longitude in decimal degrees east [-180 ... +180]
%
% Outputs:
%    RSK - Updated structure containing potential density anomaly.
%
% See also: RSKderivesalinity.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2019-07-18


p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'latitude', [], @isnumeric);
addParameter(p, 'longitude', [], @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
latitude = p.Results.latitude;
longitude = p.Results.longitude;
 

hasTEOS = ~isempty(which('gsw_sigma0_pt0_exact'));
if ~hasTEOS
    error('Must install TEOS-10 toolbox. Download it from here: http://www.teos-10.org/software.htm');
end

[Tcol,Scol,SPcol] = getchannel_T_S_SP_index(RSK);

RSK = addchannelmetadata(RSK, 'dden00', 'Density Anomaly', 'kg/m³');
DAcol = getchannelindex(RSK, 'Density Anomaly');

castidx = getdataindex(RSK);
for ndx = castidx
    SP = RSK.data(ndx).values(:,SPcol);
    S = RSK.data(ndx).values(:,Scol);
    T = RSK.data(ndx).values(:,Tcol);   
    DA = derive_DA(S,T,SP,latitude,longitude);    
    RSK.data(ndx).values(:,DAcol) = DA;
end

logentry = ('Potential density anomaly derived using TEOS-10 GSW toolbox.');
RSK = RSKappendtolog(RSK, logentry);


%% Nested functions
function [Tcol,Scol,SPcol] = getchannel_T_S_SP_index(RSK)
    Tcol = getchannelindex(RSK, 'Temperature');
    try
        Scol = getchannelindex(RSK, 'Salinity');
    catch
        error('RSKderivesigma requires practical salinity. Use RSKderivesalinity...');
    end
    try
        SPcol = getchannelindex(RSK, 'Sea Pressure');
    catch
        error('RSKderivesigma requires sea pressure. Use RSKderiveseapressure...');
    end
end

function DA = derive_DA(S,T,SP,latitude,longitude)
    if isempty(latitude) || isempty(longitude)
        SA = gsw_SR_from_SP(S); % Assume SA ~= SR
    else
        SA = gsw_SA_from_SP(S,SP,longitude,latitude);
    end
    pt0 = gsw_pt0_from_t(SA,T,SP);
    DA = gsw_sigma0_pt0_exact(SA,pt0);
end

end
