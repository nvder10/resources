--S System License by Nadeer
--لا تعيد نشر هذا النظام بدون إذني

-- ========== نظام إنشاء مركبات الاختبار ==========
function spawnTestVehicle(player, vehicleType)
    if not isElement(player) then return false end
    
    local vehicleModel = 410 -- Manana للسيارة
    if vehicleType == "bike" then
        vehicleModel = 468 -- Sanchez للدراجة
    end
    
    -- إحداثيات إنشاء المركبة (أمام DMV)
    local x, y, z = 1099.1564941406, -1776.0616455078, 12.946504592896
    local rotation = 89
    
    -- إنشاء المركبة
    local vehicle = createVehicle(vehicleModel, x, y, z, 0, 0, rotation)
    if not vehicle then return false end
    
    -- تعيين بيانات المركبة
    setElementData(vehicle, "owner", -2) -- ملكية الاختبار
    setElementData(vehicle, "faction", -1) -- غير تابع لأي فصيل
    setElementData(vehicle, "handbrake", 1) -- فرامل اليد
    setElementData(vehicle, "dbid", -2) -- معرف قاعدة البيانات
    setElementData(vehicle, "fuel", 100) -- ⛽ إضافة الوقود
    setElementFrozen(vehicle, true) -- تجميد المركبة حتى يبدأ اللاعب الاختبار
    
    -- تعيين اللون
    setVehicleColor(vehicle, 0, 0, 0) -- أسود
    
    -- إعطاء المفاتيح للاعب
    warpPedIntoVehicle(player, vehicle) 
    
    -- رسالة توجيهية 
    if vehicleType == "car" then
        triggerClientEvent(player, "showToast", resourceRoot, "لتشغيل المحرك `J` مركبة الإختبار جاهزة", false)
    else
        triggerClientEvent(player, "showToast", resourceRoot, "لتشغيل المحرك `J` دراجة الإختبار جاهزة", false)
    end
    
    return vehicle
end

-- ========== نظام إخفاء مركبات الاختبار ==========
function removeTestVehicle(vehicle)
    if not isElement(vehicle) then return end
    
    local owner = getElementData(vehicle, "owner")
    if owner == -2 then
        -- إخراج جميع الركاب
        local occupants = getVehicleOccupants(vehicle)
        for seat, occupant in pairs(occupants) do
            removePedFromVehicle(occupant)
        end
        
        -- تدمير المركبة
        destroyElement(vehicle)
    end
end
addEvent("removeTestVehicle", true)
addEventHandler("removeTestVehicle", root, removeTestVehicle)

-- ========== نظام الرخص الأساسي ==========
function giveCarLicense(usingGC)
    if usingGC then
        local perk = exports.donators:getPerks(22)
        local success, reason = exports.donators:takeGC(client, perk[2])
        if success then
            exports.donators:addPurchaseHistory(client, perk[1], -perk[2])
        else
            triggerClientEvent(client, "showToast", resourceRoot, "❌ Could not take GCs from your account", true)
            return false
        end
    end
    
    local theVehicle = getPedOccupiedVehicle(client)
    exports.anticheat:changeProtectedElementDataEx(client, "realinvehicle", 0, false)
    removePedFromVehicle(client)
    if theVehicle then 
        -- إخفاء المركبة بدلاً من إعادة ظهورها
        removeTestVehicle(theVehicle)
    end
    exports.anticheat:changeProtectedElementDataEx(client, "license.car", 1)
    dbExec(exports.mysql:getConn('mta'), "UPDATE characters SET car_license='1' WHERE id = ?", getElementData(client, 'dbid'))
    triggerClientEvent(client, "showToast", resourceRoot, "نجحت في اختبار القيادة!", false)
    exports.global:giveItem(client, 133, getPlayerName(client):gsub("_"," "))
    executeCommandHandler("stats", client, getPlayerName(client))
    
    -- تنظيف المركبة
    cleanupTestVehicle(client)
end

function giveBikeLicense(usingGC)
    if usingGC then
        local perk = exports.donators:getPerks(22)
        local success, reason = exports.donators:takeGC(client, perk[2])
        if success then
            exports.donators:addPurchaseHistory(client, perk[1], -perk[2])
        else
            triggerClientEvent(client, "showToast", resourceRoot, "❌ Could not take GCs from your account", true)
            return false
        end
    end
    
    local theVehicle = getPedOccupiedVehicle(client)
    exports.anticheat:changeProtectedElementDataEx(client, "realinvehicle", 0, false)
    removePedFromVehicle(client)
    if theVehicle then
        -- إخفاء المركبة بدلاً من إعادة ظهورها
        removeTestVehicle(theVehicle)
    end
    
    exports.anticheat:changeProtectedElementDataEx(client, "license.bike", 1)
    dbExec(exports.mysql:getConn('mta'), "UPDATE characters SET bike_license='1' WHERE id = ?", getElementData(client, 'dbid'))
    triggerClientEvent(client, "showToast", resourceRoot, "نجحت في اختبار الدراجة!", false)
    exports.global:giveItem(client, 153, getPlayerName(client):gsub("_"," "))
    executeCommandHandler("stats", client, getPlayerName(client))
    
    -- تنظيف المركبة
    cleanupTestVehicle(client)
end

-- أحداث منح الرخص
addEvent("acceptCarLicense", true)
addEventHandler("acceptCarLicense", getRootElement(), giveCarLicense)

addEvent("acceptBikeLicense", true)
addEventHandler("acceptBikeLicense", getRootElement(), giveBikeLicense)

