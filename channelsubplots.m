function hdls = channelsubplots(RSK, field, varargin)

% channelsubplots - plots each channel specified in a different subplot for
% the field chosen.
%
% Syntax:  [hdls] = channelsubplots(RSK, field, [OPTIONS])
% 
% Generate and plots to a subplot for each channel in the chosen field. If
% data has many fields and none are specified, the first one is selected. 
%
% Inputs:
%   [Required] - RSK - Structure create from an rsk file.
%
%                field - The source of the data to plot. Can be
%                      burstdata', thumbnailData', or 'data'.
%
%   [Optional] - chanCol - The column number of the channels to be plotted.
%                      Only required if all channel are not ebing plotted.
%
%                dataNum - The data field that will be used to make the
%                      plot. Note: To compare data fields use
%                      RSKplotprofiles. 
%
% Outputs:
%    hdls - The line object of the plot.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-24

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'field', @isstr)
addParameter(p, 'chanCol', [], @isnumeric);
addParameter(p, 'dataNum', 1);
parse(p, RSK, field, varargin{:})

RSK = p.Results.RSK;
field = p.Results.field;
chanCol = p.Results.chanCol;
dataNum = p.Results.dataNum;

if isempty(chanCol)
    chanCol = 1:size(RSK.(field).values,2);
end

numchannels = length(chanCol);

n = 1;
for chan = chanCol
    subplot(numchannels,1,n)
    hdls(n) = plot(RSK.(field)(dataNum).tstamp, RSK.(field)(dataNum).values(:,chan),'-');
    title(RSK.channels(chan).longName);
    ylabel(RSK.channels(chan).units);
    ax(n)=gca;
    datetick('x')
    n = n+1 ;
end

linkaxes(ax,'x')
shg

end