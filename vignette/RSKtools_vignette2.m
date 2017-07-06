%% RSKtools for Matlab processing RBR data
% RSKtools v2.0.0;
% RBR Ltd. Ottawa ON, Canada;
% support@rbr-global.com;
% 2017-07-06

%% Introduction
% In order to facilitate the post-processing process of RBR data. We
% provide a few common processing functions. Below we will walk through the
% standard steps for processing CTD data.

%% Getting set up
% If the steps below are uncommon to you, please review RSKtools_vignette.
file = 'sample.rsk';
rsk = RSKopen(file);
rsk = RSKreadprofiles(rsk, 'profile', 10:55, 'direction', 'up');

%% Low-pass filtering
% The first step is generally to apply a low pass filter to the pressure
% data; then filter the temperature and conductivity channels to
% smooth high frequencies. RSKtools provides a function called
% |RSKsmooth()|. All post-processing functions have many name-value pair
% input arguments to specify what values you want to process and how you
% want to do it. To process all data using the default parameters no
% name-value pair arguments are required. 
% All the information above is available for each function using |help|, for example: |help
% RSKsmooth|.
help RSKsmooth

%%
rsk = RSKsmooth(rsk, 'Pressure');
rsk = RSKsmooth(rsk, {'Conductivity', 'Temperature'}, 'windowLength', 21);

%% Aligning CT
% Begin by aligning temperature to pressure. This can be done in many way.
% For the sake of this example, we estimate a 5 sample lag for all
% profiles.
rsk = RSKalignchannel(rsk, 'Temperature', 2);

% RSKtools provides a function called |RSKcalculateCTlag| that suggests
% conductivity to temperature lag measurements by minimizing salinity
% spiking. See |help RSKcalculateCTlag|.
lag = RSKcalculateCTlag(rsk);
rsk = RSKalignchannel(rsk, 'Conductivity', lag);

%% Remove loops
% Profiling at sea can be very tricky. The measurements taken too slowly or
% during a pressure reversal should not be used for further analysis. We
% recommend using |RSKremoveloops()|. It uses a `treshold` value to
% determine the minimum profiling speed, the default is 0.25 m/s. As you
% can see the threshold is in m/s which means the function requires a depth
% channel. We have provided |RSKderivedepth()| to facilitate this.
rsk = RSKderivedepth(rsk);
rsk = RSKremoveloops(rsk, 'threshold', 0.3);

%% Derive
% A few functions are provided to facilitate deriving sea pressure, salinity, and depth from the data. We suggesting deriving sea pressure first,
% in case you want to add a custom atmospheric pressure, because salinity
% and depth calculations use sea pressure.
rsk = RSKderiveseapressure(rsk);
rsk = RSKderivesalinity(rsk);
rsk = RSKderivedepth(rsk);

%% Bin data
% Quantize data in 0.5dbar bins. |RSKbinaverage()| requires a direction
% to explicitly describe in which direction the bin limits will be
% determined. 
rsk = RSKbinaverage(rsk, 'binBy', 'Sea Pressure', 'binSize', 0.5, 'direction', 'up');

%% Plot
% Now we can see what the data looks like. We suggest plotting as you go to
% see if the changes eing applied are what you expect.
RSKplot2D(rsk, 'Salinity');


%% See RSKtools_vignette
% A vignette is available for information on getting started with
% |RSKtools|.


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