function [] = doDiagPlot(RSK, raw, index, ndx, channelidx)
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