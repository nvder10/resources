local screenW, screenH = guiGetScreenSize()
local dxfont_bold = dxCreateFont("Tajawal-Bold.ttf", 12) or "default-bold"
local dxfont_black = dxCreateFont("Tajawal-Black.ttf", 14) or "default-bold"
local dxfont_small = dxCreateFont("Tajawal-Bold.ttf", 10) or "default"

-- ========== نظام اللود سكرين ==========
local resourceLoader = {
    isActive = true,
    progress = 0,
    currentResource = "",
    totalResources = 15,
    loadedResources = 0,
    startTime = getTickCount(),
    minDisplayTime = 4000,
    isMinTimePassed = false
}

local loadingMessages = {
    "جاري تحميل أنظمة اللعبة...",
    "تهيئة قواعد البيانات...", 
    "تحميل نماذج المركبات...",
    "إعداد أنظمة اللاعبين...",
    "تحميل الخرائط والمناطق...",
    "تهيئة أنظمة الأسلحة...",
    "تحميل الواجهات الرسومية...",
    "إعداد أنظمة الاتصال...",
    "تحميل الأصوات والموسيقى...",
    "تهيئة أنظمة الاقتصاد...",
    "تحميل أنظمة المنازل...",
    "إعداد أنظمة الوظائف...",
    "تحميل أنظمة الأمان...",
    "تهيئة أنصار اللعبة...",
    "الإعداد النهائي..."
}

