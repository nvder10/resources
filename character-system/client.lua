-- نظام الشخصيات الحديث - كامل ومتكامل
local screenWidth, screenHeight = guiGetScreenSize()
local systemState = "selection" -- selection, creation
local characterList = {}
local currentCharacterData = {}

-- 🎨 الألوان
local colors = {
    background = tocolor(15, 15, 25, 230),
    panel_bg = tocolor(30, 30, 40, 240),
    header_bg = tocolor(45, 45, 55, 255),
    accent = tocolor(100, 65, 165, 255),
    accent_light = tocolor(120, 85, 200, 255),
    white = tocolor(255, 255, 255, 255),
    text = tocolor(255, 255, 255, 255),
    text_light = tocolor(200, 200, 220, 255),
    success = tocolor(80, 255, 80, 255),
    error = tocolor(255, 80, 80, 255),
    male = tocolor(65, 105, 225, 255),
    female = tocolor(220, 20, 60, 255)
}

-- 📝 الخطوط
local fonts = {
    title = dxCreateFont("fonts/Tajawal-Bold.ttf", 18) or "default-bold",
    subtitle = dxCreateFont("fonts/Tajawal-Bold.ttf", 14) or "default-bold",
    normal = dxCreateFont("fonts/Tajawal-Regular.ttf", 12) or "default",
    small = dxCreateFont("fonts/Tajawal-Regular.ttf", 10) or "default"
}

-- 🖼️ الصور
local images = {
    background = dxCreateTexture("images/background.png"),
    panel = dxCreateTexture("images/charpanel.png"),
    logo = dxCreateTexture("images/logopr.png"),
    button = dxCreateTexture("images/button.png"),
    left_arrow = dxCreateTexture("images/left_arrow.png"),
    right_arrow = dxCreateTexture("images/right_arrow.png")
}

-- 🔊 الصوت
function playClickSound()
    local sound = playSound("sounds/click.mp3")
    if sound then
        setSoundVolume(sound, 0.7)
    end
end

-- 🎯 الواجهة الرئيسية
function drawCharacterSystem()
    -- خلفية شفافة
    dxDrawRectangle(0, 0, screenWidth, screenHeight, tocolor(0, 0, 0, 180))
    
    if systemState == "selection" then
        drawSelectionScreen()
    elseif systemState == "creation" then
        drawCreationScreen()
    end
end

-- 🎮 شاشة اختيار الشخصيات
function drawSelectionScreen()
    -- اللوحة الرئيسية
    local panelWidth, panelHeight = 800, 600
    local panelX, panelY = (screenWidth - panelWidth) / 2, (screenHeight - panelHeight) / 2
    
    -- خلفية اللوحة
    dxDrawRectangle(panelX, panelY, panelWidth, panelHeight, colors.panel_bg)
    dxDrawRectangle(panelX, panelY, panelWidth, 4, colors.accent)
    
    -- الهيدر
    dxDrawRectangle(panelX, panelY, panelWidth, 80, colors.header_bg)
    dxDrawText("👥 نظام الشخصيات", panelX, panelY, panelX + panelWidth, panelY + 80, colors.white, 1.2, fonts.title, "center", "center")
    
    -- معلومات الحساب
    local username = getElementData(localPlayer, "account:username") or "زائر"
    local accountHours = getElementData(localPlayer, "account:hours") or 0
    
    dxDrawText("🎮 مرحباً " .. username, panelX + 20, panelY + 90, panelX + panelWidth - 20, panelY + 120, colors.text_light, 1.0, fonts.subtitle, "right")
    dxDrawText("⏰ ساعات اللعب: " .. accountHours, panelX + 20, panelY + 120, panelX + panelWidth - 20, panelY + 150, colors.text_light, 0.8, fonts.normal, "right")
    
    -- قسم الشخصيات
    local charactersStartY = panelY + 160
    dxDrawText("📋 شخصياتك", panelX + 20, charactersStartY - 30, panelX + panelWidth - 20, charactersStartY, colors.white, 1.0, fonts.subtitle, "right")
    
    -- عرض الشخصيات
    if #characterList > 0 then
        drawCharactersList(panelX, charactersStartY, panelWidth, 300)
    else
        -- لا توجد شخصيات
        local noCharsY = panelY + panelHeight / 2
        dxDrawText("📭 لا توجد شخصيات متاحة", panelX, noCharsY - 50, panelX + panelWidth, noCharsY, colors.white, 1.2, fonts.subtitle, "center", "center")
        dxDrawText("انقر على زر 'إنشاء شخصية جديدة' للبدء!", panelX, noCharsY, panelX + panelWidth, noCharsY + 30, colors.text_light, 0.9, fonts.normal, "center", "center")
    end
    
    -- الأزرار السفلية
    drawBottomButtons(panelX, panelY + panelHeight - 100, panelWidth, 80)
