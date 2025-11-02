local screenW, screenH = guiGetScreenSize()
local dxfont_small = dxCreateFont("Tajawal-Bold.ttf", 10) or "default"

-- ========== الإعدادات العامة ==========
local settings = {
    -- إعدادات التوست
    toast = {
        padding = 30,
        height = 25,
        yOffset = 0.1,
        spacing = 10,
        duration = 4000
    },
    
    -- إعدادات رسالة التفاعل
    interaction = {
        padding = 20,
        height = 25,
        yPosition = 130
    },
    
    -- إعدادات نافذة التصليح
    repairWindow = {
        width = 320,
        height = 90,
        yPosition = 150,
        barHeight = 22
    },
    
    -- إعدادات التصليح
    repair = {
        costPerPercent = 1.5, -- سعر التصليح لكل 1%
        minCost = 50, -- أقل تكلفة للتصليح
        repairSpeed = 2 -- سرعة التصليح (2% كل 100ms)
    }
}

-- ========== أماكن التصليح ==========
local repairStations = {
    -- محطة التصليح الرئيسية
    {
        x = 2063.6948242188, 
        y = -1831.6889648438, 
        z = 13.402562141418, 
        radius = 5,
        name = "محطة تصليح تلقائي"
    },
    
    -- يمكن إضافة محطات تصليح جديدة هنا:
    -- {
    --     x = 0, 
    --     y = 0, 
    --     z = 0, 
    --     radius = 5,
    --     name = "اسم المحطة"
    -- },
    
   -- محطة تصليح عند المطار
   -- {
   --      x = 1574.84, 
   --       y = -2174.94, 
   --       z = 13.55, 
   --       radius = 5,
   --       name = "محطة تصليح المطار"
   --   },
    
    -- محطة تصليح عند الداون تاون
 --  {
 --     x = 2127.64, 
 --       y = -1136.63, 
 --       z = 25.47, 
 --       radius = 5,
 --       name = "محطة تصليح الداون تاون"
 --   }
 --}

-- ========== الألوان ==========
local colors = {
    background = {3, 20, 23},
    primary = {52, 171, 173},
    text = {255, 255, 255},
    error = {255, 100, 100},
    success = {100, 255, 100},
    dark = {50, 50, 50}
}

-- ========== متغيرات التصليح ==========
local isRepairing = false
local repairProgress = 0
local repairCost = 0
local repairVehicle = nil
local currentStation = nil

-- ========== نظام التوست ==========
local toastMessages = {}

function showToast(message, isError)
    table.insert(toastMessages, {
        text = message,
        startTime = getTickCount(),
        alpha = 0,
        isError = isError or false
    })
end

function drawToastMessages()
    local currentTime = getTickCount()
    local yOffset = screenH * settings.toast.yOffset
    
    for i = #toastMessages, 1, -1 do
        local toast = toastMessages[i]
        local elapsed = currentTime - toast.startTime
        
        if elapsed < settings.toast.duration then
            local progress = elapsed / settings.toast.duration
            local alpha = 255
            
            -- حساب الشفافية
            if progress < 0.2 then
                alpha = (progress / 0.2) * 255
            elseif progress > 0.8 then
                alpha = ((1 - progress) / 0.2) * 255
            end
            
            local width = dxGetTextWidth(toast.text, 1, dxfont_small) + (settings.toast.padding * 2)
            local height = settings.toast.height
            local x = (screenW - width) / 2
            local y = yOffset
            
            -- خلفية التوست
            dxDrawRectangle(x, y, width, height, tocolor(colors.background[1], colors.background[2], colors.background[3], alpha))
            
            -- الخط العلوي المتحرك
            local lineProgress = 1 - progress
            local lineWidth = width * lineProgress
            dxDrawRectangle(x, y, lineWidth, 2, tocolor(colors.primary[1], colors.primary[2], colors.primary[3], alpha))
            
            -- النص
            local textColor = toast.isError and tocolor(colors.error[1], colors.error[2], colors.error[3], alpha) 
                              or tocolor(colors.text[1], colors.text[2], colors.text[3], alpha)
            dxDrawText(toast.text, x, y, x + width, y + height, 
                      textColor, 1, dxfont_small, "center", "center")
            
            yOffset = yOffset + height + settings.toast.spacing
        else
            table.remove(toastMessages, i)
        end
    end
end

-- ========== الواجهات الرئيسية ==========
function drawRepairSystem()
    -- رسم التوست أولاً
    drawToastMessages()
    
    -- رسم رسالة التفاعل مع محطة التصليح
    if getElementData(localPlayer, "loggedin") ~= 1 then return end
    
    local playerVehicle = getPedOccupiedVehicle(localPlayer)
    if not playerVehicle or getVehicleOccupant(playerVehicle, 0) ~= localPlayer then return end
    
    local nearStation = getNearbyRepairStation(playerVehicle)
    
    if nearStation then
        if isRepairing then
            drawRepairProgress()
        else
            drawRepairMessage(nearStation.name)
        end
    end
