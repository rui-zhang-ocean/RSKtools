function shortName = getchannelshortname(longName)

% getchannelshorname - Return short name for given channel long name.
%
% Syntax:  shortName = getchannelshortname(longName)
%
% Inputs:
%   longName - longName of the channels
%
% Outputs:
%   shorName - shorName of the channels
%
% See also: getchannelindex
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2019-05-16


channelList =   {'Conductivity','Temperature','Pressure','Sea Pressure','Depth',...
                 'Salinity','Velocity','Dissolved O2','Buoyancy Frequency Squared','Stability',...
                 'Turbidity','PAR','Chlorophyll','Acceleration','Specific conductivity',...
                 'BPR pressure','BPR temperature','Partial CO2 pressure','Period','pH',...
                 'Transmittance','Voltage','Distance','Speed of sound','Density Anomaly',...
                 'Significant wave height','Significant wave period','1/10 wave height','1/10 wave period','Maximum wave height',...
                 'Maximum wave period','Average wave height','Average wave period','Wave energy','Tidal slope'};
shortNameList = {'cond00','temp00','pres00','pres08','dpth01',...
                 'sal_00','pvel00','ddox00','buoy00','stbl00',...
                 'turb00','par_01','fluo01','acc_00','scon00',...
                 'bpr_08','bpr_09','pco200','peri00','ph__00',...
                 'tran00','volt00','alti00','sos_00','dden00',...
                 'wave00','wave01','wave02','wave03','wave04',...
                 'wave05','wave06','wave07','wave08','slop00'};
 
if ischar(longName)
    longName = {longName};
end

shortName = cell(size(longName));
[~,ind1,ind2] = intersect(longName,channelList,'stable');
shortName(ind1) = shortNameList(ind2);
[shortName{cellfun(@isempty,shortName)}] = deal('cnt_00');
             
end
