-----------------------------------
-- Car Dealership System - CLIENT
-----------------------------------

local screenW, screenH = guiGetScreenSize()
local dealershipGUI = nil
local currentCarData = nil

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("[DEALERSHIP-CLIENT] ✅ تم تحميل الكلينت")
end)

-- الرسم عند الاقتراب من المعرض
addEventHandler("onClientRender", root, function()
    local px, py, pz = getElementPosition(localPlayer)
    local foundDealership = false
    
    for _, colshape in ipairs(getElementsByType("colshape")) do
        if getElementData(colshape, "carDealership") then
            local carData = getElementData(colshape, "carData")
            local mx, my, mz = getElementPosition(colshape)
            local distance = getDistanceBetweenPoints3D(px, py, pz, mx, my, mz)
            
            if distance < 15 then -- مسافة أكبر للرؤية
                foundDealership = true
                
                -- رسم خط للمساعدة
                local camX, camY, camZ = getCameraMatrix()
                dxDrawLine3D(px, py, pz, mx, my, mz + 1, tocolor(0, 255, 255, 255), 2)
                
                local sx, sy = getScreenFromWorldPosition(mx, my, mz + 2)
                if sx and sy then
                    dxDrawRectangle(sx - 120, sy - 80, 240, 70, tocolor(0, 0, 0, 180))
                    dxDrawRectangle(sx - 120, sy - 80, 240, 3, tocolor(0, 150, 255, 255))
                    
                    dxDrawText("🚗 " .. carData.name, sx - 100, sy - 75, sx + 100, sy - 45, tocolor(255, 255, 255, 255), 1.2, "default-bold", "center", "center")
                    dxDrawText("💰 $" .. carData.price, sx - 100, sy - 45, sx + 100, sy - 25, tocolor(255, 255, 0, 255), 1.0, "default", "center", "center")
                    dxDrawText("اضغط H للشراء", sx - 100, sy - 20, sx + 100, sy + 5, tocolor(0, 255, 255, 255), 1.0, "default-bold", "center", "center")
                    
                    -- رسم المسافة
                    dxDrawText("📏 المسافة: " .. math.floor(distance) .. "m", sx - 100, sy + 10, sx + 100, sy + 30, tocolor(200, 200, 200, 255), 0.8, "default", "center", "center")
                end
                break
            end
        end
    end
    
    -- إغلاق الواجهة إذا ابتعد
    if dealershipGUI and not foundDealership then
        closeDealershipGUI()
    end
end)

-- التفاعل مع الزر H
bindKey("h", "down", function()
    local px, py, pz = getElementPosition(localPlayer)
    local nearestDistance = 999
    local nearestCarData = nil
    
    for _, colshape in ipairs(getElementsByType("colshape")) do
        if getElementData(colshape, "carDealership") then
            local carData = getElementData(colshape, "carData")
            local mx, my, mz = getElementPosition(colshape)
            local distance = getDistanceBetweenPoints3D(px, py, pz, mx, my, mz)
            
            if distance < 3 then
                if not isCursorShowing() and not dealershipGUI then
                    showDealershipGUI(carData)
                end
                return
            end
            
            if distance < nearestDistance then
                nearestDistance = distance
                nearestCarData = carData
            end
        end
    end
    
    if nearestCarData then
        outputChatBox("❌ أنت بعيد عن المعرض. المسافة: " .. math.floor(nearestDistance) .. "m", 255, 100, 100)
    end
end)

