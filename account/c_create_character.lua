-- This project by nadoory yasta ha ? :)

local gui = {}
local curskin = 1
local dummyPed = nil
local selectedGender = 0 -- 0: ذكر, 1: أنثى
local screenWidth, screenHeight = guiGetScreenSize()
local panelWidth, panelHeight = 320, 480
local panelX, panelY = 20, (screenHeight - panelHeight) / 2

-- متغيرات للتأثيرات
local hoverLeftArrow = false
local hoverRightArrow = false
local hoverMale = false
local hoverFemale = false
local hoverConfirm = false
local hoverCancel = false

-- متغيرات للتوست التحذيري
local showToast = false
local toastMessage = ""
local toastTimer = nil

-- الخطوط
local fontTitle = nil
local fontLabel = nil
local fontField = nil
local fontToast = nil

-- متغيرات للإدخال
local activeField = nil
local cursorVisible = false
local cursorTimer = nil
local textCursor = "|"

-- متغير الهوفر
local hoverAge = false
local hoverHeight = false
local hoverWeight = false
local draggingSlider = nil

-- متغير للتحقق من التحميل
local characterSystemLoaded = false

local backspacePressed = false
local backspaceTimer = nil
local backspaceDelay = 500 -- تأخير قبل البدء في المسح المستمر (ميلي ثانية)
local backspaceRepeat = 50 -- سرعة المسح المستمر (ميلي ثانية)


function newCharacter_init()
    -- التحقق من عدم تحميل النظام مسبقاً
    if characterSystemLoaded then
        outputChatBox("النظام محمل مسبقاً!", 255, 255, 0)
        return true
    end
    
    -- تحميل الخطوط مع معالجة الأخطاء
    fontTitle = dxCreateFont("Tajawal-Bold.ttf", 18) or "default-bold"
    fontLabel = dxCreateFont("Tajawal-Regular.ttf", 11) or "default"
    fontField = dxCreateFont("Tajawal-Regular.ttf", 12) or "default"
    fontToast = dxCreateFont("Tajawal-Regular.ttf", 14) or "default-bold"
    
    if not fontTitle then
        outputChatBox("تحذير: لم يتم تحميل الخطوط، سيتم استخدام الخطوط الافتراضية", 255, 255, 0)
    end
    
    -- إعداد الكاميرا والعناصر
    guiSetInputEnabled(true)
    setCameraInterior(14)
    setCameraMatrix(254.7190, -41.1370, 1002, 256.7190, -41.1370, 1002)
    
    dummyPed = createPed(217, 258, -42, 1002)
    if not dummyPed then
        outputChatBox("خطأ: فشل في إنشاء الشخصية الافتراضية", 255, 0, 0)
        return false
    end
    
    setElementInterior(dummyPed, 14)
    setElementInterior(getLocalPlayer(), 14)
    setPedRotation(dummyPed, 87)
    setElementDimension(dummyPed, getElementDimension(getLocalPlayer()))
    fadeCamera(true, 1, 0, 0, 0)
    
    -- إنشاء عناصر GUI المخفية للإدخال
    createHiddenGUIElements()
    
    -- إظهار واجهة إنشاء الشخصية
    addEventHandler("onClientRender", root, renderCharacterPanel)
    addEventHandler("onClientClick", root, handlePanelClick)
    addEventHandler("onClientCursorMove", root, handleCursorMove)
    addEventHandler("onClientCharacter", root, handleCharacterInput)
	addEventHandler("onClientKey", root, handleKey)
    
    -- مؤشر الكتابة
    cursorTimer = setTimer(function()
        cursorVisible = not cursorVisible
    end, 500, 0)
    
    showCursor(true)
    characterSystemLoaded = true
    
    outputChatBox("✅ واجهة إنشاء الشخصية جاهزة!", 0, 255, 0)
    return true
end

