mysql = exports.mysql
local lockTimer = nil
chDimension = 125
chInterior = 3

-- CALL BACKS FROM CLIENT

function onEmploymentServer()
    -- إرسال التوست بدل الشات
    triggerClientEvent(source, "showJobToast", source, "Jessie Smith says: Hello, are you looking for a new job?", false)
    triggerClientEvent(source, "showJobToast", source, " *Jessie Smith hands over a list with jobs to " .. getPlayerName(source):gsub("_", " ") .. ".", false)
end

addEvent("onEmploymentServer", true)
addEventHandler("onEmploymentServer", getRootElement(), onEmploymentServer)

function givePlayerJob(jobID)
    local charname = getPlayerName(source)
    local charID = getElementData(source, "dbid")
    mysql:query_free("UPDATE `characters` SET `job`='"..tostring(jobID).."' WHERE `id`='"..mysql:escape_string(charID).."' ")
    
    -- إرسال توست بدل الشات
    local jobTitles = {
        [1] = "سائق توصيل",
        [2] = "سائق تاكسي", 
        [3] = "سائق حافلة",
        [4] = "عامل نظافة المدينة"
    }
    
    triggerClientEvent(source, "showJobToast", source, "🎉 تم تعيينك في وظيفة: " .. (jobTitles[jobID] or "وظيفة"), false)
    
    if (jobID==4) then -- CITY MAINTENANCE
        exports.global:giveItem(source, 115, "41:1:Spraycan", 2500)
        triggerClientEvent(source, "showJobToast", source, "🎨 استخدم هذا الرذاز لطلاء الجرافيتي الذي تجده", false)
        exports.anticheat:changeProtectedElementDataEx(source, "tag", 9, false)
        mysql:query_free("UPDATE characters SET tag=9 WHERE id = " .. mysql:escape_string(getElementData(source, "dbid")) )
    end
    
    -- إرسال توست التعليمات
    if jobID == 1 then
        triggerClientEvent(source, "showJobToast", source, "🚚 اذهب إلى مستودع التوصيل لبدء العمل", false)
    elseif jobID == 2 then
        triggerClientEvent(source, "showJobToast", source, "🚕 اذهب إلى موقف التاكسي واستخدم /taxilight", false)
    elseif jobID == 3 then
        triggerClientEvent(source, "showJobToast", source, "🚌 اذهب إلى محطة الحافلات واستخدم /startbus", false)
    end
    
    fetchJobInfoForOnePlayer(source)
end
addEvent("acceptJob", true)
addEventHandler("acceptJob", getRootElement(), givePlayerJob)

function fetchJobInfo()
    if not charID then
        for key, player in pairs(getElementsByType("player")) do
            fetchJobInfoForOnePlayer(player)
        end
    end
end

function fetchJobInfoForOnePlayer(thePlayer)
    local charID = getElementData(thePlayer, "dbid")
    local jobInfo = mysql:query_fetch_assoc("SELECT `job` , `jobID`, `jobLevel`, `jobProgress`, `jobTruckingRuns` FROM `characters` LEFT JOIN `jobs` ON `id` = `jobCharID` AND `job` = `jobID` WHERE `id`='" .. tostring(charID) .. "' ")
    if jobInfo then
        local job = tonumber(jobInfo["job"])
        local jobID = tonumber(jobInfo["jobID"])
        if job and job == 0 then
            setElementData(thePlayer, "job", 0, true)
            setElementData(thePlayer, "jobLevel", 0 , true)
            setElementData(thePlayer, "jobProgress", 0, true)
            setElementData(thePlayer, "job-system-trucker:truckruns", 0, true)
            return true
        end
        
        if not jobID then
            mysql:query_free("INSERT INTO `jobs` SET `jobID`='"..tostring(job).."', `jobCharID`='"..mysql:escape_string(charID).."' ")
        end
    
        setElementData(thePlayer, "job", job, true)
        setElementData(thePlayer, "jobLevel", tonumber(jobInfo["jobLevel"]) or 1, true)
        setElementData(thePlayer, "jobProgress", tonumber(jobInfo["jobProgress"]) or 0, true)
        setElementData(thePlayer, "job-system-trucker:truckruns", tonumber(jobInfo["jobTruckingRuns"]) or 0, true)
    else
        outputDebugString("[Job system] fetchJobInfoForOnePlayer / DB error")
        return false
    end
