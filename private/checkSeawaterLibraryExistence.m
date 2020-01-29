function checkSeawaterLibraryExistence(seawaterLibrary)

hasTEOS = ~isempty(which('gsw_SP_from_C'));
hasSW = ~isempty(which('sw_salt'));

if ~hasTEOS && strcmpi(seawaterLibrary,'TEOS-10')
    RSKerror('No TEOS-10 toolbox found on your MATLAB pathway. Please download it from http://www.teos-10.org/software.htm or specify seawater toolbox.')
elseif ~hasSW && strcmpi(seawaterLibrary,'seawater')
    RSKerror('No seawater toolbox found on your MATLAB pathway.')
else
    return
end

end