function createHiddenGUIElements()
    -- إنشاء عناصر GUI مخفية للإدخال
    gui["_root"] = guiCreateStaticImage(0, 0, 1, 1, ":resources/window_body.png", false)
    guiSetVisible(gui["_root"], false)
    
    gui["txtCharName"] = guiCreateEdit(0, 0, 1, 1, "", false, gui["_root"])
    guiSetVisible(gui["txtCharName"], false)
    guiEditSetMaxLength(gui["txtCharName"], 32767)
    
    gui["scrAge"] = guiCreateScrollBar(0, 0, 1, 1, true, false, gui["_root"])
    guiSetVisible(gui["scrAge"], false)
    guiSetProperty(gui["scrAge"], "StepSize", "0.0120")
    guiScrollBarSetScrollPosition(gui["scrAge"], 42) -- قيمة افتراضية (42 + 16 = 58 سنة)
    
    gui["scrHeight"] = guiCreateScrollBar(0, 0, 1, 1, true, false, gui["_root"])
    guiSetVisible(gui["scrHeight"], false)
    guiSetProperty(gui["scrHeight"], "StepSize", "0.02")
    guiScrollBarSetScrollPosition(gui["scrHeight"], 50) -- قيمة افتراضية (50/2 + 150 = 175 سم)
    
    gui["scrWeight"] = guiCreateScrollBar(0, 0, 1, 1, true, false, gui["_root"])
    guiSetVisible(gui["scrWeight"], false)
    guiSetProperty(gui["scrWeight"], "StepSize", "0.01")
    guiScrollBarSetScrollPosition(gui["scrWeight"], 75) -- قيمة افتراضية (75 + 50 = 125 كجم)
end

function showToastMessage(message)
    showToast = true
    toastMessage = message
    
    if toastTimer then
        killTimer(toastTimer)
    end
    
    toastTimer = setTimer(function()
        showToast = false
        toastMessage = ""
    end, 3000, 1)
end

