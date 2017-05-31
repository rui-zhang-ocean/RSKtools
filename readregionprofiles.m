function RSK = readregionprofiles(RSK)

% readregionprofiles - Uses the events table to read profiles start and end
% time
%
% Syntax:  [RSK] = readregionprofiles(RSK)
%
% This is a helper function that will read in profiles start and end times
% using the region and regionCast tables.
%
% Inputs:
%    RSK - a RSK structure opened with RSKgetprofiles.m
%
% Outputs:
%    RSK - Structure containing populated profiles
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-31

tables = mksqlite('SELECT name FROM sqlite_master WHERE type="table"');

if any(strcmpi({tables.name}, 'regionCast')) && any(strcmpi({tables.name}, 'region'))
    RSK.region = mksqlite('select regionID, type, tstamp1/1.0 as tstamp1, tstamp2/1.0 as tstamp2 from region');
    RSK.regionCast = mksqlite('select * from regionCast');
else
    return
end



if ~isempty(RSK.regionCast)
    if strcmpi(RSK.regionCast(1).type, 'down')
        firstdir = 'downcast';
        lastdir = 'upcast';
    else
        firstdir = 'upcast';
        lastdir = 'downcast';
    end
else
    RSK = rmfield(RSK, 'regionCast');
    RSK = rmfield(RSK, 'region');
    return
end



for ndx = 1:length(RSK.regionCast)/2
    nregionCast = (ndx*2)-1;
    regionID = RSK.regionCast(nregionCast).regionID;
    RSK.profiles.(firstdir).tstart(ndx,1) = RSKtime2datenum(RSK.region(regionID).tstamp1);
    RSK.profiles.(firstdir).tend(ndx,1) = RSKtime2datenum(RSK.region(regionID).tstamp2);
    regionID2 = RSK.regionCast(nregionCast+1).regionID;
    RSK.profiles.(lastdir).tstart(ndx,1) = RSKtime2datenum(RSK.region(regionID2).tstamp1);
    RSK.profiles.(lastdir).tend(ndx,1) = RSKtime2datenum(RSK.region(regionID2).tstamp2);
end
end
