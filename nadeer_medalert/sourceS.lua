--// by iManGaaX

local lastDeathTick = {}
local deathCooldown = 10000

addEventHandler("onPlayerWasted", root, function()
	local deadPlayer = source

	local serial = getPlayerSerial(deadPlayer)
	local tick = getTickCount()
	if lastDeathTick[serial] and tick - lastDeathTick[serial] < deathCooldown then
		return
	end
	lastDeathTick[serial] = tick

	local x, y, z = getElementPosition(deadPlayer)
	local pname = getPlayerName(deadPlayer):gsub("_", " ")
	local city, zone = getZoneName(x, y, z, true), getZoneName(x, y, z)
	local mapString = city == zone and city or city..", "..zone

	local data = {playerName = pname, pos = {x = x, y = y, z = z}, mapString = mapString, timestamp = tick}

	for _, player in ipairs(getElementsByType("player")) do
		if --[[deadPlayer ~= player and]] exports["factions"]:isPlayerInFaction(player, 2) then
			triggerClientEvent(player, "medAlert:onReceiveAlert", resourceRoot, data)
		end
	end
end)

addEvent("medAlert:requestShowArea", true)
addEventHandler("medAlert:requestShowArea", resourceRoot, function(pos)
	local requester = client
	if not exports["factions"]:isPlayerInFaction(requester, 2) then
		return
	end

	triggerClientEvent(requester, "medAlert:clientShowArea", resourceRoot, pos)
end)

addEvent("medAlert:acceptAlert", true)
addEventHandler("medAlert:acceptAlert", resourceRoot, function(data)
	local accepter = client
	if not exports["factions"]:isPlayerInFaction(accepter, 2) then
		return
	end

	local name = getPlayerName(accepter):gsub("_", " ")
	for _, player in ipairs(getElementsByType("player")) do
		if exports["factions"]:isPlayerInFaction(player, 2) then
			outputChatBox("[EMS] "..name.." accepted the alert of death report.", player, 50, 255, 50)
		end
	end
end)