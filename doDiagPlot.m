function [] = doDiagPlot(RSK, raw, index, ndx, channelidx)

% doDiagPlot - Plot diagnostic plots to show difference before and after
% data process.
%
% Syntax:  [handles] = doDiagPlot(RSK, raw, index, ndx, channelidx)
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
%    RSK - RSK structure containing processed data.
%
%    raw - RSK structure containing raw data.
%
%    index - flagged data index (i.e. RSK.data.values(index,:))
%
%    ndx - data structure index (i.e. RSK.data(ndx).values)
%
%    channelidx - channel index (i.e. RSK.data.values(:,channelidx))
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

presCol = getchannelindex(RSK,'Pressure');
fig = figure;
set(fig, 'position', [10 10 500 800]);
plot(raw.data(ndx).values(:,1),raw.data(ndx).values(:,presCol),'-c','linewidth',2);
hold on
plot(RSK.data(ndx).values(:,1),RSK.data(ndx).values(:,presCol),'--k'); 
hold on
plot(raw.data(ndx).values(index,1),raw.data(ndx).values(index,presCol),...
    'or','MarkerEdgeColor','r','MarkerSize',5);
ax = findall(gcf,'type','axes');
set(ax, 'ydir', 'reverse');
xlabel([RSK.channels(channelidx).longName ' (' RSK.channels(channelidx).units ')']);
ylabel(['Pressure (' RSK.channels(presCol).units ')']);
if isfield(RSK.data,'profilenumber') && isfield(RSK.data,'direction')
    title(['Profile ' num2str(RSK.data(ndx).profilenumber) ' ' RSK.data(ndx).direction 'cast']);
end
legend('Original data','Processed data','Flagged data','Location','Best');
set(findall(fig,'-property','FontSize'),'FontSize',15);

end