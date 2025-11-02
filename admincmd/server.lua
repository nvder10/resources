-- 🔰 التحقق إذا اللاعب أدمن
function isPlayerAdmin(player)
    return hasObjectPermissionTo(player, "command.ban", false)
end

---------------------------------------
-- 🚗 أمر استدعاء سيارة (rs) - معدل
---------------------------------------
addCommandHandler("rs", function(sourcePlayer, commandName, vehicleID)
    if not isElement(sourcePlayer) or getElementType(sourcePlayer) ~= "player" then
        outputServerLog("❌ هذا الأمر مخصص للاعبين فقط.")
        return
    end

    if not isPlayerAdmin(sourcePlayer) then
        outputChatBox("🚫 هذا الأمر مخصص للمشرفين فقط!", sourcePlayer, 255, 50, 50)
        return
    end

    if not vehicleID then
        outputChatBox("⚠️ استخدم: /rs [ID السيارة]", sourcePlayer, 255, 255, 0)
        outputChatBox("💡 أمثلة: /rs 411 (إنفيرنوس) | /rs 415 (شيفاليه) | /rs 451 (توريزمو)", sourcePlayer, 200, 200, 255)
        return
    end

    vehicleID = tonumber(vehicleID)
    if not vehicleID then
        outputChatBox("❌ رقم السيارة غير صحيح!", sourcePlayer, 255, 0, 0)
        return
    end

    local x, y, z = getElementPosition(sourcePlayer)
    local rot = getPedRotation(sourcePlayer)
    
    -- حساب موقع أمام اللاعب
    local forwardX = x + math.sin(math.rad(rot)) * 5
    local forwardY = y + math.cos(math.rad(rot)) * 5

    -- حذف السيارة القديمة إذا موجودة
    local oldVehicle = getElementData(sourcePlayer, "spawnedVehicle")
    if isElement(oldVehicle) then
        destroyElement(oldVehicle)
    end

    -- إنشاء السيارة الجديدة
    local vehicle = createVehicle(vehicleID, forwardX, forwardY, z + 0.5, 0, 0, rot)
    if vehicle then
        -- إعدادات السيارة
        setVehicleEngineState(vehicle, true)  -- تشغيل المحرك
        setVehicleFuelTankExplodable(vehicle, false)  -- منع انفجار الخزان
        setVehicleDamageProof(vehicle, true)  -- منع الضرر
        setElementFrozen(vehicle, false)  -- إلغاء التجميد
        
        -- تعبئة البنزين 100%
        setElementData(vehicle, "fuel", 100)
        setElementData(vehicle, "maxfuel", 100)
        
        -- إدخال اللاعب للسيارة
        warpPedIntoVehicle(sourcePlayer, vehicle)
        setElementData(sourcePlayer, "spawnedVehicle", vehicle)
        
        outputChatBox("✅ تم توليد السيارة رقم: " .. vehicleID, sourcePlayer, 0, 255, 0)
        outputChatBox("⛽ البنزين: 100% | 🛡️ السيارة مضادة للضرر", sourcePlayer, 100, 255, 100)
    else
        outputChatBox("❌ فشل في توليد السيارة! تأكد من رقم السيارة.", sourcePlayer, 255, 0, 0)
    end
end)

---------------------------------------
-- 🩸 أمر إحياء نفسي (heal)
---------------------------------------
addCommandHandler("heal", function(sourcePlayer)
    if not isElement(sourcePlayer) or getElementType(sourcePlayer) ~= "player" then
        return
    end

    if not isPlayerAdmin(sourcePlayer) then
        outputChatBox("🚫 هذا الأمر مخصص للمشرفين فقط!", sourcePlayer, 255, 50, 50)
        return
    end

    -- إعادة الصحة والدم
    setElementHealth(sourcePlayer, 100)
    
    -- إذا كان السيرفر يستخدم نظام الدمالذي
    if getElementData then
        setElementData(sourcePlayer, "health", 100)
        setElementData(sourcePlayer, "blood", 12000) -- دم كامل
    end
    
    outputChatBox("💚 تم إحياؤك بنجاح! الصحة: 100%", sourcePlayer, 0, 255, 100)
end)

