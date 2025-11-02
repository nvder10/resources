--/Nadoory-->

-- نظام تصليح السيارات الأوتوماتيكي
local repairStations = {
    -- محطة التصليح الرئيسية
    {
        x = 2063.6948242188, 
        y = -1831.6889648438, 
        z = 13.402562141418, 
        radius = 5,
        name = "محطة التصليح المركزية"
    },
    
    -- محطة تصليح عند المطار
    {
        x = 1574.84, 
        y = -2174.94, 
        z = 13.55, 
        radius = 5,
        name = "محطة تصليح المطار"
    },
    
    -- محطة تصليح عند الداون تاون
    {
        x = 2127.64, 
        y = -1136.63, 
        z = 25.47, 
        radius = 5,
        name = "محطة تصليح الداون تاون"
    }
}

-- إعدادات التصليح
local repairSettings = {
    costPerPercent = 1.5, -- سعر التصليح لكل 1%
    minCost = 150, -- أقل تكلفة للتصليح
    panelCost = 200, -- تكلفة كل جزء تالف
    wheelCost = 250 -- تكلفة كل عجلة تالفة
}

function completeVehicleRepair(vehicle, cost)
    if not client then return end
    
    -- التحقق من أن اللاعب يقود السيارة
    if not isElement(vehicle) or getVehicleOccupant(vehicle, 0) ~= client then
        triggerClientEvent(client, "showRepairToast", resourceRoot, "❌ يجب أن تكون في السيارة لإكمال التصليح", true)
        return false
    end
    
    -- التحقق من الموقع
    local vx, vy, vz = getElementPosition(vehicle)
    local nearStation = false
    local stationName = "محطة التصليح"
    
    for i, station in ipairs(repairStations) do
        local distance = getDistanceBetweenPoints3D(vx, vy, vz, station.x, station.y, station.z)
        
        if distance <= station.radius then
            nearStation = true
            stationName = station.name or "محطة التصليح"
            break
        end
    end
    
    if not nearStation then
        triggerClientEvent(client, "showRepairToast", resourceRoot, "❌ يجب أن تكون في محطة التصليح", true)
        return false
    end
    
    -- التحقق من المال
    if not exports.global:hasMoney(client, cost) then
        triggerClientEvent(client, "showRepairToast", resourceRoot, "❌ لا تملك مالاً كافياً - المطلوب: $" .. cost, true)
        return false
    end
    
    -- خصم المال
    if exports.global:takeMoney(client, cost) then
        -- تصليح السيارة بالكامل
        setElementHealth(vehicle, 1000)
        fixVehicle(vehicle)
        
        -- إعادة تعيين الأضرار المرئية
        setVehicleDamageProof(vehicle, false)
        
        -- إصلاح جميع الأجزاء المرئية
        for i = 0, 6 do
            setVehiclePanelState(vehicle, i, 0)
        end
        
        -- إصلاح العجلات
        for i = 0, 3 do
            setVehicleWheelStates(vehicle, i, 0)
        end
        
        -- إشعار النجاح
        triggerClientEvent(client, "showRepairToast", resourceRoot, "✅ تم تصليح سيارتك بنجاح في " .. stationName .. " - التكلفة: $" .. cost, false)
        
        -- سجل المعاملة
        exports.global:sendMessageToAdmins("[تصليح] " .. getPlayerName(client) .. " قام بتصليح مركبته في " .. stationName .. " بتكلفة $" .. cost)
        
        return true
    else
        triggerClientEvent(client, "showRepairToast", resourceRoot, "❌ فشل في خصم المال", true)
        return false
    end
end
addEvent("completeVehicleRepair", true)
addEventHandler("completeVehicleRepair", root, completeVehicleRepair)

-- حدث لإظهار التوست من السيرفر
addEvent("showRepairToast", true)
addEventHandler("showRepairToast", root, function(message, isError)
    if source then
        triggerClientEvent(source, "showRepairToast", resourceRoot, message, isError)
    end
end)

-- دالة مساعدة لحساب تكلفة التصليح
function calculateRepairCost(vehicle)
    if not isElement(vehicle) then return 0 end
    
    local vehicleHealth = getElementHealth(vehicle)
    local repairNeeded = 1000 - vehicleHealth
    
    -- سعر التصليح الأساسي
    local baseCost = math.floor((repairNeeded / 10) * repairSettings.costPerPercent)
    
    -- إضافة تكلفة إضافية للأضرار المرئية
    local visualDamageCost = 0
    
    -- التحقق من الألواح
    for i = 0, 6 do
        local damage = getVehiclePanelState(vehicle, i)
        if damage > 0 then
            visualDamageCost = visualDamageCost + repairSettings.panelCost
        end
    end
    
    -- التحقق من العجلات
    for i = 0, 3 do
        local damage = getVehicleWheelStates(vehicle, i)
        if damage > 0 then
            visualDamageCost = visualDamageCost + repairSettings.wheelCost
        end
    end
    
    local totalCost = baseCost + visualDamageCost
    
    -- ضمان حد أدنى وأقصى للتكلفة
    totalCost = math.max(repairSettings.minCost, math.min(5000, totalCost))
    
    return totalCost
