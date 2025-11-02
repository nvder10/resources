-----------------------------------
-- Car Dealership System - SERVER
-----------------------------------

local carDealerships = {}
local playerCarKeys = {}
local dbConn = nil

-- إعداد قاعدة البيانات
addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[DEALERSHIP] 🔄 بدء تحميل نظام المعرض...")
    
    -- الاتصال بقاعدة البيانات
    dbConn = dbConnect("mysql", "dbname=mta_server;host=127.0.0.1", "root", "12345678", "autoreconnect=1;share=1")
    
    if dbConn then
        outputDebugString("[DEALERSHIP] ✅ تم الاتصال بقاعدة البيانات بنجاح")
    else
        outputDebugString("[DEALERSHIP] ❌ فشل الاتصال بقاعدة البيانات")
        dbConn = dbConnect("sqlite", ":/dealership.db")
        if dbConn then
            outputDebugString("[DEALERSHIP] ✅ تم الاتصال بـ SQLite بدلاً من MySQL")
        end
    end
    
    setupDealerships()
end)

function setupDealerships()
    outputDebugString("[DEALERSHIP] 🔧 جاري إعداد المعرض...")
    
    -- مسح المعارض القديمة
    for id, dealership in pairs(carDealerships) do
        if isElement(dealership.marker) then destroyElement(dealership.marker) end
        if isElement(dealership.vehicle) then destroyElement(dealership.vehicle) end
        if isElement(dealership.colshape) then destroyElement(dealership.colshape) end
    end
    carDealerships = {}
    
    -- سيارة Kia Forte
    local carData = {
        id = 401,
        name = "Kia Forte",
        price = 75000,
        position = {1115.9766845703, -915.4855957031, 23.5},
        markerPosition = {1115.9766845703, -915.4855957031, 22.8},
        colors = {
            {0, 0, 0},      -- أسود
            {255, 255, 255}, -- أبيض
            {200, 0, 0},     -- أحمر
            {0, 0, 200},     -- أزرق
            {50, 150, 50},   -- أخضر
            {150, 150, 0},   -- ذهبي
        },
        spawnPosition = {1141.9532470703, -927.79803466797, 43.1796875, 0}
    }
    
    createCarDealership(carData)
end

function createCarDealership(carData)
    outputDebugString("[DEALERSHIP] 🚗 جاري إنشاء معرض: " .. carData.name)
    
    -- ماركر
    local marker = createMarker(carData.markerPosition[1], carData.markerPosition[2], carData.markerPosition[3], "cylinder", 1.5, 0, 150, 255, 150)
    if not marker then
        outputDebugString("[DEALERSHIP] ❌ فشل إنشاء الماركر")
        return
    end
    
    setElementData(marker, "carDealership", true)
    setElementData(marker, "carData", carData)
    
    -- سيارة العرض
    local vehicle = createVehicle(carData.id, carData.position[1], carData.position[2], carData.position[3], 0, 0, 90)
    if not vehicle then
        outputDebugString("[DEALERSHIP] ❌ فشل إنشاء سيارة العرض")
        return
    end
    
    setElementFrozen(vehicle, true)
    setElementData(vehicle, "showroomCar", true)
    setVehicleColor(vehicle, 255, 255, 255)
    setVehicleDamageProof(vehicle, true)
    
    -- كول شيب
    local colshape = createColSphere(carData.markerPosition[1], carData.markerPosition[2], carData.markerPosition[3], 2)
    if not colshape then
        outputDebugString("[DEALERSHIP] ❌ فشل إنشاء كول شيب")
        return
    end
    
    setElementData(colshape, "carDealership", true)
    setElementData(colshape, "carData", carData)
    
    carDealerships[carData.id] = {
        marker = marker,
        vehicle = vehicle,
        colshape = colshape,
        data = carData
    }
    
    outputDebugString("[DEALERSHIP] ✅ تم إنشاء معرض لـ " .. carData.name .. " في " .. carData.position[1] .. ", " .. carData.position[2])
    outputDebugString("[DEALERSHIP] 📍 الماركر في: " .. carData.markerPosition[1] .. ", " .. carData.markerPosition[2] .. ", " .. carData.markerPosition[3])
