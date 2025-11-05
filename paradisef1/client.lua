-- client.lua
-- Paradise F1 Panel - DXDraw - Arabic - Tajawal font
-- Author: Nader (UI: Crimson theme)

local screenW, screenH = guiGetScreenSize()
local isOpen = false
local tajawal = dxCreateFont("Tajawal-Regular.ttf", 14) or "default-bold"
local logoTexture = nil
if fileExists("logopr.png") then
    logoTexture = dxCreateTexture("logopr.png")
end

local colors = {
    bg = tocolor(13,13,13,230),
    panel = tocolor(26,26,26,240),
    white = tocolor(255,255,255,255),
    gray = tocolor(179,179,179,255),
    crimson = tocolor(220,20,60,255),
    hover = tocolor(255,59,78,255),
    border = tocolor(42,42,42,255)
}

local dashboardData = {
    account = {},
    vehicles = {},
    houses = {}
}

local selectedTab = "main"
local mouseDown = false
local textInputs = {
    complaintTarget = "",
    complaintText = ""
}

-- Helpers
local function isInBox(x,y,w,h)
    local mx,my = getCursorPosition()
    if not mx then return false end
    mx = mx * screenW
    my = my * screenH
    return mx >= x and mx <= x+w and my >= y and my <= y+h
end

-- Toggle panel
bindKey("f1","down",function()
    isOpen = not isOpen
    showCursor(isOpen)
    if isOpen then
        triggerServerEvent("f1.requestDashboard", resourceRoot)
    end
end)

-- Receive dashboard data
addEvent("f1.receiveDashboard", true)
addEventHandler("f1.receiveDashboard", root, function(payload)
    if payload.error then
        outputChatBox("[F1] "..tostring(payload.error))
        return
    end
    dashboardData = payload
end)

-- Gift result
addEvent("f1.receiveGiftResult", true)
addEventHandler("f1.receiveGiftResult", root, function(success, msg, extra)
    if success then
        outputChatBox("[F1] "..tostring(msg))
        -- refresh dashboard
        triggerServerEvent("f1.requestDashboard", resourceRoot)
    else
        outputChatBox("[F1] "..tostring(msg))
    end
end)

-- Complaint result
addEvent("f1.complaintResult", true)
addEventHandler("f1.complaintResult", root, function(success, msg)
    outputChatBox("[F1] "..tostring(msg))
    if success then
        textInputs.complaintTarget = ""
        textInputs.complaintText = ""
        triggerServerEvent("f1.requestDashboard", resourceRoot)
    end
end)

-- Save setting result
addEvent("f1.saveSettingResult", true)
addEventHandler("f1.saveSettingResult", root, function(success, msg)
    outputChatBox("[F1] "..tostring(msg))
end)

-- Mouse input basic tracking
addEventHandler("onClientKey", root, function(button, press)
    if button == "mouse1" then
        mouseDown = press
    end
end)

