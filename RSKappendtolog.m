function RSK = RSKappendtolog(RSK, logentry)

% RSKappendtolog - Appends the a string to the log field in RSK structure
%
% Syntax:  [RSK] = RSKappendtolog(RSK, logstring)
% 
% RSKappendtolog adds an entry to the log field in the RSK structure. If
% the field isn't present it creates it. It only ever appends entries to
% the end.
%
% Inputs: 
%    RSK - Structure containing the logger metadata and thumbnails
%
%    logentry - Comment that will be added to the log. Must be string
%        entry.
%
% Outputs:
%    RSK - The RSK structure with updated log field
%
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-03-16

if isfield(RSK, 'log')
    nlog = length(RSK.log);
else
    nlog = 0;
end

RSK.log(nlog+1) = {logentry};
