function [] = doDiagPlot(RSK, raw, varargin)

% doDiagPlot - Plot diagnostic plots to show difference before and after
% data process.
%
% Syntax:  [handles] = doDiagPlot(RSK, raw, [OPTIONS])
% 
% Generates a plot to show original data, processed data and flagged data 
% (if exists) against Pressure for profiles. It only plots the first 
% profile of the first channel. Current RSKtools have functions below that 
% could alter the data:
%
% - RSKalignchannel
% - RSKbinaverage
% - RSKcorrecthold
% - RSKdespike
% - RSKremoveloops
% - RSKsmooth
% - RSKtrim
% 
% Inputs:
%    [Required] - RSK - RSK structure containing processed data.
%
%                 raw - RSK structure containing raw data.
%
%    [Optional] - index - flagged data index (i.e. RSK.data.values(index,:))
%
%                 ndx - data structure index (i.e. RSK.data(ndx).values)
%
%                 channelidx - channel index (i.e. RSK.data.values(:,channelidx))
%
% Output:
%     handles - Line object of the plot.
%
% See also: RSKdespike, RSKremoveloops, RSKcorrecthold, RSKtrim.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-03-19

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'raw', @isstruct);
addParameter(p, 'index',[], @isnumeric);
addParameter(p, 'ndx', 1, @isnumeric);
addParameter(p, 'channelidx', 1, @isnumeric);
parse(p, RSK, raw, varargin{:})

RSK = p.Results.RSK;
raw = p.Results.raw;
index = p.Results.index;
ndx = p.Results.ndx;
channelidx = p.Results.channelidx;

presCol = getchannelindex(RSK,'Pressure');

fig = figure;
set(fig, 'position', [10 10 500 800]);
plot(raw.data(ndx).values(:,channelidx),raw.data(ndx).values(:,presCol),'-c','linewidth',2);
hold on
plot(RSK.data(ndx).values(:,channelidx),RSK.data(ndx).values(:,presCol),'--k'); 
hold on
plot(raw.data(ndx).values(index,channelidx),raw.data(ndx).values(index,presCol),...
    'or','MarkerEdgeColor','r','MarkerSize',5);
ax = findall(gcf,'type','axes');
set(ax, 'ydir', 'reverse');
xlabel([RSK.channels(channelidx).longName ' (' RSK.channels(channelidx).units ')']);
ylabel(['Pressure (' RSK.channels(presCol).units ')']);
if isfield(RSK.data,'profilenumber') && isfield(RSK.data,'direction')
    title(['Profile ' num2str(RSK.data(ndx).profilenumber) ' ' RSK.data(ndx).direction 'cast']);
end
if isempty(index)
    legend('Original data','Processed data','Location','Best');
else
    legend('Original data','Processed data','Flagged data','Location','Best');
end
set(findall(fig,'-property','FontSize'),'FontSize',15);

end