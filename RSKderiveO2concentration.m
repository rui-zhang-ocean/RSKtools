function [RSK] = RSKderiveO2concentration(RSK)

% RSKderiveO2concentration - Derive O2 concentration from measured O2 
% saturation using equation from R.F.Weiss 1970.
%
% Syntax: [RSK] = RSKderiveO2concentration(RSK)
%
% Inputs: 
%    RSK - Structure containing measured O2 saturation.
%
% Outputs:
%    RSK - Structure containing derived O2 concentration.
%
% See also: RSKderiveO2saturation.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2018-08-02


p = inputParser;
addRequired(p, 'RSK', @isstruct);
parse(p, RSK)

RSK = p.Results.RSK;


if ~any(strcmp({RSK.channels.longName},'Salinity'))
    error('RSKderiveO2concentration needs salinity channel. Use RSKderivesalinity...')
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
    RSK = addchannelmetadata(RSK, ['Dissolved O2' num2str(suffix)], 'µmol/l');
    O2CCol = getchannelindex(RSK, ['Dissolved O2' num2str(suffix)]);

    for ndx = castidx
        temp = (RSK.data(ndx).values(:,TCol) * 1.00024 + 273.15) /100.0;
        sal = RSK.data(ndx).values(:,SCol);
        oxpercent = RSK.data(ndx).values(:,O2SCol(k));   
        oxsatmll = oxpercent.* exp(a1 + a2 ./ temp + a3 * log(temp) + a4 * temp + sal.* (b1 + b2 * temp + b3 * temp .* temp)) /100.0; % ml/l
        RSK.data(ndx).values(:,O2CCol) = 44.659*oxsatmll; % convert to µmol/l
    end
    k = k + 1;
end

logentry = ('O2 concentration derived from measured O2 saturation.');
RSK = RSKappendtolog(RSK, logentry);

end

