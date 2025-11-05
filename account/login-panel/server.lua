--[[
* ***********************************************************************************************************************
* Copyright (c) 2015 OwlGaming Community - All Rights Reserved
* All rights reserved. This program and the accompanying materials are private property belongs to OwlGaming Community
* Unauthorized copying of this file, via any medium is strictly prohibited
* Proprietary and confidential
* ***********************************************************************************************************************
]]

addEvent( 'account:character:select', true )
local mysql = exports.mysql
local accountCharacters = {}

-- validate credentials (now sends accounts:login:result for errors)
function validateCredentials(username,password,checksave)
	if not (username == "") then
		if not (password == "") then
			if checksave == true then
				triggerClientEvent(client,"saveLoginToXML",client,username,password)
			else
				triggerClientEvent(client,"resetSaveXML",client)
			end
			return true
		else
			triggerClientEvent(client,"accounts:login:result",client,false,"⚠️ يرجى إدخال كلمة المرور!")
		end
	else
		triggerClientEvent(client,"accounts:login:result",client,false,"⚠️ يرجى إدخال اسم المستخدم!")
	end
	return false
end
addEvent("onRequestLogin",true)
addEventHandler("onRequestLogin",getRootElement(),validateCredentials)

function getAccountDetails(id)
	local data = false
	local qb = dbQuery(exports.mysql:getConn("mta"), "SELECT * FROM account_details WHERE account_id=?", id)
	local result_mta = dbPoll(qb, -1)
	if not result_mta then
		outputDebugString("Magic Data connection failed!")
	elseif #result_mta == 0 then
		if dbExec(exports.mysql:getConn("mta"), "INSERT INTO account_details SET `account_id`=?", id) then
			local qb2 = dbQuery(exports.mysql:getConn("mta"), "SELECT * FROM account_details WHERE account_id=?", id)
			local result_mta2 = dbPoll(qb2, -1)
			if result_mta2 and #result_mta2 == 1 then
				data = result_mta2[1]
			end
		else
			outputDebugString("Magic Data creation failed!")
		end
	else
		data = result_mta[1]
	end
	return data
end

