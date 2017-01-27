function [RSK, salinity] = RSKcalculatesalinity(RSK)

% RSKcalculatesalinity - Calculate salinity using TEOS-10, conductivity,
% temperature and pressure
%
% Syntax:  [RSK] = RSKcalculatesalintiy(RSK, [OPTIONS])
% 
% This function calculates salinity using the TEOS-10 toolbox and fills the
% appropriate fields in channels field. If salinity is already calculated,
% it will recalculate it and overwrite that data column.
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
% Last revision: 2017-01-26

data = RSK.data;

%% Check if Salinity ,TEOS-10 and CTD data are available.
hasS = any(strcmp({RSK.channels.longName}, 'Salinity'));
 
hasTEOS = exist('gsw_SP_from_C', 'file') == 2;
nchannels = length(RSK.channels);
if nchannels >= 3
    hasCTP = strcmpi(RSK.channels(1).longName, 'Conductivity') & strcmpi(RSK.channels(2).longName, 'Temperature') & strcmpi(RSK.channels(3).longName, 'Pressure');
else 
    hasCTP = 0;
end


%% Calculate Salinity
% Does the RSK have all 3 of conductivity, temperature, and pressure, but not salinity?
% If so, calculate practical salinity using TEOS-10 (if it exists)
if ~hasS && hasCTP && hasTEOS
    if sum(strcmpi({RSK.channels.longName}, 'Salinity')) == 0
        RSK.channels(nchannels+1).longName = 'Salinity';
        RSK.channels(nchannels+1).units = 'PSU';
        % update the instrumentChannels info for the new "channel"
        if ~strcmpi(RSK.dbInfo(end).type, 'EasyParse')
            try
                RSK.instrumentChannels(nchannels+1).instrumentID = RSK.instrumentChannels(1).instrumentID;
            catch
            end
            if isfield(RSK.instrumentChannels, 'channelStatus')
                RSK.instrumentChannels(nchannels+1).channelStatus = 0;
            end
            RSK.instrumentChannels(nchannels+1).channelID = RSK.instrumentChannels(nchannels).channelID+1;
            RSK.instrumentChannels(nchannels+1).channelOrder = RSK.instrumentChannels(nchannels).channelOrder+1;
        end
    end
    salinity = gsw_SP_from_C(data.values(:, 1), data.values(:, 2), data.values(:, 3)- 10.1325);
    RSK.data.values = [data.values salinity];
elseif hasS && hasCTP && hasTEOS
    salinity = gsw_SP_from_C(data.values(:, 1), data.values(:, 2), data.values(:, 3)- 10.1325);
    RSK.data.values(:,end) = salinity;
end


end



