function RSK = populateregionProfiles(RSK)

% populateregionCast - fill the region and regionCast table with profiles
%
% Syntax:  [RSK] = populateregionCast(RSK)
%
% This is a helper function that will populate the region and regionCast
% table if profiles are found in the data but had not been detected Ruskin.
%
% Inputs:
%    RSK - a RSK structure opened with RSKfindprofiles.m
%
% Outputs:
%    RSK - Structure containing populated region/regionCast tables
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-01-16


%% Load/Create relevant annotations tables
try
    RSK.region = mksqlite('select * from regions');
catch
    RSK.region = [];
end

try
    RSK.regionCast = mksqlite('select * from regionCasts');
catch
    RSK.regionCast = [];
end

hasRegion = ~isempty(RSK.region);
hasCast = ~isempty(RSK.regionCast);

if hasRegion && hasCast
    return
elseif hasRegion && ~hasCast
    initialnregion = length(RSK.region);
else
    initialnregion = 0;
end

%% Check which profile leads
down = RSK.profiles.downcast;
up = RSK.profiles.upcast;
if up.tstart(1) < down.tstart(1)
    firstdir = up;
    lastdir = down;
    firstType = 'UP';
    lastType = 'DOWN';
else
    firstdir = down;
    lastdir = up;
    firstType = 'DOWN';
    lastType = 'UP';
    
end

%% Populate region and regionCast fields
for ndx=1:length(lastdir.tstart)
    %region table
    nregion = initialnregion+(ndx*3)-2;
    RSK.region(nregion).datasetID = 1;
    RSK.region(nregion).regionID = nregion;
    RSK.region(nregion).type = 'PROFILE';
    RSK.region(nregion).tstamp1 = firstdir.tstart(ndx);
    RSK.region(nregion).tstamp2 = lastdir.tend(ndx);
    RSK.region(nregion).label = [];
    
    RSK.region(nregion+1).datasetID = 1;
    RSK.region(nregion+1).regionID = nregion+1;
    RSK.region(nregion+1).type = 'CAST'; 
    RSK.region(nregion+1).tstamp1 = firstdir.tstart(ndx);
    RSK.region(nregion+1).tstamp2 = firstdir.tend(ndx);

    RSK.region(nregion+2).datasetID = 1;
    RSK.region(nregion+2).regionID = nregion+2;    
    RSK.region(nregion+2).type = 'CAST';
    RSK.region(nregion+2).tstamp1 = lastdir.tstart(ndx);
    RSK.region(nregion+2).tstamp2 = lastdir.tend(ndx);

    %regionCast table
    nregionCast = (ndx*2)-1;
    RSK.regionCast(nregionCast).regionID = nregion+1;
    RSK.regionCast(nregionCast).regionProfileID = nregion;
    RSK.regionCast(nregionCast).type = firstType;
    RSK.regionCast(nregionCast+1).regionID = nregion+2;
    RSK.regionCast(nregionCast+1).regionProfileID = nregion;
    RSK.regionCast(nregionCast+1).type = lastType;
    
end

%% Write fields to file.
for ndx = 1:length(RSK.region)
    tstamp1(ndx) = datenum2RSKtime(RSK.region(ndx).tstamp1);
    tstamp2(ndx) = datenum2RSKtime(RSK.region(ndx).tstamp2);
end

mksqlite('begin');
for idx =1:3:length(RSK.region)
    mksqlite(sprintf('INSERT INTO region (datasetID, type, tstamp1, tstamp2) VALUES (%i, "PROFILE", %i, %i)',RSK.region(idx).datasetID, tstamp1(idx), tstamp2(idx)));
    mksqlite(sprintf('INSERT INTO region (datasetID, type, tstamp1, tstamp2) VALUES (%i, "CAST", %i, %i)',RSK.region(idx+1).datasetID, tstamp1(idx+1), tstamp2(idx+1)));
    mksqlite(sprintf('INSERT INTO region (datasetID, type, tstamp1, tstamp2) VALUES (%i, "CAST", %i, %i)',RSK.region(idx+2).datasetID, tstamp1(idx+2), tstamp2(idx+2)));
end
for idx =1:2:length(RSK.regionCast)
    mksqlite(sprintf('INSERT INTO region (regionProfileID, type) VALUES (%i, "DOWN")',RSK.regionCast(idx).regionProfileID, RSK.regionCast(idx).type));
    mksqlite(sprintf('INSERT INTO region (regionProfileID, type) VALUES (%i, "UP")',RSK.regionCast(idx+1).regionProfileID, RSK.regionCast(idx+1).type));
end
mksqlite('commit');
end
    


    
    
   
