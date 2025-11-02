-- client.lua (paradise_panel)
-- Paradise Panel - enhanced dx GUI with Tajawal fonts

local screenW, screenH = guiGetScreenSize()
local showPanel = false
local selectedTab = "الرئيسية"
local selectedSubTab = "معلومات"

-- الألوان الجديدة
local accentR, accentG, accentB = 53, 131, 240
local hoverR, hoverG, hoverB = 73, 151, 255
local darkR, darkG, darkB = 20, 20, 25
local contentR, contentG, contentB = 28, 28, 35

-- تحسين الأبعاد - تكبير البانل
local panelW, panelH = math.min(1000, screenW * 0.75), math.min(700, screenH * 0.8)
local panelX, panelY = (screenW - panelW) / 2, (screenH - panelH) / 2

-- تحميل الخطوط
local fontNormal = "default"
local fontBold = "default-bold"
local fontTajawalBold = false
local fontTajawalBlack = false

if fileExists("fonts/Tajawal-Bold.ttf") then
    fontTajawalBold = dxCreateFont("fonts/Tajawal-Bold.ttf", 10)
end

if fileExists("fonts/Tajawal-Black.ttf") then
    fontTajawalBlack = dxCreateFont("fonts/Tajawal-Black.ttf", 12)
end

-- استخدام الخطوط العربية إذا كانت متوفرة، وإلا استخدام الخطوط الافتراضية
fontNormal = fontTajawalBold or "default"
fontBold = fontTajawalBlack or "default-bold"

-- التبويبات الرئيسية المعدلة
local tabs = {
    "الرئيسية",
    "الممتلكات", 
    "المركبات",
    "السجلات",
    "معلومات",
    "الدعم الفني",
    "الإدارة",
    "الأصدقاء",
    "القواعد والإرشادات",
    "العضويات المميزة",
    "الخيارات",
    "الهدايا",
}

-- القوائم الفرعية المعدلة
local subTabs = {
    ["الرئيسية"] = {"معلومات", "إحصائيات", "الإنجازات"},
    ["الممتلكات"] = {"مركباتي", "بيوتي"},
    ["المركبات"] = {"إعدادات المركبات", "تشغيل الكل", "إيقاف الكل"},
    ["السجلات"] = {"المخالفات", "السجلات الإدارية", "سجل اللاعب"},
    ["معلومات"] = {"معلومات اللاعب", "إحصائيات اللعب", "التقارير"},
    ["الدعم الفني"] = {"إرسال شكوى", "الديسكورد"},
    ["الإدارة"] = {"الإدارة المتصلة", "إدارة السيرفر", "الإعلانات"},
    ["الأصدقاء"] = {"قائمة الأصدقاء", "طلبات الصداقة", "اللاعبون القريبون"},
    ["القواعد والإرشادات"] = {"القواعد العامة", "قواعد الرول بلاي", "الإرشادات"},
    ["العضويات المميزة"] = {"الباقات", "مزايا العضوية", "التفاصيل"},
    ["الخيارات"] = {"الإعدادات العامة", "الجرافيكس", "الأصوات"},
    ["الهدايا"] = {"الهدايا اليومية", "المكافآت"},
}

-- بيانات التصميم
local playerVehicles = {}
local playerHouses = {}
local supportSubject = ""
local supportMessage = ""
local hoveredElement = nil
local waterGraphicsEnabled = true
local vehicleTuningEnabled = true
local isTyping = false
local lastTypingTime = 0

-- قائمة الريسورسز للمركبات
local vehicleResources = {
    {name = "مركبات رياضية", enabled = true, description = "سيارات رياضية سريعة"},
    {name = "مركبات كلاسيكية", enabled = true, description = "سيارات قديمة كلاسيكية"},
    {name = "مركبات دفع رباعي", enabled = true, description = "سيارات دفع رباعي كبيرة"},
    {name = "مركبات دراجات", enabled = true, description = "دراجات نارية وسكوتر"},
    {name = "مركبات طائرات", enabled = true, description = "طائرات وهليكوبتر"},
    {name = "مركبات قوارب", enabled = true, description = "قوارب ويخوت"},
}

-- ربط المفتاح
bindKey("F1", "down", function()
    cancelEvent()
    showPanel = not showPanel
    showCursor(showPanel)
    if showPanel then
        refreshPlayerCache()
        selectedSubTab = subTabs[selectedTab][1] or "معلومات"
        triggerServerEvent("paradise:getPlayerVehicles", localPlayer)
        triggerServerEvent("paradise:getPlayerHouses", localPlayer)
        triggerServerEvent("paradise:getPlayerData", localPlayer)
    end
end)

-- الدوال المساعدة
local function isInBox(x,y, bx,by, bw,bh)
    return x >= bx and x <= bx+bw and y >= by and y <= by+bh
end

-- دالة رسم مستطيل دائري محسنة
local function dxDrawRoundedRectangle(x, y, width, height, color, radius, postGUI)
    radius = radius or 5
    dxDrawRectangle(x + radius, y, width - (radius * 2), height, color, postGUI)
    dxDrawRectangle(x, y + radius, radius, height - (radius * 2), color, postGUI)
    dxDrawRectangle(x + width - radius, y + radius, radius, height - (radius * 2), color, postGUI)
    
    dxDrawCircle(x + radius, y + radius, radius, 180, 270, color, color, 7, 1, postGUI)
    dxDrawCircle(x + width - radius, y + radius, radius, 270, 360, color, color, 7, 1, postGUI)
    dxDrawCircle(x + radius, y + height - radius, radius, 90, 180, color, color, 7, 1, postGUI)
    dxDrawCircle(x + width - radius, y + height - radius, radius, 0, 90, color, color, 7, 1, postGUI)
end

-- دالة رسم نص بظل محسنة
local function dxDrawTextWithShadow(text, x, y, x2, y2, color, scale, font, alignX, alignY, clip, wordBreak, postGUI)
    dxDrawText(text, x + 1, y + 1, x2 + 1, y2 + 1, tocolor(0, 0, 0, 150), scale, font, alignX, alignY, clip, wordBreak, postGUI)
    dxDrawText(text, x, y, x2, y2, color, scale, font, alignX, alignY, clip, wordBreak, postGUI)
end

-- دالة تنسيق المال
local function formatMoney(amount)
    amount = math.floor(amount or 0)
    return "$" .. tostring(amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- دالة إظهار التوست
local function showToast(message, r, g, b)
    triggerEvent("paradise:showToast", localPlayer, message, r or 53, g or 131, b or 240)
end

-- دالة الرسم الرئيسية المحسنة
local function drawPanel()
    -- خلفية شفافة محسنة
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(0, 0, 0, 160))

    -- البانل الرئيسي مع ظل
    dxDrawRoundedRectangle(panelX - 2, panelY - 2, panelW + 4, panelH + 4, tocolor(0, 0, 0, 120), 10)
    dxDrawRoundedRectangle(panelX, panelY, panelW, panelH, tocolor(darkR, darkG, darkB, 240), 8)

    -- الشريط الجانبي مع تدرج لوني
    dxDrawRectangle(panelX, panelY, 220, panelH, tocolor(15, 15, 20, 255))
    
    -- تأثير تدرج على الشريط الجانبي
    dxDrawRectangle(panelX, panelY, 220, 3, tocolor(accentR, accentG, accentB, 255))

    -- منطقة اللوجو والعنوان المحسنة
    local logoY = panelY + 20
    if fileExists("images/logo.png") then
        dxDrawImage(panelX + 20, logoY, 60, 60, "images/logo.png", 0, 0, 0, tocolor(255, 255, 255, 255))
    else
        dxDrawRoundedRectangle(panelX + 20, logoY, 60, 60, tocolor(accentR, accentG, accentB, 255), 8)
        dxDrawText("P", panelX + 20, logoY, panelX + 80, logoY + 60, tocolor(255, 255, 255, 255), 1.4, fontBold, "center", "center")
    end
    
    dxDrawTextWithShadow("PARADISE", panelX + 90, logoY + 10, panelX + 210, logoY + 30, tocolor(accentR, accentG, accentB, 255), 1.0, fontBold, "left", "center")
    dxDrawTextWithShadow("ROLEPLAY", panelX + 90, logoY + 35, panelX + 210, logoY + 55, tocolor(240, 240, 240, 200), 0.8, fontNormal, "left", "center")

    -- خط فاصل تحت العنوان
    dxDrawRectangle(panelX + 20, logoY + 65, 180, 2, tocolor(accentR, accentG, accentB, 100))

    -- قائمة التبويبات المحسنة
    local yStart = panelY + 90
    for i, name in ipairs(tabs) do
        local isSel = (selectedTab == name)
        local isHov = (hoveredElement == "tab_"..name)
        local tabY = yStart + (i-1) * 42
        
        if isSel then
            dxDrawRectangle(panelX + 15, tabY - 2, 190, 40, tocolor(accentR, accentG, accentB, 80))
            -- خط مميز تحت التبويب النشط
            dxDrawRectangle(panelX + 15, tabY + 36, 190, 2, tocolor(accentR, accentG, accentB, 200))
            dxDrawText("> "..name, panelX + 25, tabY, panelX + 195, tabY + 36, tocolor(255, 255, 255, 255), 0.9, fontBold, "left", "center")
        elseif isHov then
            dxDrawRectangle(panelX + 15, tabY - 2, 190, 40, tocolor(accentR, accentG, accentB, 40))
            dxDrawText(name, panelX + 25, tabY, panelX + 195, tabY + 36, tocolor(220, 220, 220, 255), 0.85, fontNormal, "left", "center")
        else
            dxDrawText(name, panelX + 25, tabY, panelX + 195, tabY + 36, tocolor(180, 180, 180, 200), 0.85, fontNormal, "left", "center")
        end
        
        -- خط فاصل أنيق بين التبويبات
        if i < #tabs then
            dxDrawRectangle(panelX + 20, tabY + 40, 180, 1, tocolor(50, 50, 50, 100))
        end
    end

    -- منطقة المحتوى المحسنة
    local contentX, contentY, contentW, contentH = panelX + 230, panelY + 20, panelW - 250, panelH - 40
    dxDrawRoundedRectangle(contentX, contentY, contentW, contentH, tocolor(contentR, contentG, contentB, 240), 8)
    
    -- تأثير تدرج أعلى منطقة المحتوى
    dxDrawRectangle(contentX, contentY, contentW, 3, tocolor(accentR, accentG, accentB, 255))

    -- القوائم الفرعية المحسنة
    if subTabs[selectedTab] then
        local subTabW = (contentW - 25) / #subTabs[selectedTab]
        for i, name in ipairs(subTabs[selectedTab]) do
            local tx = contentX + (i-1) * (subTabW + 5) + 15
            local ty = contentY + 15
            local isSel = (selectedSubTab == name)
            local isHov = (hoveredElement == "subtab_"..name)
            
            if isSel then
                dxDrawRoundedRectangle(tx, ty, subTabW, 35, tocolor(accentR, accentG, accentB, 200), 6)
                dxDrawText(name, tx, ty, tx + subTabW, ty + 35, tocolor(255, 255, 255, 255), 0.9, fontBold, "center", "center")
                -- خط تحت القائمة النشطة
                dxDrawRectangle(tx, ty + 33, subTabW, 2, tocolor(255, 255, 255, 150))
            elseif isHov then
                dxDrawRoundedRectangle(tx, ty, subTabW, 35, tocolor(accentR, accentG, accentB, 80), 6)
                dxDrawText(name, tx, ty, tx + subTabW, ty + 35, tocolor(220, 220, 220, 255), 0.9, fontNormal, "center", "center")
            else
                dxDrawRoundedRectangle(tx, ty, subTabW, 35, tocolor(30, 30, 40, 200), 6)
                dxDrawText(name, tx, ty, tx + subTabW, ty + 35, tocolor(180, 180, 180, 200), 0.9, fontNormal, "center", "center")
            end
        end
    end

    -- عنوان المحتوى المحسن
    dxDrawTextWithShadow(selectedTab, contentX, contentY + 60, contentX + contentW, contentY + 90, tocolor(accentR, accentG, accentB, 255), 1.3, fontBold, "center", "center")
    
    -- خط فاصل تحت العنوان
    dxDrawRectangle(contentX + 25, contentY + 92, contentW - 50, 1, tocolor(accentR, accentG, accentB, 80))

    -- رسم المحتوى حسب التبويب
    drawContent(contentX + 15, contentY + 100, contentW - 30, contentH - 120)

    -- زر الإغلاق المحسن
    local closeHov = (hoveredElement == "close_btn")
    dxDrawRoundedRectangle(panelX + panelW - 45, panelY + 15, 35, 35, closeHov and tocolor(220, 80, 80, 220) or tocolor(120, 120, 120, 180), 6)
    dxDrawText("X", panelX + panelW - 45, panelY + 15, panelX + panelW - 10, panelY + 50, tocolor(255, 255, 255, 255), 1.1, fontBold, "center", "center")
