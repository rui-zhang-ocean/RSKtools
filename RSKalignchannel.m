function [RSK] = RSKalignchannel(RSK, channel, lag, varargin)

% RSKalignchannel - Align a channel profiles using a specified lag.
%
% Syntax:  [RSK] = RSKalignchannel(RSK, channel, lag, [OPTIONS])
% 
% Applies the lag to minimize  "spikes". Typically used for salinity
% to reverse the effects from temporal C/T mismatches when the
% sensors are moving through regions of high vertical gradients.
%
% If aligning salinity it requires the TEOS-10 toolbox to be installed, to
% allow salinity to be calculated using gsw_SP_from_C.
%
% Inputs: 
%    
%    [Required] - RSK - the input RSK structure, with profiles as read using
%                    RSKreadprofiles
%
%                 channel - Longname of channel to plot (e.g. temperature,
%                   salinity, etc).
%
%                 lag - For salinity, the optimal lags can be calculated
%                   for each profile using RSKgetCTlag.m
%
%    [Optional] - profileNum - the profiles to which to apply the correction. If
%                    left as an empty vector, will do all profiles.
%            
%                direction - the profile direction to consider. Must be either
%                   'down' or 'up'. Defaults to 'down'.
%
%
% Outputs:
%    RSK - the RSK structure with aligned channel values
%
% Example: 
%   
%    rsk = RSKopen('file.rsk');
%    rsk = RSKreadprofiles(rsk, 1:10); % read first 10 downcasts
%
%   1. All downcast profiles with calculated optimal C/T lag.
%    lags = RSKgetCTlag(rsk)
%    rsk = RSKalignchannel(rsk, 'salinity', lags);
%
%   2. Specified profiles (first 4) and C/T lag values (one for each profile)
%    rsk = RSKalignchannel(rsk, 'Dissolved O', [2 1 -1 0], 'profileNum',1:4);
%
%   3. Specified profiles (first 4) and C/T lag value (one for ALL profiles being aligned).
%    rsk = RSKalignchannel(rsk, 'temperature', [2], 'profileNum', 1:4);;
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-11-15

%% Check input and default arguments

validChannelNames = {'Salinity', 'Temperature', 'Conductivity', 'Chlorophyll', 'Dissolved O', 'CDOM', 'Turbidity', 'pH'};
checkChannelName = @(x) any(validatestring(x,validChannelNames));

validDirections = {'down', 'up'};
checkDirection = @(x) any(validatestring(x,validDirections));


%% Parse Inputs

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'channel', checkChannelName);
addRequired(p, 'lag', @isnumeric);
addParameter(p, 'profileNum', [], @isnumeric);
addParameter(p, 'direction', 'down', checkDirection);

parse(p, RSK, channel, lag, varargin{:})

% Assign each input argument
RSK = p.Results.RSK;
channel = p.Results.channel;
lag = p.Results.lag;
profileNum = p.Results.profileNum;
direction = p.Results.direction;



%% Determine if the structure has downcasts and upcasts
isDown = isfield(RSK.profiles.downcast, 'data');
isUp   = isfield(RSK.profiles.upcast, 'data');
switch direction
    case 'up'
        if ~isUp
            error('Structure does not contain upcasts')
        elseif isempty(profileNum)
            profileNum = 1:length(RSK.profiles.upcast.data);
        end
    case 'down'
        if ~isDown
            error('Structure does not contain downcasts')
        elseif isempty(profileNum)
            profileNum = 1:length(RSK.profiles.downcast.data);
        end
end



%% Check to make sure that lags are integers & one value of CTlag or one for each profile
if ~isequal(fix(lag),lag),
    error('Lag values must be integers.')
end

if length(lag) == 1
    if length(profileNum) == 1
    else
        lag = repmat(lag, 1, length(profileNum));
    end
elseif length(lag) > 1
    if length(lag) ~= length(profileNum)
        error(['Length of lag must match number of profiles or be a ' ...
               'single value']);
    end
end



%% Apply lag to salinity from conductivity
if strcmpi(channel, 'salinity')
    hasTEOS = exist('gsw_SP_from_C') == 2;

    if (~hasTEOS) error('Error: Must install TEOS-10 toolbox'); end

    % find column number of C and T
    Scol = find(strncmpi('salinity', {RSK.channels.longName}, 4));
    Ccol = find(strncmpi('conductivity', {RSK.channels.longName}, 4));
    Tcol = find(strncmpi('temperature', {RSK.channels.longName}, 4));
    Tcol = Tcol(1); % only take the first one
    pcol = find(strncmpi('pressure', {RSK.channels.longName}, 4));
    pcol = pcol(1);% some files also have sea pressure.


    counter = 0;
    for i = profileNum
        counter = counter + 1;
            switch direction
              case 'down'
                C = RSK.profiles.downcast.data(i).values(:, Ccol);
                T = RSK.profiles.downcast.data(i).values(:, Tcol);
                p = RSK.profiles.downcast.data(i).values(:, pcol);
              case 'up'
                C = RSK.profiles.upcast.data(i).values(:, Ccol);
                T = RSK.profiles.upcast.data(i).values(:, Tcol);
                p = RSK.profiles.upcast.data(i).values(:, pcol);
            end
            Sbest = gsw_SP_from_C(shiftarray(C, lag(counter)), T, p);
            switch direction
              case 'down'
                RSK.profiles.downcast.data(i).values(:, Scol) = Sbest;
              case 'up'
                RSK.profiles.upcast.data(i).values(:, Scol) = Sbest;
            end
    end
    
% Apply lag to any other channel.    
else
    counter = 0;
    channelCol = find(strncmpi(channel, {RSK.channels.longName}, 4));
    
    for i = profileNum
        counter = counter + 1;
            switch direction
                case 'down'        
                    channelData = RSK.profiles.downcast.data(i).values(:, channelCol);
                    channelShifted = shiftarray(channelData, lag(counter));
                    RSK.profiles.downcast.data(i).values(:, channelCol) = channelShifted;
                case 'up'
                    channelData = RSK.profiles.upcast.data(i).values(:, channelCol);
                    channelShifted = shiftarray(channelData, lag(counter));                    
                    RSK.profiles.upcast.data(i).values(:, channelCol) = channelShifted;
            end
    end
end
end