-- ========== نظام الاختبار النظري ==========
function passTheory()
    exports.anticheat:setEld( client, "license.car.cangetin", true, 'one' )
    exports.anticheat:setEld( client, "license.car", 3, 'one' ) -- Set data to "theory passed"
    dbExec( exports.mysql:getConn('mta'), "UPDATE characters SET car_license='3' WHERE id = ?", getElementData(client, 'dbid') )
end

function passBikeTheory()
    exports.anticheat:changeProtectedElementDataEx(client,"license.bike.cangetin",true, false)
    exports.anticheat:changeProtectedElementDataEx(client,"license.bike",3) -- Set data to "theory passed"
    dbExec( exports.mysql:getConn('mta'), "UPDATE characters SET bike_license='3' WHERE id=? ", getElementData( client, 'dbid' ) )
end

addEvent("theoryComplete", true)
addEventHandler("theoryComplete", getRootElement(), passTheory)

addEvent("theoryBikeComplete", true)
addEventHandler("theoryBikeComplete", getRootElement(), passBikeTheory)

-- ========== بدء الاختبار العملي ==========
function startPracticalTest(licenseType)
    if not client then return end
    
    if licenseType == "car" then
        -- تمرير الاختبار النظري للسيارة
        triggerEvent("theoryComplete", client, true)
        
        -- إنشاء مركبة الاختبار
        setTimer(function(player)
            if isElement(player) then
                local vehicle = spawnTestVehicle(player, "car")
                if vehicle then
                    triggerClientEvent(player, "startCarPracticalTest", resourceRoot)
                    triggerClientEvent(player, "showToast", resourceRoot, "🚗 مركبة الاختبار جاهزة - ابدأ القيادة", false)
                end
            end
        end, 2000, 1, client)
        
    elseif licenseType == "bike" then
        -- تمرير الاختبار النظري للدراجة
        triggerEvent("theoryBikeComplete", client, true)
        
        -- إنشاء دراجة الاختبار
        setTimer(function(player)
            if isElement(player) then
                local vehicle = spawnTestVehicle(player, "bike")
                if vehicle then
                    triggerClientEvent(player, "startBikePracticalTest", resourceRoot)
                    triggerClientEvent(player, "showToast", resourceRoot, "🏍️ دراجة الاختبار جاهزة - ابدأ القيادة", false)
                end
            end
        end, 2000, 1, client)
    end
end

addEvent("onTheoryTestPassed", true)
addEventHandler("onTheoryTestPassed", root, startPracticalTest)

-- ========== نظام التحقق من مركبات الاختبار ==========
function checkTestVehicleEnter(player, seat)
    if seat ~= 0 then return end -- فقط السائق
    
    local vehicle = source
    local owner = getElementData(vehicle, "owner")
    local faction = getElementData(vehicle, "faction")
    
    -- التحقق إذا كانت مركبة اختبار
    if owner == -2 and faction == -1 then
        local model = getElementModel(vehicle)
        
        if model == 410 then -- سيارة
            local licenseData = getElementData(player, "license.car")
            if licenseData ~= 3 then
                triggerClientEvent(player, "showToast", resourceRoot, "❌ يجب أن تجتاز الاختبار النظري أولاً", true)
                removePedFromVehicle(player)
                cancelEvent()
            end
            
        elseif model == 468 then -- دراجة
            local licenseData = getElementData(player, "license.bike")
            if licenseData ~= 3 then
                triggerClientEvent(player, "showToast", resourceRoot, "❌ يجب أن تجتاز الاختبار النظري أولاً", true)
                removePedFromVehicle(player)
                cancelEvent()
            end
        end
    end
end
addEventHandler("onVehicleStartEnter", root, checkTestVehicleEnter)

-- ========== تنظيف المركبات ==========
function cleanupTestVehicle(player)
    local vehicle = getPedOccupiedVehicle(player)
    if vehicle then
        local owner = getElementData(vehicle, "owner")
        if owner == -2 then
            removePedFromVehicle(player)
            setTimer(destroyElement, 3000, 1, vehicle)
        end
    end
end

-- ========== نظام رخصة الصيد ==========
addEventHandler("acceptFishLicense", root, function(usingGC)
    if not client then return end
    
    local cost = 250
    if exports.global:takeMoney(client, cost) then
        -- تحديث قاعدة البيانات
        dbExec(exports.mysql:getConn('mta'), "UPDATE characters SET fish_license='1' WHERE id = ?", getElementData(client, 'dbid'))
        
        -- تعيين بيانات اللاعب
        exports.anticheat:changeProtectedElementDataEx(client, "license.fish", 1)
        
        -- إعطاء الرخصة
        exports.global:giveItem(client, 154, getPlayerName(client):gsub("_"," "))
        
        -- إشعارات
        triggerClientEvent(client, "showToast", resourceRoot, "🎣 تم منح رخصة الصيد بنجاح!", false)
        executeCommandHandler("stats", client, getPlayerName(client))
        
        triggerClientEvent(client, "onLicenseGranted", resourceRoot, "fishing")
    else
        triggerClientEvent(client, "showToast", resourceRoot, "❌ لا تملك $"..cost.." المطلوبة لرخصة الصيد", true)
    end
end)

-- ========== نظام الدفع ==========
addEvent("payFee", true)
addEventHandler("payFee", getRootElement(), function(amount, reason)
    if exports.global:takeMoney(source, amount) then
        if not reason then
            reason = "a license"
        end
        triggerClientEvent(source, "showToast", resourceRoot, "💵 تم دفع $"..exports.global:formatMoney(amount).." للرخصة", false)
    end
end)