end

-- أمر لفحص النظام
addCommandHandler("testdealership", function(player)
    outputChatBox("🔍 فحص نظام المعرض:", player, 0, 255, 255)
    
    local px, py, pz = getElementPosition(player)
    outputChatBox("📍 موقعك: " .. px .. ", " .. py .. ", " .. pz, player, 255, 255, 0)
    
    outputChatBox("🚗 السيارات في الذاكرة: " .. table.size(carDealerships), player, 255, 255, 0)
    
    for id, dealership in pairs(carDealerships) do
        local mx, my, mz = getElementPosition(dealership.marker)
        local distance = getDistanceBetweenPoints3D(px, py, pz, mx, my, mz)
        outputChatBox("🎯 معرض " .. dealership.data.name .. " - المسافة: " .. math.floor(distance) .. " متر", player, 255, 255, 0)
    end
end)

-- حدث شراء السيارة
addEvent("onPlayerBuyCar", true)
addEventHandler("onPlayerBuyCar", root, function(carData, colorIndex)
    local player = client
    outputDebugString("[DEALERSHIP] 💰 طلب شراء من " .. getPlayerName(player) .. " لـ " .. carData.name)

    -- التحقق من المال
    if getPlayerMoney(player) < carData.price then
        outputChatBox("❌ ليس لديك ما يكفي من المال. السعر: $" .. carData.price, player, 255, 0, 0)
        return
    end

    -- خصم المال
    takePlayerMoney(player, carData.price)
    
    -- إنشاء السيارة مباشرة (بدون داتابيز أولاً للتجربة)
    local success = createPurchasedVehicle(player, carData, colorIndex)
    
    if success then
        -- إعطاء المفتاح
        giveCarKey(player, carData.id)
        
        outputChatBox("✅ تم شراء " .. carData.name .. " بـ $" .. carData.price, player, 0, 255, 0)
        outputChatBox("🔑 تم إضافة مفتاح السيارة إلى مخزونك", player, 0, 255, 0)
        outputChatBox("🚗 تم إنشاء سيارتك خارج المعرض", player, 0, 200, 255)
        
        outputDebugString("[DEALERSHIP] ✅ تم البيع بنجاح لـ " .. getPlayerName(player))
    else
        outputChatBox("❌ فشل في شراء السيارة. تم إرجاع أموالك.", player, 255, 0, 0)
        givePlayerMoney(player, carData.price)
    end
end)

-- دالة إنشاء السيارة المشتراة
function createPurchasedVehicle(player, carData, colorIndex)
    local color = carData.colors[colorIndex] or {255, 255, 255}
    
    outputDebugString("[DEALERSHIP] 🚗 جاري إنشاء سيارة في: " .. carData.spawnPosition[1] .. ", " .. carData.spawnPosition[2] .. ", " .. carData.spawnPosition[3])
    
    -- إنشاء السيارة في الموقع المحدد
    local vehicle = createVehicle(carData.id, 
        carData.spawnPosition[1], 
        carData.spawnPosition[2], 
        carData.spawnPosition[3], 
        0, 0, carData.spawnPosition[4])
    
    if vehicle then
        setVehicleColor(vehicle, color[1], color[2], color[1], color[2])
        setElementData(vehicle, "owner", getPlayerName(player))
        
        outputDebugString("[DEALERSHIP] ✅ تم إنشاء " .. carData.name .. " للاعب " .. getPlayerName(player))
        return true
    else
        outputDebugString("[DEALERSHIP] ❌ فشل في إنشاء السيارة")
        return false
    end
end

-- نظام المفاتيح
function giveCarKey(player, vehicleModel)
    if not playerCarKeys[player] then
        playerCarKeys[player] = {}
    end
    
    table.insert(playerCarKeys[player], {
        vehicleModel = vehicleModel,
        itemName = "car_key",
        itemImage = "car_key.png"
    })
    
    outputDebugString("[DEALERSHIP] 🔑 تم إعطاء مفتاح لـ " .. getPlayerName(player))
end

-- دالة مساعدة
function table.size(tab)
    local count = 0
    for _ in pairs(tab) do count = count + 1 end
    return count
end