---------------------------------------
-- 🩸 أمر إحياء لاعب آخر (healplayer)
---------------------------------------
addCommandHandler("healplayer", function(sourcePlayer, commandName, targetName)
    if not isElement(sourcePlayer) or getElementType(sourcePlayer) ~= "player" then
        return
    end

    if not isPlayerAdmin(sourcePlayer) then
        outputChatBox("🚫 هذا الأمر مخصص للمشرفين فقط!", sourcePlayer, 255, 50, 50)
        return
    end

    if not targetName then
        outputChatBox("👤 استخدم: /healplayer [اسم اللاعب]", sourcePlayer, 255, 255, 0)
        outputChatBox("💡 يمكنك استخدام 'all' لعلاج جميع اللاعبين", sourcePlayer, 200, 200, 255)
        return
    end

    if targetName:lower() == "all" then
        -- علاج جميع اللاعبين
        local players = getElementsByType("player")
        local healedCount = 0
        
        for _, player in ipairs(players) do
            setElementHealth(player, 100)
            if getElementData then
                setElementData(player, "health", 100)
                setElementData(player, "blood", 12000)
            end
            outputChatBox("💚 تم علاجك من قبل الأدمن " .. getPlayerName(sourcePlayer), player, 0, 255, 100)
            healedCount = healedCount + 1
        end
        
        outputChatBox("✅ تم علاج جميع اللاعبين (" .. healedCount .. " لاعب)", sourcePlayer, 0, 255, 100)
        return
    end

    -- علاج لاعب محدد
    local targetPlayer = getPlayerFromName(targetName)
    if not isElement(targetPlayer) then
        outputChatBox("❌ اللاعب غير موجود!", sourcePlayer, 255, 0, 0)
        return
    end

    setElementHealth(targetPlayer, 100)
    if getElementData then
        setElementData(targetPlayer, "health", 100)
        setElementData(targetPlayer, "blood", 12000)
    end
    
    outputChatBox("✅ تم علاج اللاعب " .. getPlayerName(targetPlayer), sourcePlayer, 0, 255, 100)
    outputChatBox("💚 تم علاجك من قبل الأدمن " .. getPlayerName(sourcePlayer), targetPlayer, 0, 255, 100)
end)

---------------------------------------
-- 🩺 أمر تعبئة الدم (blood)
---------------------------------------
addCommandHandler("blood", function(sourcePlayer, commandName, targetName)
    if not isElement(sourcePlayer) or getElementType(sourcePlayer) ~= "player" then
        return
    end

    if not isPlayerAdmin(sourcePlayer) then
        outputChatBox("🚫 هذا الأمر مخصص للمشرفين فقط!", sourcePlayer, 255, 50, 50)
        return
    end

    if not targetName then
        -- تعبئة دم النفس
        if getElementData then
            setElementData(sourcePlayer, "blood", 12000)
        end
        outputChatBox("🩸 تم تعبئة دمك بالكامل!", sourcePlayer, 0, 255, 100)
        return
    end

    if targetName:lower() == "all" then
        -- تعبئة دم جميع اللاعبين
        local players = getElementsByType("player")
        local bloodCount = 0
        
        for _, player in ipairs(players) do
            if getElementData then
                setElementData(player, "blood", 12000)
            end
            outputChatBox("🩸 تم تعبئة دمك من قبل الأدمن " .. getPlayerName(sourcePlayer), player, 0, 255, 100)
            bloodCount = bloodCount + 1
        end
        
        outputChatBox("✅ تم تعبئة دم جميع اللاعبين (" .. bloodCount .. " لاعب)", sourcePlayer, 0, 255, 100)
        return
    end

    -- تعبئة دم لاعب محدد
    local targetPlayer = getPlayerFromName(targetName)
    if not isElement(targetPlayer) then
        outputChatBox("❌ اللاعب غير موجود!", sourcePlayer, 255, 0, 0)
        return
    end

    if getElementData then
        setElementData(targetPlayer, "blood", 12000)
    end
    
    outputChatBox("✅ تم تعبئة دم اللاعب " .. getPlayerName(targetPlayer), sourcePlayer, 0, 255, 100)
    outputChatBox("🩸 تم تعبئة دمك من قبل الأدمن " .. getPlayerName(sourcePlayer), targetPlayer, 0, 255, 100)
end)

