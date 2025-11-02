function Arac()
    local txd = engineLoadTXD ('arac.txd')
    engineImportTXD(txd,546)
    local dff = engineLoadDFF('arac.dff',546)
    engineReplaceModel(dff,546)
	setVehicleModelWheelSize(546, "all_wheels", 0.9)
end
addEventHandler('onClientResourceStart',getResourceRootElement(getThisResource()),Arac)


-- Web Site : https://sparrow-mta.blogspot.com/
-- Facebook : https://facebook.com/sparrowgta/
-- İnstagram : https://instagram.com/sparrowmta/
-- YouTube: https://www.youtube.com/@TurkishSparroW/
-- Discord : https://discord.gg/DzgEcvy