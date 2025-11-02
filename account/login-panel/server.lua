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
			triggerClientEvent(client,"set_warning_text",client,"Login","Please enter your password!")
		end
	else
		triggerClientEvent(client,"set_warning_text",client,"Login","Please enter your username!")
	end
	return false
end
addEvent("onRequestLogin",true)
addEventHandler("onRequestLogin",getRootElement(),validateCredentials)

function getAccountDetails(id)
	data = false
	local qb = dbQuery(exports.mysql:getConn("mta"), "SELECT * FROM account_details WHERE account_id=?", id)
	local result_mta = dbPoll(qb, -1)
	if not result_mta then
		outputDebugString("Magic Data connection failed!")
	elseif #result_mta == 0 then
		if dbExec(exports.mysql:getConn("mta", "INSERT INTO account_details SET `account_id`=?", id)) then
			local qb = dbQuery(exports.mysql:getConn("mta"), "SELECT * FROM account_details WHERE account_id=?", id)
			local result_mta = dbPoll(qb, -1)
			if result_mta and #result_mta == 1 then
				data = result_mta[1]
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
	local encryptionRuleData, encryptionRuleQuery, accountCheckQuery, preparedQuery, accountData,newAccountHash,safeusername,safepassword = nil

	if not validateCredentials(username,password,checksave) then
		return false
	end

	--Get Encyption Rule for user.
	preparedQuery = "SELECT * FROM `accounts` WHERE `username`=?"
	dbQuery(function(qh, username, password, checksave, client)
			local result = dbPoll(qh, 0)
			if result and client then
				if #result > 0 then
					local accountData = result[1]
					-- Check if the account is banned
					if exports.bans:checkAccountBan(accountData["id"]) then
						triggerClientEvent(client,"set_warning_text",client,"Login","Account is banned. Appeal at www.owlgaming.net")
						exports.logs:dbLog("ac"..tostring(accountData["id"]), 27, "ac"..tostring(accountData["id"]), "Rejected connection from " .. getPlayerIP(client) .. " - ".. getPlayerSerial(client) .. " as account is banned.")
						return false
					end

					--Now check if passwords are matched or the account is activated, this is to prevent user with fake emails.
					triggerClientEvent(client,"set_authen_text",client,"Login","Password Accepted! Authenticating..")
					-- Check if old method
					if not string.find(accountData["password"], "$", 1, true) then -- Plain search, not regex
						local encryptionRule = accountData["salt"]
						local encryptedPW = string.lower(md5(string.lower(md5(password))..encryptionRule))

						if accountData["password"] ~= encryptedPW then
							triggerClientEvent(client,"set_warning_text",client,"Login","Password(legacy) is incorrect for account name '".. username .."'!")
							return false
						end

						triggerClientEvent(client,"set_authen_text",client,"Login","Converting Legacy Password..")
						-- Run conversions // https://docs.djangoproject.com/en/1.10/topics/auth/passwords/#increasing-the-work-factor // Since Django prefixes it's passwords with the type we do this for compatibility
						local new_pass = "bcrypt_sha256$" .. bcrypt_hashpw(sha256(password):lower(), bcrypt_gensalt(12)) -- 12 work factor // https://github.com/django/django/blob/master/django/contrib/auth/hashers.py#L404
						if not dbExec(exports.mysql:getConn("core"), "UPDATE `accounts` SET `password`=?, `salt`=NULL WHERE id=?", new_pass, accountData["id"]) then
							triggerClientEvent(client,"set_warning_text",client,"Login","Password conversion failed for account name '".. username .."'!")
							return false
						end
					else -- Else if new
						local verified = bcrypt_checkpw(sha256(password):lower(), accountData["password"]:gsub("bcrypt_sha256%$", "")) -- Take out Django's junk to verify

					end
					
					--Validation is done, fetching some more details
					triggerClientEvent(client,"set_authen_text",client,"Login","Account authenticated!")

					-- Check the account is already logged in
					local found = false
					for _, thePlayer in ipairs(exports.pool:getPoolElementsByType("player")) do
						local playerAccountID = tonumber(getElementData(thePlayer, "account:id"))
						if (playerAccountID) then
							if (playerAccountID == tonumber(accountData["id"])) and (thePlayer ~= client) then
								kickPlayer(thePlayer, thePlayer, "Someone else has logged into your account.")
								triggerClientEvent(client,"set_authen_text",client,"Login","Account is currently online. Disconnecting other user..")
								break
							end
						end
					end

					local qb = dbQuery(exports.mysql:getConn("mta"), "SELECT * FROM account_details WHERE account_id=?", accountData.id)
					local result_mta = dbPoll(qb, -1)
					if not result_mta then
						triggerClientEvent(client,"set_authen_text",client,"Login","Magic Data connection failed!")
						return
					elseif #result_mta == 0 then
						if dbExec(exports.mysql:getConn("mta"), "INSERT INTO account_details SET `account_id`=?", accountData.id) then
							local qb = dbQuery(exports.mysql:getConn("mta"), "SELECT * FROM account_details WHERE account_id=?", accountData.id)
							local result_mta = dbPoll(qb, -1)

						else

						end
					else
						accountData_mta = result_mta[1]
					end

					local accountData_mta = getAccountDetails( accountData.id )
					if not accountData_mta then
						triggerClientEvent(client,"set_authen_text",client,"Login","Magic Data connection failed!")
						return
					end

					-----------------------------------------------------------------------START THE MAGIC-----------------------------------------------------------------------------------
					triggerClientEvent(client, "items:inventory:hideinv", client)
				
					-- Start the magic
					setElementDataEx(client, "account:loggedin", true, true)
					setElementDataEx(client, "account:id", tonumber(accountData["id"]), true)
					setElementDataEx(client, "account:username", accountData["username"], true)
					setElementDataEx(client, "account:email", accountData["email"], true)
					setElementDataEx(client, "electionsvoted", accountData_mta["electionsvoted"], true)
					setElementDataEx(client, "credits", tonumber(accountData["credits"]), true)
					setElementDataEx(client, "avatar", tonumber(accountData["avatar"]), true)
					setElementData(client, "account:forumid", tonumber(accountData["forumid"]), true)
				
					--STAFF PERMISSIONS
					setElementDataEx(client, "admin_level", tonumber(accountData['admin']), true)
					setElementDataEx(client, "supporter_level", tonumber(accountData['supporter']), true)
					setElementDataEx(client, "vct_level", tonumber(accountData['vct']), true)
					setElementDataEx(client, "mapper_level", tonumber(accountData['mapper']), true)
					setElementDataEx(client, "scripter_level", tonumber(accountData['scripter']), true)
					setElementDataEx(client, "fmt_level", tonumber(accountData['fmt']), true)
				
					-- Punishment points
					setElementDataEx(client, "punishment:points", tonumber(accountData['punishpoints']), true)
					setElementDataEx(client, "punishment:date", accountData['punishdate'], true)
				
					--Admins serial whitelist
					if not exports.serialwhitelist:check(client) then
						triggerClientEvent(client,"set_warning_text",client,"Login","You're not allowed to connect to server from that PC, check UCP.")
						--REMOVE STAFF PERMISSIONS / MAXIME
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
				
					--[[
					--ADMINS
					local staffDuty = tonumber(accountData["duty_admin"]) or 0
					if exports.integration:isPlayerTrialAdmin(client) then
						setElementDataEx(client, "duty_admin", staffDuty , true)
						setElementDataEx(client, "wrn:style", tonumber(accountData["warn_style"]), true)
					end
				
					--GMs
					if exports.integration:isPlayerSupporter(client) then --GMs
						setElementDataEx(client, "duty_supporter", staffDuty , true)
					end
					]]
				
					--MAXIME / VEHICLECONSULTATIONTEAM / 18.02.14
					local vehicleConsultationTeam = exports.integration:isPlayerVehicleConsultant(client)
					setElementDataEx(client, "vehicleConsultationTeam", vehicleConsultationTeam, false)
				
					if  tonumber(accountData_mta["adminjail"]) == 1 then
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
					--[[
					local dataTable = { }
					table.insert(dataTable, { "account:characters", characterList( client ) } )
					accountCharacters[tonumber(accountData["id"])] = dataTable
					]]
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
				
					--SETTINGS / MAXIME
					loadAccountSettings(client, accountData["id"])
				
					exports.anticheat:setEld(client, "appstate", tonumber(accountData_mta["appstate"])) --Server only
					--[[
					if exports.global:isResourceRunning("interior_system") and exports.global:isResourceRunning("elevator-system") then
						triggerClientEvent(client, "screenStandBy", client, "setState", true)
					else
						goFromLoginToSelectionScreen(client)
					end
					]]

					goFromLoginToSelectionScreen(client)
				else
					triggerClientEvent(client,"set_warning_text",client,"Login","Account name '".. username .."' doesn't exist!")
				end
			else
				triggerClientEvent(client,"set_warning_text",client,"Login","Failed to connect to game server. Database error!")
				dbFree(qh)
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
			triggerClientEvent(player,"account:showRules",player, appstate)
			return false
		end
	end

	triggerClientEvent(player, "vehicle_rims", player)
	if tonumber(getElementData(player, "punishment:points") or 0) > 0 then triggerEvent("points:checkexpiration", player, player) end

	-- TUTORIAL
	local qh = dbQuery(exports.mysql:getConn("mta"), "SELECT COUNT(*) as chars FROM characters WHERE account = ?", getElementData(player,"account:id"))
	local result = dbPoll(qh, 10000)

	if (result and result[1]['chars'] < 1) then
		triggerClientEvent(player, "tutorial:run", player)
		triggerClientEvent(player, "hideLoginWindow", player)
		return false
	end

	triggerClientEvent(player, "accounts:login:attempt", player, 0 )
	triggerEvent( "social:account", player, getElementData(player,"account:id") )
	triggerClientEvent (player,"hideLoginWindow",player)

	--[[local fid = getElementData(player, 'account:forumid')
	if fid then
		exports.integration:fetchForumInfo(fid, player)
	end]]
end
addEvent("goFromLoginToSelectionScreen",true)
addEventHandler("goFromLoginToSelectionScreen",root,goFromLoginToSelectionScreen)

function playerFinishApps()
	if source then
		client = source
	end
	local index = getElementData(client, "account:id")
	triggerClientEvent(client, "accounts:login:attempt", client, 0)--, accountCharacters[index] )
	triggerEvent( "social:account", client, index )
	triggerClientEvent (client,"hideLoginWindow",client)
	triggerClientEvent (client,"apps:destroyGUIPart3",client)
	--accountCharacters[index] = nil