end

-- أمر لفحص تكلفة التصليح
addCommandHandler("فحص_التصليح", function(player)
    local vehicle = getPedOccupiedVehicle(player)
    if not vehicle or getVehicleOccupant(vehicle, 0) ~= player then
        triggerClientEvent(player, "showRepairToast", resourceRoot, "❌ يجب أن تكون في سيارة لفحص التكلفة", true)
        return
    end
    
    -- التحقق من الموقع
    local vx, vy, vz = getElementPosition(vehicle)
    local nearStation = false
    local stationName = "محطة التصليح"
    
    for i, station in ipairs(repairStations) do
        local distance = getDistanceBetweenPoints3D(vx, vy, vz, station.x, station.y, station.z)
        
        if distance <= station.radius then
            nearStation = true
            stationName = station.name or "محطة التصليح"
            break
        end
    end
    
    if not nearStation then
        triggerClientEvent(player, "showRepairToast", resourceRoot, "❌ يجب أن تكون في محطة تصليح لفحص التكلفة", true)
        return
    end
    
    local cost = calculateRepairCost(vehicle)
    local vehicleHealth = getElementHealth(vehicle)
    
    if cost > 0 then
        local healthPercent = math.floor(vehicleHealth/10)
        local message = "🔧 " .. stationName .. " - صحة السيارة: " .. healthPercent .. "% - التكلفة: $" .. cost
        triggerClientEvent(player, "showRepairToast", resourceRoot, message, false)
    else
        triggerClientEvent(player, "showRepairToast", resourceRoot, "🚗 سيارتك لا تحتاج إلى تصليح", false)
    end
end)

-- إضافة محطات تصليح إضافية
function addRepairStation(x, y, z, radius, name)
    table.insert(repairStations, {
        x = x,
        y = y, 
        z = z,
        radius = radius or 5,
        name = name or "محطة التصليح"
    })
    
    outputDebugString("تم إضافة محطة تصليح جديدة: " .. (name or "محطة التصليح"))
    
    -- مزامنة المحطات الجديدة مع جميع اللاعبين
    for _, player in ipairs(getElementsByType("player")) do
        if getElementData(player, "loggedin") == 1 then
            triggerClientEvent(player, "onRepairStationsUpdated", resourceRoot, repairStations)
        end
    end
end

-- أمر للإدمنز لإضافة محطات تصليح جديدة
addCommandHandler("addrepair", function(player, cmd, x, y, z, radius, ...)
    if exports.integration:isPlayerAdmin(player) then
        local name = table.concat({...}, " ")
        if not x or not y or not z then
            outputChatBox("استخدام: /addrepair [x] [y] [z] [radius] [name]", player, 255, 255, 0)
            return
        end
        
        addRepairStation(tonumber(x), tonumber(y), tonumber(z), tonumber(radius), name)
        outputChatBox("✅ تم إضافة محطة تصليح جديدة: " .. name, player, 0, 255, 0)
        
        -- إعطاء إحداثيات المحطة للاعب
        outputChatBox("الإحداثيات: " .. x .. ", " .. y .. ", " .. z, player, 255, 255, 255)
    else
        outputChatBox("❌ ليس لديك صلاحية لهذا الأمر", player, 255, 0, 0)
    end
end)

-- أمر لعرض جميع محطات التصليح
addCommandHandler("repairstations", function(player)
    if exports.integration:isPlayerAdmin(player) then
        outputChatBox("=== محطات التصليح ===", player, 0, 255, 255)
        for i, station in ipairs(repairStations) do
            outputChatBox(i .. ". " .. (station.name or "محطة التصليح") .. " - " .. station.x .. ", " .. station.y .. ", " .. station.z, player, 255, 255, 255)
        end
    else
        outputChatBox("❌ ليس لديك صلاحية لهذا الأمر", player, 255, 0, 0)
    end
end)

-- حدث لمزامنة محطات التصليح مع اللاعبين الجدد
addEventHandler("onPlayerLogin", root, function()
    setTimer(function(player)
        if isElement(player) and getElementData(player, "loggedin") == 1 then
            triggerClientEvent(player, "onRepairStationsUpdated", resourceRoot, repairStations)
        end
    end, 2000, 1, source)
end)

-- تحميل المحطات عند بدء الريسورس
addEventHandler("onResourceStart", resourceRoot, function()
    -- مزامنة المحطات مع جميع اللاعبين
    for _, player in ipairs(getElementsByType("player")) do
        if getElementData(player, "loggedin") == 1 then
            triggerClientEvent(player, "onRepairStationsUpdated", resourceRoot, repairStations)
        end
    end
    
    outputDebugString("✅ نظام التصليح - تم تحميل " .. #repairStations .. " محطة تصليح")
end)

-- حدث لاستقبال تحديثات المحطات من العميل
addEvent("updateRepairStations", true)
addEventHandler("updateRepairStations", resourceRoot, function(newStations)
    if exports.integration:isPlayerAdmin(client) then
        repairStations = newStations
        outputDebugString("✅ تم تحديث محطات التصليح بواسطة " .. getPlayerName(client))
    end
end)