function renderCharacterPanel()
    -- رسم البانل الأساسي بشفافية
    dxDrawRectangle(panelX, panelY, panelWidth, panelHeight, tocolor(0, 0, 0, 200), true)
    
    -- الشعار والعنوان
    dxDrawImage(panelX + 130, panelY + 25, 60, 60, "logopr.png", 0, 0, 0, tocolor(255, 255, 255, 255), true)
    dxDrawText("إنشاء شخصيتك", panelX, panelY + 40, panelX + panelWidth, panelY + 70, tocolor(255, 255, 255, 255), 1.0, fontTitle, "center", "center", false, false, true, false, false)
    
    -- الخط الفاصل تحت العنوان
    dxDrawLine(panelX + 15, panelY + 85, panelX + panelWidth - 15, panelY + 85, tocolor(0, 0, 0, 128), 2, true)
    
    -- الزرين السهمين (أسفل الشاشة)
    local arrowSize = 48
    local arrowY = screenHeight - 100
    local leftArrowX = (screenWidth / 2) - 80
    local rightArrowX = (screenWidth / 2) + 80
    
    -- تأثير التكبير عند التمرير
    local leftArrowScale = hoverLeftArrow and 1.15 or 1.0
    local rightArrowScale = hoverRightArrow and 1.15 or 1.0
    
    -- رسم السهام
    dxDrawImage(leftArrowX - (arrowSize * leftArrowScale / 2), arrowY - (arrowSize * leftArrowScale / 2), 
                arrowSize * leftArrowScale, arrowSize * leftArrowScale, "left_arrow.png", 0, 0, 0, tocolor(255, 255, 255, 255), true)
    dxDrawImage(rightArrowX - (arrowSize * rightArrowScale / 2), arrowY - (arrowSize * rightArrowScale / 2), 
                arrowSize * rightArrowScale, arrowSize * rightArrowScale, "right_arrow.png", 0, 0, 0, tocolor(255, 255, 255, 255), true)
    
    -- خيارات الجنس (في وسط البانل)
    local genderY = panelY + 110
    local genderWidth = 120
    local maleX = panelX + (panelWidth / 2) - genderWidth / 2 - 10
    local femaleX = panelX + (panelWidth / 2) + genderWidth / 2 - 40
    
    -- تأثير التكبير عند التمرير
    local maleScale = hoverMale and 1.15 or 1.0
    local femaleScale = hoverFemale and 1.15 or 1.0
    
    -- رسم خيارات الجنس
    dxDrawText("ذكر", maleX - 25 * maleScale, genderY, maleX + 25 * maleScale, genderY + 25, tocolor(255, 255, 255, 255), 0.9 * maleScale, fontField, "center", "center", false, false, true, false, false)
    dxDrawRectangle(maleX + 30, genderY + 5, 15, 15, tocolor(0, 0, 0, 128))
    if selectedGender == 0 then
        dxDrawText("✓", maleX + 30, genderY + 5, maleX + 45, genderY + 20, tocolor(255, 255, 255, 255), 0.8, fontField, "center", "center", false, false, true, false, false)
    end
    
    dxDrawText("أنثى", femaleX - 25 * femaleScale, genderY, femaleX + 25 * femaleScale, genderY + 25, tocolor(255, 255, 255, 255), 0.9 * femaleScale, fontField, "center", "center", false, false, true, false, false)
    dxDrawRectangle(femaleX + 30, genderY + 5, 15, 15, tocolor(0, 0, 0, 128))
    if selectedGender == 1 then
        dxDrawText("✓", femaleX + 30, genderY + 5, femaleX + 45, genderY + 20, tocolor(255, 255, 255, 255), 0.8, fontField, "center", "center", false, false, true, false, false)
    end
    
    -- الحقول (في وسط البانل)
    local fieldStartY = panelY + 150
    local fieldWidth = 220
    local fieldHeight = 28
    local fieldSpacing = 50
    
    -- حقل الإسم
    local nameX = panelX + (panelWidth - fieldWidth) / 2
    dxDrawText("الإسم", nameX, fieldStartY - 20, nameX + fieldWidth, fieldStartY, tocolor(255, 255, 255, 255), 0.7, fontLabel, "center", "center", false, false, true, false, false)
    dxDrawRectangle(nameX, fieldStartY, fieldWidth, fieldHeight, tocolor(0, 0, 0, 128))
    
    local nameText = guiGetText(gui["txtCharName"]) or ""
    if activeField == "name" and cursorVisible then
        nameText = nameText .. textCursor
    end
    dxDrawText(nameText, nameX, fieldStartY, nameX + fieldWidth, fieldStartY + fieldHeight, tocolor(255, 255, 255, 255), 0.8, fontField, "center", "center", false, false, true, false, false)
    dxDrawLine(nameX, fieldStartY + fieldHeight, nameX + fieldWidth, fieldStartY + fieldHeight, tocolor(220, 20, 60, 255), 1, true)
    
    -- حقل العمر مع شريط التمرير البصري
    local ageX = panelX + (panelWidth - fieldWidth) / 2
    local ageY = fieldStartY + fieldSpacing
    
    -- خلفية شريط التمرير
    dxDrawRectangle(ageX, ageY, fieldWidth, fieldHeight, tocolor(0, 0, 0, 128))
    
    -- حساب الموضع الحالي للشريط
    local ageValue = math.floor((guiScrollBarGetScrollPosition(gui["scrAge"]) * 0.8) + 16)
    local agePercentage = (ageValue - 16) / 84
    local sliderWidth = 20
    local sliderX = ageX + (fieldWidth - sliderWidth) * agePercentage
    
    -- رسم الشريط المنزلق
    local sliderColor = hoverAge and tocolor(220, 20, 60, 200) or tocolor(220, 20, 60, 255)
    dxDrawRectangle(sliderX, ageY, sliderWidth, fieldHeight, sliderColor)
    
    -- النص
    dxDrawText("العمر: " .. ageValue .. " سنة", ageX, ageY, ageX + fieldWidth, ageY + fieldHeight, 
    tocolor(255, 255, 255, 255), 0.7, fontField, "center", "center", false, false, true, false, false)
    dxDrawText("العمر", ageX, ageY - 20, ageX + fieldWidth, ageY, 
	tocolor(255, 255, 255, 255), 0.7, fontLabel, "center", "center", false, false, true, false, false)
    
    -- حقل الطول
    local heightX = panelX + (panelWidth - fieldWidth) / 2
    local heightY = fieldStartY + fieldSpacing * 2
    
    dxDrawRectangle(heightX, heightY, fieldWidth, fieldHeight, tocolor(0, 0, 0, 128))
    
    local heightValue = math.floor((guiScrollBarGetScrollPosition(gui["scrHeight"]) / 2) + 150)
    local heightPercentage = (heightValue - 150) / 50
    local heightSliderX = heightX + (fieldWidth - sliderWidth) * heightPercentage
    
    local heightSliderColor = hoverHeight and tocolor(220, 20, 60, 200) or tocolor(220, 20, 60, 255)
    dxDrawRectangle(heightSliderX, heightY, sliderWidth, fieldHeight, heightSliderColor)
    
    dxDrawText("الطول: " .. heightValue .. " سم", heightX, heightY, heightX + fieldWidth, heightY + fieldHeight, 
    tocolor(255, 255, 255, 255), 0.7, fontField, "center", "center", false, false, true, false, false)
    dxDrawText("الطول", heightX, heightY - 20, heightX + fieldWidth, heightY, 
	tocolor(255, 255, 255, 255), 0.7, fontLabel, "center", "center", false, false, true, false, false)
    
    -- حقل الوزن
    local weightX = panelX + (panelWidth - fieldWidth) / 2
    local weightY = fieldStartY + fieldSpacing * 3
    
    dxDrawRectangle(weightX, weightY, fieldWidth, fieldHeight, tocolor(0, 0, 0, 128))
    
    local weightValue = math.floor(guiScrollBarGetScrollPosition(gui["scrWeight"]) + 50)
    local weightPercentage = (weightValue - 50) / 150
    local weightSliderX = weightX + (fieldWidth - sliderWidth) * weightPercentage
    
    local weightSliderColor = hoverWeight and tocolor(220, 20, 60, 200) or tocolor(220, 20, 60, 255)
    dxDrawRectangle(weightSliderX, weightY, sliderWidth, fieldHeight, weightSliderColor)
    
    dxDrawText("الوزن: " .. weightValue .. " كجم", weightX, weightY, weightX + fieldWidth, weightY + fieldHeight, 
    tocolor(255, 255, 255, 255), 0.7, fontField, "center", "center", false, false, true, false, false)
    dxDrawText("الوزن", weightX, weightY - 20, weightX + fieldWidth, weightY, 
	tocolor(255, 255, 255, 255), 0.7, fontLabel, "center", "center", false, false, true, false, false)

    
    -- زر التأكيد والإلغاء
    local buttonY = panelY + panelHeight - 50
    local buttonWidth = 120
    local buttonHeight = 30
    local confirmX = panelX + (panelWidth / 2) - 130
    local cancelX = panelX + (panelWidth / 2) + 10
    
    -- تأثير التعتيم عند التمرير
    local confirmAlpha = hoverConfirm and 200 or 255
    local cancelAlpha = hoverCancel and 200 or 255
    
    dxDrawImage(confirmX, buttonY, buttonWidth, buttonHeight, "button.png", 0, 0, 0, tocolor(255, 255, 255, confirmAlpha), true)
    dxDrawText("تأكيد الإنشاء", confirmX, buttonY, confirmX + buttonWidth, buttonY + buttonHeight, tocolor(255, 255, 255, 255), 0.8, fontField, "center", "center", false, false, true, false, false)
    
    dxDrawImage(cancelX, buttonY, buttonWidth, buttonHeight, "button.png", 0, 0, 0, tocolor(255, 255, 255, cancelAlpha), true)
    dxDrawText("إلغاء", cancelX, buttonY, cancelX + buttonWidth, buttonY + buttonHeight, tocolor(255, 255, 255, 255), 0.8, fontField, "center", "center", false, false, true, false, false)
    
    -- رسم التوست التحذيري (أعلى الشاشة)
    if showToast then
        local toastWidth = 300
        local toastHeight = 35
        local toastX = (screenWidth - toastWidth) / 2
        local toastY = 50
        
        dxDrawRectangle(toastX, toastY, toastWidth, toastHeight, tocolor(0, 0, 0, 128))
        dxDrawText(toastMessage, toastX, toastY, toastX + toastWidth, toastY + toastHeight, tocolor(255, 255, 255, 255), 0.7, fontToast, "center", "center", false, false, true, false, false)
    end
