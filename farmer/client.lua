--==================================================
-- MTA:SA Farmer Job - Client Side
-- Author: NaderBasha & GPT
--==================================================

local JOB_PICKUP = { x = -1184.3122558594, y = -1136.91015625, z = 129.21875 }
local FARM_CENTER = { x = -1087.1124267578, y = -988.70538330078, z = 129.21875 }
local FARM_RADIUS = 100 -- تم التوسيع من 80 إلى 100
local SELL_POS = { x = -1733.5043945312, y = 187.78205871582, z = 3.5546875 }

local hud = {
    boxes = 0,
    seeds = 0,
    harvest = 0,
    unreadyPlants = 0,
    readyPlants = 0,
    isFarmer = false
}

local selling = false
local lastLookedAtPlant = nil

-- إنشاء NPC عند نقطة استلام الوظيفة
local function createJobNPC()
    local jobNPC = createPed(158, JOB_PICKUP.x, JOB_PICKUP.y, JOB_PICKUP.z, 90)
    if jobNPC then
        setElementFrozen(jobNPC, true)
        setElementData(jobNPC, "name", "مسؤول توظيف المزارعين")
        outputDebugString("✅ NPC created successfully")
    else
        outputDebugString("❌ Failed to create NPC")
    end
end

-- إنشاء الـ NPC عند بدء السكربت
addEventHandler("onClientResourceStart", resourceRoot, function()
    createJobNPC()
    setTimer(function()
        triggerServerEvent("server_requestHUD", localPlayer)
    end, 2000, 1)
end)

-------------------------------------------------
-- Job status updates from server
-------------------------------------------------
addEvent("updateFarmerJobStatus", true)
addEventHandler("updateFarmerJobStatus", root, function(state)
    hud.isFarmer = state and true or false
    setElementData(localPlayer, "farmer_job", hud.isFarmer, false)
    triggerServerEvent("server_requestHUD", localPlayer)
    outputChatBox(hud.isFarmer and "✅ أصبحت مزارعاً الآن!" or "❌ تركت وظيفة المزارع", hud.isFarmer and 0 or 255, hud.isFarmer and 255 or 0, 0)
end)

-------------------------------------------------
-- FARM LOGIC
-------------------------------------------------
local function inFarmArea(x, y)
    local dx, dy = x - FARM_CENTER.x, y - FARM_CENTER.y
    return math.sqrt(dx*dx + dy*dy) <= FARM_RADIUS
end

-------------------------------------------------
-- HUD DRAW - تظهر فقط في منطقة الزراعة
-------------------------------------------------
addEventHandler("onClientRender", root, function()
    local px, py, pz = getElementPosition(localPlayer)
    local inFarmZone = inFarmArea(px, py)
    
    -- إذا كان خارج منطقة الزراعة، لا تعرض HUD الوظيفة
    if not inFarmZone then return end
    
    local sx, sy = guiGetScreenSize()
    local x = sx * 0.02  -- 2% من الشاشة من الشمال (على اليسار)
    local y = sy * 0.4   -- 40% من الشاشة من الأعلى (منتصف الشمال)
    local w = 380
    local h = 160

    dxDrawRectangle(x, y, w, h, tocolor(0, 0, 0, 180))
    dxDrawRectangle(x+2, y+2, w-4, 30, tocolor(14, 15, 15, 180))
    dxDrawText("📋تفاصيل المُزارع", x, y, x+w, y+30, tocolor(8, 168, 80), 1.1, "default-bold", "center", "center")

    local startY = y + 38
    dxDrawText("الوظيفة: "..(hud.isFarmer and "مزارع ✅" or "غير متوظف ❌"), x+10, startY, x+w, startY+18, tocolor(255,255,255), 1, "default-bold", "left", "top")

    dxDrawText("📦 صناديق: "..hud.boxes.."   🌱 بذور: "..hud.seeds.."   🥬 محصول: "..hud.harvest,
        x+10, startY+20, x+w, startY+36, tocolor(8, 168, 80), 1.0, "default", "left", "top")

    dxDrawText("🌿 جاهز للحصاد: "..hud.readyPlants.."   ⏳ لم يجهز بعد: "..hud.unreadyPlants,
        x+10, startY+40, x+w, startY+56, tocolor(8, 168, 80), 1.0, "default", "left", "top")

    if hud.isFarmer then
        dxDrawText("اضغط H: زرع/حصاد - اضغط O لفتح الصناديق", x+10, startY+65, x+w, startY+80, tocolor(200,255,200), 1.0, "default", "left", "top")
        dxDrawText("اذهب لنقطة البيع لبيع المحصول", x+10, startY+83, x+w, startY+100, tocolor(190,255,190), 1.0, "default", "left", "top")
    else
        dxDrawText("❌ انتقل لنقطة التوظيف واستلم الوظيفة أولاً", x+10, startY+65, x+w, startY+80, tocolor(255,200,200), 1.0, "default", "left", "top")
    end
end)

