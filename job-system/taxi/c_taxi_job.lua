local screenW, screenH = guiGetScreenSize()
local dxfont = dxCreateFont("Tajawal-Bold.ttf", 14) or "default-bold" -- خط أكبر للعنوان
local dxfont_small = dxCreateFont("Tajawal-Bold.ttf", 10) or "default" -- نفس خط باقي السكربت

-- ألوان المظهر الرئيسي
local primaryColor = {168, 132, 81}
local backgroundColor = {20, 20, 20}

-- نظام التاكسي
local taxiBlip = nil
local taxiPanelVisible = false
local paymentPanelVisible = false
local taxiRequests = {}
local selectedRequest = nil
local pickupBlip = nil
local pickupMarker = nil
local currentCustomer = nil
local paymentAmount = ""

-- التوست notifications
local toastData = { visible = false, message = "", startTime = 0, duration = 3000 }

function showToast(message, isError)
    toastData.visible = true
    toastData.message = message
    toastData.startTime = getTickCount()
    toastData.isError = isError or false
    toastData.progress = 100
end

function isMouseInPosition(x, y, width, height)
    if not isCursorShowing() then return false end
    local cursorX, cursorY = getCursorPosition()
    cursorX, cursorY = cursorX * screenW, cursorY * screenH
    return cursorX >= x and cursorX <= x + width and cursorY >= y and cursorY <= y + height
end

-- وظائف التاكسي الأساسية
function resetTaxiJob()
    if isElement(taxiBlip) then
        destroyElement(taxiBlip)
    end
    removePickupLocation()
    closeTaxiPanel()
    closePaymentPanel()
end

function displayTaxiJob()
    taxiBlip = createBlip(1787.1259765625, -1903.591796875, 13.394536972046, 0, 4, 255, 255, 0)
    showToast("🚕 اذهب إلى موقف التاكسي لبدء العمل", false)
end

-- فتح/إغلاق بانل التاكسي
bindKey("F4", "down", function()
    local job = getElementData(localPlayer, "job") or 0
    if job ~= 2 then return end -- موظف التاكسي فقط
    
    if not taxiPanelVisible then
        openTaxiPanel()
    else
        closeTaxiPanel()
    end
end)

function openTaxiPanel()
    taxiPanelVisible = true
    showCursor(true)
    triggerServerEvent("getTaxiRequests", localPlayer)
end

function closeTaxiPanel()
    taxiPanelVisible = false
    showCursor(false)
    selectedRequest = nil
end

-- فتح/إغلاق بانل الدفع
function openPaymentPanel(customer)
    currentCustomer = customer
    paymentPanelVisible = true
    paymentAmount = ""
    showCursor(true)
end

function closePaymentPanel()
    paymentPanelVisible = false
    showCursor(false)
    currentCustomer = nil
    paymentAmount = ""
end

-- استقبال طلبات التاكسي
addEvent("onNewTaxiRequest", true)
addEventHandler("onNewTaxiRequest", root, function(player, x, y, z, price)
    taxiRequests[player] = {
        player = player,
        x = x,
        y = y,
        z = z,
        price = price,
        distance = math.floor(getDistanceBetweenPoints3D(getElementPosition(localPlayer), x, y, z))
    }
end)

addEvent("removeTaxiRequest", true)
addEventHandler("removeTaxiRequest", root, function(player)
    taxiRequests[player] = nil
    if selectedRequest == player then
        selectedRequest = nil
    end
end)

-- تعيين موقع العميل
addEvent("setTaxiPickup", true)
addEventHandler("setTaxiPickup", root, function(x, y, z, playerName)
    removePickupLocation()
    
    pickupBlip = createBlip(x, y, z, 0, 2, 0, 255, 0, 255, 0, 99999)
    setElementData(pickupBlip, "blip.name", "موقع " .. playerName)
    
    pickupMarker = createMarker(x, y, z, "checkpoint", 4.0, 0, 255, 0, 150)
    
    showToast("🎯 تم تحديد موقع العميل على الخريطة", false)
end)

