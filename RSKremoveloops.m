function [RSK, flagidx] = RSKremoveloops(RSK, varargin)

% RSKremoveloops - Remove data exceeding a threshold profiling rate and
% with reversed pressure (loops).
%
% Syntax:  [RSK, flagidx] = RSKremoveloops(RSK, [OPTIONS])
% 
% Identifies and flags data obtained when the logger vertical profiling
% speed falls below a threshold value or when the logger reversed the
% desired cast direction (forming a loop). The flagged data is replaced 
% with NaNs.  All logger channels except depth are affected.    
% 
% Differenciates depth to estimate the profiling speed. The depth channel
% is first smoothed with a 3-point running average to reduce noise. 
% 
% Inputs:
%   [Required] - RSK - RSK structure with logger data and metadata
%
%   [Optional] - profile - Profile number. Defaults to all profiles.
%
%                direction - 'up' for upcast, 'down' for downcast, or
%                      'both' for all. Defaults to all directions
%                       available.
% 
%                threshold - Minimum speed at which the profile must
%                       be taken. Defaults to 0.25 m/s.
%
%                diagnostic - To give a diagnostic plot on the first 
%                      profile of the first channel or not (1 or 0). 
%                      Original, processed data and loops will be plotted 
%                      to show users how the algorithm works. Default is 0.
%
% Outputs:
%    RSK - Structure with data filtered by threshold profiling speed and
%          removal of loops.
%
%    flagidx - Index of the samples that are filtered.
%
% Example: 
%    RSK = RSKopen('file.rsk');
%    RSK = RSKreadprofiles(RSK);
%    RSK = RSKremoveloops(RSK);
%    OR
%    RSK = RSKremoveloops(RSK,'profile',7:9,'direction','down','threshold',0.3,'diagnostic',1);
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-03-09

validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'direction', [], checkDirection);
addParameter(p, 'threshold', 0.25, @isnumeric);
addParameter(p, 'diagnostic', 0, @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
profile = p.Results.profile;
direction = p.Results.direction;
threshold = p.Results.threshold;
diagnostic = p.Results.diagnostic;



try
    Dcol = getchannelindex(RSK, 'Depth');
catch
    error('RSKremoveloops requires a depth channel to calculate velocity (m/s). Use RSKderivedepth...');
end

if diagnostic == 1; raw = RSK; end % Save raw data if diagnostic plot is required

castidx = getdataindex(RSK, profile, direction);
k = 1;
for ndx = castidx
    d = RSK.data(ndx).values(:,Dcol);
    depth = runavg(d, 3, 'nan');
    time = RSK.data(ndx).tstamp;

    velocity = calculatevelocity(depth, time);
    
    if getcastdirection(depth, 'up')
      flag = (velocity > -threshold);
      cm = cummin(depth);
      flag((depth - cm) > 0) = true;
    else
      flag = velocity < threshold; 
      cm = cummax(depth);
      flag((depth - cm) < 0) = true;
    end
    
    flagChannels = ~strcmpi('Depth', {RSK.channels.longName});    
    RSK.data(ndx).values(flag,flagChannels) = NaN;
    flagidx(k).index = find(flag);
    if k == 1 && diagnostic == 1; 
        doDiagPlot(RSK, raw, find(flag), ndx); 
    end 
    k = k + 1;
end



logdata = logentrydata(RSK, profile, direction);
logentry = ['Samples measured at a profiling velocity less than ' num2str(threshold) ' m/s were replaced with NaN on ' logdata '.'];
RSK = RSKappendtolog(RSK, logentry);

    %% Nested Functions
    function [] = doDiagPlot(RSK, raw, index, ndx)
    % plot when diag == 1, only plot variable in RSK.channels(1)
        presCol = getchannelindex(RSK,'Pressure');
        fig = figure;
        set(fig, 'position', [10 10 500 800]);
        plot(raw.data(ndx).values(:,1),raw.data(ndx).values(:,presCol),'-c','linewidth',2);
        hold on
        plot(RSK.data(ndx).values(:,1),RSK.data(ndx).values(:,presCol),'--k'); 
        hold on
        plot(raw.data(ndx).values(index,1),raw.data(ndx).values(index,presCol),...
            'or','MarkerEdgeColor','r','MarkerSize',5);
        ax = findall(gcf,'type','axes');
        set(ax, 'ydir', 'reverse');
        xlabel([RSK.channels(1).longName ' (' RSK.channels(1).units ')']);
        ylabel(['Pressure (' RSK.channels(presCol).units ')']);
        title(['Profile ' num2str(RSK.data(ndx).profilenumber) ' ' RSK.data(ndx).direction 'cast']);
        legend('Original data','Removedloop data','Loops','Location','Best');
        set(findall(fig,'-property','FontSize'),'FontSize',15);
    end

end
