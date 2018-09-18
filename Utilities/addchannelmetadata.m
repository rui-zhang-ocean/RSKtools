function RSK = addchannelmetadata(RSK, shortName, longName, units)

% ADDCHANNELMETADATA - Add the metadata for a new channel.
%
% Syntax:  [RSK] = ADDCHANNELMETADATA(RSK, shortName, longName, units)
% 
% Adds all the metadata associated with a new channel in the fields,
% channels and instrumentsChannels, of the RSK structure.
%
% Inputs:
%   RSK - Input RSK structure
%
%   shortName - Short name of the new channel
%
%   longName - Full name of the new channel
%            
%   units - Units of the new channel. 
%
% Outputs:
%    RSK - RSK structure containing new channel metadata.
%
% See also: RSKderivedepth, RSKderiveseapressure, RSKderivesalinity.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-05-29

hasChan = any(strcmpi({RSK.channels.longName}, longName));

if ~hasChan
    nchannels = length(RSK.channels);
    RSK.channels(nchannels+1).shortName = shortName;
    RSK.channels(nchannels+1).longName = longName;
    RSK.channels(nchannels+1).units = units;
    
    
    if isfield(RSK, 'instrumentChannels')
        if isfield(RSK.instrumentChannels, 'instrumentID')
            RSK.instrumentChannels(nchannels+1).instrumentID = RSK.instrumentChannels(1).instrumentID;
        end
        if isfield(RSK.instrumentChannels, 'channelStatus')
            RSK.instrumentChannels(nchannels+1).channelStatus = 0;
        end
        if isfield(RSK.instrumentChannels, 'serialID')
            RSK.instrumentChannels(nchannels+1).serialID = RSK.instrumentChannels(1).serialID;
        end
        RSK.instrumentChannels(nchannels+1).channelID = RSK.instrumentChannels(nchannels).channelID+1;
        RSK.instrumentChannels(nchannels+1).channelOrder = RSK.instrumentChannels(nchannels).channelOrder+1;
    end
end

end