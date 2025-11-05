-- client.lua - واجهة تحميل موارد بارادايس - الإصدار المحسن
outputDebugString("[LOADSCREEN] Client loaded successfully!")
local screenWidth, screenHeight = guiGetScreenSize()

-- ⚡⚡⚡ المتغيرات الجديدة المعدلة ⚡⚡⚡
local PANEL_SCALE = 1.7  -- تكبير البانل شوية كمان
local PANEL_WIDTH = 150 * PANEL_SCALE  -- 255
local PANEL_HEIGHT = 80 * PANEL_SCALE  -- 136

-- ⚡ تعديلات البروجرس: اعرض بنص والطول يقل الربع
local PROGRESS_BAR_WIDTH = (60 * 1.5) * PANEL_SCALE  -- 153 (اعرض بنص 50%)
local PROGRESS_BAR_HEIGHT = (6 * 0.75) * PANEL_SCALE  -- 7.65 (الطول يقل الربع)

-- ⚡ تصغير اللوجو
local LOGO_SIZE = 40  -- مصغر من 50 إلى 40

-- الخطوط ثابتة
local FONT_SIZE = 12
local SMALL_FONT_SIZE = 10

-- تحميل الصور
local loadPanelImage = dxCreateTexture("load.png")
local lineImage = dxCreateTexture("line.png")
local logoImage = dxCreateTexture("logopr.png")
local startIcon = dxCreateTexture("start.png")
local stopIcon = dxCreateTexture("stop.png")
local backgroundImage = dxCreateTexture("background.png")

-- الصوت
local quranSound
local isSoundPlaying = true

-- animation ومتغيرات التحكم
local panelX = screenWidth + 100
local targetX = (screenWidth - PANEL_WIDTH) / 2
local currentProgress = 0
local animationProgress = 0
local isLoading = false
local currentElements = {}

-- خطوط
local font = dxCreateFont("Tajawal-Black.ttf", FONT_SIZE) or "default-bold"
local smallFont = dxCreateFont("Tajawal-Regular.ttf", SMALL_FONT_SIZE) or "default"

-- ألوان
local colors = {
    white = tocolor(255, 255, 255, 255),
    progress = tocolor(220, 20, 60, 255),
    text = tocolor(255, 255, 255, 255),
    progressBg = tocolor(100, 100, 100, 150)
}

