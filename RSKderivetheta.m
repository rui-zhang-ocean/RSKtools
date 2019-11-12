function RSK = RSKderivetheta(RSK)

% RSKderivetheta - Calculate potential temperature.
%
% Syntax: RSK = RSKderivetheta(RSK)
% 
% Derives potential temperature using the TEOS-10 GSW toolbox
% (http://www.teos-10.org/software.htm). The result is added to the RSK 
% data structure, and the channel list is updated. 
%
% Note: Absolute Salinity is computed as intermediate variables. Here it is
% assumed that the Absolute Salinity (SA) anomaly is zero, which means that
% SA = SR (Reference Salinity).  This is probably the best approach near
% the coast (see http://www.teos-10.org/pubs/TEOS-10_Primer.pdf).
%
% Inputs: 
%    RSK - Structure containing the logger metadata and data
%
% Outputs:
%    RSK - Updated structure containing potential temperature.
%
% See also: RSKderivesalinity, RSKderivesigma.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2019-11-12


p = inputParser;
addRequired(p, 'RSK', @isstruct);
parse(p, RSK)

RSK = p.Results.RSK;
 

hasTEOS = ~isempty(which('gsw_pt0_from_t'));
if ~hasTEOS
    error('Must install TEOS-10 toolbox. Download it from here: http://www.teos-10.org/software.htm');
end

[Tcol,Scol,SPcol] = getchannel_T_S_SP_index(RSK);

RSK = addchannelmetadata(RSK, 'cnt_00', 'Potential Temperature', '°C'); % cnt_00 will need update when Ruskin sets up a shortname for theta
PTcol = getchannelindex(RSK, 'Potential Temperature');

castidx = getdataindex(RSK);
for ndx = castidx
    SP = RSK.data(ndx).values(:,SPcol);
    S = RSK.data(ndx).values(:,Scol);
    T = RSK.data(ndx).values(:,Tcol);   
    SA = gsw_SR_from_SP(S);
    PT = gsw_pt0_from_t(SA, T, SP);    
    RSK.data(ndx).values(:,PTcol) = PT;
end

logentry = ('Potential temperature derived using TEOS-10 GSW toolbox.');
RSK = RSKappendtolog(RSK, logentry);


%% Nested functions
function [Tcol,Scol,SPcol] = getchannel_T_S_SP_index(RSK)
    Tcol = getchannelindex(RSK, 'Temperature');
    try
        Scol = getchannelindex(RSK, 'Salinity');
    catch
        error('RSKderivetheta requires practical salinity. Use RSKderivesalinity...');
    end
    try
        SPcol = getchannelindex(RSK, 'Sea Pressure');
    catch
        error('RSKderivetheta requires sea pressure. Use RSKderiveseapressure...');
    end
end
end
