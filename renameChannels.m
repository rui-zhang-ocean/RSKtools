function RSK = renameChannels(RSK)

% renameChannels - Rename channels that requires a more descriptive name
%
% Syntax:  [RSK] = renameChannels(RSK)
%
% renameChannels checks for shortnames that correspond
% to temperature channels that require a more descriptive name because they
% are not the main temperature channel. These are doxy, temp04, temp05, temp10
% and temp13.
%
% Inputs:
%    RSK - An RSK structure
%
% Outputs:
%    RSK - An RSK structure with decriptive unique channel names if
%      required.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-03

shortName = {RSK.channels.shortName};
if strcmpi(shortName, 'temp04')
    idx = find(strcmpi(shortName, 'temp04'));
    for ndx = 1:length(idx)
        RSK.channels(idx(ndx)).longName = ['Temperature' num2str(ndx)];
    end
end

if any(strcmpi(shortName, 'temp05'))   
    idx = find(strcmpi(shortName, 'temp05'));
    RSK.channels(idx(ndx)).longName = 'Pressure Gauge Temperature';
elseif any(strcmpi(shortName, 'temp10'))
    idx = strcmpi(shortName, 'temp10');
    RSK.channels(idx).longName = 'Pressure Gauge Temperature';
end    

if any(strcmpi(shortName, 'temp13'))
    idx = strcmpi(shortName, 'temp13');
    RSK.channels(idx).longName = 'External Cabled Temperature';
end

if any(strncmpi(shortName, 'doxy', 4))
    idx = strncmpi(shortName, 'doxy', 4);
    RSK.channels(idx).longName = 'Dissolved O2';
end
end