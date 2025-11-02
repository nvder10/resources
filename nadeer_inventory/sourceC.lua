--// by iManGaaX

local isScreenW, isScreenH = guiGetScreenSize()
local devScreenW, devScreenH = 1600, 900

function getScale()
	local scaleX, scaleY = isScreenW / devScreenW, isScreenH / devScreenH
	local scale = math.min(scaleX, scaleY)
	return scale, scaleX, scaleY
end

function adjustSizes(x, y, width, height)
	local _, scaleX, scaleY = getScale()
	local scaledX = x * scaleX
	local scaledY = y * scaleY
	local scaledWidth = width * scaleX
	local scaledHeight = height * scaleY
	return scaledX, scaledY, scaledWidth, scaledHeight
end

function adjustFontSize(fontSize)
	local scale = getScale()
	return math.ceil(fontSize * scale)
end

function isCursorPosition(x, y, w, h)
	local x, y, width, height = adjustSizes(x, y, w, h)

	if not isCursorShowing() then
		return false
	end

	local cx, cy = getCursorPosition()
	cx, cy = (cx * isScreenW), (cy * isScreenH)

	if (cx >= x and cx <= x + width) and (cy >= y and cy <= y + height) then
		return true
	else
		return false
	end
end

function dxDrawRectangleBorde(x, y, w, h, ...)
	local left, top, width, height = adjustSizes(x, y, w, h)

	postGUI = postGUI or false
	left, top = left + 2, top + 2
	width, height = width - 4, height - 4

	dxDrawRectangle(left - 2, top, 2, height, color, postGUI)
	dxDrawRectangle(left + width, top, 2, height, color, postGUI)
	dxDrawRectangle(left, top - 2, width, 2, color, postGUI)
	dxDrawRectangle(left, top + height, width, 2, color, postGUI)

	dxDrawRectangle(left - 1, top - 1, 1, 1, color, postGUI)
	dxDrawRectangle(left + width, top - 1, 1, 1, color, postGUI)
	dxDrawRectangle(left - 1, top + height, 1, 1, color, postGUI)
	dxDrawRectangle(left + width, top + height, 1, 1, color, postGUI)

	dxDrawRectangle(left, top, width, height, color, postGUI)
end

local _dxDrawImage = dxDrawImage
local function dxDrawImage(x, y, w, h, ...)
	local xx, yy, ww, hh = adjustSizes(x, y, w, h)
	return _dxDrawImage(xx, yy, ww, hh, ...)
end

local _dxDrawText = dxDrawText
local function dxDrawText(text, x, y, w, h, ...)
	local xx, yy, ww, hh = adjustSizes(x, y, w, h)
	return _dxDrawText(text, xx, yy, ww, hh, ...)
end

function getItems(...)
	return exports["item-system"]:getItems(...)
end

function tooltip(...)
	return exports["item-system"]:tooltip(...)
end

function getImage(...)
	return exports["item-system"]:getImage(...)
end

function getItemName(...)
	return exports["item-system"]:getItemName(...)
end

function getHoverElement(...)
	return exports["item-system"]:getHoverElement(...)
end

function getItemValue(...)
	return exports["item-system"]:getItemValue(...)
end

function getOverlayText(...)
	return exports["item-system"]:getOverlayText(...)
end

local dxfont0 = dxCreateFont(":nadeer_jobclick/Tajawal-Bold.ttf", adjustFontSize(10)) or "default"

local sx, sy = guiGetScreenSize()

local isInventory = false
local padding, slotW, slotH = 3.5, 41, 39.5
local cols, rows = 5, 5
local inventory, slots = {}, {}
local draggingItem, dragOffsetX, dragOffsetY = nil, 0, 0
local hoverItemSlot, clickItemSlot, clickDown = false, false, false
local hoverWorldItem, hoverElement, hoverAction = false, false, false
local isCursorOverInventory = false
local tooltipYet = false
local waitingForItemDrop = false

local full_color = tocolor(255,255,255,255)
local empty_color = tocolor(50,50,50,50)
local error_color = tocolor(255,0,0,150)
local move_color = tocolor(0,255,0,150)
local background_color = tocolor(20,20,20,180)
local tooltip_text_color = tocolor(255,255,255,255)
local background_error_color = tocolor(255,0,0,150)
local background_movetoelement_color = tocolor(0,255,0,150)

