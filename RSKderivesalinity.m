function [RSK, salinity] = RSKderivesalinity(RSK)

% RSKderivesalinity - Calculate salinity and add it or replace it in the data table
%
% Syntax:  [RSK] = RSKderivesalinty(RSK, [OPTIONS])
% 
% This function derives salinity using the TEOS-10 toolbox and fills the
% appropriate fields in channels field and data field. If salinity is
% already calculated, it will recalculate it and overwrite that data
% column. 
% This function requires TEOS-10 to be downloaded and in the path
% (http://www.teos-10.org/software.htm)
%
% Inputs:
%    RSK - the input RSK structure
%
% Outputs:
%    RSK - RSK structure containing the salinity data
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-03-27

data = RSK.data;

%% Check TEOS-10 and CTP data are available.
 
if isempty(which('gsw_SP_from_C'))
    error('RSKtools required TEOS-10 toolbox to derive salinity. Download it here: http://www.teos-10.org/software.htm')
end
    
if ~strcmpi(RSK.channels(1).longName, 'Conductivity') && ~strcmpi(RSK.channels(2).longName, 'Temperature') && ~strcmpi(RSK.channels(3).longName, 'Pressure');
    error('Conductivity, Temperature and Pressure are required to calculate Salinity')
end


%% Calculate Salinity
hasS = any(strcmp({RSK.channels.longName}, 'Salinity'));
nchannels = length(RSK.channels);

if ~hasS
    RSK.channels(nchannels+1).longName = 'Salinity';
    RSK.channels(nchannels+1).units = 'PSU';
    % update the instrumentChannels info for the new "channel"
    if isfield(RSK, 'instrumentChannels')
        if isfield(RSK.instrumentChannels, 'instrumentID')
            RSK.instrumentChannels(nchannels+1).instrumentID = RSK.instrumentChannels(1).instrumentID;
        end
        if isfield(RSK.instrumentChannels, 'channelStatus')
            RSK.instrumentChannels(nchannels+1).channelStatus = 0;
        end
        RSK.instrumentChannels(nchannels+1).channelID = RSK.instrumentChannels(nchannels).channelID+1;
        RSK.instrumentChannels(nchannels+1).channelOrder = RSK.instrumentChannels(nchannels).channelOrder+1;
    end
    salinity = gsw_SP_from_C(data.values(:, 1), data.values(:, 2), data.values(:, 3)- 10.1325);
    RSK.data.values = [data.values salinity];
    
elseif hasS
    Scol = strcmp({RSK.channels.longName}, 'Salinity');
    salinity = gsw_SP_from_C(data.values(:, 1), data.values(:, 2), data.values(:, 3)- 10.1325);
    RSK.data.values(:,Scol) = salinity;
end


end