---------------------------------------
-- 🎒 أمر إضافة غرض لنفسك (additem) - كما هو
---------------------------------------
addCommandHandler("additem", function(player, cmd, itemName)
    if not isPlayerAdmin(player) then
        outputChatBox("🚫 هذا الأمر مخصص للمشرفين فقط!", player, 255, 50, 50)
        return
    end

    if not itemName or itemName == "" then
        outputChatBox("🧰 استخدم الأمر كده: /additem [اسم الغرض]", player, 255, 255, 0)
        return
    end

    if not items[itemName] then
        outputChatBox("⚠️ الغرض '" .. itemName .. "' غير موجود!", player, 255, 100, 100)
        return
    end

    if not playerInventories[player] then
        playerInventories[player] = {}
    end

    if #playerInventories[player] >= 30 then
        outputChatBox("🎒 الحقيبة ممتلئة! لا يمكنك إضافة المزيد.", player, 255, 50, 50)
        return
    end

    table.insert(playerInventories[player], itemName)
    outputChatBox("✅ تمت إضافة " .. items[itemName].name .. " إلى حقيبتك!", player, 0, 255, 100)
    triggerClientEvent(player, "updateInventory", player, playerInventories[player])
end)

---------------------------------------
-- 🎁 أمر إعطاء غرض للاعب آخر (giveitem) - كما هو
---------------------------------------
addCommandHandler("giveitem", function(player, cmd, targetName, itemName)
    if not isPlayerAdmin(player) then
        outputChatBox("🚫 هذا الأمر مخصص للمشرفين فقط!", player, 255, 50, 50)
        return
    end

    if not targetName or not itemName then
        outputChatBox("🎁 استخدم: /giveitem [اسم اللاعب] [اسم الغرض]", player, 255, 255, 0)
        return
    end

    local targetPlayer = getPlayerFromName(targetName)
    if not isElement(targetPlayer) then
        outputChatBox("❌ اللاعب غير موجود!", player, 255, 50, 50)
        return
    end

    if not items[itemName] then
        outputChatBox("⚠️ الغرض '" .. itemName .. "' غير موجود!", player, 255, 100, 100)
        return
    end

    if not playerInventories[targetPlayer] then
        playerInventories[targetPlayer] = {}
    end

    if #playerInventories[targetPlayer] >= 30 then
        outputChatBox("🎒 حقيبة اللاعب ممتلئة!", player, 255, 50, 50)
        return
    end

    table.insert(playerInventories[targetPlayer], itemName)
    triggerClientEvent(targetPlayer, "updateInventory", targetPlayer, playerInventories[targetPlayer])
    outputChatBox("✅ أضفت " .. items[itemName].name .. " إلى حقيبة " .. getPlayerName(targetPlayer) .. "!", player, 0, 255, 100)
    outputChatBox("🎁 تم إعطاؤك " .. items[itemName].name .. " من الأدمن!", targetPlayer, 0, 255, 100)
end)
---------------------------------------
-- 💰 أمر إعطاء فلوس لنفسك (givemoney)
---------------------------------------
addCommandHandler("givemoney", function(sourcePlayer, commandName, amount)
    if not isElement(sourcePlayer) or getElementType(sourcePlayer) ~= "player" then
        return
    end

    if not isPlayerAdmin(sourcePlayer) then
        outputChatBox("🚫 هذا الأمر مخصص للمشرفين فقط!", sourcePlayer, 255, 50, 50)
        return
    end

    if not amount then
        outputChatBox("💰 استخدم: /givemoney [المبلغ]", sourcePlayer, 255, 255, 0)
        outputChatBox("💡 مثال: /givemoney 1000000", sourcePlayer, 200, 200, 255)
        return
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        outputChatBox("❌ المبلغ غير صحيح!", sourcePlayer, 255, 0, 0)
        return
    end

    -- الطريقة الأولى: إذا كان السيرفر يستخدم setElementData للفلوس
    if getElementData then
        local currentMoney = getElementData(sourcePlayer, "money") or 0
        setElementData(sourcePlayer, "money", currentMoney + amount)
    end

    -- الطريقة الثانية: إذا كان السيرفر يستخدم exports.mysql
    if exports.mysql then
        local accountID = getElementData(sourcePlayer, "account:id")
        if accountID then
            exports.mysql:query_free("UPDATE accounts SET credits = credits + " .. amount .. " WHERE id = " .. accountID)
            -- تحديث الفلوس في اللاعب
            local currentCredits = getElementData(sourcePlayer, "credits") or 0
            setElementData(sourcePlayer, "credits", currentCredits + amount)
        end
    end

    -- الطريقة الثالثة: إذا كان السيرفر يستخدم givePlayerMoney
    if givePlayerMoney then
        givePlayerMoney(sourcePlayer, amount)
    end

    outputChatBox("💰 تم إضافة " .. formatNumber(amount) .. "$ إلى رصيدك!", sourcePlayer, 0, 255, 100)
    
    -- إذا كان فيه نظام للبنك، أضف للبنك أيضاً
    if getElementData then
        local bankMoney = getElementData(sourcePlayer, "bankmoney") or 0
        setElementData(sourcePlayer, "bankmoney", bankMoney + amount)
        outputChatBox("🏦 تم إضافة " .. formatNumber(amount) .. "$ إلى حسابك البنكي أيضاً!", sourcePlayer, 100, 255, 100)
    end
end)