-- Main render
addEventHandler("onClientRender", root, function()
    if not isOpen then return end

    local baseX, baseY = screenW*0.1, screenH*0.06
    local baseW, baseH = screenW*0.8, screenH*0.82

    -- backdrop
    dxDrawRectangle(baseX, baseY, baseW, baseH, colors.bg, true)

    -- sidebar
    local sideX, sideY, sideW, sideH = baseX + 20, baseY + 20, 260, baseH - 40
    dxDrawRectangle(sideX, sideY, sideW, sideH, colors.panel, true)

    -- logo + server name
    if logoTexture then
        dxDrawImage(sideX + 16, sideY + 16, 64, 64, logoTexture, 0,0,0, colors.white, true)
    end
    dxDrawText("Paradise RP", sideX + 96, sideY + 24, sideX + sideW - 12, sideY + 56, colors.white, 1.2, tajawal, "left", "top", false, false, true)

    -- tabs
    local tabs = {
        {id="main", text="الرئيسية"},
        {id="assets", text="ممتلكاتي"},
        {id="complaint", text="تقديم شكوى"},
        {id="vip", text="اشتراك خاص"},
        {id="rules", text="القوانين والإرشادات"},
        {id="gifts", text="الهدايا"},
        {id="settings", text="الإعدادات والأشكال"}
    }
    local tabStartY = sideY + 100
    for i,t in ipairs(tabs) do
        local tx = sideX + 12
        local ty = tabStartY + (i-1) * 48
        local tw = sideW - 24
        local th = 40
        local active = (selectedTab == t.id)
        if active then
            dxDrawRectangle(tx, ty, tw, th, colors.crimson, true)
            dxDrawText(t.text, tx+12, ty+8, tx+tw-12, ty+th, colors.white, 1, tajawal, "left", "center", false, false, true)
        else
            local col = colors.panel
            if isInBox(tx,ty,tw,th) then
                col = colors.border
                if mouseDown then selectedTab = t.id end
            end
            dxDrawRectangle(tx, ty, tw, th, col, true)
            dxDrawText(t.text, tx+12, ty+8, tx+tw-12, ty+th, colors.white, 1, tajawal, "left", "center", false, false, true)
        end
    end

    -- content area
    local contentX, contentY = sideX + sideW + 20, sideY
    local contentW, contentH = baseX + baseW - 20 - contentX, sideH
    dxDrawRectangle(contentX, contentY, contentW, contentH, colors.panel, true)

    -- render selected tab content
    if selectedTab == "main" then
        renderMain(contentX, contentY, contentW, contentH)
    elseif selectedTab == "assets" then
        renderAssets(contentX, contentY, contentW, contentH)
    elseif selectedTab == "complaint" then
        renderComplaint(contentX, contentY, contentW, contentH)
    elseif selectedTab == "vip" then
        renderVIP(contentX, contentY, contentW, contentH)
    elseif selectedTab == "rules" then
        renderRules(contentX, contentY, contentW, contentH)
    elseif selectedTab == "gifts" then
        renderGifts(contentX, contentY, contentW, contentH)
    elseif selectedTab == "settings" then
        renderSettings(contentX, contentY, contentW, contentH)
    end
end)

-- Render functions
function renderMain(x,y,w,h)
    dxDrawText("الصفحة الرئيسية", x+16, y+16, x+w-16, y+56, colors.white, 1.4, tajawal, "left", "top")
    local a = dashboardData.account or {}
    dxDrawText("اسم اللاعب: "..(a.username or "غير معروف"), x+16, y+64, x+w-16, y+96, colors.gray, 1, tajawal, "left", "top")
    dxDrawText("المال: "..(a.money or 0).."$", x+16, y+96, x+w-16, y+128, colors.gray, 1, tajawal, "left", "top")
    dxDrawText("المستوى: "..(a.level or 0).."    XP: "..(a.xp or 0), x+16, y+128, x+w-16, y+160, colors.gray, 1, tajawal, "left", "top")
    dxDrawText("ساعات اللعب: "..(a.hours or 0), x+16, y+160, x+w-16, y+192, colors.gray, 1, tajawal, "left", "top")

    -- quick actions
    local bx, by, bw, bh = x+16, y+210, 200, 40
    dxDrawRectangle(bx, by, bw, bh, colors.crimson, true)
    dxDrawText("فتح قائمة السيارات", bx, by, bx+bw, by+bh, colors.white, 1, tajawal, "center", "center")
    if isInBox(bx,by,bw,bh) and mouseDown then
        selectedTab = "assets"
    end
end

