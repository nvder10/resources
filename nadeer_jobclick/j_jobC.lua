local screenW, screenH = guiGetScreenSize()
local dxfont = dxCreateFont("Tajawal-Bold.ttf", 11) or "default-bold"
local dxfont_small = dxCreateFont("Tajawal-Bold.ttf", 9) or "default"
local isJobMenuOpen = false
local jobWindow = nil
local selectedJob = 0

-- التوست notifications
local toastData = { visible = false, message = "", startTime = 0, duration = 3000 }

-- ألوان المظهر الرئيسي
local primaryColor = {168, 132, 81}
local backgroundColor = {20, 20, 20}
local textColor = {255, 255, 255}
local secondaryColor = {30, 30, 30}

-- الإيقونات
local jobIcons = {
    [1] = { name = "سائق توصيل", icon = "twsel.png", color = {168, 132, 81} },
    [2] = { name = "سائق تاكسي", icon = "taxi.png", color = {168, 132, 81} },
    [3] = { name = "سائق حافلة", icon = "bus.png", color = {168, 132, 81} }
}

-- ========== تحميل الصور ==========

local loadedTextures = {}
for i, job in pairs(jobIcons) do
    local texturePath = job.icon
    if fileExists(texturePath) then
        loadedTextures[i] = dxCreateTexture(texturePath)
        outputDebugString("تم تحميل الصورة: " .. texturePath)
    else
        outputDebugString("ملف الصورة غير موجود: " .. texturePath)
        loadedTextures[i] = nil
    end
end

-- ========== الدوال الأساسية ==========

function showToast(message, isError)
    toastData.visible = true
    toastData.message = message
    toastData.startTime = getTickCount()
    toastData.isError = isError or false
    toastData.progress = 100
end

function isMouseInPosition(x, y, width, height)
    if not isCursorShowing() then return false end
    local cursorX, cursorY = getCursorPosition()
    cursorX, cursorY = cursorX * screenW, cursorY * screenH
    return cursorX >= x and cursorX <= x + width and cursorY >= y and cursorY <= y + height
end

function hasDrivingLicense()
    local carLicense = getElementData(localPlayer, "license.car")
    return carLicense == 1
end

function getCurrentJobInfo()
    local currentJob = getElementData(localPlayer, "job") or 0
    local jobName = "لا يوجد"
    
    if currentJob == 1 then
        jobName = "سائق توصيل"
    elseif currentJob == 2 then
        jobName = "سائق تاكسي"
    elseif currentJob == 3 then
        jobName = "سائق حافلة"
    elseif currentJob > 0 then
        jobName = "وظيفة أخرى"
    end
    
    return currentJob, jobName
end

-- ========== نظام التكامل مع الوظائف الحالية ==========

function initializeJobSystem(jobId)
    outputDebugString("جاري تهيئة نظام الوظيفة: " .. tostring(jobId))
    
    if jobId == 1 then
        if exports["job-system-trucker"] then
            exports["job-system-trucker"]:displayTruckerJob()
            showToast("🚚 تم تعيينك كسائق توصيل\nاتبع العلامات البرتقالية على الخريطة")
        end
    elseif jobId == 2 then
        displayTaxiJob()
        showToast("🚕 تم تعيينك كسائق تاكسي\nاذهب إلى الموقف الأصفر لبدء العمل")
    elseif jobId == 3 then
        displayBusJob()
        showToast("🚌 تم تعيينك كسائق حافلة\nاستخدم /startbus لبدء الخط\nاتبع العلامات الزرقاء")
    end
    
    setElementData(localPlayer, "currentJob", jobId)
end

-- ========== الواجهة الرئيسية ==========