-- دالة مساعدة لتنسيق الأرقام
function formatNumber(amount)
    local formatted = amount
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k==0) then
            break
        end
    end
    return formatted
end

---------------------------------------
-- 🏦 أمر إعطاء فلوس بنك (givebank)
---------------------------------------
addCommandHandler("givebank", function(sourcePlayer, commandName, amount)
    if not isElement(sourcePlayer) or getElementType(sourcePlayer) ~= "player" then
        return
    end

    if not isPlayerAdmin(sourcePlayer) then
        outputChatBox("🚫 هذا الأمر مخصص للمشرفين فقط!", sourcePlayer, 255, 50, 50)
        return
    end

    if not amount then
        outputChatBox("🏦 استخدم: /givebank [المبلغ]", sourcePlayer, 255, 255, 0)
        return
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        outputChatBox("❌ المبلغ غير صحيح!", sourcePlayer, 255, 0, 0)
        return
    end

    -- إضافة الفلوس للبنك
    if getElementData then
        local currentBank = getElementData(sourcePlayer, "bankmoney") or 0
        setElementData(sourcePlayer, "bankmoney", currentBank + amount)
        outputChatBox("🏦 تم إضافة " .. formatNumber(amount) .. "$ إلى حسابك البنكي!", sourcePlayer, 0, 255, 100)
    else
        outputChatBox("❌ نظام البنك غير متوفر!", sourcePlayer, 255, 0, 0)
    end
end)

---------------------------------------
-- 💸 أمر تعيين فلوس (setmoney)
---------------------------------------
addCommandHandler("setmoney", function(sourcePlayer, commandName, amount)
    if not isElement(sourcePlayer) or getElementType(sourcePlayer) ~= "player" then
        return
    end

    if not isPlayerAdmin(sourcePlayer) then
        outputChatBox("🚫 هذا الأمر مخصص للمشرفين فقط!", sourcePlayer, 255, 50, 50)
        return
    end

    if not amount then
        outputChatBox("💸 استخدم: /setmoney [المبلغ]", sourcePlayer, 255, 255, 0)
        return
    end

    amount = tonumber(amount)
    if not amount or amount < 0 then
        outputChatBox("❌ المبلغ غير صحيح!", sourcePlayer, 255, 0, 0)
        return
    end

    -- تعيين الفلوس
    if getElementData then
        setElementData(sourcePlayer, "money", amount)
        outputChatBox("💸 تم تعيين فلوسك إلى " .. formatNumber(amount) .. "$!", sourcePlayer, 0, 255, 100)
    end

    -- إذا كان فيه نظام للبنك
    if getElementData then
        setElementData(sourcePlayer, "bankmoney", amount)
        outputChatBox("🏦 تم تعيين فلوس البنك إلى " .. formatNumber(amount) .. "$!", sourcePlayer, 100, 255, 100)
    end
end)