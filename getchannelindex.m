function channelIdx = checkchannels(RSK, channel)

% checkchannel - Check if channels longNames are in RSK channels field.
%
% Syntax:  [channelIdx] = checkchannel(RSK, channel)
% 
% A helper function used to check if the channels field in the RSK
% structure has the channels that are requested.
%
% Inputs:
%   RSK - the input RSK structure
%
%   channel - The channel longNames to be check.
%
% Outputs:
%    profileIdx - An array containing the index of the profiles with data.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-04-05

if strcmpi(channel, 'all')
    channel = {RSK.channels.longName};
elseif ~iscell(channel)
    channel = {channel};
end

channelIdx = [];
for chanName = channel
    if any(strcmpi(chanName{1}, {RSK.channels.longName}));
        chanCol = find(strcmpi(chanName{1}, {RSK.channels.longName}));
        channelIdx = [channelIdx, chanCol(1)];
    else
        error(['RSK channels does not contain ' chanName{1}]);
    end
end
    
end