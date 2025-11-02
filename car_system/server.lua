-----------------------------------
-- Car System - SERVER (مدمج بالكامل)
-----------------------------------

-- =========================
-- إعدادات النظام
-- =========================
local useMySQL = true
local dbConn = nil

-- =========================
-- متغيرات الأنظمة
-- =========================
local carDealerships = {}
local playerCarKeys = {}
local vehicleOwners = {}
local playerSeatbelts = {}
local activeGarages = {}
local playerInGarageArea = {}
local playerInDealershipArea = {}

-- =========================
-- نظام الأسعار بناءً على حالة السيارة
-- =========================
local VEHICLE_PRICES = {
    BASE_RETRIEVE = 500,          -- سعر أساسي لإخراج السيارة
    BASE_CALL = 1000,             -- سعر أساسي لاستدعاء السيارة
    DAMAGE_REPAIR = 1000,         -- سعر إصلاح التلف
    FAR_DISTANCE = 500,           -- سعر إضافي للمسافات البعيدة
    LOW_FUEL = 200,               -- سعر إضافي لتعبة الوقود
    URGENT_CALL = 1500,           -- سعر الاستدعاء العاجل,
}

-- =========================
-- تهيئة النظام
-- =========================
addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[CAR_SYSTEM] 🚀 بدء تحميل النظام المتكامل...")
    
    if not initializeDatabase() then
        outputDebugString("[CAR_SYSTEM] ❌ فشل تحميل النظام بسبب مشكلة في قاعدة البيانات", 1)
        return
    end
    
    -- إنشاء الجداول أولاً
    if not createSystemTables() then
        outputDebugString("[CAR_SYSTEM] ⚠️ هناك مشكلة في الجداول، جاري المحاولة مرة أخرى...", 2)
    end
    
    -- فحص الجداول بعد الإنشاء
    checkDatabaseTables()
    
    -- تحميل الأنظمة
    setupDealerships()
    loadAllGarages()
    
    outputDebugString("[CAR_SYSTEM] ✅ تم تحميل جميع الأنظمة بنجاح")
end)

-- =========================
-- قاعدة البيانات
-- =========================
function initializeDatabase()
    if useMySQL then
        local DB_NAME = "mta_server"
        local DB_HOST = "127.0.0.1"
        local DB_USER = "root"
        local DB_PASS = "12345678"

        dbConn = dbConnect("mysql", "dbname="..DB_NAME..";host="..DB_HOST, DB_USER, DB_PASS, "autoreconnect=1;share=1")
        
        if dbConn then
            outputDebugString("[CAR_SYSTEM] ✅ تم الاتصال بقاعدة بيانات MySQL بنجاح.")
            return true
        else
            outputDebugString("[CAR_SYSTEM] ⚠️ فشل الاتصال بـ MySQL، سيتم استخدام SQLite بدلاً منه.", 2)
        end
    end
    
    dbConn = dbConnect("sqlite", "car_system.db")
    
    if dbConn then
        outputDebugString("[CAR_SYSTEM] 🗄️ جاري استخدام SQLite (car_system.db).")
        return true
    else
        outputDebugString("[CAR_SYSTEM] ❌ فشل في الاتصال بقاعدة البيانات!", 1)
        return false
    end
end