-- عرض واجهة الشراء
function showDealershipGUI(carData)
    outputDebugString("[DEALERSHIP-CLIENT] 🎮 فتح واجهة الشراء لـ " .. carData.name)
    
    currentCarData = carData
    
    -- إنشاء النافذة
    dealershipGUI = {
        window = guiCreateWindow((screenW - 500) / 2, (screenH - 400) / 2, 500, 400, "🚗 معرض السيارات - " .. carData.name, false),
        closeBtn = nil,
        colorGrid = nil,
        buyBtn = nil
    }
    
    guiWindowSetSizable(dealershipGUI.window, false)
    guiSetAlpha(dealershipGUI.window, 0.95)
    
    -- زر الإغلاق
    dealershipGUI.closeBtn = guiCreateButton(460, 10, 30, 25, "X", false, dealershipGUI.window)
    guiSetProperty(dealershipGUI.closeBtn, "NormalTextColour", "FFFF0000")
    
    -- معلومات السيارة
    guiCreateLabel(20, 35, 460, 30, "🚗 " .. carData.name, false, dealershipGUI.window)
    guiSetFont(guiCreateLabel(20, 60, 460, 30, "موديل: " .. carData.id, false, dealershipGUI.window), "default-bold-small")
    
    -- السعر
    local priceLabel = guiCreateLabel(20, 90, 460, 30, "💰 السعر: $" .. carData.price, false, dealershipGUI.window)
    guiSetFont(priceLabel, "default-bold")
    guiLabelSetColor(priceLabel, 255, 255, 0)
    
    -- اختيار الألوان
    guiCreateLabel(20, 130, 200, 20, "🎨 اختر اللون:", false, dealershipGUI.window)
    dealershipGUI.colorGrid = guiCreateGridList(20, 155, 460, 150, false, dealershipGUI.window)
    guiGridListAddColumn(dealershipGUI.colorGrid, "اللون", 0.7)
    guiGridListAddColumn(dealershipGUI.colorGrid, "الكود", 0.2)
    
    -- إضافة الألوان للقائمة
    for i, color in ipairs(carData.colors) do
        local row = guiGridListAddRow(dealershipGUI.colorGrid)
        local colorName = "اللون " .. i
        if i == 1 then colorName = "🖤 أسود"
        elseif i == 2 then colorName = "🤍 أبيض" 
        elseif i == 3 then colorName = "❤️ أحمر"
        elseif i == 4 then colorName = "💙 أزرق"
        elseif i == 5 then colorName = "💚 أخضر"
        elseif i == 6 then colorName = "💛 ذهبي" end
        
        guiGridListSetItemText(dealershipGUI.colorGrid, row, 1, colorName, false, false)
        guiGridListSetItemText(dealershipGUI.colorGrid, row, 2, color[1] .. "," .. color[2], false, false)
        guiGridListSetItemData(dealershipGUI.colorGrid, row, 1, i)
    end
    
    -- زر الشراء
    dealershipGUI.buyBtn = guiCreateButton(20, 320, 460, 50, "🛒 شراء السيارة - $" .. carData.price, false, dealershipGUI.window)
    guiSetFont(dealershipGUI.buyBtn, "default-bold")
    guiSetProperty(dealershipGUI.buyBtn, "NormalTextColour", "FF00FF00")
    
    -- الأحداث
    addEventHandler("onClientGUIClick", dealershipGUI.closeBtn, closeDealershipGUI, false)
    addEventHandler("onClientGUIClick", dealershipGUI.buyBtn, onBuyButtonClick, false)
    
    showCursor(true)
    guiSetInputEnabled(true)
end

-- إغلاق الواجهة
function closeDealershipGUI()
    if dealershipGUI and isElement(dealershipGUI.window) then
        destroyElement(dealershipGUI.window)
    end
    dealershipGUI = nil
    currentCarData = nil
    showCursor(false)
    guiSetInputEnabled(false)
end

-- حدث الضغط على زر الشراء
function onBuyButtonClick()
    if not currentCarData then return end
    
    local selectedRow = guiGridListGetSelectedItem(dealershipGUI.colorGrid)
    if selectedRow == -1 then
        outputChatBox("❌ يرجى اختيار لون للسيارة", 255, 0, 0)
        return
    end
    
    local colorIndex = guiGridListGetItemData(dealershipGUI.colorGrid, selectedRow, 1)
    
    outputDebugString("[DEALERSHIP-CLIENT] 📤 إرسال طلب شراء للسيارة " .. currentCarData.name .. " باللون " .. colorIndex)
    
    -- إرسال طلب الشراء للسيرفر
    triggerServerEvent("onPlayerBuyCar", localPlayer, currentCarData, colorIndex)
    closeDealershipGUI()
end

-- أمر لفحص الكلينت
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