--[[
* تم إزالة حقوق النشر كما طلبت
]]

local pedTable = { }
local characterSelected, characterElementSelected, newCharacterButton, bLogout = nil
addEvent( 'account:character:select', true )
addEvent("account:character:spawned", true)

selectionScreenID = 0
function Characters_showSelection()
	characters_destroyDetailScreen()
	triggerEvent("account:changingchar", localPlayer)
	setPlayerHudComponentVisible("radar", false)

	guiSetInputEnabled(false)

	showCursor(true)

	setElementDimension ( localPlayer, 1 )
	setElementInterior( localPlayer, 0 )

	for _, thePed in ipairs(pedTable) do
		if isElement(thePed) then
			destroyElement(thePed)
		end
	end

	selectionScreenID = getSelectionScreenID()

	startCam[selectionScreenID] = originalStartCam[selectionScreenID]

	local x, y, z, rot =  pedPos[selectionScreenID][1], pedPos[selectionScreenID][2], pedPos[selectionScreenID][3], pedPos[selectionScreenID][4]
	local characterList = getElementData(localPlayer, "account:characters")
	if (characterList) then
		-- Prepare the peds
		local count = 0
		local oldPos = y
		username = getElementData(localPlayer, "account:username")
		credits = getElementData(localPlayer, "credits")
		createdDate = getElementData(localPlayer, "account:creationdate")
		lastLoginDate = getElementData(localPlayer, "account:lastlogin")
		accountEmail = getElementData(localPlayer, "account:email")
		for _, v in ipairs(characterList) do
			local thePed = createPed(tonumber(v[9]), x, y, z)
			if not thePed then
				thePed = createPed(264, x, y, z)
			end
			if thePed and isElement( thePed ) then
				setPedRotation(thePed, rot)
				setElementFrozen(thePed, true)
				setElementDimension(thePed, 1)
				setElementInterior(thePed, 0)
				setElementData(thePed,"account:charselect:id", v[1], false)
				setElementData(thePed,"account:charselect:name", v[2]:gsub("_", " "), false)
				setElementData(thePed,"account:charselect:cked", v[3], false)
				setElementData(thePed,"account:charselect:hoursplayed", v[4], false)
				setElementData(thePed,"account:charselect:lastseen", v[10], false)
				setElementData(thePed,"account:charselect:age", v[5], false)
				setElementData(thePed,"account:charselect:weight", v[11], false)
				setElementData(thePed,"account:charselect:height", v[12], false)
				setElementData(thePed,"account:charselect:age", v[5], false)
				setElementData(thePed,"account:charselect:gender", v[6], false)
				setElementData(thePed,"account:charselect:race", v[7], false)
				setElementData(thePed,"account:charselect:factionrank", v[8] or "", false)
				setElementData(thePed,"clothing:id", v[15] or "", false)
				setElementData(thePed,"account:charselect:month", v[13], false)
				setElementData(thePed,"account:charselect:day", v[14], false)

				local randomAnimation = getRandomAnim( v[3] > 0 and 4 or 2 )
				setPedAnimation ( thePed , randomAnimation[1], randomAnimation[2], -1, true, false, false, false )

				if selectionScreenID == 0 then
					y = y - 3
					count = count + 1
					if count >= 4 then
						count = 0
						y = oldPos
						x = x - 3
					end
				elseif selectionScreenID == 1 then
					y = y + 3
					count = count + 1
					if count >= 6 then
						count = 0
						y = oldPos
						x = x - 3
					end
				elseif selectionScreenID == 2 then
					y = y + 3
					count = count + 1
					if count >= 6 then
						count = 0
						y = oldPos
						x = x - 3
					end
				elseif selectionScreenID == 3 then
					y = y - 3
					count = count + 1
					if count >= 6 then
						count = 0
						y = oldPos
						x = x - 3
					end
				end
				table.insert(pedTable, thePed)
			else
				outputChatBox("[ACCOUNT] Error occurred while spawning character '"..v[2].."'. Please report on Paradise Discord :" )
				for index, value in pairs( v ) do
					outputChatBox( index .. " : " .. value )
				end
				outputChatBox("createPed( ".. v[9] .. ", " .. x .. ", " .. y .. ", " .. z .. ") failed."  )
			end
		end

		-- Cam magic
		fadeCamera ( false, 0, 0,0,0 )
		setCameraMatrix (originalStartCam[selectionScreenID][1], originalStartCam[selectionScreenID][2], originalStartCam[selectionScreenID][3], originalStartCam[selectionScreenID][4], originalStartCam[selectionScreenID][5], originalStartCam[selectionScreenID][6], 0, exports.global:getPlayerFov())
		setTimer(function ()
			fadeCamera ( true, 1, 0,0,0 )
			end, 1000, 1)

		setTimer(function ()
			showCursor(true)
			addEventHandler("onClientRender", getRootElement(), Characters_updateSelectionCamera)
			addEventHandler("onClientRender", getRootElement(), renderNametags)
			addEventHandler("onClientRender", root, characterMouseOver)

			for i = 1, #pedTable do
				setElementFrozen(pedTable[i], false)
			end

		end, 2000, 1)
	end

	-- Prematurely prepare avatars a few seconds ealier. So it shortens the loading time, making avatar showing up faster on character selection screen.
	local id = getElementData(localPlayer, 'account:id')
	local fid = getElementData(localPlayer, 'account:forumid')

	if id and getElementData(localPlayer, "avatar") == 1  then
		avatar = exports.cache:getImage(id)
	end
	if fid then
	
	end