end
addEventHandler("onClientRender", root, drawRepairSystem)

function drawRepairMessage(stationName)
    local text = "[E] لتصليح السيارة"
    if stationName then
        text = "[E] " .. stationName
    end
    
    local textWidth = dxGetTextWidth(text, 1, dxfont_small)
    local width = textWidth + (settings.interaction.padding * 2)
    local height = settings.interaction.height
    local x = (screenW - width) / 2
    local y = screenH - settings.interaction.yPosition
    
    -- خلفية الرسالة
    dxDrawRectangle(x, y, width, height, tocolor(colors.background[1], colors.background[2], colors.background[3], 200))
    
    -- الخط العلوي
    dxDrawRectangle(x, y, width, 2, tocolor(colors.primary[1], colors.primary[2], colors.primary[3], 255))
    
    -- النص
    dxDrawText(text, x, y, x + width, y + height, 
              tocolor(colors.text[1], colors.text[2], colors.text[3], 255), 1, dxfont_small, "center", "center")
end

function drawRepairProgress()
    local width = settings.repairWindow.width
    local height = settings.repairWindow.height
    local x = (screenW - width) / 2
    local y = screenH - settings.repairWindow.yPosition
    
    -- خلفية النافذة
    dxDrawRectangle(x, y, width, height, tocolor(colors.background[1], colors.background[2], colors.background[3], 220))
    
    -- الحدود
    dxDrawRectangle(x, y, width, 3, tocolor(colors.primary[1], colors.primary[2], colors.primary[3], 255))
    dxDrawRectangle(x, y + height - 3, width, 3, tocolor(colors.primary[1], colors.primary[2], colors.primary[3], 255))
    
    -- العنوان
    dxDrawText("جاري تصليح السيارة", x, y + 10, x + width, y + 30, 
              tocolor(colors.text[1], colors.text[2], colors.text[3], 255), 1, dxfont_small, "center", "center")
    
    -- شريط التقدم
    local progressWidth = (width - 40) * (repairProgress / 100)
    dxDrawRectangle(x + 20, y + 35, width - 40, settings.repairWindow.barHeight, tocolor(colors.dark[1], colors.dark[2], colors.dark[3], 255))
    dxDrawRectangle(x + 20, y + 35, progressWidth, settings.repairWindow.barHeight, tocolor(colors.primary[1], colors.primary[2], colors.primary[3], 255))
    
    -- النسبة المئوية
    dxDrawText(math.floor(repairProgress) .. "%", x + 20, y + 35, x + width - 20, y + 35 + settings.repairWindow.barHeight, 
              tocolor(colors.text[1], colors.text[2], colors.text[3], 255), 1, dxfont_small, "center", "center")
    
    -- التكلفة
    dxDrawText("التكلفة: $" .. repairCost, x, y + 65, x + width, y + height, 
              tocolor(200, 200, 200, 255), 0.9, dxfont_small, "center", "center")
end

-- ========== الدوال المساعدة ==========
function getNearbyRepairStation(vehicle)
    local px, py, pz = getElementPosition(vehicle)
    
    for i, station in ipairs(repairStations) do
        local distance = getDistanceBetweenPoints3D(px, py, pz, station.x, station.y, station.z)
        
        if distance <= station.radius then
            return station
        end
    end
    
    return nil
end

function calculateRepairCost(vehicleHealth)
    local repairNeeded = 1000 - vehicleHealth
    local cost = math.floor((repairNeeded / 10) * settings.repair.costPerPercent)
    return math.max(settings.repair.minCost, cost)
end

-- ========== نظام التصليح ==========
function startRepairProcess()
    if isRepairing then return end
    
    local playerVehicle = getPedOccupiedVehicle(localPlayer)
    if not playerVehicle or getVehicleOccupant(playerVehicle, 0) ~= localPlayer then return end
    
    -- التحقق من الموقع
    currentStation = getNearbyRepairStation(playerVehicle)
    if not currentStation then return end
    
    -- حساب تكلفة التصليح
    local vehicleHealth = getElementHealth(playerVehicle)
    
    if vehicleHealth >= 1000 then
        showToast("سيارتك لا تحتاج إلى تصليح", false)
        return
    end
    
    repairCost = calculateRepairCost(vehicleHealth)
    
    -- بدء عملية التصليح
    isRepairing = true
    repairProgress = 0
    repairVehicle = playerVehicle
    
    -- إشعار البدء
    showToast("بدأت عملية التصليح - التكلفة: $" .. repairCost, false)
    
    -- بدء التصليح التدريجي
    setTimer(updateRepairProgress, 100, 0)
