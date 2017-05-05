function RSKplotdata(RSK, varargin)

% RSKplotdata - Plot summaries of logger data
%
% Syntax:  RSKplotdata(RSK, channel)
% 
% This generates a plot, similar to the thumbnail plot, only using the
% full 'data' that you read in, rather than just the thumbnail view.
% It tries to be intelligent about the subplots and channel names, so
% you can get an idea of how to do better processing.
% 
% Inputs:
%    [Required] - RSK - Structure containing the logger metadata and data
%
%    [Optional] - channel - channel to plots, can be multiple in a cell, if no value is
%                            given it will plot all. 
%
% Example: 
%    RSK=RSKopen('sample.rsk');   
%    RSK=RSKreaddata(RSK);  
%    RSKplotdata(RSK);
%    RSKplotdata(RSK, 'channel', {'Temperature', 'Conductivity'})
%
% See also: RSKplotthumbnail, RSKplotburstdata
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-05

%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'channel', 'all');
parse(p, RSK, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
channel = p.Results.channel;

if isfield(RSK,'data')==0
    disp('You must read a section of data in first!');
    disp('Use RSKreaddata...')
    return
end

if strcmpi(channel, 'all')
    channel = {RSK.channels.longName};
elseif ~iscell(channel)
    channel = {channel};
end

numchannels = length(channel);

for n=1:numchannels
    subplot(numchannels,1,n)
    Ccol = strcmpi({RSK.channels.longName}, channel(n));
    plot(RSK.data.tstamp,RSK.data.values(:,Ccol),'-')
    title(RSK.channels(Ccol).longName);
    ylabel(RSK.channels(Ccol).units);
    ax(n)=gca;
    datetick('x')
end
linkaxes(ax,'x')
shg
end