function drawLoadingScreen()
    if not resourceLoader.isActive then return end
    
    -- الخلفية
    dxDrawImage(0, 0, screenW, screenH, "loadbg.png", 0, 0, 0, tocolor(255, 255, 255, 255))
    
    -- شريط التحميل الخلفي (315x9)
    local barWidth, barHeight = 315, 9
    local barX = (screenW - barWidth) / 2
    local barY = screenH * 0.85
    
    -- الشريط الخلفي (#031417)
    dxDrawRectangle(barX, barY, barWidth, barHeight, tocolor(3, 20, 23, 255))
    
    -- الشريط الأمامي المتحرك (تركوازي)
    local progressWidth = (barWidth * resourceLoader.progress) / 100
    dxDrawRectangle(barX, barY, progressWidth, barHeight, tocolor(52, 171, 173, 255))
    
    -- الحدود التركوازية للشريط
    dxDrawRectangle(barX, barY, barWidth, 1, tocolor(52, 171, 173, 255)) -- أعلى
    dxDrawRectangle(barX, barY + barHeight - 1, barWidth, 1, tocolor(52, 171, 173, 255)) -- أسفل
    dxDrawRectangle(barX, barY, 1, barHeight, tocolor(52, 171, 173, 255)) -- يسار
    dxDrawRectangle(barX + barWidth - 1, barY, 1, barHeight, tocolor(52, 171, 173, 255)) -- يمين
    
    -- النسبة المئوية
    dxDrawText(math.floor(resourceLoader.progress) .. "%", barX, barY - 30, barX + barWidth, barY, 
              tocolor(255, 255, 255, 255), 1.2, dxfont_bold, "center", "bottom")
    
    -- رسالة التحميل الحالية
    local messageIndex = math.floor((resourceLoader.progress / 100) * #loadingMessages) + 1
    if messageIndex > #loadingMessages then messageIndex = #loadingMessages end
    
    dxDrawText(loadingMessages[messageIndex], 0, barY - 60, screenW, barY, 
              tocolor(52, 171, 173, 255), 1, dxfont_bold, "center", "bottom")
    
    -- تذييل الصفحة
    dxDrawText("San Andreas Roleplay • نظام محاكاة الحياة الواقعية", 0, screenH - 30, screenW, screenH, 
              tocolor(200, 200, 200, 255), 0.8, dxfont_small, "center", "center")
end

-- ========== نظام اللوج سكرين ==========
local loginSystem = {
    isActive = false,
    username = "",
    password = "",
    rememberMe = false,
    currentPanel = "login" -- login, register, forgot
}

function drawLoginScreen()
    if not loginSystem.isActive then return end
    
    -- الخلفية
    dxDrawImage(0, 0, screenW, screenH, "login.png", 0, 0, 0, tocolor(255, 255, 255, 255))
    
    -- لوحة التسجيل/الدخول
    local panelWidth, panelHeight = 400, 450
    local panelX = (screenW - panelWidth) / 2
    local panelY = (screenH - panelHeight) / 2
    
    -- خلفية اللوحة
    dxDrawRectangle(panelX, panelY, panelWidth, panelHeight, tocolor(3, 20, 23, 220))
    dxDrawRectangle(panelX, panelY, panelWidth, 3, tocolor(52, 171, 173, 255)) -- الحد العلوي
    
    -- العنوان
    dxDrawText("تسجيل الدخول", panelX, panelY + 20, panelX + panelWidth, panelY + 60, 
              tocolor(255, 255, 255, 255), 1.3, dxfont_black, "center", "center")
    
    -- حقل اسم المستخدم
    dxDrawText("اسم المستخدم:", panelX + 30, panelY + 90, panelX + panelWidth, panelY + 120, 
              tocolor(200, 200, 200, 255), 1, dxfont_small, "left", "center")
    
    local usernameBoxY = panelY + 120
    dxDrawRectangle(panelX + 30, usernameBoxY, panelWidth - 60, 40, tocolor(10, 40, 45, 255))
    dxDrawRectangle(panelX + 30, usernameBoxY, panelWidth - 60, 2, tocolor(52, 171, 173, 255))
    dxDrawText(loginSystem.username, panelX + 40, usernameBoxY, panelX + panelWidth - 40, usernameBoxY + 40, 
              tocolor(255, 255, 255, 255), 1, dxfont_bold, "left", "center")
    
    -- حقل كلمة المرور
    dxDrawText("كلمة المرور:", panelX + 30, usernameBoxY + 60, panelX + panelWidth, usernameBoxY + 90, 
              tocolor(200, 200, 200, 255), 1, dxfont_small, "left", "center")
    
    local passwordBoxY = usernameBoxY + 90
    dxDrawRectangle(panelX + 30, passwordBoxY, panelWidth - 60, 40, tocolor(10, 40, 45, 255))
    dxDrawRectangle(panelX + 30, passwordBoxY, panelWidth - 60, 2, tocolor(52, 171, 173, 255))
    
    local passwordText = string.gsub(loginSystem.password, ".", "•")
    dxDrawText(passwordText, panelX + 40, passwordBoxY, panelX + panelWidth - 40, passwordBoxY + 40, 
              tocolor(255, 255, 255, 255), 1, dxfont_bold, "left", "center")
    
    -- خيار تذكرني
    local rememberY = passwordBoxY + 60
    local rememberBoxSize = 20
    dxDrawRectangle(panelX + 30, rememberY, rememberBoxSize, rememberBoxSize, 
                   loginSystem.rememberMe and tocolor(52, 171, 173, 255) or tocolor(10, 40, 45, 255))
    dxDrawRectangle(panelX + 30, rememberY, rememberBoxSize, rememberBoxSize, tocolor(52, 171, 173, 255), true)
    
    if loginSystem.rememberMe then
        dxDrawText("✓", panelX + 30, rememberY, panelX + 30 + rememberBoxSize, rememberY + rememberBoxSize, 
                  tocolor(255, 255, 255, 255), 1, dxfont_bold, "center", "center")
    end
    
    dxDrawText("تذكرني", panelX + 60, rememberY, panelX + panelWidth, rememberY + rememberBoxSize, 
              tocolor(200, 200, 200, 255), 1, dxfont_small, "left", "center")
    
    -- زر تسجيل الدخول
    local loginBtnY = rememberY + 40
    dxDrawRectangle(panelX + 30, loginBtnY, panelWidth - 60, 45, tocolor(52, 171, 173, 255))
    dxDrawText("تسجيل الدخول", panelX + 30, loginBtnY, panelX + panelWidth - 30, loginBtnY + 45, 
              tocolor(255, 255, 255, 255), 1.1, dxfont_bold, "center", "center")
    
    -- زر إنشاء حساب
    local registerBtnY = loginBtnY + 60
    dxDrawRectangle(panelX + 30, registerBtnY, panelWidth - 60, 45, tocolor(10, 40, 45, 255))
    dxDrawText("إنشاء حساب جديد", panelX + 30, registerBtnY, panelX + panelWidth - 30, registerBtnY + 45, 
              tocolor(52, 171, 173, 255), 1, dxfont_bold, "center", "center")
    
    -- رابط استعادة كلمة المرور
    local forgotY = registerBtnY + 70
    dxDrawText("نسيت كلمة المرور؟", panelX + 30, forgotY, panelX + panelWidth - 30, forgotY + 20, 
              tocolor(150, 150, 150, 255), 0.9, dxfont_small, "center", "center")
    
    -- رابط الديسكورد
    local discordY = forgotY + 25
    dxDrawText("https://discord.gg/JpzNJ95E", panelX + 30, discordY, panelX + panelWidth - 30, discordY + 20, 
              tocolor(52, 171, 173, 255), 0.9, dxfont_small, "center", "center")
end

-- ========== إدارة النظام ==========
function startLoadingSystem()
    resourceLoader.isActive = true
    addEventHandler("onClientRender", root, drawLoadingScreen)
    showCursor(false)
    
    -- محاكاة تحميل الموارد
    local loadInterval = 150 -- مللي ثانية بين كل مورد
    for i = 1, resourceLoader.totalResources do
        setTimer(function()
            resourceLoader.loadedResources = i
            resourceLoader.progress = (i / resourceLoader.totalResources) * 100
            
            if i == resourceLoader.totalResources then
                setTimer(function()
                    resourceLoader.isMinTimePassed = true
                    checkLoadingCompletion()
                end, 1000, 1)
            end
        end, i * loadInterval, 1)
    end
end

function checkLoadingCompletion()
    if resourceLoader.progress >= 100 and resourceLoader.isMinTimePassed then
        fadeCamera(false, 1.0)
        setTimer(function()
            resourceLoader.isActive = false
            removeEventHandler("onClientRender", root, drawLoadingScreen)
            startLoginSystem()
        end, 1000, 1)
    end
end

function startLoginSystem()
    loginSystem.isActive = true
    addEventHandler("onClientRender", root, drawLoginScreen)
    showCursor(true)
    fadeCamera(true, 1.0)
end

-- ========== معالجة الإدخال ==========
function handleLoginClick(button, state, absoluteX, absoluteY)
    if button ~= "left" or state ~= "down" then return end
    if not loginSystem.isActive then return end
    
    local panelWidth, panelHeight = 400, 450
    local panelX = (screenW - panelWidth) / 2
    local panelY = (screenH - panelHeight) / 2
    
    -- حقل اسم المستخدم
    if isMouseInPosition(panelX + 30, panelY + 120, panelWidth - 60, 40) then
        triggerServerEvent("onClientRequestInput", localPlayer, "username")
        return
    end
    
    -- حقل كلمة المرور
    if isMouseInPosition(panelX + 30, panelY + 210, panelWidth - 60, 40) then
        triggerServerEvent("onClientRequestInput", localPlayer, "password") 
        return
    end
    
    -- خيار تذكرني
    if isMouseInPosition(panelX + 30, panelY + 270, 20, 20) then
        loginSystem.rememberMe = not loginSystem.rememberMe
        return
    end
    
    -- زر تسجيل الدخول
    if isMouseInPosition(panelX + 30, panelY + 310, panelWidth - 60, 45) then
        if #loginSystem.username < 3 or #loginSystem.password < 3 then
            outputChatBox("يرجى إدخال اسم مستخدم وكلمة مرور صحيحة", 255, 0, 0)
            return
        end
        triggerServerEvent("onClientLoginAttempt", localPlayer, loginSystem.username, loginSystem.password, loginSystem.rememberMe)
        return
    end
    
    -- زر إنشاء حساب
    if isMouseInPosition(panelX + 30, panelY + 370, panelWidth - 60, 45) then
        triggerServerEvent("onClientRegisterRequest", localPlayer)
        return
    end
    
    -- رابط استعادة كلمة المرور
    if isMouseInPosition(panelX + 30, panelY + 440, panelWidth - 60, 20) then
        executeBrowserURL(getLocalPlayer(), "https://discord.gg/JpzNJ95E")
        return
    end
end

-- ========== الأحداث من السيرفر ==========
addEvent("onClientUpdateLoginField", true)
addEventHandler("onClientUpdateLoginField", root, function(field, value)
    if field == "username" then
        loginSystem.username = value
    elseif field == "password" then
        loginSystem.password = value
    end
end)

addEvent("onClientLoginSuccess", true)
addEventHandler("onClientLoginSuccess", root, function()
    loginSystem.isActive = false
    removeEventHandler("onClientRender", root, drawLoginScreen)
    showCursor(false)
    showChat(true)
end)

-- ========== بدء النظام ==========
addEventHandler("onClientResourceStart", resourceRoot, function()
    showChat(false)
    showCursor(false)
    fadeCamera(false, 0)
    startLoadingSystem()
    addEventHandler("onClientClick", root, handleLoginClick)
end)

-- ========== دوال مساعدة ==========
function isMouseInPosition(x, y, width, height)
    if not isCursorShowing() then return false end
    local cursorX, cursorY = getCursorPosition()
    cursorX, cursorY = cursorX * screenW, cursorY * screenH
    return cursorX >= x and cursorX <= x + width and cursorY >= y and cursorY <= y + height
end