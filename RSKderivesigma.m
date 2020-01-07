function [RSK] = RSKderivesigma(RSK, varargin)

% RSKderivesigma - Calculate potential density anomaly.
%
% Syntax: [RSK] = RSKderivesigma(RSK, [OPTIONS])
% 
% Derives potential density anomaly using the TEOS-10 GSW toolbox
% (http://www.teos-10.org/software.htm). The result is added to the RSK 
% data structure, and the channel list is updated. The workflow of the
% function is as below:
%
% 1, Calculate absolute salinity (SA)
%    a) When latitude and longitude data are available (either from
%    optional input or station data in RSK.data.latitude/longitude), the
%    function will call SA = gsw_SA_from_SP(salinity,seapressure,lon,lat)
%    b) When latitude and longitude data are absent, the function will call
%    SA = gsw_SR_from_SP(salinity) assuming that reference salinity equals
%    absolute salinity approximately.
% 2, Calculate potential temperature (pt0)
%    pt0 = gsw_pt0_from_t(absolute salinity,temperature,seapressure)
% 3, Calculate potential density anomaly (sigma0)
%    sigma0 = gsw_sigma0_pt0_exact(absolute salinity,potential temperature)
%
% Note: When geographic information are both available from optional inputs
% and RSK.data structure, the optional inputs will override. The inputs
% latitude/longitude must be either a single value of vector of the same
% length of RSK.data.
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
% Last revision: 2019-07-22


p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'latitude', [], @isnumeric);
addParameter(p, 'longitude', [], @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
latitude = p.Results.latitude;
longitude = p.Results.longitude;
 

checkDataField(RSK)

hasTEOS = ~isempty(which('gsw_sigma0_pt0_exact'));
if ~hasTEOS
    error('Must install TEOS-10 toolbox. Download it from here: http://www.teos-10.org/software.htm');
end

if length(latitude) > 1 && length(RSK.data) ~= length(latitude)
    error('Input latitude must be either one value or vector of the same length of RSK.data')
end

if length(longitude) > 1 && length(RSK.data) ~= length(longitude)
    error('Input longitude must be either one value or vector of the same length of RSK.data')
end

[Tcol,Scol,SPcol] = getchannel_T_S_SP_index(RSK);

RSK = addchannelmetadata(RSK, 'dden00', 'Density Anomaly', 'kg/m³');
DAcol = getchannelindex(RSK, 'Density Anomaly');

castidx = getdataindex(RSK);
for ndx = castidx
    SP = RSK.data(ndx).values(:,SPcol);
    S = RSK.data(ndx).values(:,Scol);
    T = RSK.data(ndx).values(:,Tcol);   
    [lat,lon] = getGeo(RSK,ndx,latitude,longitude);
    DA = derive_DA(S,T,SP,lat,lon);    
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

function  [lat,lon] = getGeo(RSK,ndx,latitude,longitude)
    if ~isempty(latitude) && length(latitude) > 1 
        lat = latitude(ndx);  
    elseif isempty(latitude) && isfield(RSK.data,'latitude')
        lat = RSK.data(ndx).latitude; 
    else
        lat = latitude;    
    end
    
    if ~isempty(longitude) && length(longitude) > 1 
        lon = longitude(ndx);  
    elseif isempty(longitude) && isfield(RSK.data,'longitude')
        lon = RSK.data(ndx).longitude; 
    else
        lon = longitude;    
    end
end

function DA = derive_DA(S,T,SP,lat,lon)
    if isempty(lat) || isempty(lon)
        SA = gsw_SR_from_SP(S); % Assume SA ~= SR
    else
        SA = gsw_SA_from_SP(S,SP,lon,lat);
    end
    pt0 = gsw_pt0_from_t(SA,T,SP);
    DA = gsw_sigma0_pt0_exact(SA,pt0);
end

end
