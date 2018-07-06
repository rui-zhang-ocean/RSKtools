function [newfile] = RSKclone(inputdir, outputdir, file, suffix)

% RSKclone - Clone rsk file to specified directory.
%
% Syntax:  [newfile] = RSKclone(inputdir, outputdir, file, suffix)
% 
% Inputs: 
%    inputdir - Directory that contains original rsk file. 
%    
%    outputdir - Directory where the file will be copied to.
% 
%    file - file name.
%
%    suffix - suffix add to file name for new file name, default is current
%    time in format of YYYYMMDDTHHMM.
%
% Outputs:
%    newfile - output new file name.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-06-06

if isempty(suffix)
    suffix = datestr(now,'yyyymmddTHHMM');
end

newfile = [strtok(file,'.rsk') '_' suffix '.rsk'];
copyfile([inputdir '/' file], [outputdir '/' newfile]);

mksqlite('open',[outputdir '/' newfile]);
mksqlite(['UPDATE deployments SET name = "' newfile '" where deploymentID = 1']);
mksqlite('close')

end