function createSystemTables()
    outputDebugString("[CAR_SYSTEM] 🔧 جاري إنشاء الجداول...")
    
    -- جدول الجراجات - MySQL syntax
    local success1 = dbExec(dbConn, [[
        CREATE TABLE IF NOT EXISTS garages (
            id INTEGER PRIMARY KEY AUTO_INCREMENT,
            garage_name VARCHAR(50) NOT NULL,
            player_id INT NOT NULL DEFAULT 0,
            position_x FLOAT NOT NULL,
            position_y FLOAT NOT NULL,
            position_z FLOAT NOT NULL,
            interior INT DEFAULT 0,
            capacity INT DEFAULT 10,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    -- 🆕 إصلاح: تغيير اسم العميل stored إلى is_stored
    local success2 = dbExec(dbConn, [[
        CREATE TABLE IF NOT EXISTS garage_vehicles (
            id INTEGER PRIMARY KEY AUTO_INCREMENT,
            vehicle_id VARCHAR(100) NOT NULL,
            garage_id INT NOT NULL DEFAULT 1,
            vehicle_model INT NOT NULL,
            vehicle_name VARCHAR(50) DEFAULT 'سيارة',
            color1 INT DEFAULT 0,
            color2 INT DEFAULT 0,
            color3 INT DEFAULT 0,
            color4 INT DEFAULT 0,
            posX FLOAT DEFAULT 0,
            posY FLOAT DEFAULT 0,
            posZ FLOAT DEFAULT 0,
            rotZ FLOAT DEFAULT 0,
            health FLOAT DEFAULT 1000,
            fuel FLOAT DEFAULT 100,
            is_stored TINYINT(1) DEFAULT 1,
            owner_name VARCHAR(100) DEFAULT '',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    -- جدول سيارات المعرض - MySQL syntax
    local success3 = dbExec(dbConn, [[
        CREATE TABLE IF NOT EXISTS dealership_vehicles (
            id INTEGER PRIMARY KEY AUTO_INCREMENT,
            vehicle_id VARCHAR(100) UNIQUE NOT NULL,
            owner_name VARCHAR(100) NOT NULL,
            vehicle_model INTEGER NOT NULL,
            vehicle_name VARCHAR(50) DEFAULT 'سيارة',
            color1 INTEGER DEFAULT 0,
            color2 INTEGER DEFAULT 0,
            color3 INTEGER DEFAULT 0,
            color4 INTEGER DEFAULT 0,
            price INTEGER DEFAULT 0,
            purchased_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    if success1 and success2 and success3 then
        outputDebugString("[CAR_SYSTEM] ✅ تم إنشاء جميع الجداول بنجاح")
        
        -- 🔧 الجراج الرئيسي
        dbExec(dbConn, "INSERT IGNORE INTO garages (id, garage_name, player_id, position_x, position_y, position_z) VALUES (?, ?, ?, ?, ?, ?)",
            1, "الجراج الرئيسي", 0, 1128.1207275391, -931.78747558594, 43.0)
            
        -- 🆕 جراجات جديدة - 8 جراجات إضافية
        dbExec(dbConn, "INSERT IGNORE INTO garages (id, garage_name, player_id, position_x, position_y, position_z) VALUES (?, ?, ?, ?, ?, ?)",
            2, "جراج لوس سانتوس", 0, 1804.25, -2141.12, 43.0)
            
        dbExec(dbConn, "INSERT IGNORE INTO garages (id, garage_name, player_id, position_x, position_y, position_z) VALUES (?, ?, ?, ?, ?, ?)",
            3, "جراج سان فييرو", 0, -1975.85, 273.36, 43.0)
            
        dbExec(dbConn, "INSERT IGNORE INTO garages (id, garage_name, player_id, position_x, position_y, position_z) VALUES (?, ?, ?, ?, ?, ?)",
            4, "جراج لاس فينتوراس", 0, 1690.63, 1434.92, 43.0)
            
        dbExec(dbConn, "INSERT IGNORE INTO garages (id, garage_name, player_id, position_x, position_y, position_z) VALUES (?, ?, ?, ?, ?, ?)",
            5, "جراج عام", 0, 1570.32, -2111.45, 43.0)
            
        dbExec(dbConn, "INSERT IGNORE INTO garages (id, garage_name, player_id, position_x, position_y, position_z) VALUES (?, ?, ?, ?, ?, ?)",
            6, "جراج المطار", 0, 1588.51, -2284.12, 43.0)
            
        dbExec(dbConn, "INSERT IGNORE INTO garages (id, garage_name, player_id, position_x, position_y, position_z) VALUES (?, ?, ?, ?, ?, ?)",
            7, "جراج الميناء", 0, 2783.84, -2457.82, 43.0)
            
        dbExec(dbConn, "INSERT IGNORE INTO garages (id, garage_name, player_id, position_x, position_y, position_z) VALUES (?, ?, ?, ?, ?, ?)",
            8, "جراج الريف", 0, -151.25, 1211.25, 43.0)
            
        dbExec(dbConn, "INSERT IGNORE INTO garages (id, garage_name, player_id, position_x, position_y, position_z) VALUES (?, ?, ?, ?, ?, ?)",
            9, "جراج الجبال", 0, -2243.96, -2558.57, 43.0)
            
        outputDebugString("[CAR_SYSTEM] ✅ تم إضافة 9 جراجات (8 جديدة + الرئيسي)")
        return true
    else
        outputDebugString("[CAR_SYSTEM] ❌ فشل في إنشاء بعض الجداول", 1)
        outputDebugString("[CAR_SYSTEM] garages " .. tostring(success1), 1)
        outputDebugString("[CAR_SYSTEM] garage_vehicles " .. tostring(success2), 1)
        outputDebugString("[CAR_SYSTEM] dealership_vehicles " .. tostring(success3), 1)
        return false
    end
end

function checkDatabaseTables()
    outputDebugString("[CAR_SYSTEM] 🔍 فحص حالة الجداول...")
    
    local tables = {"garages", "garage_vehicles", "dealership_vehicles"}
    
    for _, tableName in ipairs(tables) do
        local success, result = pcall(function()
            local qh = dbQuery(dbConn, "SELECT 1 FROM " .. tableName .. " LIMIT 1")
            if qh then
                local res = dbPoll(qh, 1000)
                return res ~= nil
            end
            return false
        end)
        
        if success and result then
            outputDebugString("[CAR_SYSTEM] ✅ جدول " .. tableName .. " موجود")
        else
            outputDebugString("[CAR_SYSTEM] ❌ جدول " .. tableName .. " غير موجود أو به خطأ", 1)
        end
    end
end

-- =========================
-- نظام المعرض
-- =========================
function setupDealerships()
    -- تنظيف المعارض القديمة
    for id, dealership in pairs(carDealerships) do
        if isElement(dealership.marker) then destroyElement(dealership.marker) end
        if isElement(dealership.vehicle) then destroyElement(dealership.vehicle) end
        if isElement(dealership.colshape) then destroyElement(dealership.colshape) end
        if isElement(dealership.vehicleCol) then destroyElement(dealership.vehicleCol) end
    end
    carDealerships = {}

    local carsData = {
        {
            id = 401,
            name = "Kia Forte",
            carimage = "images/kia_forte.png",
            price = 120000,
            position = {1115.9766845703, -915.4855957031, 43.5},
            markerPosition = {1116.1594238281, -910.42761230469, 40.8},
            colors = {
                {0, 0, 0},
                {255, 255, 255},
                {255, 0, 0},
                {54, 74, 255},
                {0, 255, 17},
                {255, 215, 0},
                {255, 165, 0},
                {179, 20, 219}
            },
            spawnPosition = {1142.0629882812, -928.34436035156, 43.175956726074, 0}
        },

        {
            id = 420,
            name = "BMW-E39",
            carimage = "images/bmwe39.png",
            price = 150000,
            position = {1102.6400146484, -915.76263427734, 43.5},
            markerPosition = {1103.5179443359, -910.42761230469, 40.8},
            colors = {
                {0, 0, 0},
                {255, 255, 255},
                {255, 0, 0},
                {54, 74, 255},
                {0, 255, 17},
                {255, 215, 0},
                {255, 165, 0},
                {179, 20, 219}
            },
            spawnPosition = {1142.0629882812, -928.34436035156, 43.175956726074, 0}
        },

        {
            id = 546,
            name = "Golf-R22",
            carimage = "images/golfr.png",
            price = 110000,
            position = {1090.1343994141, -915.52807617188, 43.6},
            markerPosition = {1090.4036865234, -910.47589111328, 40.8},
            colors = {
                {0, 0, 0},
                {255, 255, 255},
                {200, 0, 0},
                {54, 74, 255},
                {0, 255, 17},
                {255, 215, 0},
                {255, 165, 0},
                {179, 20, 219}
            },
            spawnPosition = {1142.0629882812, -928.34436035156, 43.175956726074, 0}
        },

        {
            id = 554,
            name = "Toyota-Tundra",
            carimage = "images/toyotatundra.png",
            price = 80000,
            position = {1129.3402099609, -889.82586669922, 43.6},
            markerPosition = {1125.1676025391, -892.56805419922, 40.8},
            colors = {
                {0, 0, 0},
                {255, 255, 255},
                {255, 0, 0},
                {54, 74, 255},
                {0, 255, 17},
                {255, 215, 0},
                {255, 165, 0},
                {179, 20, 219}
            },
            spawnPosition = {1142.0629882812, -928.34436035156, 43.175956726074, 0}
        },

        {
            id = 445,
            name = "Mercedes-E190",
            carimage = "images/mercedese190.png",
            price = 160000,
            position = {1122.0689697266, -881.49371337891, 43.5},
            markerPosition = {1115.9099121094, -881.07745361328, 40.8},
            colors = {
                {0, 0, 0},
                {255, 255, 255},
                {255, 0, 0},
                {54, 74, 255},
                {0, 255, 17},
                {255, 215, 0},
                {255, 165, 0},
                {179, 20, 219}
            },
            spawnPosition = {1142.0629882812, -928.34436035156, 43.175956726074, 0}
        }
    }

    -- إنشاء المعارض لكل سيارة
    for _, carData in ipairs(carsData) do
        if carData and carData.id and carData.name then
            createCarDealership(carData)
        else
            outputDebugString("[DEALERSHIP] ❌ بيانات سيارة غير صالحة " .. tostring(carData))
        end
    end
    
    outputDebugString("[DEALERSHIP] ✅ تم إنشاء " .. #carsData .. " معرض سيارات")
end

function createCarDealership(carData)
    if not carData or not carData.id or not carData.name then
        outputDebugString("[DEALERSHIP] ❌ بيانات سيارة غير كافية")
        return
    end
    
    outputDebugString("[DEALERSHIP] 🚗 جاري إنشاء معرض " .. carData.name)
    
    -- التحقق من بيانات المواقع
    local markerPos = carData.markerPosition or {0, 0, 0}
    local carPos = carData.position or {0, 0, 0}
    
    -- ماركر المعرض
    local marker = createMarker(markerPos[1], markerPos[2], markerPos[3], "cylinder", 2.0, 87, 166, 255, 200)
    if not marker then
        outputDebugString("[DEALERSHIP] ❌ فشل إنشاء الماركر للسيارة " .. carData.name)
        return
    end
    
    setElementData(marker, "carDealership", true)
    setElementData(marker, "carData", carData)
    
    -- سيارة العرض
    local vehicle = createVehicle(carData.id, carPos[1], carPos[2], carPos[3], 0, 0, 90)
    if not vehicle then
        outputDebugString("[DEALERSHIP] ❌ فشل إنشاء سيارة العرض " .. carData.name)
        destroyElement(marker)
        return
    end
    
    -- 🔒 إضافة كل الخصائص لمنع التفاعل مع السيارة
    setElementFrozen(vehicle, true)
    setElementData(vehicle, "showroomCar", true)
    setVehicleColor(vehicle, 255, 255, 255)
    setVehicleDamageProof(vehicle, true)
    setElementAlpha(vehicle, 255)
    setVehicleLocked(vehicle, true)
    setVehicleEngineState(vehicle, false)
    setVehicleOverrideLights(vehicle, 1)
    
    -- 🎯 إضافة كولشيب حول السيارة لمنع الاقتراب
    local vehicleCol = createColSphere(carPos[1], carPos[2], carPos[3], 4)
    setElementData(vehicleCol, "showroomVehicle", true)
    
    -- حدث لمنع دخول السيارة
    addEventHandler("onColShapeHit", vehicleCol, function(hitElement, matchingDimension)
        if hitElement and isElement(hitElement) and getElementType(hitElement) == "player" and matchingDimension then
            outputChatBox("🚫 هذه السيارة للعرض فقط ولا يمكنك ركوبها", hitElement, 255, 0, 0)
        end
    end)
    
    -- كول شيب للمعرض
    local colshape = createColSphere(markerPos[1], markerPos[2], markerPos[3], 3)
    if not colshape then
        outputDebugString("[DEALERSHIP] ❌ فشل إنشاء كول شيب " .. carData.name)
        destroyElement(marker)
        destroyElement(vehicle)
        destroyElement(vehicleCol)
        return
    end
    
    setElementData(colshape, "carDealership", true)
    setElementData(colshape, "carData", carData)
    
    carDealerships[carData.id] = {
        marker = marker,
        vehicle = vehicle,
        colshape = colshape,
        vehicleCol = vehicleCol,
        data = carData
    }
    
    outputDebugString("[DEALERSHIP] ✅ تم إنشاء معرض لـ " .. carData.name)
end

-- =========================
-- دالة إنشاء السيارة المشتراة
-- =========================
function createPurchasedVehicle(player, carData, colorIndex)
    -- 🔧 التحقق من بيانات السيارة
    if not carData or not player then
        outputDebugString("[DEALERSHIP] ❌ بيانات غير كافية لإنشاء السيارة")
        return false
    end
    
    local color = carData.colors and carData.colors[colorIndex] or {255, 255, 255}
    
    -- التحقق من موقع الإسباون
    local spawnX = carData.spawnPosition and carData.spawnPosition[1] or 1142.0629882812
    local spawnY = carData.spawnPosition and carData.spawnPosition[2] or -928.34436035156
    local spawnZ = carData.spawnPosition and carData.spawnPosition[3] or 43.175956726074
    local spawnRot = carData.spawnPosition and carData.spawnPosition[4] or 0
    
    outputDebugString("[DEALERSHIP] 🚗 جاري إنشاء سيارة في " .. spawnX .. ", " .. spawnY .. ", " .. spawnZ)
    
    local vehicleModel = carData.id or 400
    local vehicle = createVehicle(vehicleModel, spawnX, spawnY, spawnZ, 0, 0, spawnRot)
    
    if vehicle then
        -- 🔧 تطبيق الألوان بشكل صحيح - استخدام جميع الألوان الأربعة
        local r, g, b = color[1], color[2], color[3] or color[1]
        
        -- تطبيق الألوان الأربعة بشكل صحيح
        setVehicleColor(vehicle, r, g, b, r, g, b)
        
        local vehicleId = tostring(getPlayerName(player)) .. "_" .. vehicleModel .. "_" .. getTickCount()
        local vehicleName = carData.name or "سيارة"
        
        setElementData(vehicle, "vehicle.model", vehicleModel)
        setElementData(vehicle, "vehicle.name", vehicleName)
        setElementData(vehicle, "vehicle.price", carData.price or 0)
        setElementData(vehicle, "vehicle.owner", player)
        setElementData(vehicle, "vehicle.id", vehicleId)
        setElementData(vehicle, "vehicle.color1", r)
        setElementData(vehicle, "vehicle.color2", g)
        setElementData(vehicle, "vehicle.color3", b)
        setElementData(vehicle, "vehicle.color4", r)
        
        outputDebugString("[DEALERSHIP] ✅ تم إنشاء " .. vehicleName .. " للاعب " .. getPlayerName(player) .. " - ID " .. vehicleId .. " - الألوان " .. r .. "," .. g .. "," .. b)
        return vehicle, vehicleId
    else
        outputDebugString("[DEALERSHIP] ❌ فشل في إنشاء السيارة - الموديل " .. vehicleModel)
        return false
    end
end

-- حدث شراء السيارة
addEvent("onPlayerBuyCar", true)
addEventHandler("onPlayerBuyCar", root, function(carData, colorIndex)
    local player = client
    
    -- 🔧 التحقق من البيانات الأساسية
    if not player or not isElement(player) then
        outputDebugString("[DEALERSHIP] ❌ لاعب غير صالح")
        return
    end
    
    if not carData then
        outputDebugString("[DEALERSHIP] ❌ بيانات السيارة غير موجودة")
        outputChatBox("❌ حدث خطأ في بيانات السيارة", player, 255, 0, 0)
        return
    end
    
    local vehicleName = carData.name or "سيارة"
    local price = carData.price or 0
    
    outputDebugString("[DEALERSHIP] 💰 طلب شراء من " .. getPlayerName(player) .. " لـ " .. vehicleName)

    if getPlayerMoney(player) < price then
        outputChatBox("❌ ليس لديك ما يكفي من المال. السعر $" .. price, player, 255, 0, 0)
        return
    end

    takePlayerMoney(player, price)
    
    local vehicle, vehicleId = createPurchasedVehicle(player, carData, colorIndex)
    
    if vehicle then
        -- 🔧 تسجيل الملكية في نظام car_system
        registerVehicleOwner(vehicle, player, vehicleId)
        
        -- إعطاء المفتاح
        giveCarKey(player, vehicle, vehicleId)
        
        -- حفظ في قاعدة البيانات
        saveVehicleToDatabase(vehicle, vehicleId, player, carData, colorIndex)
        
        outputChatBox("✅ تم شراء " .. vehicleName .. " بـ $" .. price, player, 0, 255, 0)
        outputChatBox("🔑 تم إضافة مفتاح السيارة إلى مخزونك", player, 0, 255, 0)
        outputChatBox("🚗 تم إنشاء سيارتك خارج المعرض", player, 0, 200, 255)
        
        outputDebugString("[DEALERSHIP] ✅ تم البيع بنجاح لـ " .. getPlayerName(player))
    else
        outputChatBox("❌ فشل في شراء السيارة. تم إرجاع أموالك.", player, 255, 0, 0)
        givePlayerMoney(player, price)
    end
end)

function saveVehicleToDatabase(vehicle, vehicleId, player, carData, colorIndex)
    if not dbConn then
        outputDebugString("[DEALERSHIP] ⚠️ لا يوجد اتصال بقاعدة البيانات - تخطي الحفظ")
        return false
    end
    
    -- 🔧 التحقق من بيانات السيارة
    if not carData or not vehicleId or not player then
        outputDebugString("[DEALERSHIP] ❌ بيانات غير كافية لحفظ السيارة")
        return false
    end
    
    local color = carData.colors and carData.colors[colorIndex] or {255, 255, 255}
    local r, g, b = color[1], color[2], color[3] or color[1]
    
    local vehicleName = carData.name or "سيارة"
    local vehicleModel = carData.id or 400
    local price = carData.price or 0
    local playerName = getPlayerName(player) or "Unknown"
    
    local success = dbExec(dbConn, 
        "INSERT INTO dealership_vehicles (vehicle_id, owner_name, vehicle_model, vehicle_name, color1, color2, color3, color4, price) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        vehicleId, playerName, vehicleModel, vehicleName, r, g, b, r, price
    )
    
    if success then
        outputDebugString("[DEALERSHIP] 💾 تم حفظ السيارة في قاعدة البيانات " .. vehicleId .. " - الاسم " .. vehicleName .. " - الألوان " .. r .. "," .. g .. "," .. b)
        return true
    else
        outputDebugString("[DEALERSHIP] ❌ فشل في حفظ السيارة في قاعدة البيانات")
        return false
    end
end

-- نظام المفاتيح
function giveCarKey(player, vehicle, vehicleId)
    if not playerCarKeys[player] then
        playerCarKeys[player] = {}
    end
    
    local keyData = {
        vehicleId = vehicleId,
        vehicleModel = getElementModel(vehicle),
        vehicleName = getElementData(vehicle, "vehicle.name") or "سيارة",
        itemName = "car_key",
        itemImage = "car_key.png",
        timestamp = getRealTime().timestamp
    }
    
    table.insert(playerCarKeys[player], keyData)
    
    -- إضافة المفتاح للانفنتوري
    triggerClientEvent(player, "addInventoryItem", player, "مفتاح سيارة", "images/car_key.png", vehicleId)
    
    outputDebugString("[DEALERSHIP] 🔑 تم إعطاء مفتاح لـ " .. getPlayerName(player) .. " للسيارة " .. vehicleId)
end

function hasCarKey(player, vehicle)
    local vehicleId = getElementData(vehicle, "vehicle.id")
    
    if playerCarKeys[player] then
        for _, key in ipairs(playerCarKeys[player]) do
            if key.vehicleId == vehicleId then
                return true
            end
        end
    end
    
    return false
end

-- =========================
-- نظام الجراج
-- =========================
function loadAllGarages()
    -- تنظيف العلامات القديمة
    for _, col in ipairs(getElementsByType("colshape")) do
        if getElementData(col, "garage.id") then
            destroyElement(col)
        end
    end
    
    for _, marker in ipairs(getElementsByType("marker")) do
        if getElementData(marker, "garage.marker") then
            destroyElement(marker)
        end
    end
    
    activeGarages = {}
    
    -- التحقق من اتصال قاعدة البيانات أولاً
    if not dbConn then
        outputDebugString("[GARAGE] ❌ لا يوجد اتصال بقاعدة البيانات", 1)
        return
    end
    
    -- استعلام قاعدة البيانات مع معالجة الأخطاء
    local success, result = pcall(function()
        local qh = dbQuery(dbConn, "SELECT * FROM garages")
        if not qh then return nil end
        return dbPoll(qh, 3000)
    end)
    
    if not success then
        outputDebugString("[GARAGE] ❌ خطأ في استعلام قاعدة البيانات: " .. tostring(result), 1)
        return
    end
    
    local res = result
    
    if res and #res > 0 then
        for _, garage in ipairs(res) do
            createGarageColshape(garage)
        end
        outputDebugString("[GARAGE] ✅ تم تحميل " .. #res .. " جراج")
    else
        outputDebugString("[GARAGE] ⚠️ لا توجد جراجات في قاعدة البيانات")
        
        -- 🆕 إضافة: إنشاء جراجات افتراضية في حالة عدم وجودها
        createDefaultGarages()
    end
end

-- 🆕 إضافة: دالة إنشاء جراجات افتراضية
function createDefaultGarages()
    outputDebugString("[GARAGE] 🔨 جاري إنشاء جراجات افتراضية...")
    
    local defaultGarages = {
        {id = 1, name = "الجراج الرئيسي", x = 1128.1207275391, y = -931.78747558594, z = 43.0},
        {id = 2, name = "جراج لوس سانتوس", x = 1804.25, y = -2141.12, z = 13.55},
        {id = 3, name = "جراج سان فييرو", x = -1975.85, y = 273.36, z = 35.15},
        {id = 4, name = "جراج لاس فينتوراس", x = 1690.63, y = 1434.92, z = 10.77},
        {id = 5, name = "جراج المنطقة الصناعية", x = 1570.32, y = -2111.45, z = 13.55}
    }
    
    for _, garage in ipairs(defaultGarages) do
        createGarageColshape(garage)
    end
    
    outputDebugString("[GARAGE] ✅ تم إنشاء " .. #defaultGarages .. " جراج افتراضي")
end

function createGarageColshape(garageData)
    if not garageData or not garageData.id then 
        outputDebugString("[GARAGE] ❌ بيانات جراج غير صالحة")
        return 
    end
    
    -- 🆕 إضافة: معالجة بيانات الإحداثيات بشكل أفضل
    local x, y, z = garageData.x or garageData.position_x, garageData.y or garageData.position_y, garageData.z or garageData.position_z
    local name = garageData.name or garageData.garage_name or "جراج غير معروف"
    
    if not x or not y or not z then
        outputDebugString("[GARAGE] ❌ إحداثيات جراج غير صالحة: " .. tostring(garageData.id))
        return
    end
    
    outputDebugString("[GARAGE] 🔨 جاري إنشاء جراج #" .. garageData.id .. " في " .. x .. ", " .. y .. ", " .. z)
    
    -- 🆕 تحسين: نطاق كول شيب أكبر (4 بدلاً من 3)
    local col = createColSphere(x, y, z, 4)
    if not col then
        outputDebugString("[GARAGE] ❌ فشل إنشاء كول شيب للجراج #" .. garageData.id)
        return
    end
    
    setElementData(col, "garage.id", garageData.id)
    setElementData(col, "garage.name", name)
    setElementData(col, "garage.data", garageData)
    
    -- ❌❌❌ احذف هذه الأسطر التي تنشئ الماركر في السيرفر:
    -- local marker = createMarker(x, y, z - 1, "cylinder", 2.5, 0, 150, 255, 150)
    -- if marker then
    --     setElementData(marker, "garage.marker", true)
    --     setElementData(marker, "garage.id", garageData.id)
    --     setElementData(marker, "garage.name", name)
    -- end
    
    -- 🆕 إضافة: بلب الجراج
    createBlip(x, y, z, 55, 2, 0, 150, 255, 255, 0, 200)
    
    activeGarages[garageData.id] = col
    
    outputDebugString("[GARAGE] ✅ تم إنشاء جراج #" .. garageData.id .. " - " .. name)
    return col
end

-- =========================
-- 🆕 أحداث تفاعل الجراج والمعرض (محدثة ومصححة)
-- =========================

-- حدث دخول منطقة الجراج
addEventHandler("onColShapeHit", root, function(hitElement, matchingDimension)
    if not matchingDimension then return end
    if getElementType(hitElement) ~= "player" then return end
    
    local garageID = getElementData(source, "garage.id")
    local dealershipData = getElementData(source, "carDealership")
    
    if garageID then
        outputDebugString("[GARAGE] 🚶 اللاعب " .. getPlayerName(hitElement) .. " دخل جراج #" .. garageID)
        playerInGarageArea[hitElement] = garageID
        triggerClientEvent(hitElement, "onPlayerEnterGarageArea", hitElement, garageID, true)
    end
    
    if dealershipData then
        outputDebugString("[DEALERSHIP] 🚶 اللاعب " .. getPlayerName(hitElement) .. " دخل معرض سيارات")
        playerInDealershipArea[hitElement] = true
        triggerClientEvent(hitElement, "onPlayerEnterDealershipArea", hitElement, true)
    end
end)

-- حدث خروج من منطقة الجراج
addEventHandler("onColShapeLeave", root, function(hitElement, matchingDimension)
    if getElementType(hitElement) ~= "player" then return end
    
    local garageID = getElementData(source, "garage.id")
    local dealershipData = getElementData(source, "carDealership")
    
    if garageID then
        outputDebugString("[GARAGE] 🚶 اللاعب " .. getPlayerName(hitElement) .. " خرج من جراج #" .. garageID)
        playerInGarageArea[hitElement] = nil
        triggerClientEvent(hitElement, "onPlayerEnterGarageArea", hitElement, garageID, false)
    end
    
    if dealershipData then
        outputDebugString("[DEALERSHIP] 🚶 اللاعب " .. getPlayerName(hitElement) .. " خرج من معرض سيارات")
        playerInDealershipArea[hitElement] = nil
        triggerClientEvent(hitElement, "onPlayerEnterDealershipArea", hitElement, false)
    end
end)

-- 🆕 حدث فتح الجراج من العميل
addEvent("requestOpenGarage", true)
addEventHandler("requestOpenGarage", root, function()
    local player = client
    local garageID = playerInGarageArea[player]
    
    if not garageID then
        outputChatBox("❌ أنت لست في منطقة جراج", player, 255, 0, 0)
        return
    end
    
    outputDebugString("[GARAGE] 🎯 اللاعب " .. getPlayerName(player) .. " طلب فتح الجراج #" .. garageID)
    triggerEvent("onPlayerGarageInteract", player, garageID)
end)

-- 🆕 حدث فتح المعرض من العميل
addEvent("requestOpenDealership", true)
addEventHandler("requestOpenDealership", root, function()
    local player = client
    
    if not playerInDealershipArea[player] then
        outputChatBox("❌ أنت لست في منطقة المعرض", player, 255, 0, 0)
        return
    end
    
    outputDebugString("[DEALERSHIP] 🎯 اللاعب " .. getPlayerName(player) .. " طلب فتح المعرض")
    triggerClientEvent(player, "openDealershipGUI", player, carDealerships)
end)

-- =========================
-- نظام التحقق من الحالة الحقيقية للسيارة
-- =========================

-- دالة للتحقق من الحالة الحقيقية للسيارة في العالم
function getVehicleRealStatus(vehicleId)
    -- البحث عن السيارة في العالم
    for _, vehicle in ipairs(getElementsByType("vehicle")) do
        local existingId = getElementData(vehicle, "vehicle.id")
        if existingId and existingId == vehicleId then
            local health = getElementHealth(vehicle)
            local fuel = getElementData(vehicle, "fuel") or 100
            local color1, color2, color3, color4 = getVehicleColor(vehicle)
            
            return {
                health = health,
                fuel = fuel,
                color1 = color1,
                color2 = color2,
                color3 = color3,
                color4 = color4,
                exists = true,
                vehicle = vehicle
            }
        end
    end
    
    return {
        health = 1000,
        fuel = 100,
        color1 = 0,
        color2 = 0,
        color3 = 0,
        color4 = 0,
        exists = false,
        vehicle = nil
    }
end

-- دالة محسنة لحساب تكلفة الاستدعاء بناءً على الحالة الحقيقية
function calculateCallCostReal(vehicleData, player)
    local cost = VEHICLE_PRICES.BASE_CALL
    
    -- 🔧 الحصول على الحالة الحقيقية للسيارة من العالم
    local realStatus = getVehicleRealStatus(vehicleData.vehicle_id)
    local health = realStatus.health
    local fuel = realStatus.fuel
    
    -- إذا كانت السيارة موجودة في العالم، استخدام حالتها الحقيقية
    if realStatus.exists then
        outputDebugString("[GARAGE] 🔍 تم اكتشاف الحالة الحقيقية للسيارة: الصحة " .. health .. " - الوقود " .. fuel)
    else
        -- إذا لم تكن موجودة، استخدام الحالة المخزنة
        health = vehicleData.health or 1000
        fuel = vehicleData.fuel or 100
        outputDebugString("[GARAGE] 🔍 استخدام الحالة المخزنة: الصحة " .. health .. " - الوقود " .. fuel)
    end
    
    -- تكلفة الإصلاح بناءً على الحالة الحقيقية
    if health < 800 then
        local damagePercentage = (1000 - health) / 1000
        cost = cost + (VEHICLE_PRICES.DAMAGE_REPAIR * damagePercentage)
    end
    
    -- تكلفة الوقود بناءً على الحالة الحقيقية
    if fuel < 30 then
        local fuelNeeded = 100 - fuel
        cost = cost + (VEHICLE_PRICES.LOW_FUEL * (fuelNeeded / 100))
    end
    
    -- تكلفة المسافة البعيدة
    if isVehicleFarFromPlayer(player, vehicleData) then
        cost = cost + VEHICLE_PRICES.FAR_DISTANCE
    end
    
    -- تكلفة الاستدعاء العاجل (إذا كانت السيارة ليست في الجراج)
    if not vehicleData.is_stored or vehicleData.is_stored == 0 then
        cost = cost + VEHICLE_PRICES.URGENT_CALL
    end
    
    -- تقريب السعر لأقرب 50
    cost = math.floor((cost + 49) / 50) * 50
    
    return math.max(cost, VEHICLE_PRICES.BASE_CALL), health, fuel
end

-- دالة محسنة لحساب تكلفة الإخراج بناءً على الحالة الحقيقية
function calculateRetrieveCostReal(health, fuel, isCall)
    local cost = isCall and VEHICLE_PRICES.BASE_CALL or VEHICLE_PRICES.BASE_RETRIEVE
    
    -- حساب تكلفة الإصلاح بناءً على الصحة الحقيقية
    if health < 800 then
        local damagePercentage = (1000 - health) / 1000
        cost = cost + (VEHICLE_PRICES.DAMAGE_REPAIR * damagePercentage)
    end
    
    -- حساب تكلفة الوقود بناءً على الحالة الحقيقية
    if fuel < 30 then
        local fuelNeeded = 100 - fuel
        cost = cost + (VEHICLE_PRICES.LOW_FUEL * (fuelNeeded / 100))
    end
    
    -- تقريب السعر لأقرب 50
    cost = math.floor((cost + 49) / 50) * 50
    
    return math.max(cost, isCall and VEHICLE_PRICES.BASE_CALL or VEHICLE_PRICES.BASE_RETRIEVE)
end

-- حدث فتح الجراج
addEvent("onPlayerGarageInteract", true)
addEventHandler("onPlayerGarageInteract", root, function(garageID)
    local player = client
    local playerName = getPlayerName(player)
    
    outputDebugString("[GARAGE] 🔍 البحث عن سيارات للاعب: " .. playerName .. " في الجراج: " .. garageID)
    
    local vehicles = {}
    
    -- 🆕 إصلاح: تغيير stored إلى is_stored
    local success1, result1 = pcall(function()
        local qh = dbQuery(dbConn, "SELECT * FROM garage_vehicles WHERE `is_stored` = 1")
        if qh then
            local res = dbPoll(qh, 1000) or {}
            local filtered = {}
            for _, car in ipairs(res) do
                if (car.owner_name and car.owner_name == playerName) or 
                   (car.vehicle_id and string.find(car.vehicle_id, playerName)) then
                    table.insert(filtered, car)
                end
            end
            return filtered
        end
        return {}
    end)
    
    if success1 then
        vehicles = result1
        outputDebugString("[GARAGE] 📊 عدد السيارات في garage_vehicles: " .. #vehicles)
    end
    
    -- البحث في dealership_vehicles
    if #vehicles == 0 then
        outputDebugString("[GARAGE] 🔍 البحث في جدول المعرض...")
        local success2, result2 = pcall(function()
            local qh = dbQuery(dbConn, "SELECT * FROM dealership_vehicles WHERE owner_name = ?", playerName)
            if qh then
                return dbPoll(qh, 1000) or {}
            end
            return {}
        end)
        
        if success2 and result2 then
            for _, vehicle in ipairs(result2) do
                -- 🔧 التحقق من الحالة الحقيقية للسيارة
                local realStatus = getVehicleRealStatus(vehicle.vehicle_id)
                local actualHealth = realStatus.exists and realStatus.health or 1000
                local actualFuel = realStatus.exists and realStatus.fuel or 100
                
                table.insert(vehicles, {
                    id = vehicle.id,
                    vehicle_id = vehicle.vehicle_id,
                    vehicle_model = vehicle.vehicle_model,
                    vehicle_name = vehicle.vehicle_name or "سيارة",
                    color1 = vehicle.color1 or 0,
                    color2 = vehicle.color2 or 0,
                    color3 = vehicle.color3 or 0,
                    color4 = vehicle.color4 or 0,
                    health = actualHealth,
                    fuel = actualFuel,
                    is_stored = 1,
                    owner_name = vehicle.owner_name,
                    cost = calculateRetrieveCostReal(actualHealth, actualFuel, false)
                })
            end
            outputDebugString("[GARAGE] ✅ تم العثور على " .. #result2 .. " سيارة من المعرض")
        end
    end

    if #vehicles == 0 then
        outputDebugString("[GARAGE] ⚠️ لا توجد سيارات مخزنة للاعب: " .. playerName)
        outputChatBox("🚗 لا توجد سيارات مخزنة في الجراج", player, 255, 255, 0)
        outputChatBox("💡 يمكنك شراء سيارة من المعرض وتخزينها هنا", player, 200, 200, 200)
        return
    end

    -- تحديث عرض التكلفة في الجراج بناءً على الحالة الحقيقية
    for _, car in ipairs(vehicles) do
        -- 🔧 التحقق من الحالة الحقيقية للسيارة
        local realStatus = getVehicleRealStatus(car.vehicle_id)
        local actualHealth = realStatus.exists and realStatus.health or (car.health or 1000)
        local actualFuel = realStatus.exists and realStatus.fuel or (car.fuel or 100)
        
        car.cost = calculateRetrieveCostReal(actualHealth, actualFuel, false)
        car.actual_health = actualHealth  -- إضافة الحالة الحقيقية للعرض
        car.actual_fuel = actualFuel      -- إضافة الوقود الحقيقي للعرض
        
        if not car.vehicle_name then
            car.vehicle_name = getVehicleNameFromModel(car.vehicle_model) or "سيارة"
        end
    end

    triggerClientEvent(player, "openGarageGUI", player, vehicles, garageID)
    outputDebugString("[GARAGE] ✅ تم إرسال " .. #vehicles .. " سيارة للواجهة")
end)

function getVehicleNameFromModel(modelId)
    local vehicleNames = {
        [401] = "Kia Forte",
        [445] = "Admiral", 
        [402] = "Ford Mustang",
        [411] = "Infernus",
        [415] = "Cheetah",
        [451] = "Turismo",
        [541] = "Bullet",
        [560] = "Sultan",
        [562] = "Elegy",
        [565] = "Flash"
    }
    return vehicleNames[tonumber(modelId)] or "مركبة " .. tostring(modelId)
end

function getVehicleDataFromDB(vehicleDBId)
    local success1, result1 = pcall(function()
        local qh = dbQuery(dbConn, "SELECT * FROM garage_vehicles WHERE id = ?", tonumber(vehicleDBId))
        if qh then
            return dbPoll(qh, 1000)
        end
        return nil
    end)
    
    if success1 and result1 and #result1 > 0 then
        return result1[1]
    end
    
    local success2, result2 = pcall(function()
        local qh = dbQuery(dbConn, "SELECT * FROM dealership_vehicles WHERE id = ?", tonumber(vehicleDBId))
        if qh then
            return dbPoll(qh, 1000)
        end
        return nil
    end)
    
    if success2 and result2 and #result2 > 0 then
        local vehicle = result2[1]
        return {
            id = vehicle.id,
            vehicle_id = vehicle.vehicle_id,
            vehicle_model = vehicle.vehicle_model,
            vehicle_name = vehicle.vehicle_name,
            color1 = vehicle.color1,
            color2 = vehicle.color2,
            color3 = vehicle.color3,
            color4 = vehicle.color4,
            health = 1000,
            fuel = 100,
            posX = 0, posY = 0, posZ = 0,
            rotZ = 0
        }
    end
    
    return nil
end

function isVehicleOwner(player, vehicleData)
    local playerName = getPlayerName(player)
    
    if vehicleData.vehicle_id and string.find(vehicleData.vehicle_id, playerName) then
        return true
    end
    
    if vehicleData.owner_name and vehicleData.owner_name == playerName then
        return true
    end
    
    return false
end

function createGarageVehicle(player, vehicleData, garagePos)
    local spawnX = garagePos.x + 3
    local spawnY = garagePos.y
    local spawnZ = garagePos.z + 0.5
    
    -- 🔍 البحث عن موقع فارغ للإسباون
    local freeX, freeY, freeZ = findFreeSpawnPosition(spawnX, spawnY, spawnZ)
    
    -- استخدام الاتجاه المخزن إذا كان متوفراً
    local rotation = vehicleData.rotZ or 0
    
    local vehicle = createVehicle(vehicleData.vehicle_model, freeX, freeY, freeZ, 0, 0, rotation)
    
    if vehicle then
        -- 🔧 تطبيق الألوان المخزنة بدقة - استخدام جميع الألوان الأربعة
        setVehicleColor(vehicle, 
            vehicleData.color1 or 0, 
            vehicleData.color2 or 0, 
            vehicleData.color3 or 0, 
            vehicleData.color4 or 0
        )
        
        -- تسجيل الملكية
        registerVehicleOwner(vehicle, player, vehicleData.vehicle_id)
        
        setElementData(vehicle, "vehicle.model", vehicleData.vehicle_model)
        setElementData(vehicle, "vehicle.name", vehicleData.vehicle_name)
        setElementData(vehicle, "vehicle.owner", player)
        setElementData(vehicle, "vehicle.id", vehicleData.vehicle_id)
        setElementData(vehicle, "vehicle.color1", vehicleData.color1)
        setElementData(vehicle, "vehicle.color2", vehicleData.color2)
        setElementData(vehicle, "vehicle.color3", vehicleData.color3)
        setElementData(vehicle, "vehicle.color4", vehicleData.color4)
        
        outputDebugString("[GARAGE] 🎨 تم تطبيق الألوان: " .. (vehicleData.color1 or 0) .. "," .. (vehicleData.color2 or 0) .. "," .. (vehicleData.color3 or 0) .. "," .. (vehicleData.color4 or 0))
        
        warpPedIntoVehicle(player, vehicle)
        return vehicle
    end
    
    return false
end

-- دالة لتحميل الألوان بشكل صحيح من قاعدة البيانات
function loadVehicleColors(vehicleData)
    if not vehicleData then return {0, 0, 0, 0} end
    
    local colors = {
        vehicleData.color1 or 0,
        vehicleData.color2 or 0,
        vehicleData.color3 or 0,
        vehicleData.color4 or 0
    }
    
    outputDebugString("[COLOR_SYSTEM] 🎨 تحميل الألوان: " .. colors[1] .. "," .. colors[2] .. "," .. colors[3] .. "," .. colors[4])
    return colors
end

-- دالة لإيجاد موقع فارغ للإسباون
function findFreeSpawnPosition(x, y, z)
    local positions = {
        {x = x, y = y, z = z},
        {x = x + 2, y = y, z = z},
        {x = x, y = y + 2, z = z},
        {x = x - 2, y = y, z = z},
        {x = x, y = y - 2, z = z},
        {x = x + 4, y = y, z = z},
        {x = x, y = y + 4, z = z}
    }
    
    for _, pos in ipairs(positions) do
        local vehicles = getElementsWithinRange(pos.x, pos.y, pos.z, 2, "vehicle")
        if #vehicles == 0 then
            return pos.x, pos.y, pos.z
        end
    end
    
    -- إذا لم يجد موقع فارغ، يستخدم الموقع الأصلي
    return x, y, z
end

-- دالة مساعدة للتحقق من العناصر في النطاق
function getElementsWithinRange(x, y, z, range, elementType)
    local elements = {}
    local allElements = getElementsByType(elementType)
    
    for _, element in ipairs(allElements) do
        local ex, ey, ez = getElementPosition(element)
        local distance = getDistanceBetweenPoints3D(x, y, z, ex, ey, ez)
        if distance <= range then
            table.insert(elements, element)
        end
    end
    
    return elements
end

-- 🆕 إصلاح: تغيير stored إلى is_stored
function updateVehicleStorageStatus(vehicleDBId, stored)
    local success, result = pcall(function()
        return dbExec(dbConn, "UPDATE garage_vehicles SET `is_stored` = ? WHERE id = ?", stored, vehicleDBId)
    end)
    
    if not success then
        outputDebugString("[GARAGE] ⚠️ فشل تحديث حالة التخزين: " .. tostring(result))
    end
end

function getGaragePosition(garageID)
    if garageID == 1 then
        return {x = 1128.1207275391, y = -931.78747558594, z = 43.0}
    end

    local success, result = pcall(function()
        local qh = dbQuery(dbConn, "SELECT position_x, position_y, position_z FROM garages WHERE id = ?", garageID)
        if qh then
            return dbPoll(qh, 1000)
        end
        return nil
    end)
    
    if success and result and #result > 0 then
        return {
            x = result[1].position_x,
            y = result[1].position_y, 
            z = result[1].position_z
        }
    end
    
    return nil
end

-- حدث تخزين السيارة في الجراج - الإصدار المحسّن
addEvent("storeVehicleInGarage", true)
addEventHandler("storeVehicleInGarage", root, function(garageId)
    local player = client
    local vehicle = getPedOccupiedVehicle(player)
    
    if not vehicle then
        outputChatBox("❌ يجب أن تكون داخل السيارة لتخزينها", player, 255, 0, 0)
        return false
    end
    
    local owner = getElementData(vehicle, "vehicle.owner")
    if owner ~= player then
        outputChatBox("❌ هذه السيارة ليست ملكك", player, 255, 0, 0)
        return false
    end
    
    if not hasCarKey(player, vehicle) then
        outputChatBox("❌ ليس لديك مفتاح هذه السيارة", player, 255, 0, 0)
        return false
    end
    
    -- 🔧 الحصول على بيانات السيارة الحقيقية
    local vehicleHealth = getElementHealth(vehicle)
    local vehicleFuel = getElementData(vehicle, "fuel") or 100
    local vehicleId = getElementData(vehicle, "vehicle.id")
    
    -- 🔧 الحصول على الألوان الحقيقية للسيارة
    local color1, color2, color3, color4 = getVehicleColor(vehicle)
    
    -- 🔧 الحصول على الموقع والاتجاه الحالي
    local posX, posY, posZ = getElementPosition(vehicle)
    local rotX, rotY, rotZ = getElementRotation(vehicle)
    
    local vehicleData = {
        id = vehicleId,
        model = getElementModel(vehicle),
        name = getElementData(vehicle, "vehicle.name"),
        color1 = color1,
        color2 = color2,
        color3 = color3,
        color4 = color4,
        posX = posX,
        posY = posY, 
        posZ = posZ,
        rotZ = rotZ,
        health = vehicleHealth,
        fuel = vehicleFuel
    }
    
    outputDebugString("[GARAGE] 💾 جاري تخزين السيارة: " .. vehicleId .. " - الصحة: " .. vehicleHealth .. " - الوقود: " .. vehicleFuel .. " - الألوان: " .. color1 .. "," .. color2 .. "," .. color3 .. "," .. color4)
    
    -- 🔄 التحقق إذا السيارة مسجلة مسبقاً في الجراج لتحديث بياناتها
    local existingRecord = getVehicleRecordFromDB(vehicleId)
    
    local success, result
    if existingRecord then
        -- تحديث البيانات الحالية
        success, result = pcall(function()
            return dbExec(dbConn, 
                "UPDATE garage_vehicles SET garage_id = ?, vehicle_model = ?, vehicle_name = ?, color1 = ?, color2 = ?, color3 = ?, color4 = ?, posX = ?, posY = ?, posZ = ?, rotZ = ?, health = ?, fuel = ?, `is_stored` = ?, owner_name = ? WHERE vehicle_id = ?",
                garageId, vehicleData.model, vehicleData.name, vehicleData.color1, vehicleData.color2, vehicleData.color3, vehicleData.color4,
                vehicleData.posX, vehicleData.posY, vehicleData.posZ, vehicleData.rotZ, 
                vehicleData.health, vehicleData.fuel, 1, getPlayerName(player), vehicleId
            )
        end)
    else
        -- إضافة سجل جديد
        success, result = pcall(function()
            return dbExec(dbConn, 
                "INSERT INTO garage_vehicles (vehicle_id, garage_id, vehicle_model, vehicle_name, color1, color2, color3, color4, posX, posY, posZ, rotZ, health, fuel, `is_stored`, owner_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                vehicleData.id, garageId, vehicleData.model, vehicleData.name, vehicleData.color1, vehicleData.color2, vehicleData.color3, vehicleData.color4,
                vehicleData.posX, vehicleData.posY, vehicleData.posZ, vehicleData.rotZ, 
                vehicleData.health, vehicleData.fuel, 1, getPlayerName(player)
            )
        end)
    end
    
    if success and result then
        destroyElement(vehicle)
        outputChatBox("✅ تم تخزين السيارة في الجراج بنجاح", player, 0, 255, 0)
        outputChatBox("📊 حالة السيارة: الصحة " .. math.floor(vehicleHealth/10) .. "% - الوقود " .. vehicleFuel .. "%", player, 200, 200, 0)
        outputDebugString("[GARAGE] ✅ تم تخزين السيارة: " .. vehicleData.id .. " - الصحة: " .. vehicleHealth .. " - الألوان: " .. color1 .. "," .. color2 .. "," .. color3 .. "," .. color4)
        return true
    else
        outputChatBox("❌ فشل في تخزين السيارة", player, 255, 0, 0)
        outputDebugString("[GARAGE] ❌ فشل في تخزين قاعدة البيانات: " .. tostring(result))
        return false
    end
end)

-- دالة للبحث عن سجل السيارة في قاعدة البيانات
function getVehicleRecordFromDB(vehicleId)
    local success, result = pcall(function()
        local qh = dbQuery(dbConn, "SELECT * FROM garage_vehicles WHERE vehicle_id = ?", vehicleId)
        if qh then
            return dbPoll(qh, 1000)
        end
        return nil
    end)
    
    if success and result and #result > 0 then
        return result[1]
    end
    
    return nil
end

-- حدث إخراج السيارة من الجراج - الإصدار المحسّن بالحالة الحقيقية
addEvent("spawnGarageVehicle", true)
addEventHandler("spawnGarageVehicle", root, function(vehicleDBId, garageID)
    local player = client
    outputDebugString("[GARAGE] 🚗 طلب إخراج سيارة ID: " .. tostring(vehicleDBId))
    
    local vehicleData = getVehicleDataFromDB(vehicleDBId)
    
    if not vehicleData then
        outputChatBox("❌ لم يتم العثور على بيانات السيارة", player, 255, 0, 0)
        return
    end
    
    if not isVehicleOwner(player, vehicleData) then
        outputChatBox("❌ هذه السيارة ليست ملكك", player, 255, 0, 0)
        return
    end
    
    -- 🔧 الحصول على الحالة الحقيقية للسيارة
    local realStatus = getVehicleRealStatus(vehicleData.vehicle_id)
    
    -- التحقق إذا السيارة موجودة بالفعل في العالم
    if realStatus.exists then
        outputDebugString("[GARAGE] ⚠️ السيارة موجودة بالفعل في العالم، جاري إزالتها: " .. vehicleData.vehicle_id)
        destroyElement(realStatus.vehicle)
        outputChatBox("🔄 تم إزالة النسخة الحالية من السيارة", player, 255, 255, 0)
    end
    
    -- 🔧 استخدام الحالة الحقيقية إذا كانت السيارة موجودة، وإلا استخدام الحالة المخزنة
    local actualHealth = realStatus.exists and realStatus.health or (vehicleData.health or 1000)
    local actualFuel = realStatus.exists and realStatus.fuel or (vehicleData.fuel or 100)
    
    -- حساب تكلفة الإخراج بناءً على الحالة الحقيقية
    local cost = calculateRetrieveCostReal(actualHealth, actualFuel, false)
    
    -- التحقق من رصيد اللاعب
    if getPlayerMoney(player) < cost then
        outputChatBox("❌ ليس لديك ما يكفي من المال. التكلفة: $" .. cost, player, 255, 0, 0)
        outputChatBox("💵 رصيدك الحالي: $" .. getPlayerMoney(player), player, 255, 255, 0)
        return
    end
    
    -- خصم المال
    takePlayerMoney(player, cost)
    
    local garagePos = getGaragePosition(garageID)
    if not garagePos then
        outputChatBox("❌ موقع الجراج غير متاح", player, 255, 0, 0)
        givePlayerMoney(player, cost) -- إرجاع المال
        return
    end
    
    local vehicle = createGarageVehicle(player, vehicleData, garagePos)
    
    if vehicle then
        -- 🔧 إصلاح السيارة بالكامل عند الإخراج من الجراج
        fixVehicle(vehicle)
        setElementHealth(vehicle, 1000) -- صحة كاملة
        setElementData(vehicle, "fuel", 100) -- وقود كامل
        
        updateVehicleStorageStatus(vehicleData.id, 0)
        
        -- رسالة حسب الحالة الحقيقية للسيارة
        local message = "✅ تم إخراج " .. (vehicleData.vehicle_name or "السيارة") .. " من الجراج"
        local details = ""
        
        if actualHealth < 800 then
            details = details .. "🔧 تم إصلاح السيارة بالكامل\n"
        else
            details = details .. "🔧 الصحة الحالية: 100%\n"
        end
        
        if actualFuel < 30 then
            details = details .. "⛽ تم تعبة الوقود بالكامل\n"
        else
            details = details .. "⛽ الوقود الحالي: 100%\n"
        end
        
        outputChatBox(message, player, 0, 255, 0)
        outputChatBox(details, player, 255, 255, 0)
        
        -- عرض تفاصيل التكلفة بناءً على الحالة الحقيقية
        outputChatBox("💵 تفاصيل التكلفة:", player, 255, 255, 0)
        outputChatBox("   - سعر الأساس: $" .. VEHICLE_PRICES.BASE_RETRIEVE, player, 200, 200, 200)
        
        if actualHealth < 800 then
            local repairCost = VEHICLE_PRICES.DAMAGE_REPAIR * ((1000 - actualHealth) / 1000)
            outputChatBox("   - إصلاح تلف: $" .. math.floor(repairCost), player, 255, 100, 100)
        end
        
        if actualFuel < 30 then
            outputChatBox("   - تعبة وقود: $" .. VEHICLE_PRICES.LOW_FUEL, player, 100, 200, 255)
        end
        
        outputChatBox("   - المجموع: $" .. cost, player, 255, 255, 0)
        
        outputDebugString("[GARAGE] ✅ تم إخراج السيارة: " .. tostring(vehicleData.vehicle_id) .. " - التكلفة: $" .. cost .. " - الصحة الحقيقية: " .. actualHealth .. " - الوقود الحقيقي: " .. actualFuel .. " - الألوان: " .. (vehicleData.color1 or 0) .. "," .. (vehicleData.color2 or 0) .. "," .. (vehicleData.color3 or 0) .. "," .. (vehicleData.color4 or 0))
    else
        outputChatBox("❌ فشل في إخراج السيارة", player, 255, 0, 0)
        givePlayerMoney(player, cost) -- إرجاع المال في حالة الفشل
    end
end)

-- دالة للتحقق إذا السيارة بعيدة عن اللاعب
function isVehicleFarFromPlayer(player, vehicleData)
    if not vehicleData.posX or vehicleData.posX == 0 then
        return true -- إذا لا يوجد موقع مسجل، تعتبر بعيدة
    end
    
    local playerX, playerY, playerZ = getElementPosition(player)
    local distance = getDistanceBetweenPoints3D(playerX, playerY, playerZ, vehicleData.posX, vehicleData.posY, vehicleData.posZ)
    
    -- إذا المسافة أكثر من 100 متر تعتبر بعيدة
    return distance > 100
end

-- دالة محسنة للتحقق من وجود السيارة خارج الجراج
function isVehicleAlreadySpawned(vehicleId)
    for _, vehicle in ipairs(getElementsByType("vehicle")) do
        local existingId = getElementData(vehicle, "vehicle.id")
        if existingId and existingId == vehicleId then
            return vehicle
        end
    end
    return false
end

-- أمر لاستدعاء السيارة من أي مكان - الإصدار المحسّن بالحالة الحقيقية
-- حدث استدعاء السيارة - الإصدار المحسّن
addCommandHandler("callcar", function(player, cmd, vehicleId)
    if not vehicleId then
        outputChatBox("استخدم: /callcar [معرف السيارة]", player, 255, 255, 0)
        outputChatBox("💡 يمكنك معرفة معرف السيارة من خلال فحص الجراج /checkgarage", player, 200, 200, 200)
        return
    end
    
    local playerName = getPlayerName(player)
    outputDebugString("[GARAGE] 📞 طلب استدعاء سيارة: " .. vehicleId .. " للاعب: " .. playerName)
    
    -- البحث عن السيارة في قاعدة البيانات
    local vehicleData = getVehicleDataByID(vehicleId, playerName)
    
    if not vehicleData then
        outputChatBox("❌ لم يتم العثور على سيارة بهذا المعرف", player, 255, 0, 0)
        return
    end
    
    if not isVehicleOwner(player, vehicleData) then
        outputChatBox("❌ هذه السيارة ليست ملكك", player, 255, 0, 0)
        return
    end
    
    -- 🔧 الحصول على الحالة الحقيقية للسيارة
    local realStatus = getVehicleRealStatus(vehicleData.vehicle_id)
    
    -- التحقق إذا السيارة موجودة بالفعل في العالم
    if realStatus.exists then
        outputDebugString("[GARAGE] ⚠️ السيارة موجودة بالفعل في العالم، جاري إزالتها: " .. vehicleData.vehicle_id)
        destroyElement(realStatus.vehicle)
        outputChatBox("🔄 تم إزالة النسخة الحالية من السيارة", player, 255, 255, 0)
    end
    
    -- 🔧 حساب التكلفة بناءً على الحالة الحقيقية
    local cost, actualHealth, actualFuel = calculateCallCostReal(vehicleData, player)
    
    if getPlayerMoney(player) < cost then
        outputChatBox("❌ ليس لديك ما يكفي من المال. التكلفة: $" .. cost, player, 255, 0, 0)
        outputChatBox("💵 رصيدك الحالي: $" .. getPlayerMoney(player), player, 255, 255, 0)
        return
    end
    
    -- خصم المال
    takePlayerMoney(player, cost)
    
    -- إنشاء السيارة أمام اللاعب
    local playerX, playerY, playerZ = getElementPosition(player)
    local rotation = getPedRotation(player)
    
    -- حساب موقع أمام اللاعب
    local forwardX = playerX + math.sin(math.rad(rotation)) * 5
    local forwardY = playerY + math.cos(math.rad(rotation)) * 5
    
    local vehicle = createVehicle(vehicleData.vehicle_model, forwardX, forwardY, playerZ, 0, 0, rotation)
    
    if vehicle then
        -- 🔧 تطبيق الألوان المخزنة بدقة - التحديث هنا
        setVehicleColor(vehicle, 
            vehicleData.color1 or 0, 
            vehicleData.color2 or 0, 
            vehicleData.color3 or 0, 
            vehicleData.color4 or 0
        )
        
        -- تسجيل الملكية
        registerVehicleOwner(vehicle, player, vehicleData.vehicle_id)
        
        setElementData(vehicle, "vehicle.model", vehicleData.vehicle_model)
        setElementData(vehicle, "vehicle.name", vehicleData.vehicle_name)
        setElementData(vehicle, "vehicle.owner", player)
        setElementData(vehicle, "vehicle.id", vehicleData.vehicle_id)
        setElementData(vehicle, "vehicle.color1", vehicleData.color1 or 0)
        setElementData(vehicle, "vehicle.color2", vehicleData.color2 or 0)
        setElementData(vehicle, "vehicle.color3", vehicleData.color3 or 0)
        setElementData(vehicle, "vehicle.color4", vehicleData.color4 or 0)
        
        -- 🔧 إصلاح السيارة بالكامل عند الاستدعاء
        fixVehicle(vehicle)
        setElementHealth(vehicle, 1000) -- صحة كاملة
        setElementData(vehicle, "fuel", 100) -- وقود كامل
        
        outputChatBox("✅ تم استدعاء " .. (vehicleData.vehicle_name or "السيارة") .. " أمامك", player, 0, 255, 0)
        outputChatBox("🎨 الألوان: " .. (vehicleData.color1 or 0) .. "," .. (vehicleData.color2 or 0) .. "," .. (vehicleData.color3 or 0) .. "," .. (vehicleData.color4 or 0), player, 200, 200, 200)
        
        -- عرض تفاصيل التكلفة بناءً على الحالة الحقيقية
        outputChatBox("💵 تفاصيل التكلفة:", player, 255, 255, 0)
        outputChatBox("   - سعر الأساس: $" .. VEHICLE_PRICES.BASE_CALL, player, 200, 200, 200)
        
        if actualHealth < 800 then
            local repairCost = VEHICLE_PRICES.DAMAGE_REPAIR * ((1000 - actualHealth) / 1000)
            outputChatBox("   - إصلاح تلف: $" .. math.floor(repairCost), player, 255, 100, 100)
        end
        
        if actualFuel < 30 then
            outputChatBox("   - تعبة وقود: $" .. VEHICLE_PRICES.LOW_FUEL, player, 100, 200, 255)
        end
        
        if isVehicleFarFromPlayer(player, vehicleData) then
            outputChatBox("   - مسافة بعيدة: $" .. VEHICLE_PRICES.FAR_DISTANCE, player, 255, 200, 100)
        end
        
        if not vehicleData.is_stored or vehicleData.is_stored == 0 then
            outputChatBox("   - استدعاء عاجل: $" .. VEHICLE_PRICES.URGENT_CALL, player, 255, 150, 150)
        end
        
        outputChatBox("   - المجموع: $" .. cost, player, 255, 255, 0)
        
        outputDebugString("[GARAGE] ✅ تم استدعاء السيارة: " .. vehicleData.vehicle_id .. " - الألوان: " .. (vehicleData.color1 or 0) .. "," .. (vehicleData.color2 or 0) .. "," .. (vehicleData.color3 or 0) .. "," .. (vehicleData.color4 or 0))
    else
        outputChatBox("❌ فشل في استدعاء السيارة", player, 255, 0, 0)
        givePlayerMoney(player, cost) -- إرجاع المال
    end
end)

-- دالة مساعدة للبحث عن سيارة بالمعرف
function getVehicleDataByID(vehicleId, playerName)
    -- البحث في garage_vehicles
    local success1, result1 = pcall(function()
        local qh = dbQuery(dbConn, "SELECT * FROM garage_vehicles WHERE vehicle_id = ?", vehicleId)
        if qh then
            return dbPoll(qh, 1000)
        end
        return nil
    end)
    
    if success1 and result1 and #result1 > 0 then
        return result1[1]
    end
    
    -- البحث في dealership_vehicles
    local success2, result2 = pcall(function()
        local qh = dbQuery(dbConn, "SELECT * FROM dealership_vehicles WHERE vehicle_id = ?", vehicleId)
        if qh then
            return dbPoll(qh, 1000)
        end
        return nil
    end)
    
    if success2 and result2 and #result2 > 0 then
        local vehicle = result2[1]
        return {
            id = vehicle.id,
            vehicle_id = vehicle.vehicle_id,
            vehicle_model = vehicle.vehicle_model,
            vehicle_name = vehicle.vehicle_name,
            color1 = vehicle.color1,
            color2 = vehicle.color2,
            color3 = vehicle.color3,
            color4 = vehicle.color4,
            health = 1000,
            fuel = 100,
            posX = 0, posY = 0, posZ = 0,
            rotZ = 0,
            is_stored = 0
        }
    end
    
    return nil
end

-- =========================
-- نظام car_system
-- =========================
-- دوال مساعدة
local function getPlayerFromPartialName(name)
    if not name then return false end
    name = string.lower(name)
    for _, pl in ipairs(getElementsByType("player")) do
        if string.find(string.lower(getPlayerName(pl)), name, 1, true) then
            return pl
        end
    end
    return false
end

local function getPlayerAccountNameSafe(player)
    local acc = getPlayerAccount(player)
    if acc and isGuestAccount(acc) == false then
        return getAccountName(acc)
    end
    return getPlayerName(player)
end

function isPlayerAdmin(player)
    if not isElement(player) then return false end
    local acc = getPlayerAccount(player)
    if not acc or isGuestAccount(acc) then return false end
    return hasObjectPermissionTo(player, "general.tab_players", false) or
           hasObjectPermissionTo(player, "command.kick", false) or
           hasObjectPermissionTo(player, "command.ban", false)
end

-- أمر إعطاء المفتاح
addCommandHandler("givecar", function(admin, cmd, targetName)
    if not isPlayerAdmin(admin) then
        outputChatBox("🚫 هذا الأمر مخصص للمشرفين فقط.", admin, 255, 80, 80)
        return
    end

    if not targetName then
        outputChatBox("استخدم: /givecar [اسم اللاعب]", admin, 255, 255, 0)
        return
    end

    local target = getPlayerFromPartialName(targetName)
    if not target then
        outputChatBox("❌ اللاعب غير موجود.", admin, 255, 80, 80)
        return
    end

    local veh = getPedOccupiedVehicle(admin)
    if not veh then
        outputChatBox("❌ لازم تكون راكب عربية علشان تدّي مفتاح.", admin, 255, 80, 80)
        return
    end

    -- التصحيح: استخدام vehicle.id بدلاً من getElementID
    local vehID = getElementData(veh, "vehicle.id")
    if not vehID or vehID == "" then
        vehID = "veh_" .. tostring(getTickCount())
        setElementData(veh, "vehicle.id", vehID)
    end

    local acctName = getPlayerAccountNameSafe(target)
    vehicleOwners[vehID] = acctName

    triggerClientEvent(target, "addInventoryItem", target, "مفتاح سيارة", "images/car_key.png", vehID)

    outputChatBox("✅ تم إعطاء مفتاح السيارة لـ " .. getPlayerName(target), admin, 0, 200, 0)
    outputChatBox("🔑 تم إضافه مفتاح سيارة إلى حقيبتك!", target, 255, 200, 0)
end)

-- 🔧 دالة تسجيل ملكية السيارة
function registerVehicleOwner(vehicle, player, vehicleId)
    if not isElement(vehicle) or not isElement(player) then
        outputDebugString("[CAR_SYSTEM] ❌ بيانات غير صالحة لتسجيل الملكية")
        return false
    end
    
    -- استخدام setElementData بدلاً من setElementID
    setElementData(vehicle, "vehicle.id", vehicleId)
    
    local acctName = getPlayerAccountNameSafe(player)
    vehicleOwners[vehicleId] = acctName
    
    outputDebugString("[CAR_SYSTEM] ✅ تم تسجيل ملكية السيارة " .. vehicleId .. " للاعب " .. getPlayerName(player))
    return true
end

-- حدث تشغيل المحرك - الإصدار المصحح
addEvent("car:tryToggleEngine", true)
addEventHandler("car:tryToggleEngine", root, function(veh)
    local player = client
    if not isElement(veh) then return end
    
    local vehID = getElementData(veh, "vehicle.id")
    if not vehID then
        triggerClientEvent(player, "car:notify", player, "❌ هذه السيارة غير مسجلة في النظام.")
        return
    end
    
    local owner = vehicleOwners[vehID]
    local playerAcct = getPlayerAccountNameSafe(player)

    if owner and owner ~= playerAcct then
        triggerClientEvent(player, "car:notify", player, "❌ المفتاح لا يخص هذه السيارة.")
        return
    end

    if not owner then
        triggerClientEvent(player, "car:notify", player, "🔒 لا توجد ملكية لهذه السيارة — لا يمكنك تشغيلها.")
        return
    end

    local current = getVehicleEngineState(veh)
    setVehicleEngineState(veh, not current)
    triggerClientEvent(player, "car:notify", player, (current and "🛑 تم إيقاف المحرك." or "🚗 تم تشغيل المحرك."))
end)

-- حدث تبديل الأنوار - الإصدار المصحح
addEvent("car:toggleLights", true)
addEventHandler("car:toggleLights", root, function(veh)
    local player = client
    if not isElement(veh) then return end
    
    local vehID = getElementData(veh, "vehicle.id")
    if not vehID then return end
        
    local owner = vehicleOwners[vehID]
    local playerAcct = getPlayerAccountNameSafe(player)

    if owner and owner ~= playerAcct then
        triggerClientEvent(player, "car:notify", player, "❌ هذه ليست سيارتك (الأضواء مقفولة).")
        return
    end

    local current = getVehicleOverrideLights(veh) or 1
    local new = (current == 2) and 1 or 2
    setVehicleOverrideLights(veh, new)
    triggerClientEvent(player, "car:notify", player, (new == 2 and "💡 الأضواء اشتغلت." or "💡 الأضواء اطفئت."))
end)

-- حدث الحزام
addEvent("car:setSeatbelt", true)
addEventHandler("car:setSeatbelt", root, function(state)
    local player = client
    playerSeatbelts[player] = state and true or false
    triggerClientEvent(player, "car:notify", player, state and "🔒 الحزام مربوط." or "🔓 الحزام مفكوك.")
end)

-- منع الخروج مع الحزام
addEventHandler("onVehicleStartExit", root, function(player, seat)
    if playerSeatbelts[player] then
        cancelEvent()
        outputChatBox("⚠️ افك الحزام قبل ما تنزل (اضغط N).", player, 255, 180, 0)
    end
end)

-- تنظيف البيانات
addEventHandler("onPlayerQuit", root, function()
    playerSeatbelts[source] = nil
    playerCarKeys[source] = nil
    playerInGarageArea[source] = nil
    playerInDealershipArea[source] = nil
end)

-- =========================
-- أوامر الفحص
-- =========================
addCommandHandler("checkgarage", function(player)
    local playerName = getPlayerName(player)
    outputChatBox("🔍 فحص سيارات الجراج لـ " .. playerName, player, 255, 255, 0)
    
    -- 🆕 إصلاح: تغيير stored إلى is_stored
    local success1, result1 = pcall(function()
        local qh = dbQuery(dbConn, "SELECT * FROM garage_vehicles WHERE `is_stored` = 1")
        if qh then
            local res = dbPoll(qh, 1000) or {}
            local filtered = {}
            for _, car in ipairs(res) do
                if (car.owner_name and car.owner_name == playerName) or 
                   (car.vehicle_id and string.find(car.vehicle_id, playerName)) then
                    table.insert(filtered, car)
                end
            end
            return filtered
        end
        return {}
    end)
    
    if success1 then
        outputChatBox("🚗 السيارات في garage_vehicles: " .. #result1, player, 255, 255, 0)
        for i, car in ipairs(result1) do
            outputChatBox("   - " .. (car.vehicle_name or "غير معروف") .. " (ID: " .. car.id .. ")", player, 200, 200, 200)
        end
    end
    
    local success2, result2 = pcall(function()
        local qh = dbQuery(dbConn, "SELECT * FROM dealership_vehicles WHERE owner_name = ?", playerName)
        if qh then
            return dbPoll(qh, 1000) or {}
        end
        return {}
    end)
    
    if success2 then
        outputChatBox("🏪 السيارات في dealership_vehicles: " .. #result2, player, 255, 255, 0)
        for i, car in ipairs(result2) do
            outputChatBox("   - " .. (car.vehicle_name or "غير معروف") .. " (ID: " .. car.id .. ")", player, 200, 200, 200)
        end
    end
end)

addCommandHandler("resetgaragetables", function(player)
    if hasObjectPermissionTo(player, "function.kickPlayer") then
        outputChatBox("🔧 جاري إعادة إنشاء جداول الجراج...", player, 255, 255, 0)
        
        createSystemTables()
        
        outputChatBox("✅ تم إعادة إنشاء الجداول بنجاح", player, 0, 255, 0)
        outputDebugString("[CAR_SYSTEM] ✅ تم إعادة إنشاء الجداول بواسطة " .. getPlayerName(player))
    else
        outputChatBox("❌ ليس لديك صلاحية لهذا الأمر", player, 255, 0, 0)
    end
end)

addCommandHandler("fixcarlsystem", function(player)
    if hasObjectPermissionTo(player, "function.kickPlayer") then
        outputChatBox("🔧 جاري إصلاح نظام السيارات...", player, 255, 255, 0)
        
        -- إعادة إنشاء الجداول
        createSystemTables()
        checkDatabaseTables()
        
        -- إعادة تحميل الأنظمة
        setupDealerships()
        loadAllGarages()
        
        outputChatBox("✅ تم إصلاح نظام السيارات بنجاح", player, 0, 255, 0)
        outputDebugString("[CAR_SYSTEM] ✅ تم الإصلاح بواسطة " .. getPlayerName(player))
    else
        outputChatBox("❌ ليس لديك صلاحية لهذا الأمر", player, 255, 0, 0)
    end
end)

addCommandHandler("fixduplicatecars", function(player)
    if hasObjectPermissionTo(player, "function.kickPlayer") then
        outputChatBox("🔧 جاري إصلاح السيارات المكررة...", player, 255, 255, 0)
        
        local vehicles = getElementsByType("vehicle")
        local uniqueIds = {}
        local duplicates = 0
        
        for _, vehicle in ipairs(vehicles) do
            local vehicleId = getElementData(vehicle, "vehicle.id")
            if vehicleId then
                if uniqueIds[vehicleId] then
                    -- هذه سيارة مكررة
                    destroyElement(vehicle)
                    duplicates = duplicates + 1
                else
                    uniqueIds[vehicleId] = true
                end
            end
        end
        
        outputChatBox("✅ تم حذف " .. duplicates .. " سيارة مكررة", player, 0, 255, 0)
    else
        outputChatBox("❌ ليس لديك صلاحية لهذا الأمر", player, 255, 0, 0)
    end
end)

addCommandHandler("checkcar", function(player)
    local vehicle = getPedOccupiedVehicle(player)
    
    if not vehicle then
        outputChatBox("❌ يجب أن تكون داخل السيارة لفحص حالتها", player, 255, 0, 0)
        return
    end
    
    local vehicleId = getElementData(vehicle, "vehicle.id")
    if not vehicleId then
        outputChatBox("❌ هذه السيارة غير مسجلة في النظام", player, 255, 0, 0)
        return
    end
    
    local health = getElementHealth(vehicle)
    local fuel = getElementData(vehicle, "fuel") or 100
    local color1, color2, color3, color4 = getVehicleColor(vehicle)
    
    outputChatBox("🔍 فحص حالة السيارة:", player, 255, 255, 0)
    outputChatBox("   - المعرف: " .. vehicleId, player, 200, 200, 200)
    outputChatBox("   - الصحة: " .. math.floor(health/10) .. "%", player, health < 800 and {255, 100, 100} or {100, 255, 100})
    outputChatBox("   - الوقود: " .. fuel .. "%", player, fuel < 30 and {255, 200, 100} or {100, 200, 255})
    outputChatBox("   - الألوان: " .. color1 .. ", " .. color2 .. ", " .. color3 .. ", " .. color4, player, 200, 200, 255)
end)

addCommandHandler("setcarcolor",
    function(player)
        local veh = getPedOccupiedVehicle(player)
        if veh then
            setVehicleColor(veh, 200, 0, 0)  -- أحمر متوسط
            outputChatBox("تم تغيير لون السيارة إلى الأحمر.", player, 255, 0, 0)
        else
            outputChatBox("يجب أن تكون داخل سيارة!", player, 255, 0, 0)
        end
    end
)

addCommandHandler("checkcarcolors", function(player)
    local vehicle = getPedOccupiedVehicle(player)
    
    if not vehicle then
        outputChatBox("❌ يجب أن تكون داخل السيارة لفحص ألوانها", player, 255, 0, 0)
        return
    end
    
    local color1, color2, color3, color4 = getVehicleColor(vehicle)
    local vehicleId = getElementData(vehicle, "vehicle.id")
    local vehicleName = getElementData(vehicle, "vehicle.name") or "غير معروف"
    
    outputChatBox("🎨 فحص ألوان السيارة:", player, 255, 255, 0)
    outputChatBox("   - اسم السيارة: " .. vehicleName, player, 200, 200, 200)
    outputChatBox("   - المعرف: " .. (vehicleId or "غير معروف"), player, 200, 200, 200)
    outputChatBox("   - اللون 1: " .. color1, player, color1, color2, color3)
    outputChatBox("   - اللون 2: " .. color2, player, color1, color2, color3)
    outputChatBox("   - اللون 3: " .. color3, player, color1, color2, color3)
    outputChatBox("   - اللون 4: " .. color4, player, color1, color2, color3)
    
    outputDebugString("[COLOR_SYSTEM] 🎨 ألوان السيارة: " .. color1 .. "," .. color2 .. "," .. color3 .. "," .. color4)
end)

addCommandHandler("fixcolorsdb", function(player)
    if hasObjectPermissionTo(player, "function.kickPlayer") then
        outputChatBox("🔧 جاري إصلاح ألوان قاعدة البيانات...", player, 255, 255, 0)
        
        -- إصلاح الألوان في garage_vehicles
        dbExec(dbConn, "UPDATE garage_vehicles SET color3 = color1, color4 = color2 WHERE color3 IS NULL OR color4 IS NULL")
        
        -- إصلاح الألوان في dealership_vehicles  
        dbExec(dbConn, "UPDATE dealership_vehicles SET color3 = color1, color4 = color2 WHERE color3 IS NULL OR color4 IS NULL")
        
        outputChatBox("✅ تم إصلاح ألوان قاعدة البيانات بنجاح", player, 0, 255, 0)
        outputDebugString("[COLOR_SYSTEM] ✅ تم إصلاح ألوان قاعدة البيانات بواسطة " .. getPlayerName(player))
    else
        outputChatBox("❌ ليس لديك صلاحية لهذا الأمر", player, 255, 0, 0)
    end
end)

-- دالة للتحقق من جدول dealership_vehicles
function checkDealershipTable()
    if not dbConn then
        outputDebugString("[DEALERSHIP] ❌ لا يوجد اتصال بقاعدة البيانات")
        return false
    end
    
    local success, result = pcall(function()
        local qh = dbQuery(dbConn, "SHOW TABLES LIKE 'dealership_vehicles'")
        if qh then
            local res = dbPoll(qh, 1000)
            return res and #res > 0
        end
        return false
    end)
    
    if success and result then
        outputDebugString("[DEALERSHIP] ✅ جدول dealership_vehicles موجود")
        return true
    else
        outputDebugString("[DEALERSHIP] ❌ جدول dealership_vehicles غير موجود")
        -- محاولة إنشاء الجدول
        local createSuccess = dbExec(dbConn, [[
            CREATE TABLE IF NOT EXISTS dealership_vehicles (
                id INTEGER PRIMARY KEY AUTO_INCREMENT,
                vehicle_id VARCHAR(100) UNIQUE NOT NULL,
                owner_name VARCHAR(100) NOT NULL,
                vehicle_model INTEGER NOT NULL,
                vehicle_name VARCHAR(50) DEFAULT 'سيارة',
                color1 INTEGER DEFAULT 0,
                color2 INTEGER DEFAULT 0,
                color3 INTEGER DEFAULT 0,
                color4 INTEGER DEFAULT 0,
                price INTEGER DEFAULT 0,
                purchased_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ]])
        
        if createSuccess then
            outputDebugString("[DEALERSHIP] ✅ تم إنشاء جدول dealership_vehicles")
            return true
        else
            outputDebugString("[DEALERSHIP] ❌ فشل في إنشاء جدول dealership_vehicles")
            return false
        end
    end
end

-- استدعاء التحقق عند بدء التشغيل
addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[CAR_SYSTEM] 🚀 بدء تحميل النظام المتكامل...")
    
    if not initializeDatabase() then
        outputDebugString("[CAR_SYSTEM] ❌ فشل تحميل النظام بسبب مشكلة في قاعدة البيانات", 1)
        return
    end
    
    -- التحقق من الجداول أولاً
    if not checkDealershipTable() then
        outputDebugString("[CAR_SYSTEM] ⚠️ مشكلة في جدول المعرض", 2)
    end
    
    -- إنشاء الجداول الأخرى
    if not createSystemTables() then
        outputDebugString("[CAR_SYSTEM] ⚠️ هناك مشكلة في الجداول، جاري المحاولة مرة أخرى...", 2)
    end
    
    -- تحميل الأنظمة
    setupDealerships()
    loadAllGarages()
    
    outputDebugString("[CAR_SYSTEM] ✅ تم تحميل جميع الأنظمة بنجاح")
end)
-- في السيرفر
addCommandHandler("debuggarages", function(player)
    if hasObjectPermissionTo(player, "function.kickPlayer") then
        outputChatBox("🔧 فحص نظام الجراجات:", player, 255, 255, 0)
        outputChatBox("   - عدد الجراجات النشطة: " .. countTable(activeGarages), player, 200, 200, 200)
        outputChatBox("   - اتصال قاعدة البيانات: " .. tostring(dbConn and true or false), player, 200, 200, 200)
        
        for garageID, col in pairs(activeGarages) do
            if isElement(col) then
                local name = getElementData(col, "garage.name") or "غير معروف"
                outputChatBox("   - جراج #" .. garageID .. ": " .. name, player, 100, 255, 100)
            end
        end
        
        -- إعادة تحميل الجراجات
        loadAllGarages()
        outputChatBox("   - تم إعادة تحميل الجراجات", player, 0, 255, 0)
    end
end)

-- دالة مساعدة
function countTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end
-- كل الكود الحالي موجود هنا...
-- دوال إنشاء الجداول، نظام المعرض، نظام الجراج، إلخ...

-- =========================
-- 🛠️ الإصلاح: أحداث الجراج المفقودة 
-- =========================

-- هذا الحدث ينقصك - الكلينت يطلبه ولكن السيرفر لا يستجيبه
addEvent("onClientRequestGarages", true)
addEventHandler("onClientRequestGarages", root, function()
    local player = client
    outputDebugString("[GARAGE] 📦 طلب بيانات الجراجات من " .. getPlayerName(player))
    
    local garagesData = {}
    
    -- جمع بيانات الجراجات من قاعدة البيانات
    local success, result = pcall(function()
        local qh = dbQuery(dbConn, "SELECT * FROM garages")
        if qh then
            return dbPoll(qh, 1000) or {}
        end
        return {}
    end)
    
    if success and result then
        for _, garage in ipairs(result) do
            table.insert(garagesData, {
                id = garage.id,
                garage_name = garage.garage_name,
                position_x = garage.position_x,
                position_y = garage.position_y, 
                position_z = garage.position_z
            })
        end
        outputDebugString("[GARAGE] ✅ تم تحميل " .. #garagesData .. " جراج من قاعدة البيانات")
    else
        outputDebugString("[GARAGE] ⚠️ فشل تحميل الجراجات من قاعدة البيانات، استخدام البيانات الافتراضية")
        -- استخدام البيانات الافتراضية
        garagesData = {
            {id = 1, garage_name = "الجراج الرئيسي", position_x = 1128.12, position_y = -931.787, position_z = 43.0},
            {id = 2, garage_name = "جراج لوس سانتوس", position_x = 1804.25, position_y = -2141.12, position_z = 13.55},
            -- ... باقي الجراجات
        }
    end
    
    triggerClientEvent(player, "onClientReceiveGarages", player, garagesData)
end)

-- هذا الحدث الثاني الناقص
addEvent("onPlayerGarageInteract", true) 
addEventHandler("onPlayerGarageInteract", root, function(garageID)
    local player = client
    outputDebugString("[GARAGE] 🎯 تفاعل جراج #" .. garageID .. " من " .. getPlayerName(player))
    
    -- استدعاء الدالة الأصلية الموجودة في السيرفر
    triggerEvent("onPlayerGarageInteract", player, garageID)
end)

-- نهاية الملف