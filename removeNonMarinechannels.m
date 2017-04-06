function [RSK, isDerived] = removeNonMarinechannels(RSK)

% renameAdditionalTemperatureChannels - Rename temperature channels that
%          requires a more descriptive name
%
% Syntax:  [RSK] = renameAdditionalTemperatureChannels(RSK)
%
% renameAdditionalTemperatureChannels checks for shortnames that correspond
% to temperature channels that require a more descriptive name because they
% are not the main temperature channel. These are temp04, temp05, temp10
% and temp13.
%
% Inputs:
%    RSK - An RSK structure
%
% Outputs:
%    RSK - An RSK structure with only marine channels.
%
%    isDerived - A logical index describing which channels are non-marine.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-04-06

%% readheaderfull
if iscompatibleversion(RSK, 1, 8, 9) && ~strcmp(RSK.dbInfo(end).type, 'EP')
    isDerived = logical([RSK.instrumentChannels.channelStatus]);% hidden and derived channels have a non-zero channelStatus
    RSK.instrumentChannels(isDerived) = [];
else
    results = mksqlite('select isDerived from channels');
    isDerived = logical([results.isDerived]); % some files may not have channelStatus
end
RSK.channels(isDerived) = [];  
end


