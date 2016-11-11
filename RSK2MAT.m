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
% Last revision: 2016-11-08



%RBR.name = 
RBR.sampleperiod = RSK.schedules.samplingPeriod/1000; % seconds
RBR.channelnames = {RSK.channels.longName}';
RBR.channelunits = {RSK.channels.units}';
%RBR.channelranging = ;
RBR.starttime = datestr(RSK.epochs.startTime, 'dd/mm/yyyy HH:MM:SS PM');
RBR.endtime = datestr(RSK.epochs.endTime, 'dd/mm/yyyy HH:MM:SS PM');

%If many channels have the same ID the calibration tables isn't consistent.
%RBR.coefficients = [{RSK.calibrations(1:8).c0};{RSK.calibrations(1:8).c1};{RSK.calibrations(1:8).c2};{RSK.calibrations(1:8).c3}];
RBR.sampletimes = cellstr(datestr(RSK.data.tstamp, 'yyyy-mm-dd HH:MM:ss.FFF'));
RBR.data = RSK.data.values;

end