function [RSK] = RSKaddchannel(RSK, input, channelName, units)

% RSKaddchannel - Add a new channel with defined channel name and units.
%
% Syntax:  [RSK] = RSKaddchannel(RSK, input, channelName, units)
% 
% Inputs: 
%    RSK - Structure containing the logger metadata and data. 
%    
%    input - data of the added channel, must be a structure with form of:
%            input(n).values 
% 
%    channelName - Name of the added channel
%
%    units - unit of the added channel
%
% Outputs:
%    RSK - Updated structure containing added data.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-10-30

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'input',@isstruct);
addRequired(p, 'channelName', @ischar);
addRequired(p, 'units', @ischar);
parse(p, RSK, input, channelName, units)

RSK = p.Results.RSK;
input = p.Results.input;
channelName = p.Results.channelName;
units = p.Results.units;

RSK = addchannelmetadata(RSK, channelName, units);
Ncol = getchannelindex(RSK, channelName);
castidx = getdataindex(RSK);
    
for ndx = castidx
   if ~isequal(size(input(ndx).values), size(RSK.data(ndx).tstamp));
       error('The input data structure must be consistent with RSK structure.')
   else
       RSK.data(ndx).values(:,Ncol) = input(ndx).values(:);
   end
end

logentry = [channelName ' (' units ') added to data table by RSKaddchannel'];
RSK = RSKappendtolog(RSK, logentry);


end