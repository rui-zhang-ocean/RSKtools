function [RBR] = RSK2MAT(RSK)

% RSK2MAT - Creates a structure array from a RSK structure.
%
% Syntax: [RBR] = RSK2MAT(RSKfile)
%
% RSK2MAT converts the regular RSK structure format to the legacy .mat RBR
% structure array.
%
% Inputs:
%    RSK - Structure containing the logger metadata, along with the
%          added 'data' fields.
%
% Outputs:
%    RBR - Structure containing the logger data and some metadata in the
%    same format as the .mat files exported by Ruskin.
%
% Example:
%   RSK = RSKopen(fname);
%   RSK = RSKreaddata(RSK);
%   RBR = RSK2MAT(RSK);
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-11-21

% Firmware Version location is dependant on the rsk file version
vsnString = RSK.dbInfo.version;
vsn = strread(vsnString,'%s','delimiter','.');
vsnMajor = str2num(vsn{1});
vsnMinor = str2num(vsn{2});
vsnPatch = str2num(vsn{3});
if (vsnMajor > 1) || ((vsnMajor == 1)&&(vsnMinor > 12)) || ((vsnMajor == 1)&&(vsnMinor == 12)&&(vsnPatch >= 2))
    firmwareV  = RSK.instruments.firmwareVersion;
else
    firmwareV  = RSK.deployments.firmwareVersion;    
end

% Set up metadata
RBR.name = ['RBR ' RSK.instruments.model ' ' firmwareV ' ' num2str(RSK.instruments.serialID)];
RBR.datasetfilename = RSK.datasets.name;
RBR.sampleperiod = RSK.schedules.samplingPeriod/1000; % seconds
RBR.channelnames = {RSK.channels.longName}';
RBR.channelunits = {RSK.channels.units}';
RBR.channelranging = {RSK.ranging.mode}';
RBR.starttime = datestr(RSK.epochs.startTime, 'dd/mm/yyyy HH:MM:SS PM');
RBR.endtime = datestr(RSK.epochs.endTime, 'dd/mm/yyyy HH:MM:SS PM');

% Set up coefficients table
nchannels = length(RBR.channelnames);
RBR.coefficients = zeros(4, nchannels);
for i=1:nchannels
    channelindex = find([RSK.calibrations.channelOrder] == i);
    coefcell = [{RSK.calibrations(channelindex(end)).c0}; {RSK.calibrations(channelindex(end)).c1}; {RSK.calibrations(channelindex(end)).c2; RSK.calibrations(channelindex(end)).c3}];
    nocoef = cellfun('isempty', coefcell);
    coefcell(nocoef) = {NaN};
    RBR.coefficients(:,i) = cell2mat(coefcell);
end

% Set up data tables
RBR.sampletimes = cellstr(datestr(RSK.data.tstamp, 'yyyy-mm-dd HH:MM:ss.FFF'));
RBR.data = RSK.data.values;

% %Events...Not consistent
% if isfield(RSK, 'events')
%     k = find(RSK.events.values(:,4) == 0);
%     x1 = cellstr(strcat('DIAG-',num2str(RSK.events.values(k,2))));
%     x2 = cellstr(datestr(RSK.events.tstamp(k), 'dd/mm/yyyy HH:MM:SS PM'));
%     x3 = cellstr(num2str(RSK.events.values(k,3)));
%     RBR.events = [x1, x2, x3];
% end
%     

end
