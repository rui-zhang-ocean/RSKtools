function out = zeroorderholdpad(in, padSize)

% zeroorderholdpad - Pad a vector by entering Nan.
%
% Syntax:  out = zeroorderholdpad(in, windowLength)
% 
% Pads vector with window length of entries at the beginning and end of the
% in vector. The added entries are repeated first and last entry.
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
%    out = zeroorderholdpad([1:10], 3)
% 
%    out =
%
%    [1 1 1 1 2 3 4 5 6 7 8 9 10 10 10 10]
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-04-19


if isrow(in)
    pre = repmat(in(1), [1,padSize]);
    post = repmat(in(end), [1,padSize]);
    out = [pre in post];
elseif iscolumn(in)
    pre = repmat(in(1), [padSize,1]);
    post = repmat(in(end), [padSize,1]);
    out = [pre; in; post];
else
    error('in must be a row or column vector.')
end
end
