-- server.lua (paradise_panel)
-- Handles: support messages, admin delivery, player properties

-- قاعدة بيانات وهمية لتخزين بيانات اللاعبين (في الواقع الفعلي ستستخدم قاعدة بيانات حقيقية)
local playerData = {}

-- استقبال رسائل الدعم من اللاعب وإرسالها للإداريين
addEvent("paradise:sendSupport", true)
addEventHandler("paradise:sendSupport", root, function(subject, message)
    local senderName = getPlayerName(source)
    
    -- التحقق من flood protection
    if not canPlayerSendSupport(source) then
        triggerClientEvent(source, "paradise:clientSupportSent", source, 0)
        return
    end
    
    -- التحقق من طول الرسالة
    if #message > 500 then
        triggerClientEvent(source, "paradise:clientSupportSent", source, 0)
        return
    end
    
    -- إرسال لجميع الإداريين
    local sentTo = 0
    for _, p in ipairs(getElementsByType("player")) do
        if getElementData(p, "isAdmin") then
            triggerClientEvent(p, "paradise:adminReceiveSupport", p, senderName, subject, message)
            sentTo = sentTo + 1
        end
    end
    
    -- رد للمرسل
    triggerClientEvent(source, "paradise:clientSupportSent", source, sentTo)
end)

-- دالة الحماية من الإرسال المتكرر
function canPlayerSendSupport(player)
    local lastSupport = getElementData(player, "lastSupportTime") or 0
    local currentTime = getTickCount()
    
    if currentTime - lastSupport < 30000 then -- 30 ثانية بين كل رسالة
        return false
    end
    
    setElementData(player, "lastSupportTime", currentTime)
    return true
end

-- حدث طلب بيانات المركبات المملوكة
addEvent("paradise:getPlayerVehicles", true)
addEventHandler("paradise:getPlayerVehicles", root, function()
    local playerVehicles = getElementData(source, "playerVehicles") or {}
    
    -- إذا لم تكن هناك بيانات، نعيد بيانات افتراضية للاختبار
    if #playerVehicles == 0 then
        playerVehicles = {
            {name = "Infernus", plate = "PARADISE1", health = 95},
            {name = "Sultan", plate = "PARADISE2", health = 85},
        }
        setElementData(source, "playerVehicles", playerVehicles)
    end
    
    triggerClientEvent(source, "paradise:receivePlayerVehicles", source, playerVehicles)
end)

-- حدث طلب بيانات البيوت المملوكة
addEvent("paradise:getPlayerHouses", true)
addEventHandler("paradise:getPlayerHouses", root, function()
    local playerHouses = getElementData(source, "playerHouses") or {}
    
    -- إذا لم تكن هناك بيانات، نعيد بيانات افتراضية للاختبار
    if #playerHouses == 0 then
        playerHouses = {
            {name = "فيلا الجنة", location = "لوس سانتوس", price = 250000},
            {name = "شقة وسط المدينة", location = "وسط المدينة", price = 150000},
        }
        setElementData(source, "playerHouses", playerHouses)
    end
    
    triggerClientEvent(source, "paradise:receivePlayerHouses", source, playerHouses)
end)

-- حدث طلب بيانات اللاعب
addEvent("paradise:getPlayerData", true)
addEventHandler("paradise:getPlayerData", root, function()
    local playerName = getPlayerName(source)
    
    -- إذا لم تكن هناك بيانات مخزنة للاعب، ننشئ بيانات افتراضية
    if not playerData[playerName] then
        playerData[playerName] = {
            playerLevel = 5,
            playerExp = 1250,
            playerMaxExp = 2000,
            playTime = 1500, -- بالدقائق
            joinDate = "2024-01-01",
            completedMissions = 7,
            achievements = {
                ["المبتدئ"] = true,
                ["المتسوق"] = false,
                ["السائق"] = false,
                ["الصياد"] = false,
                ["المليونير"] = false
            },
            friendsCount = 12,
            totalProperties = 3,
            distanceTraveled = 125.5,
            premiumType = "عادي",
            playerActivities = {
                {"انضم إلى السيرفر", "2024-01-01 14:30"},
                {"أكمل المهمة الأولى", "2024-01-01 15:45"},
                {"اشترى أول مركبة", "2024-01-02 10:20"},
                {"وصل للمستوى 5", "2024-01-03 16:15"},
            },
            availableRewards = {
                {name = "مكافأة المستوى 5", description = "مكافأة للوصول للمستوى الخامس"},
                {name = "هدية الأسبوع", description = "هدية أسبوعية مجانية"},
            }
        }
    end
    
    -- إرسال البيانات للاعب
    triggerClientEvent(source, "paradise:receivePlayerData", source, playerData[playerName])
end)

