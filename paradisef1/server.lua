-- server.lua
-- Paradise F1 Panel Edition
-- Author: Nader (per user request)
-- Notes:
--   - This expects an active mysql resource exposing exports.mysql:getConnection()
--   - Adjust queries/column names if your vehicles/houses tables use different fields.

local MYSQL = nil

-- Helper: get connection (Paradise style)
local function getConnection()
    if exports.mysql and exports.mysql.getConnection then
        return exports.mysql:getConnection()
    end
    return nil
end

-- Safe SQL escape fallback (very basic). Prefer using your mysql resource escaping if available.
local function escapeSQL(s)
    if not s then return "" end
    s = tostring(s)
    -- basic escape for quotes
    s = s:gsub("\\", "\\\\")
    s = s:gsub("'", "\\'")
    s = s:gsub("\"", "\\\"")
    return s
end

-- DB query wrapper using OWL connection
local function dbQuerySync(query)
    local conn = getConnection()
    if not conn then
        outputDebugString("[paradise_f1] MySQL connection not found. Ensure mysql resource is started.")
        return nil
    end
    local qh = dbQuery(conn, query)
    if not qh then
        outputDebugString("[paradise_f1] dbQuery returned nil for: "..tostring(query))
        return nil
    end
    local res = dbPoll(qh, 0)
    return res
end

local function dbExecSync(query)
    local conn = getConnection()
    if not conn then
        outputDebugString("[paradise_f1] MySQL connection not found for dbExec.")
        return false
    end
    return dbExec(conn, query)
end