end
addEvent("accounts:playerFinishApps",true)
addEventHandler("accounts:playerFinishApps",getRootElement(),playerFinishApps)

--local lastClient = nil
function playerRegister(username, password, confirmPassword, email)
    -- التحقق من البيانات الأساسية
    if not username or username == "" or not password or password == "" or not confirmPassword or confirmPassword == "" or not email or email == "" then
        triggerClientEvent(client, "set_warning_text", client, "Register", "Please fill all fields!")
        return false
    end
    
    if string.len(username) < 3 then
        triggerClientEvent(client, "set_warning_text", client, "Register", "Username must be at least 3 characters!")
        return false
    end
    
    if string.find(username, ' ') then
        triggerClientEvent(client, "set_warning_text", client, "Register", "Username cannot contain spaces!")
        return false
    end
    
    if string.len(password) < 8 then
        triggerClientEvent(client, "set_warning_text", client, "Register", "Password must be at least 8 characters!")
        return false
    end
    
    if password ~= confirmPassword then
        triggerClientEvent(client, "set_warning_text", client, "Register", "Passwords do not match!")
        return false
    end
    
    -- التحقق من البريد الإلكتروني
    if not string.find(email, "@") or not string.find(email, "%.") then
        triggerClientEvent(client, "set_warning_text", client, "Register", "Please enter a valid email address!")
        return false
    end
    
    local mtaSerial = getPlayerSerial(client)
    local ipAddress = getPlayerIP(client)
    
    -- التحقق من عدم وجود المستخدم أو البريد الإلكتروني مسبقاً
    dbQuery(function(qh, username, password, email, mtaSerial, ipAddress, client)
        local result = dbPoll(qh, 0)
        if result then
            if #result > 0 then
                triggerClientEvent(client, "set_warning_text", client, "Register", "Username or email already exists!")
                return false
            end
            
            -- إنشاء الحساب الجديد - بدون حقل activated
            local encryptedPW = "bcrypt_sha256$" .. bcrypt_hashpw(sha256(password):lower(), bcrypt_gensalt(12))
            
            local query = "INSERT INTO `accounts` SET `username`=?, `password`=?, `email`=?, `registerdate`=NOW(), `ip`=?"
            local success = dbExec(exports.mysql:getConn("core"), query, username, encryptedPW, email, ipAddress)
            
            if success then
                -- جلب ID الحساب الجديد
                dbQuery(function(qh2, username, password, mtaSerial, client)
                    local result2 = dbPoll(qh2, 0)
                    if result2 and #result2 == 1 then
                        local accountId = result2[1].id
                        
                        -- إدخال بيانات الحساب الإضافية
                        dbExec(exports.mysql:getConn("mta"), "INSERT INTO account_details SET `account_id`=?, `mtaserial`=?", accountId, mtaSerial)
                        
                        -- إرسال نجاح التسجيل للكلاينت
                        triggerClientEvent(client, "accounts:register:complete", client, username, password)
                        
                        -- تسجيل الدخول التلقائي بعد ثانية
                        setTimer(function()
                            triggerClientEvent(client, "accounts:login:attempt", client, username, password, false)
                        end, 1000, 1)
                        
                    else
                        triggerClientEvent(client, "set_warning_text", client, "Register", "Account created but failed to retrieve ID")
                    end
                end, {username, password, mtaSerial, client}, exports.mysql:getConn("core"), "SELECT id FROM accounts WHERE username=?", username)
                
            else
                triggerClientEvent(client, "set_warning_text", client, "Register", "Failed to create account. Please try again.")
            end
        else
            triggerClientEvent(client, "set_warning_text", client, "Register", "Database error occurred.")
        end
    end, {username, password, email, mtaSerial, ipAddress, client}, exports.mysql:getConn("core"), "SELECT id FROM accounts WHERE username=? OR email=?", username, email)
end
addEvent("accounts:register:attempt",true)
addEventHandler("accounts:register:attempt",getRootElement(),playerRegister)