end

function handleCursorMove(relativeX, relativeY, absoluteX, absoluteY)
    -- تحديث حالة التمرير على العناصر
    local arrowSize = 48
    local arrowY = screenHeight - 100
    local leftArrowX = (screenWidth / 2) - 80
    local rightArrowX = (screenWidth / 2) + 80
    
    hoverLeftArrow = isCursorInArea(absoluteX, absoluteY, leftArrowX - arrowSize/2, arrowY - arrowSize/2, arrowSize, arrowSize)
    hoverRightArrow = isCursorInArea(absoluteX, absoluteY, rightArrowX - arrowSize/2, arrowY - arrowSize/2, arrowSize, arrowSize)
    
    local genderY = panelY + 110
    local genderWidth = 120
    local maleX = panelX + (panelWidth / 2) - genderWidth / 2 - 10
    local femaleX = panelX + (panelWidth / 2) + genderWidth / 2 - 40
    
    hoverMale = isCursorInArea(absoluteX, absoluteY, maleX - 25, genderY, 50, 25)
    hoverFemale = isCursorInArea(absoluteX, absoluteY, femaleX - 25, genderY, 50, 25)
    
    local buttonY = panelY + panelHeight - 50
    local confirmX = panelX + (panelWidth / 2) - 130
    local cancelX = panelX + (panelWidth / 2) + 10
    
    hoverConfirm = isCursorInArea(absoluteX, absoluteY, confirmX, buttonY, 120, 26)
    hoverCancel = isCursorInArea(absoluteX, absoluteY, cancelX, buttonY, 120, 26)

	local fieldStartY = panelY + 150
    local fieldWidth = 220
    local fieldHeight = 28
    local fieldX = panelX + (panelWidth - fieldWidth) / 2
    
    hoverAge = isCursorInArea(absoluteX, absoluteY, fieldX, fieldStartY + 50, fieldWidth, fieldHeight)
    hoverHeight = isCursorInArea(absoluteX, absoluteY, fieldX, fieldStartY + 100, fieldWidth, fieldHeight)
    hoverWeight = isCursorInArea(absoluteX, absoluteY, fieldX, fieldStartY + 150, fieldWidth, fieldHeight)
    
    -- إذا كان المستخدم يسحب شريط التمرير
    if draggingSlider and getKeyState("mouse1") then
        updateSliderValue(draggingSlider, absoluteX, fieldX, fieldWidth)
    end
