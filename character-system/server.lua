local mysql = exports.mysql

-- حدث لفتح النظام من الريسورس الرئيسي
addEvent("characterSystem:open", true)
addEventHandler("characterSystem:open", root, function()
    triggerClientEvent(client, "characterSystem:open", client)
end)

-- حدث للحصول على قائمة الشخصيات
addEvent("characterSystem:getCharacters", true)
addEventHandler("characterSystem:getCharacters", root, function()
    local characters = getElementData(client, "account:characters") or {}
    triggerClientEvent(client, "characterSystem:receiveCharacters", client, characters)
end)

-- حدث لإنشاء شخصية جديدة
addEvent("characterSystem:createCharacter", true)
addEventHandler("characterSystem:createCharacter", root, function(characterData)
    local characterName = characterData.name
    local gender = characterData.gender
    local skin = characterData.skin
    local age = characterData.age
    local height = characterData.height
    local weight = characterData.weight
    
    -- التحقق من صحة البيانات
    if not characterName or string.len(characterName) < 3 then
        triggerClientEvent(client, "characterSystem:creationResult", client, false, "اسم الشخصية يجب أن يكون 3 أحرف على الأقل")
        return
    end
    
    if not age or age < 16 or age > 100 then
        triggerClientEvent(client, "characterSystem:creationResult", client, false, "العمر يجب أن يكون بين 16 و 100")
        return
    end
    
    -- استدعاء النظام القديم لإنشاء الشخصية
    triggerEvent("accounts:characters:new", client, 
        characterName, "", 0, gender, skin, height, weight, age, 1, 1, 1, 
        {0, 0, 0, 0, 0, 0, "Unknown"}
    )
end)

-- حدث لاختيار شخصية
addEvent("characterSystem:selectCharacter", true)
addEventHandler("characterSystem:selectCharacter", root, function(characterID)
    triggerServerEvent("accounts:characters:spawn", client, characterID)
end)

-- حدث للخروج
addEvent("characterSystem:logout", true)
addEventHandler("characterSystem:logout", root, function()
    triggerServerEvent("accounts:characters:logout", client)
end)