function RSK = CSV2RSK(filename,varargin)

% CSV2RSK - convert a csv wirewalker data file into a RSK structure
%
% Inputs: 
%    [Required] - filename - the filename of wirewalker csv file
%
%    [Optional] - serialID - serial ID of the wirewalker
%
% Output:
%    RSK - RSK structure with wirewalker data
%
% Example format of the csv file:
%
% "Time (ms)","Conductivity (mS/cm)","Temperature (°C)","Pressure (dbar)"
% 1564099200000,49.5392,21.8148,95.387
% 1564099200167,49.5725,21.8453,95.311
% 1564099200333,49.5948,21.8752,95.237
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2019-09-27


p = inputParser;
addRequired(p,'filename', @ischar);
addParameter(p,'serialID', 0, @isnumeric);
parse(p, filename, varargin{:})

filename = p.Results.filename;
serialID = p.Results.serialID;


data = csvread(filename,1,0);

if exist('slCharacterEncoding','file')
    originalCharacterEncoding = slCharacterEncoding;
    slCharacterEncoding('UTF-8');      
    fid = fopen(filename);
    varNameAndUnit = strsplit(fgetl(fid),',');
    fclose(fid);
    slCharacterEncoding(originalCharacterEncoding)
else  
    fid = fopen(filename);
    varNameAndUnit = strsplit(fgetl(fid),',');
    fclose(fid);
end

varNameAndUnit = regexprep(varNameAndUnit(2:end),'[",(,)]','');
[channels,units] = strtok(varNameAndUnit,' ');
units = regexprep(units,' ','');

tstamp = rsktime2datenum(data(:,1))';
values = data(:,2:end);

RSK = RSKcreate(tstamp, values, channels, units,...
    'filename','wirewalker.rsk','model','wirewalker','serialID',serialID);

end