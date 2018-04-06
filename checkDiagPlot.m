function [raw, diagndx] = checkDiagPlot(RSK, diagnostic, direction, castidx)

% Check if requested profile for diagnostic plot exists in processed
if diagnostic ~= 0; 
    raw = RSK; 
    diagndx = getdataindex(RSK, diagnostic, direction);
    diagndx = diagndx(1);
    if ~ismember(diagndx, castidx)
        error('Requested profile for diagnostic plot is not processed.')
    end
end

end