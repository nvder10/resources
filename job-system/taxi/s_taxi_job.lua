addEventHandler( "onVehicleRespawn", getRootElement( ),
    function( )
        if isVehicleTaxiLightOn( source ) then
            setVehicleTaxiLightOn( source, false )
        end
    end
)

addEventHandler( "onVehicleStartExit", getRootElement( ),
    function( player, seat, jacked )
        if isVehicleTaxiLightOn( source ) then
            setVehicleTaxiLightOn( source, false )
        end
    end
)

function toggleTaxiLight(thePlayer, commandName)
    local theVehicle = getPedOccupiedVehicle(thePlayer)
    if theVehicle then
        if getVehicleController(theVehicle) == thePlayer and getElementModel(theVehicle) == 438 or getElementModel(theVehicle) == 420 then
            setVehicleTaxiLightOn(theVehicle, not isVehicleTaxiLightOn(theVehicle))
        end
    end
end
addCommandHandler("taxilight", toggleTaxiLight, false, false)

-- ========== نظام طلبات التاكسي بين اللاعبين ==========
local taxiRequests = {}
local activeDrivers = {}

-- لاعب عادي يطلب تاكسي
function requestTaxi(player, commandName, price)
    local job = getElementData(player, "job") or 0
    if job == 2 then
        return -- سائق تاكسي ما يقدر يطلب
    end
    
    if taxiRequests[player] then
        return -- ممنوع طلبين
    end
    
    local x, y, z = getElementPosition(player)
    local requestedPrice = tonumber(price) or 100
    
    taxiRequests[player] = {
        x = x,
        y = y, 
        z = z,
        price = requestedPrice,
        time = getTickCount(),
        accepted = false,
        driver = nil
    }
    
    -- إرسال الطلب لسائقي التاكسي
    for _, driver in ipairs(getElementsByType("player")) do
        local driverJob = getElementData(driver, "job") or 0
        if driverJob == 2 then
            triggerClientEvent(driver, "onNewTaxiRequest", driver, player, x, y, z, requestedPrice)
        end
    end
    
    -- حذف الطلب بعد 5 دقائق
    setTimer(function()
        if taxiRequests[player] and not taxiRequests[player].accepted then
            taxiRequests[player] = nil
            for _, driver in ipairs(getElementsByType("player")) do
                local driverJob = getElementData(driver, "job") or 0
                if driverJob == 2 then
                    triggerClientEvent(driver, "removeTaxiRequest", driver, player)
                end
            end
        end
    end, 300000, 1)
end
addCommandHandler("calltaxi", requestTaxi)

-- سائق يقبل طلب تاكسي
function acceptTaxiRequest(driver, targetPlayer)
    local job = getElementData(driver, "job") or 0
    if job ~= 2 then return end
    
    if activeDrivers[driver] then return end -- عنده طلب نشط
    
    if not taxiRequests[targetPlayer] then return end -- الطلب مش موجود
    if taxiRequests[targetPlayer].accepted then return end -- الطلب متقبلش
    
    -- قبول الطلب
    taxiRequests[targetPlayer].accepted = true
    taxiRequests[targetPlayer].driver = driver
    activeDrivers[driver] = targetPlayer
    
    -- إعلام اللاعب
    triggerClientEvent(targetPlayer, "showJobToast", targetPlayer, "✅ " .. getPlayerName(driver):gsub("_", " ") .. " قبل طلبك!", false)
    
    -- إعلام السائق
    triggerClientEvent(driver, "showJobToast", driver, "✅ قبلت طلب " .. getPlayerName(targetPlayer):gsub("_", " "), false)
    
    -- إرسال إحداثيات العميل للسائق
    local request = taxiRequests[targetPlayer]
    triggerClientEvent(driver, "setTaxiPickup", driver, request.x, request.y, request.z, getPlayerName(targetPlayer))
    
    -- إزالة الطلب من السائقين الآخرين
    for _, otherDriver in ipairs(getElementsByType("player")) do
        local otherJob = getElementData(otherDriver, "job") or 0
        if otherJob == 2 and otherDriver ~= driver then
            triggerClientEvent(otherDriver, "removeTaxiRequest", otherDriver, targetPlayer)
        end
    end
end
addEvent("acceptTaxiRequest", true)
addEventHandler("acceptTaxiRequest", root, acceptTaxiRequest)

-- سائق يرفض طلب تاكسي
function rejectTaxiRequest(driver, targetPlayer)
    triggerClientEvent(driver, "removeTaxiRequest", driver, targetPlayer)
end
addEvent("rejectTaxiRequest", true)
addEventHandler("rejectTaxiRequest", root, rejectTaxiRequest)

-- إرسال فاتورة للعميل
function sendTaxiBill(driver, customer, amount)
    if not activeDrivers[driver] or activeDrivers[driver] ~= customer then
        return -- ما فيش رحلة نشطة
    end
    
    local customerMoney = getPlayerMoney(customer)
    if customerMoney >= amount then
        takePlayerMoney(customer, amount)
        givePlayerMoney(driver, amount)
        
        triggerClientEvent(driver, "showJobToast", driver, "💰 استلمت $" .. amount .. " أجرة", false)
        triggerClientEvent(customer, "showJobToast", customer, "💰 دفعت $" .. amount .. " أجرة تاكسي", false)
        
        -- تحديث إحصائيات الوظيفة
        triggerEvent("updateJobEarnings", driver, amount)
        
        -- إنهاء الرحلة
        activeDrivers[driver] = nil
        taxiRequests[customer] = nil
        
        triggerClientEvent(driver, "removeTaxiDestination", driver)
    else
        triggerClientEvent(driver, "showJobToast", driver, "❌ العميل لا يملك مالاً كافياً!", true)
        triggerClientEvent(customer, "showJobToast", customer, "❌ لا تملك مالاً كافياً لأجرة التاكسي!", true)
    end
end
addEvent("sendTaxiBill", true)
addEventHandler("sendTaxiBill", root, sendTaxiBill)

-- الحصول على طلبات التاكسي
function getTaxiRequests(player)
    local job = getElementData(player, "job") or 0
    if job ~= 2 then return {} end
    
    local requests = {}
    for targetPlayer, request in pairs(taxiRequests) do
        if isElement(targetPlayer) and not request.accepted then
            local distance = getDistanceBetweenPoints3D(
                getElementPosition(player), request.x, request.y, request.z
            )
            requests[targetPlayer] = {
                player = targetPlayer,
                x = request.x,
                y = request.y, 
                z = request.z,
                price = request.price,
                distance = math.floor(distance)
            }
        end
    end
    
    return requests
end
addEvent("getTaxiRequests", true)
addEventHandler("getTaxiRequests", root, getTaxiRequests)