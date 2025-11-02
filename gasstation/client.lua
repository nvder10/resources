--------------------------------------------------------

-- Sitemiz : https://sparrow-mta.blogspot.com/

-- Facebook : https://facebook.com/sparrowgta/
-- İnstagram : https://instagram.com/sparrowmta/
-- YouTube : https://www.youtube.com/@TurkishSparroW/

-- Discord : https://discord.gg/DzgEcvy

--------------------------------------------------------

addEventHandler('onClientResourceStart', resourceRoot,
function()
local txd = engineLoadTXD('Textures.txd',true)
engineImportTXD(txd, 5409)
local dff = engineLoadDFF('Building.dff', 0)
engineReplaceModel(dff, 5409)
local col = engineLoadCOL('Building.col')
engineReplaceCOL(col, 5409)
engineSetModelLODDistance(5409, 500)


local txd = engineLoadTXD('Textures.txd',true)
engineImportTXD(txd, 14449)
local dff = engineLoadDFF('Gaspump.dff', 0)
engineReplaceModel(dff, 14449)
local col = engineLoadCOL('Gaspump.col')
engineReplaceCOL(col, 14449)
engineSetModelLODDistance(14449, 100)


local txd = engineLoadTXD('Textures.txd',true)
engineImportTXD(txd, 2899)
local dff = engineLoadDFF('Foodstuff.dff', 0)
engineReplaceModel(dff, 2899)
local col = engineLoadCOL('Foodstuff.col')
engineReplaceCOL(col, 2899)
engineSetModelLODDistance(2899, 100)

local txd = engineLoadTXD('Textures.txd',true)
engineImportTXD(txd, 2892)
local dff = engineLoadDFF('Furniture.dff', 0)
engineReplaceModel(dff, 2892)
local col = engineLoadCOL('Furniture.col')
engineReplaceCOL(col, 2892)
engineSetModelLODDistance(2892, 100)

local txd = engineLoadTXD('Textures.txd',true)
engineImportTXD(txd, 5503)
local dff = engineLoadDFF('laeroad38.dff', 0)
engineReplaceModel(dff, 5503)
local col = engineLoadCOL('laeroad38.col')
engineReplaceCOL(col, 5503)
engineSetModelLODDistance(5503, 300)
end)

function byebyetl()
	removeWorldModel(5681, 0.25, 1921.4844, -1778.9141, 18.5781)
	removeWorldModel(1293, 99999999, 1921.4844, -1778.9141, 18.5781)
	removeWorldModel(1292, 99999999, 1921.4844, -1778.9141, 18.5781)
	removeWorldModel(1289, 99999999, 1921.4844, -1778.9141, 18.5781)
	removeWorldModel(1286, 99999999, 1921.4844, -1778.9141, 18.5781)
	
	removeWorldModel(1285, 99999999, 1921.4844, -1778.9141, 18.5781)
	removeWorldModel(917, 99999999, 1921.4844, -1778.9141, 18.5781)
	removeWorldModel(1288, 99999999, 1921.4844, -1778.9141, 18.5781)
	removeWorldModel(1287, 99999999, 1921.4844, -1778.9141, 18.5781)
	removeWorldModel(1977, 99999999, 1921.4844, -1778.9141, 18.5781)
	removeWorldModel(2760, 99999999, 1921.4844, -1778.9141, 18.5781)
end
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), byebyetl)


--------------------------------------------------------

-- Sitemiz : https://sparrow-mta.blogspot.com/

-- Facebook : https://facebook.com/sparrowgta/
-- İnstagram : https://instagram.com/sparrowmta/
-- YouTube : https://www.youtube.com/@TurkishSparroW/

-- Discord : https://discord.gg/DzgEcvy

--------------------------------------------------------