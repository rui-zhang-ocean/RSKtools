function out = nanpad(in, padSize)

% nanpad - Pad a vector by entering Nan.
%
% Syntax:  out = nanpad(in, windowLength)
% 
% Pads vector with padSize of entries at the beginning and end of the
% in vector. The added entries are NaN
%
% Inputs:
%    in - a vector
%
%    padSize - The length of the padding on each side of the vector.
%         Must be <= length(in).
%
% Outputs:
%    out - padded in vector of length length(in)+2*padSize
%
% Example: 
%    out = nanpad([1:10], 3)
% 
%    out =
%
%    [NaN NaN NaN 1 2 3 4 5 6 7 8 9 10 NaN NaN NaN]
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-04-03


if isrow(in)
    pad = NaN(1,padSize);
    out = [pad in pad];
elseif iscolumn(in)
    pad = NaN(padSize,1);
    out = [pad; in; pad];
else
    error('in must be a row or column vector.')
end
end
