function [newfile] = RSKclone(fromDir, toDir, file)

% RSKclone - Clone rsk file to specified directory.
%
% Syntax:  [newfile] = RSKclone(fromDir, toDir, file)
% 
% Inputs: 
%    fromDir - Directory that contains original rsk file. 
%    
%    toDir - Directory where the file will be copied to.
% 
%    file - file name.
%
% Outputs:
%    newfile - copied file name, with current time appended to the end.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-05-15


newfile = [strtok(file,'.rsk') '_' datestr(now,'yyyymmddTHHMM') '.rsk'];
copyfile([fromDir file], [toDir newfile]);

mksqlite('open',[toDir newfile]);
mksqlite(['UPDATE deployments SET name = "' newfile '" where deploymentID = 1']);
mksqlite('close')

end