end

function updateRepairProgress()
    if not isRepairing or not repairVehicle or not isElement(repairVehicle) then
        stopRepairProcess()
        return
    end
    
    -- التحقق من أن اللاعب لا يزال في السيارة وفي المحطة
    local playerVehicle = getPedOccupiedVehicle(localPlayer)
    if playerVehicle ~= repairVehicle or getVehicleOccupant(repairVehicle, 0) ~= localPlayer then
        showToast("❌ تم إيقاف التصليح - يجب البقاء في السيارة", true)
        stopRepairProcess()
        return
    end
    
    -- التحقق من الموقع
    if not getNearbyRepairStation(repairVehicle) then
        showToast("❌ تم إيقاف التصليح - ابتعدت عن محطة التصليح", true)
        stopRepairProcess()
        return
    end
    
    -- زيادة التقدم
    repairProgress = repairProgress + settings.repair.repairSpeed
    
    if repairProgress >= 100 then
        -- إنهاء التصليح
        triggerServerEvent("completeVehicleRepair", localPlayer, repairVehicle, repairCost)
        stopRepairProcess()
        showToast("✅ تم تصليح سيارتك بنجاح!", false)
    else
        -- تحديث صحة السيارة تدريجياً
        local currentHealth = getElementHealth(repairVehicle)
        local newHealth = currentHealth + ((1000 - currentHealth) * 0.02)
        setElementHealth(repairVehicle, math.min(1000, newHealth))
    end
end

function stopRepairProcess()
    isRepairing = false
    repairProgress = 0
    repairCost = 0
    repairVehicle = nil
    currentStation = nil
end

-- ========== الأحداث ==========
bindKey("e", "down", function()
    if getElementData(localPlayer, "loggedin") ~= 1 then return end
    
    local playerVehicle = getPedOccupiedVehicle(localPlayer)
    if not playerVehicle or getVehicleOccupant(playerVehicle, 0) ~= localPlayer then return end
    
    if getNearbyRepairStation(playerVehicle) and not isRepairing then
        startRepairProcess()
    end
end)

bindKey("f2", "down", function()
    if getElementData(localPlayer, "loggedin") ~= 1 then return end
    
    local playerVehicle = getPedOccupiedVehicle(localPlayer)
    if not playerVehicle or getVehicleOccupant(playerVehicle, 0) ~= localPlayer then return end
    
    local station = getNearbyRepairStation(playerVehicle)
    if station then
        local vehicleHealth = getElementHealth(playerVehicle)
        local cost = calculateRepairCost(vehicleHealth)
        
        if cost > 0 then
            showToast("صحة السيارة: " .. math.floor(vehicleHealth/10) .. "% - التكلفة: $" .. cost, false)
        else
            showToast("سيارتك لا تحتاج إلى تصليح", false)
        end
    end
end)

-- إيقاف التصليح إذا تحركت السيارة
addEventHandler("onClientVehicleStartExit", root, function(player)
    if player == localPlayer and isRepairing then
        showToast("❌ تم إيقاف التصليح بسبب تحرك السيارة", true)
        stopRepairProcess()
    end
end)

addEventHandler("onClientVehicleStartEnter", root, function(player, seat)
    if player == localPlayer and seat == 0 and isRepairing then
        showToast("❌ تم إيقاف التصليح", true)
        stopRepairProcess()
    end
end)

-- ========== إضافة محطات تصليح جديدة ==========
function addRepairStation(x, y, z, radius, name)
    table.insert(repairStations, {
        x = x,
        y = y, 
        z = z,
        radius = radius or 5,
        name = name or "محطة التصليح"
    })
    outputDebugString("تم إضافة محطة تصليح جديدة: " .. (name or "محطة التصليح"))
end

-- مثال لإضافة محطات من الكونسول
addCommandHandler("addrepair", function(player, cmd, x, y, z, radius, ...)
    if exports.integration:isPlayerAdmin(player) then
        local name = table.concat({...}, " ")
        addRepairStation(tonumber(x), tonumber(y), tonumber(z), tonumber(radius), name)
        outputChatBox("تم إضافة محطة تصليح جديدة: " .. name, player, 0, 255, 0)
    end
end)
-- حدث لتحديث محطات التصليح من السيرفر
addEvent("onRepairStationsUpdated", true)
addEventHandler("onRepairStationsUpdated", resourceRoot, function(newStations)
    repairStations = newStations
    outputDebugString("✅ تم تحديث محطات التصليح: " .. #repairStations .. " محطة")
end)