function drawLoadingScreen()
    if not isLoading then return end
    
    -- رسم الخلفية
    if backgroundImage then
        dxDrawImage(0, 0, screenWidth, screenHeight, backgroundImage, 0, 0, 0, tocolor(255, 255, 255, 255))
    else
        dxDrawRectangle(0, 0, screenWidth, screenHeight, tocolor(20, 20, 20, 255))
    end
    
    -- حساب موضع البانل مع animation (البانل ثابت في مكانها)
    local currentPanelX = panelX
    if animationProgress < 1 then
        animationProgress = animationProgress + 0.03
        currentPanelX = interpolateBetween(
            screenWidth + 100, 0, 0,
            targetX, 0, 0,
            animationProgress, "OutBack"
        )
        panelX = currentPanelX
    end
    
    -- رسم البانل الرئيسي (متكبير)
    if loadPanelImage then
        dxDrawImage(currentPanelX, (screenHeight - PANEL_HEIGHT) / 2, PANEL_WIDTH, PANEL_HEIGHT, loadPanelImage, 0, 0, 0, tocolor(255, 255, 255, 255))
    else
        dxDrawRectangle(currentPanelX, (screenHeight - PANEL_HEIGHT) / 2, PANEL_WIDTH, PANEL_HEIGHT, tocolor(40, 40, 40, 230))
    end
    
    -- حساب الإحداثيات داخل البانل
    local panelCenterX = currentPanelX + (PANEL_WIDTH / 2)
    
    -- ⚡ رفع المحتوى لأعلى: اللوجو والبروجرس والنص
    local contentStartY = (screenHeight - PANEL_HEIGHT) / 2 + 25  -- رفع المحتوى 25 بدل 15
    
    -- رسم اللوجو (مصغر ومرتفع)
    if logoImage then
        dxDrawImage(panelCenterX - (LOGO_SIZE / 2), contentStartY, LOGO_SIZE, LOGO_SIZE, logoImage, 0, 0, 0, tocolor(255, 255, 255, 255))
    end
    
    -- شريط التقدم (مرتفع وبتعديلات العرض والطول)
    local progressBarY = contentStartY + LOGO_SIZE + 12  -- رفع البروجرس
    
    -- رسم خلفية شريط التقدم
    if lineImage then
        dxDrawImage(panelCenterX - (PROGRESS_BAR_WIDTH / 2), progressBarY, PROGRESS_BAR_WIDTH, PROGRESS_BAR_HEIGHT, lineImage, 0, 0, 0, tocolor(255, 255, 255, 255))
    else
        dxDrawRectangle(panelCenterX - (PROGRESS_BAR_WIDTH / 2), progressBarY, PROGRESS_BAR_WIDTH, PROGRESS_BAR_HEIGHT, colors.progressBg)
    end
    
    -- رسم شريط التقدم المتحرك
    local currentProgressWidth = PROGRESS_BAR_WIDTH * (currentProgress / 100)
    dxDrawRectangle(panelCenterX - (PROGRESS_BAR_WIDTH / 2), progressBarY, currentProgressWidth, PROGRESS_BAR_HEIGHT, colors.progress)
    
    -- ⚡⚡⚡ النسبة المئوية جنب البروجرس من الشمال (خارج البروجرس) ⚡⚡⚡
    local percentX = (panelCenterX - (PROGRESS_BAR_WIDTH / 2)) + PROGRESS_BAR_WIDTH + 8  -- بعد نهاية البروجرس بـ 8 بكسلات
    local percentY = progressBarY + (PROGRESS_BAR_HEIGHT / 2) - 10  -- في منتصف ارتفاع البروجرس
    
    dxDrawText(math.floor(currentProgress) .. "%", 
               percentX, percentY, percentX + 50, percentY + 20, 
               colors.progress, 0.9, font, "left", "top", false, true)
    
    -- ⚡ النص مرفوع فوق شوية
    local textY = progressBarY + PROGRESS_BAR_HEIGHT + 15  -- رفع النص
    
    dxDrawText("جارٍ تحميل موارد بارادايس", 
               currentPanelX, textY, currentPanelX + PANEL_WIDTH, textY + 20, 
               colors.text, 0.7, font, "center", "top", false, true)
    
    -- معلومات القرآن في أعلى الشاشة
    local quranText = "سورة ابراهيم - القارئ يوسف الصقير"
    local quranTextWidth = dxGetTextWidth(quranText, 0.8, smallFont)
    
    -- أيقونة التحكم في الصوت
    local soundIcon = isSoundPlaying and stopIcon or startIcon
    local iconSize = 20
    local iconX = 10 + quranTextWidth + 5
    local iconY = 10
    
    -- رسم النص
    dxDrawText(quranText, 10, 10, 10 + quranTextWidth, 30, colors.text, 0.8, smallFont, "left", "center")
    
    -- رسم أيقونة الصوت
    if soundIcon then
        dxDrawImage(iconX, iconY, iconSize, iconSize, soundIcon, 0, 0, 0, tocolor(255, 255, 255, 255))
    end
    
    -- حفظ إحداثيات أيقونة الصوت للنقر
    currentElements.soundButton = {
        x = iconX,
        y = iconY,
        width = iconSize,
        height = iconSize
    }
end

-- دالة للتحريك السلس
function interpolateBetween(x1, y1, z1, x2, y2, z2, progress, easingType)
    local easeOutBack = function(t)
        local c1 = 1.70158
        local c3 = c1 + 1
        return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)
    end
    
    if easingType == "OutBack" then
        progress = easeOutBack(progress)
    end
    
    local x = x1 + (x2 - x1) * progress
    local y = y1 + (y2 - y1) * progress
    local z = z1 + (z2 - z1) * progress
    
    return x, y, z
end

function updateLoadingProgress(progress)
    currentProgress = math.min(100, math.max(0, progress))
end

function toggleQuranSound()
    if isSoundPlaying then
        if isElement(quranSound) then
            stopSound(quranSound)
        end
        isSoundPlaying = false
    else
        quranSound = playSound("qur2an.mp3", true)
        setSoundVolume(quranSound, 0.7)
        isSoundPlaying = true
    end
end

function handleClick(button, state, x, y)
    if button ~= "left" or state ~= "up" then return end
    if not isLoading then return end
    
    if currentElements and currentElements.soundButton then
        local soundBtn = currentElements.soundButton
        if x >= soundBtn.x and x <= soundBtn.x + soundBtn.width and
           y >= soundBtn.y and y <= soundBtn.y + soundBtn.height then
            toggleQuranSound()
            return
        end
    end
