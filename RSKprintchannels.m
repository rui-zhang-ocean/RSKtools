function RSKprintchannels(RSK)

% RSKprintchannels - Display channel names and units in rsk structure
%
% Syntax:  RSKprintchannels(RSK)
%
% Inputs: 
%    RSK - Input RSK structure
%
% Outputs:
%    Printed channel names and units in MATLAB command window
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2020-02-05


channelTable = struct2table(RSK.channels);
channelTable = channelTable(:,{'longName','units'});
channelTable.Properties.VariableNames = {'channels','units'};

disp(channelTable)


end
