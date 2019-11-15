function RSK = splitprofiles(RSK,varargin)

% splitprofiles - Function that finds time gaps in profiles and splits
% profiles accordingly
%
% Syntax: RSK = splitprofiles(RSK,[OPTIONS])
%
% This function will find time gaps during upcasts that are greater than
% 2min (indicating there is a transmitting error). The upcast is split into 
% two profiles at the gap spot. An upcast is added to the data field.
%
% Note: the function is designed for wirewalker data only, one must remove
% all the downcasts before using the function.
%
% Inputs: 
%    [Required] - RSK - RSK structure with profiles
%
%    [Optional] - timeGap - time interval threshold (in sec) to detect 
%                           overlapped profiles, default is 2 min
%
% Output: 
%       RSK - Same as above but containing more profiles if gaps were found
% 
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2019-09-26


p = inputParser;
addRequired(p,'RSK', @isstruct);
addParameter(p,'timeGap', 120, @isnumeric);
parse(p, RSK, varargin{:})

RSK = p.Results.RSK;
timeGap = p.Results.timeGap;


pnum = 1;
for ndx = 1:length(RSK.data)
    
    t = RSK.data(ndx).tstamp;
    
    [gapindex,profilegap] = find(diff(t) > timeGap/86400); % two minutes
    
    if ~isempty(profilegap)
        gapindex = [1; gapindex];
        for k = 1:length(gapindex)-1
            
            if k ~= length(gapindex)-1;
                data(pnum).tstamp = RSK.data(ndx).tstamp(gapindex(k):gapindex(k+1));
                data(pnum).values = RSK.data(ndx).values(gapindex(k):gapindex(k+1),:);
            else
                data(pnum).tstamp = RSK.data(ndx).tstamp(gapindex(k):end);
                data(pnum).values = RSK.data(ndx).values(gapindex(k):end,:);
            end      
            data(pnum).direction = 'up';
            data(pnum).profilenumber = pnum;
            pnum = pnum + 1;
        end
    else
        data(pnum).tstamp = t;
        data(pnum).values = RSK.data(ndx).values;
        data(pnum).direction = 'up';
        data(pnum).profilenumber = pnum;
        pnum = pnum + 1;
    end
end

end 
