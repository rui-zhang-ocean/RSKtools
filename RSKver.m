function [v, vsnMajor, vsnMinor, vsnPatch, RSK]  = RSKver(RSK)

% RSKver - Returns the version of the RSK file.
%
% Syntax:  [v, vsnMajor, vsnMinor, vsnPatch] = RSKver(RSK)
%
% RSKver will return the most recent version of the RSK file. If it is
% 1.13.0 it will check if it is a bug and fix it in the database.
%
% Inputs:
%    RSK - Structure containing the logger metadata and thumbnails
%          returned by RSKopen.
%
% Output:
%    v - The lastest version of the RSK file.
%    vsnMajor - The latest version number of category major.
%    vsnMinor - The latest version number of category minor.
%    vsnPatch - The latest version number of category patch.
%    RSK - RSK structure with updated dbInfo if required.
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-04-27

v = RSK.dbInfo(end).version;
vsn = textscan(v,'%s','delimiter','.');
s=size(vsn{1});
if s(1) ~= 3
    disp('Version unreadable')
    vsnMajor = 0;
    vsnMinor=0;
    vsnPatch=0;
else
    vsnMajor = str2double(vsn{1}{1});
    vsnMinor = str2double(vsn{1}{2});
    vsnPatch = str2double(vsn{1}{3});
end

% Bug in RSK schema 1.13.0
if  (vsnMajor == 1)&&(vsnMinor == 13)&&(vsnPatch == 0) && length(RSK.dbInfo)>1 && strcmpi(RSK.dbInfo(end).type,'full')
    vsnMajorlast = 1;
    vsnMinorlast = 13;
    vsnPatchlast = 0;
    for ndx = 1:length(RSK.dbInfo)-1
        if ~strcmpi(RSK.dbInfo(ndx).type,'skinny')
            v = RSK.dbInfo(ndx).version;
            vsn = textscan(v,'%s','delimiter','.');
            vsnMajor = str2double(vsn{1}{1});
            vsnMinor = str2double(vsn{1}{2});
            vsnPatch = str2double(vsn{1}{3});
            if vsnMajor > vsnMajorlast || (vsnMajor == vsnMajorlast)&&(vsnMinor > vsnMinorlast) || (vsnMajor == vsnMajorlast)&&(vsnMinor == vsnMinorlast)&&(vsnPatch > vsnPatchlast)
                    vsnMajorlast = vsnMajor;
                    vsnMinorlast = vsnMinor;
                    vsnPatchlast = vsnPatch;
                    type = RSK.dbInfo(ndx).type;
            end
        end
    end
    v = [num2str(vsnMajorlast) '.' num2str(vsnMinorlast) '.' num2str(vsnPatchlast)];
    vsnMajor = vsnMajorlast;
    vsnMinor = vsnMinorlast;
    vsnPatch = vsnPatchlast;
    
    % write fix to file
    mksqlite('begin');
    mksqlite(['INSERT INTO `dbInfo` VALUES ("' v '","' type '")']);
    mksqlite('commit');
    mksqlite('analyze');
    
    RSK.dbInfo = mksqlite('select version,type from dbInfo');
end

end