end

function drawCharactersList(x, y, width, height)
    local charHeight = 100
    local charsPerRow = 2
    local charWidth = (width - 60) / charsPerRow
    
    for i, character in ipairs(characterList) do
        if i <= 6 then -- حد أقصى 6 شخصيات في الصفحة
            local row = math.floor((i - 1) / charsPerRow)
            local col = (i - 1) % charsPerRow
            
            local charX = x + 20 + (col * (charWidth + 20))
            local charY = y + (row * (charHeight + 15))
            
            drawCharacterCard(character, charX, charY, charWidth, charHeight)
        end
    end
end

function drawCharacterCard(character, x, y, width, height)
    local isHovered = isCursorInBox(x, y, width, height)
    local cardColor = isHovered and tocolor(50, 45, 70, 220) or tocolor(35, 30, 50, 200)
    local borderColor = isHovered and colors.accent_light : colors.accent
    
    -- خلفية البطاقة
    dxDrawRectangle(x, y, width, height, cardColor)
    dxDrawRectangle(x, y, width, 3, borderColor)
    
    -- معلومات الشخصية
    local charName = character[2]:gsub("_", " ")
    local charAge = character[5] or "غير معروف"
    local charGender = character[6] == 0 and "🚹 ذكر" or "🚺 أنثى"
    local charStatus = character[3] == 1 and "💀 متوفى" or "✅ نشط"
    local statusColor = character[3] == 1 and colors.error : colors.success
    
    -- الأيقونة
    dxDrawText("🎭", x + 15, y + 10, x + 45, y + 40, colors.white, 1.0, "default", "center", "center")
    
    -- المعلومات
    dxDrawText(charName, x + 60, y + 10, x + width - 15, y + 30, colors.white, 0.9, fonts.subtitle, "right")
    dxDrawText(charGender, x + 60, y + 30, x + width - 15, y + 50, colors.text_light, 0.8, fonts.normal, "right")
    dxDrawText("🎂 العمر: " .. charAge, x + 60, y + 50, x + width - 15, y + 70, colors.text_light, 0.7, fonts.small, "right")
    dxDrawText(charStatus, x + 60, y + 70, x + width - 15, y + 90, statusColor, 0.7, fonts.small, "right")
    
    -- زر الدخول (للشخصيات النشطة فقط)
    if character[3] == 0 then
        local btnWidth, btnHeight = 80, 30
        local btnX, btnY = x + 15, y + height - btnHeight - 10
        
        local btnHovered = isCursorInBox(btnX, btnY, btnWidth, btnHeight)
        local btnColor = btnHovered and tocolor(100, 65, 165, 220) : tocolor(70, 50, 120, 180)
        
        dxDrawRectangle(btnX, btnY, btnWidth, btnHeight, btnColor)
        dxDrawText("🎮 دخول", btnX, btnY, btnX + btnWidth, btnY + btnHeight, colors.white, 0.8, fonts.small, "center", "center")
    end
end

