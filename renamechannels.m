function RSK = renamechannels(RSK)

%RENAMECHANNELS - Rename channels that require a more descriptive name.
%
% Syntax:  [RSK] = RENAMECHANNELS(RSK)
%
% Checks for shortnames that correspond to channels that require a more
% descriptive name and replaces the longName. These are doxy, temp04,
% temp05, temp10, temp13 and pres08. 
% 
% Inputs:
%    RSK - Structure containing metadata.
%
% Outputs:
%    RSK - Structure with decriptive unique channel names if required. 
%
% See also: RSKopen.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-21

shortName = {RSK.channels.shortName};

idx = find(strcmpi(shortName, 'temp04'));
for ndx = 1:length(idx)
    RSK.channels(idx(ndx)).longName = ['Temperature' num2str(ndx)];
end

idx = (strcmpi(shortName, 'temp05') | strcmpi(shortName, 'temp10'));
if any(idx)
    RSK.channels(idx).longName = 'Pressure Gauge Temperature';
end


idx = strcmpi(shortName, 'temp13');
if any(idx)
    RSK.channels(idx).longName = 'External Cabled Temperature';
end

idx = strcmpi(shortName, 'doxy09');
if any(idx)
    RSK.channels(idx).longName = 'Dissolved O2';
end

idx = strcmpi(shortName, 'pres08');
if any(idx)
    RSK.channels(idx).longName = 'Sea Pressure';
end
end