--Sitemiz : https://sparrow-mta.blogspot.com/

--Facebook : https://facebook.com/sparrowgta/
--İnstagram : https://instagram.com/sparrowmta/
--YouTube : https://www.youtube.com/@TurkishSparroW/

--Discord : https://discord.gg/DzgEcvy

function replaceModel()

txd = engineLoadTXD( "hosp.txd", 5708 )
engineImportTXD(txd, 5708 )

dff = engineLoadDFF( "hosp.dff", 5708 )
engineReplaceModel(dff, 5708 )

col = engineLoadCOL ( "hosp.col" )
engineReplaceCOL ( col, 5708 )

end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), replaceModel)



--Sitemiz : https://sparrow-mta.blogspot.com/

--Facebook : https://facebook.com/sparrowgta/
--İnstagram : https://instagram.com/sparrowmta/
--YouTube : https://www.youtube.com/@TurkishSparroW/

--Discord : https://discord.gg/DzgEcvy