-------------------------------------------------
-- Update HUD data from server
-------------------------------------------------
addEvent("client_updateFarmerHUD", true)
addEventHandler("client_updateFarmerHUD", root, function()
    hud.boxes   = getElementData(localPlayer, "farmer_boxes") or 0
    hud.seeds   = getElementData(localPlayer, "farmer_seeds") or 0
    hud.harvest = getElementData(localPlayer, "farmer_harvest") or 0
    hud.isFarmer = getElementData(localPlayer, "farmer_job") or false

    -- Count plants nearby
    local ready, unready = 0, 0
    for _, obj in ipairs(getElementsByType("object")) do
        if getElementData(obj, "ready") ~= nil then
            local ox, oy, oz = getElementPosition(obj)
            local px, py, pz = getElementPosition(localPlayer)
            if getDistanceBetweenPoints3D(px, py, pz, ox, oy, oz) < 150 then
                if getElementData(obj, "ready") then
                    ready = ready + 1
                else
                    unready = unready + 1
                end
            end
        end
    end
    hud.readyPlants = ready
    hud.unreadyPlants = unready
end)

bindKey("h", "down", function()
    local px, py, pz = getElementPosition(localPlayer)
    local distJob = getDistanceBetweenPoints3D(px, py, pz, JOB_PICKUP.x, JOB_PICKUP.y, JOB_PICKUP.z)
    local distSell = getDistanceBetweenPoints3D(px, py, pz, SELL_POS.x, SELL_POS.y, SELL_POS.z)
    local inFarmZone = inFarmArea(px, py)

    -- Job toggle
    if distJob < 3 then
        triggerServerEvent("server_toggleFarmerJob", localPlayer)
        return
    end

    -- Not a farmer - تظهر الرسالة فقط في منطقة الزراعة
    if not hud.isFarmer then
        if inFarmZone then
            outputChatBox("❌ أنت لست مزارع. اذهب لنقطة التوظيف أولاً.", 255, 100, 100)
        end
        return
    end

    -- إذا كان خارج منطقة الزراعة ولا يضغط على نقاط محددة، لا تفعل شيء
    if not inFarmZone and distJob >= 3 and distSell >= 5 then
        return
    end

    -- Harvest if near ready plant
    for _, obj in ipairs(getElementsByType("object")) do
        if getElementData(obj, "ready") then
            local ox, oy, oz = getElementPosition(obj)
            if getDistanceBetweenPoints3D(px, py, pz, ox, oy, oz) < 3 then
                setPedAnimation(localPlayer, "BOMBER", "BOM_Plant_Crouch_Out", 2000, false, false, false)
                setTimer(function()
                    triggerServerEvent("server_harvestPlant", localPlayer, obj)
                    setPedAnimation(localPlayer)
                end, 2000, 1)
                return
            end
        end
    end

    -- Plant seed
    if inFarmZone then
        local seeds = getElementData(localPlayer, "farmer_seeds") or 0
        if seeds > 0 then
            setPedAnimation(localPlayer, "BOMBER", "BOM_Plant", 2000, false, false, false)
            setTimer(function()
                triggerServerEvent("server_plantSeed", localPlayer, px, py, pz)
                setPedAnimation(localPlayer)
            end, 2000, 1)
        else
            outputChatBox("❌ لا تملك بذور. افتح الصناديق بزر O", 255, 80, 80)
        end
        return
    end

    -- Sell crops
    if distSell < 5 then
        triggerServerEvent("server_startSelling", localPlayer)
        return
    end
end)