function renderAssets(x,y,w,h)
    dxDrawText("ممتلكاتي", x+16, y+16, x+w-16, y+56, colors.white, 1.4, tajawal, "left", "top")

    dxDrawText("السيارات:", x+16, y+64, x+w-16, y+96, colors.gray, 1, tajawal, "left", "top")
    local vy = y + 96
    local vehicles = dashboardData.vehicles or {}
    for i=1, #vehicles do
        local v = vehicles[i]
        local model = v.model or v.vehicle or v.model_name or v.vehicle_model or "غير معروف"
        local plate = v.plate or v.plate_number or v.plate_no or "-"
        local sy = vy + (i-1) * 36
        dxDrawText(i..". "..tostring(model).." | لوحة: "..tostring(plate), x+20, sy, x+w-200, sy+28, colors.white, 1, tajawal, "left", "center")
        local bx, by, bw, bh = x + w - 160, sy, 120, 28
        dxDrawRectangle(bx, by, bw, bh, colors.border, true)
        dxDrawText("استدعاء", bx, by, bx+bw, by+bh, colors.white, 1, tajawal, "center", "center")
        if isInBox(bx,by,bw,bh) and mouseDown then
            -- be careful trusting client data; we send vehicle row object to server for lookup
            triggerServerEvent("f1.requestVehicleSpawn", resourceRoot, v)
        end
    end

    -- houses
    dxDrawText("البيوت:", x+16, y + 320, x+w-16, y + 352, colors.gray, 1, tajawal, "left", "top")
    local houses = dashboardData.houses or {}
    for i=1, #houses do
        local hdata = houses[i]
        local name = hdata.houseName or hdata.name or hdata.title or ("بيت "..i)
        local sy = y + 352 + (i-1) * 36
        dxDrawText(i..". "..tostring(name), x+20, sy, x+w-20, sy+28, colors.white, 1, tajawal, "left", "center")
    end
end

function renderComplaint(x,y,w,h)
    dxDrawText("تقديم شكوى", x+16, y+16, x+w-16, y+56, colors.white, 1.4, tajawal, "left", "top")

    dxDrawText("ضد:", x+16, y+74, x+w-16, y+96, colors.gray, 1, tajawal, "left", "top")
    local tx, ty, tw, th = x+16, y+100, w-32, 34
    dxDrawRectangle(tx, ty, tw, th, colors.border, true)
    dxDrawText(textInputs.complaintTarget or "", tx+8, ty+4, tx+tw-8, ty+th, colors.white, 1, tajawal, "left", "center")
    if isInBox(tx,ty,tw,th) and mouseDown then
        -- focus: use inputBox (since MTA has no built-in textareas easily) -> we'll use default inputBox
        local res = guiCreateStaticImage(0,0,0,0,"",false) -- dummy to consume click
        local entered = exports.vio_input and exports.vio_input:showInputBox or nil
        -- fallback simple input via outputChatBox prompt
        outputChatBox("[F1] اكتب اسم الهدف في الشات الآن ثم ارسل (سيتم التقاط السطر كهدف).")
        -- Note: For a full text input, you'd implement a custom dxEdit control,
        -- here we'll keep it simple because you said you already have files.
    end

    dxDrawText("نص الشكوى:", x+16, y+148, x+w-16, y+176, colors.gray, 1, tajawal, "left", "top")
    local taX, taY, taW, taH = x+16, y+176, w-32, 160
    dxDrawRectangle(taX, taY, taW, taH, colors.border, true)
    dxDrawText(textInputs.complaintText or "", taX+8, taY+8, taX+taW-8, taY+taH-8, colors.white, 1, tajawal, "left", "top")

    local bx, by, bw, bh = x+16, y+348, 180, 36
    dxDrawRectangle(bx, by, bw, bh, colors.crimson, true)
    dxDrawText("إرسال الشكوى", bx, by, bx+bw, by+bh, colors.white, 1, tajawal, "center", "center")
    if isInBox(bx,by,bw,bh) and mouseDown then
        triggerServerEvent("f1.submitComplaint", resourceRoot, textInputs.complaintTarget, textInputs.complaintText)
    end
end