function playerLogin(username,password,checksave)
	if not validateCredentials(username,password,checksave) then
		return false
	end

	local preparedQuery = "SELECT * FROM `accounts` WHERE `username`=?"
	dbQuery(function(qh, username, password, checksave, client)
		local result = dbPoll(qh, 0)
		if not result then
			triggerClientEvent(client,"accounts:login:result",client,false,"❌ فشل الاتصال بقاعدة البيانات!")
			return
		end

		if #result > 0 then
			local accountData = result[1]

			-- Check if the account is banned
			if exports.bans:checkAccountBan(accountData["id"]) then
				triggerClientEvent(client,"accounts:login:result",client,false,"🚫 هذا الحساب محظور. Appeal at www.owlgaming.net")
				exports.logs:dbLog("ac"..tostring(accountData["id"]), 27, "ac"..tostring(accountData["id"]), "Rejected connection from " .. getPlayerIP(client) .. " - ".. getPlayerSerial(client) .. " as account is banned.")
				return false
			end

			-- Authentication feedback (client will show messages via accounts:login:result)
			-- Check password: legacy or bcrypt_sha256
			local verified = false
			if accountData["password"] and string.find(accountData["password"], "$", 1, true) then
				-- bcrypt_sha256 stored (Django style)
				verified = bcrypt_checkpw(sha256(password):lower(), accountData["password"]:gsub("bcrypt_sha256%$", ""))
			else
				-- legacy md5+salt
				local encryptionRule = accountData["salt"] or ""
				local encryptedPW = string.lower(md5(string.lower(md5(password))..encryptionRule))
				verified = (accountData["password"] == encryptedPW)
				-- if verified, convert to new hash
				if verified then
					local new_pass = "bcrypt_sha256$" .. bcrypt_hashpw(sha256(password):lower(), bcrypt_gensalt(12))
					if dbExec(exports.mysql:getConn("core"), "UPDATE `accounts` SET `password`=?, `salt`=NULL WHERE id=?", new_pass, accountData["id"]) then
						-- converted
					else
						-- conversion failed but don't block login, just report
						outputDebugString("Password conversion failed for account id ".. tostring(accountData["id"]))
					end
				end
			end

			if not verified then
				triggerClientEvent(client,"accounts:login:result",client,false,"❌ كلمة المرور غير صحيحة!")
				return false
			end

			-- Check if already logged in (kick other session)
			for _, thePlayer in ipairs(exports.pool:getPoolElementsByType("player")) do
				local playerAccountID = tonumber(getElementData(thePlayer, "account:id"))
				if (playerAccountID) then
					if (playerAccountID == tonumber(accountData["id"])) and (thePlayer ~= client) then
						kickPlayer(thePlayer, thePlayer, "Someone else has logged into your account.")
						-- inform new client briefly
						triggerClientEvent(client,"accounts:login:result",client,true,"✅ تم تسجيل الدخول! جاري فصل الجلسة القديمة..")
						break
					end
				end
			end

			-- Ensure account_details exists
			local qb = dbQuery(exports.mysql:getConn("mta"), "SELECT * FROM account_details WHERE account_id=?", accountData.id)
			local result_mta = dbPoll(qb, -1)
			if not result_mta then
				triggerClientEvent(client,"accounts:login:result",client,false,"❌ خطأ في قراءة بيانات الحساب (magic data).")
				return
			elseif #result_mta == 0 then
				dbExec(exports.mysql:getConn("mta"), "INSERT INTO account_details SET `account_id`=?", accountData.id)
			end

			local accountData_mta = getAccountDetails(accountData.id)
			if not accountData_mta then
				triggerClientEvent(client,"accounts:login:result",client,false,"❌ خطأ في بيانات الحساب (account details).")
				return
			end

			-- Start session: set element data
			triggerClientEvent(client, "items:inventory:hideinv", client)
			setElementDataEx(client, "account:loggedin", true, true)
			setElementDataEx(client, "account:id", tonumber(accountData["id"]), true)
			setElementDataEx(client, "account:username", accountData["username"], true)
			setElementDataEx(client, "account:email", accountData["email"], true)
			setElementDataEx(client, "electionsvoted", accountData_mta["electionsvoted"], true)
			setElementDataEx(client, "credits", tonumber(accountData["credits"]), true)
			setElementDataEx(client, "avatar", tonumber(accountData["avatar"]), true)
			setElementData(client, "account:forumid", tonumber(accountData["forumid"]), true)

			-- STAFF PERMISSIONS
			setElementDataEx(client, "admin_level", tonumber(accountData['admin']), true)
			setElementDataEx(client, "supporter_level", tonumber(accountData['supporter']), true)
			setElementDataEx(client, "vct_level", tonumber(accountData['vct']), true)
			setElementDataEx(client, "mapper_level", tonumber(accountData['mapper']), true)
			setElementDataEx(client, "scripter_level", tonumber(accountData['scripter']), true)
			setElementDataEx(client, "fmt_level", tonumber(accountData['fmt']), true)

			-- Punishment points
			setElementDataEx(client, "punishment:points", tonumber(accountData['punishpoints']), true)
			setElementDataEx(client, "punishment:date", accountData['punishdate'], true)

			-- Serial whitelist check
			if not exports.serialwhitelist:check(client) then
				triggerClientEvent(client,"accounts:login:result",client,false,"🚫 لا يمكنك الاتصال من هذا الجهاز. تحقق من UCP.")
				-- strip staff perms
				setElementDataEx(client, "admin_level", 0, true)
				setElementDataEx(client, "supporter_level", 0, true)
				setElementDataEx(client, "vct_level", 0, true)
				setElementDataEx(client, "mapper_level", 0, true)
				setElementDataEx(client, "scripter_level", 0, true)
				setElementDataEx(client, "fmt_level", 0, true)
				return false
			end

			exports['report']:reportLazyFix(client)

			setElementDataEx(client, "adminreports", tonumber(accountData_mta["adminreports"]), true)
			setElementDataEx(client, "adminreports_saved", tonumber(accountData_mta["adminreports_saved"]))

			if accountData['referrer'] and tonumber(accountData['referrer']) then
				setElementDataEx(client, "referrer", tonumber(accountData['referrer']), false, true)
			end

			if exports.integration:isPlayerLeadAdmin(client) then
				setElementDataEx(client, "hiddenadmin", accountData_mta["hiddenadmin"], true)
			else
				setElementDataEx(client, "hiddenadmin", 0, true)
			end

			local vehicleConsultationTeam = exports.integration:isPlayerVehicleConsultant(client)
			setElementDataEx(client, "vehicleConsultationTeam", vehicleConsultationTeam, false)

			if tonumber(accountData_mta["adminjail"]) == 1 then
				setElementDataEx(client, "adminjailed", true, true)
			else
				setElementDataEx(client, "adminjailed", false, true)
			end
			setElementDataEx(client, "jailtime", tonumber(accountData_mta["adminjail_time"]), true)
			setElementDataEx(client, "jailadmin", accountData_mta["adminjail_by"], true)
			setElementDataEx(client, "jailreason", accountData_mta["adminjail_reason"], true)

			if accountData_mta["monitored"] ~= "" then
				setElementDataEx(client, "admin:monitor", accountData_mta["monitored"], true)
			end

			exports.logs:dbLog("ac"..tostring(accountData["id"]), 27, "ac"..tostring(accountData["id"]), "Connected from "..getPlayerIP(client) .. " - "..getPlayerSerial(client) )
			mysql:query_free("UPDATE `account_details` SET `mtaserial`='" .. mysql:escape_string(getPlayerSerial(client)) .. "' WHERE `account_id`='".. mysql:escape_string(tostring(accountData["id"])) .."'")
			dbExec(exports.mysql:getConn("core"), "UPDATE `accounts` SET `ip`=? WHERE id=?", getPlayerIP(client), accountData.id)

			local sum = mysql:query_fetch_assoc("SELECT SUM(hoursPlayed) AS hours FROM `characters` WHERE account = " .. mysql:escape_string(accountData["id"]))
			if sum then
				setElementData(client, "account:hours", sum.hours)
			else
				setElementData(client, "account:hours", 0)
			end

			setElementDataEx(client, "jailreason", accountData_mta["adminjail_reason"], true)
			setElementDataEx(client, "account:lastlogin", accountData_mta["lastlogin"], true)
			setElementDataEx(client, "account:creationdate", accountData["registerdate"], true)
			setElementDataEx(client, "account:email", accountData["email"], true)

			triggerEvent("updateCharacters", client)

			exports.donators:loadAllPerks(client)
			local togNewsPerk, togNewsStatus = exports.donators:hasPlayerPerk(client, 3)
			if (togNewsPerk) then
				setElementDataEx(client, "tognews", tonumber(togNewsStatus), false, true)
			end

			-- Load settings
			loadAccountSettings(client, accountData["id"])

			exports.anticheat:setEld(client, "appstate", tonumber(accountData_mta["appstate"])) --Server only



			-- ✅ إظهار رسالة النجاح أولاً
triggerClientEvent(client, "accounts:login:result", client, true, "✅ تم تسجيل الدخول بنجاح!")

-- ⏳ وبعدها بثانيتين نخفي واجهة اللوجن فقط وننتقل لشاشة إنشاء / اختيار الشخصية
setTimer(function(player)
    if isElement(player) then
        triggerClientEvent(player, "accounts:login:success", player)
        goFromLoginToSelectionScreen(player)
    end
end, 2000, 1, client)


			
		else
			-- account not found
			triggerClientEvent(client,"accounts:login:result",client,false,"❌ اسم المستخدم أو كلمة المرور غير صحيحة!")
		end
	end, {username, password, checksave, client}, exports.mysql:getConn("core"), preparedQuery, username)
