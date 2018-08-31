function [RSK] = RSKderiveO2(RSK, toDerive, varargin)

% RSKderiveO2 - Derive O2 concentration from measured O2 saturation using 
% equation from R.F.Weiss 1970.
% OR
% Derive O2 saturation from measured O2 concentration using equation from 
% Garcia and Gordon, 1992.
%
% Syntax: [RSK] = RSKderiveO2(RSK,toDerive,[OPTIONS])
%
% Inputs: 
%    [Required] - RSK - Structure containing measured O2 saturation or
%                       concentration.
%
%                 toDerive - O2 variable to derive, should only be
%                       'saturation' or 'concentration'.
%    
%    [Optional] - unit - Unit of derived O2 concentration. Valid inputs 
%                       include µmol/l, ml/l and mg/l. Default is µmol/l.
%                       Only effective when toDerive is concentration.
%
% Outputs:
%    RSK - Structure containing derived O2 concentration or saturation.
%
% Example:
%    RSK = RSKderiveO2(RSK, 'saturation', 'unit', 'ml/l')
%
% See also: deriveO2concentration, deriveO2saturation.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-08-31


validToDerive = {'concentration','saturation'};
checkToDerive = @(x) any(validatestring(x,validToDerive));

validUnits = {'µmol/l', 'ml/l','mg/l'};
checkUnit = @(x) any(validatestring(x,validUnits));

p = inputParser;
addRequired(p, 'RSK', @isstruct);
addRequired(p, 'toDerive', checkToDerive);
addParameter(p, 'unit', 'µmol/l', checkUnit);
parse(p, RSK, toDerive, varargin{:})

RSK = p.Results.RSK;
toDerive = p.Results.toDerive;
unit = p.Results.unit;


if strcmp(toDerive,'concentration')
    RSK = deriveO2concentration(RSK,'unit',unit);
else
    RSK = deriveO2saturation(RSK);
end

end

