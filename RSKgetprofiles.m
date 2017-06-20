function RSK = RSKgetprofiles(RSK)

% RSKgetprofiles - finds the profiles start and end times
%
% Syntax:  [RSK] = RSKgetprofiles(RSK)
% 
% RSKgetprofiles finds the profiles start and end times by first looking at
% the region table (Ruskin generated) then at the events table (logger
% generated).
%
% Inputs: 
%    RSK - the input RSK structure, with profile events
%
% Outputs:
%    RSK - Structure containing the logger metadata and thumbnails
%    including profile metadata
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-31

if isfield(RSK, 'profiles')
    error('Profiles are already found, get data using RSKreadprofiles.m');
end



RSK = readregionprofiles(RSK);



if ~isfield(RSK, 'profiles')
    RSK = readeventsprofiles(RSK);
end

end



        