end

function refreshCharacters()
	for _, thePed in ipairs(pedTable) do
		if isElement(thePed) then
			destroyElement(thePed)
		end
	end
	selectionScreenID = getSelectionScreenID()

	local x, y, z, rot =  pedPos[selectionScreenID][1], pedPos[selectionScreenID][2], pedPos[selectionScreenID][3], pedPos[selectionScreenID][4]
	local characterList = getElementData(localPlayer, "account:characters")
	if (characterList) then
		-- Prepare the peds
		local count = 0
		local oldPos = y
		username = getElementData(localPlayer, "account:username")
		credits = getElementData(localPlayer, "credits")
		createdDate = getElementData(localPlayer, "account:creationdate")
		lastLoginDate = getElementData(localPlayer, "account:lastlogin")
		accountEmail = getElementData(localPlayer, "account:email")
		for _, v in ipairs(characterList) do
			local thePed = createPed(tonumber(v[9]), x, y, z)
			if not thePed then
				thePed = createPed(264, x, y, z)
			end
			setPedRotation(thePed, rot)
			setElementDimension(thePed, 1)
			setElementInterior(thePed, 0)
			setElementData(thePed,"account:charselect:id", v[1], false)
			setElementData(thePed,"account:charselect:name", v[2]:gsub("_", " "), false)
			setElementData(thePed,"account:charselect:cked", v[3], false)
			setElementData(thePed,"account:charselect:hoursplayed", v[4], false)
			setElementData(thePed,"account:charselect:lastseen", v[10], false)
			setElementData(thePed,"account:charselect:age", v[5], false)
			setElementData(thePed,"account:charselect:weight", v[11], false)
			setElementData(thePed,"account:charselect:height", v[12], false)
			setElementData(thePed,"account:charselect:age", v[5], false)
			setElementData(thePed,"account:charselect:gender", v[6], false)
			setElementData(thePed,"account:charselect:race", v[7], false)
			setElementData(thePed,"account:charselect:factionrank", v[8] or "", false)
			setElementData(thePed,"clothing:id", v[15] or "", false)

			setElementData(thePed,"account:charselect:month", v[13], false)
			setElementData(thePed,"account:charselect:day", v[14], false)

			local randomAnimation = getRandomAnim( v[3] == 1 and 4 or 2 )
			setPedAnimation ( thePed , randomAnimation[1], randomAnimation[2], -1, true, false, false, false )


			if selectionScreenID == 0 then
				y = y - 3
				count = count + 1
				if count >= 4 then
					count = 0
					y = oldPos
					x = x - 3
				end
			elseif selectionScreenID == 1 then
				y = y + 3
				count = count + 1
				if count >= 6 then
					count = 0
					y = oldPos
					x = x - 3
				end
			elseif selectionScreenID == 2 then
				y = y + 3
				count = count + 1
				if count >= 6 then
					count = 0
					y = oldPos
					x = x - 3
				end
			elseif selectionScreenID == 3 then
				y = y - 3
				count = count + 1
				if count >= 6 then
					count = 0
					y = oldPos
					x = x - 3
				end
			end
			table.insert(pedTable, thePed)
		end
	end
end
addEvent("refreshCharacters", true)
addEventHandler("refreshCharacters", resourceRoot, refreshCharacters)

local forum_box = {}
function updateForumBox(data)
	for key, value in pairs(data) do
		forum_box[key] = value
	end
end
addEvent("updateForumBox", true)
addEventHandler("updateForumBox", root, updateForumBox)

cooldown = false
showing = false
justClicked = false
local swidth, sheight = guiGetScreenSize()

local function isInBox( x, y, xmin, xmax, ymin, ymax )
	return x and y and x >= xmin and x <= xmax and y >= ymin and y <= ymax
end