end
addEvent("accounts:login:attempt",true)
addEventHandler("accounts:login:attempt",getRootElement(),playerLogin)

function playerFinishTutorial()
	-- DONE TUTORIAL, RUN LOGIN
	triggerClientEvent(client, "accounts:login:attempt", client, 0)
    triggerEvent("social:account", client, getElementData(client, "account:id"))
end
addEvent("accounts:tutorialFinished", true)
addEventHandler("accounts:tutorialFinished", resourceRoot, playerFinishTutorial)


function goFromLoginToSelectionScreen(player)
	if source then
		player = source
	end

	-- Check if player passed application
	local appstate = tonumber(getElementData(player, "appstate")) or 0
	if appstate < 3 then
		if exports.integration:isPlayerTrialAdmin(player) or exports.integration:isPlayerSupporter(player) then
			dbExec( exports.mysql:getConn('mta'), "UPDATE account_details SET appstate=3, appreason=NULL WHERE account_id=? ", getElementData(player,"account:id") )
		else
			-- If account hasn't passed application, show rules (client should handle)
			triggerClientEvent(player,"account:showRules",player, appstate)
			return false
		end
	end

	triggerClientEvent(player, "vehicle_rims", player)
	if tonumber(getElementData(player, "punishment:points") or 0) > 0 then triggerEvent("points:checkexpiration", player, player) end

	-- TUTORIAL: if no characters, run tutorial/creation
	local qh = dbQuery(exports.mysql:getConn("mta"), "SELECT COUNT(*) as chars FROM characters WHERE account = ?", getElementData(player,"account:id"))
	local result = dbPoll(qh, 10000)

	if (result and result[1]['chars'] < 1) then
		-- open tutorial/character creation on client
		triggerClientEvent(player, "tutorial:run", player)
		-- hide only login UI (client listens to accounts:login:success to show creation UI; keep hide as a fallback)
		triggerClientEvent(player, "hideLoginPanel", player)
		return false
	end

	-- If player has characters, continue normal flow
	triggerClientEvent(player, "accounts:login:attempt", player, 0 )
	triggerEvent( "social:account", player, getElementData(player,"account:id") )
	-- hide login UI on client (client will show selection screen)
	triggerClientEvent (player,"hideLoginPanel",player)
