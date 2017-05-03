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
%    RSK - Structure containing the logger metadata and data
%
%    channel - channel to plots, if no value is given it will plot all.
%
% Example: 
%    RSK=RSKopen('sample.rsk');  
%    RSK=RSKreaddata(RSK);  
%    RSKplotdata(RSK);  
%
% See also: RSKplotthumbnail, RSKplotburstdata
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com

%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addOptional(p, 'channel', [], @ischar);
parse(p, RSK, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
channel = p.Results.channel;

if isfield(RSK,'data')==0
    disp('You must read a section of data in first!');
    disp('Use RSKreaddata...')
    return
end
numchannels = size(RSK.data.values,2);

if ~isempty(channel)
    Ccol = strcmpi({RSK.channels.longName}, channel);
    plot(RSK.data.tstamp,RSK.data.values(:,Ccol),'-')
    title(RSK.channels(Ccol).longName);
    ylabel(RSK.channels(Ccol).units);
    ax(Ccol)=gca;
    datetick('x')  % doesn't display the date if all data within one day :(
else
    for n=1:numchannels
        subplot(numchannels,1,n)
        plot(RSK.data.tstamp,RSK.data.values(:,n),'-')
        title(RSK.channels(n).longName);
        ylabel(RSK.channels(n).units);
        ax(n)=gca;
        datetick('x')  % doesn't display the date if all data within one day :(
        linkaxes(ax,'x')
    end
end

shg
