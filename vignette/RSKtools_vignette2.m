%% RSKtools for Matlab processing RBR data
% RSKtools v2.0.0;
% RBR Ltd. Ottawa ON, Canada;
% support@rbr-global.com;
% 2017-07-07

%% Introduction
% A suite of new functions are included in RSKtools v2.0.0 
% to post-process RBR logger data. Below we show how
% to implement some common processing steps to obtain the highest
% quality data possible. 

%% Getting set up
% See review RSKtools_vignette for help.
file = 'sample.rsk';
rsk = RSKopen(file);
rsk = RSKreadprofiles(rsk, 'profile', 10:55, 'direction', 'up');

%% Low-pass filtering
% The first step is generally to apply a low pass filter to the pressure
% data; then filter the temperature and conductivity channels to
% smooth high frequency variability and match sensor time constants. 
% RSKtools includes a function called
% |RSKsmooth| for this purpose. All post-processing functions are customizable
% with name-value pair input arguments.  To process all data using the default parameters no
% name-value pair arguments are required. 
% All the information above is available for each function using |help|, for example: |help
% RSKsmooth|.
help RSKsmooth

%%
rsk = RSKsmooth(rsk, 'Pressure');
rsk = RSKsmooth(rsk, {'Conductivity', 'Temperature'}, 'windowLength', 21);

%% Aligning CT
% RSKtools provides a function called |RSKcalculateCTlag| that estimates
% the optimal lag between conductivity and temperature by minimising salinity
% spiking. See |help RSKcalculateCTlag|.
lag = RSKcalculateCTlag(rsk);
rsk = RSKalignchannel(rsk, 'Conductivity', lag);

%% Remove loops
% Profiling during rough seas can cause the CTD descent (or ascent) rate to vary, or even
% temporarily reverse direction, while profiling.  During such times, the 
% CTD can effectively sample its own wake, potentially degrading the quality
% of the profile in regions of strong gradients. The measurements taken too slowly or
% during a pressure reversal should not be used for further analysis. We
% recommend using |RSKremoveloops| to flag and remove data when the instrument falls
% below a |threshold| speed.  This function requires a depth channel, for
% which we have provided |RSKderivedepth|.
rsk = RSKderivedepth(rsk);
rsk = RSKremoveloops(rsk, 'threshold', 0.3);

%% Derive
% Functions are provided to derive sea pressure,
% practical salinity, and depth from measured channels. We suggest deriving sea pressure first, 
% especially when an atmospheric pressure other than the nominal value of 10.1325 dbar
% is used, because deriving salinity and depth requires sea pressure.
rsk = RSKderiveseapressure(rsk);
rsk = RSKderivesalinity(rsk);
rsk = RSKderivedepth(rsk);

%% Bin data
% Average the data into 0.5 dbar bins using |RSKbinaverage|.
rsk = RSKbinaverage(rsk, 'binBy', 'Sea Pressure', 'binSize', 0.5, 'direction', 'up');

%% Plot 
% Now we can see the changes to the data. We suggest plotting as you go to 
% see if the changes being applied are what you expect. 
RSKplot2D(rsk, 'Salinity'); 


%% See RSKtools_vignette
% A vignette is available for information on getting started with
% |RSKtools| standard functions.


%% About this document
% This document was created using
% <http://www.mathworks.com/help/matlab/matlab_prog/marking-up-matlab-comments-for-publishing.html
% Matlab(TM) Markup Publishing>. To publish it as an HTML page, run the
% command:
%%
% 
%   publish('RSKtools_vignette.m');

%%
% See |help publish| for more document export options.