local startX, startY = 1322, 454
for row=0, rows-1 do
	for col=0, cols-1 do
		table.insert(slots, {x=startX + col*(slotW+padding), y=startY + row*(slotH+padding), w=slotW, h=slotH, id=#slots+1})
	end
end

function refreshInventory()
	local items = getItems(localPlayer) or {}
	inventory = {}
	for k,v in ipairs(items) do
		table.insert(inventory, {v[1], v[2], v[3], k, false, v[5], k})
	end
end

function getElementUnderCursor()
	local cx, cy, cwX, cwY, cwZ = 0, 0, 0, 0, 0
	if isCursorShowing() then
		cx, cy, cwX, cwY, cwZ = getCursorPosition()
		cx, cy = cx * sx, cy * sy
	end

	local cameraX, cameraY, cameraZ = getWorldFromScreenPosition(cx, cy, 0.1)
	local col, hitX, hitY, hitZ, hitElement = processLineOfSight(cameraX, cameraY, cameraZ, cwX, cwY, cwZ)

	if hitElement then
		local px, py, pz = getElementPosition(localPlayer)
		local dist = getDistanceBetweenPoints3D(px, py, pz, hitX, hitY, hitZ)
		if dist <= 3 then
			return hitElement
		end
	end

	return false
end

function displayItems()
	if not isInventory then return end
	if getElementData(localPlayer, "loggedin") ~= 1 then return end

	hoverItemSlot, hoverWorldItem, hoverAction, isCursorOverInventory, tooltipYet = false, false, false, false, false
	local cursorX, cursorY = 0,0
	if isCursorShowing() then
		cursorX, cursorY = getCursorPosition()
		cursorX, cursorY = cursorX*sx, cursorY*sy
	end

	refreshInventory()

	dxDrawImage(1269, 348, 325, 440, "inventory.png")
	dxDrawText("$"..exports.global:formatMoney(getElementData(localPlayer,"money") or 0), 1312,371,1413,387,tocolor(255,255,255,255),1,dxfont0 or "default","left","top")
	dxDrawText("$"..exports.global:formatMoney(getElementData(localPlayer,"bankmoney") or 0), 1312,391,1413,407,tocolor(255,255,255,255),1,dxfont0 or "default","left","top")

	local weaponDrawn = false

	for i, slot in ipairs(slots) do
		local item = inventory[i]
		if item then
			local boxx, boxy, box = slot.x, slot.y, slot.w

			local fff = 0

			if not weaponDrawn and item[1] == 115 then
				boxx = 1406
				boxy = 706
				box = 50
				fff = 44
				weaponDrawn = true
			end

			dxDrawImage(boxx + 6, boxy + 6, box - 12, box - 12, getImage(item[1], item[2]), fff or 0, 0, 0)

			if isCursorPosition(boxx, boxy, box, box) then
				hoverItemSlot = {invslot=i, id=item[4], x=slot.x, y=slot.y, group=item[5]}
				local tooltipText = getItemName(item[1], item[2], item[6])
				local overlayText = getOverlayText(item[1], item[2], item[6] or {}, item[5])
				if #overlayText > 0 then
					tooltipText = overlayText.." - "..tooltipText
				end
				tooltip(cursorX, cursorY, tooltipText)
			end
		end
	end

	isCursorOverInventory = hoverItemSlot ~= false

	if draggingItem then
		local color = error_color

		local hoverElementCandidate = getElementUnderCursor(true)
		if isElement(hoverElementCandidate) then
			local etype = getElementType(hoverElementCandidate)
			if etype == "slot" then
				color = move_color
				hoverElement = nil
			else
				color = move_color
				hoverElement = hoverElementCandidate
			end
		else
			hoverElement = nil
		end

		dxDrawRectangleBorde(draggingItem.x-1, draggingItem.y-1, slotW+2, slotH+2, color)
		local image = getImage(draggingItem.item[1], draggingItem.item[2])
		if image then
			_dxDrawImage(draggingItem.x, draggingItem.y, slotW, slotH, image)
		end

		if hoverElement then
			local name = ""
			local elementType = getElementType(hoverElement)
			if elementType == "player" then
				name = getPlayerName(hoverElement):gsub("_", " ")
			elseif elementType == "vehicle" then
				name = getVehicleName(hoverElement).." (#"..getElementData(hoverElement,"dbid")..")"
			elseif elementType == "ped" then
				name = getElementData(hoverElement,"name") or "person"
			elseif elementType == "object" then
				name = "storage"
			end
			tooltip(draggingItem.x + slotW + 5, draggingItem.y + slotH/2 - 10, "Move to "..name..".")
		end
	end
end
addEventHandler("onClientRender", root, displayItems)

addEventHandler("onClientClick", root, function(button, state, _, _, worldX, worldY, worldZ)
	if not isInventory then return end

	local cx, cy = getCursorPosition()
	cx, cy = cx * sx, cy * sy

	local function getClickItemSlot()
		return clickItemSlot or hoverItemSlot
	end

	if button == "left" then
		if state == "down" and hoverItemSlot then
			clickItemSlot = hoverItemSlot
			clickDown = getTickCount()
			local _, scaleX, scaleY = getScale()
			local scaledX, scaledY = hoverItemSlot.x * scaleX, hoverItemSlot.y * scaleY

			draggingItem = {
				slotID = hoverItemSlot.invslot,
				item = inventory[hoverItemSlot.invslot],
				x = scaledX,
				y = scaledY
			}

			dragOffsetX = cx - scaledX
			dragOffsetY = cy - scaledY

			if getKeyState("delete") then
				hoverAction = ACTION_DESTROY
			elseif getKeyState("lctrl") or getKeyState("rctrl") then
				hoverAction = ACTION_DROP
			elseif getKeyState("lshift") or getKeyState("rshift") then
				hoverAction = ACTION_SPLIT
			end
		end

		if state == "up" and draggingItem then
			local targetSlot = hoverItemSlot
			local hoverTarget = hoverElement

			if targetSlot then
				inventory[draggingItem.slotID], inventory[targetSlot.invslot] = inventory[targetSlot.invslot], draggingItem.item
			elseif isElement(hoverTarget) then
				if hoverTarget == localPlayer then
					outputChatBox("You can't give items to yourself.", 255, 0, 0)
					inventory[draggingItem.slotID] = nil
					draggingItem, clickItemSlot, clickDown, hoverElement = nil, nil, nil, nil
					return
				end
				local elementType = getElementType(hoverTarget)
				local itemID = draggingItem.item[1]
				if elementType == "ped" and itemID == 211 and getElementData(hoverTarget, "rpp.npc.type") == "santa" then
					triggerServerEvent("xmas:useChristmasLotteryTicket", localPlayer, hoverTarget, draggingItem.slotID)
				elseif itemID > 0 then
					waitingForItemDrop = true
					triggerServerEvent( "moveToElement", localPlayer, hoverTarget, draggingItem.slotID, nil, "finishItemDrop")
				elseif itemID == -100 then
					triggerServerEvent( "moveToElement", localPlayer, hoverTarget, draggingItem.slotID, true, "finishItemDrop")
				end
				inventory[draggingItem.slotID] = nil
			elseif worldX and worldY and worldZ then
				local item = draggingItem.item
				local itemID, itemValue = item[1], item[2]

				if itemID > 0 or itemID == -100 then
					waitingForItemDrop = true
					triggerServerEvent("dropItem", localPlayer, draggingItem.slotID, worldX, worldY, worldZ, itemID == -100 and savedArmor or nil)
					inventory[draggingItem.slotID] = nil
				else
					local slot = -item[3]
					if slot >= 2 and slot <= 9 then
						openWeaponDropGUI(-itemID, itemValue, worldX, worldY, worldZ)
					else
						waitingForItemDrop = true
						triggerServerEvent("dropItem", localPlayer, -itemID, worldX, worldY, worldZ, itemValue)
						inventory[draggingItem.slotID] = nil
					end
				end
			end

			draggingItem, clickItemSlot, clickDown, hoverElement = nil, nil, nil, nil
		end

		if state == "down" and hoverWorldItem then
			local px, py, pz = getElementPosition(localPlayer)
			local wx, wy, wz = getElementPosition(hoverWorldItem)
			local dist = getDistanceBetweenPoints3D(px, py, pz, wx, wy, wz)
			if dist <= 3 then
				local itemID = getElementData(hoverWorldItem, "itemID")
				if itemID == 169 and not getElementData(localPlayer, "exclusiveGUI") then
					triggerServerEvent("openKeypadInterface", localPlayer, hoverWorldItem)
				else
					triggerServerEvent("pickupItem", localPlayer, hoverWorldItem)
				end
				clickWorldItem = hoverWorldItem
				clickDown = getTickCount()
				if not getElementData(clickWorldItem, "protected") then
					setElementAlpha(clickWorldItem, 150)
					setElementCollisionsEnabled(clickWorldItem, false)
				end
			end
		end

		if state == "up" and isElement(clickWorldItem) then
			local px, py, pz = getElementPosition(localPlayer)
			local wx, wy, wz = getElementPosition(clickWorldItem)
			if getDistanceBetweenPoints3D(px, py, pz, wx, wy, wz) <= 3 then
				setElementAlpha(clickWorldItem, 255)
				setElementCollisionsEnabled(clickWorldItem, true)
				triggerServerEvent("releaseWorldItem", localPlayer, clickWorldItem)
			end
			clickWorldItem = nil
			cursorDown = false
			rotate = false
		end
	end

	if button == "right" and state == "up" then
		local slot = getClickItemSlot()
		if not slot then return end
		local item = inventory[slot.invslot]
		if not item then return end

		local action = "use"
		if getKeyState("delete") then
			action = "destroy"
		elseif getKeyState("lctrl") or getKeyState("rctrl") then
			action = "drop"
		elseif getKeyState("lshift") or getKeyState("rshift") then
			action = "split"
		end

		if action == "use" then
			triggerServerEvent("useItem", localPlayer, slot.invslot)
		elseif action == "drop" and worldX and worldY and worldZ then
			triggerServerEvent("dropItem", localPlayer, slot.invslot, worldX, worldY, worldZ)
			inventory[slot.invslot] = nil
		elseif action == "destroy" then
			triggerServerEvent("destroyItem", localPlayer, slot.invslot)
			inventory[slot.invslot] = nil
		elseif action == "split" then
			triggerServerEvent("splitItem", localPlayer, slot.invslot)
		end
		clickItemSlot = nil
	end
end)

addEventHandler("onClientRender", root, function()
	if not isInventory then return end

	if draggingItem then
		local cx, cy = getCursorPosition()
		cx, cy = cx * sx, cy * sy

		draggingItem.x = (cx - dragOffsetX)
		draggingItem.y = (cy - dragOffsetY)
	end
end)

local showInventory = false

bindKey("i", "down", function()
	if getElementData(localPlayer, "loggedin") == 1 then
		if showInventory then
			showInventory = false
			isInventory = false
			showCursor(false)
			playSoundInvClose()
		else
			if (not getElementData(localPlayer, "adminjailed") or exports.integration:isPlayerTrialAdmin(localPlayer)) 
				and getElementData(localPlayer, "viewingInterior") ~= 1 then
				
				if getElementData(localPlayer, "exclusiveGUI") then return end
				
				showInventory = true
				isInventory = true
				showCursor(true)
				playSoundInvOpen()
			else
				outputChatBox("You can't access your inventory in jail or in property preview.", 255, 0, 0)
			end
		end
	end
end)

addEventHandler("recieveItems", root, function()
	--showInventory, isInventory = true, true
end)

function dxDrawRectangleBorde(left, top, width, height, color, postGUI)
	postGUI = postGUI or false
	left, top = left + 2, top + 2
	width, height = width - 4, height - 4

	dxDrawRectangle(left - 2, top, 2, height, color, postGUI)
	dxDrawRectangle(left + width, top, 2, height, color, postGUI)
	dxDrawRectangle(left, top - 2, width, 2, color, postGUI)
	dxDrawRectangle(left, top + height, width, 2, color, postGUI)

	dxDrawRectangle(left - 1, top - 1, 1, 1, color, postGUI)
	dxDrawRectangle(left + width, top - 1, 1, 1, color, postGUI)
	dxDrawRectangle(left - 1, top + height, 1, 1, color, postGUI)
	dxDrawRectangle(left + width, top + height, 1, 1, color, postGUI)

	dxDrawRectangle(left, top, width, height, color, postGUI)
end

function playSoundInvOpen()
	local sound = playSound(":resources/sounds/inv_open.mp3")
	if not sound then return end
	setSoundVolume(sound, 0.3)
end

function playSoundInvClose()
	local sound = playSound(":resources/sounds/inv_close.mp3")
	if not sound then return end
	setSoundVolume(sound, 0.3)
end