-- دالة تنسيق المال
function formatMoney(amount)
    amount = math.floor(amount or 0)
    return "$" .. tostring(amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- أمر لتعيين الإداري (للاختبار)
addCommandHandler("setmyadmin", function(player, cmd)
    setElementData(player, "isAdmin", true)
    triggerEvent("paradise:showToast", player, "تم اعطاؤك حالة ادمن مؤقتاً")
end)

-- أمر لإزالة الصلاحية
addCommandHandler("removeadmin", function(player, cmd)
    setElementData(player, "isAdmin", false)
    triggerEvent("paradise:showToast", player, "تم إزالة صلاحية الإداري", 255, 100, 100)
end)

-- أمر لإعطاء مال (للاختبار)
addCommandHandler("givemoney", function(player, cmd, amount)
    amount = tonumber(amount) or 100000
    givePlayerMoney(player, amount)
    triggerEvent("paradise:showToast", player, "تم إعطاؤك "..formatMoney(amount))
end)

-- دالة لتحميل الإعدادات
function loadPlayerSettings(player)
    -- يمكن تحميل إعدادات اللاعب من قاعدة البيانات
    local settings = {
        waterGraphics = true,
        vehicleTuning = true
    }
    return settings
end

-- دالة لحفظ الإعدادات  
function savePlayerSettings(player, settings)
    -- يمكن حفظ إعدادات اللاعب في قاعدة البيانات
    return true
end

-- تهيئة بيانات اللاعب عند الدخول
addEventHandler("onPlayerJoin", root, function()
    local playerName = getPlayerName(source)
    
    -- تعيين إعدادات افتراضية
    setElementData(source, "vehicleTuningEnabled", true)
    
    -- تحميل بيانات اللاعب من قاعدة البيانات
    if not playerData[playerName] then
        playerData[playerName] = {
            playerLevel = 1,
            playerExp = 0,
            playerMaxExp = 1000,
            playTime = 0,
            joinDate = os.date("%Y-%m-%d"),
            completedMissions = 0,
            achievements = {},
            friendsCount = 0,
            totalProperties = 0,
            distanceTraveled = 0,
            premiumType = "عادي",
            playerActivities = {},
            availableRewards = {}
        }
    end
    
    -- إرسال بيانات اللاعب للعميل
    setTimer(function()
        triggerClientEvent(source, "paradise:receivePlayerData", source, playerData[playerName])
    end, 1000, 1)
end)

-- حفظ البيانات عند الخروج
addEventHandler("onPlayerQuit", root, function()
    -- هنا يمكن حفظ بيانات اللاعب في قاعدة البيانات
    local playerName = getPlayerName(source)
    outputConsole("Player "..playerName.." left the game - data saved")
end)

-- وظائف لإضافة مركبات وبيوت للاعب (للتجربة)
addCommandHandler("addvehicle", function(player, cmd, vehicleName, plate)
    local playerVehicles = getElementData(player, "playerVehicles") or {}
    table.insert(playerVehicles, {
        name = vehicleName or "مركبة جديدة",
        plate = plate or "NEW"..math.random(1000,9999),
        health = math.random(80, 100)
    })
    setElementData(player, "playerVehicles", playerVehicles)
    triggerEvent("paradise:showToast", player, "تمت إضافة مركبة جديدة إلى ممتلكاتك")
end)

addCommandHandler("addhouse", function(player, cmd, houseName, location, price)
    local playerHouses = getElementData(player, "playerHouses") or {}
    table.insert(playerHouses, {
        name = houseName or "منزل جديد",
        location = location or "موقع جديد",
        price = tonumber(price) or 100000
    })
    setElementData(player, "playerHouses", playerHouses)
    triggerEvent("paradise:showToast", player, "تمت إضافة منزل جديد إلى ممتلكاتك")
end)

-- تحديث بيانات اللاعب بشكل دوري
setTimer(function()
    for _, player in ipairs(getElementsByType("player")) do
        local playerName = getPlayerName(player)
        if playerData[playerName] then
            -- زيادة وقت اللعب
            playerData[playerName].playTime = playerData[playerName].playTime + 1
            
            -- تحديث عدد الممتلكات
            local vehicles = getElementData(player, "playerVehicles") or {}
            local houses = getElementData(player, "playerHouses") or {}
            playerData[playerName].totalProperties = #vehicles + #houses
            
            -- إرسال البيانات المحدثة
            triggerClientEvent(player, "paradise:receivePlayerData", player, playerData[playerName])
        end
    end
end, 60000, 0) -- كل دقيقة