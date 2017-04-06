function [RSK, isDerived] = removeNonMarinechannels(RSK)

% removeNonMarinechannels - Remove channels that are hidden or derived from
%         RSK channels.
%
% Syntax:  [RSK, isDerived] = removeNonMarinechannels(RSK)
%
% removeNonMarinechannels will remove the hidden or derived channels from the channels table
% and return a logical index vector indicating where they are. They are
% also removed from instrumentChannels if available.
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

if iscompatibleversion(RSK, 1, 8, 9) && ~strcmp(RSK.dbInfo(end).type, 'EP')
    isDerived = logical([RSK.instrumentChannels.channelStatus]);% hidden and derived channels have a non-zero channelStatus
    RSK.instrumentChannels(isDerived) = [];
    
else
    results = mksqlite('select isDerived from channels');
    isDerived = logical([results.isDerived]); 
    
end


RSK.channels(isDerived) = [];  


end


