function RSK = CSV2RSK(fname,varargin)

% CSV2RSK - Convert a csv file into a rsk structure.
%
% Syntax: RSK = CSV2RSK(fname, [OPTIONS])
%
% Inputs: 
%    [Required] - fname - filename of the csv file
%
%    [Optional] - model - instrument model from which data was collected, 
%                 default is 'unknown'
%    
%                 serialID - serial ID of the instrument from which data
%                 was collected, default is 0
%
% Output:
%    RSK - RSK structure containing data from the csv file
%
% Note: The header of the csv file must follow exactly the format below to
% make this function work:
%
% "Time (ms)","Conductivity (mS/cm)","Temperature (°C)","Pressure (dbar)"
% 1564099200000,49.5392,21.8148,95.387
% 1564099200167,49.5725,21.8453,95.311
% 1564099200333,49.5948,21.8752,95.237
% ...
%
% where the first column represents time stamp, which is milliseconds
% elapsed since January 1 1970 (i.e. unix time or POSIX time). Header for
% each column is comprised with channel name followed by space and unit 
% (with parentheses) with double quotes.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2020-03-30


p = inputParser;
addRequired(p,'fname', @ischar);
addParameter(p,'model','unknown', @ischar);
addParameter(p,'serialID', 0, @isnumeric);
parse(p, fname, varargin{:})

fname = p.Results.fname;
model = p.Results.model;
serialID = p.Results.serialID;


data = csvread(fname,1,0);

fid = fopen(fname,'r','n','UTF-8');
varNameAndUnit = strsplit(fgetl(fid),',');
fclose(fid);

varNameAndUnit = varNameAndUnit(2:end);
[channels,units] = deal(cell(size(varNameAndUnit)));

for i = 1:length(varNameAndUnit)
    idx = strfind(varNameAndUnit{i},'(');
    idx = idx(end);
    channels{i} = varNameAndUnit{i}(1:idx-2);
    units{i} = varNameAndUnit{i}(idx:end);
end

channels = regexprep(channels,'"','');
units = regexprep(units,'[",(,)]','');

tstamp = rsktime2datenum(data(:,1))';
values = data(:,2:end);

RSK = RSKcreate('tstamp',tstamp,'values',values,'channel',channels,'unit',...
      units,'filename',[strtok(fname,'.') '.rsk'],'model',model,'serialID',serialID);

end