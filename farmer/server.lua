local JOB_PICKUP = { x = -1184.3122558594, y = -1136.91015625, z = 129.21875 }
local FARM_CENTER = { x = -1087.1124267578, y = -988.70538330078, z = 129.21875 }
local FARM_RADIUS = 100
local SELL_POS = { x = -1733.5043945312, y = 187.78205871582, z = 3.5546875 }

local FARM_SKIN = 158
local MAX_GLOBAL_PLANTS = 50

-- مراحل النمو
local PLANT_STAGES = {
    { model = 692, time = 40000 },   -- المرحلة الأولى: 40 ثانية
    { model = 877, time = 40000 },   -- المرحلة الثانية: 40 ثانية  
    { model = 878, time = 40000 },   -- المرحلة الثالثة: 40 ثانية
    { model = 878, time = 0, scale = 0.8 } -- المرحلة النهائية (جاهز للحصاد)
}

local plantedObjects = {}
local playerSellTimers = {}

local function countGlobalPlants()
    local c = 0
    for obj,_ in pairs(plantedObjects) do
        if isElement(obj) then c = c + 1 end
    end
    return c
end

-- إضافة دالة لحساب الوقت المتبقي لكل نبتة
local function updatePlantTimeLeft()
    for obj, data in pairs(plantedObjects) do
        if isElement(obj) and data.currentTimer and isTimer(data.currentTimer) then
            local timeLeft = getTimerDetails(data.currentTimer)
            if timeLeft then
                setElementData(obj, "timeLeft", timeLeft + ((#PLANT_STAGES - data.currentStage - 1) * 40000))
            end
        elseif isElement(obj) and data.ready then
            setElementData(obj, "timeLeft", 0) -- جاهز للحصاد
        end
    end
end

-- تحديث الوقت كل ثانية
setTimer(updatePlantTimeLeft, 1000, 0)

addEventHandler("onPlayerJoin", root, function()
    setElementData(source, "farmer_job", false)
    setElementData(source, "farmer_boxes", 0)
    setElementData(source, "farmer_seeds", 0)
    setElementData(source, "farmer_harvest", 0)

    triggerClientEvent(source, "client_updateFarmerHUD", source)
    triggerClientEvent(source, "updateFarmerJobStatus", source, false)
end)

local function givePlayerMoneySafe(player, amount)
    if not isElement(player) or not tonumber(amount) then return end
    if getPlayerMoney and setPlayerMoney then
        setPlayerMoney(player, getPlayerMoney(player) + amount)
    end
end

addEvent("server_toggleFarmerJob", true)
addEventHandler("server_toggleFarmerJob", root, function()
    local player = source
    local isFarmer = getElementData(player, "farmer_job")
    if isFarmer then
        setElementData(player, "farmer_job", false)
        local oldSkin = getElementData(player, "farmer_oldSkin") or 0
        setElementModel(player, oldSkin)
        setElementData(player, "farmer_oldSkin", nil)
        outputChatBox("✖️ تركت وظيفة المزارع.", player, 255, 100, 100)
        if playerSellTimers[player] then
            killTimer(playerSellTimers[player])
            playerSellTimers[player] = nil
        end
        triggerClientEvent(player, "updateFarmerJobStatus", player, false)
    else
        setElementData(player, "farmer_oldSkin", getElementModel(player))
        setElementData(player, "farmer_job", true)
        setElementModel(player, FARM_SKIN)
        outputChatBox("✔️ استلمت وظيفة المزارع.", player, 100, 255, 100)
        triggerClientEvent(player, "updateFarmerJobStatus", player, true)
    end
    triggerClientEvent(player, "client_updateFarmerHUD", player)
end)

addCommandHandler("buybox", function(player)
    local boxes = getElementData(player, "farmer_boxes") or 0
    setElementData(player, "farmer_boxes", boxes + 1)
    outputChatBox("📦 حصلت على صندوق بذور، افتحه بزر (O).", player, 200, 255, 200)
    triggerClientEvent(player, "client_updateFarmerHUD", player)
end)

addCommandHandler("giveseed", function(player, cmd, amount)
    local num = tonumber(amount) or 1
    if num < 1 then num = 1 end
    local seeds = getElementData(player, "farmer_seeds") or 0
    setElementData(player, "farmer_seeds", seeds + num)
    outputChatBox("🌱 استلمت " .. num .. " بذور.", player, 100, 255, 100)
    triggerClientEvent(player, "client_updateFarmerHUD", player)
end)

addEvent("server_openBoxSeed", true)
addEventHandler("server_openBoxSeed", root, function()
    local player = source
    local boxes = getElementData(player, "farmer_boxes") or 0
    if boxes <= 0 then
        outputChatBox("❌ لا يوجد صندوق بذور لفتحه.", player, 255, 100, 100)
        return
    end

    local seeds = getElementData(player, "farmer_seeds") or 0
    local extracted = getElementData(player, "farmer_box_extracted") or 0
    extracted = extracted + 1
    seeds = seeds + 1

    setElementData(player, "farmer_seeds", seeds)
    setElementData(player, "farmer_box_extracted", extracted)

    outputChatBox("🌾 حصلت على بذرة من الصندوق. ("..extracted.."/5)", player, 200, 255, 200)
    if extracted >= 5 then
        setElementData(player, "farmer_boxes", boxes - 1)
        setElementData(player, "farmer_box_extracted", 0)
        outputChatBox("📦 انتهى الصندوق وتمت إزالته.", player, 255, 200, 0)
    end
    triggerClientEvent(player, "client_updateFarmerHUD", player)
end)

-- دالة لتحديث مرحلة النمو
local function updatePlantStage(obj, stageIndex)
    if not isElement(obj) then return end
    
    local data = plantedObjects[obj]
    if not data then return end
    
    local stage = PLANT_STAGES[stageIndex]
    if not stage then return end
    
    -- تغيير نموذج النبات
    setElementModel(obj, stage.model)
    
    -- تطبيق الحجم إذا محدد
    if stage.scale then
        setObjectScale(obj, stage.scale)
    end
    
    -- تحديث بيانات النبات
    data.currentStage = stageIndex
    setElementData(obj, "currentStage", stageIndex)
    setElementData(obj, "totalStages", #PLANT_STAGES)
    
    -- إذا كانت هذه آخر مرحلة
    if stageIndex == #PLANT_STAGES then
        data.ready = true
        setElementData(obj, "ready", true)
        setElementData(obj, "timeLeft", 0)
        
        local owner = data.plantedBy
        if isElement(owner) then
            outputChatBox("🌿 زرعتك نضجت!", owner, 200, 255, 200)
            triggerClientEvent(owner, "client_updateFarmerHUD", owner)
        end
    else
        -- الانتقال للمرحلة التالية
        local nextStage = stageIndex + 1
        data.currentTimer = setTimer(function()
            updatePlantStage(obj, nextStage)
        end, stage.time, 1)
    end
end

addEvent("server_plantSeed", true)
addEventHandler("server_plantSeed", root, function(px, py, pz)
    local player = source
    if not getElementData(player, "farmer_job") then
        outputChatBox("❌ يجب أن تكون موظف مزارع.", player, 255, 100, 100)
        return
    end
    local seeds = getElementData(player, "farmer_seeds") or 0
    if seeds <= 0 then
        outputChatBox("❌ لا تملك بذور.", player, 255, 100, 100)
        return
    end

    local dx, dy = px - FARM_CENTER.x, py - FARM_CENTER.y
    if math.sqrt(dx*dx + dy*dy) > FARM_RADIUS then
        outputChatBox("❌ أنت خارج منطقة الزراعة.", player, 255, 100, 100)
        return
    end

    if countGlobalPlants() >= MAX_GLOBAL_PLANTS then
        outputChatBox("❌ وصلت الحد الأقصى من الزراعة.", player, 255, 100, 100)
        return
    end

    -- إنشاء النبات بالمرحلة الأولى
    local obj = createObject(PLANT_STAGES[1].model, px, py, pz - 0.8)
    local totalGrowTime = 0
    for i = 1, #PLANT_STAGES - 1 do
        totalGrowTime = totalGrowTime + PLANT_STAGES[i].time
    end
    
    setElementData(obj, "plantedBy", player)
    setElementData(obj, "ready", false)
    setElementData(obj, "plantTime", totalGrowTime)
    setElementData(obj, "timeLeft", totalGrowTime)
    setElementData(obj, "currentStage", 1)
    setElementData(obj, "totalStages", #PLANT_STAGES)
    setElementData(obj, "plantName", getPlayerName(player))
    
    plantedObjects[obj] = { 
        plantedBy = player, 
        ready = false,
        plantTime = totalGrowTime,
        currentStage = 1,
        totalStages = #PLANT_STAGES
    }

    setElementData(player, "farmer_seeds", seeds - 1)

    -- بدء المرحلة الأولى
    updatePlantStage(obj, 1)
    
    triggerClientEvent(player, "client_updateFarmerHUD", player)
end)

addEvent("server_harvestPlant", true)
addEventHandler("server_harvestPlant", root, function(obj)
    local player = source
    if not isElement(obj) or not plantedObjects[obj] then
        outputChatBox("❌ ليست نبتة صالحة.", player, 255, 100, 100)
        return
    end
    local data = plantedObjects[obj]
    if not data.ready then
        outputChatBox("❌ ليست جاهزة بعد.", player, 255, 100, 100)
        return
    end
    local px, py, pz = getElementPosition(player)
    local ox, oy, oz = getElementPosition(obj)
    if getDistanceBetweenPoints3D(px, py, pz, ox, oy, oz) > 3 then
        outputChatBox("❌ بعيد عن النبتة.", player, 255, 100, 100)
        return
    end
    if data.plantedBy ~= player then
        outputChatBox("❌ ليست نبتتك.", player, 255, 100, 100)
        return
    end
    if data.currentTimer and isTimer(data.currentTimer) then 
        killTimer(data.currentTimer) 
    end
    if isElement(obj) then destroyElement(obj) end
    plantedObjects[obj] = nil
    setElementData(player, "farmer_harvest", (getElementData(player, "farmer_harvest") or 0) + 1)
    outputChatBox("✅ تم الحصاد.", player, 200, 255, 200)
    triggerClientEvent(player, "client_updateFarmerHUD", player)
end)

addEvent("server_startSelling", true)
addEventHandler("server_startSelling", root, function()
    local player = source
    if not getElementData(player, "farmer_job") then
        outputChatBox("❌ يجب أن تكون مزارع لتبيع.", player, 255, 100, 100)
        return
    end

    local harvested = getElementData(player, "farmer_harvest") or 0
    if harvested <= 0 then
        outputChatBox("❌ لا يوجد لديك محصول.", player, 255, 100, 100)
        return
    end

    if playerSellTimers[player] then
        outputChatBox("⏳ أنت تبيع بالفعل.", player, 200, 200, 0)
        return
    end

    outputChatBox("🟢 بدء البيع...", player, 200, 255, 200)
    playerSellTimers[player] = setTimer(function()
        if not isElement(player) then return end
        local curHarvest = getElementData(player, "farmer_harvest") or 0
        if curHarvest <= 0 then
            outputChatBox("✅ انتهى البيع.", player, 200, 255, 200)
            killTimer(playerSellTimers[player])
            playerSellTimers[player] = nil
            return
        end
        givePlayerMoneySafe(player, 350)
        setElementData(player, "farmer_harvest", curHarvest - 1)
        outputChatBox("💰 بعت محصول بـ $350", player, 200, 255, 200)
        triggerClientEvent(player, "client_updateFarmerHUD", player)
    end, 1000, 0)
end)

addEvent("server_cancelSelling", true)
addEventHandler("server_cancelSelling", root, function()
    local player = source
    if playerSellTimers[player] then
        killTimer(playerSellTimers[player])
        playerSellTimers[player] = nil
        outputChatBox("⏹️ تم إيقاف البيع.", player, 255, 200, 0)
    end
end)

addEventHandler("onElementDestroy", root, function()
    if plantedObjects[source] then
        if plantedObjects[source].currentTimer and isTimer(plantedObjects[source].currentTimer) then 
            killTimer(plantedObjects[source].currentTimer) 
        end
        plantedObjects[source] = nil
    end
end)

addEvent("server_requestHUD", true)
addEventHandler("server_requestHUD", root, function()
    triggerClientEvent(source, "client_updateFarmerHUD", source)
end)

addEventHandler("onPlayerQuit", root, function()
    if playerSellTimers[source] then
        killTimer(playerSellTimers[source])
        playerSellTimers[source] = nil
    end
end)