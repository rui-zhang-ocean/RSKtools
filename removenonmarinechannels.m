function [RSK, isDerived] = removenonmarinechannels(RSK, varargin)

%REMOVENONMARINECHANNELS - Remove hidden or derived channels.
%
% Syntax:  [RSK, isDerived] = REMOVENONMARINECHANNELS(RSK)
%
% Removes the hidden or derived channels from the channels table and
% returns a logical index vector. They are also removed from
% instrumentChannels if the field exists. 
%
% Inputs:
%    [Required] - RSK - Structure
%
%    [Optional] - rhc - Read hidden channel or not, 1 or 0.
%
% Outputs:
%    RSK - Structure with only marine channels.
%
%    isDerived - Logical index describing which channels are non-marine.
%
% See also: RSKopen, readheaderfull.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-21

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addOptional(p, 'rhc', 0, @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
rhc = p.Results.rhc;

if ~(strcmp(RSK.dbInfo(end).type, 'EPdesktop') || strcmp(RSK.dbInfo(end).type, 'skinny'))
    if iscompatibleversion(RSK, 1, 8, 9) && ~strcmp(RSK.dbInfo(end).type, 'EP')
        if logical(rhc)
            isDerived = logical([RSK.instrumentChannels.channelStatus] == 4);% derived channels have a '4' channelStatus
        else
            isDerived = logical([RSK.instrumentChannels.channelStatus]);% hidden and derived channels have a non-zero channelStatus
        end
        RSK.instrumentChannels(isDerived) = [];
    else
        results = mksqlite('select isDerived from channels');
        isDerived = logical([results.isDerived])'; 
    end
else
    isDerived = false(length(RSK.channels));
end


if length(RSK.channels) == length(isDerived)
    RSK.channels(isDerived) = [];
end


end


