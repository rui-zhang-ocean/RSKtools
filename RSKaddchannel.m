function [RSK] = RSKaddchannel(RSK, input, channelName, units)

% RSKaddchannel - Add a new channel with defined channel name and
% units. If the new channel already exists in the RSK structure, it
% will overwrite the old one.
%
% Syntax:  [RSK] = RSKaddchannel(RSK, input, channelName, units)
% 
% Inputs: 
%    RSK - Structure containing the logger metadata and data. 
%    
%    input - Structure containing the data to be added.  The data for
%            the new channel must be stored in a field of 'input'
%            called 'values' (i.e., input.values).  If the data is
%            arranged as profiles in the RSK structure, then 'input'
%            must be a 1XN array of structures of where N =
%            length(RSK.data).
% 
%    channelName - name of the added channel
%
%    units - unit of the added channel
%
% Outputs:
%    RSK - Updated structure containing the new channel.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-01-24

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