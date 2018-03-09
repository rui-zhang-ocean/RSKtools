function [RSK, holdpts] = RSKcorrecthold(RSK, varargin)

% RSKcorrecthold - Replace zero-order hold points with interpolated
%                  value or NaN.
%
% Syntax:  [RSK, holdpts] = RSKcorrecthold(RSK, [OPTIONS])
% 
% The analog-to-digital (A2D) converter on RBR instruments must
% recalibrate periodically.  In the time it takes for the calibration
% to finish, one or more samples are missed.  The onboard firmware
% fills the missed sample with the same data measured during the
% previous sample, a simple technique called a zero-order hold.
%
% The function identifies zero-hold points by looking for where
% consecutive differences for each channel are equal to zero, and
% replaces them with an interpolated value or a NaN.
%
% An example of where zero-order holds are important is when computing
% the vertical profiling rate from pressure.  Zero-order hold points
% produce spikes in the profiling rate at regular intervals, which can
% cause the points to be flagged by RSKremoveloops.
%
%
% Inputs:
%   [Required] - RSK - Structure containing logger data.
%
%
%   [Optional] - channel - Longname of channel to correct the zero-order
%                hold (e.g., temperature, salinity, etc)
%
%                profile - Profile number. Default is all available
%                profiles.
%
%                direction - 'up' for upcast, 'down' for downcast, or
%                'both' for all. Default is all directions available.
%
%                action - Action to perform on a hold point. The default is
%                'nan', whereby hold points are replaced with NaN. Another
%                option is 'interp', whereby hold points are replaced with
%                values calculated by linearly interpolating from the
%                neighbouring points.
%
%                diagnostic - To give a diagnostic plot on the first 
%                profile of the first channel or not (1 or 0). Original, 
%                processed data and zero-order hold points will be plotted 
%                to show users how the algorithm works. Default is 0.
%
% Outputs:
%    RSK - Structure with zero-order hold corrected values.
%
%    holdpts - Structure containing the index of the corrected hold points; 
%              if more than one channel has hold points, hold is a structure
%              with a field for each channel.  
%
% Example: 
%    [RSK, holdpts] = RSKcorrecthold(RSK)
%     OR
%    [RSK, holdpts] = RSKcorrecthold(RSK, 'channel', 'Temperature', 'action', 'interp','diagnostic',1); 
%
% See also: RSKdespike, RSKremoveloops, RSKsmooth.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-01-24

validActions = {'interp', 'nan'};
checkAction = @(x) any(validatestring(x,validActions));

validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'channel','all');
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'direction', [], checkDirection);
addParameter(p, 'action', 'nan', checkAction);
addParameter(p, 'diagnostic', 0, @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
channel = p.Results.channel;
profile = p.Results.profile;
direction = p.Results.direction;
action = p.Results.action;
diagnostic = p.Results.diagnostic;

chanCol = [];
channels = cellchannelnames(RSK, channel);
for chan = channels
    chanCol = [chanCol getchannelindex(RSK, chan{1})];
end
castidx = getdataindex(RSK, profile, direction);

%loop through channels
for c = chanCol 
    k = 1;
    for ndx = castidx
        in = RSK.data(ndx).values(:,c);
        intime = RSK.data(ndx).tstamp; 
        [out, index] = correcthold(in, intime, action);  
        RSK.data(ndx).values(:,c) = out;
        holdpts(k).index{c} = index;
        if k == 1 && c == chanCol(1) && diagnostic == 1; 
            doDiagPlot(RSK, in, out, index, ndx, channel, c); 
        end 
        k = k+1;
    end     
end

logentry = sprintf(['Zero-order hold corrected for ' repmat('%s ', 1, length(channels)) 'channel.' ' Hold points were treated with %s.'], channels{:}, action);
RSK = RSKappendtolog(RSK, logentry);

    %% Nested Functions
    function [y, I] = correcthold(x, t, action)
    % Replaces zero-order hold values with either a NaN or interpolated 
    % value using the neighbouring points. 

        y = x;
        I = find(diff(x) == 0) + 1;
        good = find(ismember(1:length(t),I) == 0);
        hashold = ~isempty(I);

        if hashold,
            switch action  
              case 'interp'
                y(I) = interp1(t(good), x(good), t(I)); 
              case 'nan'
                y(I) = NaN;
            end
        end  
    end

    %% Nested Functions
    function [] = doDiagPlot(RSK, in, out, index, ndx, channel, c)
    % plot when diag == 1
        if strcmp(channel,'all');
            channel = RSK.channels(1).longName; c = 1;
        else
            channel = channel(1); c = c(1);
        end
        
        presCol = getchannelindex(RSK,'Pressure');
        fig = figure;
        set(fig, 'position', [10 10 500 800]);
        plot(in,RSK.data(ndx).values(:,presCol),'-c','linewidth',2);
        hold on
        plot(out,RSK.data(ndx).values(:,presCol),'--k'); 
        hold on
        plot(in(index),RSK.data(ndx).values(index,presCol),...
            'or','MarkerEdgeColor','r','MarkerSize',5);
        ax = findall(gcf,'type','axes');
        set(ax, 'ydir', 'reverse');
        xlabel([RSK.channels(c).longName ' (' RSK.channels(c).units ')']);
        ylabel(['Pressure (' RSK.channels(presCol).units ')']);
        if isfield(RSK.data,'profilenumber') && isfield(RSK.data,'direction')
            title(['Profile ' num2str(RSK.data(ndx).profilenumber) ' ' RSK.data(ndx).direction 'cast']);
        end
        legend('Original data','Correctedhold data','Holds points','Location','Best');
        set(findall(fig,'-property','FontSize'),'FontSize',15);
    end
end