end

function handlePanelClick(button, state, absX, absY)
    if button == "left" and state == "down" then
        -- تشغيل صوت النقر
        if fileExists("click.mp3") then
            playSound("click.mp3")
        end
        
        -- الزرين السهمين (أسفل الشاشة)
        local arrowSize = 48
        local arrowY = screenHeight - 100
        local leftArrowX = (screenWidth / 2) - 80
        local rightArrowX = (screenWidth / 2) + 80
        
        -- السهم الأيسر
        if isCursorInArea(absX, absY, leftArrowX - arrowSize/2, arrowY - arrowSize/2, arrowSize, arrowSize) then
            newCharacter_changeSkin(-1)
            return
        end
        
        -- السهم الأيمن
        if isCursorInArea(absX, absY, rightArrowX - arrowSize/2, arrowY - arrowSize/2, arrowSize, arrowSize) then
            newCharacter_changeSkin(1)
            return
        end
        
        -- خيارات الجنس
        local genderY = panelY + 110
        local genderWidth = 120
        local maleX = panelX + (panelWidth / 2) - genderWidth / 2 - 10
        local femaleX = panelX + (panelWidth / 2) + genderWidth / 2 - 40
        
        -- ذكر
        if isCursorInArea(absX, absY, maleX - 25, genderY, 50, 25) then
            selectedGender = 0
            newCharacter_updateGender()
            return
        end
        
        -- أنثى
        if isCursorInArea(absX, absY, femaleX - 25, genderY, 50, 25) then
            selectedGender = 1
            newCharacter_updateGender()
            return
        end
        
        -- الحقول
        local fieldStartY = panelY + 150
        local fieldWidth = 220
        local fieldHeight = 28
        local fieldX = panelX + (panelWidth - fieldWidth) / 2
        
        -- حقل الإسم
        if isCursorInArea(absX, absY, fieldX, fieldStartY, fieldWidth, fieldHeight) then
            activeField = "name"
            guiSetInputEnabled(true)
            return
        end
        
        -- شرائح التمرير للعمر والطول والوزن
        if isCursorInArea(absX, absY, fieldX, fieldStartY + 50, fieldWidth, fieldHeight) then
            draggingSlider = "age"
            updateSliderValue("age", absX, fieldX, fieldWidth)
            return
        end
        
        if isCursorInArea(absX, absY, fieldX, fieldStartY + 100, fieldWidth, fieldHeight) then
            draggingSlider = "height"
            updateSliderValue("height", absX, fieldX, fieldWidth)
            return
        end
        
        if isCursorInArea(absX, absY, fieldX, fieldStartY + 150, fieldWidth, fieldHeight) then
            draggingSlider = "weight"
            updateSliderValue("weight", absX, fieldX, fieldWidth)
            return
        end
        
        -- زر التأكيد
        local buttonY = panelY + panelHeight - 50
        local confirmX = panelX + (panelWidth / 2) - 130
        if isCursorInArea(absX, absY, confirmX, buttonY, 120, 26) then
            newCharacter_attemptCreateCharacter()
            return
        end
        
        -- زر الإلغاء
        local cancelX = panelX + (panelWidth / 2) + 10
        if isCursorInArea(absX, absY, cancelX, buttonY, 120, 26) then
            newCharacter_cancel()
            return
        end
        
        -- إذا ضغط في مكان آخر، إلغاء تفعيل الحقل النشط
        activeField = nil
		draggingSlider = nil
    elseif button == "left" and state == "up" then
        draggingSlider = nil
    end
