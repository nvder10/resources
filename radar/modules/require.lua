
-- Author :

local PATH = "assets/modules/?.lua;modules/?.lua;?.lua;";

local function find_full_path(name)
    if (fileExists(name)) then return name end

    for path in PATH:gmatch("[^;]+") do
        path = path:gsub("%?", name);

        if (fileExists(path)) then
            return path;
        end
    end
end


local MEM_MODULES = {}
local __func__ = 'up_character'

function require(name)
    
    local nameType = type(name);
    
    if (nameType ~= "string") then
        error("bad argument #1 to '" ..__func__.. "' (string expected, got " ..nameType.. ")", 2);
    end
    
    local path = find_full_path(name);
    
    if (not path) then
        error("bad argument #1 to '" ..__func__.. "' (file not found)", 2);
    end
    

    local module = MEM_MODULES[path];
    
    if (not module) then
        local file = fileOpen(path);
        local fileSize = fileGetSize(file);
        
        local code = fileRead(file, fileSize);
        fileClose(file);
        
        local func, err = loadstring(code);
        
        if (not func) and err then
            error("bad argument #1 to '" ..__func__.. "' (error loading " ..name.. ")\n-> " ..err, 2);
        end
        
        local success;
        
        success, module = pcall(func);
        
        if (not success) then
            error("bad argument #1 to '" ..__func__.. "' (error loading " ..name.. ")\n-> " ..module, 2);
        end
        
        MEM_MODULES[path] = module;
    end
    
    return module;
end