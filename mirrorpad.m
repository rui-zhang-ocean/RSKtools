function out = mirrorpad(in, windowLength)

% mirrorpad - Pad a vector by mirroring elements in the vector.
%
% Syntax:  out = mirrorpad(in, windowLength)
% 
% Pads vector with window length of entries at the begining and end of the
% in vector. The added entries are mirrors of in. 
%
% Inputs:
%    in - a vector
%
%    windowLength - The length of the padding on each side of the vector.
%         Must be <= length(in).
%
% Outputs:
%    dnum - MATLAB datenum
%
% Example: 
%    out = mirrorpad([1:10], 3)
% 
%    out =
%
%    [3 2 1 1 2 3 4 5 6 7 8 9 10 9 8 7]
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-12-07



if isrow(in)
    pre = fliplr(in(1:windowLength));
    post = fliplr(in(end-windowLength+1:end));
    out = [pre in post];
elseif iscolumn(in)
    pre = flipud(in(1:windowLength));
    post = flipud(in(end-windowLength+1:end));
    out = [pre; in; post];
else
    error('in must be a row or column vector.')
end
end