end

function startLoadingScreen()
    outputDebugString("[LOADSCREEN] Starting loading screen...")
    isLoading = true
    currentProgress = 0
    animationProgress = 0
    panelX = screenWidth + 100
    
    addEventHandler("onClientRender", root, drawLoadingScreen)
    addEventHandler("onClientClick", root, handleClick)
    showCursor(true)
    
    if isSoundPlaying then
        quranSound = playSound("qur2an.mp3", true)
        if quranSound then
            setSoundVolume(quranSound, 0.7)
        end
    end
end

function finishLoadingScreen()
    isLoading = false
    removeEventHandler("onClientRender", root, drawLoadingScreen)
    removeEventHandler("onClientClick", root, handleClick)
    showCursor(false)
    
    if isElement(quranSound) then
        stopSound(quranSound)
    end
end

-- ==================== الأحداث ====================

addEvent("updateLoadingProgress", true)
addEventHandler("updateLoadingProgress", root, function(progress)
    updateLoadingProgress(progress)
end)

addEvent("startLoadingScreen", true)
addEventHandler("startLoadingScreen", root, function()
    startLoadingScreen()
end)

addEvent("finishLoadingScreen", true)
addEventHandler("finishLoadingScreen", root, function()
    finishLoadingScreen()
end)

-- أمر لفحص حالة الملفات والواجهة
addCommandHandler("debugload", function()
    outputChatBox("🔍 فحص واجهة التحميل:", 255, 255, 0)
    outputChatBox("• حجم البانل: " .. PANEL_SCALE .. "x", 255, 255, 0)
    outputChatBox("• أبعاد البانل: " .. PANEL_WIDTH .. "x" .. PANEL_HEIGHT, 255, 255, 0)
    outputChatBox("• حجم البروجرس: " .. PROGRESS_BAR_WIDTH .. "x" .. PROGRESS_BAR_HEIGHT, 255, 255, 0)
    outputChatBox("• حجم اللوجو: " .. LOGO_SIZE .. "x" .. LOGO_SIZE, 255, 255, 0)
    
    startLoadingScreen()
    setTimer(function() updateLoadingProgress(30) end, 500, 1)
    setTimer(function() updateLoadingProgress(60) end, 1000, 1)
    setTimer(function() updateLoadingProgress(90) end, 1500, 1)
    setTimer(function() updateLoadingProgress(100) end, 2000, 1)
    setTimer(function() finishLoadingScreen() end, 2500, 1)
end)

-- أمر لتغيير حجم البانل فقط
addCommandHandler("setpanelsize", function(_, scale)
    if scale and tonumber(scale) then
        local newScale = tonumber(scale)
        if newScale >= 0.5 and newScale <= 3 then
            PANEL_SCALE = newScale
            PANEL_WIDTH = 150 * PANEL_SCALE
            PANEL_HEIGHT = 80 * PANEL_SCALE
            PROGRESS_BAR_WIDTH = (60 * 1.5) * PANEL_SCALE
            PROGRESS_BAR_HEIGHT = (6 * 0.75) * PANEL_SCALE
            
            targetX = (screenWidth - PANEL_WIDTH) / 2
            
            outputChatBox("✅ حجم البانل والبروجرس: " .. PANEL_SCALE .. "x", 0, 255, 0)
            outputChatBox("أبعاد البانل: " .. PANEL_WIDTH .. "x" .. PANEL_HEIGHT, 255, 255, 0)
        else
            outputChatBox("❌ استخدم حجم بين 0.5 و 3", 255, 0, 0)
        end
    else
        outputChatBox("❌ استخدم: /setpanelsize [الحجم]", 255, 0, 0)
        outputChatBox("مثال: /setpanelsize 1.7", 255, 255, 0)
    end
end)

-- فحص الملفات عند بدء التشغيل
addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[LOADSCREEN] ✅ Client script loaded successfully!")
    outputDebugString("[LOADSCREEN] 📏 Panel scale: " .. PANEL_SCALE .. "x")
    outputDebugString("[LOADSCREEN] 📐 Panel size: " .. PANEL_WIDTH .. "x" .. PANEL_HEIGHT)
    outputDebugString("[LOADSCREEN] 🎯 Progress bar size: " .. PROGRESS_BAR_WIDTH .. "x" .. PROGRESS_BAR_HEIGHT)
    outputDebugString("[LOADSCREEN] 🔵 Logo size: " .. LOGO_SIZE .. "x" .. LOGO_SIZE)
end)