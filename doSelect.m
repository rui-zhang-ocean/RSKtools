function [results] = doSelect(RSK, sql)

    mksqlite('open', RSK.filename);
    results = mksqlite(sql);
    mksqlite('close')
    
end