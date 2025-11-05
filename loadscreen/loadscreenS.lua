-- server.lua - إصدار محسن
local playerLoadingStates = {}
local RESOURCE_LOAD_TIME = 10000 -- 10 ثواني للتحميل

function startPlayerLoading(player)
    if not isElement(player) then return false end
    
    playerLoadingStates[player] = { 
        progress = 0, 
        isActive = true,
        startTime = getTickCount(),
        resourcesLoaded = 0,
        totalResources = 0
    }
    
    triggerClientEvent(player, "startLoadingScreen", player)
    outputDebugString("[LOADING] بدء التحميل للاعب: " .. getPlayerName(player))
    
    -- بدء عملية التحميل الحقيقية
    startResourceLoading(player)
    return true
end

function startResourceLoading(player)
    if not isElement(player) or not playerLoadingStates[player] then return end
    
    -- محاكاة تحميل الموارد مع تقدم حقيقي
    local stages = {
        {progress = 10, message = "جاري تحميل البيانات الأساسية..."},
        {progress = 25, message = "جاري تحميل النماذج..."},
        {progress = 40, message = "جاري تحميل القوام..."},
        {progress = 55, message = "جاري تحميل السيارات..."},
        {progress = 70, message = "جاري تحميل الخرائط..."},
        {progress = 85, message = "جاري التهيئة النهائية..."},
        {progress = 100, message = "اكتمل التحميل!"}
    }
    
    for i, stage in ipairs(stages) do
        setTimer(function()
            if isElement(player) and playerLoadingStates[player] then
                updatePlayerLoading(player, stage.progress)
                outputDebugString("[LOADING] " .. stage.message .. " (" .. stage.progress .. "%) - " .. getPlayerName(player))
                
                if stage.progress == 100 then
                    setTimer(function()
                        if isElement(player) and playerLoadingStates[player] then
                            finishPlayerLoading(player)
                        end
                    end, 2000, 1)
                end
            end
        end, (RESOURCE_LOAD_TIME / #stages) * i, 1)
    end
end

function updatePlayerLoading(player, progress)
    if not isElement(player) or not playerLoadingStates[player] then return false end
    playerLoadingStates[player].progress = math.max(0, math.min(100, progress))
    triggerClientEvent(player, "updateLoadingProgress", player, progress)
    return true
end

function finishPlayerLoading(player)
    if not isElement(player) or not playerLoadingStates[player] then return false end
    playerLoadingStates[player].isActive = false
    triggerClientEvent(player, "finishLoadingScreen", player)
    
    local loadTime = (getTickCount() - playerLoadingStates[player].startTime) / 1000
    outputDebugString("[LOADING] اكتمل تحميل الموارد للاعب: " .. getPlayerName(player) .. " - الوقت: " .. loadTime .. " ثانية")
    
    -- إرسال رسالة ترحيب
   -- outputChatBox("#FFD700🎉 مرحباً بك في سيرفر بارادايس! #FFFFFFتم تحميل جميع الموارد بنجاح", player, 255, 255, 255, true)
    
    return true
end

-- ==================== الأحداث الأساسية ====================

addEventHandler("onPlayerJoin", root, function()
    outputDebugString("[LOADING] لاعب انضم: " .. getPlayerName(source))
    
    -- انتظر قليلاً قبل بدء التحميل
    setTimer(function()
        if isElement(source) then
            startPlayerLoading(source)
        end
    end, 1000, 1)
end)

addEventHandler("onPlayerQuit", root, function()
    if playerLoadingStates[source] then
        playerLoadingStates[source] = nil
    end
end)


-- تشغيل للاعبين الموجودين عند restart
addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[LOADSCREEN] ✅ تم تحميل سكربت Loading Screen بنجاح!")
    
    -- إعادة تحميل الواجهة للاعبين الموجودين
    for i, player in ipairs(getElementsByType("player")) do
        setTimer(function()
            if isElement(player) then
                startPlayerLoading(player)
            end
        end, 2000, 1)
    end
end)

addEventHandler("onResourceStop", resourceRoot, function()
    for player, state in pairs(playerLoadingStates) do
        if isElement(player) then
            triggerClientEvent(player, "finishLoadingScreen", player)
        end
    end
    playerLoadingStates = {}
end)