function drawBottomButtons(x, y, width, height)
    -- زر إنشاء شخصية جديدة
    local btnWidth, btnHeight = 200, 50
    local btnX = x + (width - btnWidth) / 2
    local btnY = y + (height - btnHeight) / 2
    
    local btnHovered = isCursorInBox(btnX, btnY, btnWidth, btnHeight)
    local btnColor = btnHovered and tocolor(100, 65, 165, 220) : tocolor(70, 50, 120, 200)
    
    dxDrawRectangle(btnX, btnY, btnWidth, btnHeight, btnColor)
    dxDrawRectangle(btnX, btnY, btnWidth, 3, colors.accent_light)
    dxDrawText("✨ إنشاء شخصية جديدة", btnX, btnY, btnX + btnWidth, btnY + btnHeight, colors.white, 0.9, fonts.subtitle, "center", "center")
    
    -- زر الخروج
    local logoutBtnWidth, logoutBtnHeight = 120, 35
    local logoutBtnX = x + width - logoutBtnWidth - 20
    local logoutBtnY = y + (height - logoutBtnHeight) / 2
    
    local logoutHovered = isCursorInBox(logoutBtnX, logoutBtnY, logoutBtnWidth, logoutBtnHeight)
    local logoutColor = logoutHovered and tocolor(200, 80, 80, 220) : tocolor(150, 50, 50, 200)
    
    dxDrawRectangle(logoutBtnX, logoutBtnY, logoutBtnWidth, logoutBtnHeight, logoutColor)
    dxDrawText("🚪 خروج", logoutBtnX, logoutBtnY, logoutBtnX + logoutBtnWidth, logoutBtnY + logoutBtnHeight, colors.white, 0.8, fonts.normal, "center", "center")
end

-- 🎨 شاشة إنشاء الشخصية
function drawCreationScreen()
    -- اللوحة الرئيسية
    local panelWidth, panelHeight = 500, 650
    local panelX, panelY = (screenWidth - panelWidth) / 2, (screenHeight - panelHeight) / 2
    
    -- خلفية اللوحة
    dxDrawRectangle(panelX, panelY, panelWidth, panelHeight, colors.panel_bg)
    dxDrawRectangle(panelX, panelY, panelWidth, 4, colors.accent)
    
    -- الهيدر
    dxDrawRectangle(panelX, panelY, panelWidth, 60, colors.header_bg)
    dxDrawText("✨ إنشاء شخصية جديدة", panelX, panelY, panelX + panelWidth, panelY + 60, colors.white, 1.1, fonts.title, "center", "center")
    
    -- محتوى الإنشاء
    local contentY = panelY + 70
    
    -- قسم الجنس
    drawGenderSelection(panelX, contentY, panelWidth)
    
    -- الحقول
    drawCreationFields(panelX, contentY + 100, panelWidth)
    
    -- أزرار التحكم
    drawCreationControls(panelX, panelY + panelHeight - 80, panelWidth, 60)
end

function drawGenderSelection(x, y, width)
    dxDrawText("اختر الجنس:", x + 20, y, x + width - 20, y + 25, colors.white, 1.0, fonts.normal, "right")
    
    local btnWidth, btnHeight = 100, 40
    local maleX = x + (width - (btnWidth * 2 + 20)) / 2
    local femaleX = maleX + btnWidth + 20
    
    -- زر الذكر
    local maleHovered = isCursorInBox(maleX, y + 30, btnWidth, btnHeight)
    local maleColor = currentCharacterData.gender == "male" and colors.male : (maleHovered and tocolor(80, 110, 240, 200) : tocolor(50, 80, 200, 150))
    
    dxDrawRectangle(maleX, y + 30, btnWidth, btnHeight, maleColor)
    dxDrawText("🚹 ذكر", maleX, y + 30, maleX + btnWidth, y + 30 + btnHeight, colors.white, 0.9, fonts.normal, "center", "center")
    
    -- زر الأنثى
    local femaleHovered = isCursorInBox(femaleX, y + 30, btnWidth, btnHeight)
    local femaleColor = currentCharacterData.gender == "female" and colors.female : (femaleHovered and tocolor(240, 80, 120, 200) : tocolor(200, 50, 80, 150))
    
    dxDrawRectangle(femaleX, y + 30, btnWidth, btnHeight, femaleColor)
    dxDrawText("🚺 أنثى", femaleX, y + 30, femaleX + btnWidth, y + 30 + btnHeight, colors.white, 0.9, fonts.normal, "center", "center")
end

function drawCreationFields(x, y, width)
    local fields = {
        {name = "name", label = "اسم الشخصية", placeholder = "أدخل الاسم الكامل", type = "text"},
        {name = "age", label = "العمر", placeholder = "16 - 100", type = "number"},
        {name = "height", label = "الطول", placeholder = "150 - 200 سم", type = "number"},
        {name = "weight", label = "الوزن", placeholder = "50 - 200 كجم", type = "number"}
    }
    
    local fieldHeight = 40
    local spacing = 15
    
    for i, field in ipairs(fields) do
        local fieldY = y + ((i-1) * (fieldHeight + spacing))
        drawCreationField(field, x + 20, fieldY, width - 40, fieldHeight)
    end
