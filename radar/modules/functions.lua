

return function(__scale__)
    return {
        createtexture = function(...) return dxCreateTexture(...) end,
        settarget = function(target, clear, __func) dxSetRenderTarget(target, clear) __func() dxSetRenderTarget() end,
        rendertarget = function(relative, w, h, ...) return dxCreateRenderTarget(not relative and w or __scale__ * w, not relative and h or __scale__ * h, ...) end,
        rectangle = function(relative, x, y, w, h, ...) local x, y, w, h = not relative and x or __scale__ *  x, not relative and y or __scale__ * y, not relative and w or __scale__ * w, not relative and h or __scale__ * h return dxDrawRectangle(x, y, w, h, ...) end,
        image = function(relative, x, y, w, h, ...) return dxDrawImage(not relative and x or __scale__ * x, not relative and y or __scale__ * y, not relative and w or __scale__ * w, not relative and h or __scale__ * h, ...) end,
        imagesection = function(relative, x, y, w, h, ...) local x, y, w, h = not relative and x or __scale__ *  x, not relative and y or __scale__ * y, not relative and w or __scale__ * w, not relative and h or __scale__ * h return dxDrawImageSection(x, y, w, h, ...) end,
        text = function(relative, text, x, y, w, h, ...)  local x, y, w, h = not relative and x or __scale__ *  x, not relative and y or __scale__ * y, not relative and w or __scale__ * w, not relative and h or __scale__ * h return dxDrawText(text, x, y, ( x + w), (y + h), ...) end,
        cursor = function (relative, x, y, w, h) if isCursorShowing() then local x, y, w, h = not relative and x or __scale__ *  x, not relative and y or __scale__ * y, not relative and w or __scale__ * w, not relative and h or __scale__ * h local mx, my = getCursorPosition() local fullx, fully = guiGetScreenSize() cursorx, cursory = mx*fullx, my*fully if cursorx > x and cursorx < x + w and cursory > y and cursory < y + h then return true else return false end end end,
        round = function(relative, x, y, width, height, radius, offset, colorBackground, strokeOffset, colorStroke, sizeStroke, postGUI) local x, y, width,  height, radius = not relative and x or __scale__ * x, not relative and y or __scale__ * y, not relative and width or __scale__ * width, not relative and height or __scale__ * height, not relative and radius or  __scale__ * radius if not buttons then buttons = {} end if not strokes then strokes = {} end colorStroke = tostring(colorStroke) sizeStroke = tostring(sizeStroke) 
            if (not buttons[radius + width + height..'-'..colorBackground..'-'..colorStroke]) then 
                local raw = string.format([[ <svg width='%s' height='%s' fill='none' xmlns='http://www.w3.org/2000/svg'>     <mask id='path_inside' fill='#FFFFFF' > <rect width='%s' height='%s' rx='%s' />     </mask>     <rect opacity='1' width='%s' height='%s' rx='%s' fill='%s' mask='url(#path_inside)'/> </svg>     ]], width, height, width, height, radius, width, height, radius, colorBackground) 
                local stroke = string.format([[ <svg width='%s' height='%s' fill='none' xmlns='http://www.w3.org/2000/svg'>     <mask id='path_inside' fill='#FFFFFF' > <rect width='%s' height='%s' rx='%s' />     </mask>     <rect opacity='1' width='%s' height='%s' rx='%s' stroke='%s' stroke-width='%s' mask='url(#path_inside)'/> </svg>     ]], width, height, width, height, radius, width, height, radius, colorStroke, sizeStroke) 
                buttons[radius + width + height..'-'..colorBackground..'-'..colorStroke] = svgCreate(width, height, raw) 
                strokes[radius + width + height..'-'..colorBackground..'-'..colorStroke] = svgCreate(width, height, stroke) 
            end 
            if (buttons[radius + width + height..'-'..colorBackground..'-'..colorStroke]) then 
                dxDrawImage(x, y, width, height, buttons[radius + width + height..'-'..colorBackground..'-'..colorStroke], 0, 0, 0, tocolor(255, 255, 255, offset), postGUI) 
                dxDrawImage(x, y, width, height, strokes[radius + width + height..'-'..colorBackground..'-'..colorStroke], 0, 0, 0, tocolor(255, 255, 255, strokeOffset), postGUI) 
            end 
        end,
        formatnumber = function(number, sep)
            assert(type(tonumber(number))=="number", "Bad argument @'formatNumber' [Expected number at argument 1 got "..type(number).."]")
            assert(not sep or type(sep)=="string", "Bad argument @'formatNumber' [Expected string at argument 2 got "..type(sep).."]")
            local money = number
            for i = 1, tostring(money):len()/3 do
                money = string.gsub(money, "^(-?%d+)(%d%d%d)", "%1"..sep.."%2")
            end
            return money
        end,
        hex2rgb = function(hex) 
            hex = hex:gsub("#","") 
            return {tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))} 
        end,
        
        rgb2hex = function(red, green, blue)
            if( ( red < 0 or red > 255 or green < 0 or green > 255 or blue < 0 or blue > 255 ) ) then return nil end
            return string.format("#%.2X%.2X%.2X", red, green, blue)
        end,
        
        findrotation = function(x1,y1,x2,y2)
            local t = -math.deg(math.atan2(x2-x1,y2-y1))
            if t < 0 then t = t + 360 end;
            return t;
        end,
        getPointFromDistanceRotation = function(x, y, dist, angle)
            local a = math.rad(90 - angle);
            local dx = math.cos(a) * dist;
            local dy = math.sin(a) * dist;
            return x+dx, y+dy;
        end,
        table_find = function(t, ...) local args = { ... } if #args == 0 then for k,v in pairs(t) do if v then return k end end return false end local value = table.remove(args) if value == '[nil]' then value = nil end for k,v in pairs(t) do for i,index in ipairs(args) do if type(index) == 'function' then v = index(v) else if index == '[last]' then index = #v end v = v[index] end end if v == value then return k end end return false end,
    }
end