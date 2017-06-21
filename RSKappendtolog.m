function RSK = RSKappendtolog(RSK, logentry)

%RSKappendtolog - Append the entry and current time to the log field.
%
% Syntax:  [RSK] = RSKappendtolog(RSK, logentry)
% 
% Adds the current time and logentry  to the log field in the RSK structure.
% If the field isn't present it creates it. It only ever appends entries to
% the end. 
%
% Inputs: 
%    RSK - Structure containing the logger metadata and thumbnail
%
%    logentry - Comment that will be added to the log. Must be a string. 
%
% Outputs:
%    RSK - Input structure with updated log field.
%
% See also: RSKopen, RSKalignchannel, RSKbinaverage.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-06-21

if isfield(RSK, 'log')
    nlog = length(RSK.log);
else
    nlog = 0;
end

RSK.log(nlog+1,:) = {now, logentry};

end
