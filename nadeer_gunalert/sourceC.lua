--// by iManGaaX

local activeWindow, acceptButton, showButton, ignoreButton, windowLabel, alertTimer, countLabel, currentAlert
local blipDuration = 60000 * 2
local alertsQueue = {}

local function showNextAlert()
	if activeWindow or #alertsQueue == 0 then
		return
	end

	currentAlert = table.remove(alertsQueue, 1)

	local data = currentAlert
	local screenW, screenH = guiGetScreenSize()
	local w, h = 360, 140
	local x, y = 25, screenH * 0.5

	activeWindow = guiCreateWindow(x, y, w, h, "Gunfire Alert", false)
	guiWindowSetSizable(activeWindow, false)

	windowLabel = guiCreateLabel(0.05, 0.2, 0.9, 0.35, ("Position: %s\nWeapon: %s"):format(data.mapString, data.weapon), true, activeWindow)
	guiLabelSetVerticalAlign(windowLabel, "top")
	guiLabelSetHorizontalAlign(windowLabel, "left")

	label = guiCreateLabel(0.05, 0.4, 0.9, 0.35, "ـــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــ", true, activeWindow)
	guiLabelSetColor(label, 29, 77, 181)

	countLabel = guiCreateLabel(0.05, 0.55, 0.9, 0.1, "Pending Alerts: "..#alertsQueue, true, activeWindow)
	guiLabelSetHorizontalAlign(countLabel, "left")
	guiLabelSetVerticalAlign(countLabel, "center")

	acceptButton = guiCreateButton(0.05, 0.7, 0.28, 0.25, "Accept & Show", true, activeWindow)
	showButton = guiCreateButton(0.365, 0.7, 0.28, 0.25, "Show Area", true, activeWindow)
	ignoreButton = guiCreateButton(0.68, 0.7, 0.28, 0.25, "Ignore Alert", true, activeWindow)

	addEventHandler("onClientGUIClick", acceptButton, function()
		triggerServerEvent("gunAlert:acceptAlert", resourceRoot, data)
		triggerServerEvent("gunAlert:requestShowArea", resourceRoot, data.pos)
		destroyAlertWindow()
	end, false)

	addEventHandler("onClientGUIClick", showButton, function()
		triggerServerEvent("gunAlert:requestShowArea", resourceRoot, data.pos)
		destroyAlertWindow()
	end, false)

	addEventHandler("onClientGUIClick", ignoreButton, function()
		destroyAlertWindow()
	end, false)

	if alertTimer and isTimer(alertTimer) then
		killTimer(alertTimer)
	end

	alertTimer = setTimer(function()
		destroyAlertWindow()
	end, 60000, 1)
end

function destroyAlertWindow()
	if alertTimer and isTimer(alertTimer) then
		killTimer(alertTimer)
	end

	if activeWindow and isElement(activeWindow) then
		destroyElement(activeWindow)
	end

	activeWindow, currentAlert, countLabel = nil

	if #alertsQueue > 0 then
		showNextAlert()
	end
end

addEvent("gunAlert:onReceiveAlert", true)
addEventHandler("gunAlert:onReceiveAlert", root, function(data)
	if not exports["factions"]:isPlayerInFaction(localPlayer, 1) then
		return
	end

	table.insert(alertsQueue, data)

	if activeWindow and isElement(activeWindow) and countLabel and isElement(countLabel) then
		guiSetText(countLabel, "Pending Alerts: "..#alertsQueue)
	end

	if not activeWindow then
		showNextAlert()
	end
end)

addEvent("gunAlert:clientShowArea", true)
addEventHandler("gunAlert:clientShowArea", root, function(pos)
	if not pos then
		return
	end

	local px, py, pz = pos.x, pos.y, pos.z
	local areaSize = 150
	local blinkInterval = 100

	local area = createRadarArea(px - areaSize/2, py - areaSize/2, areaSize, areaSize, 255, 25, 25, 155)
	local blip = createBlip(px, py, pz, 6, 2, 255, 0, 0, 255, 0, 9999)

	local visible = true
	local blinkTimer = setTimer(function()
		if isElement(area) then
			if visible then
				setRadarAreaColor(area, 255, 25, 25, 155)
			else
				setRadarAreaColor(area, 25, 25, 255, 155)
			end
			visible = not visible
		end
	end, blinkInterval, 0)

	setTimer(function()
		if isElement(area) then
			destroyElement(area)
		end

		if isElement(blip) then
			destroyElement(blip)
		end

		if isTimer(blinkTimer) then
			killTimer(blinkTimer)
		end
	end, blipDuration, 1)
end)