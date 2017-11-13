function RSK = readstandardtables(RSK,varargin)

%READSTANDARDTABLES- Read tables that are populated in all .rsk files.
%
% Syntax:  [RSK] = READSTANDARDTABLES(RSK)
%
% Opens the tables that are populated in any file. These tables are
% channels, epochs, schedules, deployments and instruments.
%
% Inputs:
%    [Required] - RSK - Structure opened using RSKopen.m.
%
%    [Optional] - rhc - Read hidden channel or not, 1 or 0.
%
% Outputs:
%    RSK - Structure containing the standard tables.
%
% See also: RSKopen.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-21

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addOptional(p, 'rhc', 0, @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
rhc = p.Results.rhc;

RSK = readchannels(RSK, rhc);

RSK.epochs = doSelect(RSK, 'select deploymentID,startTime/1.0 as startTime, endTime/1.0 as endTime from epochs');
RSK.epochs.startTime = RSKtime2datenum(RSK.epochs.startTime);
RSK.epochs.endTime = RSKtime2datenum(RSK.epochs.endTime);

RSK.schedules = doSelect(RSK, 'select * from schedules');

RSK.deployments = doSelect(RSK, 'select * from deployments');

RSK.instruments = doSelect(RSK, 'select * from instruments');

end