end

-- دالة رسم المحتوى الرئيسية
function drawContent(x, y, w, h)
    if selectedTab == "الرئيسية" then
        drawMainTab(x, y, w, h)
    elseif selectedTab == "الممتلكات" then
        drawPropertiesTab(x, y, w, h)
    elseif selectedTab == "المركبات" then
        drawVehiclesTab(x, y, w, h)
    elseif selectedTab == "السجلات" then
        drawRecordsTab(x, y, w, h)
    elseif selectedTab == "معلومات" then
        drawInfoTab(x, y, w, h)
    elseif selectedTab == "الدعم الفني" then
        drawSupportTab(x, y, w, h)
    elseif selectedTab == "الإدارة" then
        drawAdminTab(x, y, w, h)
    elseif selectedTab == "الأصدقاء" then
        drawFriendsTab(x, y, w, h)
    elseif selectedTab == "القواعد والإرشادات" then
        drawRulesTab(x, y, w, h)
    elseif selectedTab == "العضويات المميزة" then
        drawPremiumTab(x, y, w, h)
    elseif selectedTab == "الخيارات" then
        drawSettingsTab(x, y, w, h)
    elseif selectedTab == "الهدايا" then
        drawGiftsTab(x, y, w, h)
    end
end

-- تبويب الرئيسية
function drawMainTab(x, y, w, h)
    local name = getPlayerName(localPlayer)
    local money = getPlayerMoney(localPlayer) or 0
    local level = getElementData(localPlayer, "playerLevel") or 1
    local exp = getElementData(localPlayer, "playerExp") or 0
    local maxExp = getElementData(localPlayer, "playerMaxExp") or 1000
    
    if selectedSubTab == "معلومات" then
        -- بطاقة معلومات اللاعب المحسنة
        dxDrawRoundedRectangle(x, y, w, 100, tocolor(35, 35, 45, 220), 8)
        
        -- خط علوي مميز
        dxDrawRectangle(x, y, w, 3, tocolor(accentR, accentG, accentB, 255))
        
        dxDrawText("اسم اللاعب: "..name, x + 25, y + 20, 0, 0, tocolor(255, 255, 255, 255), 0.9, fontBold)
        dxDrawText("المال: "..formatMoney(money), x + 25, y + 45, 0, 0, tocolor(180, 255, 180, 255), 0.9, fontBold)
        dxDrawText("المستوى: "..level, x + 25, y + 70, 0, 0, tocolor(255, 255, 255, 200), 0.8, fontNormal)
        
        -- خط فاصل أنيق
        dxDrawRectangle(x + 15, y + 110, w - 30, 1, tocolor(60, 60, 70, 150))
        
        -- الإحصائيات
        dxDrawRoundedRectangle(x, y + 120, (w - 15)/2, 140, tocolor(35, 35, 45, 220), 8)
        dxDrawTextWithShadow("الإحصائيات", x + (w - 15)/4, y + 130, 0, 0, tocolor(accentR, accentG, accentB, 255), 0.9, fontBold, "center")
        
        -- خط تحت عنوان الإحصائيات
        dxDrawRectangle(x + 25, y + 160, (w - 15)/2 - 50, 1, tocolor(accentR, accentG, accentB, 80))
        
        local playTime = getElementData(localPlayer, "playTime") or 0
        local playTimeHours = math.floor(playTime / 60)
        local joinDate = getElementData(localPlayer, "joinDate") or "2024-01-01"
        local missions = getElementData(localPlayer, "completedMissions") or 0
        
        dxDrawText("وقت اللعب: "..playTimeHours.." ساعة", x + 25, y + 170, 0, 0, tocolor(200, 200, 200, 255), 0.75, fontNormal)
        dxDrawText("تاريخ التسجيل: "..joinDate, x + 25, y + 190, 0, 0, tocolor(200, 200, 200, 255), 0.75, fontNormal)
        dxDrawText("المهمات: "..missions, x + 25, y + 210, 0, 0, tocolor(200, 200, 200, 255), 0.75, fontNormal)
        dxDrawText("النقاط: "..formatMoney(exp), x + 25, y + 230, 0, 0, tocolor(200, 200, 200, 255), 0.75, fontNormal)
        
        -- الإنجازات
        dxDrawRoundedRectangle(x + (w - 15)/2 + 15, y + 120, (w - 15)/2, 140, tocolor(35, 35, 45, 220), 8)
        dxDrawTextWithShadow("الإنجازات", x + (w - 15)/2 + 15 + (w - 15)/4, y + 130, 0, 0, tocolor(accentR, accentG, accentB, 255), 0.9, fontBold, "center")
        
        -- خط تحت عنوان الإنجازات
        dxDrawRectangle(x + (w - 15)/2 + 35, y + 160, (w - 15)/2 - 70, 1, tocolor(accentR, accentG, accentB, 80))
        
        local achievements = getElementData(localPlayer, "achievements") or {}
        local achievementNames = {"المبتدئ", "المتسوق", "السائق", "الصياد"}
        
        for i, achName in ipairs(achievementNames) do
            local completed = achievements[achName] or false
            local achY = y + 170 + (i-1) * 20
            dxDrawText(achName .. " ("..(completed and "مكتمل" or "جاري")..")", x + (w - 15)/2 + 30, achY, 0, 0, completed and tocolor(180, 255, 180, 255) or tocolor(200, 200, 200, 255), 0.75, fontNormal)
        end
        
    elseif selectedSubTab == "إحصائيات" then
        dxDrawTextWithShadow("الإحصائيات التفصيلية", x + w/2, y + 20, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
        
        -- محتوى الإحصائيات
        local playTime = getElementData(localPlayer, "playTime") or 0
        local playTimeHours = math.floor(playTime / 60)
        local missions = getElementData(localPlayer, "completedMissions") or 0
        local friends = getElementData(localPlayer, "friendsCount") or 0
        local properties = getElementData(localPlayer, "totalProperties") or 0
        
        local stats = {
            {"المستوى:", level, "مستوى التقدم"},
            {"النقاط:", formatMoney(exp), "نقاط الخبرة"},
            {"المهمات المكتملة:", missions, "من أصل 20 مهمة"},
            {"الوقت الإجمالي:", playTimeHours.." ساعة", "وقت اللعب"},
            {"الأصدقاء:", friends, "صديق مضاف"},
            {"الممتلكات:", properties, "مركبات وبيوت"},
        }
        
        for i, stat in ipairs(stats) do
            local rowY = y + 50 + (i-1) * 45
            dxDrawRoundedRectangle(x + 20, rowY, w - 40, 35, tocolor(35, 35, 45, 180), 6)
            
            dxDrawText(stat[1], x + 35, rowY, 0, rowY + 35, tocolor(255, 255, 255, 255), 0.8, fontBold, "left", "center")
            dxDrawText(stat[2], x + w/2, rowY, 0, rowY + 35, tocolor(accentR, accentG, accentB, 255), 0.85, fontBold, "center", "center")
            dxDrawText(stat[3], x + w - 40, rowY, 0, rowY + 35, tocolor(180, 180, 180, 200), 0.7, fontNormal, "right", "center")
        end
        
    elseif selectedSubTab == "الإنجازات" then
        dxDrawTextWithShadow("الإنجازات والمستويات", x + w/2, y + 20, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
        
        -- قائمة الإنجازات
        local achievements = getElementData(localPlayer, "achievements") or {}
        local achievementList = {
            {name = "المبتدئ", desc = "اللعب لأول مرة", progress = 100, completed = achievements["المبتدئ"] or false},
            {name = "المتسوق", desc = "شراء 10 عناصر", progress = achievements["المتسوق"] and 100 or 70, completed = achievements["المتسوق"] or false},
            {name = "السائق", desc = "قيادة 100 كم", progress = achievements["السائق"] and 100 or 45, completed = achievements["السائق"] or false},
            {name = "الصياد", desc = "صيد 5 أسماك", progress = achievements["الصياد"] and 100 or 20, completed = achievements["الصياد"] or false},
            {name = "المليونير", desc = "جمع مليون دولار", progress = achievements["المليونير"] and 100 or 15, completed = achievements["المليونير"] or false},
        }
        
        for i, ach in ipairs(achievementList) do
            local achY = y + 50 + (i-1) * 65
            dxDrawRoundedRectangle(x + 20, achY, w - 40, 55, tocolor(35, 35, 45, 180), 6)
            
            -- شريط التقدم
            local progressWidth = (w - 100) * (ach.progress / 100)
            dxDrawRectangle(x + 30, achY + 35, w - 100, 12, tocolor(60, 60, 70, 200))
            dxDrawRectangle(x + 30, achY + 35, progressWidth, 12, ach.completed and tocolor(80, 200, 120, 220) or tocolor(accentR, accentG, accentB, 220))
            
            dxDrawText(ach.name, x + 30, achY + 10, 0, 0, tocolor(255, 255, 255, 255), 0.85, fontBold)
            dxDrawText(ach.desc, x + 30, achY + 30, 0, 0, tocolor(200, 200, 200, 200), 0.7, fontNormal)
            dxDrawText(ach.progress .. "%", x + w - 40, achY + 10, 0, 0, ach.completed and tocolor(80, 200, 120, 255) or tocolor(accentR, accentG, accentB, 255), 0.8, fontBold, "right")
            
            if ach.completed then
                dxDrawText("مكتمل", x + w - 40, achY + 30, 0, 0, tocolor(80, 200, 120, 255), 0.7, fontNormal, "right")
            end
        end
    end
end

-- تبويب الممتلكات
function drawPropertiesTab(x, y, w, h)
    if selectedSubTab == "مركباتي" then
        dxDrawTextWithShadow("المركبات المملوكة", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
        
        if #playerVehicles > 0 then
            for i, veh in ipairs(playerVehicles) do
                local vy = y + 40 + (i-1) * 75
                dxDrawRoundedRectangle(x, vy, w, 65, tocolor(35, 35, 45, 220), 8)
                
                -- خط علوي مميز
                dxDrawRectangle(x, vy, w, 2, tocolor(accentR, accentG, accentB, 150))
                
                dxDrawText(veh.name or "مركبة غير معروفة", x + 25, vy + 12, 0, 0, tocolor(255, 255, 255, 255), 0.85, fontBold)
                dxDrawText("لوحة: "..(veh.plate or "غير معروفة"), x + 25, vy + 32, 0, 0, tocolor(200, 200, 200, 200), 0.75, fontNormal)
                dxDrawText("الحالة: "..(veh.health or 100).."%", x + w - 120, vy + 22, 0, 0, tocolor(180, 255, 180, 255), 0.75, fontNormal)
                
                -- خط فاصل
                if i < #playerVehicles then
                    dxDrawRectangle(x + 20, vy + 64, w - 40, 1, tocolor(60, 60, 70, 150))
                end
            end
        else
            dxDrawText("لا تمتلك أي مركبات حالياً", x + w/2, y + 60, 0, 0, tocolor(200, 200, 200, 200), 0.9, fontNormal, "center")
            dxDrawText("يمكنك شراء مركبات من معارض السيارات", x + w/2, y + 85, 0, 0, tocolor(150, 150, 150, 200), 0.75, fontNormal, "center")
        end
        
    elseif selectedSubTab == "بيوتي" then
        dxDrawTextWithShadow("البيوت المملوكة", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
        
        if #playerHouses > 0 then
            for i, house in ipairs(playerHouses) do
                local hy = y + 40 + (i-1) * 85
                dxDrawRoundedRectangle(x, hy, w, 75, tocolor(35, 35, 45, 220), 8)
                
                -- خط علوي مميز
                dxDrawRectangle(x, hy, w, 2, tocolor(accentR, accentG, accentB, 150))
                
                dxDrawText(house.name or "منزل غير معروف", x + 25, hy + 15, 0, 0, tocolor(255, 255, 255, 255), 0.85, fontBold)
                dxDrawText("المكان: "..(house.location or "غير معروف"), x + 25, hy + 35, 0, 0, tocolor(200, 200, 200, 200), 0.75, fontNormal)
                dxDrawText("السعر: "..formatMoney(house.price or 0), x + 25, hy + 55, 0, 0, tocolor(180, 255, 180, 255), 0.8, fontNormal)
                
                -- خط فاصل
                if i < #playerHouses then
                    dxDrawRectangle(x + 20, hy + 74, w - 40, 1, tocolor(60, 60, 70, 150))
                end
            end
        else
            dxDrawText("لا تمتلك أي بيوت حالياً", x + w/2, y + 60, 0, 0, tocolor(200, 200, 200, 200), 0.9, fontNormal, "center")
            dxDrawText("يمكنك شراء بيوت من الوكالات العقارية", x + w/2, y + 85, 0, 0, tocolor(150, 150, 150, 200), 0.75, fontNormal, "center")
        end
    end
end

-- تبويب المركبات
function drawVehiclesTab(x, y, w, h)
    if selectedSubTab == "إعدادات المركبات" then
        dxDrawTextWithShadow("إعدادات مركبات السيرفر", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
        
        -- وصف الخانة
        dxDrawText("إدارة أنواع المركبات المتاحة في السيرفر", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        -- عرض قائمة الريسورسز
        for i, resource in ipairs(vehicleResources) do
            local vy = y + 55 + (i-1) * 65
            local isHov = (hoveredElement == "resource_"..i)
            
            dxDrawRoundedRectangle(x, vy, w, 55, tocolor(35, 35, 45, 220), 8)
            
            -- خط علوي مميز
            dxDrawRectangle(x, vy, w, 2, tocolor(accentR, accentG, accentB, 150))
            
            -- اسم الريسورس
            dxDrawText(resource.name, x + 25, vy + 10, 0, 0, tocolor(255, 255, 255, 255), 0.85, fontBold)
            dxDrawText(resource.description, x + 25, vy + 30, 0, 0, tocolor(180, 180, 180, 200), 0.7, fontNormal)
            
            -- زر التفعيل/التعطيل
            local btnX, btnY, btnW, btnH = x + w - 120, vy + 15, 90, 25
            local btnColor = resource.enabled and (isHov and tocolor(hoverR,hoverG,hoverB,200) or tocolor(accentR,accentG,accentB,180)) or (isHov and tocolor(120,120,120,200) or tocolor(100,100,100,150))
            
            dxDrawRoundedRectangle(btnX, btnY, btnW, btnH, btnColor, 4)
            dxDrawText(resource.enabled and "مفعل" or "معطل", btnX, btnY, btnX + btnW, btnY + btnH, tocolor(255,255,255,255), 0.75, fontBold, "center", "center")
            
            -- خط فاصل
            if i < #vehicleResources then
                dxDrawRectangle(x + 20, vy + 54, w - 40, 1, tocolor(60, 60, 70, 150))
            end
        end
        
    elseif selectedSubTab == "تشغيل الكل" then
        dxDrawTextWithShadow("تشغيل جميع مركبات السيرفر", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
        
        -- وصف الخانة
        dxDrawText("تفعيل جميع أنواع المركبات في السيرفر مرة واحدة", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        -- زر تشغيل الكل
        local enableAllHov = (hoveredElement == "enable_all")
        dxDrawRoundedRectangle(x + w/2 - 80, y + 80, 160, 40, enableAllHov and tocolor(hoverR,hoverG,hoverB,200) or tocolor(accentR,accentG,accentB,180), 8)
        dxDrawText("تشغيل جميع المركبات", x + w/2 - 80, y + 80, x + w/2 + 80, y + 120, tocolor(255,255,255,255), 0.85, fontBold, "center", "center")
        
        dxDrawText("سيتم تفعيل جميع أنواع المركبات في السيرفر", x + w/2, y + 150, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        dxDrawText("هذا قد يؤثر على أداء السيرفر", x + w/2, y + 170, 0, 0, tocolor(255, 200, 100, 255), 0.8, fontNormal, "center")
        
        -- قائمة المركبات التي سيتم تفعيلها
        dxDrawText("المركبات التي سيتم تفعيلها:", x + 25, y + 200, 0, 0, tocolor(255, 255, 255, 255), 0.85, fontBold)
        for i, resource in ipairs(vehicleResources) do
            dxDrawText("• " .. resource.name, x + 40, y + 225 + (i-1)*20, 0, 0, tocolor(200, 200, 200, 200), 0.75, fontNormal)
        end
        
    elseif selectedSubTab == "إيقاف الكل" then
        dxDrawTextWithShadow("إيقاف جميع مركبات السيرفر", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
        
        -- وصف الخانة
        dxDrawText("تعطيل جميع أنواع المركبات في السيرفر مرة واحدة", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        -- زر إيقاف الكل
        local disableAllHov = (hoveredElement == "disable_all")
        dxDrawRoundedRectangle(x + w/2 - 80, y + 80, 160, 40, disableAllHov and tocolor(200,60,60,200) or tocolor(150,50,50,180), 8)
        dxDrawText("إيقاف جميع المركبات", x + w/2 - 80, y + 80, x + w/2 + 80, y + 120, tocolor(255,255,255,255), 0.85, fontBold, "center", "center")
        
        dxDrawText("سيتم تعطيل جميع أنواع المركبات في السيرفر", x + w/2, y + 150, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        dxDrawText("سيؤدي هذا إلى تحسين أداء السيرفر", x + w/2, y + 170, 0, 0, tocolor(180, 255, 180, 255), 0.8, fontNormal, "center")
        
        -- قائمة المركبات التي سيتم تعطيلها
        dxDrawText("المركبات التي سيتم تعطيلها:", x + 25, y + 200, 0, 0, tocolor(255, 255, 255, 255), 0.85, fontBold)
        for i, resource in ipairs(vehicleResources) do
            dxDrawText("• " .. resource.name, x + 40, y + 225 + (i-1)*20, 0, 0, tocolor(200, 200, 200, 200), 0.75, fontNormal)
        end
    end
end

-- تبويب الدعم الفني
function drawSupportTab(x, y, w, h)
    if selectedSubTab == "إرسال شكوى" then
        dxDrawTextWithShadow("إرسال شكوى للإدارة", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
        
        -- وصف الخانة
        dxDrawText("أرسل شكوى أو استفسار للإدارة المتصلة حالياً", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        -- حقل عنوان الشكوى
        dxDrawText("عنوان الشكوى:", x + 25, y + 60, 0, 0, tocolor(255, 255, 255, 255), 0.85, fontBold)
        local subjectHov = (hoveredElement == "support_subject")
        dxDrawRoundedRectangle(x + 120, y + 58, w - 145, 35, subjectHov and tocolor(45, 45, 55, 220) or tocolor(35, 35, 45, 220), 6)
        dxDrawText(supportSubject ~= "" and supportSubject or "اكتب عنوان الشكوى هنا...", x + 130, y + 68, x + w - 20, y + 88, supportSubject ~= "" and tocolor(255, 255, 255, 255) or tocolor(150, 150, 150, 200), 0.8, fontNormal, "left", "center")
        
        -- حقل نص الشكوى
        dxDrawText("نص الشكوى:", x + 25, y + 110, 0, 0, tocolor(255, 255, 255, 255), 0.85, fontBold)
        local messageHov = (hoveredElement == "support_message")
        dxDrawRoundedRectangle(x + 25, y + 135, w - 50, 120, messageHov and tocolor(45, 45, 55, 220) or tocolor(35, 35, 45, 220), 6)
        
        -- إظهار مؤشر الكتابة إذا كان المستخدم يكتب
        if isTyping and hoveredElement == "support_message" and getTickCount() - lastTypingTime < 500 then
            local typingText = supportMessage .. "|"
            dxDrawText(typingText ~= "" and typingText or "اكتب تفاصيل الشكوى هنا...", x + 35, y + 145, x + w - 35, y + 245, supportMessage ~= "" and tocolor(255, 255, 255, 255) or tocolor(150, 150, 150, 200), 0.8, fontNormal, "left", "top", true, true)
        else
            dxDrawText(supportMessage ~= "" and supportMessage or "اكتب تفاصيل الشكوى هنا...", x + 35, y + 145, x + w - 35, y + 245, supportMessage ~= "" and tocolor(255, 255, 255, 255) or tocolor(150, 150, 150, 200), 0.8, fontNormal, "left", "top", true, true)
        end
        
        -- عداد الأحرف
        local charCount = string.len(supportMessage or "")
        dxDrawText(charCount .. "/500", x + w - 40, y + 250, 0, 0, charCount < 450 and tocolor(200, 200, 200, 200) or tocolor(255, 100, 100, 255), 0.7, fontNormal, "right")
        
        -- زر إرسال الشكوى
        local sendHov = (hoveredElement == "send_support")
        local canSend = supportSubject ~= "" and supportMessage ~= "" and string.len(supportMessage) <= 500
        dxDrawRoundedRectangle(x + w/2 - 70, y + 270, 140, 40, sendHov and (canSend and tocolor(hoverR,hoverG,hoverB,200) or tocolor(100,100,100,150)) or (canSend and tocolor(accentR,accentG,accentB,180) or tocolor(80,80,80,120)), 8)
        dxDrawText("إرسال", x + w/2 - 70, y + 270, x + w/2 + 70, y + 310, canSend and tocolor(255,255,255,255) or tocolor(150,150,150,200), 0.85, fontBold, "center", "center")
        
        -- ملاحظات
        dxDrawText("• سيتم إرسال الشكوى للإدارة المتصلة فقط", x + 25, y + 325, 0, 0, tocolor(200, 200, 200, 200), 0.7, fontNormal)
        dxDrawText("• يمكنك إرسال شكوى كل 30 ثانية", x + 25, y + 345, 0, 0, tocolor(200, 200, 200, 200), 0.7, fontNormal)
        dxDrawText("• الرد سيأتي عبر الشات أو النظام", x + 25, y + 365, 0, 0, tocolor(200, 200, 200, 200), 0.7, fontNormal)
        
    elseif selectedSubTab == "الديسكورد" then
        dxDrawTextWithShadow("سيرفر الديسكورد", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
        
        -- وصف الخانة
        dxDrawText("انضم إلى مجتمعنا على الديسكورد للدعم والمشاركة", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        -- رابط الديسكورد
        dxDrawRoundedRectangle(x + 50, y + 60, w - 100, 80, tocolor(35, 35, 45, 220), 8)
        dxDrawText("https://discord.gg/paradiserp", x + w/2, y + 85, 0, 0, tocolor(accentR, accentG, accentB, 255), 1.0, fontBold, "center", "center")
        dxDrawText("رابط سيرفر الديسكورد الرسمي", x + w/2, y + 110, 0, 0, tocolor(180, 180, 180, 200), 0.75, fontNormal, "center", "center")
        
        -- زر نسخ الرابط
        local copyHov = (hoveredElement == "copy_discord")
        dxDrawRoundedRectangle(x + w/2 - 70, y + 130, 140, 40, copyHov and tocolor(hoverR,hoverG,hoverB,200) or tocolor(accentR,accentG,accentB,180), 6)
        dxDrawText("نسخ الرابط", x + w/2 - 70, y + 130, x + w/2 + 70, y + 170, tocolor(255,255,255,255), 0.85, fontBold, "center", "center")
        
        -- معلومات الديسكورد
        dxDrawText("انضم إلى سيرفر الديسكورد للحصول على:", x + w/2, y + 190, 0, 0, tocolor(255, 255, 255, 255), 0.85, fontBold, "center")
        
        local benefits = {
            "• دعم فني مباشر ومستمر",
            "• آخر الأخبار والتحديثات أولاً بأول",
            "• التواصل مع اللاعبين والإدارة",
            "• المسابقات والعروض الحصرية",
            "• الإعلان عن الأحداث الجديدة",
            "• مناقشة القضايا والمقترحات"
        }
        
        for i, benefit in ipairs(benefits) do
            local by = y + 215 + (i-1) * 25
            dxDrawText(benefit, x + w/2, by, 0, 0, tocolor(200, 200, 200, 255), 0.75, fontNormal, "center")
        end
    end
end

-- تبويب السجلات
function drawRecordsTab(x, y, w, h)
    dxDrawTextWithShadow("السجلات", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
    
    if selectedSubTab == "المخالفات" then
        dxDrawText("سجل المخالفات والجزاءات", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        dxDrawText("لا توجد مخالفات مسجلة", x + w/2, y + 80, 0, 0, tocolor(150, 150, 150, 200), 0.9, fontNormal, "center")
        
    elseif selectedSubTab == "السجلات الإدارية" then
        dxDrawText("السجلات الإدارية والتحذيرات", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        dxDrawText("لا توجد سجلات إدارية", x + w/2, y + 80, 0, 0, tocolor(150, 150, 150, 200), 0.9, fontNormal, "center")
        
    elseif selectedSubTab == "سجل اللاعب" then
        dxDrawText("سجل الأنشطة والإنجازات", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        local activities = getElementData(localPlayer, "playerActivities") or {
            {"انضم إلى السيرفر", "2024-01-01 14:30"},
            {"أكمل المهمة الأولى", "2024-01-01 15:45"},
            {"اشترى أول مركبة", "2024-01-02 10:20"},
            {"وصل للمستوى 5", "2024-01-03 16:15"},
        }
        
        for i, activity in ipairs(activities) do
            local ay = y + 60 + (i-1) * 40
            dxDrawRoundedRectangle(x + 20, ay, w - 40, 30, tocolor(35, 35, 45, 180), 6)
            dxDrawText(activity[1], x + 35, ay, 0, ay + 30, tocolor(255, 255, 255, 255), 0.75, fontNormal, "left", "center")
            dxDrawText(activity[2], x + w - 35, ay, 0, ay + 30, tocolor(180, 180, 180, 200), 0.7, fontNormal, "right", "center")
        end
    end
end

-- تبويب المعلومات
function drawInfoTab(x, y, w, h)
    dxDrawTextWithShadow("معلومات عامة عن اللاعب", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
    
    if selectedSubTab == "معلومات اللاعب" then
        local name = getPlayerName(localPlayer)
        local money = getPlayerMoney(localPlayer) or 0
        local level = getElementData(localPlayer, "playerLevel") or 1
        local exp = getElementData(localPlayer, "playerExp") or 0
        local maxExp = getElementData(localPlayer, "playerMaxExp") or 1000
        local premium = getElementData(localPlayer, "premiumType") or "عادي"
        local joinDate = getElementData(localPlayer, "joinDate") or "2024-01-01"
        
        dxDrawText("المعلومات الأساسية", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        local infoItems = {
            {"اسم اللاعب:", name},
            {"المال:", formatMoney(money)},
            {"المستوى:", tostring(level)},
            {"الخبرة:", formatMoney(exp) .. " / " .. formatMoney(maxExp)},
            {"العضوية:", premium},
            {"آخر دخول:", joinDate},
        }
        
        for i, item in ipairs(infoItems) do
            local iy = y + 60 + (i-1) * 35
            dxDrawRoundedRectangle(x + 20, iy, w - 40, 25, tocolor(35, 35, 45, 180), 6)
            dxDrawText(item[1], x + 35, iy, 0, iy + 25, tocolor(255, 255, 255, 255), 0.75, fontBold, "left", "center")
            dxDrawText(item[2], x + w - 35, iy, 0, iy + 25, tocolor(accentR, accentG, accentB, 255), 0.75, fontNormal, "right", "center")
        end
        
    elseif selectedSubTab == "إحصائيات اللعب" then
        dxDrawText("إحصائيات الأداء واللعب", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        local playTime = getElementData(localPlayer, "playTime") or 0
        local playTimeHours = math.floor(playTime / 60)
        local missions = getElementData(localPlayer, "completedMissions") or 0
        local vehicles = #playerVehicles
        local houses = #playerHouses
        local friends = getElementData(localPlayer, "friendsCount") or 0
        local distance = getElementData(localPlayer, "distanceTraveled") or 0
        
        local stats = {
            {"وقت اللعب الإجمالي:", playTimeHours .. " ساعة"},
            {"المهمات المكتملة:", missions .. " من 20"},
            {"المركبات المملوكة:", tostring(vehicles)},
            {"البيوت المملوكة:", tostring(houses)},
            {"المسافة المقطوعة:", string.format("%.1f كم", distance)},
            {"الأصدقاء المضافين:", tostring(friends)},
        }
        
        for i, stat in ipairs(stats) do
            local sy = y + 60 + (i-1) * 35
            dxDrawRoundedRectangle(x + 20, sy, w - 40, 25, tocolor(35, 35, 45, 180), 6)
            dxDrawText(stat[1], x + 35, sy, 0, sy + 25, tocolor(255, 255, 255, 255), 0.75, fontBold, "left", "center")
            dxDrawText(stat[2], x + w - 35, sy, 0, sy + 25, tocolor(180, 255, 180, 255), 0.75, fontNormal, "right", "center")
        end
        
    elseif selectedSubTab == "التقارير" then
        dxDrawText("تقارير الأداء والتقييم", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        dxDrawText("لا توجد تقارير متاحة حالياً", x + w/2, y + 80, 0, 0, tocolor(150, 150, 150, 200), 0.9, fontNormal, "center")
    end
end

-- تبويب الإدارة
function drawAdminTab(x, y, w, h)
    dxDrawTextWithShadow("الإدارة المتصلة", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
    
    if selectedSubTab == "الإدارة المتصلة" then
        dxDrawText("قائمة الإداريين المتصلين حالياً", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        local admins = {}
        for _, p in ipairs(getElementsByType("player")) do
            if getElementData(p, "isAdmin") then
                table.insert(admins, getPlayerName(p))
            end
        end
        
        if #admins > 0 then
            for i, adminName in ipairs(admins) do
                local ay = y + 60 + (i-1) * 60
                dxDrawRoundedRectangle(x, ay, w, 50, tocolor(35, 35, 45, 220), 8)
                
                -- خط علوي مميز
                dxDrawRectangle(x, ay, w, 2, tocolor(accentR, accentG, accentB, 150))
                
                dxDrawText(adminName, x + 25, ay + 15, 0, 0, tocolor(255, 255, 255, 255), 0.85, fontBold)
                dxDrawText("إداري متصل", x + w - 80, ay + 15, 0, 0, tocolor(180, 255, 180, 255), 0.8, fontNormal)
                dxDrawText("حالة: نشط", x + 25, ay + 35, 0, 0, tocolor(200, 200, 200, 200), 0.7, fontNormal)
                
                -- خط فاصل
                if i < #admins then
                    dxDrawRectangle(x + 20, ay + 49, w - 40, 1, tocolor(60, 60, 70, 150))
                end
            end
        else
            dxDrawText("لا يوجد إداريون متصلون حالياً", x + w/2, y + 80, 0, 0, tocolor(200, 200, 200, 200), 0.9, fontNormal, "center")
            dxDrawText("يمكنك التواصل عبر نظام الشكاوى", x + w/2, y + 105, 0, 0, tocolor(150, 150, 150, 200), 0.75, fontNormal, "center")
        end
        
    elseif selectedSubTab == "إدارة السيرفر" then
        dxDrawText("إحصائيات وإدارة السيرفر", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        local serverStats = {
            {"اللاعبون المتصلون:", #getElementsByType("player") .. "/100"},
            {"أداء السيرفر:", "جيد"},
            {"وقت التشغيل:", "45 يوم"},
            {"الإصدار:", "1.0.0"},
        }
        
        for i, stat in ipairs(serverStats) do
            local sy = y + 60 + (i-1) * 40
            dxDrawRoundedRectangle(x + 20, sy, w - 40, 30, tocolor(35, 35, 45, 180), 6)
            dxDrawText(stat[1], x + 35, sy, 0, sy + 30, tocolor(255, 255, 255, 255), 0.75, fontBold, "left", "center")
            dxDrawText(stat[2], x + w - 35, sy, 0, sy + 30, tocolor(accentR, accentG, accentB, 255), 0.75, fontNormal, "right", "center")
        end
        
    elseif selectedSubTab == "الإعلانات" then
        dxDrawText("نظام الإعلانات والإشعارات", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        dxDrawText("هذه الخانة للإداريين فقط", x + w/2, y + 80, 0, 0, tocolor(150, 150, 150, 200), 0.9, fontNormal, "center")
    end
end

-- تبويب الأصدقاء
function drawFriendsTab(x, y, w, h)
    dxDrawTextWithShadow("نظام الأصدقاء", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
    
    if selectedSubTab == "قائمة الأصدقاء" then
        dxDrawText("قائمة أصدقائك المضافين", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        dxDrawText("لا يوجد أصدقاء مضافين حالياً", x + w/2, y + 80, 0, 0, tocolor(150, 150, 150, 200), 0.9, fontNormal, "center")
        
    elseif selectedSubTab == "طلبات الصداقة" then
        dxDrawText("طلبات الصداقة الواردة", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        dxDrawText("لا توجد طلبات صداقة جديدة", x + w/2, y + 80, 0, 0, tocolor(150, 150, 150, 200), 0.9, fontNormal, "center")
        
    elseif selectedSubTab == "اللاعبون القريبون" then
        dxDrawText("اللاعبون المتواجدون بالقرب منك", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        local nearbyPlayers = {}
        for _, p in ipairs(getElementsByType("player")) do
            if p ~= localPlayer then
                table.insert(nearbyPlayers, getPlayerName(p))
            end
        end
        
        if #nearbyPlayers > 0 then
            for i, playerName in ipairs(nearbyPlayers) do
                local py = y + 60 + (i-1) * 45
                dxDrawRoundedRectangle(x + 20, py, w - 40, 35, tocolor(35, 35, 45, 180), 6)
                dxDrawText(playerName, x + 35, py, 0, py + 35, tocolor(255, 255, 255, 255), 0.8, fontNormal, "left", "center")
                
                -- زر إضافة صديق
                local addHov = (hoveredElement == "add_friend_"..i)
                dxDrawRoundedRectangle(x + w - 100, py + 7, 70, 21, addHov and tocolor(hoverR,hoverG,hoverB,200) or tocolor(accentR,accentG,accentB,180), 4)
                dxDrawText("إضافة", x + w - 100, py + 7, x + w - 30, py + 28, tocolor(255,255,255,255), 0.7, fontBold, "center", "center")
            end
        else
            dxDrawText("لا يوجد لاعبون قريبون منك", x + w/2, y + 80, 0, 0, tocolor(150, 150, 150, 200), 0.9, fontNormal, "center")
        end
    end
end

-- تبويب القواعد والإرشادات
function drawRulesTab(x, y, w, h)
    if selectedSubTab == "القواعد العامة" then
        dxDrawTextWithShadow("القواعد العامة", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
        
        -- وصف الخانة
        dxDrawText("القواعد الأساسية التي يجب الالتزام بها في السيرفر", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        -- محتوى القواعد العامة
        local rules = {
            "• احترام جميع اللاعبين والإدارة بدون استثناء",
            "• ممنوع استخدام الشتايم أو الإهانات بأي شكل",
            "• الالتزام التام بقوانين السيرفر المعلنة",
            "• ممنوع استخدام الأكواد أو برامج الغش نهائياً",
            "• الحفاظ على جو اللعب المناسب للجميع",
            "• الالتزام بقواعد الرول بلاي بشكل كامل",
            "• احترام أوامر الإدارة وتنفيذها فوراً",
            "• الإبلاغ عن أي مخالفات عبر نظام الشكاوى",
            "• المحافظة على البيئة الافتراضية من التخريب",
            "• عدم استغلال الأخطاء أو الثغرات في السيرفر"
        }
        
        for i, rule in ipairs(rules) do
            local ry = y + 60 + (i-1) * 28
            dxDrawText("• " .. rule, x + 30, ry, 0, 0, tocolor(200, 200, 200, 255), 0.75, fontNormal)
        end
        
    elseif selectedSubTab == "قواعد الرول بلاي" then
        dxDrawTextWithShadow("قواعد الرول بلاي", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
        
        -- وصف الخانة
        dxDrawText("قواعد اللعب الواقعي والتفاعل بالشخصيات", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        -- محتوى قواعد الرول بلاي
        local rpRules = {
            "• الالتزام الكامل بالشخصية المختارة ودورها",
            "• التفاعل الواقعي والمنطقي مع جميع المواقف",
            "• ممنوع كسر الإيميرجن (الواقع الافتراضي)",
            "• احترام التسلسل الزمني والمنطقي للأحداث",
            "• التفاعل المنطقي مع البيئة والمحيط",
            "• الالتزام بقوانين اللعب النظيف والشريف",
            "• عدم الخروج عن دور الشخصية المسندة",
            "• التفاعل الطبيعي مع الكوارث والحوادث",
            "• احترام التسلسل الهرمي في الوظائف",
            "• الالتزام بقوانين المرور والقيادة"
        }
        
        for i, rule in ipairs(rpRules) do
            local ry = y + 60 + (i-1) * 28
            dxDrawText("• " .. rule, x + 30, ry, 0, 0, tocolor(200, 200, 200, 255), 0.75, fontNormal)
        end
        
    elseif selectedSubTab == "الإرشادات" then
        dxDrawTextWithShadow("الإرشادات", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
        
        -- وصف الخانة
        dxDrawText("نصائح وإرشادات لتحسين تجربة اللعب", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        -- محتوى الإرشادات
        local tips = {
            "• اقرأ القواعد بعناية قبل البدء في اللعب",
            "• استخدم الدعم الفني للمساعدة في المشاكل",
            "• تواصل مع الإدارة بلطف عند الحاجة للمساعدة",
            "• احترم تجربة اللاعبين الآخرين واستمتع",
            "• طور من شخصيتك وقصتك باستمرار",
            "• تعاون مع اللاعبين الآخرين في المهمات",
            "• استكشف العالم واكتشف أماكن جديدة",
            "• احتفظ بروح رياضية في المنافسات",
            "• استخدم النظام الاقتصادي بحكمة",
            "• استمتع وابني ذكريات جميلة في السيرفر"
        }
        
        for i, tip in ipairs(tips) do
            local ty = y + 60 + (i-1) * 28
            dxDrawText("• " .. tip, x + 30, ty, 0, 0, tocolor(200, 200, 200, 255), 0.75, fontNormal)
        end
    end
end

-- تبويب العضويات
function drawPremiumTab(x, y, w, h)
    dxDrawTextWithShadow("العضويات المميزة", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
    
    if selectedSubTab == "الباقات" then
        dxDrawText("اختر الباقة المناسبة لك", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        local premiumOptions = {
            { name = "برونز", perks = "مزايا أساسية", price = "$5", color = tocolor(53, 131, 240, 180) },
            { name = "سيلفر", perks = "مزايا متوسطة", price = "$10", color = tocolor(53, 131, 240, 180) },
            { name = "غولد", perks = "مزايا كاملة", price = "$25", color = tocolor(53, 131, 240, 180) },
        }
        
        for i, opt in ipairs(premiumOptions) do
            local py = y + 60 + (i-1) * 120
            dxDrawRoundedRectangle(x, py, w, 110, opt.color, 8)
            
            -- خط علوي مميز
            dxDrawRectangle(x, py, w, 3, tocolor(accentR, accentG, accentB, 150))
            
            dxDrawText(opt.name, x + 25, py + 15, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold)
            dxDrawText(opt.perks, x + 25, py + 45, 0, 0, tocolor(240, 240, 240, 255), 0.8, fontNormal)
            dxDrawText("السعر: "..opt.price, x + 25, py + 75, 0, 0, tocolor(180, 255, 180, 255), 0.9, fontBold)
            
            -- زر الشراء
            local buyHov = (hoveredElement == "buy_"..i)
            dxDrawRoundedRectangle(x + w - 120, py + 35, 90, 35, buyHov and tocolor(hoverR,hoverG,hoverB,200) or tocolor(accentR,accentG,accentB,180), 6)
            dxDrawText("اشترِ الآن", x + w - 120, py + 35, x + w - 30, py + 70, tocolor(255,255,255,255), 0.8, fontBold, "center", "center")
            
            -- خط فاصل
            if i < #premiumOptions then
                dxDrawRectangle(x + 20, py + 109, w - 40, 1, tocolor(60, 60, 70, 150))
            end
        end
        
    elseif selectedSubTab == "مزايا العضوية" then
        dxDrawText("مقارنة بين مزايا الباقات المختلفة", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        local features = {
            {"الدعم المميز", "✓", "✓", "✓"},
            {"رتبة في الديسكورد", "✗", "✓", "✓"},
            {"مركبات حصرية", "✗", "1", "3"},
            {"بيوت إضافية", "✗", "1", "2"},
            {"مكافآت يومية", "✗", "✓", "✓"},
            {"خصومات في المحلات", "10%", "20%", "30%"},
        }
        
        -- عناوين الأعمدة
        dxDrawText("الميزة", x + 50, y + 70, 0, 0, tocolor(255, 255, 255, 255), 0.8, fontBold)
        dxDrawText("برونز", x + w/2 - 60, y + 70, 0, 0, tocolor(205, 127, 50, 255), 0.8, fontBold, "center")
        dxDrawText("سيلفر", x + w/2, y + 70, 0, 0, tocolor(192, 192, 192, 255), 0.8, fontBold, "center")
        dxDrawText("غولد", x + w/2 + 60, y + 70, 0, 0, tocolor(255, 215, 0, 255), 0.8, fontBold, "center")
        
        for i, feature in ipairs(features) do
            local fy = y + 95 + (i-1) * 30
            dxDrawRoundedRectangle(x + 20, fy, w - 40, 25, tocolor(35, 35, 45, 180), 6)
            
            dxDrawText(feature[1], x + 35, fy, 0, fy + 25, tocolor(255, 255, 255, 255), 0.75, fontNormal, "left", "center")
            dxDrawText(feature[2], x + w/2 - 60, fy, 0, fy + 25, tocolor(200, 200, 200, 255), 0.75, fontNormal, "center", "center")
            dxDrawText(feature[3], x + w/2, fy, 0, fy + 25, tocolor(200, 200, 200, 255), 0.75, fontNormal, "center", "center")
            dxDrawText(feature[4], x + w/2 + 60, fy, 0, fy + 25, tocolor(200, 200, 200, 255), 0.75, fontNormal, "center", "center")
        end
        
    elseif selectedSubTab == "التفاصيل" then
        dxDrawText("تفاصيل العضويات والشروط", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        local details = {
            "• العضويات تساعد في تطوير السيرفر واستمراريته",
            "• يمكنك ترقية باقتك في أي وقت",
            "• المميزات تُطبق فوراً بعد الشراء",
            "• لا يوجد استرجاع للأموال بعد الشراء",
            "• للإلغاء أو الاستفسار راسل الإدارة",
            "• الشروط والأحكام قابلة للتعديل",
        }
        
        for i, detail in ipairs(details) do
            local dy = y + 70 + (i-1) * 35
            dxDrawText("• " .. detail, x + 30, dy, 0, 0, tocolor(200, 200, 200, 255), 0.75, fontNormal)
        end
    end
end

-- تبويب الإعدادات
function drawSettingsTab(x, y, w, h)
    dxDrawTextWithShadow("الإعدادات العامة", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
    
    if selectedSubTab == "الإعدادات العامة" then
        dxDrawText("تخصيص تجربة اللعب حسب رغبتك", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        -- إعدادات متنوعة
        local settings = {
            {name = "إشعارات الدردشة", value = true, desc = "عرض إشعارات الدردشة العامة"},
            {name = "موسيقى الخلفية", value = false, desc = "تشغيل موسيقى الخلفية في القائمة"},
            {name = "الأصوات البيئية", value = true, desc = "أصوات البيئة والمحيط"},
            {name = "الاهتزاز", value = true, desc = "اهتزاز التحكم عند الحوادث"},
        }
        
        for i, setting in ipairs(settings) do
            local sy = y + 60 + (i-1) * 55
            dxDrawRoundedRectangle(x, sy, w, 45, tocolor(35, 35, 45, 220), 8)
            
            -- خط علوي مميز
            dxDrawRectangle(x, sy, w, 2, tocolor(accentR, accentG, accentB, 150))
            
            dxDrawText(setting.name, x + 25, sy + 10, 0, 0, tocolor(255, 255, 255, 255), 0.85, fontBold)
            dxDrawText(setting.desc, x + 25, sy + 28, 0, 0, tocolor(180, 180, 180, 200), 0.7, fontNormal)
            
            -- زر التفعيل/التعطيل
            local btnHov = (hoveredElement == "setting_"..i)
            local btnX, btnY, btnW, btnH = x + w - 100, sy + 12, 80, 25
            local btnColor = setting.value and (btnHov and tocolor(hoverR,hoverG,hoverB,200) or tocolor(accentR,accentG,accentB,180)) or (btnHov and tocolor(120,120,120,200) or tocolor(100,100,100,150))
            
            dxDrawRoundedRectangle(btnX, btnY, btnW, btnH, btnColor, 4)
            dxDrawText(setting.value and "مفعل" or "معطل", btnX, btnY, btnX + btnW, btnY + btnH, tocolor(255,255,255,255), 0.75, fontBold, "center", "center")
            
            -- خط فاصل
            if i < #settings then
                dxDrawRectangle(x + 15, sy + 44, w - 30, 1, tocolor(60, 60, 70, 150))
            end
        end
        
    elseif selectedSubTab == "الجرافيكس" then
        dxDrawText("إعدادات الجرافيكس والأداء", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        -- إعداد جرافكس الماء
        local waterBtnHov = (hoveredElement == "water_gfx")
        dxDrawRoundedRectangle(x, y + 60, w, 50, tocolor(35, 35, 45, 220), 8)
        
        -- خط علوي مميز
        dxDrawRectangle(x, y + 60, w, 2, tocolor(accentR, accentG, accentB, 150))
        
        dxDrawText("جرافكس الماء", x + 25, y + 70, 0, 0, tocolor(255, 255, 255, 255), 0.85, fontBold)
        dxDrawText("تحسين مظهر الماء والانعكاسات", x + 25, y + 90, 0, 0, tocolor(180, 180, 180, 200), 0.7, fontNormal)
        dxDrawRoundedRectangle(x + w - 100, y + 68, 80, 30, waterGraphicsEnabled and (waterBtnHov and tocolor(hoverR,hoverG,hoverB,200) or tocolor(accentR,accentG,accentB,180)) or (waterBtnHov and tocolor(120,120,120,200) or tocolor(100,100,100,150)), 4)
        dxDrawText(waterGraphicsEnabled and "مفعل" or "معطل", x + w - 100, y + 68, x + w - 20, y + 98, tocolor(255,255,255,255), 0.8, fontBold, "center", "center")
        
        -- خط فاصل
        dxDrawRectangle(x + 15, y + 125, w - 30, 1, tocolor(60, 60, 70, 150))
        
        -- إعدادات أخرى للجرافيكس
        local gfxSettings = {
            {name = "الجودة العالية", value = true, desc = "تحسين جودة النماذج والمركبات"},
            {name = "الظلال", value = false, desc = "عرض الظلال (يستهلك موارد)"},
            {name = "التأثيرات البصرية", value = true, desc = "تأثيرات الضوء والانعكاس"},
        }
        
        for i, setting in ipairs(gfxSettings) do
            local gy = y + 135 + (i-1) * 55
            dxDrawRoundedRectangle(x, gy, w, 45, tocolor(35, 35, 45, 220), 8)
            
            dxDrawText(setting.name, x + 25, gy + 10, 0, 0, tocolor(255, 255, 255, 255), 0.85, fontBold)
            dxDrawText(setting.desc, x + 25, gy + 28, 0, 0, tocolor(180, 180, 180, 200), 0.7, fontNormal)
            
            -- زر التفعيل/التعطيل
            local btnHov = (hoveredElement == "gfx_setting_"..i)
            local btnX, btnY, btnW, btnH = x + w - 100, gy + 12, 80, 25
            local btnColor = setting.value and (btnHov and tocolor(hoverR,hoverG,hoverB,200) or tocolor(accentR,accentG,accentB,180)) or (btnHov and tocolor(120,120,120,200) or tocolor(100,100,100,150))
            
            dxDrawRoundedRectangle(btnX, btnY, btnW, btnH, btnColor, 4)
            dxDrawText(setting.value and "مفعل" or "معطل", btnX, btnY, btnX + btnW, btnY + btnH, tocolor(255,255,255,255), 0.75, fontBold, "center", "center")
        end
        
    elseif selectedSubTab == "الأصوات" then
        dxDrawText("إعدادات الصوت والموسيقى", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        local soundSettings = {
            {name = "صوت المحرك", value = 80, desc = "صوت مركبات اللاعب والآخرين"},
            {name = "الموسيقى", value = 50, desc = "موسيقى الخلفية والمحلات"},
            {name = "الأصوات البيئية", value = 70, desc = "أصوات الطبيعة والمدينة"},
            {name = "الإشعارات", value = 90, desc = "صوت الإشعارات والتنبيهات"},
        }
        
        for i, setting in ipairs(soundSettings) do
            local sndY = y + 60 + (i-1) * 60
            dxDrawRoundedRectangle(x, sndY, w, 50, tocolor(35, 35, 45, 220), 8)
            
            -- خط علوي مميز
            dxDrawRectangle(x, sndY, w, 2, tocolor(accentR, accentG, accentB, 150))
            
            dxDrawText(setting.name, x + 25, sndY + 10, 0, 0, tocolor(255, 255, 255, 255), 0.85, fontBold)
            dxDrawText(setting.desc, x + 25, sndY + 30, 0, 0, tocolor(180, 180, 180, 200), 0.7, fontNormal)
            
            -- شريط الصوت
            local barX, barY, barW, barH = x + w - 180, sndY + 15, 150, 20
            dxDrawRectangle(barX, barY, barW, barH, tocolor(60, 60, 70, 200))
            dxDrawRectangle(barX, barY, (barW * setting.value) / 100, barH, tocolor(accentR, accentG, accentB, 220))
            dxDrawText(setting.value .. "%", barX + barW/2, barY, barX + barW/2, barY + barH, tocolor(255, 255, 255, 255), 0.8, fontBold, "center", "center")
        end
    end
end

-- تبويب الهدايا
function drawGiftsTab(x, y, w, h)
    dxDrawTextWithShadow("الهدايا والمكافآت", x + w/2, y + 10, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
    
    if selectedSubTab == "الهدايا اليومية" then
        dxDrawText("احصل على هدايا مجانية كل يوم", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        -- هدية اليوم
        dxDrawRoundedRectangle(x + 50, y + 70, w - 100, 100, tocolor(35, 35, 45, 220), 8)
        dxDrawText("هدية اليوم", x + w/2, y + 85, 0, 0, tocolor(255, 255, 255, 255), 1.0, fontBold, "center")
        dxDrawText("$5,000", x + w/2, y + 115, 0, 0, tocolor(180, 255, 180, 255), 1.2, fontBold, "center")
        dxDrawText("مكافأة الدخول اليومي", x + w/2, y + 140, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        -- زر المطالبة
        local claimHov = (hoveredElement == "claim_daily")
        dxDrawRoundedRectangle(x + w/2 - 60, y + 190, 120, 40, claimHov and tocolor(hoverR,hoverG,hoverB,200) or tocolor(accentR,accentG,accentB,180), 6)
        dxDrawText("المطالبة", x + w/2 - 60, y + 190, x + w/2 + 60, y + 230, tocolor(255,255,255,255), 0.9, fontBold, "center", "center")
        
        -- تقويم الهدايا
        dxDrawText("تقويم الهدايا الشهري", x + w/2, y + 250, 0, 0, tocolor(255, 255, 255, 255), 0.9, fontBold, "center")
        
    elseif selectedSubTab == "المكافآت" then
        dxDrawText("مكافآت الإنجازات والتحديات", x + w/2, y + 35, 0, 0, tocolor(200, 200, 200, 200), 0.8, fontNormal, "center")
        
        -- عرض المكافآت المتاحة
        local rewards = getElementData(localPlayer, "availableRewards") or {}
        
        if #rewards > 0 then
            for i, reward in ipairs(rewards) do
                local ry = y + 60 + (i-1) * 80
                dxDrawRoundedRectangle(x, ry, w, 70, tocolor(35, 35, 45, 220), 8)
                
                -- خط علوي مميز
                dxDrawRectangle(x, ry, w, 2, tocolor(accentR, accentG, accentB, 150))
                
                dxDrawText(reward.name or "مكافأة", x + 25, ry + 15, 0, 0, tocolor(255, 255, 255, 255), 0.85, fontBold)
                dxDrawText(reward.description or "وصف المكافأة", x + 25, ry + 35, 0, 0, tocolor(200, 200, 200, 200), 0.7, fontNormal)
                
                -- زر المطالبة
                local claimHov = (hoveredElement == "claim_reward_"..i)
                dxDrawRoundedRectangle(x + w - 120, ry + 20, 90, 30, claimHov and tocolor(hoverR,hoverG,hoverB,200) or tocolor(accentR,accentG,accentB,180), 6)
                dxDrawText("المطالبة", x + w - 120, ry + 20, x + w - 30, ry + 50, tocolor(255,255,255,255), 0.75, fontBold, "center", "center")
            end
        else
            dxDrawText("لا توجد مكافآت متاحة حالياً", x + w/2, y + 80, 0, 0, tocolor(150, 150, 150, 200), 0.9, fontNormal, "center")
        end
    end
end

-- كاش اللاعبين للأصدقاء
local cachedPlayers = {}
function refreshPlayerCache()
    cachedPlayers = {}
    for _, p in ipairs(getElementsByType("player")) do
        table.insert(cachedPlayers, {player = p, name = getPlayerName(p), health = getElementHealth(p)})
    end
end

-- معالجة حركة الماوس
addEventHandler("onClientCursorMove", root, function(_, _, cx, cy)
    if not showPanel then 
        hoveredElement = nil
        return 
    end
    
    hoveredElement = nil
    
    -- التحقق من التبويبات الرئيسية
    local yStart = panelY + 90
    for i, name in ipairs(tabs) do
        local tabY = yStart + (i-1) * 42
        if isInBox(cx, cy, panelX + 15, tabY - 2, 190, 40) then
            hoveredElement = "tab_"..name
            return
        end
    end
    
    -- التحقق من القوائم الفرعية
    local contentX, contentY = panelX + 230, panelY + 20
    if subTabs[selectedTab] then
        local subTabW = (panelW - 250 - 25) / #subTabs[selectedTab]
        for i, name in ipairs(subTabs[selectedTab]) do
            local tx = contentX + (i-1) * (subTabW + 5) + 15
            local ty = contentY + 15
            if isInBox(cx, cy, tx, ty, subTabW, 35) then
                hoveredElement = "subtab_"..name
                return
            end
        end
    end
    
    -- زر الإغلاق
    if isInBox(cx, cy, panelX + panelW - 45, panelY + 15, 35, 35) then
        hoveredElement = "close_btn"
        return
    end
    
    -- أزرار الإعدادات
    if selectedTab == "الخيارات" then
        if selectedSubTab == "الإعدادات العامة" then
            for i = 1, 4 do
                if isInBox(cx, cy, contentX + panelW - 250 - 100, contentY + 100 + 60 + (i-1) * 55 + 12, 80, 25) then
                    hoveredElement = "setting_"..i
                    return
                end
            end
        elseif selectedSubTab == "الجرافيكس" then
            if isInBox(cx, cy, contentX + panelW - 250 - 100, contentY + 100 + 68, 80, 30) then
                hoveredElement = "water_gfx"
                return
            end
            for i = 1, 3 do
                if isInBox(cx, cy, contentX + panelW - 250 - 100, contentY + 100 + 135 + (i-1) * 55 + 12, 80, 25) then
                    hoveredElement = "gfx_setting_"..i
                    return
                end
            end
        end
    end
    
    -- أزرار الريسورسز في المركبات
    if selectedTab == "المركبات" and selectedSubTab == "إعدادات المركبات" then
        for i, resource in ipairs(vehicleResources) do
            local vy = contentY + 100 + 55 + (i-1) * 65
            local btnX, btnY = contentX + panelW - 250 - 120, vy + 15
            
            if isInBox(cx, cy, btnX, btnY, 90, 25) then
                hoveredElement = "resource_"..i
                return
            end
        end
    end
    
    -- زر تشغيل الكل
    if selectedTab == "المركبات" and selectedSubTab == "تشغيل الكل" then
        if isInBox(cx, cy, contentX + panelW/2 - 80, contentY + 100 + 80, 160, 40) then
            hoveredElement = "enable_all"
            return
        end
    end
    
    -- زر إيقاف الكل
    if selectedTab == "المركبات" and selectedSubTab == "إيقاف الكل" then
        if isInBox(cx, cy, contentX + panelW/2 - 80, contentY + 100 + 80, 160, 40) then
            hoveredElement = "disable_all"
            return
        end
    end
    
    -- زر إرسال الشكوى
    if selectedTab == "الدعم الفني" and selectedSubTab == "إرسال شكوى" then
        if isInBox(cx, cy, contentX + panelW/2 - 70, contentY + 100 + 270, 140, 40) then
            hoveredElement = "send_support"
            return
        end
        
        -- حقول النص
        if isInBox(cx, cy, contentX + 120, contentY + 100 + 58, panelW - 250 - 145, 35) then
            hoveredElement = "support_subject"
            return
        end
        
        if isInBox(cx, cy, contentX + 25, contentY + 100 + 135, panelW - 250 - 50, 120) then
            hoveredElement = "support_message"
            return
        end
    end
    
    -- زر نسخ الديسكورد
    if selectedTab == "الدعم الفني" and selectedSubTab == "الديسكورد" then
        if isInBox(cx, cy, contentX + panelW/2 - 70, contentY + 100 + 130, 140, 40) then
            hoveredElement = "copy_discord"
            return
        end
    end
    
    -- أزرار الأصدقاء
    if selectedTab == "الأصدقاء" and selectedSubTab == "اللاعبون القريبون" then
        local nearbyPlayers = {}
        for _, p in ipairs(getElementsByType("player")) do
            if p ~= localPlayer then
                table.insert(nearbyPlayers, p)
            end
        end
        
        for i = 1, #nearbyPlayers do
            local py = contentY + 100 + 60 + (i-1) * 45
            if isInBox(cx, cy, contentX + panelW - 250 - 100, py + 7, 70, 21) then
                hoveredElement = "add_friend_"..i
                return
            end
        end
    end
    
    -- أزرار العضويات
    if selectedTab == "العضويات المميزة" and selectedSubTab == "الباقات" then
        for i = 1, 3 do
            local py = contentY + 100 + 60 + (i-1) * 120
            if isInBox(cx, cy, contentX + panelW - 250 - 120, py + 35, 90, 35) then
                hoveredElement = "buy_"..i
                return
            end
        end
    end
    
    -- أزرار الهدايا
    if selectedTab == "الهدايا" then
        if selectedSubTab == "الهدايا اليومية" then
            if isInBox(cx, cy, contentX + panelW/2 - 60, contentY + 100 + 190, 120, 40) then
                hoveredElement = "claim_daily"
                return
            end
        elseif selectedSubTab == "المكافآت" then
            local rewards = getElementData(localPlayer, "availableRewards") or {}
            for i = 1, #rewards do
                local ry = contentY + 100 + 60 + (i-1) * 80
                if isInBox(cx, cy, contentX + panelW - 250 - 120, ry + 20, 90, 30) then
                    hoveredElement = "claim_reward_"..i
                    return
                end
            end
        end
    end
end)

-- معالجة النقرات
addEventHandler("onClientClick", root, function(button, state, cx, cy)
    if not showPanel or button ~= "left" or state ~= "down" then return end

    -- زر الإغلاق
    if isInBox(cx, cy, panelX + panelW - 45, panelY + 15, 35, 35) then
        showPanel = false
        showCursor(false)
        return
    end

    -- التبويبات الرئيسية
    local yStart = panelY + 90
    for i, name in ipairs(tabs) do
        local tabY = yStart + (i-1) * 42
        if isInBox(cx, cy, panelX + 15, tabY - 2, 190, 40) then
            selectedTab = name
            selectedSubTab = subTabs[name][1] or "معلومات"
            return
        end
    end

    -- القوائم الفرعية
    local contentX, contentY = panelX + 230, panelY + 20
    if subTabs[selectedTab] then
        local subTabW = (panelW - 250 - 25) / #subTabs[selectedTab]
        for i, name in ipairs(subTabs[selectedTab]) do
            local tx = contentX + (i-1) * (subTabW + 5) + 15
            local ty = contentY + 15
            if isInBox(cx, cy, tx, ty, subTabW, 35) then
                selectedSubTab = name
                return
            end
        end
    end

    -- أزرار الإعدادات
    if selectedTab == "الخيارات" then
        if selectedSubTab == "الإعدادات العامة" then
            for i = 1, 4 do
                if isInBox(cx, cy, contentX + panelW - 250 - 100, contentY + 100 + 60 + (i-1) * 55 + 12, 80, 25) then
                    -- تبديل الإعدادات العامة
                    showToast("تم تغيير الإعداد: " .. i)
                    return
                end
            end
        elseif selectedSubTab == "الجرافيكس" then
            if isInBox(cx, cy, contentX + panelW - 250 - 100, contentY + 100 + 68, 80, 30) then
                waterGraphicsEnabled = not waterGraphicsEnabled
                showToast("جرافكس الماء: "..(waterGraphicsEnabled and "مفعل" or "معطل"))
                return
            end
            for i = 1, 3 do
                if isInBox(cx, cy, contentX + panelW - 250 - 100, contentY + 100 + 135 + (i-1) * 55 + 12, 80, 25) then
                    showToast("تم تغيير إعداد الجرافيكس: " .. i)
                    return
                end
            end
        end
    end
    
    -- أزرار الريسورسز في المركبات
    if selectedTab == "المركبات" and selectedSubTab == "إعدادات المركبات" then
        for i, resource in ipairs(vehicleResources) do
            local vy = contentY + 100 + 55 + (i-1) * 65
            local btnX, btnY = contentX + panelW - 250 - 120, vy + 15
            
            if isInBox(cx, cy, btnX, btnY, 90, 25) then
                vehicleResources[i].enabled = not vehicleResources[i].enabled
                showToast(resource.name .. ": " .. (vehicleResources[i].enabled and "مفعل" or "معطل"))
                return
            end
        end
    end
    
    -- زر تشغيل الكل
    if selectedTab == "المركبات" and selectedSubTab == "تشغيل الكل" then
        if isInBox(cx, cy, contentX + panelW/2 - 80, contentY + 100 + 80, 160, 40) then
            for i, resource in ipairs(vehicleResources) do
                vehicleResources[i].enabled = true
            end
            showToast("تم تشغيل جميع مركبات السيرفر")
            return
        end
    end
    
    -- زر إيقاف الكل
    if selectedTab == "المركبات" and selectedSubTab == "إيقاف الكل" then
        if isInBox(cx, cy, contentX + panelW/2 - 80, contentY + 100 + 80, 160, 40) then
            for i, resource in ipairs(vehicleResources) do
                vehicleResources[i].enabled = false
            end
            showToast("تم إيقاف جميع مركبات السيرفر")
            return
        end
    end
    
    -- زر إرسال الشكوى
    if selectedTab == "الدعم الفني" and selectedSubTab == "إرسال شكوى" then
        if isInBox(cx, cy, contentX + panelW/2 - 70, contentY + 100 + 270, 140, 40) then
            if supportSubject and supportSubject ~= "" and supportMessage and supportMessage ~= "" and string.len(supportMessage) <= 500 then
                triggerServerEvent("paradise:sendSupport", localPlayer, supportSubject, supportMessage)
                supportSubject = ""
                supportMessage = ""
                showToast("تم إرسال الشكوى للإدارة")
            else
                showToast("يرجى ملء جميع الحقول بشكل صحيح", 255, 100, 100)
            end
            return
        end
    end
    
    -- زر نسخ الديسكورد
    if selectedTab == "الدعم الفني" and selectedSubTab == "الديسكورد" then
        if isInBox(cx, cy, contentX + panelW/2 - 70, contentY + 100 + 130, 140, 40) then
            setClipboard("https://discord.gg/paradiserp")
            showToast("تم نسخ رابط الديسكورد")
            return
        end
    end
    
    -- أزرار الأصدقاء
    if selectedTab == "الأصدقاء" and selectedSubTab == "اللاعبون القريبون" then
        local nearbyPlayers = {}
        for _, p in ipairs(getElementsByType("player")) do
            if p ~= localPlayer then
                table.insert(nearbyPlayers, p)
            end
        end
        
        for i = 1, #nearbyPlayers do
            local py = contentY + 100 + 60 + (i-1) * 45
            if isInBox(cx, cy, contentX + panelW - 250 - 100, py + 7, 70, 21) then
                local playerName = getPlayerName(nearbyPlayers[i])
                showToast("تم إرسال طلب صداقة إلى: " .. playerName)
                return
            end
        end
    end
    
    -- أزرار العضويات
    if selectedTab == "العضويات المميزة" and selectedSubTab == "الباقات" then
        for i = 1, 3 do
            local py = contentY + 100 + 60 + (i-1) * 120
            if isInBox(cx, cy, contentX + panelW - 250 - 120, py + 35, 90, 35) then
                local packageNames = {"برونز", "سيلفر", "غولد"}
                showToast("عملية شراء باقة " .. packageNames[i] .. " قيد المعالجة")
                return
            end
        end
    end
    
    -- أزرار الهدايا
    if selectedTab == "الهدايا" then
        if selectedSubTab == "الهدايا اليومية" then
            if isInBox(cx, cy, contentX + panelW/2 - 60, contentY + 100 + 190, 120, 40) then
                showToast("تم المطالبة بالهدية اليومية")
                return
            end
        elseif selectedSubTab == "المكافآت" then
            local rewards = getElementData(localPlayer, "availableRewards") or {}
            for i = 1, #rewards do
                local ry = contentY + 100 + 60 + (i-1) * 80
                if isInBox(cx, cy, contentX + panelW - 250 - 120, ry + 20, 90, 30) then
                    showToast("تم المطالبة بالمكافأة: " .. (rewards[i].name or "غير معروفة"))
                    return
                end
            end
        end
    end
end)

-- معالجة إدخال النص
addEventHandler("onClientCharacter", root, function(character)
    if not showPanel or selectedTab ~= "الدعم الفني" or selectedSubTab ~= "إرسال شكوى" then return end
    
    if hoveredElement == "support_subject" and string.len(supportSubject or "") < 50 then
        supportSubject = (supportSubject or "") .. character
        lastTypingTime = getTickCount()
        isTyping = true
    elseif hoveredElement == "support_message" and string.len(supportMessage or "") < 500 then
        supportMessage = (supportMessage or "") .. character
        lastTypingTime = getTickCount()
        isTyping = true
    end
end)

addEventHandler("onClientKey", root, function(button, press)
    if not showPanel or selectedTab ~= "الدعم الفني" or selectedSubTab ~= "إرسال شكوى" then return end
    
    if button == "backspace" and press then
        if hoveredElement == "support_message" and string.len(supportMessage or "") > 0 then
            supportMessage = string.sub(supportMessage, 1, -2)
            lastTypingTime = getTickCount()
            isTyping = true
        elseif hoveredElement == "support_subject" and string.len(supportSubject or "") > 0 then
            supportSubject = string.sub(supportSubject, 1, -2)
            lastTypingTime = getTickCount()
            isTyping = true
        end
    end
end)

-- الرندر الرئيسي
addEventHandler("onClientRender", root, function()
    if showPanel then
        drawPanel()
    end
end)

-- حدث التوست
addEvent("paradise:showToast", true)
addEventHandler("paradise:showToast", root, function(message, r, g, b)
    outputChatBox("["..getPlayerName(localPlayer).."] "..message, r or 53, g or 131, b or 240)
end)

-- الأحداث من السيرفر
addEvent("paradise:clientSupportSent", true)
addEventHandler("paradise:clientSupportSent", root, function(sentToCount)
    if sentToCount and sentToCount > 0 then
        showToast("تم إرسال الشكوى إلى "..sentToCount.." إداري")
    else
        showToast("لا يوجد إداري متصل لاستلام الشكوى الآن", 255, 180, 0)
    end
end)

addEvent("paradise:receiveFriendRequest", true)
addEventHandler("paradise:receiveFriendRequest", root, function(fromPlayer, fromName)
    showToast("طلب صداقة من: "..fromName)
end)

addEvent("paradise:adminReceiveSupport", true)
addEventHandler("paradise:adminReceiveSupport", root, function(senderName, subject, message)
    -- هذا الحدث للإداريين فقط
    if getElementData(localPlayer, "isAdmin") then
        showToast("شكوى من "..senderName..": "..subject)
    end
end)

addEvent("paradise:announcement", true)
addEventHandler("paradise:announcement", root, function(fromName, text)
    showToast("إعلان من "..fromName..": "..text, 255, 200, 0)
end)

-- حدث استقبال بيانات المركبات المملوكة
addEvent("paradise:receivePlayerVehicles", true)
addEventHandler("paradise:receivePlayerVehicles", root, function(vehicles)
    playerVehicles = vehicles or {}
end)

-- حدث استقبال بيانات البيوت المملوكة
addEvent("paradise:receivePlayerHouses", true)
addEventHandler("paradise:receivePlayerHouses", root, function(houses)
    playerHouses = houses or {}
end)

-- حدث استقبال بيانات اللاعب
addEvent("paradise:receivePlayerData", true)
addEventHandler("paradise:receivePlayerData", root, function(playerData)
    if playerData then
        for key, value in pairs(playerData) do
            setElementData(localPlayer, key, value)
        end
    end
end)