-- Create helper tables (if not exist)
local function ensureHelperTables()
    -- daily gifts
    local q1 = [[
        CREATE TABLE IF NOT EXISTS f1_daily_gifts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            money INT DEFAULT 0,
            xp INT DEFAULT 0,
            cooldown_seconds INT DEFAULT 86400
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]
    dbExecSync(q1)

    -- claims
    local q2 = [[
        CREATE TABLE IF NOT EXISTS f1_daily_claims (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            gift_id INT NOT NULL,
            claimed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]
    dbExecSync(q2)

    -- complaints
    local q3 = [[
        CREATE TABLE IF NOT EXISTS f1_complaints (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            target VARCHAR(255),
            text TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]
    dbExecSync(q3)

    -- player settings
    local q4 = [[
        CREATE TABLE IF NOT EXISTS f1_player_settings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            account_id INT NOT NULL,
            setting_key VARCHAR(100),
            setting_value VARCHAR(255),
            UNIQUE KEY (account_id, setting_key)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]
    dbExecSync(q4)

    -- insert default gifts if empty
    local check = dbQuerySync("SELECT COUNT(*) AS c FROM f1_daily_gifts")
    if check and #check > 0 and tonumber(check[1].c) == 0 then
        dbExecSync("INSERT INTO f1_daily_gifts (name, money, xp, cooldown_seconds) VALUES ('هدية يومية صغيرة', 2500, 150, 86400)")
        dbExecSync("INSERT INTO f1_daily_gifts (name, money, xp, cooldown_seconds) VALUES ('هدية يومية متوسطة', 5000, 300, 86400)")
        dbExecSync("INSERT INTO f1_daily_gifts (name, money, xp, cooldown_seconds) VALUES ('هدية VIP أسبوعية', 20000, 1200, 604800)")
        outputDebugString("[paradise_f1] Default gifts inserted.")
    end
end

addEventHandler("onResourceStart", resourceRoot, function()
    if not exports.mysql or not exports.mysql.getConnection then
        outputDebugString("[paradise_f1] Warning: exports.mysql:getConnection() not available. Start mysql resource first.")
    else
        outputDebugString("[paradise_f1] MySQL export detected.")
    end
    ensureHelperTables()
end)

-- Utility: fetch account row from accounts table by getPlayerAccount() name or player name
local function fetchAccountRow(player)
    local accName = nil
    local acc = getPlayerAccount(player)
    if acc and getAccountName then
        accName = getAccountName(acc)
    end
    if not accName then
        accName = getPlayerName(player)
    end
    if not accName then return nil end

    local q = string.format("SELECT * FROM accounts WHERE username = '%s' LIMIT 1", escapeSQL(accName))
    local rows = dbQuerySync(q)
    if rows and #rows > 0 then
        return rows[1]
    end
    return nil
end

-- Utility: get player's vehicles from common tables
local function fetchPlayerVehicles(accountRow)
    local uname = accountRow.username or ""
    local accid = tonumber(accountRow.id) or 0

    -- We'll try multiple tables and union results
    local parts = {}
    table.insert(parts, string.format("SELECT 'vehicles' AS source, * FROM vehicles WHERE owner = '%s' OR owner_id = %d", escapeSQL(uname), accid))
    table.insert(parts, string.format("SELECT 'vehicles_custom' AS source, * FROM vehicles_custom WHERE owner = '%s' OR owner_id = %d", escapeSQL(uname), accid))
    table.insert(parts, string.format("SELECT 'vehicles_shop' AS source, * FROM vehicles_shop WHERE owner = '%s' OR owner_id = %d", escapeSQL(uname), accid))

    local query = table.concat(parts, " UNION ALL ")
    local res = dbQuerySync(query)
    if not res then return {} end
    return res
end

-- Utility: get player's houses common names
local function fetchPlayerHouses(accountRow)
    local uname = accountRow.username or ""
    local accid = tonumber(accountRow.id) or 0

    local parts = {}
    table.insert(parts, string.format("SELECT 'player_houses' AS source, * FROM player_houses WHERE owner = '%s' OR owner_id = %d", escapeSQL(uname), accid))
    table.insert(parts, string.format("SELECT 'houses' AS source, * FROM houses WHERE owner = '%s' OR owner_id = %d", escapeSQL(uname), accid))

    local query = table.concat(parts, " UNION ALL ")
    local res = dbQuerySync(query)
    if not res then return {} end
    return res
end

-- -----------------------
-- Events: Dashboard data request
-- -----------------------
addEvent("f1.requestDashboard", true)
addEventHandler("f1.requestDashboard", resourceRoot, function()
    local player = source
    local accountRow = fetchAccountRow(player)
    if not accountRow then
        triggerClientEvent(player, "f1.receiveDashboard", player, { error = "لا يوجد حساب مرتبط" })
        return
    end

    local account = {
        id = accountRow.id,
        username = accountRow.username,
        money = tonumber(accountRow.money) or 0,
        xp = tonumber(accountRow.xp) or 0,
        level = tonumber(accountRow.level) or 0,
        hours = tonumber(accountRow.hours) or 0
    }

    -- fetch vehicles & houses (may be empty)
    local vehicles = fetchPlayerVehicles(accountRow) or {}
    local houses = fetchPlayerHouses(accountRow) or {}

    local payload = {
        account = account,
        vehicles = vehicles,
        houses = houses
    }
    triggerClientEvent(player, "f1.receiveDashboard", player, payload)
end)

-- -----------------------
-- Daily gifts claim
-- -----------------------
addEvent("f1.claimDailyGift", true)
addEventHandler("f1.claimDailyGift", resourceRoot, function(gift_id)
    local player = source
    local accountRow = fetchAccountRow(player)
    if not accountRow then
        triggerClientEvent(player, "f1.receiveGiftResult", player, false, "لا يوجد حساب مرتبط")
        return
    end
    local accid = tonumber(accountRow.id) or 0
    gift_id = tonumber(gift_id) or 0
    if gift_id <= 0 then
        triggerClientEvent(player, "f1.receiveGiftResult", player, false, "معرّف الهدية غير صالح")
        return
    end

    -- get gift
    local giftQ = string.format("SELECT * FROM f1_daily_gifts WHERE id = %d LIMIT 1", gift_id)
    local giftRows = dbQuerySync(giftQ)
    if not giftRows or #giftRows == 0 then
        triggerClientEvent(player, "f1.receiveGiftResult", player, false, "الهدية غير موجودة")
        return
    end
    local gift = giftRows[1]

    -- check last claim
    local checkQ = string.format("SELECT * FROM f1_daily_claims WHERE account_id = %d AND gift_id = %d ORDER BY claimed_at DESC LIMIT 1", accid, gift_id)
    local last = dbQuerySync(checkQ)
    local canClaim = true
    if last and #last > 0 and last[1].claimed_at then
        -- convert SQL timestamp to epoch
        local ts = last[1].claimed_at -- format 'YYYY-MM-DD HH:MM:SS'
        local y,m,d,hh,mm,ss = ts:match("(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)")
        local lastEpoch = 0
        if y then
            lastEpoch = os.time{year=tonumber(y), month=tonumber(m), day=tonumber(d), hour=tonumber(hh), min=tonumber(mm), sec=tonumber(ss)}
        end
        local now = os.time()
        if now - lastEpoch < (tonumber(gift.cooldown_seconds) or 86400) then
            canClaim = false
        end
    end

    if not canClaim then
        triggerClientEvent(player, "f1.receiveGiftResult", player, false, "لا يمكنك استلام هذه الهدية الآن")
        return
    end

    -- give rewards: update accounts.money and xp (if xp column exists)
    local addMoney = tonumber(gift.money) or 0
    local addXP = tonumber(gift.xp) or 0
    if addMoney ~= 0 or addXP ~= 0 then
        local updateQ = string.format("UPDATE accounts SET money = money + %d, xp = COALESCE(xp,0) + %d WHERE id = %d", addMoney, addXP, accid)
        dbExecSync(updateQ)
    end

    -- insert claim record
    local insertQ = string.format("INSERT INTO f1_daily_claims (account_id, gift_id) VALUES (%d, %d)", accid, gift_id)
    dbExecSync(insertQ)

    triggerClientEvent(player, "f1.receiveGiftResult", player, true, ("تم استلام الهدية: %s"):format(tostring(gift.name)), { money = addMoney, xp = addXP })
end)

-- -----------------------
-- Submit complaint
-- -----------------------
addEvent("f1.submitComplaint", true)
addEventHandler("f1.submitComplaint", resourceRoot, function(target, text)
    local player = source
    local accountRow = fetchAccountRow(player)
    if not accountRow then
        triggerClientEvent(player, "f1.complaintResult", player, false, "لا يوجد حساب مرتبط")
        return
    end
    local accid = tonumber(accountRow.id) or 0
    local t = tostring(target or "")
    local msg = tostring(text or "")
    local q = string.format("INSERT INTO f1_complaints (account_id, target, text) VALUES (%d, '%s', '%s')", accid, escapeSQL(t), escapeSQL(msg))
    dbExecSync(q)
    triggerClientEvent(player, "f1.complaintResult", player, true, "تم إرسال الشكوى بنجاح")
end)

-- -----------------------
-- Save setting (toggle)
-- -----------------------
addEvent("f1.saveSetting", true)
addEventHandler("f1.saveSetting", resourceRoot, function(key, value)
    local player = source
    local accountRow = fetchAccountRow(player)
    if not accountRow then
        triggerClientEvent(player, "f1.saveSettingResult", player, false, "لا يوجد حساب مرتبط")
        return
    end
    local accid = tonumber(accountRow.id) or 0
    key = tostring(key)
    value = tostring(value)
    -- upsert pattern (MySQL specific)
    local q = string.format("INSERT INTO f1_player_settings (account_id, setting_key, setting_value) VALUES (%d, '%s', '%s') ON DUPLICATE KEY UPDATE setting_value = '%s'",
        accid, escapeSQL(key), escapeSQL(value), escapeSQL(value))
    dbExecSync(q)
    triggerClientEvent(player, "f1.saveSettingResult", player, true, "تم حفظ الإعداد")
end)

-- -----------------------
-- Request vehicle spawn (placeholder)
-- -----------------------
-- Note: actual spawning logic depends on your server's vehicle system.
-- Here we emit an event that other resources can listen to (e.g., spawn manager).
addEvent("f1.requestVehicleSpawn", true)
addEventHandler("f1.requestVehicleSpawn", resourceRoot, function(vehicleRow)
    local player = source
    -- vehicleRow: row data passed from client (be careful trusting client)
    -- Best approach: find the vehicle in DB by id/plate and then call your spawn function.
    -- We'll try to determine an id/plate and trigger an event for other resource to handle.

    -- attempt to find unique identifier
    local plate = vehicleRow.plate or vehicleRow.plate_number or vehicleRow.plate_no or nil
    local idField = vehicleRow.id or vehicleRow.vehicle_id or nil

    if plate then
        -- trigger a general event with plate: other resource can handle spawn by plate
        triggerEvent("f1.onRequestVehicleSpawnByPlate", resourceRoot, source, plate)
        outputChatBox("[F1] تم طلب استدعاء السيارة (لوحة: "..tostring(plate)..").", player, 220,20,60)
    elseif idField then
        triggerEvent("f1.onRequestVehicleSpawnById", resourceRoot, source, idField)
        outputChatBox("[F1] تم طلب استدعاء السيارة (ID: "..tostring(idField)..").", player, 220,20,60)
    else
        outputChatBox("[F1] لا يمكن تحديد السيارة للاستدعاء. اتصل بالأدمن.", player, 255,100,100)
    end
end)

-- -----------------------
-- VIP request placeholder
-- -----------------------
addEvent("f1.requestVIP", true)
addEventHandler("f1.requestVIP", resourceRoot, function()
    local player = source
    -- You can implement payment handling here or send a ticket to admins
    -- For now we'll save a complaint-like request in complaints table
    local accountRow = fetchAccountRow(player)
    if accountRow then
        local q = string.format("INSERT INTO f1_complaints (account_id, target, text) VALUES (%d, '%s', '%s')", accountRow.id, "VIP_REQUEST", "طلب اشتراك VIP من خلال F1 Panel")
        dbExecSync(q)
        triggerClientEvent(player, "f1.complaintResult", player, true, "تم إرسال طلب الاشتراك. سيتم مراجعة الطلب من الإدارة.")
    else
        triggerClientEvent(player, "f1.complaintResult", player, false, "لا يوجد حساب مرتبط")
    end
end)

-- end of server.lua
