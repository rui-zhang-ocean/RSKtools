function [wwevt] = detectprofiles(pressure, timestamp, conductivity, profileThreshold)

% detectprofiles - implements the logger profile detection.
%
% Syntax:  [wwevt] = detectprofiles(pressure, timestamp)
% 
% detectprofiles is a helper function that implements the algorithm used by
% the logger to find upcast and downcast events during the pressure time
% series. If conductivity is also input the algorithm can detect when the
% logger is out of the water.
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
%    wwevt - A matrix containing the timestamp in the first column and an
%            event index describing the start of a event (1=downcast,
%            2=upcast, 3=outofwater)
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-03-08

%% Set up
detectcaststate = 0; % 0 unknown, 1 down, 2 up
evt = 0; % 0 nothing new 1 we are descending 2 profile detect
hasC = ~isempty(conductivity);


%% The Profile Detection
k=1;
klast = k;
n=1;
maxpressure=pressure(1);
minpressure=pressure(1);
wwevt = zeros(1,2);
while(k<length(timestamp))
    %
    % profile detection part
    evt=0;
    if hasC && conductivity(k)<0.05
        evt=3;
        minpressure=pressure(k);
    else
        
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
    end

    if evt == 1
        % downcast detected
        profiletime = timestamp(klast:k);
        idx = find(pressure(klast:k) == minpressure);
        wwevt(n,:) = [profiletime(idx(end)) evt];
        n = n+1;
        klast = k;

    elseif evt ==2
        % upcast detected
        profiletime = timestamp(klast:k);
        idx = find(pressure(klast:k) == maxpressure);
        wwevt(n,:) = [profiletime(idx(end)) evt];
        n = n+1;
        klast = k;
        
    elseif evt == 3
        % If logger is out of water mark timestamp a out of water
        if n==1
            wwevt(n,:) = [timestamp(k) evt];
            n = n+1;
            klast = k;
        elseif wwevt(n-1,2) ~= 3
            wwevt(n,:) = [timestamp(k) evt];
            n = n+1;
            klast = k;
        end
    end
    k= k+1;
end

end