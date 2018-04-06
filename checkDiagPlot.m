function [raw, diagndx] = checkDiagPlot(RSK, diagnostic, direction, castidx)

raw = RSK; 
diagndx = getdataindex(RSK, diagnostic, direction);
diagndx = diagndx(1);

if ~ismember(diagndx, castidx)
    error('Requested profile for diagnostic plot is not processed.')
end

end