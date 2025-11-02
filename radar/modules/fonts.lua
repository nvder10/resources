local list = {}
return {
    create = function(name, directory, size, scale)
        
        gSize = function(directory, size)
            local size__ = size
            local __size = 1
            while true do
                local font = dxCreateFont(directory, __size)
                local height = dxGetFontHeight(1, font)
                destroyElement(font)
                if height == size__ then
                    return __size
                end
                __size = __size + 1
                if __size == 100 then
                    break
                end
            end
        end

        if not list[name] then
            list[name] = {}
        end

        list[name][size] = dxCreateFont(directory, gSize(directory, size) * scale)
    end,

    use = function(name, size) if list[name] and list[name][size] then return list[name][size] end end  
}