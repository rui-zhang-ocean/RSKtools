function RSK = readchannels(RSK, varargin)

%READCHANNELS - Populate the channels table.
%
% Syntax:  [RSK] = READCHANNELS(RSK)
%
% If available, uses the instrumentChannels table to read the channels with
% matching channelID. Otherwise, directly reads the metadata from the
% channels table. Only returns non-marine channels, unless it is a
% EPdesktop file, and enumerates duplicate channel names.
%
% Inputs:
%    [Required] - RSK - Structure opened using RSKopen.m.
%
%    [Optional] - rhc - Read hidden channel or not, 1 or 0.
%
% Outputs:
%    RSK - Structure containing channels.
%
% See also: readstandardtables, RSKopen.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-07-10

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addOptional(p, 'rhc', 0, @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
rhc = p.Results.rhc;

tables = doSelect(RSK, 'SELECT name FROM sqlite_master WHERE type="table"');

if any(strcmpi({tables.name}, 'instrumentChannels'))
    RSK.instrumentChannels = doSelect(RSK, 'select * from instrumentChannels');
    RSK.channels = doSelect(RSK, ['SELECT c.shortName as shortName,'...
                        'c.longName as longName,'...
                        'c.units as units '... 
                        'FROM instrumentChannels ic '... 
                        'JOIN channels c ON ic.channelID = c.channelID '...
                        'ORDER by ic.channelOrder']);
else
    RSK.channels = doSelect(RSK, 'SELECT shortName, longName, units FROM channels ORDER by channels.channelID');
end

RSK = removenonmarinechannels(RSK,rhc);
RSK = renamechannels(RSK);

end