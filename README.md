# RSKtools

Current stable version: 3.4.0 (2020-02-14)

RSKtools is a Matlab toolbox designed to help RBR users work with the
"RSK" SQLite data files generated by RBR instruments. This repository
is for the development version of the toolbox -- for the current
stable version go to:

[http://www.rbr-global.com/support/matlab-tools](http://www.rbr-global.com/support/matlab-tools)

Please note, RSKtools requires MATLAB R2013b or later, and we
recommend installing the freely
available [TEOS-10 GSW](http://www.teos-10.org/software.htm)
and
[cmocean](https://www.mathworks.com/matlabcentral/fileexchange/57773-cmocean-perceptually-uniform-colormaps) packages.


## What can RSKtools do?

* Open RSK files:
```matlab
rsk = RSKopen('sample.rsk');
```

* Read data from RSK files:
```matlab
rsk = RSKreaddata(rsk);
```

* Plot a time series of the data:
```matlab
RSKplotdata(rsk);
```

* Low-pass filter selected channels:
```matlab
rsk = RSKsmooth(rsk,'channel',{'Conductivity','Temperature'},'windowLength',5);
```

* And lots of other stuff like automatic profile detection, sensor time
  alignment, bin averaging, and exporting data to CSV files.

## How do I get set up?

* Unzip the archive (to `~/matlab/RSKtools`, for instance).
* Add the RSKtools folder to your Matlab path by running either of the following at the command prompt:
    * `addpath ~/matlab/RSKtools`
    * `pathtool` and manually add RSKtools directory
* Type `help RSKtools` to get an overview and take a look at the examples.
* Read the [RSKtools User Manual](https://docs.rbr-global.com/rsktools).
* Check out [Getting started](http://rbr-global.com/wp-content/uploads/2020/02/Standard.pdf)
  and [Post-processing](http://rbr-global.com/wp-content/uploads/2020/02/PostProcessing.pdf) for a quick start.

## A note on calculation of salinity

A typical RBR CTD (e.g., Concerto or Maestro) has sensors to measure
*in situ* pressure, temperature, and electrical conductivity. These
three variables are required to calculate seawater salinity, either
using the Practical Salinity Scale (PSS-78,
see
[Unesco, 1981](http://unesdoc.unesco.org/images/0004/000461/046148eb.pdf)),
or Absolute Salinity based on the Thermodynamic Equation of Seawater
2010 (see [IOC, SCOR and IAPSO, 2010](http://www.teos-10.org)).  If
the [TEOS-10 GSW](http://www.teos-10.org/software.htm) or [seawater]
(http://www.cmar.csiro.au/datacentre/ext_docs/seawater.htm) Matlab 
toolbox is installed, users can call the `RSKtools` function
`RSKderivesalinity` to calculate Practical Salinity and store it as a 
channel in the RSK structure.


## Contribution guidelines

* Feel free to add improvements at any time:
    * by forking and sending a pull request
    * by emailing patches or changes to `support@rbr-global.com`
* Write to `support@rbr-global.com` if you need help

## Changes

* Version 3.4.0 (2020-02-14)

   - All RSKtools functions now require name-value pair format for input arguments except when specifying the RSK structure and filename.
   - More derivation functions now support CSIRO seawater library, including `RSKderivesalinity`, `RSKderivedepth`, `RSKderivebuoyancy`, `RSKderivetheta` and `RSKderivesigma`.
   - New function `RSKderivesoundspeed` to derive speed of sound in seawater.
   - New function `CSV2RSK` to read CSV file into rsk structure.
   - New functions `RSKsettings` and `RSKdefaultsettings` to set up global parameters for RSKtools.
   - New function `RSKprintchannels` to display channel names and units in MATLAB command window.
   - New functions `RSKerror` and `RSKwarning` to better handle error and warning messages.
   - Fixed bug that `RSKderiveO2` could not recognize saturation/concentration channel correctly.
   - Fixed bug that `RSKgenerate2D` required user to specify cast direction when only upcast is available.
   - Fixed bug that `RSKreaddata` could not recognize derived and hidden channels correctly.
   - Export functions now adjust file path separator to be compatible across operating systems.
   - `RSK2RSK` now uses millisecond for sampling period unit.
   - Subfolder `Utilities` renamed to `private`.
   - `Utilites/loadconstants` removed.
   - `RSKreadata` now handles cases when file type is not available.
   - `RSKderivetheta` and `RSKderivesigma` now check if Absolute Salinity exists before calculation.
   - `RSKderivebuoyancy` now recognizes latitude input by `RSKaddstationdata`.

* Version 3.3.0 (2019-11-15)

    - New function `RSKderivesigma` to calculate density anomaly.
    - New function `RSKderivetheta` to calculate potential temperature.
    - New function `RSKderiveSA` to calculate absolute salinity.
    - `RSKderivesalinity` allows to choose seawater or TEOS-10 toolboxes.
    - `RSKderiveBPR` allows coefficients as optional input.
    - `RSKcorrectTM` handles NaN values in temperature channel correctly.
    - `RSKimages`, `RSKplotdownsample` and `RSKplotburstdata` can output axes objects.
    - `RSK2RSK` handles DDsampling (different sampling rate during up and downcasts) correctly.
    - Fixed bug that `RSKimages` won?t work for rsk with upcasts only when not specifying cast direction.
    - `RSKreadburstdata` locates pressure channel correctly for multi-channel instruments.
    - Visualization functions will not output handles when not specified.
    - Removed dependency on `stats` toolbox.
    - Integrated functions for reading different rsk file types into `Utilities/readheader`.
    - Optimized legend location for `RSKplotprofiles`.

* Version 3.2.0 (2019-07-16)

    - New function `RSKcorrecttau` to apply Fozdar et al. (1985) algorithm for sharpening sensor response (e.g., O2).
    - New function `RSKcreate` to convert any data (e.g., other CTDs, gliders, floats) into rsk structure.
    - RSKtools correctly handles cases when the number of downcasts and upcasts is not the same.
    - `RSKaddmetadata` renamed to `RSKaddstationdata`.
    - `RSKaddstationdata` now allows adding station data to time series data.
    - `RSKtrim` now requires `reference` and `range` as mandatory inputs.
    - Simplify `RSK2RSK` schema by removing the events, errors, and downloads tables.
    - `RSKfindprofiles` now uses sea pressure to detect profiles when pressure channel is missing.
    - `RSKplotdata` returns an error when `showcast` is set to true while pressure channel is missing.
    - `RSKopen` now reads instrumentSensors table if it exists.
    - `RSKderivesalinity` now sets sea pressure to 0 dbar when pressure channel is absent.
    - Fixed bug that caused `RSKbinaverage` not to work when bin averaging an upcast by time.
    - Fixed bug that caused `RSK2CSV` and `RSK2ODV` not to work when `profile` field is missing.
    - `Utilities/getchannelindex` now allows multiple channel inputs and outputs.

* Version 3.1.0 (2019-03-04)

    - New function `RSKcentrebursttimestamp` to set the burst timestamps to the centre of each burst period instead of the beginning.
    - `RSKplotprofiles` returns an error for rsk files containing only a pressure channel (e.g., soloD).
    - Fixed bug that caused `readdownsample` not to work when `readHiddenChannels` was set to true.
    - `RSKreaddata` now reads derived channels for RBRcoda T.ODO.
    - `RSKreaddata` now converts `NULL` values into `NaN`s instead of zeros.
    - Improved speed when bin averaging by time with `RSKbinaverage`.
    - `readfirmwarever` and `readsamplingperiod` are now compatible with rsk files generated by `RSK2RSK`.
    - `RSKfindprofiles` only deletes the profile field when new profiles are detected.

* Version 3.0.0 (2018-11-14)

    - New function `RSK2RSK` for writing the RSKtools rsk MATLAB structure into a new rsk file. 
    - New function `RSKcorrectTM` to correct conductivity for the thermal inertia effect.
    - New function `RSKderivebuoyancy` for deriving buoyancy frequency and stability. 
    - New function `RSKderiveO2` for converting between oxygen concentration and saturation.
    - New function `RSKplotTS` for plotting T-S diagrams.
    - New function `RSKgenerate2D` for generating 2D data with time as x-axis and reference channel (e.g., depth) as y-axis.
    - New function `RSKtimeseries2profiles` for organizing a time series into discrete profiles without reading from the rsk file on disk.
    - `RSKreadprofiles` now only reads data from the rsk file on disk.
    - `RSKselectdowncast` and `RSKselectupcast` are replaced by `RSKremovecasts`.
    - Renamed the following functions that are typically called internally:
        * `RSKfirmwarever` to `readfirmwarever`
        * `RSKgetprofiles` to `getprofiles`
        * `RSKreaddownsample` to `readdownsample`
        * `RSKreadevents` to `readevents`
        * `RSKreadgeodata` to `readgeodata`
        * `RSKsamplingperiod` to `readsamplingperiod`
        * `RSKver` to `returnversion`
        * `RSKreadannotations` to `readannotations`
        * `RSKconstants` to `loadconstants`
        * `datenum2RSKtime` to `datenum2rsktime`
        * `RSKtime2datenum` to `rsktime2datenum`
    - Move subfunctions that are mostly for internal use into folder ../rsktools/Utilities/ 
    - Synchronises plot limits using linkaxes in visualization mode of all post-processing functions.
    - Plot downcast only when both downcast and upcast are processed in visualization mode.
    - Revise `RSKalignchannel` visualize mode by plotting against time instead of sea pressure.
    - Make x-axis tight in `RSKplotdata` and `RSKimages`.
    - `RSKderiveseapressure` allows variable atmosphere pressure input.
    - Exclude pressure and sea pressure channel from being NaN in `RSKremoveloops`.
    - Input argument `rhc` in `RSKopen` is renamed to `readHiddenChannels`, whose type is changed from numeric (1 or 0) to boolean (true or false).
    - Input argument `showcast` type in `RSKplotdata` is changed from numeric (1 or 0) to boolean (true or false).
    - `RSKplot2D` renamed to `RSKimages`.
    - `RSKimages` (formerly `RSKplot2D`) optional input `interp` renamed as `showgap`.
    - `RSKimages` defaults to operate on all channels.
    - Unit of input argument `threshold` in `RSKimages` is changed from hours to seconds.
    - When bin averaging by time, the `binSize` argument in `RSKbinaverage` is now specified in seconds instead of days.
    - Fixed bug that `RSKreaddata` mislabels channels when reading wave file.

* Version 2.3.1 (2018-06-20)

    - Fixed bug in `RSKcorrecthold` when one channel contains zero value only
    - Changed input variable name pressure to seapressure in `calculatedepth.m`
    - Removed thumbnail data from the rsk structure; use downsample for a quick overview of the dataset

* Version 2.3.0 (2018-05-09)

    - New function `RSK2ODV` for outputting RSK structure into Ocean Data View (ODV) files.
    - New function `RSKaddmetadata` for adding station metadata to profiles.
    - `RSKopen` now reads Ruskin annotations including latitude, longitude, comment, and description.
    - `RSKreadprofiles` assigns latitude, longitude, comment and description annotations into data structure.
    - Fixed bug that `RSKplot2D` was not aligning profile with correct time stamp. 
    - Added option that `RSKplot2D` could determine the length of gap shown on the plot.
    - Visualization mode added to `RSKalignchannel`,`RSKbinaverage`,`RSKcorrecthold`,`RSKdespike`,`RSKremoveloops`,`RSKsmooth` and `RSKtrim` to show differences before and after alteration of data.
    - `RSKtrim` input `appliedchannel` changed to `channel`.
    - Option to choose cast direction to write with `RSK2CSV`.
    - `RSK2CSV` will write station metadata to the file CSV file header.
    - `showcast` option added in `RSKplotdata` to show cast detection events overlaid on pressure.
    - Added profile number and cast direction as legend in the last subplot in `RSKplotdata`.

* Version 2.2.0 (2018-01-25)
    - New function `RSKcorrecthold` for correcting A2D zero-order hold points.
    - New function `RSKaddchannel` for adding new variable into existing rsk structure.
    - New function `RSKderiveC25` for deriving specific conductivity at 25 degree Celsius.
    - New function `RSKderiveBPR` for deriving pressure and temperature from period data with bottom pressure recorder (BPR) channels.
    - New function `RSK2CSV` for writing logger data to CSV files.
    - New functions `RSKreaddownsample` and `RSKplotdownsample` for reading and plotting downsample data.
    - mksqlite upgraded to Version 2.5
    - Fixed bug that `RSKopen` imports wrong data table when multiple files are opened.
    - Fixed bug that `RSKfindprofile` does not always detect upcast correctly.
    - Added option to specify lag in units of time in `RSKalignchannel`.
    - Option added in `RSKopen` to read hidden channels 
    - `RSKopen` now reads power table for certain logger firmware versions.
    - Added interpolation option in `RSKtrim`.
    - Added `Optode Temperature` channel long name.
    - Improved algorithm for `RSKbinaverage`.
    - Improved algorithm for finding pressure reversals in `RSKremoveloops`.
    - Added `direction` and `profilenumber` fields to `rsk.data` with profiles.
    - `RSKplotprofiles` uses different line styles for upcast and downcast.
    - Added option in `RSKplotprofiles` to plot against total pressure.

* Version 2.1.0 (2017-08-31)
    - New function `RSKtrim` for pruning data
    - Improved vignettes
    - Option to plot against depth in `RSKplotprofiles`
    - Fixed `RSKplotprofiles` for compatibility with pre-R2014b
    - Fixed `RSKcalculateCTlag` and `RSKdespike` for compatibility with pre-R2015a
    - pressureRange option in `RSKcalculateCTlag` now seapressureRange
    - Removed dependence on Financial Toolbox in `RSKbinaverage`
    - Fixed bug occurring when RSK file has multiple dissolved oxygen channels
    - Enumerate channels with duplicate longName

* Version 2.0.0 (2017-07-07)
    - All optional input arguments are name-value pair
    - Rename burstdata field to burstData
    - Add post-processing functions for smoothing, channel alignment, etc.
    - RSKtools data processing log recorded in RSK structure 
    - Add 2D plotting function, `RSKplot2D`
    - RSKplotprofiles contains a subplot for each channel
    - Add option to plot selected channels to plotting functions
    - Plotting functions output handles to line objects for customization
    - Relocate profiling data from the profiles field to the data field
    - Added function to calculate Practical Salinity, `RSKderivesalinity`
    - Added function to calculate sea pressure from total pressure, `RSKderiveseapressure`
    - Added function to calculate depth, `RSKderivedepth`
    - Added function to calculate profiling speed, `RSKderivevelocity`
    - Cast detection function added, `RSKfindprofiles`

* Version 1.5.3 (2017-06-07)
    - Use atmospheric pressure in database if available
    - Improve channel table reading by using instrumentChannels
    - Change geodata warning to a display message
    - Only read current parameter values in parameter table

* Version 1.5.2 (2017-05-23)
    - Update RSKconstants.m
    - Fix bug with opening files that are not in current directory

* Version 1.5.1 (2017-05-18)
    - Add RSKderivedepth function
    - Add RSKderiveseapressure function
    - Add channel longName change for doxy09
    - Add filename check to RSKopen
    - Fix bug with dbInfo 1.13.0
    - Add channel argument to RSKplotdata
    - Fix bug introduced in 1.5.0 in RSKreaddata from dbInfo.version < 1.8.9.

* Version 1.5.0 (2017-03-30)
    - Move salinity derivation from RSKreaddata to RSKderivesalinity
    - Move calibrations table reading from RSKopen to RSKreadcalibrations
    - Add RSKfirmwarever function
    - Add RSKsamplingperiod function
    - Add channel longName change for temp04, temp05, temp10 and temp13
    - Remove dataset and datasetDeployments fields
    - Fix bug with loading geodata
    - Support for RSK v1.13.8


* Version 1.4.6 (2017-01-18)
    - Remove non-marine channels from data table
    - Fix bugs that occured if RSKreaddata.m is run twice
    - Seperate profile metadata reading into a different fuction in RSKopen.m
    - Add option to enter UTCdelta for geodata
    - Remove channels units and longName from data table
    - Fix bug in data when reading in profile data


* Version 1.4.5 (2016-12-22)
    - Add more support for geodata
    - Add helper files to open different file types
    - Add function to read version of file


* Version 1.4.4 (2016-12-15)
    - Add support for geodata
    - Assure that non-marine channel stay hidden
    - Add RSK2MAT.m for legacy mat file users
    - Update support for coefficients and parameter tables


* Version 1.4.3 (2016-11-03)
    - Events structure does not read in notes
    - Fix dbInfo bug to read last entry
    - Support for RSK v1.13.4


* Version 1.4.2 (2016-10-20)
    - Changed removal of 'datasetID' to be case insensitive
    - Fix upcast/downcast type in RSKplotprofiles
    - Fix RSKreadprofile typo
    - Fix bug opening |rt instruments data


* Version 1.4.1 (2016-05-20)
    - Add RSKreadwavetxt to handle import wave text exports	
    - properly read "realtime" RSK files
    - don't plot hidden channels in profiles
    - Fix bug reading data table for RSK version >= 1.12.2
    - add info from `ranging` table to structure
    - mfile vignette using Matlab markup
  

* Version 1.4 (2015-11-30)
    - add support for profile events and profile plotting
    - supports TEOS-10 for calculation of salinity
    - improved documentation
  

* Version 1.3
    - compatible with RSK generated from an EasyParse (iOs format) logger


* Version 1.2

    - added linux 64 bit mksqlite library


* Version 1.1

    - added burst and event readers

