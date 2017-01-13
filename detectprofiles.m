function [upcaststart, downcaststart] = detectprofiles(pressure, timestamp, conductivity, profileThreshold)

% detectprofiles - implements the logger profile detection.
%
% Syntax:  [RSK] = detectprofiles(pressure, timestamp)
% 
% detectprofiles is a helper function that implements the algorithm used by
% the logger to find upcasts and downcasts by going through the pressure
% time series.
%
% Inputs:
%    
%    pressure - The pressure time series.
%
%    timestamp - The time associated with the pressure time series.
%
%    conductivity - A optional input, checked that the logger is in the
%        water before detecting a profile. If no conductivity channel use [].
%    
%    pressureThreshold - The pressure difference required to detect a
%        profile. Standard is 3dbar, or 1/4(max(pressure)-min(pressure).
%
% Outputs:
%
%    upcaststart - The timestamp of the start of upcasts.
%
%    downcaststart - The timestamp of the start of downcasts.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-01-13

%% Set up
detectcaststate = 0; % 0 unknown, 1 down, 2 up
evt = 0; % 0 nothing new 1 we are descending 2 profile detect
hasC = ~isempty(conductivity);


%% The Profile Detection
k=1;
klast = k;
d = 1;
u = 1;
maxpressure=pressure(1);
minpressure=pressure(1);
while(k<length(timestamp))
    %
    % profile detection part
    evt=0;
    if ~hasC || conductivity(k)>0.05
        
        switch  detectcaststate

            case 0   % unknown
                if (pressure(k)>maxpressure)
                    maxpressure=pressure(k);
                    if (maxpressure-minpressure>profileThreshold)
                        detectcaststate=1;
                        evt=1;
                    end
                end
                if (pressure(k)<minpressure)
                    minpressure=pressure(k);
                    if (maxpressure-minpressure>13)
                        detectcaststate=2;
                        evt=2;
                    end
                end

            case 1   % down
                if (pressure(k)>maxpressure)
                    maxpressure=pressure(k);
                end
                if (pressure(k)<minpressure)
                    minpressure=pressure(k);
                end
                if (maxpressure-pressure(k)>max(profileThreshold, 0.05*(maxpressure-minpressure))) % we are going up, set by profile detection algorithm
                    detectcaststate=2;
                    evt=2;
                    minpressure=pressure(k);
                else
                    detectcaststate=1;  
                end


            case 2   % up
                if (pressure(k)>maxpressure)
                    maxpressure=pressure(k);
                end
                if (pressure(k)<minpressure)
                    minpressure=pressure(k);
                end
                if (pressure(k)-minpressure>max(profileThreshold, 0.05*(maxpressure-minpressure))) % we are going down, set by profile detection algorithm
                    detectcaststate=1;
                    evt=1;
                    maxpressure=pressure(k);
                else
                    detectcaststate=2;
                end

        end



        if evt == 1
            % downcast detected
            profiletime = timestamp(klast:k);
            idx = find(pressure(klast:k) == minpressure);
            downcaststart(d) = profiletime(idx(end));
            d = d+1;
            klast = k;

        elseif evt ==2
            %upcast detected
            profiletime = timestamp(klast:k);
            idx = find(pressure(klast:k) == maxpressure);
            upcaststart(u) = profiletime(idx(end));
            u = u+1;
            klast = k;
        end
    end
    k= k+1;
end
upcaststart = upcaststart';
downcaststart = downcaststart';
end