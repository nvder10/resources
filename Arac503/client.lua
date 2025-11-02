function Arac()
    local txd = engineLoadTXD ('arac.txd')
    engineImportTXD(txd,503)
    local dff = engineLoadDFF('arac.dff',503)
    engineReplaceModel(dff,503)
end
addEventHandler('onClientResourceStart',getResourceRootElement(getThisResource()),Arac)


--------------------------------------------------------

-- Sitemiz : https://sparrow-mta.blogspot.com/
-- Facebook : https://facebook.com/sparrowgta/
-- İnstagram : https://instagram.com/sparrowmta/
-- YouTube : https://youtube.com/c/SparroWMTA/

-- Discord : https://discord.gg/DzgEcvy

--------------------------------------------------------