end
addEvent("goFromLoginToSelectionScreen",true)
addEventHandler("goFromLoginToSelectionScreen",root,goFromLoginToSelectionScreen)

function playerFinishApps()
	if source then
		client = source
	end
	local index = getElementData(client, "account:id")
	triggerClientEvent(client, "accounts:login:attempt", client, 0)
	triggerEvent( "social:account", client, index )
	triggerClientEvent (client,"hideLoginPanel",client)
	triggerClientEvent (client,"apps:destroyGUIPart3",client)
end
addEvent("accounts:playerFinishApps",true)
addEventHandler("accounts:playerFinishApps",getRootElement(),playerFinishApps)

-- Registration (send accounts:register:result for client feedback)
function playerRegister(username, password, confirmPassword, email)
    if not username or username == "" or not password or password == "" or not confirmPassword or confirmPassword == "" or not email or email == "" then
        triggerClientEvent(client, "accounts:register:result", client, false, "⚠️ يرجى ملء جميع الحقول!")
        return false
    end

    if string.len(username) < 3 then
        triggerClientEvent(client, "accounts:register:result", client, false, "⚠️ اسم المستخدم يجب أن يكون 3 أحرف على الأقل!")
        return false
    end

    if string.find(username, ' ') then
        triggerClientEvent(client, "accounts:register:result", client, false, "⚠️ لا يمكن أن يحتوي الاسم على مسافات!")
        return false
    end

    if string.len(password) < 8 then
        triggerClientEvent(client, "accounts:register:result", client, false, "⚠️ كلمة المرور يجب أن تكون 8 أحرف على الأقل!")
        return false
    end

    if password ~= confirmPassword then
        triggerClientEvent(client, "accounts:register:result", client, false, "❌ كلمات المرور غير متطابقة!")
        return false
    end

    if not string.find(email, "@") or not string.find(email, "%.") then
        triggerClientEvent(client, "accounts:register:result", client, false, "⚠️ يرجى إدخال بريد إلكتروني صحيح!")
        return false
    end

    local mtaSerial = getPlayerSerial(client)
    local ipAddress = getPlayerIP(client)

    dbQuery(function(qh, username, password, email, mtaSerial, ipAddress, client)
        local result = dbPoll(qh, 0)
        if result then
            if #result > 0 then
                triggerClientEvent(client, "accounts:register:result", client, false, "⚠️ اسم المستخدم أو البريد الإلكتروني موجود مسبقًا!")
                return false
            end

            local encryptedPW = "bcrypt_sha256$" .. bcrypt_hashpw(sha256(password):lower(), bcrypt_gensalt(12))

            local query = "INSERT INTO `accounts` SET `username`=?, `password`=?, `email`=?, `registerdate`=NOW(), `ip`=?"
            local success = dbExec(exports.mysql:getConn("core"), query, username, encryptedPW, email, ipAddress)

            if success then
                -- fetch inserted id
                dbQuery(function(qh2, username, password, mtaSerial, client)
                    local result2 = dbPoll(qh2, 0)
                    if result2 and #result2 == 1 then
                        local accountId = result2[1].id
                        dbExec(exports.mysql:getConn("mta"), "INSERT INTO account_details SET `account_id`=?, `mtaserial`=?", accountId, mtaSerial)

                        triggerClientEvent(client, "accounts:register:result", client, true, "✅ تم إنشاء الحساب بنجاح!")
                        triggerClientEvent(client, "accounts:register:complete", client, username, password)

                        -- auto-login after short delay
                        setTimer(function()
                            triggerClientEvent(client, "accounts:login:attempt", client, username, password, false)
                        end, 1000, 1)
						
                    else
                        triggerClientEvent(client, "accounts:register:result", client, false, "⚠️ تم إنشاء الحساب لكن فشل جلب الـ ID.")
                    end
                end, {username, password, mtaSerial, client}, exports.mysql:getConn("core"), "SELECT id FROM accounts WHERE username=?", username)
            else
                triggerClientEvent(client, "accounts:register:result", client, false, "❌ حدث خطأ أثناء إنشاء الحساب!")
            end
        else
            triggerClientEvent(client, "accounts:register:result", client, false, "❌ خطأ في قاعدة البيانات.")
        end
    end, {username, password, email, mtaSerial, ipAddress, client}, exports.mysql:getConn("core"), "SELECT id FROM accounts WHERE username=? OR email=?", username, email)
end
addEvent("accounts:register:attempt",true)
addEventHandler("accounts:register:attempt",getRootElement(),playerRegister)
