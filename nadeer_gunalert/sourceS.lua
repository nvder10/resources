--// by iManGaaX

local fireCoolDown = 5000
local lastFireTick = {}

addEventHandler("onPlayerWeaponFire", root, function(weaponID)
	local shooter = source
	if not isElement(shooter) then
		return
	end

	--[[if exports["factions"]:isPlayerInFaction(shooter, 1) or exports["factions"]:isPlayerInFaction(shooter, 3) then
		return
	end]]

	local serial = getPlayerSerial(shooter)
	local tick = getTickCount()
	if lastFireTick[serial] and tick - lastFireTick[serial] < fireCoolDown then
		return
	end
	lastFireTick[serial] = tick

	local weapon = getWeaponNameFromID(weaponID)
	local x, y, z = getElementPosition(shooter)
	local pname = getPlayerName(shooter):gsub("_", " ")
	local city, zone = getZoneName(x, y, z, true), getZoneName(x, y, z)
	local mapString = city == zone and city or city..", "..zone

	local data = {weapon = weapon or "N/A", pos = {x = x, y = y, z = z}, mapString = mapString or "N/A", timestamp = tick}

	for _, player in ipairs(getElementsByType("player")) do
		if exports["factions"]:isPlayerInFaction(player, 1) then
			triggerClientEvent(player, "gunAlert:onReceiveAlert", resourceRoot, data)
		end
	end
end)

addEvent("gunAlert:requestShowArea", true)
addEventHandler("gunAlert:requestShowArea", resourceRoot, function(pos)
	if not pos or not pos.x then
		return
	end

	local requester = client
	if not exports["factions"]:isPlayerInFaction(requester, 1) then
		return
	end

	triggerClientEvent(requester, "gunAlert:clientShowArea", resourceRoot, pos)
end)

addEvent("gunAlert:acceptAlert", true)
addEventHandler("gunAlert:acceptAlert", resourceRoot, function(data)
	local accepter = client
	if not exports["factions"]:isPlayerInFaction(accepter, 1) then
		return
	end

	local name = getPlayerName(accepter):gsub("_", " ")
	for _, player in ipairs(getElementsByType("player")) do
		if exports["factions"]:isPlayerInFaction(player, 1) then
			outputChatBox("[Police] "..name.." accepted the alert of report.", player, 50, 50, 255)
		end
	end
end)