end

function updateSliderValue(sliderType, cursorX, fieldX, fieldWidth)
    local relativeX = cursorX - fieldX
    local percentage = math.max(0, math.min(1, relativeX / fieldWidth))
    
    if sliderType == "age" then
        -- العمر: 16-100 (84 قيمة ممكنة)
        local ageValue = 16 + math.floor(percentage * 84)
        guiScrollBarSetScrollPosition(gui["scrAge"], ageValue - 16)
    elseif sliderType == "height" then
        -- الطول: 150-200 (50 قيمة ممكنة)
        local heightValue = 150 + math.floor(percentage * 50)
        guiScrollBarSetScrollPosition(gui["scrHeight"], (heightValue - 150) * 2)
    elseif sliderType == "weight" then
        -- الوزن: 50-200 (150 قيمة ممكنة)
        local weightValue = 50 + math.floor(percentage * 150)
        guiScrollBarSetScrollPosition(gui["scrWeight"], weightValue - 50)
    end
end

function handleCharacterInput(character)
    if activeField == "name" then
        local currentText = guiGetText(gui["txtCharName"]) or ""
        local newText = currentText .. character
        guiSetText(gui["txtCharName"], newText)
    end
end

function handleKey(button, press)
    if activeField == "name" then
        if button == "backspace" then
            if press then
                -- الضغط على الزر
                backspacePressed = true
                -- مسح أول حرف فوراً
                local currentText = guiGetText(gui["txtCharName"]) or ""
                guiSetText(gui["txtCharName"], string.sub(currentText, 1, -2))
                
                -- بدء المسح المستمر بعد التأخير
                setTimer(function()
                    if backspacePressed then
                        backspaceTimer = setTimer(function()
                            if backspacePressed then
                                local currentText = guiGetText(gui["txtCharName"]) or ""
                                if currentText ~= "" then
                                    guiSetText(gui["txtCharName"], string.sub(currentText, 1, -2))
                                else
                                    backspacePressed = false
                                    if backspaceTimer then
                                        killTimer(backspaceTimer)
                                        backspaceTimer = nil
                                    end
                                end
                            end
                        end, backspaceRepeat, 0)
                    end
                end, backspaceDelay, 1)
                
            else
                -- تحرير الزر
                backspacePressed = false
                if backspaceTimer then
                    killTimer(backspaceTimer)
                    backspaceTimer = nil
                end
            end
            cancelEvent() -- منع السلوك الافتراضي
        end
    end
end