addEventHandler("onClientRender", root, function()
    -- رسم التوست (أصغر وأجمل)
    if toastData.visible then
        local elapsed = getTickCount() - toastData.startTime
        local progress = elapsed / toastData.duration
        
        if progress >= 1 then
            toastData.visible = false
            return
        end
        
        toastData.progress = 100 - (progress * 100)
        
        local toastWidth, toastHeight = 300, 45 -- حجم أصغر
        local toastX = (screenW - toastWidth) / 2
        local toastY = 80 -- أعلى قليلاً
        
        dxDrawRectangle(toastX, toastY, toastWidth, toastHeight, tocolor(20, 20, 20, 240))
        dxDrawRectangle(toastX, toastY, toastWidth, 1, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
        
        local progressWidth = (toastWidth * toastData.progress) / 100
        dxDrawRectangle(toastX, toastY + toastHeight - 1, progressWidth, 1, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
        
        local textColor = toastData.isError and tocolor(255, 100, 100, 255) or tocolor(255, 255, 255, 255)
        dxDrawText(toastData.message, toastX, toastY, toastX + toastWidth, toastY + toastHeight, 
                  textColor, 0.9, dxfont_small, "center", "center")
    end
    
    if isJobMenuOpen then
        drawJobSelectionWindow()
    end
    
    if getElementData(localPlayer, "loggedin") ~= 1 then return end

    local nearJobBoard = false
    local peds = getElementsByType("ped", root, true)

    for k, element in ipairs(peds) do
        local isNpc = getElementData(element, "rpp.npc.type") or getElementData(element, "npc.type")

        if isNpc == "ch.jobboard" then
            local px, py, pz = getElementPosition(element)
            local x, y, z = getElementPosition(localPlayer)

            if getDistanceBetweenPoints3D(px, py, pz, x, y, z) <= 3 then
                nearJobBoard = true
                local text = isJobMenuOpen and "[E] لإغلاق القائمة" or "[E] لإختيار وظيفة"
                
                local padding = 15
                local textWidth = dxGetTextWidth(text, 1, dxfont_small)
                local startX = screenW/2 - (textWidth/2) - padding
                local startY = screenH - 130
                local width = textWidth + (padding * 2)
                local height = 25
                
                dxDrawRectangle(startX, startY, width, height, tocolor(0, 0, 0, 180))
                dxDrawRectangle(startX, startY, width, 2, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
                dxDrawText(text, startX, startY, startX + width, startY + height, 
                          tocolor(255, 255, 255, 255), 1, dxfont_small, "center", "center")
                break
            end
        end
    end
end)

function drawJobSelectionWindow()
    local width, height = 500, 450
    local x = (screenW - width) / 2
    local y = (screenH - height) / 2
    
    dxDrawRectangle(x, y, width, height, tocolor(20, 20, 20, 255))
    dxDrawRectangle(x, y, width, 3, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    dxDrawRectangle(x, y + height - 3, width, 3, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    dxDrawRectangle(x, y, 3, height, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    dxDrawRectangle(x + width - 3, y, 3, height, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    
    dxDrawText("مسؤول التوظيف - بلدية لوس سانتوس", x, y + 15, x + width, y + 45, 
              tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255), 1.2, dxfont, "center", "center")
    
    local currentJob, jobName = getCurrentJobInfo()
    local statusText = currentJob > 0 and ("الوظيفة الحالية: " .. jobName) or "أنت عاطل عن العمل حالياً"
    dxDrawText(statusText, x, y + 50, x + width, y + 70, 
              currentJob > 0 and tocolor(255, 100, 100, 255) or tocolor(100, 255, 100, 255), 1, dxfont_small, "center", "center")
    
    local jobHeight = 90
    local startY = y + 80
    
    for i = 1, 3 do
        local jobY = startY + ((i-1) * (jobHeight + 10))
        local isSelected = (selectedJob == i)
        
        local bgColor = isSelected and tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 80) 
                              or tocolor(40, 40, 40, 255)
        dxDrawRectangle(x + 20, jobY, width - 40, jobHeight, bgColor)
        dxDrawRectangle(x + 20, jobY, width - 40, 2, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
        dxDrawRectangle(x + 20, jobY + jobHeight - 2, width - 40, 2, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
        
        local iconX, iconY = x + 30, jobY + 15
        if loadedTextures[i] then
            dxDrawImage(iconX, iconY, 60, 60, loadedTextures[i])
        else
            dxDrawRectangle(iconX, iconY, 60, 60, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
            dxDrawText("وظيفة", iconX, iconY, iconX + 60, iconY + 60, tocolor(255, 255, 255, 255), 1, dxfont_small, "center", "center")
        end
        
        dxDrawText(jobIcons[i].name, x + 110, jobY + 15, x + width - 20, jobY + 35, 
                  tocolor(255, 255, 255, 255), 1.1, dxfont, "left", "center")
        
        local descriptions = {
            [1] = "توصيل الطرود والبضائع في جميع أنحاء المدينة\nالمتطلبات: رخصة قيادة سارية",
            [2] = "نقل الركاب إلى وجهاتهم المختلفة\nالمتطلبات: رخصة قيادة سارية",
            [3] = "قيادة الحافلات على خطوط النقل العام\nالمتطلبات: رخصة قيادة سارية"
        }
        dxDrawText(descriptions[i], x + 110, jobY + 35, x + width - 20, jobY + 75, 
                  tocolor(200, 200, 200, 255), 0.9, dxfont_small, "left", "top")
    end
    
    local buttonWidth = (width - 60) / 2
    local buttonHeight = 40
    local buttonY = y + height - 55
    
    local acceptHover = isMouseInPosition(x + 20, buttonY, buttonWidth, buttonHeight)
    local acceptColor = acceptHover and tocolor(188, 152, 101, 255) or tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255)
    dxDrawRectangle(x + 20, buttonY, buttonWidth, buttonHeight, acceptColor)
    dxDrawText("تقديم للوظيفة", x + 20, buttonY, x + 20 + buttonWidth, buttonY + buttonHeight, 
              tocolor(255, 255, 255, 255), 1, dxfont_small, "center", "center")
    
    local cancelHover = isMouseInPosition(x + 30 + buttonWidth, buttonY, buttonWidth, buttonHeight)
    local cancelColor = cancelHover and tocolor(100, 100, 100, 255) or tocolor(80, 80, 80, 255)
    dxDrawRectangle(x + 30 + buttonWidth, buttonY, buttonWidth, buttonHeight, cancelColor)
    dxDrawText("إلغاء", x + 30 + buttonWidth, buttonY, x + 30 + buttonWidth + buttonWidth, buttonY + buttonHeight, 
              tocolor(255, 255, 255, 255), 1, dxfont_small, "center", "center")
    
    dxDrawText("اختر الوظيفة المناسبة لك ثم اضغط على 'تقديم للوظيفة'", x, buttonY - 25, x + width, buttonY, 
              tocolor(150, 150, 150, 255), 0.8, dxfont_small, "center", "center")
end

-- ========== التحكم في الواجهة ==========

bindKey("e", "down", function()
    if getElementData(localPlayer, "loggedin") ~= 1 then return end
    
    local nearJobBoard = false
    local peds = getElementsByType("ped", root, true)

    for k, element in ipairs(peds) do
        local isNpc = getElementData(element, "rpp.npc.type") or getElementData(element, "npc.type")

        if isNpc == "ch.jobboard" then
            local px, py, pz = getElementPosition(element)
            local x, y, z = getElementPosition(localPlayer)

            if getDistanceBetweenPoints3D(px, py, pz, x, y, z) <= 3 then
                nearJobBoard = true
                
                if not isJobMenuOpen then
                    openJobMenu()
                else
                    closeJobMenu()
                end
                break
            end
        end
    end
    
    if not nearJobBoard and isJobMenuOpen then
        closeJobMenu()
    end
end)

function openJobMenu()
    if isJobMenuOpen then return end
    
    isJobMenuOpen = true
    selectedJob = 0
    showCursor(true)
    
    local currentJob, jobName = getCurrentJobInfo()
    if currentJob > 0 then
        showToast("⚠ لديك وظيفة حالية: " .. jobName .. " - استخدم /quitjob لتركها", true)
    end
end

function closeJobMenu()
    if not isJobMenuOpen then return end
    
    isJobMenuOpen = false
    selectedJob = 0
    showCursor(false)
end

addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY)
    if not isJobMenuOpen or button ~= "left" or state ~= "down" then return end
    
    local width, height = 500, 450
    local x = (screenW - width) / 2
    local y = (screenH - height) / 2
    
    local jobHeight = 90
    local startY = y + 80
    
    for i = 1, 3 do
        local jobY = startY + ((i-1) * (jobHeight + 10))
        if isMouseInPosition(x + 20, jobY, width - 40, jobHeight) then
            selectedJob = i
            return
        end
    end
    
    local buttonWidth = (width - 60) / 2
    local buttonHeight = 40
    local buttonY = y + height - 55
    
    if isMouseInPosition(x + 20, buttonY, buttonWidth, buttonHeight) then
        if selectedJob == 0 then
            showToast("❌ يرجى اختيار وظيفة أولاً", true)
            return
        end
        acceptJob(selectedJob)
    end
    
    if isMouseInPosition(x + 30 + buttonWidth, buttonY, buttonWidth, buttonHeight) then
        closeJobMenu()
    end
end)

function acceptJob(jobId)
    local jobText = jobIcons[jobId].name
    outputDebugString("محاولة التقديم للوظيفة: " .. jobText)
    
    local currentJob = getElementData(localPlayer, "job") or 0
    
    if currentJob > 0 then
        showToast("❌ لديك وظيفة بالفعل\nاستخدم /quitjob لتركها أولاً", true)
        return
    end
    
    if (jobId == 1 or jobId == 2 or jobId == 3) and not hasDrivingLicense() then
        showToast("❌ تحتاج إلى رخصة قيادة سارية المفعول\nلهذه الوظيفة", true)
        return
    end
    
    triggerServerEvent("acceptJob", localPlayer, jobId)
    showToast("📝 تم إرسال طلبك للوظيفة: " .. jobText)
    closeJobMenu()
end

-- ========== أحداث السيرفر ==========

addEvent("onJobApplicationResult", true)
addEventHandler("onJobApplicationResult", root, function(success, message)
    if success then
        showToast("✅ " .. message)
    else
        showToast("❌ " .. message, true)
    end
end)

addEvent("onJobAccepted", true)
addEventHandler("onJobAccepted", root, function(jobId, success, message)
    if success then
        showToast("✅ " .. (message or "تم قبول طلبك للوظيفة"))
        initializeJobSystem(jobId)
    else
        showToast("❌ " .. (message or "فشل في الحصول على الوظيفة"), true)
    end
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    for i, texture in pairs(loadedTextures) do
        if isElement(texture) then
            destroyElement(texture)
        end
    end
end)

outputDebugString("تم تحميل نظام الوظائف المحسن بنجاح")