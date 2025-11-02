cursor = function (relative, x, y, w, h) if isCursorShowing() then local x, y, w, h = not relative and x or __scale__ *  x, not relative and y or __scale__ * y, not relative and w or __scale__ * w, not relative and h or __scale__ * h local mx, my = getCursorPosition() local fullx, fully = guiGetScreenSize() cursorx, cursory = mx*fullx, my*fully if cursorx > x and cursorx < x + w and cursory > y and cursory < y + h then return true else return false end end end

editbox = {
    edits = {},
    actualClick = nil
}

editbox.create = function(name, defaultText, x, y, w, h, type, color, offset, maxChar, allowNumber, space, font, style)
    if not editbox.edits[name] then
        editbox.edits[name] = {text = '', defaultText = defaultText, click = false, x = x, y = y, w = w, h = h, type = type, maxChar = maxChar, allowNumber = allowNumber, space = space, isNumbers = isNumbers, style = style}
    end

    editbox.edits[name].x = x
    editbox.edits[name].y = y

    local box = editbox.edits[name]
    dxDrawText((box.text == '' and box.defaultText) or (type == 'password' and string.gsub(box.text, ".", "•") or box.text), box.x, box.y, box.x + box.w, box.y + box.h, tocolor(color[1], color[2], color[3], offset), 1, font, style, 'center')
    
    if box.click and editbox.actualClick then
        if getKeyState('backspace') then
            local box = editbox.edits[editbox.actualClick]
            if not backSpaceTick then
                backSpaceTick = getTickCount()
            end
    
            if getTickCount() > backSpaceTick + 100 then
                box.text = string.sub(box.text, 1, (#box.text - 1))
                backSpaceTick = nil
            end
        end
    end
end

editbox.set = function(name, text)
    if not editbox.edits[name] then return false end
    editbox.edits[name].text = text
end

editbox.get = function(name)
    return editbox.edits[name]
end

addEventHandler('onClientClick', root, 
    function(key, state)
        if key and state then
            for id, response in pairs(editbox.edits) do
                if cursor(false, response.x, response.y, response.w, response.h) then
                    response.click = true
                    editbox.actualClick = id
                    toggleControl ( 'all', false )
                    guiSetInputMode("no_binds")
                else
                    response.click = false
                    toggleControl ( 'all', true ) 
                    guiSetInputMode("allow_binds")
                end
            end
        end
    end
)

addEventHandler('onClientCharacter', root, 
    function(key)
        for id, response in pairs(editbox.edits) do
            if key == ' ' then if not response.space then return end end

            if response.click and #response.text < response.maxChar then
                if response.isNumbers and tonumber(key) then
                    response.text = response.text..key    
                else
                    if response.allowNumber == 'number' then
                        if not tonumber(key) then return end
                        response.text = response.text..tonumber(key)
                    elseif response.allowNumber == 'text' then
                        if tonumber(key) then return end
                        response.text = response.text..key
                    else
                        response.text = response.text..key
                    end
                end
            end
        end
    end
)

return editbox