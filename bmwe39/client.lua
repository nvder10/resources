function replaceModel()
txd = engineLoadTXD('car.txd',420)
engineImportTXD(txd,420)
dff = engineLoadDFF('car.dff',420)
engineReplaceModel(dff,420)
end
addEventHandler ( 'onClientResourceStart', getResourceRootElement(getThisResource()), replaceModel)
