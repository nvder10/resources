--// by iManGaaX

local harSystem = createElement("harborSystem", "harborSystem")

local systemState = false
local lastHour = nil

function checkHourlyToggle()
	local time = getRealTime()
	local currentHour = time.hour

	if currentHour ~= lastHour then
		systemState = not systemState
		lastHour = currentHour
		setElementData(harSystem, "harborSystem", systemState)
	end
end
setTimer(checkHourlyToggle, 1000, 0)