-- Key O: open seed box
bindKey("o", "down", function()
    if not hud.isFarmer then
        outputChatBox("❌ يجب أن تكون مزارعاً لفتح الصناديق", 255, 100, 100)
        return
    end
    triggerServerEvent("server_openBoxSeed", localPlayer)
end)

-- Key C: cancel selling
bindKey("c", "down", function()
    triggerServerEvent("server_cancelSelling", localPlayer)
end)

-------------------------------------------------
-- عرض الوقت المتبقي فوق النباتات
-------------------------------------------------
addEventHandler("onClientRender", root, function()
    if not hud.isFarmer then return end
    
    local px, py, pz = getElementPosition(localPlayer)
    
    for _, obj in ipairs(getElementsByType("object")) do
        if getElementData(obj, "plantedBy") then
            local ox, oy, oz = getElementPosition(obj)
            local distance = getDistanceBetweenPoints3D(px, py, pz, ox, oy, oz)
            
            if distance < 30 then
                local sx, sy = getScreenFromWorldPosition(ox, oy, oz + 2.5)
                if sx and sy then
                    local ready = getElementData(obj, "ready") or false
                    local timeLeft = getElementData(obj, "timeLeft") or 0
                    local plantedBy = getElementData(obj, "plantedBy")
                    local isMyPlant = (plantedBy == localPlayer)
                    local currentStage = getElementData(obj, "currentStage") or 1
                    local totalStages = getElementData(obj, "totalStages") or 4
                    
                    if ready then
                        dxDrawText("✅ جاهز للحصاد", sx-80, sy-30, sx+80, sy+10, tocolor(100, 255, 100, 255), 1.2, "default-bold", "center", "center")
                        if isMyPlant then
                            dxDrawText("🌿 نبتتك - اضغط H لحصادها", sx-100, sy-10, sx+100, sy+30, tocolor(255, 255, 100, 255), 1, "default", "center", "center")
                        end
                    else
                        local minutes = math.floor(timeLeft / 60000)
                        local seconds = math.floor((timeLeft % 60000) / 1000)
                        local timeText = string.format("⏳ %02d:%02d", minutes, seconds)
                        local stageText = string.format("المرحلة: %d/%d", currentStage, totalStages)
                        
                        dxDrawText(timeText, sx-60, sy-40, sx+60, sy-10, tocolor(255, 200, 100, 255), 1.2, "default-bold", "center", "center")
                        dxDrawText(stageText, sx-60, sy-20, sx+60, sy+10, tocolor(200, 230, 255, 255), 1, "default", "center", "center")
                        
                        if isMyPlant then
                            dxDrawText("🌱 نبتتك - تنتظر النضج", sx-80, sy-5, sx+80, sy+25, tocolor(200, 200, 255, 255), 0.9, "default", "center", "center")
                        else
                            local planterName = getElementData(obj, "plantName") or "لاعب"
                            dxDrawText("👤 زرعها: "..planterName, sx-80, sy-5, sx+80, sy+25, tocolor(200, 200, 200, 255), 0.8, "default", "center", "center")
                        end
                    end
                end
            end
        end
    end
end)