end

function printJobInfo(thePlayer)
    -- تحويل معلومات الوظيفة إلى توست
    local jobTitle = getJobTitleFromID(getElementData(thePlayer, "job")) or "عاطل عن العمل"
    local jobLevel = tonumber(getElementData(thePlayer, "jobLevel")) or 0
    local jobProgress = tonumber(getElementData(thePlayer, "jobProgress")) or 0
    
    triggerClientEvent(thePlayer, "showJobToast", thePlayer, "📊 معلومات الوظيفة", false)
    triggerClientEvent(thePlayer, "showJobToast", thePlayer, "💼 الوظيفة: " .. jobTitle, false)
    triggerClientEvent(thePlayer, "showJobToast", thePlayer, "⭐ المستوى: " .. jobLevel, false)
    triggerClientEvent(thePlayer, "showJobToast", thePlayer, "📈 التقدم: " .. jobProgress .. "%", false)
end
addCommandHandler("myjob", printJobInfo)

function quitJob(source)
    local logged = getElementData(source, "loggedin")
    if logged == 1 then
        local job = getElementData(source, "job")
        if job == 0 then
            triggerClientEvent(source, "showJobToast", source, "❌ أنت عاطل عن العمل حالياً", true)
        else
            local charID = getElementData(source, "dbid")
            mysql:query_free("UPDATE `characters` SET `job`='0' WHERE `id`='"..mysql:escape_string(charID).."' ")
            fetchJobInfoForOnePlayer(source)
            
            local jobTitles = {
                [1] = "سائق توصيل",
                [2] = "سائق تاكسي",
                [3] = "سائق حافلة", 
                [4] = "عامل نظافة المدينة"
            }
            
            triggerClientEvent(source, "showJobToast", source, "👋 ترك وظيفة: " .. (jobTitles[job] or "الوظيفة"), false)
            
            if job == 4 then
                exports.anticheat:changeProtectedElementDataEx(source, "tag", 1, false)
                mysql:query_free("UPDATE characters SET tag=1 WHERE id = " .. mysql:escape_string(charID) )
            end
            triggerClientEvent(source, "quitJob", source, job)
        end
    end
end
addCommandHandler("endjob", quitJob, false, false)
addCommandHandler("quitjob", quitJob, false, false)

-- PREVENT UNEMPLOYED PLAYER GETTING IN DRIVER SEAT OR JACKING JOB VEHICLES -- MAXIME
function startEnterVehJob(thePlayer, seat, jacked) 
    local vjob = tonumber(getElementData(source, "job")) or 0
    local job = getElementData(thePlayer, "job")
    local seat = getPedOccupiedVehicleSeat(thePlayer) or 0
    if vjob>0 and job~=vjob and seat == 0 and not (getElementData(thePlayer, "duty_admin") == 1) and not (getElementData(thePlayer, "duty_supporter") == 1) then
        if (vjob==1) then
            triggerClientEvent(thePlayer, "showJobToast", thePlayer, "❌ أنت لست موظف توصيل، إذهب إلى مركز الوظائف أولاً", true)
        elseif (vjob==2) then
            triggerClientEvent(thePlayer, "showJobToast", thePlayer, "❌ أنت لست سائق تاكسي، إذهب إلى مركز الوظائف أولاً", true)
        elseif (vjob==3) then
            triggerClientEvent(thePlayer, "showJobToast", thePlayer, "❌ أنت لست سائق حافلة، إذهب إلى مركز الوظائف أولاً", true)
        end
        if isTimer(lockTimer) then
            killTimer(lockTimer)
            lockTimer = nil
        end
        setVehicleLocked(source, true)
        lockTimer = setTimer(setVehicleLocked, 5000, 1, source, false)
    end
end
addEventHandler("onVehicleStartEnter", getRootElement(), startEnterVehJob)