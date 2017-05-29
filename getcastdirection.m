function [castdir] = getcastdirection(pressure, direction)

% selectcastdirection - Returns TRUE for a pressure array that is in the
% speicifed direction.
%
% Syntax:  [castdir] = getcastdirection(pressure, direction)
%
% Inputs:
%    pressure - The time series of pressure that the direction is being
%               checked.
%
%    direction - up or down.
%
% Outputs:
%    castdir - True if the pressure is in the direction specified.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-19

if isUpcast(pressure) && strcmpi(direction, 'up')
    castdir = 1;
elseif isDowncast(pressure) && strcmpi(direction, 'down')
    castdir = 1;
else
    castdir = 0;
end 


    function up = isUpcast(pressure)
    % Returns true if pressure decreases. False is pressure increases.

        if pressure(1) > pressure(end)
            up = 1;
        else
            up = 0;
        end

    end


    function down = isDowncast(pressure)
    % Returns true if pressure increases. False is pressure decreases.

        if pressure(1) < pressure(end)
            down = 1;
        else
            down = 0;
        end

    end
end
