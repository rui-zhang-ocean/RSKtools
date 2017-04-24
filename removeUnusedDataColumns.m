function dataresults = removeUnusedDataColumns(results)
% removeUnusedDataColumn -  remove tstamp_1 and datasetId if they are
%        present. They are not used and are not in all data tables.
%
% Syntax:  [dataresults] = removeUnusedDataColumns(results)
%
% Inputs:
%    results - the output from the sql call to the data table
%
% Outputs:
%    dataresults - The data table without tstamp_1 and datasetId.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-04-24

dataresults = rmfield(results,'tstamp_1');

names = fieldnames(dataresults);
fieldmatch = strcmpi(names, 'datasetid');

if sum(fieldmatch)
    dataresults = rmfield(dataresults, names(fieldmatch)); % get rid of the datasetID column
end

end