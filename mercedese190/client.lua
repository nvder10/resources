function replaceModel()
txd = engineLoadTXD('car.txd',445)
engineImportTXD(txd,445)
dff = engineLoadDFF('car.dff',445)
engineReplaceModel(dff,445)
end
addEventHandler ( 'onClientResourceStart', getResourceRootElement(getThisResource()), replaceModel)
--addCommandHandler ( 'reloadcar', replaceModel )

-- Sitemiz : https://sparrow-mta.blogspot.com/

-- Facebook : https://facebook.com/sparrowgta/
-- İnstagram : https://instagram.com/sparrowmta/
-- YouTube : https://www.youtube.com/@TurkishSparroW/

-- Discord : https://discord.gg/DzgEcvy