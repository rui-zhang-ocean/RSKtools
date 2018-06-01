function [newfile] = RSKclone(inputdir, outputdir, file)

% RSKclone - Clone rsk file to specified directory.
%
% Syntax:  [newfile] = RSKclone(inputdir, outputdir, file)
% 
% Inputs: 
%    inputdir - Directory that contains original rsk file. 
%    
%    outputdir - Directory where the file will be copied to.
% 
%    file - file name.
%
% Outputs:
%    newfile - copied file name, with current time appended to the end.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-06-01


newfile = [strtok(file,'.rsk') '_' datestr(now,'yyyymmddTHHMM') '.rsk'];
copyfile([inputdir '/' file], [outputdir '/' newfile]);

mksqlite('open',[outputdir '/' newfile]);
mksqlite(['UPDATE deployments SET name = "' newfile '" where deploymentID = 1']);
mksqlite('close')

end