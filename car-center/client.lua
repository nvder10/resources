------------------------------------------------------------
-- Sitemiz : https://sparrow-mta.blogspot.com/

-- Facebook : https://facebook.com/sparrowgta/
-- İnstagram : https://instagram.com/sparrowmta/
-- YouTube : https://www.youtube.com/@TurkishSparroW/

-- Discord : https://discord.gg/DzgEcvy
------------------------------------------------------------

addEventHandler('onClientResourceStart',resourceRoot,function () 
    txd = engineLoadTXD ( "model.txd" )
    engineImportTXD ( txd, 5896 )
    dff = engineLoadDFF ( "model.dff", 0 )
    engineReplaceModel ( dff, 5896 )
    col = engineLoadCOL ( "model.col" )
    engineReplaceCOL ( col, 5896 )
end)
setOcclusionsEnabled( false )

------------------------------------------------------------
-- Sitemiz : https://sparrow-mta.blogspot.com/

-- Facebook : https://facebook.com/sparrowgta/
-- İnstagram : https://instagram.com/sparrowmta/
-- YouTube : https://www.youtube.com/@TurkishSparroW/

-- Discord : https://discord.gg/DzgEcvy
------------------------------------------------------------