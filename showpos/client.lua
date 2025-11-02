-- أمر لعرض الإحداثيات الحالية في الشات والكونسول
addCommandHandler("mypos", function()
    local x, y, z = getElementPosition(localPlayer)
    local rx, ry, rz = getElementRotation(localPlayer)
    
    -- إظهار في الشات
    outputChatBox("📍 الإحداثيات الحالية:")
    outputChatBox("🔄 X: " .. x .. " | Y: " .. y .. " | Z: " .. z)
    outputChatBox("🎯 RX: " .. rx .. " | RY: " .. ry .. " | RZ: " .. rz)
    
    -- إظهار في الكونسول
    outputConsole("📍 الإحداثيات الحالية: X=" .. x .. " Y=" .. y .. " Z=" .. z)
    outputConsole("🎯 الدوران: RX=" .. rx .. " RY=" .. ry .. " RZ=" .. rz)
end)

-- أمر مختصر
addCommandHandler("myp", function()
    local x, y, z = getElementPosition(localPlayer)
    outputChatBox("📍 " .. x .. ", " .. y .. ", " .. z)
    outputConsole("📍 " .. x .. ", " .. y .. ", " .. z)
end)