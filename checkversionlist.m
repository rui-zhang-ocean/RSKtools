function [v, vsnMajorlast, vsnMinorlast, vsnPatchlast] = checkversionlist(RSK)
% checkversionlist - Checks that the last dbInfo entry is the most recent.
%
% Syntax:  [v, vsnMajorlast, vsnMinorlast, vsnPatchlast] = checkversionlist(RSK);
%
% checkversionlist check to see if the most recent version in dbInfo table is
% 1.13.0. If it is the case it will check if there is a newer version
% available, if there is RSKtools will use the correct version and type
% associated with the file.  
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
%
% Author: RBR Ltd. Ottawa ON, Canada
% email: support@rbr-global.com
% Website: www.rbr-global.com
% Last revision: 2017-05-01
[~, vsnMajor, vsnMinor, vsnPatch] = RSKver(RSK);

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
    
% write fix to file
%     try
%         mksqlite('begin');
%         mksqlite(['INSERT INTO `dbInfo` VALUES ("' v '","' type '")']);
%         mksqlite('commit');
%     catch
%         mksqlite('rollback');
%     end
%     RSK.dbInfo = mksqlite('select version,type from dbInfo');
end
end