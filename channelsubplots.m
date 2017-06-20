function handles = channelsubplots(RSK, field, varargin)

% channelsubplots - Plots each channel specified in a different subplot.
%
% Syntax:  [handles] = channelsubplots(RSK, field, [OPTIONS])
% 
% Generate and plots in a subplot each channel in the chosen data element.
% If data has many fields and none are specified, the first one is
% selected.  
%
% Inputs:
%   [Required] - RSK - Structure create from an .rsk file.
%
%                field - The source of the data to plot. Can be
%                      burstdata', thumbnailData', or 'data'.
%
%   [Optional] - chanCol - The column number of the channels to be plotted.
%                      Only required if a selection of channels are being
%                      plotted.
%
%                castidx - The element of data that will be used to make
%                      the plot. The default is 1. Note: To compare data
%                      fields use RSKplotprofiles. 
%
% Outputs:
%    handles - The line object of the plot.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-19

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'field', @isstr)
addParameter(p, 'chanCol', [], @isnumeric);
addParameter(p, 'castidx', 1);
parse(p, RSK, field, varargin{:})

RSK = p.Results.RSK;
field = p.Results.field;
chanCol = p.Results.chanCol;
castidx = p.Results.castidx;



if isempty(chanCol)
    chanCol = 1:size(RSK.(field)(castidx).values,2);
end
numchannels = length(chanCol);

n = 1;
for chan = chanCol
    subplot(numchannels,1,n)
    handles(n) = plot(RSK.(field)(castidx).tstamp, RSK.(field)(castidx).values(:,chan),'-');
    title(RSK.channels(chan).longName);
    ylabel(RSK.channels(chan).units);
    ax(n)=gca;
    datetick('x')
    n = n+1 ;
end

linkaxes(ax,'x')
shg

end