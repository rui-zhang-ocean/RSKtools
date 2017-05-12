function setcolormap(channel)
% Use cmocean colormaps, choose it based on the channel.

if exist('cmocean', 'file')==2 
    cmocean('haline');
    if strcmpi(channel, 'temperature')
        cmocean('thermal'); 
    elseif strcmpi(channel, 'chlorophyll')
        cmocean('algae'); 
    elseif strcmpi(channel, 'backscatter')
        cmocean('matter');
    elseif strcmpi(channel, 'phycoerythrin')
        cmocean('turbid');
    end
else
    colormap default
end

end