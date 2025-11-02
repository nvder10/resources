-- server_login.lua
addEvent("onClientLoginAttempt", true)
addEventHandler("onClientLoginAttempt", root, function(username, password, rememberMe)
    local player = client
    
    -- التحقق من البيانات في الداتابيز
    dbQuery(function(qh)
        local result = dbPoll(qh, 0)
        if result and #result > 0 then
            local account = result[1]
            -- التحقق من كلمة المرور (bcrypt)
            if verifyPassword(password, account.password) then
                triggerClientEvent(player, "onClientLoginSuccess", player)
                outputChatBox("تم تسجيل الدخول بنجاح!", player, 0, 255, 0)
            else
                outputChatBox("كلمة المرور غير صحيحة", player, 255, 0, 0)
            end
        else
            outputChatBox("اسم المستخدم غير موجود", player, 255, 0, 0)
        end
    end, connection, "SELECT * FROM accounts WHERE username = ?", username)
end)

-- دالة التحقق من كلمة المرور (ستحتاج لتعديلها حسب نظام التشفير المستخدم)
function verifyPassword(inputPassword, storedHash)
    -- هنا تضيف منطق التحقق من كلمة المرور
    return inputPassword == "test" -- مؤقت لأغراض الاختبار
end