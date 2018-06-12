function RSK = RSKcorrectTM(RSK, varargin) 
    
% RSKcorrectTM - Apply thermal mass correction to conductivity.
%
% Syntax:  [RSK] = RSKcorrectTM(RSK, [OPTIONS])
% 
% The conductivity cell itself could store heat and provides "inertia" 
% against temperature fluctuations, which introduces bias when deriving
% salinity, known as thermal mass effect. The function applies an algorithm
% introduced by Lueck and Picklo 1990 to eliminate the effect. To determine
% the values of the coefficients, please see:
% Lueck, R. G., 1990: Thermal inertia of conductivity cells: Theory. 
% J. Atmos. Oceanic Technol., 7, 741?755
% Lueck, R. G., and J. J. Picklo, 1990: Thermal inertia of conductivity 
% cells: Observations with a Sea-Bird cell. J. Atmos. Oceanic Technol.,
% 7, 756?768
%
% Inputs: 
%   [Required] - RSK - Structure containing the logger data.
%               
%   [Optional] - alpha - Coefficient alpha. Default is 0.04
%
%                beta - Coefficient beta. Default is 0.1
%
%                gamma - Scale factor. Default is 1 when conductivity is
%                      measured in mS/cm
%
%                profile - Profile number. Default is all available
%                      profiles.
% 
%                direction - 'up' for upcast, 'down' for downcast, or
%                      'both' for all. Default is all directions available.
% 
%                visualize - To give a diagnostic plot on specified
%                      profile number(s). Original and processed data will
%                      be plotted to show users how the algorithm works.
%                      Default is 0.
%
% Outputs:
%    RSK - Structure with processed values.
%
% Example: 
%    RSK = RSKcorrectTM(RSK)
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-06-12


validDirections = {'down', 'up', 'both'};
checkDirection = @(x) any(validatestring(x,validDirections));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'alpha', 0.04, @isnumeric);
addParameter(p, 'beta', 0.1, @isnumeric);
addParameter(p, 'gamma', 1, @isnumeric);
addParameter(p, 'profile', [], @isnumeric);
addParameter(p, 'direction', [], checkDirection);
addParameter(p, 'visualize', 0, @isnumeric);
parse(p, RSK, varargin{:});

RSK = p.Results.RSK;
alpha = p.Results.alpha;
beta = p.Results.beta;
gamma = p.Results.gamma;
profile = p.Results.profile;
direction = p.Results.direction;
visualize = p.Results.visualize;


fs = round(1/RSKsamplingperiod(RSK));
a = 4*fs/2*alpha/beta * 1/(1 + 4*fs/2/beta);
b = 1 - 2*a/alpha;
Tcol = getchannelindex(RSK,'Temperature');
Ccol = getchannelindex(RSK,'Conductivity');

castidx = getdataindex(RSK, profile, direction);

if visualize ~= 0; [raw, diagndx] = checkDiagPlot(RSK, visualize, direction, castidx); end

for ndx = castidx
    T = RSK.data(ndx).values(:,Tcol);
    C = RSK.data(ndx).values(:,Ccol);
    Ccor = zeros(size(T));
    for k = 2:length(T);
        Ccor(k) = -b*Ccor(k-1) + gamma*a*(T(k) - T(k-1));
    end   
    RSK.data(ndx).values(:,Ccol) = C + Ccor;
end

if visualize ~= 0      
    for d = diagndx;
        figure
        doDiagPlot(RSK,raw,'ndx',d,'channelidx',Ccol,'fn',mfilename); 
    end
end 

logentry = ['Thermal mass correction applied with gamma = ' num2str(gamma) ',alpha = ' num2str(alpha) 'and beta = ' num2str(beta) '.'];
RSK = RSKappendtolog(RSK, logentry);
    
end
