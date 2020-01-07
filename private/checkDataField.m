function checkDataField(RSK)

if ~isfield(RSK,'data')
    error('RSK structure do not contain any data, try RSKreaddata or RSKreadprofiles first.')
end

end