end

function drawCreationField(field, x, y, width, height)
    -- خلفية الحقل
    dxDrawRectangle(x, y, width, height, tocolor(40, 40, 50, 200))
    
    -- التسمية
    dxDrawText(field.label, x + 10, y, x + width - 10, y + height, colors.text_light, 0.8, fonts.normal, "right", "center")
    
    -- الخط التحتي
    dxDrawLine(x, y + height - 1, x + width, y + height - 1, colors.accent_light, 2)
end

function drawCreationControls(x, y, width, height)
    -- زر العودة
    local backBtnWidth, backBtnHeight = 120, 40
    local backBtnX = x + 20
    local backBtnY = y + (height - backBtnHeight) / 2
    
    local backHovered = isCursorInBox(backBtnX, backBtnY, backBtnWidth, backBtnHeight)
    local backColor = backHovered and tocolor(120, 120, 140, 200) : tocolor(80, 80, 100, 150)
    
    dxDrawRectangle(backBtnX, backBtnY, backBtnWidth, backBtnHeight, backColor)
    dxDrawText("↩ العودة", backBtnX, backBtnY, backBtnX + backBtnWidth, backBtnY + backBtnHeight, colors.white, 0.8, fonts.normal, "center", "center")
    
    -- زر الإنشاء
    local createBtnWidth, createBtnHeight = 150, 40
    local createBtnX = x + width - createBtnWidth - 20
    local createBtnY = y + (height - createBtnHeight) / 2
    
    local createHovered = isCursorInBox(createBtnX, createBtnY, createBtnWidth, createBtnHeight)
    local createColor = createHovered and tocolor(100, 65, 165, 220) : tocolor(70, 50, 120, 200)
    
    dxDrawRectangle(createBtnX, createBtnY, createBtnWidth, createBtnHeight, createColor)
    dxDrawText("✅ إنشاء", createBtnX, createBtnY, createBtnX + createBtnWidth, createBtnY + createBtnHeight, colors.white, 0.9, fonts.normal, "center", "center")
end

-- 🖱️ معالجة النقر
function handleCharacterSystemClick(button, state)
    if button ~= "left" or state ~= "up" then return end
    
    local cursorX, cursorY = getCursorPosition()
    if not cursorX then return end
    
    cursorX, cursorY = cursorX * screenWidth, cursorY * screenHeight
    
    if systemState == "selection" then
        handleSelectionClick(cursorX, cursorY)
    elseif systemState == "creation" then
        handleCreationClick(cursorX, cursorY)
    end
end

function handleSelectionClick(x, y)
    local panelWidth, panelHeight = 800, 600
    local panelX, panelY = (screenWidth - panelWidth) / 2, (screenHeight - panelHeight) / 2
    
    -- زر إنشاء شخصية جديدة
    local btnWidth, btnHeight = 200, 50
    local btnX = panelX + (panelWidth - btnWidth) / 2
    local btnY = panelY + panelHeight - 100 + (80 - btnHeight) / 2
    
    if isCursorInBox(btnX, btnY, btnWidth, btnHeight) then
        playClickSound()
        systemState = "creation"
        currentCharacterData = {gender = "male"}
        return
    end
    
    -- زر الخروج
    local logoutBtnWidth, logoutBtnHeight = 120, 35
    local logoutBtnX = panelX + panelWidth - logoutBtnWidth - 20
    local logoutBtnY = panelY + panelHeight - 100 + (80 - logoutBtnHeight) / 2
    
    if isCursorInBox(logoutBtnX, logoutBtnY, logoutBtnWidth, logoutBtnHeight) then
        playClickSound()
        triggerServerEvent("characterSystem:logout", localPlayer)
        return
    end
    
    -- النقر على الشخصيات
    if #characterList > 0 then
        local charHeight = 100
        local charsPerRow = 2
        local charWidth = (panelWidth - 60) / charsPerRow
        local charactersStartY = panelY + 160
        
        for i, character in ipairs(characterList) do
            if i <= 6 and character[3] == 0 then -- شخصيات نشطة فقط
                local row = math.floor((i - 1) / charsPerRow)
                local col = (i - 1) % charsPerRow
                
                local charX = panelX + 20 + (col * (charWidth + 20))
                local charY = charactersStartY + (row * (charHeight + 15))
                
                -- زر الدخول
                local btnWidth, btnHeight = 80, 30
                local btnX, btnY = charX + 15, charY + charHeight - btnHeight - 10
                
                if isCursorInBox(btnX, btnY, btnWidth, btnHeight) then
                    playClickSound()
                    triggerServerEvent("characterSystem:selectCharacter", localPlayer, character[1])
                    return
                end
            end
        end
    end