function isCursorInArea(cursorX, cursorY, areaX, areaY, areaWidth, areaHeight)
    return cursorX >= areaX and cursorX <= areaX + areaWidth and cursorY >= areaY and cursorY <= areaY + areaHeight
end

function newCharacter_updateGender()
    curskin = 1
    newCharacter_changeSkin(0)
end

function newCharacter_changeSkin(diff)
    local array = newCharacters_getSkinArray()
    if (diff ~= nil) then
        curskin = curskin + diff
    end

    if (curskin > #array or curskin < 1) then
        curskin = 1
        skin = array[1]
    else
        curskin = curskin
        skin = array[curskin]
    end

    if skin ~= nil then
        setElementModel(dummyPed, tonumber(skin))
    end
end

function newCharacters_getSkinArray()
    local array = {}
    if selectedGender == 0 then -- ذكر
        array = {7, 14, 15, 16, 17, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 32, 33, 34, 35, 36, 37, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 57, 58, 59, 60, 61, 62, 66, 67, 68, 70, 72, 73, 78, 79, 80, 81, 82, 83, 84, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 132, 133, 134, 135, 136, 137, 142, 143, 144, 146, 147, 153, 154, 155, 156, 158, 159, 160, 161, 162, 163, 164, 165, 166, 168, 170, 171, 173, 174, 175, 176, 177, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 200, 202, 203, 204, 206, 209, 210, 212, 213, 217, 220, 221, 222, 223, 227, 228, 229, 230, 234, 235, 236, 240, 241, 242, 247, 248, 249, 250, 252, 253, 254, 255, 258, 259, 260, 261, 262, 264, 272, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312}
    else -- أنثى
        array = {9, 10, 11, 12, 13, 31, 38, 39, 40, 41, 53, 54, 55, 56, 63, 64, 69, 75, 76, 77, 85, 86, 87, 88, 89, 90, 91, 92, 93, 129, 130, 131, 138, 139, 140, 141, 145, 148, 150, 151, 152, 157, 169, 172, 178, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 201, 205, 207, 211, 214, 215, 216, 218, 219, 224, 225, 226, 231, 232, 233, 237, 238, 243, 244, 245, 246, 251, 256, 257, 263, 298}
    end
    return array
end

function newCharacter_attemptCreateCharacter()
    local characterName = guiGetText(gui["txtCharName"]) or ""
    
    -- التحقق من الاسم
    if string.len(characterName) < 2 then
        showToastMessage("يجب إدخال اسم مناسب")
        return
    end
    
    -- استخدام دالة التحقق الأصلية مع ترجمة الأخطاء
    local nameCheckPassed, nameCheckError = checkValidCharacterName(characterName) -- غير characterName إلى characterName
    if not nameCheckPassed then
        local errorMessages = {
            ["يجب أن يكون الاسم بالصيغة: الاسم الأول ثم اللقب"] = "يجب أن يكون الاسم بالصيغة: الاسم الأول ثم اللقب",
            ["يوجد أحرف غير مسموحة في الاسم"] = "يوجد أحرف غير مسموحة في الاسم",
            ["اسم الشخصية طويل جداً"] = "اسم الشخصية طويل جداً",
            ["اسم الشخصية قصير جداً"] = "اسم الشخصية قصير جداً",
            ["غير مسموح باستخدام أسماء مشهورة"] = "غير مسموح باستخدام أسماء مشهورة",
            ["اسم الشخصية هذا مستخدم بالفعل :(!"] = "اسم الشخصية هذا مستخدم بالفعل"
        }
        showToastMessage(errorMessages[nameCheckError] or " - " .. tostring(nameCheckError))
        return
    end

    local skin = getElementModel(dummyPed)
    if not skin then
        showToastMessage("يجب اختيار مظهر للشخصية")
        return
    end

    -- الحصول على القيم
    local ageValue = math.floor((guiScrollBarGetScrollPosition(gui["scrAge"]) * 0.8) + 16)
    local heightValue = math.floor((guiScrollBarGetScrollPosition(gui["scrHeight"]) / 2) + 150)
    local weightValue = math.floor(guiScrollBarGetScrollPosition(gui["scrWeight"]) + 50)

    -- بيانات الموقع الآمنة
    local spawnLocation = {
        1168.6484375, 
        -1412.576171875, 
        13.497941017151,
        357.72854614258,
        0,
        0,
        "بداية اللعبة"
    }

    -- إخفاء الواجهة أولاً ثم إرسال البيانات
    removeEventHandler("onClientRender", root, renderCharacterPanel)
    showCursor(false)
    
    fadeCamera(false, 1)
    setTimer(function()
        triggerServerEvent("accounts:characters:new", getLocalPlayer(), characterName, "", 0, selectedGender, skin, heightValue, weightValue, ageValue, 1, 1, 1, spawnLocation)
    end, 1000, 1)
end

function newCharacter_cancel(hideSelection)
    removeEventHandler("onClientRender", root, renderCharacterPanel)
    removeEventHandler("onClientClick", root, handlePanelClick)
    removeEventHandler("onClientCursorMove", root, handleCursorMove)
    removeEventHandler("onClientCharacter", root, handleCharacterInput)
	removeEventHandler("onClientKey", root, handleKey)

	if backspaceTimer then
        killTimer(backspaceTimer)
        backspaceTimer = nil
    end
    backspacePressed = false
    
    -- إيقاف مؤشر الكتابة
    if cursorTimer then
        killTimer(cursorTimer)
    end
    
    -- تدمير عناصر GUI
    if gui["_root"] and isElement(gui["_root"]) then
        destroyElement(gui["_root"])
    end
    
    if isElement(fontTitle) then destroyElement(fontTitle) end
    if isElement(fontLabel) then destroyElement(fontLabel) end
    if isElement(fontField) then destroyElement(fontField) end
    if isElement(fontToast) then destroyElement(fontToast) end
    
    if toastTimer then
        killTimer(toastTimer)
    end
    
    guiSetInputEnabled(false)
    if isElement(dummyPed) then
        destroyElement(dummyPed)
    end
    showCursor(false)
    
    characterSystemLoaded = false
    
    if hideSelection ~= true then
        -- Characters_showSelection() -- إذا كان لديك دالة لعرض قائمة الشخصيات
    end
    clearChat()
end

function newCharacter_response(statusID, statusSubID)
    if (statusID == 1) then
        showToastMessage("حدث خطأ، حاول مرة أخرى أو تواصل مع الإدارة")
    elseif (statusID == 2) then
        if (statusSubID == 1) then
            showToastMessage("اسم الشخصية هذا مستخدم بالفعل")
        else
            showToastMessage("حدث خطأ في إنشاء الشخصية")
        end
    elseif (statusID == 3) then
        newCharacter_cancel(true)
        triggerServerEvent("accounts:characters:spawn", getLocalPlayer(), statusSubID, nil, nil, nil, nil, true)
        triggerServerEvent("updateCharacters", getLocalPlayer())
        return
    end
end
addEventHandler("accounts:characters:new", getRootElement(), newCharacter_response)

-- =====================================================================
-- الأكواد الجديدة لإطلاق الواجهة
-- =====================================================================

-- دالة لبدء واجهة إنشاء الشخصية
function startNewCharacter()
    if newCharacter_init() then
        outputChatBox("✅ واجهة إنشاء الشخصية تم تحميلها بنجاح!", 0, 255, 0)
    else
        outputChatBox("❌ فشل في تحميل واجهة إنشاء الشخصية!", 255, 0, 0)
    end
end


-- دالة للتحقق من تحميل الواجهة
function debugCharacterSystem()
    outputChatBox("=== تشخيص نظام الشخصية ===", 255, 255, 0)
    outputChatBox("الدوال المحددة: " .. tostring(type(newCharacter_init)), 255, 255, 255)
    outputChatBox("الدوال المضافة: " .. tostring(isEventHandlerAdded("onClientRender", root, renderCharacterPanel)), 255, 255, 255)
    outputChatBox("النظام محمل: " .. tostring(characterSystemLoaded), 255, 255, 255)
end

function isEventHandlerAdded(eventName, attachedTo, func)
    local events = getEventHandlers(eventName, attachedTo)
    for _, event in ipairs(events) do
        if event == func then
            return true
        end
    end
    return false
end

addCommandHandler("debugchar", debugCharacterSystem)