-------------------------------------------------
-- Draw markers & text hints
-------------------------------------------------
addEventHandler("onClientRender", root, function()
    local px, py, pz = getElementPosition(localPlayer)

    -- Job pickup مع NPC
    local distJ = getDistanceBetweenPoints3D(px, py, pz, JOB_PICKUP.x, JOB_PICKUP.y, JOB_PICKUP.z)
    if distJ < 20 then
        local sx, sy = getScreenFromWorldPosition(JOB_PICKUP.x, JOB_PICKUP.y, JOB_PICKUP.z + 2.2)
        if sx and sy then
            dxDrawText("👨‍🌾 توظيف المزارعين", sx-100, sy-50, sx+100, sy-30, tocolor(255,255,255,255), 1.2, "default-bold", "center", "center")
            dxDrawText("وظيفة المزارع - راتب مجزي", sx-100, sy-25, sx+100, sy-5, tocolor(200,255,200,255), 1, "default", "center", "center")
            dxDrawText("اضغط H لاستلام/ترك الوظيفة", sx-100, sy-0, sx+100, sy+20, tocolor(255,255,255,255), 1, "default-bold", "center", "center")
        end
        drawMarker(1, JOB_PICKUP.x, JOB_PICKUP.y, JOB_PICKUP.z - 1, 0,0,0, 0,0,0, 1.5,1.5,1.5, 0, 120, 255, 150)
    end

    -- Sell spot مع علامة واضحة + علامة خضراء
    local distS = getDistanceBetweenPoints3D(px, py, pz, SELL_POS.x, SELL_POS.y, SELL_POS.z)
    if distS < 20 then
        local sx, sy = getScreenFromWorldPosition(SELL_POS.x, SELL_POS.y, SELL_POS.z + 2.2)
        if sx and sy then
            dxDrawText("💰 بيع المحصول", sx-80, sy-50, sx+80, sy-30, tocolor(255,255,255,255), 1.2, "default-bold", "center", "center")
            dxDrawText("$350 لكل محصول", sx-80, sy-25, sx+80, sy-5, tocolor(200,255,200,255), 1, "default", "center", "center")
            dxDrawText("اضغط H للبدء في البيع", sx-80, sy-0, sx+80, sy+20, tocolor(255,255,255,255), 1, "default-bold", "center", "center")
        end
        -- علامة بيع واضحة + علامة خضراء
        drawMarker(0, SELL_POS.x, SELL_POS.y, SELL_POS.z, 0,0,0, 0,0,0, 3.0,3.0,3.0, 255,100,100,200)
        drawMarker(1, SELL_POS.x, SELL_POS.y, SELL_POS.z - 0.5, 0,0,0, 0,0,0, 2.5,2.5,2.5, 255,50,50,150)
        -- علامة خضراء مكان البيع
        drawMarker(2, SELL_POS.x, SELL_POS.y, SELL_POS.z - 0.3, 0,0,0, 0,0,0, 1.5,1.5,1.5, 0,255,0,180)
    end

    -- Farm zone circle
    local distF = getDistanceBetweenPoints3D(px, py, pz, FARM_CENTER.x, FARM_CENTER.y, FARM_CENTER.z)
    if distF < 150 then
        for a = 0, 360, 12 do
            local rad = math.rad(a)
            local fx = FARM_CENTER.x + math.cos(rad) * FARM_RADIUS
            local fy = FARM_CENTER.y + math.sin(rad) * FARM_RADIUS
            drawMarker(2, fx, fy, FARM_CENTER.z - 0.9, 0,0,0, 0,0,0, 0.8,0.8,0.8, 0,200,0,80)
        end
    end
end)

-------------------------------------------------
-- تحديث بيانات النباتات بشكل دوري
-------------------------------------------------
setTimer(function()
    if hud.isFarmer then
        triggerServerEvent("server_requestHUD", localPlayer)
    end
end, 2000, 0)