avatar = nil
calledAvatar = false
calledGot = false
local function getAvatar()
	if not calledAvatar or (getTickCount() - 10000 >= calledAvatar and not calledGot) then
		if getElementData(localPlayer, "avatar") == 1 then
			avatar = exports.cache:getImage(getElementData(localPlayer,"account:id"))
			if avatar and avatar.tex then
				calledGot = true
			end
		else
			exports.cache:removeImage(getElementData(localPlayer,"account:id"), true)
			calledGot = true
		end
	end
	calledAvatar = getTickCount()

	return avatar
end

local hover = tocolor( 255, 0, 0, 255 )
local mta_posxOffset, mta_posyOffset = 0,106
local character_detail_yoffset = 0

-- تعريف الخط العربي - تم التصحيح
local arabicFont = dxCreateFont(":resources/account/Tajawal-Regular.ttf", 12) or "default"
local arabicFontBold = dxCreateFont(":resources/account/Tajawal-Bold.ttf", 12) or "default-bold"

-- إعدادات الأزرار - تم التعديل
local buttonSettings = {
    newCharacter = {
        text = "إنشاء شخصية جديدة!",
        x = 100,
        y = 155,
        width = 200,
        height = 25,
        textScale = 1.0
    },
    refresh = {
        text = "تحديث الشخصيات",
        x = 100,
        y = 185,
        width = 200,
        height = 25,
        textScale = 1.0
    },
    login = {
        text = "تسجيل الدخول",
        x = 100,
        y = 215,
        width = 200,
        height = 25,
        textScale = 1.0
    }
}

-- متغير للتحكم في تغيير الترحيب
local lastGreetingChange = 0
local currentGreeting = "أهلاً"
local greetings = {"أهلاً", "مرحباً", "سلام", "هاي"}

