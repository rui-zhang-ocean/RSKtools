function [v, vsnMajor, vsnMinor, vsnPatch]  = RSKver(RSK)

% RSKver - Returns the version of the RSK file.
%
% Syntax:  [v, vsnMajor, vsnMinor, vsnPatch] = RSKver(RSK)
%
% RSKver will return the most recent version of the RSK file.
%
% Inputs:
%    RSK - Structure containing the logger metadata and thumbnails
%          returned by RSKopen.
%
% Output:
%    v - The lastest version of the RSK file.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2016-12-19

v = RSK.dbInfo(end).version;
vsn = textscan(v,'%s','delimiter','.');
s=size(vsn);
if s(2) ~= 3
    disp('Version unreadable')
    vsnMajor = 0;
    vsnMinor=0;
    vsnPatch=0;
else
vsnMajor = str2double(vsn{1}{1});
vsnMinor = str2double(vsn{1}{2});
vsnPatch = str2double(vsn{1}{3});
end
end
