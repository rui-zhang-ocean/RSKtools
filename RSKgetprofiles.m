function RSK = RSKgetprofiles(RSK)

% RSKgetprofiles - finds the profiles start and end times
%
% Syntax:  [RSK] = RSKgetprofiles(RSK)
% 
% RSKgetprofiles finds the profiles start and end times by first looking at
% the region table (Ruskin generated) then at the events table (logger
% generated) if neither are populated it will detect them.
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
% Last revision: 2017-04-28

RSKconstants

%% Check if upcasts is already populated
if isfield(RSK, 'profiles')
    error('Profiles are already found, get data using RSKreadprofiles.m');
end



%% Check region/regionCast for profiles
try
    RSK.regionCast = mksqlite('select * from regionCast');
catch
    RSK.regionCast = [];
end

hasCast = ~isempty(RSK.regionCast);

if  hasCast
    RSK = readregionprofiles(RSK);
    return;
elseif ~hasCast
    RSK = rmfield(RSK, 'regionCast');
end



%% Check events table for profiles
try 
    tmp = RSKreadevents(RSK);
    events = tmp.events;
catch
end

if exist('events', 'var')
    nup = length(find(events.values(:,2) == eventBeginUpcast));
    if nup>1
        RSK = readeventsprofiles(RSK);
    end
end



end



        
