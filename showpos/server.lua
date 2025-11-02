-- سيرفر سايد معدل
addCommandHandler("setpos", function(player, command, x, y, z)
    -- تحقق بسيط من التسجيل
    if isGuestAccount(getPlayerAccount(player)) then
        outputChatBox("❌ لازم تسجل دخول أولاً!", player, 255, 0, 0)
        return false
    end
    
    -- تحقق من وجود الإحداثيات
    if not x or not y or not z then
        outputChatBox("❌ استخدم: /setpos [x] [y] [z]", player, 255, 255, 0)
        outputChatBox("مثال: /setpos 1500 -2000 15", player, 255, 255, 0)
        return false
    end
    
    -- تحويل للإحداثيات
    local posX, posY, posZ = tonumber(x), tonumber(y), tonumber(z)
    
    if not posX or not posY or not posZ then
        outputChatBox("❌ الإحداثيات لازم تكون أرقام!", player, 255, 0, 0)
        return false
    end
    
    -- سجل محاولة النقل (للت debugging)
    outputDebugString("محاولة نقل اللاعب " .. getPlayerName(player) .. " إلى: " .. posX .. ", " .. posY .. ", " .. posZ)
    
    -- حاول النقل
    local success = setElementPosition(player, posX, posY, posZ)
    
    if success then
        outputChatBox("✅ تم النقل بنجاح!", player, 0, 255, 0)
        outputChatBox("📍 الإحداثيات: " .. posX .. ", " .. posY .. ", " .. posZ, player, 255, 255, 0)
        
        -- تحقق من الموقع الجديد
        local newX, newY, newZ = getElementPosition(player)
        outputDebugString("الموقع الجديد: " .. newX .. ", " .. newY .. ", " .. newZ)
    else
        outputChatBox("❌ فشل في النقل!", player, 255, 0, 0)
    end
    
    return success
end)

-- أمر تجريبي بدون صلاحيات
addCommandHandler("testpos", function(player, command, x, y, z)
    if not x or not y or not z then
        outputChatBox("استخدم: /testpos [x] [y] [z]", player, 255, 255, 0)
        return
    end
    
    local posX, posY, posZ = tonumber(x), tonumber(y), tonumber(z)
    
    if posX and posY and posZ then
        outputChatBox("🎯 محاولة نقل إلى: " .. posX .. ", " .. posY .. ", " .. posZ, player, 255, 255, 0)
        setElementPosition(player, posX, posY, posZ)
        outputChatBox("✅ تمت المحاولة!", player, 0, 255, 0)
    end
end)