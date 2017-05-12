function [RSK, salinity] = RSKderivesalinity(RSK, varargin)

% RSKderivesalinity - Calculate salinity and add it or replace it in the data table
%
% Syntax:  [RSK] = RSKderivesalinty(RSK, [OPTIONS])
% 
% This function derives salinity using the TEOS-10 toolbox and fills the
% appropriate fields in channels field and data or profile field. If salinity is
% already calculated, it will recalculate it and overwrite that data
% column. 
% This function requires TEOS-10 to be downloaded and in the path
% (http://www.teos-10.org/software.htm)
%
%
% Inputs: 
%    [Required] - RSK - Structure containing the logger metadata and data
%
%               
%    [Optional] - series - Specifies the series to be filtered. Either 'data'
%                     or 'profile'. Default is 'data'.
%            
%                 direction - 'up' for upcast, 'down' for downcast, or 'both' for
%                     all. Default is 'down'.
%
% Outputs:
%    RSK - RSK structure containing the salinity data
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-08

validSeries = {'profile', 'data'};
checkSeriesName = @(x) any(validatestring(x,validSeries));

validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'series', 'data', checkSeriesName)
addParameter(p, 'direction', 'down', checkDirection);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
series = p.Results.series;
direction = p.Results.direction;

if strcmpi(series, 'profile')
    if strcmpi(direction, 'both')
        direction = {'down', 'up'};
    else
        direction = {direction};
    end
end

%% Check TEOS-10 and CTP data are available.
 
if isempty(which('gsw_SP_from_C'))
    error('RSKtools requires TEOS-10 toolbox to derive salinity. Download it here: http://www.teos-10.org/software.htm');
end
    
Ccol = getchannelindex(RSK, 'Conductivity');
Tcol = getchannelindex(RSK, 'Temperature');
try 
    spCol = getchannelindex(RSK, 'Sea Pressure');
catch
    pCol = getchannelindex(RSK, 'Pressure');
end


%% Calculate Salinity
RSK = addchannelmetadata(RSK, 'Salinity', 'mS/cm');
Scol = getchannelindex(RSK, 'Salinity');

switch series
    case 'data'
        data = RSK.data;
        if exist('spCol',1)
            pressure = data.values(:, spCol);
        else
            pressure = data.values(:, pCol) - 10.1325;
        end
        salinity = gsw_SP_from_C(data.values(:, Ccol), data.values(:, Tcol), pressure);
        RSK.data.values(:,Scol) = salinity;
    case 'profile'
        for dir = direction
            profileNum = [];
            profileIdx = checkprofiles(RSK, profileNum, dir{1});
            castdir = [dir{1} 'cast'];
            for ndx = profileIdx
                data = RSK.profiles.(castdir).data(ndx);
                if exist('spCol',1)
                    pressure = data.values(:, spCol);
                else
                    pressure = data.values(:, pCol) - 10.1325;
                end
                salinity = gsw_SP_from_C(data.values(:, Ccol), data.values(:, Tcol), pressure);
                RSK.profiles.(castdir).data(ndx).values(:,Scol) = salinity;
            end
        end
end

end



