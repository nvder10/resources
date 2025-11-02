--// by iManGaaX

local sx, sy = guiGetScreenSize()
local lastState, displayText = nil
local fadeState = "none"
local alpha, fadeStartTick = 0, 0
local holdTime = 5000
local fadeDuration = holdTime/2

function getTimeRemaining()
	local time = getRealTime()
	local minsLeft = 59 - time.minute
	local secsLeft = 59 - time.second
	return minsLeft, secsLeft
end

function harborStateChange()
	if not displayText then return end

	local now = getTickCount()
	local progress = (now - fadeStartTick) / fadeDuration

	if fadeState == "in" then
		alpha = interpolateBetween(0, 0, 0, 255, 0, 0, progress, "OutQuad")
		if progress >= 1 then
			fadeState = "hold"
			fadeStartTick = now
		end
	elseif fadeState == "hold" then
		alpha = 255
		if now - fadeStartTick > holdTime then
			fadeState = "out"
			fadeStartTick = now
		end
	elseif fadeState == "out" then
		alpha = interpolateBetween(255, 0, 0, 0, 0, 0, progress, "InQuad")
		if progress >= 1 then
			displayText = nil
			fadeState = "none"
			alpha = 0
		end
	end

	if displayText then
		local boxW, boxH = sx, 120
		local x, y = 0, (sy - boxH) / 2

		dxDrawRectangle(x, y, boxW, boxH, tocolor(0, 0, 0, math.min(alpha, 180)), false)

		local borderColor = tocolor(29, 77, 181, alpha)
		dxDrawRectangle(x, y, boxW, 4, borderColor)
		dxDrawRectangle(x, y + boxH - 4, boxW, 4, borderColor)

		dxDrawText(displayText, x, y, x + boxW, y + boxH, borderColor, 3, "default", "center", "center", false, false, false, true)
	end
end

addEventHandler("onClientRender", root, function()
	local loggedin = getElementData(localPlayer, "loggedin")
	if loggedin ~= 1 then return end

	local harborElement = getElementByID("harborSystem")
	if not isElement(harborElement) then return end

	local systemState = getElementData(harborElement, "harborSystem")
	if systemState ~= false and systemState ~= true then return end

	if lastState ~= nil and lastState ~= systemState then
		if systemState then
			displayText = "Harbor Opened"
		else
			displayText = "Harbor Closed"
		end
		alpha = 0
		fadeState = "in"
		fadeStartTick = getTickCount()
	end
	lastState = systemState

	harborStateChange()

	local mins, secs = getTimeRemaining()
	local stateText = systemState and "Open" or "Closed"
	local color = systemState and tocolor(0, 255, 120, 230) or tocolor(255, 60, 60, 230)
	local timerText = string.format("%s in: %02d:%02d", (systemState and "Closing" or "Opening"), mins, secs)

	local w, h = 235, 0
	local x, y = (sx/2 - w) / 2, sy - 90
	dxDrawText("[Harbor System]: "..stateText.."\n"..timerText, x, y, x + w, y + h, color, 1, "default-bold", "center", "top")
end)