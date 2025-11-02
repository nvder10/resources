-----------------------------------
-- Car System - CLIENT (مدمج بالكامل)
-----------------------------------

local screenW, screenH = guiGetScreenSize()

-- =========================
-- متغيرات الأنظمة
-- =========================
local seatbeltOn = false
local handbrakeOn = false
local dealershipGUI = nil
local currentCarData = nil
local isDealershipGUIOpen = false -- 🔄 متغير لتتبع حالة واجهة المعرض

-- =========================
-- متغيرات الجراجات في الكلينت
-- =========================
local garageCols = {} -- جدول لحفظ كل كولشيبز الجراجات
local garageMarkers = {} -- جدول لحفظ كل ماركرات الجراجات

-- =========================
-- تهيئة النظام
-- =========================
-- في الكلينت، بعد سطر outputDebugString مباشرة
addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[CAR_SYSTEM-CLIENT] ✅ تم تحميل الكلينت")
    
    -- طلب بيانات الجراجات من السيرفر
    triggerServerEvent("onClientRequestGarages", localPlayer)
    
    -- تحميل الجراجات بعد ثانية للتأكد من تحميل الخريطة
    setTimer(function()
        triggerServerEvent("onClientRequestGarages", localPlayer)
    end, 1000, 1)
end)

-- =========================
-- استقبال بيانات الجراجات من السيرفر
-- =========================
addEvent("onClientReceiveGarages", true)
addEventHandler("onClientReceiveGarages", root, function(garagesData)
    outputDebugString("[GARAGE-CLIENT] 📦 استقبال بيانات الجراجات: " .. #garagesData .. " جراج")
    
    -- تنظيف الجراجات القديمة
    for _, col in ipairs(garageCols) do
        if isElement(col) then
            destroyElement(col)
        end
    end
    for _, marker in ipairs(garageMarkers) do
        if isElement(marker) then
            destroyElement(marker)
        end
    end
    
    garageCols = {}
    garageMarkers = {}
    
    -- إنشاء الجراجات الجديدة
    for _, garage in ipairs(garagesData) do
        createClientGarage(garage)
    end
    
    outputDebugString("[GARAGE-CLIENT] ✅ تم إنشاء " .. #garageCols .. " جراج في الكلينت")
end)

-- =========================
-- دالة إنشاء الجراج في الكلينت
-- =========================
function createClientGarage(garageData)
    if not garageData or not garageData.id then 
        outputDebugString("[GARAGE-CLIENT] ❌ بيانات جراج غير صالحة")
        return 
    end
    
    -- إنشاء كولشيب للجراج
    local col = createColSphere(garageData.position_x, garageData.position_y, garageData.position_z, 3)
    if not col then
        outputDebugString("[GARAGE-CLIENT] ❌ فشل إنشاء كولشيب للجراج #" .. garageData.id)
        return
    end
    
    setElementData(col, "garage.id", garageData.id)
    setElementData(col, "garage.name", garageData.garage_name)
    setElementData(col, "garage.data", garageData)
    
    table.insert(garageCols, col)
    
    -- 🆕 تحسين: ماركر واحد فقط بحجم ولون مناسب
    local marker = createMarker(
        garageData.position_x, 
        garageData.position_y, 
        garageData.position_z - 1.0,  -- ارتفاع مناسب
        "cylinder", 
        1.5,  -- حجم مناسب
        0, 150, 255, 150  -- لون أزرق واضح
    )
    
    if marker then
        setElementData(marker, "garage.marker", true)
        setElementData(marker, "garage.id", garageData.id)
        setElementData(marker, "garage.name", garageData.garage_name)
        table.insert(garageMarkers, marker)
    end
    
    -- إنشاء بلب للجراج
    createBlip(garageData.position_x, garageData.position_y, garageData.position_z, 55, 2, 255, 255, 255, 255, 0, 200)
    
    outputDebugString("[GARAGE-CLIENT] ✅ تم إنشاء جراج #" .. garageData.id .. " - " .. garageData.garage_name)
end

-- =========================
-- نظام الجراج في الكلينت (مُحدَّث)
-- =========================

-- متغيرات جديدة للتحكم في الرسائل
local showGarageMessage = false
local currentGarageName = ""
local lastGarageCheck = 0

-- تحديث نظام العرض للجراج
addEventHandler("onClientRender", root, function()
    local currentTime = getTickCount()
    
    -- التحقق من الجراج كل 500 مللي ثانية لتقليل الحمل
    if currentTime - lastGarageCheck > 500 then
        local px, py, pz = getElementPosition(localPlayer)
        local nearGarage = false
        local tempGarageName = ""
        
        -- التحقق من كل الجراجات
        for _, col in ipairs(garageCols) do
            if isElement(col) and isElementWithinColShape(localPlayer, col) then
                nearGarage = true
                tempGarageName = getElementData(col, "garage.name") or "الجراج"
                break
            end
        end
        
        showGarageMessage = nearGarage
        currentGarageName = tempGarageName
        lastGarageCheck = currentTime
    end
    
    -- عرض الرسالة فقط إذا كان اللاعب داخل جراج
    if showGarageMessage then
        -- 🆕 موقع جديد في الأسفل مع اللون المطلوب
        local startX = screenW/2 - 150  -- منتصف الشاشة
        local startY = screenH - 120    -- أسفل الشاشة
        local width = 300               -- عرض الخلفية
        local height = 80               -- ارتفاع الخلفية
        
        -- خلفية شفافة
        dxDrawRectangle(startX, startY, width, height, tocolor(0, 0, 0, 150))
        
        -- 🆕 الخط العلوي باللون المطلوب (74, 181, 142)
        dxDrawRectangle(startX, startY, width, 3, tocolor(74, 181, 142, 255))
        
        -- النص
        dxDrawText("" .. currentGarageName, startX, startY + 10, startX + width, startY + 40,
            tocolor(74, 181, 142, 255), 1.3, "default-bold", "center", "center")
        dxDrawText("[Z] لفتح الجـراج إضغط زر", startX, startY + 40, startX + width, startY + 70,
            tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center")
    end
end)

-- تحديث زر Z للجراج
bindKey("z", "down", function()
    local px, py, pz = getElementPosition(localPlayer)
    local inAnyGarage = false
    
    -- البحث عن الجراج الحالي
    for _, col in ipairs(garageCols) do
        if isElement(col) and isElementWithinColShape(localPlayer, col) then
            local garageID = getElementData(col, "garage.id")
            local garageName = getElementData(col, "garage.name") or "الجراج"
            
            outputDebugString("[GARAGE-CLIENT] 🎯 فتح الجراج: " .. garageName .. " (ID: " .. garageID .. ")")
            triggerServerEvent("onPlayerGarageInteract", localPlayer, garageID)
            inAnyGarage = true
            break
        end
    end
    
    -- 🆕 إزالة رسالة الخطأ - لا تظهر أي رسالة إذا لم يكن في جراج
    if not inAnyGarage then
        -- لا تفعل شيء - لا تظهر رسالة خطأ
        return
    end
end)

-- =========================
-- نظام المعرض (مُحدَّث)
-- =========================

-- متغيرات جديدة للتحكم في رسائل المعرض
local showDealershipMessage = false
local currentDealershipName = ""
local lastDealershipCheck = 0

-- تحديث نظام العرض للمعرض
addEventHandler("onClientRender", root, function()
    local currentTime = getTickCount()
    
    -- التحقق من المعرض كل 500 مللي ثانية
    if currentTime - lastDealershipCheck > 500 then
        local px, py, pz = getElementPosition(localPlayer)
        local foundDealership = false
        local tempDealershipName = ""
        
        for _, colshape in ipairs(getElementsByType("colshape")) do
            if getElementData(colshape, "carDealership") then
                local carData = getElementData(colshape, "carData")
                local mx, my, mz = getElementPosition(colshape)
                local distance = getDistanceBetweenPoints3D(px, py, pz, mx, my, mz)
                
                if distance < 3 then -- 🆕 تقليل المسافة إلى 3 أمتار فقط
                    foundDealership = true
                    tempDealershipName = carData.name or "المعرض"
                    break
                end
            end
        end
        
        showDealershipMessage = foundDealership
        currentDealershipName = tempDealershipName
        lastDealershipCheck = currentTime
    end
    
    -- عرض الرسالة فقط إذا كان اللاعب داخل نطاق المعرض
    if showDealershipMessage then
        -- 🆕 موقع في الأسفل مع اللون المطلوب
        local startX = screenW/2 - 150  -- منتصف الشاشة
        local startY = screenH - 120    -- أسفل الشاشة
        local width = 300               -- عرض الخلفية
        local height = 80               -- ارتفاع الخلفية
        
        -- خلفية شفافة
        dxDrawRectangle(startX, startY, width, height, tocolor(0, 0, 0, 150))
        
        -- 🆕 الخط العلوي باللون المطلوب (74, 181, 142)
        dxDrawRectangle(startX, startY, width, 3, tocolor(74, 181, 142, 255))
        
        -- النص
        if isDealershipGUIOpen then
            dxDrawText("- " .. currentDealershipName, startX, startY + 10, startX + width, startY + 40,
                tocolor(74, 181, 142, 255), 1.3, "default-bold", "center", "center")
            dxDrawText("[H] لإغلاق المعرض", startX, startY + 40, startX + width, startY + 70,
                tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center")
        else
            dxDrawText("- " .. currentDealershipName, startX, startY + 10, startX + width, startY + 40,
                tocolor(74, 181, 142, 255), 1.3, "default-bold", "center", "center")
            dxDrawText("[H] إضغط لفتح المعرض", startX, startY + 40, startX + width, startY + 70,
                tocolor(255, 255, 255, 255), 1.0, "default-bold", "center", "center")
        end
    end
end)

-- تحديث زر H للمعرض
bindKey("h", "down", function()
    -- إذا كانت الواجهة مفتوحة، قم بإغلاقها
    if isDealershipGUIOpen then
        closeDealershipGUI()
        showNotification("🚗 تم إغلاق معرض السيارات")
        return
    end
    
    local px, py, pz = getElementPosition(localPlayer)
    local inAnyDealership = false
    
    for _, colshape in ipairs(getElementsByType("colshape")) do
        if getElementData(colshape, "carDealership") then
            local carData = getElementData(colshape, "carData")
            local mx, my, mz = getElementPosition(colshape)
            local distance = getDistanceBetweenPoints3D(px, py, pz, mx, my, mz)
            
            -- 🆕 تقليل المسافة إلى 3 أمتار فقط
            if distance < 3 then
                showDealershipGUI(carData)
                showNotification("🚗 تم فتح معرض " .. carData.name)
                inAnyDealership = true
                return
            end
        end
    end
    
    -- 🆕 إزالة رسالة الخطأ - لا تظهر أي رسالة إذا لم يكن في معرض
    if not inAnyDealership then
        -- لا تفعل شيء - لا تظهر رسالة خطأ
        return
    end
end)

-- إغلاق واجهة المعرض عند الضغط على ESC
bindKey("escape", "down", function()
    if isDealershipGUIOpen then
        closeDealershipGUI()
        outputChatBox("🚗 تم إغلاق معرض السيارات", 255, 255, 0)
    end
end)

-- عرض واجهة الشراء
function showDealershipGUI(carData)
    -- إذا كانت الواجهة مفتوحة بالفعل، لا تفتح أخرى
    if isDealershipGUIOpen then
        return
    end
    
    outputDebugString("[DEALERSHIP-CLIENT] 🎮 فتح واجهة الشراء لـ " .. carData.name)
    
    currentCarData = carData
    isDealershipGUIOpen = true
    
    -- إنشاء النافذة الشفافة
    dealershipGUI = {
        window = guiCreateWindow((screenW - 650) / 2, (screenH - 550) / 2, 650, 550, " معرض السيارات - " .. carData.name, false),
        closeBtn = nil,
        carImage = nil,
        colorGrid = nil,
        buyBtn = nil
    }
    
    guiWindowSetSizable(dealershipGUI.window, false)
    guiSetAlpha(dealershipGUI.window, 0.50) -- شفافية أعلى
    
    -- زر الإغلاق
    dealershipGUI.closeBtn = guiCreateButton(615, 10, 25, 25, "✕", false, dealershipGUI.window)
    guiSetProperty(dealershipGUI.closeBtn, "NormalTextColour", "FFFF0000")
    guiSetFont(dealershipGUI.closeBtn, "default-bold-small")
    
    -- صورة السيارة
    dealershipGUI.carImage = guiCreateStaticImage(50, 40, 250, 150, carData.carimage, false, dealershipGUI.window)
    
    -- معلومات السيارة
    local carNameLabel = guiCreateLabel(320, 40, 280, 35, "🚗 " .. carData.name, false, dealershipGUI.window)
    guiSetFont(carNameLabel, "default-bold")
    
    local modelLabel = guiCreateLabel(320, 75, 280, 25, "🆔 الموديل: " .. carData.id, false, dealershipGUI.window)
    guiSetFont(modelLabel, "default-bold-small")
    
    -- السعر
    local priceLabel = guiCreateLabel(320, 105, 280, 40, "💰 السعر: $" .. carData.price, false, dealershipGUI.window)
    guiSetFont(priceLabel, "default-bold")
    guiLabelSetColor(priceLabel, 255, 215, 0) -- لون ذهبي
    
    -- الموقع
    local locationLabel = guiCreateLabel(320, 145, 280, 25, "📍 التسليم: أمام المعرض", false, dealershipGUI.window)
    guiSetFont(locationLabel, "default-small")
    
    -- اختيار الألوان
    local colorTitle = guiCreateLabel(50, 210, 200, 25, "🎨 اختر اللون المفضل:", false, dealershipGUI.window)
    guiSetFont(colorTitle, "default-bold")
    
    dealershipGUI.colorGrid = guiCreateGridList(50, 240, 550, 160, false, dealershipGUI.window)
    guiGridListAddColumn(dealershipGUI.colorGrid, "اللون", 0.5)
    guiGridListAddColumn(dealershipGUI.colorGrid, "العينة", 0.4)
    guiGridListSetSortingEnabled(dealershipGUI.colorGrid, false)
    
    -- إضافة الألوان للقائمة مع عينات الألوان
    for i, color in ipairs(carData.colors) do
        local row = guiGridListAddRow(dealershipGUI.colorGrid)
        local colorName = "اللون " .. i
        
        -- أسماء الألوان العربية
        if i == 1 then 
            colorName = "أســود"
        elseif i == 2 then 
            colorName = "أبيــض" 
        elseif i == 3 then 
            colorName = "أحمــر"
        elseif i == 4 then 
            colorName = "أزرق"
        elseif i == 5 then 
            colorName = "أخضــر"
        elseif i == 6 then 
            colorName = "أصفــر"            
        elseif i == 7 then 
            colorName = "برتقــالي" 
        elseif i == 8 then
            colorName = "بنفســجي"
        end
        
        guiGridListSetItemText(dealershipGUI.colorGrid, row, 1, colorName, false, false)
        guiGridListSetItemText(dealershipGUI.colorGrid, row, 2, "■■■■■■■■■■", false, false)
        
        -- تعيين لون النص للعمود الثاني ليظهر كلون السيارة
        local r, g, b = color[1], color[2], color[3] or color[1]
        guiGridListSetItemColor(dealershipGUI.colorGrid, row, 2, r, g, b)
        
        guiGridListSetItemData(dealershipGUI.colorGrid, row, 1, {
            index = i,
            colors = color
        })
    end
    
    -- زر الشراء
    dealershipGUI.buyBtn = guiCreateButton(50, 420, 550, 60, "🛒 شراء السيارة الآن - $" .. carData.price, false, dealershipGUI.window)
    guiSetFont(dealershipGUI.buyBtn, "default-bold")
    guiSetProperty(dealershipGUI.buyBtn, "NormalTextColour", "FF00FF00")
    guiSetProperty(dealershipGUI.buyBtn, "HoverTextColour", "FFFFFF00")
    
    -- معلومات إضافية
    local infoLabel = guiCreateLabel(50, 490, 550, 20, "💡 تشمل الضمان والخدمة لمدة عام", false, dealershipGUI.window)
    guiSetFont(infoLabel, "default-small")
    guiLabelSetColor(infoLabel, 200, 200, 200)
    guiLabelSetHorizontalAlign(infoLabel, "center")
    
    -- الأحداث
    addEventHandler("onClientGUIClick", dealershipGUI.closeBtn, closeDealershipGUI, false)
    addEventHandler("onClientGUIClick", dealershipGUI.buyBtn, onBuyButtonClick, false)
    
    showCursor(true)
    guiSetInputEnabled(true)
    
    outputDebugString("[DEALERSHIP-CLIENT] ✅ تم فتح واجهة الشراء")
end

-- إغلاق واجهة المعرض
function closeDealershipGUI()
    if dealershipGUI and isElement(dealershipGUI.window) then
        destroyElement(dealershipGUI.window)
    end
    dealershipGUI = nil
    currentCarData = nil
    isDealershipGUIOpen = false
    showCursor(false)
    guiSetInputEnabled(false)
    
    outputDebugString("[DEALERSHIP-CLIENT] ✅ تم إغلاق واجهة الشراء")
end

-- حدث الضغط على زر الشراء
function onBuyButtonClick()
    if not currentCarData then return end
    
    local selectedRow = guiGridListGetSelectedItem(dealershipGUI.colorGrid)
    if selectedRow == -1 then
        outputChatBox("❌ يرجى اختيار لون للسيارة", 255, 0, 0)
        return
    end
    
    local colorData = guiGridListGetItemData(dealershipGUI.colorGrid, selectedRow, 1)
    local colorIndex = colorData.index
    
    outputDebugString("[DEALERSHIP-CLIENT] 📤 إرسال طلب شراء للسيارة " .. currentCarData.name .. " باللون " .. colorIndex)
    outputDebugString("[DEALERSHIP-CLIENT] 🎨 بيانات الألوان: " .. toJSON(colorData.colors))
    
    triggerServerEvent("onPlayerBuyCar", localPlayer, currentCarData, colorIndex)
    closeDealershipGUI()
end

-- =========================
-- فتح واجهة الجراج
-- =========================
addEvent("openGarageGUI", true)
addEventHandler("openGarageGUI", root, function(cars, garageID)
    if isElement(garageWindow) then
        destroyElement(garageWindow)
        showCursor(false)
    end

    -- إنشاء نافذة الجراج الشفافة
    garageWindow = guiCreateWindow((screenW - 700) / 2, (screenH - 550) / 2, 700, 550, "🏪 جراج السيارات - إدارة المركبات", false)
    guiWindowSetSizable(garageWindow, false)
    guiSetAlpha(garageWindow, 0.90) -- شفافية أعلى

    -- زر الإغلاق العلوي
    topCloseBtn = guiCreateButton(700 - 35, 8, 30, 25, "✕", false, garageWindow)
    guiSetProperty(topCloseBtn, "NormalTextColour", "FFFF4444")
    guiSetFont(topCloseBtn, "default-bold-small")

    -- زر الإغلاق السفلي
    closeBtn = guiCreateButton(500, 490, 180, 40, "❌ إغلاق النافذة", false, garageWindow)
    guiSetFont(closeBtn, "default-bold-small")

    -- قائمة السيارات
    carList = guiCreateGridList(20, 40, 660, 350, false, garageWindow)
    guiGridListAddColumn(carList, "اسم السيارة", 0.3)
    guiGridListAddColumn(carList, "الموديل", 0.15)
    guiGridListAddColumn(carList, "الحالة", 0.15)
    guiGridListAddColumn(carList, "الصحة", 0.1)
    guiGridListAddColumn(carList, "الوقود", 0.1)
    guiGridListAddColumn(carList, "سعر الإخراج", 0.15)
    guiGridListSetSortingEnabled(carList, false)

    -- ملء القائمة بالبيانات
    for _, car in ipairs(cars) do
        local row = guiGridListAddRow(carList)
        local health = tonumber(car.actual_health) or tonumber(car.health) or 1000
        local fuel = tonumber(car.actual_fuel) or tonumber(car.fuel) or 100
        local isDamaged = health < 800
        local lowFuel = fuel < 30
        
        -- اسم السيارة
        guiGridListSetItemText(carList, row, 1, car.vehicle_name or "سيارة", false, false)
        
        -- الموديل
        guiGridListSetItemText(carList, row, 2, tostring(car.vehicle_model), false, false)
        
        -- الحالة
        local statusText = "✅ سليمة"
        local statusColor = {0, 255, 0}
        if isDamaged then
            statusText = "⚙️ تالفة"
            statusColor = {255, 100, 100}
        end
        guiGridListSetItemText(carList, row, 3, statusText, false, false)
        
        -- الصحة
        local healthText = math.floor(health / 10) .. "%"
        local healthColor = {100, 255, 100}
        if health < 800 then healthColor = {255, 100, 100}
        elseif health < 500 then healthColor = {255, 50, 50} end
        guiGridListSetItemText(carList, row, 4, healthText, false, false)
        guiGridListSetItemColor(carList, row, 4, healthColor[1], healthColor[2], healthColor[3])
        
        -- الوقود
        local fuelText = fuel .. "%"
        local fuelColor = {100, 200, 255}
        if fuel < 30 then fuelColor = {255, 200, 100}
        elseif fuel < 10 then fuelColor = {255, 100, 100} end
        guiGridListSetItemText(carList, row, 5, fuelText, false, false)
        guiGridListSetItemColor(carList, row, 5, fuelColor[1], fuelColor[2], fuelColor[3])
        
        -- سعر الإخراج
        local cost = car.cost or (isDamaged and 1500 or 500)
        local costText = "$" .. cost
        if isDamaged then
            costText = costText .. " 🔧"
        end
        if lowFuel then
            costText = costText .. " ⛽"
        end
        guiGridListSetItemText(carList, row, 6, costText, false, false)
        
        -- تخزين بيانات السيارة
        guiGridListSetItemData(carList, row, 1, car)
    end

    -- الأزرار
    storeBtn = guiCreateButton(20, 410, 320, 45, "💾 تخزين المركبة الحالية", false, garageWindow)
    guiSetFont(storeBtn, "default-bold")
    
    local spawnBtn = guiCreateButton(360, 410, 320, 45, "🚗 إخراج السيارة المحددة", false, garageWindow)
    guiSetFont(spawnBtn, "default-bold")

    -- معلومات الأسعار
    local priceInfo = guiCreateLabel(20, 465, 660, 20, "💡 سعر الإخراج يشمل: 500$ أساسي + تكاليف الإصلاح + تعبة الوقود إذا لزم", false, garageWindow)
    guiSetFont(priceInfo, "default-small")
    guiLabelSetColor(priceInfo, 200, 200, 100)
    guiLabelSetHorizontalAlign(priceInfo, "center")

    showCursor(true)
    guiBringToFront(garageWindow)
    guiSetInputEnabled(true)

    -- حدث زر إخراج السيارة
    addEventHandler("onClientGUIClick", spawnBtn, function()
        local selectedRow = guiGridListGetSelectedItem(carList)
        if selectedRow ~= -1 then
            local carData = guiGridListGetItemData(carList, selectedRow, 1)
            if carData then
                triggerServerEvent("spawnGarageVehicle", localPlayer, tonumber(carData.id), garageID)
                if isElement(garageWindow) then destroyElement(garageWindow) end
                showCursor(false)
                guiSetInputEnabled(false)
            end
        else
            outputChatBox("⚠️ يرجى اختيار سيارة من القائمة", 255, 255, 0)
        end
    end, false)

    addEventHandler("onClientGUIClick", storeBtn, function()
        triggerServerEvent("storeVehicleInGarage", localPlayer, garageID)
        if isElement(garageWindow) then destroyElement(garageWindow) end
        showCursor(false)
        guiSetInputEnabled(false)
    end, false)

    addEventHandler("onClientGUIClick", topCloseBtn, function()
        if isElement(garageWindow) then destroyElement(garageWindow) end
        showCursor(false)
        guiSetInputEnabled(false)
    end, false)

    addEventHandler("onClientGUIClick", closeBtn, function()
        if isElement(garageWindow) then destroyElement(garageWindow) end
        showCursor(false)
        guiSetInputEnabled(false)
    end, false)

    -- إلغاء النقر المزدوج
    addEventHandler("onClientGUIDoubleClick", carList, function()
        -- لا تفعل شيء
    end, false)
end)

-- =========================
-- نظام car_system
-- =========================
-- إشعار بسيط في الشات
addEvent("car:notify", true)
addEventHandler("car:notify", root, function(text)
    outputChatBox(tostring(text), 255, 255, 0)
end)

-- 🔑 تشغيل / إيقاف المحرك (J)
bindKey("j", "down", function()
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh then
        outputChatBox("❌ يجب أن تكون داخل سيارة", 255, 180, 0)
        return
    end

    if getPedOccupiedVehicleSeat(localPlayer) ~= 0 then
        outputChatBox("❌ يجب أن تكون السائق لتشغيل المحرك", 255, 180, 0)
        return
    end

    triggerServerEvent("car:tryToggleEngine", resourceRoot, veh)
end)

-- ⛓️ ربط / فك الحزام (N)
bindKey("n", "down", function()
    seatbeltOn = not seatbeltOn
    triggerServerEvent("car:setSeatbelt", resourceRoot, seatbeltOn)
    outputChatBox(seatbeltOn and "🔒 الحزام مربوط" or "🔓 الحزام مفكوك", 100, 200, 255)
end)

-- منع النزول لو الحزام مربوط
addEventHandler("onClientVehicleStartExit", root, function(player, seat)
    if player == localPlayer and seatbeltOn then
        cancelEvent()
        outputChatBox("⚠️ فك الحزام قبل النزول (N)", 255, 150, 0)
    end
end)

-- 💡 تشغيل / إطفاء الأنوار (L)
bindKey("l", "down", function()
    local veh = getPedOccupiedVehicle(localPlayer)
    if veh and getPedOccupiedVehicleSeat(localPlayer) == 0 then
        triggerServerEvent("car:toggleLights", resourceRoot, veh)
    end
end)

-- 🅿️ فرامل اليد (G)
bindKey("g", "down", function()
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh or getPedOccupiedVehicleSeat(localPlayer) ~= 0 then return end

    handbrakeOn = not handbrakeOn
    setElementFrozen(veh, handbrakeOn)
    outputChatBox(handbrakeOn and "🅿️ فرامل اليد مفعلة" or "🟢 فرامل اليد مفصولة", 100, 255, 100)
end)

-- 🔑 استقبال حدث إضافة مفتاح العربية للشنطة
addEvent("addInventoryItem", true)
addEventHandler("addInventoryItem", root, function(displayName, iconPath, vehID)
    outputChatBox("🔑 تم إضافة " .. tostring(displayName) .. " إلى الحقيبة", 255, 255, 0)

    if not inventoryItems then inventoryItems = {} end

    table.insert(inventoryItems, { name = displayName, icon = iconPath })

    if triggerEvent then
        triggerEvent("updateInventory", localPlayer, inventoryItems)
    end
end)

-- 🔊 أصوات (كلاكس / تشغيل / موسيقى)
addEvent("car:playSound", true)
addEventHandler("car:playSound", root, function(soundName)
    local soundPath = "sounds/" .. soundName
    if fileExists(soundPath) then
        local s = playSound(soundPath)
        setSoundVolume(s, 0.7)
    else
        outputChatBox("⚠️ ملف الصوت غير موجود: " .. soundName)
    end
end)

-- 🔁 عند دخول السيارة / الخروج منها
addEventHandler("onClientVehicleEnter", root, function(player, seat)
    if player == localPlayer and seat == 0 then
        outputChatBox("🚗 اضغط J للمحرك - N للحزام - L للأنوار - G لفرامل اليد", 180, 255, 200)
    end
end)

-- =========================
-- أوامر الفحص
-- =========================
addCommandHandler("testdealershipclient", function()
    local px, py, pz = getElementPosition(localPlayer)
    outputChatBox("📍 موقعك: " .. px .. ", " .. py .. ", " .. pz, 255, 255, 0)
    
    local found = false
    for _, colshape in ipairs(getElementsByType("colshape")) do
        if getElementData(colshape, "carDealership") then
            local carData = getElementData(colshape, "carData")
            local mx, my, mz = getElementPosition(colshape)
            local distance = getDistanceBetweenPoints3D(px, py, pz, mx, my, mz)
            outputChatBox("🎯 معرض " .. carData.name .. " - المسافة: " .. math.floor(distance) .. "m", 255, 255, 0)
            found = true
        end
    end
    
    if not found then
        outputChatBox("❌ لم يتم العثور على أي معرض قريب", 255, 0, 0)
    end
end)

addCommandHandler("checkcoords", function()
    local px, py, pz = getElementPosition(localPlayer)
    local groundZ = getGroundPosition(px, py, pz)
    
    outputChatBox("📍 ارتفاعك: " .. pz .. " | ارتفاع الأرض: " .. groundZ, 255, 255, 0)
    outputChatBox("📏 الفرق: " .. (pz - groundZ), 255, 255, 0)
    
    if (pz - groundZ) < 0.5 then
        outputChatBox("⚠️ تحذير: أنت قريب جداً من الأرض أو تحتها!", 255, 100, 100)
    end
end)

-- أمر لفحص الجراجات في الكلينت
addCommandHandler("checkclientgarages", function()
    outputChatBox("🔧 فحص الجراجات في الكلينت:", 255, 255, 0)
    outputChatBox("📊 عدد الجراجات: " .. #garageCols, 0, 255, 0)
    
    for _, col in ipairs(garageCols) do
        local garageID = getElementData(col, "garage.id")
        local garageName = getElementData(col, "garage.name") or "غير معروف"
        outputChatBox("   - " .. garageName .. " (ID: " .. garageID .. ")", 200, 200, 200)
    end
end)
-- =========================
-- 🆕 نظام الإشعارات المحسّن
-- =========================
local notifications = {}
local notificationStartY = screenH - 200 -- بداية الإشعارات من الأعلى

-- دالة لعرض إشعار جديد
function showNotification(text, duration)
    duration = duration or 5000 -- 5 ثواني افتراضياً
    
    table.insert(notifications, {
        text = text,
        startTime = getTickCount(),
        duration = duration,
        y = notificationStartY
    })
    
    outputDebugString("[NOTIFICATION] 📢 " .. text)
end

-- عرض الإشعارات على الشاشة
addEventHandler("onClientRender", root, function()
    local currentTime = getTickCount()
    local activeNotifications = {}
    
    for i, notification in ipairs(notifications) do
        local elapsed = currentTime - notification.startTime
        local progress = elapsed / notification.duration
        
        if progress <= 1 then
            -- حساب الشفافية
            local alpha = 255
            if progress > 0.8 then
                alpha = 255 * (1 - ((progress - 0.8) / 0.2))
            end
            
            -- أبعاد الإشعار
            local width = dxGetTextWidth(notification.text, 1.0, "default-bold") + 40
            local height = 50
            local x = (screenW - width) / 2
            local y = notification.y
            
            -- خلفية الإشعار
            dxDrawRectangle(x, y, width, height, tocolor(0, 0, 0, 150))
            
            -- 🆕 الخط العلوي باللون المطلوب (74, 181, 142)
            dxDrawRectangle(x, y, width, 3, tocolor(74, 181, 142, alpha))
            
            -- النص
            dxDrawText(notification.text, x, y, x + width, y + height, 
                tocolor(255, 255, 255, alpha), 1.0, "default-bold", "center", "center")
            
            table.insert(activeNotifications, {
                data = notification,
                index = i
            })
        end
    end
    
    -- تحديث المواقع
    for i, notif in ipairs(activeNotifications) do
        notifications[notif.index].y = notificationStartY - ((i - 1) * 60)
    end
    
    -- تنظيف الإشعارات المنتهية
    notifications = activeNotifications
end)

-- تنظيف الإشعارات القديمة
setTimer(function()
    local currentTime = getTickCount()
    local tempNotifications = {}
    
    for i, notification in ipairs(notifications) do
        local elapsed = currentTime - notification.startTime
        if elapsed <= notification.duration then
            table.insert(tempNotifications, notification)
        end
    end
    
    notifications = tempNotifications
end, 1000, 0)
-- إضافة هذا الحدث في الكلينت لاستقبال الإشعارات من السيرفر
addEvent("showNotification", true)
addEventHandler("showNotification", root, function(text)
    showNotification(text)
end)