function [RSK] = RSKderiveO2concentration(RSK, varargin)

% RSKderiveO2concentration - Derive O2 concentration from measured O2 
% saturation using equation from R.F.Weiss 1970.
%
% Syntax: [RSK] = RSKderiveO2concentration(RSK,[OPTIONS])
%
% Inputs: 
%    [Required] - RSK - Structure containing measured O2 saturation in unit
%                       of %.
%    
%    [Optional] - unit - Unit of derived O2 concentration. 1, 2 and 3
%                       refers to �mol/l, ml/l and mg/l, respectively. 
%                       Default is 1.
%
% Outputs:
%    RSK - Structure containing derived O2 concentration in unit of �mol/l.
%
% See also: RSKderiveO2saturation.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-08-13


p = inputParser;
addRequired(p, 'RSK', @isstruct);
addParameter(p, 'unit', 1, @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
unit = p.Results.unit;


if ~any(strcmp({RSK.channels.longName},'Salinity'))
    error('RSKderiveO2concentration needs salinity channel. Use RSKderivesalinity...')
end
 
switch unit
    case 1
        unitstring = '�mol/l';
    case 2
        unitstring = 'ml/l';
    case 3
        unitstring = 'mg/l';
end

% Channel shortnames for saturation 
SATname = {'doxy03','doxy25','doxy07','doxy08','doxy09','doxy13','doxy26','doxy22'};
% CONname = {'doxy10','doxy20','doxy21','doxy23','doxy24','doxy27','doxy28'};

% Find temperature and salinity data column
TCol = getchannelindex(RSK,'Temperature');
SCol = getchannelindex(RSK,'Salinity');
O2SCol = find(ismember({RSK.channels.shortName},SATname));

if ~any(O2SCol)
    error('RSK file does not contain O2 saturation channel.')
end

% Get coefficients
a1 = -173.42920; a2 = 249.63390; a3 = 143.34830; a4 = -21.84920;
b1 = -0.0330960; b2 = 0.0142590; b3 = -0.00170;

castidx = getdataindex(RSK);
k = 1;
for c = O2SCol    
    suffix = sum(strncmpi('Dissolved O2',{RSK.channels.longName},12)) + 1;
    RSK = addchannelmetadata(RSK, ['Dissolved O2' num2str(suffix)], unitstring);
    O2CCol = getchannelindex(RSK, ['Dissolved O2' num2str(suffix)]);
    
    for ndx = castidx
        temp = (RSK.data(ndx).values(:,TCol) * 1.00024 + 273.15) /100.0;
        sal = RSK.data(ndx).values(:,SCol);
        oxpercent = RSK.data(ndx).values(:,O2SCol(k));   
        oxsatmll = oxpercent.* exp(a1 + a2 ./ temp + a3 * log(temp) + a4 * temp + sal.* (b1 + b2 * temp + b3 * temp .* temp)) /100.0; % ml/l      
        switch unit
            case 1
                RSK.data(ndx).values(:,O2CCol) = 44.659 * oxsatmll; % default, convert to �mol/l
            case 2
                RSK.data(ndx).values(:,O2CCol) = oxsatmll; % ml/l
            case 3
                RSK.data(ndx).values(:,O2CCol) = 1.4276 * oxsatmll; % convert to mg/l
        end
    end    
    k = k + 1;
end

logentry = (['O2 concentration is derived from measured O2 saturation, in unit of ' unitstring '.']);
RSK = RSKappendtolog(RSK, logentry);

end

