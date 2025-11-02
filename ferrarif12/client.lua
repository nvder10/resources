--By Reventon

function AracYukle560()
    local txd = engineLoadTXD ('Dosyalar/1.txd')
    engineImportTXD(txd,560)
    local dff = engineLoadDFF('Dosyalar/2.dff',560)
    engineReplaceModel(dff,560)
end
addEventHandler('onClientResourceStart',getResourceRootElement(getThisResource()),AracYukle560)

--By Reventon