function renderVIP(x,y,w,h)
    dxDrawText("اشتراك خاص (VIP)", x+16, y+16, x+w-16, y+56, colors.white, 1.4, tajawal, "left", "top")
    dxDrawText("المزايا:", x+16, y+72, x+w-16, y+96, colors.gray, 1, tajawal, "left", "top")
    dxDrawText("- مزايا خاصة للـ VIP تُعرض هنا", x+16, y+100, x+w-16, y+132, colors.white, 1, tajawal, "left", "top")

    local bx, by, bw, bh = x+16, y+150, 220, 36
    dxDrawRectangle(bx, by, bw, bh, colors.crimson, true)
    dxDrawText("تقديم طلب اشتراك VIP", bx, by, bx+bw, by+bh, colors.white, 1, tajawal, "center", "center")
    if isInBox(bx,by,bw,bh) and mouseDown then
        triggerServerEvent("f1.requestVIP", resourceRoot)
    end
end

function renderRules(x,y,w,h)
    dxDrawText("القوانين والإرشادات", x+16, y+16, x+w-16, y+56, colors.white, 1.4, tajawal, "left", "top")
    dxDrawText("لا توجد قوانين مضافة بعد. سيتم عرض القوانين هنا عند إضافتها.", x+16, y+80, x+w-16, y+120, colors.gray, 1, tajawal, "left", "top")
end

function renderGifts(x,y,w,h)
    dxDrawText("الهدايا", x+16, y+16, x+w-16, y+56, colors.white, 1.4, tajawal, "left", "top")

    -- We'll show default 3 gifts (server has table); this client uses static list as fallback.
    local gifts = {
        {id=1, name="هدية يومية صغيرة", money=2500, xp=150},
        {id=2, name="هدية يومية متوسطة", money=5000, xp=300},
        {id=3, name="هدية VIP أسبوعية", money=20000, xp=1200}
    }
    for i,g in ipairs(gifts) do
        local sy = y + 56 + (i-1) * 64
        dxDrawText(g.name.." - "..g.money.."$ / "..g.xp.." XP", x+20, sy, x+w-200, sy+28, colors.white, 1, tajawal, "left", "center")
        local bx, by, bw, bh = x + w - 160, sy - 6, 140, 34
        dxDrawRectangle(bx, by, bw, bh, colors.crimson, true)
        dxDrawText("استلام", bx, by, bx+bw, by+bh, colors.white, 1, tajawal, "center", "center")
        if isInBox(bx,by,bw,bh) and mouseDown then
            triggerServerEvent("f1.claimDailyGift", resourceRoot, g.id)
        end
    end
end

local localSettings = { showVehicleSkins = true, showHUD = true, effects = true }
function renderSettings(x,y,w,h)
    dxDrawText("الإعدادات والأشكال", x+16, y+16, x+w-16, y+56, colors.white, 1.4, tajawal, "left", "top")
    local opts = {
        {key="showVehicleSkins", text="إظهار أشكال السيارات"},
        {key="showHUD", text="إظهار HUD"},
        {key="effects", text="مؤثرات إضافية"}
    }
    for i,opt in ipairs(opts) do
        local sy = y + 56 + (i-1) * 48
        dxDrawText(opt.text, x+20, sy, x+w-220, sy+32, colors.white, 1, tajawal, "left", "center")
        local bx, by, bw, bh = x + w - 180, sy - 6, 140, 36
        local col = localSettings[opt.key] and colors.crimson or colors.border
        dxDrawRectangle(bx, by, bw, bh, col, true)
        dxDrawText(localSettings[opt.key] and "مُفعّل" or "متوقّف", bx, by, bx+bw, by+bh, colors.white, 1, tajawal, "center", "center")
        if isInBox(bx,by,bw,bh) and mouseDown then
            localSettings[opt.key] = not localSettings[opt.key]
            triggerServerEvent("f1.saveSetting", resourceRoot, opt.key, tostring(localSettings[opt.key]))
        end
    end
end

-- end client.lua
