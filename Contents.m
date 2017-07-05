% RSKTOOLS
% Version 2.0.0 2017-07-07
%
% 1.  This toolbox depends on the presence of a functional mksqlite
% library.  We have included a couple of versions here for Windows (32 bit/ 64 bit), Linux (64 bit)
% and Mac (64 bit), but you might need to compile another version.  The
% mksqlite-src directory contains everything you need and some instructions
% from the original author.  You can also find the source through Google.
%
% 2.  Opening an RSK.  Use "RSKopen" with a filename as argument:
%
% RSK = RSKopen('sample.rsk');  
%
% This generates an RSK structure with all the metadata from the database, 
% and a thumbnail of the data, but without slurping in a massive amount of 
% data.
%
% 3.  Plot the thumbnail data from the RSK that gives you an overview of
% the dataset:
%
% RSKplotthumbnail(RSK) 
% 
% This is usually a plot of 4000 points.  Each time value has a max
% and a min data value so that all spikes are visible even though the 
% dataset is down-sampled.
%
% 4.  Use RSKreaddata to read a block of data from the database on disk
%
% RSK=RSKreaddata(RSK, 't1', <starttime>, 't2', <endtime>); 
%
% This reads a portion of the 'data' table into the RSK structure 
% (replacing any previous data that was read this way).  The <starttime> 
% and <endtime> values are the range of data thast should be read.  Depending
% on the amount of data in your dataset, and the amount of memory in your 
% computer, you can read bigger or smaller chunks before Matlab will complain 
% and run out of memory.  The times are specified using the Matlab
% 'datenum' format - there are some conversion utilities (see below) which
% work behind the scenes to convert to the time format used in the
% database.
% You will find the start and end times of the deployment useful reference
% points - these are contained in the RSK structure as the
% RSK.epochs.starttime and RSK.epochs.endtime fields.
%
% 5.  Plot the data!
%
% RSKplotdata(RSK)
%
% This generates a plot, similar to the thumbnail plot, only using the full
% 'data' that you read in, rather than just the thumbnail view.  It tries
% to be intelligent about the subplots and channel names, so you can get an
% idea of how to do better processing.
%
%
% User files
%   RSKopen            - assumes only a single instrument deployment in RSK
%   RSKreadthumbnail   - read thumbnail data from database
%   RSKplotthumbnail   - plot data
%   RSKreaddata        - read data from database
%   RSKplotdata        - plot data
%   RSKgetprofiles     - read multiple start and end times determined in profiles field
%   RSKreadprofiles    - read profiles using metadata in profiles field
%   RSKplotprofiles    - plot profiles for each channel versus sea pressure
%   RSKfindprofiles    - detect profiles start and end times using pressure data
%   RSKreadburstdata   - read burst data from database
%   RSKplotburstdata   - plot burst data
%   RSKreadevents      - read events from database
%   RSKver             - reads the version of the file
%   RSKreadgeodata     - read geodata
%   RSKderivesalinity  - derive salinity from CTP
%   RSKderiveseapressure - derive sea pressure from pressure
%   RSKderivedepth     - derive depth from pressure
%   RSKderivevelocity  - derive velocity from depth and time
%   RSKsmooth          - apply low-pass filter to data
%   RSKdespike         - remove or replace spikes in data
%   RSKcalculateCTlag  - estimate optimal conductivity shift
%   RSKalignchannel    - align a channel using a specified lag
%   RSKremoveloops     - remove values exceeding a threshold profiling rate
%   RSKbinaverage      - average the profile data by reference channel intervals
%
%
% Helper files
%   mksqlite           - the library for SQLite files (the .rsk file format)
%   arrangedata        - rearrange a structure into a cell array for convenience
%   RSKtime2datenum    - convert SQLite times to Matlab datenums 
%   datenum2RSKtime    - convert Matlab datenums to SQLite times
%   unixtime2datenum   - convert unixtimes to Matlab datenums
%   datenum2unixtime   - convert Matlab datenums to unixtimes
%
% 