function renderAccountStats()
	if isCursorShowing( ) then
		cursorX, cursorY = getCursorPosition( )
		cursorX, cursorY = cursorX * swidth, cursorY * sheight
	end
	if cooldown then
		if cooldown<=getTickCount()-5000 then
			cooldown = false
		end
	end

	-- تغيير الترحيب كل 2 ثانية
	if getTickCount() - lastGreetingChange > 2000 then
		currentGreeting = greetings[math.random(#greetings)]
		lastGreetingChange = getTickCount()
	end

	local width = 350
	mta_posxOffset = 10
	mta_posyOffset = 80
	local mta_box_height = 280

	-- الخلفية الرئيسية
	dxDrawRectangle(mta_posxOffset, mta_posyOffset, width, mta_box_height, tocolor(3, 20, 23, 230), true)
	
	-- الخط الفاصل
	dxDrawLine(mta_posxOffset + 10, mta_posyOffset + 50, mta_posxOffset + width - 10, mta_posyOffset + 50, tocolor(52, 171, 173, 255), 2, true)
	
	-- الصورة الشخصية - تم رفعها قليلاً
	avatar = getAvatar()
	dxDrawImage(mta_posxOffset + 15, mta_posyOffset + 12, 40, 40, avatar and avatar.tex or ":cache/default.png", 0, 0, 0, tocolor(255, 255, 255, 255), true)
	
	-- الترحيب - باستخدام الترحيب المتغير
	dxDrawText(currentGreeting.." "..username, mta_posxOffset + 65, mta_posyOffset + 15, mta_posxOffset + width - 10, mta_posyOffset + 45, tocolor(52, 171, 173, 255), 0.85, arabicFont, "right", "center", false, false, true, false, false)
	
	-- النقاط
	dxDrawImage(mta_posxOffset + width - 25, mta_posyOffset + 55, 16, 16, ":donators/gamecoin.png", 0, 0, 0, tocolor(255, 255, 255, 255), true)
	dxDrawText("النقاط:", mta_posxOffset + width - 120, mta_posyOffset + 55, mta_posxOffset + width - 30, mta_posyOffset + 75, tocolor(255, 255, 255, 255), 0.90, arabicFont, "right", "center", false, false, true, false, false)
	dxDrawText(exports.global:formatMoney(credits), mta_posxOffset + 15, mta_posyOffset + 55, mta_posxOffset + width - 125, mta_posyOffset + 75, tocolor(52, 171, 173, 255), 0.90, arabicFont, "left", "center", false, false, true, false, false)
	
	-- الساعات
	dxDrawText(": ساعات اللعب", mta_posxOffset + width - 120, mta_posyOffset + 80, mta_posxOffset + width - 30, mta_posyOffset + 100, tocolor(255, 255, 255, 255), 0.90, arabicFont, "right", "center", false, false, true, false, false)
	dxDrawText(getElementData(localPlayer, "account:hours") or 0, mta_posxOffset + 15, mta_posyOffset + 80, mta_posxOffset + width - 125, mta_posyOffset + 100, tocolor(52, 171, 173, 255), 0.90, arabicFont, "left", "center", false, false, true, false, false)
	
	-- تاريخ الإنشاء
	dxDrawText(": تاريخ الإنشاء", mta_posxOffset + width - 120, mta_posyOffset + 105, mta_posxOffset + width - 30, mta_posyOffset + 125, tocolor(255, 255, 255, 255), 0.90, arabicFont, "right", "center", false, false, true, false, false)
	dxDrawText(createdDate, mta_posxOffset + 15, mta_posyOffset + 105, mta_posxOffset + width - 125, mta_posyOffset + 125, tocolor(52, 171, 173, 255), 0.85, arabicFont, "left", "center", false, false, true, false, false)
	
	-- آخر دخول
	dxDrawText(": آخر تسجيل دخول", mta_posxOffset + width - 120, mta_posyOffset + 130, mta_posxOffset + width - 30, mta_posyOffset + 150, tocolor(255, 255, 255, 255), 0.90, arabicFont, "right", "center", false, false, true, false, false)
	dxDrawText(lastLoginDate or "أبداً", mta_posxOffset + 15, mta_posyOffset + 130, mta_posxOffset + width - 125, mta_posyOffset + 150, tocolor(52, 171, 173, 255), 0.85, arabicFont, "left", "center", false, false, true, false, false)

    -- زر إنشاء شخصية جديدة
    local btnNewChar = buttonSettings.newCharacter
    local hoverNewChar = isInBox( cursorX, cursorY, 
        mta_posxOffset + btnNewChar.x, 
        mta_posxOffset + btnNewChar.x + btnNewChar.width, 
        mta_posyOffset + btnNewChar.y, 
        mta_posyOffset + btnNewChar.y + btnNewChar.height 
    )
    
    local newCharColor = hoverNewChar and tocolor(52, 171, 173, 200) or tocolor(52, 171, 173, 120)
    
    dxDrawRectangle(mta_posxOffset + btnNewChar.x, mta_posyOffset + btnNewChar.y, btnNewChar.width, btnNewChar.height, newCharColor, true)
    dxDrawText(btnNewChar.text, 
        mta_posxOffset + btnNewChar.x, 
        mta_posyOffset + btnNewChar.y, 
        mta_posxOffset + btnNewChar.x + btnNewChar.width, 
        mta_posyOffset + btnNewChar.y + btnNewChar.height, 
        tocolor(255, 255, 255, 255), btnNewChar.textScale, arabicFont, "center", "center", false, false, true, false, false
    )
    
    if justClicked and hoverNewChar then
        if guiGetText(newCharacterButton_text) ~= "جاري التحقق من عدد الشخصيات..." then
            guiSetText(newCharacterButton_text, "جاري التحقق من عدد الشخصيات...")
            guiSetEnabled(newCharacterButton_text, false)
            guiSetEnabled(newCharacterButton, false)
            guiSetAlpha(newCharacterButton_text, 0.3)
            triggerServerEvent('account:charactersQuotaCheck', resourceRoot)
        end
    end

    -- زر تحديث الشخصيات
    local btnRefresh = buttonSettings.refresh
    local hoverRefresh = isInBox( cursorX, cursorY, 
        mta_posxOffset + btnRefresh.x, 
        mta_posxOffset + btnRefresh.x + btnRefresh.width, 
        mta_posyOffset + btnRefresh.y, 
        mta_posyOffset + btnRefresh.y + btnRefresh.height 
    )
    
    local refreshColor = hoverRefresh and tocolor(52, 171, 173, 200) or tocolor(52, 171, 173, 120)
    local refreshTextColor = cooldown and cooldown>=getTickCount()-5000 and tocolor(255, 255, 255, 100) or tocolor(255, 255, 255, 255)
    
    dxDrawRectangle(mta_posxOffset + btnRefresh.x, mta_posyOffset + btnRefresh.y, btnRefresh.width, btnRefresh.height, refreshColor, true)
    dxDrawText(btnRefresh.text, 
        mta_posxOffset + btnRefresh.x, 
        mta_posyOffset + btnRefresh.y, 
        mta_posxOffset + btnRefresh.x + btnRefresh.width, 
        mta_posyOffset + btnRefresh.y + btnRefresh.height, 
        refreshTextColor, btnRefresh.textScale, arabicFont, "center", "center", false, false, true, false, false
    )
    
    if justClicked and hoverRefresh and not cooldown then
        triggerServerEvent("updateCharacters", resourceRoot, true)
        cooldown = getTickCount()
    end

    -- زر تسجيل الدخول
    local btnLogin = buttonSettings.login
    local hoverLogin = isInBox( cursorX, cursorY, 
        mta_posxOffset + btnLogin.x, 
        mta_posxOffset + btnLogin.x + btnLogin.width, 
        mta_posyOffset + btnLogin.y, 
        mta_posyOffset + btnLogin.y + btnLogin.height 
    )
    
    local loginColor = hoverLogin and tocolor(52, 171, 173, 200) or tocolor(52, 171, 173, 120)
    
    dxDrawRectangle(mta_posxOffset + btnLogin.x, mta_posyOffset + btnLogin.y, btnLogin.width, btnLogin.height, loginColor, true)
    dxDrawText(btnLogin.text, 
        mta_posxOffset + btnLogin.x, 
        mta_posyOffset + btnLogin.y, 
        mta_posxOffset + btnLogin.x + btnLogin.width, 
        mta_posyOffset + btnLogin.y + btnLogin.height, 
        tocolor(255, 255, 255, 255), btnLogin.textScale, arabicFont, "center", "center", false, false, true, false, false
    )
    
    if justClicked and hoverLogin then
        removeEventHandler("onClientRender", getRootElement(), renderNametags)
        removeEventHandler("onClientRender", root, characterMouseOver)
        fadeCamera ( false, 2, 0,0,0 )
        setTimer(function()
            triggerServerEvent("accounts:reconnectMe", localPlayer)
        end, 2000,1)
    end

	justClicked = false
end

forumLink = {
button = {},
window = {},
edit = {},
label = {}
}

function linkForumAccount()
	if isElement(forumLink.window[1]) then destroyElement(forumLink.window[1]) end

	guiSetInputEnabled(true)
	forumLink.window[1] = guiCreateWindow(749, 273, 318, 223, "Forum Login", false)
	guiWindowSetSizable(forumLink.window[1], false)
	exports.global:centerWindow(forumLink.window[1])

	forumLink.button[1] = guiCreateButton(165, 171, 143, 42, "Cancel", false, forumLink.window[1])
	guiSetProperty(forumLink.button[1], "NormalTextColour", "FFAAAAAA")
	forumLink.button[2] = guiCreateButton(9, 171, 146, 42, "Login", false, forumLink.window[1])
	guiSetProperty(forumLink.button[2], "NormalTextColour", "FFAAAAAA")
	forumLink.label[1] = guiCreateLabel(11, 23, 287, 17, "OwlGaming Forum Login", false, forumLink.window[1])
	guiSetFont(forumLink.label[1], "default-bold-small")
	guiLabelSetHorizontalAlign(forumLink.label[1], "center", false)
	forumLink.label[2] = guiCreateLabel(12, 40, 287, 17, "Enter your forum credentials below", false, forumLink.window[1])
	guiLabelSetHorizontalAlign(forumLink.label[2], "center", false)
	forumLink.label[3] = guiCreateLabel(19, 71, 113, 15, "Username:", false, forumLink.window[1])
	forumLink.edit[1] = guiCreateEdit(20, 86, 278, 23, "", false, forumLink.window[1])
	forumLink.label[4] = guiCreateLabel(19, 118, 113, 15, "Password:", false, forumLink.window[1])
	forumLink.edit[2] = guiCreateEdit(20, 133, 278, 23, "", false, forumLink.window[1])

	guiEditSetMaxLength ( forumLink.edit[1] ,25)
	guiEditSetMaxLength ( forumLink.edit[2] ,25)
	guiEditSetMasked ( forumLink.edit[2] , true )
	guiSetProperty( forumLink.edit[2] , 'MaskCodepoint', '8226' )

	addEventHandler("onClientGUIClick", forumLink.button[1], function()
		destroyElement(forumLink.window[1])
		guiSetInputEnabled(false)
		end, false)

	addEventHandler("onClientGUIClick", forumLink.button[2], function()
		local username = guiGetText(forumLink.edit[1])
		local password = guiGetText(forumLink.edit[2])
		if username~="" and password~="" then
			triggerServerEvent("forum:login", root, username, password)
		end
		end, false)
end

function returnForumResults(result, er)
	if not result then
		guiSetText(forumLink.label[1], er)
		guiLabelSetColor( forumLink.label[1], 255, 0, 0 )
		guiSetText(forumLink.edit[1], "")
		guiSetText(forumLink.edit[2], "")
	else
		destroyElement(forumLink.window[1])
		guiSetInputEnabled(false)
		--Now display forums info box.
		forum_box['show'] = true
	end
end
addEvent("forum:loginResult", true)
addEventHandler("forum:loginResult", resourceRoot, returnForumResults)

function Characters_characterSelectionVisisble()
	addEventHandler("onClientClick", getRootElement(), Characters_onClientClick)

	-- إخفاء الأزرار القديمة
	if isElement(bLogout) then
		destroyElement(bLogout)
	end
	if isElement(newCharacterButton) then
		destroyElement(newCharacterButton)
	end

	showing = true
	addEventHandler("onClientRender", root, renderAccountStats)
end

function charactersQuotaCheck(ok, why)
	-- تحديث النص في الزر الجديد
	if ok then
		Characters_deactivateGUI()
		characters_destroyDetailScreen()
		newCharacter_init()
	end
end
addEvent('account:charactersQuotaCheck', true)
addEventHandler('account:charactersQuotaCheck', resourceRoot, charactersQuotaCheck)

--Character info box / Maxime
local function getHoverElement()
	local cursorX, cursorY, absX, absY, absZ = getCursorPosition( )
	local cameraX, cameraY, cameraZ = getWorldFromScreenPosition( cursorX, cursorY, 0.1 )

	local a, b, c, d, element = processLineOfSight( cameraX, cameraY, cameraZ, absX, absY, absZ )
	if element and getElementParent(getElementParent(element)) == getResourceRootElement(getResourceFromName("account")) then
		return element
	elseif b and c and d then
		element = nil
		local x, y, z = nil
		local maxdist = 0.34
		for key, value in ipairs(getElementsByType("ped", getResourceRootElement(getResourceFromName("account")))) do
			if isElementStreamedIn(value) and isElementOnScreen(value) then
				x, y, z = getElementPosition(value)
				local dist = getDistanceBetweenPoints3D(x, y, z, b, c, d)
				if dist < maxdist then
					element = value
					maxdist = dist
				end
			end
		end
		if element then
			return element
		end
	end
end

local font1 = dxCreateFont(':resources/nametags0.ttf')
local font2 = dxCreateFont(':interior_system/intNameFont.ttf')

function truncateText(text, maxLength)
    if string.len(text) > maxLength then
        return string.sub(text, 1, maxLength - 3) .. "..."
    end
    return text
end

function characterMouseOver()
    local cursorX, cursorY
    if isCursorShowing( ) then
        local ped = getHoverElement()
        if ped and isElement(ped) then
            cursorX, cursorY = getCursorPosition( )
            cursorX, cursorY = cursorX * swidth, cursorY * sheight
            local ox, oy = cursorX-1053, cursorY-564
            
            -- صورة الشخصية
            dxDrawImage(805+ox, 432+oy, 109, 105, "img/" .. ("%03d"):format(getElementModel(ped)) .. ".png", 0, 0, 0, tocolor(255, 255, 255, 255), true)
            
            -- معلومات الشخصية بالعربية
            local tRace = "أسود"
            local race = getElementData(ped, "account:charselect:race")
            if race == 1 then
                tRace = "أبيض"
            elseif race == 2 then
                tRace = "آسيوي"
            end
            
            local genderText = getElementData(ped, "account:charselect:gender") == 0 and "ذكر" or "أنثى"
            local statusText = getElementData(ped, "account:charselect:cked") > 0 and "ميت" or "حي"
            
            local text = "■ العرق: "..tRace..
                       "\n■ الجنس: "..genderText..
                       "\n■ الحالة: "..statusText..
                       "\n■ العمر: "..getElementData(ped, "account:charselect:age")..
                       "\n■ الطول: "..getElementData(ped, "account:charselect:height").."سم"..
                       "\n■ الوزن: "..getElementData(ped, "account:charselect:weight").."كجم"..
                       "\n■ ساعات اللعب: "..getElementData(ped, "account:charselect:hoursplayed").."س"
            
            -- الخلفية
            dxDrawRectangle(910+ox, 430+oy, 140, 110, tocolor(3, 20, 23, 220), true)
            
            -- النص
            dxDrawText(text, 915+ox, 435+oy, 1045+ox, 535+oy, tocolor(255, 255, 255, 255), 0.85, arabicFont, "right", "top", true, false, true, true, false)
            
            -- الخط السفلي
            dxDrawLine(805+ox, 542+oy, 1017+ox, 542+oy, tocolor(52, 171, 173, 255), 2, true)
            
            -- نص الضغط للعب
            local name = exports.global:explode(" ", getElementData(ped,"account:charselect:name"))[1]
            local playText = "إضغط للعب كـ "..name
            
            dxDrawText(playText, 805+ox, 549+oy, 1017+ox, 565+oy, tocolor(52, 171, 173, 255), 1.00, arabicFont, "center", "center", true, false, true, false, false)
            
            updateCharacterAnim(ped)
        end
    end
end

local lastCharAnim = nil
function updateCharacterAnim(theElement)
	if not theElement then lastCharAnim = nil end
	if theElement and theElement ~= lastCharAnim then
		lastCharAnim = theElement
		local cked = getElementData(theElement,"account:charselect:cked")
		local randomAnimation = cked > 0 and getRandomAnim( 4 ) or getRandomAnim( 1 )
		setPedAnimation ( theElement , randomAnimation[1], randomAnimation[2], -1, cked > 0, false, false, false )
		playSoundFrontEnd(cked>0 and 4 or 1)
	end
end

function getCamSpeed( index1, startCam1, endCam1, globalspeed1)
return (math.abs(startCam1[index1]-endCam1[index1])/globalspeed1)
end

function Characters_updateSelectionCamera ()
	for var = 1, 6, 1 do
		if not doneCam[selectionScreenID][var] then
			if (math.abs(startCam[selectionScreenID][var] - endCam[selectionScreenID][var]) > 0.2) then
			if startCam[selectionScreenID][var] > endCam[selectionScreenID][var] then
			startCam[selectionScreenID][var] = startCam[selectionScreenID][var] - getCamSpeed( var, startCam[selectionScreenID], endCam[selectionScreenID], globalspeed)
		else
			startCam[selectionScreenID][var] = startCam[selectionScreenID][var] + getCamSpeed( var, startCam[selectionScreenID], endCam[selectionScreenID], globalspeed)
		end
	else
		doneCam[selectionScreenID][var] = true
	end
end
end

setCameraMatrix (startCam[selectionScreenID][1], startCam[selectionScreenID][2], startCam[selectionScreenID][3], startCam[selectionScreenID][4], startCam[selectionScreenID][5], startCam[selectionScreenID][6], 0, exports.global:getPlayerFov())
if doneCam[selectionScreenID][1] and doneCam[selectionScreenID][2] and doneCam[selectionScreenID][3] and doneCam[selectionScreenID][4] and doneCam[selectionScreenID][5] and doneCam[selectionScreenID][6] then
	stopMovingCam()
end
end

function stopMovingCam()
	removeEventHandler("onClientRender",getRootElement(),Characters_updateSelectionCamera)
	Characters_characterSelectionVisisble()
end

function renderNametags()
	for key, player in ipairs(getElementsByType("ped")) do
		if (isElement(player))then
			if (getElementData(player,"account:charselect:id")) then
				local lx, ly, lz = getElementPosition( localPlayer )
				local rx, ry, rz = getElementPosition(player)
				local distance = getDistanceBetweenPoints3D(lx, ly, lz, rx, ry, rz)
				if  (isElementOnScreen(player)) then
					local lx, ly, lz = getCameraMatrix()
					local collision, cx, cy, cz, element = processLineOfSight(lx, ly, lz, rx, ry, rz+1, true, true, true, true, false, false, true, false, nil)
					if not (collision) then
						local x, y, z = getElementPosition(player)
						local sx, sy = getScreenFromWorldPosition(x, y, z+0.45, 100, false)
						if (sx) and (sy) then
							if (distance<=2) then
								sy = math.ceil( sy - ( 2 - distance ) * 40 )
							end
							sy = sy - 20
							if (sx) and (sy) then
								distance = 1.5
								local offset = 75 / distance
								dxDrawText(getElementData(player,"account:charselect:name"), sx-offset+2, sy+2, (sx-offset)+130 / distance, sy+20 / distance, tocolor(0, 0, 0, 220), 0.6 / distance, "bankgothic", "center", "center", false, false, false)
								dxDrawText(getElementData(player,"account:charselect:name"), sx-offset, sy, (sx-offset)+130 / distance, sy+20 / distance, tocolor(255, 255, 255, 220), 0.6 / distance, "bankgothic", "center", "center", false, false, false)
							end
						end
					end
				end
			end
		end
	end
end

function Characters_onClientClick(mouseButton, state, alsoluteX, alsoluteY, worldX, worldY, worldZ, theElement)
	if mouseButton=="left" and state=="up" and theElement and getElementData(theElement, "account:charselect:cked") == 0 then
		if (getElementData(theElement,"account:charselect:id")) then
			characterSelected = getElementData(theElement,"account:charselect:id")
			characterElementSelected = theElement

			Characters_deactivateGUI()
			local randomAnimation = getRandomAnim(3)
			setPedAnimation ( characterElementSelected, randomAnimation[1], randomAnimation[2], -1, true, false, false, false )
			cFadeOutTime = 254
			addEventHandler("onClientRender", getRootElement(), Characters_FadeOut)
			fadeCamera ( false, 2, 0,0,0 )
			setTimer(function()
				triggerServerEvent("accounts:characters:spawn", localPlayer, characterSelected)
			end, 2000,1)
		end
	end
	justClicked = state=="up"
end

function Characters_deactivateGUI()
	removeEventHandler("onClientRender", getRootElement(), renderNametags)
	removeEventHandler("onClientRender", root, renderAccountStats)
	showing = false
	removeEventHandler("onClientClick", getRootElement(), Characters_onClientClick)
	removeEventHandler("onClientRender", root, characterMouseOver)
end

function Characters_FadeOut()
	cFadeOutTime = cFadeOutTime -3
	if (cFadeOutTime <= 0) then
		removeEventHandler("onClientRender", getRootElement(), Characters_FadeOut)
	else
		for _, thePed in ipairs(pedTable) do
			if isElement(thePed) and (thePed ~= characterElementSelected) then
				setElementAlpha(thePed, cFadeOutTime)
			end
		end
	end
end

function characters_destroyDetailScreen()
	if isElement(wDetailScreen) then
		destroyElement(iCharacterImage)
		destroyElement(bPlayAs)
		destroyElement(wDetailScreen)
		iCharacterImage = nil
		iPlayAs = nil
		wDetailScreen = nil
		character_detail_yoffset = 0
	end
	for _, thePed in ipairs(pedTable) do
		if isElement(thePed) then
			destroyElement(thePed)
		end
	end
	pedTable = { }
	cFadeOutTime = 0
	if isElement(newCharacterButton) then
		destroyElement( newCharacterButton )
	end
	if isElement(bLogout) then
		destroyElement( bLogout )
	end
	removeEventHandler("onClientRender", root, renderAccountStats)
	showing = false
end

function characters_onSpawn(fixedName, adminLevel, gmLevel, location)
	clearChat()
	showChat(true)
	guiSetInputEnabled(false)
	showCursor(false)
	outputChatBox("Press F1 for Help.", 255, 194, 14)
	outputChatBox("You can visit the Options menu by pressing 'F10' or /home.", 255, 194, 15)
	outputChatBox(" ")
	characters_destroyDetailScreen()

	setElementData(localPlayer, "admin_level", adminLevel, false)
	setElementData(localPlayer, "account:gmlevel", gmLevel, false)

	options_enable()
	stopLoginSound()
	if toggleSoundLabel then 
		destroyElement(toggleSoundLabel)
		toggleSoundLabel = nil
	end

	setTimer(function(expectedLocation)
		local currentPositionX, currentPositionY = getElementPosition(localPlayer)
		local expectedPositionX, expectedPositionY = expectedLocation[1], expectedLocation[2]
		if getDistanceBetweenPoints2D( currentPositionX, currentPositionY, unpack( defaultCharacterSelectionSpawnPosition ) ) < 20 and
				getDistanceBetweenPoints2D( expectedPositionX, expectedPositionY, unpack( defaultCharacterSelectionSpawnPosition ) ) > 20 then
			outputDebugString('We got stuck in a river near Angel Pine, oooh~', 2)
			triggerServerEvent('accounts:characters:fixCharacterSpawnPosition', localPlayer, expectedLocation)
		end
	end, 5000, 1, location)
end
addEventHandler("accounts:characters:spawn", getRootElement(), characters_onSpawn)

function stopLoginSound()
	local bgMusic = getElementData(localPlayer, "bgMusic")
	if bgMusic and isElement(bgMusic) then
		setTimer(startSoundFadeOut, 2000, 1, bgMusic, 100, 30, 0.04, "bgMusic")
	end
	local selectionSound = getElementData(localPlayer, "selectionSound")
	if selectionSound and isElement(selectionSound) then
		destroyElement(selectionSound)
		bgMusic = nil
	end
end

function soundFadeOut(sound, decrease, dataKey)
	if sound and isElement(sound) then
		local oldVol = getSoundVolume(sound)
		if oldVol <= 0 then
			if soundFadeTimer and isElement(soundFadeTimer) then
				killTimer(soundFadeTimer)
				soundFadeTimer = nil
			end
			destroyElement(sound)
			if dataKey then
				setElementData(localPlayer, dataKey, false)
			end
		else
			if not decrease then decrease = 0.05 end
			local newVol = oldVol - decrease
			setSoundVolume(sound, newVol)
		end
	end
end

function startSoundFadeOut(sound, timeInterval, timesToExecute, decrease, dataKey)
	if not sound or not isElement(sound) then return false end
	if not tonumber(timeInterval) then timeInterval = 100 end
	if not tonumber(timesToExecute) then timesToExecute = 30 end
	if not tonumber(decrease) then decrease = 0.05 end
	soundFadeTimer = setTimer(soundFadeOut, timeInterval, timesToExecute, sound, decrease, dataKey)
	setTimer(forceStopSound, 4000, 1, sound, dataKey)
end

function forceStopSound(sound, dataKey)
	if sound and isElement(sound) then
		destroyElement(sound)
		if dataKey then
			setElementData(localPlayer, dataKey, false)
		end
	end
end

function playerLogout()
	Characters_deactivateGUI()
	characters_destroyDetailScreen()
	for _, thePed in ipairs(pedTable) do
		destroyElement(thePed, 0)
	end
end