end

function handleCreationClick(x, y)
    local panelWidth, panelHeight = 500, 650
    local panelX, panelY = (screenWidth - panelWidth) / 2, (screenHeight - panelHeight) / 2
    
    -- أزرار الجنس
    local btnWidth, btnHeight = 100, 40
    local maleX = panelX + (panelWidth - (btnWidth * 2 + 20)) / 2
    local femaleX = maleX + btnWidth + 20
    local genderY = panelY + 70 + 30
    
    if isCursorInBox(maleX, genderY, btnWidth, btnHeight) then
        playClickSound()
        currentCharacterData.gender = "male"
        return
    end
    
    if isCursorInBox(femaleX, genderY, btnWidth, btnHeight) then
        playClickSound()
        currentCharacterData.gender = "female"
        return
    end
    
    -- زر العودة
    local backBtnWidth, backBtnHeight = 120, 40
    local backBtnX = panelX + 20
    local backBtnY = panelY + panelHeight - 80 + (60 - backBtnHeight) / 2
    
    if isCursorInBox(backBtnX, backBtnY, backBtnWidth, backBtnHeight) then
        playClickSound()
        systemState = "selection"
        return
    end
    
    -- زر الإنشاء
    local createBtnWidth, createBtnHeight = 150, 40
    local createBtnX = panelX + panelWidth - createBtnWidth - 20
    local createBtnY = panelY + panelHeight - 80 + (60 - createBtnHeight) / 2
    
    if isCursorInBox(createBtnX, createBtnY, createBtnWidth, createBtnHeight) then
        playClickSound()
        createNewCharacter()
        return
    end
end

function createNewCharacter()
    -- هنا سيتم إضافة التحقق من البيانات وإرسالها للسيرفر
    if not currentCharacterData.gender then
        outputChatBox("⚠️ يرجى اختيار الجنس", 255, 100, 100)
        return
    end
    
    -- إرسال البيانات للسيرفر
    triggerServerEvent("characterSystem:createCharacter", localPlayer, currentCharacterData)
end

-- 🔧 دوال مساعدة
function isCursorInBox(x, y, width, height)
    local cursorX, cursorY = getCursorPosition()
    if not cursorX then return false end
    
    cursorX, cursorY = cursorX * screenWidth, cursorY * screenHeight
    return cursorX >= x and cursorX <= x + width and cursorY >= y and cursorY <= y + height
end

-- 🚀 أحداث النظام
addEvent("characterSystem:open", true)
addEventHandler("characterSystem:open", root, function()
    showCursor(true)
    systemState = "selection"
    triggerServerEvent("characterSystem:getCharacters", localPlayer)
    addEventHandler("onClientRender", root, drawCharacterSystem)
    addEventHandler("onClientClick", root, handleCharacterSystemClick)
end)

addEvent("characterSystem:receiveCharacters", true)
addEventHandler("characterSystem:receiveCharacters", root, function(characters)
    characterList = characters or {}
end)

addEvent("characterSystem:creationResult", true)
addEventHandler("characterSystem:creationResult", root, function(success, message)
    if success then
        outputChatBox("✅ " .. (message or "تم إنشاء الشخصية بنجاح!"), 100, 255, 100)
        systemState = "selection"
        triggerServerEvent("characterSystem:getCharacters", localPlayer) -- تحديث القائمة
    else
        outputChatBox("❌ " .. (message or "فشل في إنشاء الشخصية"), 255, 100, 100)
    end
end)

-- 🎯 تصديرات
function openCharacterSystem()
    triggerEvent("characterSystem:open", localPlayer)
end

function getCharacterSystemState()
    return systemState
end