function removePickupLocation()
    if isElement(pickupBlip) then
        destroyElement(pickupBlip)
        pickupBlip = nil
    end
    if isElement(pickupMarker) then
        destroyElement(pickupMarker)
        pickupMarker = nil
    end
end

-- رسم بانل التاكسي
function drawTaxiPanel()
    if not taxiPanelVisible then return end
    
    local width, height = 420, 380 -- حجم أصغر قليلاً
    local x = (screenW - width) / 2
    local y = (screenH - height) / 2
    
    -- الخلفية الرئيسية
    dxDrawRectangle(x, y, width, height, tocolor(20, 20, 20, 240))
    dxDrawRectangle(x, y, width, 2, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    dxDrawRectangle(x, y + height - 2, width, 2, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    dxDrawRectangle(x, y, 2, height, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    dxDrawRectangle(x + width - 2, y, 2, height, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    
    -- العنوان (أكبر)
    dxDrawText("🚕 وظيفة التاكسي", x, y + 15, x + width, y + 45, 
              tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255), 1.3, dxfont, "center", "center")
    
    -- خط ذهبي تحت العنوان
    dxDrawRectangle(x + 40, y + 47, width - 80, 1, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    
    -- عدد الطلبات
    local requestCount = 0
    for _, request in pairs(taxiRequests) do
        if isElement(request.player) then
            requestCount = requestCount + 1
        end
    end
    
    dxDrawText("📋 الطلبات المتاحة: " .. requestCount, x, y + 55, x + width, y + 75, 
              tocolor(255, 255, 255, 255), 1, dxfont_small, "center", "center")
    
    -- قائمة الطلبات
    local startY = y + 80
    local requestHeight = 50 -- ارتفاع مناسب
    local index = 0
    
    for player, request in pairs(taxiRequests) do
        if isElement(player) then
            local requestY = startY + (index * (requestHeight + 8)) -- مسافة مناسبة
            local isSelected = (selectedRequest == player)
            local isHovered = isMouseInPosition(x + 15, requestY, width - 30, requestHeight)
            
            -- خلفية الطلب (تتفاعل مع الماوس)
            local bgColor
            if isSelected then
                bgColor = tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 120) -- مختار
            elseif isHovered then
                bgColor = tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 60) -- هاڤر
            else
                bgColor = tocolor(40, 40, 40, 200) -- عادي
            end
            
            dxDrawRectangle(x + 15, requestY, width - 30, requestHeight, bgColor)
            
            -- خط فاصل بين الطلبات
            if index > 0 then
                dxDrawRectangle(x + 20, requestY - 4, width - 40, 1, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 80))
            end
            
            -- معلومات الطلب
            local playerName = getPlayerName(player):gsub("_", " ")
            if utf8.len(playerName) > 15 then
                playerName = utf8.sub(playerName, 1, 15) .. "..."
            end
            
            -- الاسم
            dxDrawText("👤 " .. playerName, x + 25, requestY + 8, x + width - 25, requestY + 28, 
                      tocolor(255, 255, 255, 255), 1, dxfont_small, "left", "center")
            
            -- السعر والمسافة في سطر واحد
            dxDrawText("💰 $" .. request.price, x + 25, requestY + 30, x + width - 25, requestY + 48, 
                      tocolor(255, 215, 0, 255), 0.9, dxfont_small, "left", "center")
            
            dxDrawText("📏 " .. request.distance .. "m", x + width - 90, requestY + 30, x + width - 25, requestY + 48, 
                      tocolor(200, 200, 200, 255), 0.9, dxfont_small, "right", "center")
            
            index = index + 1
        end
    end
    
    -- إذا ما فيش طلبات
    if requestCount == 0 then
        dxDrawText("📭 لا توجد طلبات تاكسي متاحة حالياً", x, y + 180, x + width, y + 200, 
                  tocolor(150, 150, 150, 255), 1, dxfont_small, "center", "center")
    end
    
    -- أزرار التحكم (أصغر وأجمل)
    local buttonWidth = 120 -- عرض أصغر
    local buttonHeight = 35 -- ارتفاع مناسب
    local buttonY = y + height - 50
    
    -- زر قبول الطلب
    local acceptHover = isMouseInPosition(x + 30, buttonY, buttonWidth, buttonHeight) and selectedRequest
    local acceptColor = acceptHover and tocolor(188, 152, 101, 255) or tocolor(primaryColor[1], primaryColor[2], primaryColor[3], selectedRequest and 255 or 150)
    dxDrawRectangle(x + 30, buttonY, buttonWidth, buttonHeight, acceptColor)
    dxDrawRectangle(x + 30, buttonY, buttonWidth, 2, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    dxDrawText("✅ قبول", x + 30, buttonY, x + 30 + buttonWidth, buttonY + buttonHeight, 
              tocolor(255, 255, 255, 255), 1, dxfont_small, "center", "center")
    
    -- زر رفض الطلب
    local rejectHover = isMouseInPosition(x + width - 30 - buttonWidth, buttonY, buttonWidth, buttonHeight) and selectedRequest
    local rejectColor = rejectHover and tocolor(200, 100, 100, 255) or tocolor(120, 60, 60, selectedRequest and 255 or 150)
    dxDrawRectangle(x + width - 30 - buttonWidth, buttonY, buttonWidth, buttonHeight, rejectColor)
    dxDrawRectangle(x + width - 30 - buttonWidth, buttonY, buttonWidth, 2, tocolor(200, 100, 100, 255))
    dxDrawText("❌ رفض", x + width - 30 - buttonWidth, buttonY, x + width - 30, buttonY + buttonHeight, 
              tocolor(255, 255, 255, 255), 1, dxfont_small, "center", "center")
    
    -- زر فاتورة الرحلة (بلون ذهبي بدل الأزرق)
    local billButtonY = buttonY - 45
    local billHover = isMouseInPosition(x + 30, billButtonY, width - 60, 35) and currentCustomer
    local billColor = billHover and tocolor(188, 152, 101, 255) or tocolor(primaryColor[1], primaryColor[2], primaryColor[3], currentCustomer and 255 or 150)
    dxDrawRectangle(x + 30, billButtonY, width - 60, 35, billColor)
    dxDrawRectangle(x + 30, billButtonY, width - 60, 2, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    dxDrawText("🧾 فاتورة الرحلة", x + 30, billButtonY, x + width - 30, billButtonY + 35, 
              tocolor(255, 255, 255, 255), 1, dxfont_small, "center", "center")
    
    -- تعليمات
    dxDrawText("• اختر طلباً من القائمة", x, billButtonY - 25, x + width, billButtonY - 8, 
              tocolor(150, 150, 150, 255), 0.85, dxfont_small, "center", "center")
end

-- رسم بانل الدفع
function drawPaymentPanel()
    if not paymentPanelVisible then return end
    
    local width, height = 350, 250
    local x = (screenW - width) / 2
    local y = (screenH - height) / 2
    
    -- الخلفية الرئيسية
    dxDrawRectangle(x, y, width, height, tocolor(20, 20, 20, 240))
    dxDrawRectangle(x, y, width, 2, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    dxDrawRectangle(x, y + height - 2, width, 2, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    dxDrawRectangle(x, y, 2, height, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    dxDrawRectangle(x + width - 2, y, 2, height, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    
    -- العنوان
    dxDrawText("🧾 فاتورة الرحلة", x, y + 15, x + width, y + 40, 
              tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255), 1.2, dxfont, "center", "center")
    
    -- خط ذهبي تحت العنوان
    dxDrawRectangle(x + 40, y + 42, width - 80, 1, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    
    dxDrawText("👤 العميل: " .. getPlayerName(currentCustomer):gsub("_", " "), x + 20, y + 50, x + width - 20, y + 70, 
              tocolor(255, 255, 255, 255), 1, dxfont_small, "left", "center")
    
    -- حقل إدخال المبلغ
    dxDrawText("💰 المبلغ:", x + 20, y + 85, x + width - 20, y + 105, 
              tocolor(255, 255, 255, 255), 1, dxfont_small, "left", "center")
    
    local inputBoxX, inputBoxY = x + 90, y + 80
    local inputBoxWidth, inputBoxHeight = 150, 35
    
    local inputHover = isMouseInPosition(inputBoxX, inputBoxY, inputBoxWidth, inputBoxHeight)
    local inputColor = inputHover and tocolor(50, 50, 50, 255) or tocolor(40, 40, 40, 255)
    
    dxDrawRectangle(inputBoxX, inputBoxY, inputBoxWidth, inputBoxHeight, inputColor)
    dxDrawRectangle(inputBoxX, inputBoxY, inputBoxWidth, 2, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    
    dxDrawText(paymentAmount or "0", inputBoxX + 10, inputBoxY, inputBoxX + inputBoxWidth - 10, inputBoxY + inputBoxHeight, 
              tocolor(255, 255, 255, 255), 1, dxfont_small, "center", "center")
    
    -- أزرار
    local buttonWidth = 130
    local buttonHeight = 35
    local buttonY = y + height - 50
    
    -- زر إرسال الفاتورة
    local sendHover = isMouseInPosition(x + 25, buttonY, buttonWidth, buttonHeight) and paymentAmount ~= ""
    local sendColor = sendHover and tocolor(188, 152, 101, 255) or tocolor(primaryColor[1], primaryColor[2], primaryColor[3], paymentAmount ~= "" and 255 or 150)
    dxDrawRectangle(x + 25, buttonY, buttonWidth, buttonHeight, sendColor)
    dxDrawRectangle(x + 25, buttonY, buttonWidth, 2, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    dxDrawText("✅ إرسال", x + 25, buttonY, x + 25 + buttonWidth, buttonY + buttonHeight, 
              tocolor(255, 255, 255, 255), 1, dxfont_small, "center", "center")
    
    -- زر إلغاء
    local cancelHover = isMouseInPosition(x + width - 25 - buttonWidth, buttonY, buttonWidth, buttonHeight)
    local cancelColor = cancelHover and tocolor(200, 100, 100, 255) or tocolor(120, 60, 60, 255)
    dxDrawRectangle(x + width - 25 - buttonWidth, buttonY, buttonWidth, buttonHeight, cancelColor)
    dxDrawRectangle(x + width - 25 - buttonWidth, buttonY, buttonWidth, 2, tocolor(200, 100, 100, 255))
    dxDrawText("❌ إلغاء", x + width - 25 - buttonWidth, buttonY, x + width - 25, buttonY + buttonHeight, 
              tocolor(255, 255, 255, 255), 1, dxfont_small, "center", "center")
end

-- التحكم في البانل
addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY)
    if button ~= "left" or state ~= "down" then return end
    
    -- التحكم في بانل التاكسي
    if taxiPanelVisible then
        local width, height = 420, 380
        local x = (screenW - width) / 2
        local y = (screenH - height) / 2
        
        -- النقر على طلبات
        local startY = y + 80
        local requestHeight = 50
        local index = 0
        
        for player, request in pairs(taxiRequests) do
            if isElement(player) then
                local requestY = startY + (index * (requestHeight + 8))
                if isMouseInPosition(x + 15, requestY, width - 30, requestHeight) then
                    selectedRequest = player
                    return
                end
                index = index + 1
            end
        end
        
        -- النقر على الأزرار
        local buttonWidth = 120
        local buttonHeight = 35
        local buttonY = y + height - 50
        
        -- زر قبول الطلب
        if isMouseInPosition(x + 30, buttonY, buttonWidth, buttonHeight) and selectedRequest then
            triggerServerEvent("acceptTaxiRequest", localPlayer, selectedRequest)
            taxiRequests[selectedRequest] = nil
            selectedRequest = nil
            closeTaxiPanel()
            return
        end
        
        -- زر رفض الطلب
        if isMouseInPosition(x + width - 30 - buttonWidth, buttonY, buttonWidth, buttonHeight) and selectedRequest then
            triggerServerEvent("rejectTaxiRequest", localPlayer, selectedRequest)
            taxiRequests[selectedRequest] = nil
            selectedRequest = nil
            return
        end
        
        -- زر فاتورة الرحلة
        local billButtonY = buttonY - 45
        if isMouseInPosition(x + 30, billButtonY, width - 60, 35) and currentCustomer then
            openPaymentPanel(currentCustomer)
            return
        end
    end
    
    -- التحكم في بانل الدفع
    if paymentPanelVisible then
        local width, height = 350, 250
        local x = (screenW - width) / 2
        local y = (screenH - height) / 2
        
        -- حقل إدخال المبلغ
        local inputBoxX, inputBoxY = x + 90, y + 80
        local inputBoxWidth, inputBoxHeight = 150, 35
        
        if isMouseInPosition(inputBoxX, inputBoxY, inputBoxWidth, inputBoxHeight) then
            -- فتح نافذة إدخال النص
            local currentAmount = paymentAmount == "" and "0" or paymentAmount
            local newAmount = getPlayerInput("أدخل المبلغ:", currentAmount, 10)
            if newAmount and tonumber(newAmount) then
                paymentAmount = tostring(math.floor(tonumber(newAmount)))
            end
            return
        end
        
        -- أزرار
        local buttonWidth = 130
        local buttonHeight = 35
        local buttonY = y + height - 50
        
        -- زر إرسال الفاتورة
        if isMouseInPosition(x + 25, buttonY, buttonWidth, buttonHeight) and paymentAmount ~= "" then
            local amount = tonumber(paymentAmount)
            if amount and amount > 0 then
                triggerServerEvent("sendTaxiBill", localPlayer, currentCustomer, amount)
                showToast("✅ تم إرسال الفاتورة للعميل", false)
                closePaymentPanel()
            end
            return
        end
        
        -- زر إلغاء
        if isMouseInPosition(x + width - 25 - buttonWidth, buttonY, buttonWidth, buttonHeight) then
            closePaymentPanel()
            return
        end
    end
end)

-- إدخال النص
function getPlayerInput(title, current, maxLength)
    local result = guiGetInputMode()
    -- هنا يمكن إضافة نافذة إدخال نص مخصصة
    return current
end

-- الرسم
addEventHandler("onClientRender", root, function()
    -- رسم التوست
    if toastData.visible then
        local elapsed = getTickCount() - toastData.startTime
        local progress = elapsed / toastData.duration
        
        if progress >= 1 then
            toastData.visible = false
            return
        end
        
        toastData.progress = 100 - (progress * 100)
        
        local toastWidth, toastHeight = 300, 45
        local toastX = (screenW - toastWidth) / 2
        local toastY = 80
        
        dxDrawRectangle(toastX, toastY, toastWidth, toastHeight, tocolor(20, 20, 20, 240))
        dxDrawRectangle(toastX, toastY, toastWidth, 1, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
        
        local progressWidth = (toastWidth * toastData.progress) / 100
        dxDrawRectangle(toastX, toastY + toastHeight - 1, progressWidth, 1, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
        
        local textColor = toastData.isError and tocolor(255, 100, 100, 255) or tocolor(255, 255, 255, 255)
        dxDrawText(toastData.message, toastX, toastY, toastX + toastWidth, toastY + toastHeight, 
                  textColor, 0.9, dxfont_small, "center", "center")
    end
    
    -- رسم بانل التاكسي
    drawTaxiPanel()
    
    -- رسم بانل الدفع
    drawPaymentPanel()
end)

-- تنظيف عند الخروج
addEventHandler("onClientResourceStop", resourceRoot, function()
    resetTaxiJob()
end)

outputDebugString("تم تحميل نظام التاكسي المحسن بنجاح")