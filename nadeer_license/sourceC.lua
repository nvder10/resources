local screenW, screenH = guiGetScreenSize()
local dxfont_bold = dxCreateFont("Tajawal-Bold.ttf", 12) or "default-bold"
local dxfont_black = dxCreateFont("Tajawal-Black.ttf", 14) or "default-bold"
local dxfont_small = dxCreateFont("Tajawal-Bold.ttf", 10) or "default"

-- ========== نظام التوست ==========
local toastSystem = {
    visible = false,
    message = "",
    startTime = 0,
    isError = false,
    progress = 100,
    duration = 4000
}

local toastMessages = {}

function showToast(message, isError)
    table.insert(toastMessages, {
        text = message,
        startTime = getTickCount(),
        alpha = 0,
        isError = isError or false
    })
end

function drawToastMessages()
    local currentTime = getTickCount()
    local yOffset = screenH * 0.1
    
    for i = #toastMessages, 1, -1 do
        local toast = toastMessages[i]
        local elapsed = currentTime - toast.startTime
        
        if elapsed < toastSystem.duration then
            local progress = elapsed / toastSystem.duration
            local alpha = 255
            
            -- حساب الشفافية
            if progress < 0.2 then
                alpha = (progress / 0.2) * 255
            elseif progress > 0.8 then
                alpha = ((1 - progress) / 0.2) * 255
            end
            
            local width = dxGetTextWidth(toast.text, 1, dxfont_small) + (30 * 2)
            local height = 25
            local x = (screenW - width) / 2
            local y = yOffset
            
            -- خلفية التوست
            dxDrawRectangle(x, y, width, height, tocolor(3, 20, 23, alpha))
            
            -- الخط العلوي المتحرك
            local lineProgress = 1 - progress
            local lineWidth = width * lineProgress
            dxDrawRectangle(x, y, lineWidth, 2, tocolor(52, 171, 173, alpha))
            
            -- النص
            local textColor = toast.isError and tocolor(255, 100, 100, alpha) 
                              or tocolor(255, 255, 255, alpha)
            dxDrawText(toast.text, x, y, x + width, y + height, 
                      textColor, 1, dxfont_small, "center", "center")
            
            yOffset = y + height + 10
        else
            table.remove(toastMessages, i)
        end
    end
end

-- ========== نظام الرخص ==========
local isLicenseMenuOpen = false
local selectedLicense = 0

local currentTestData = {
    active = false,
    questions = {},
    currentQuestion = 1,
    correctAnswers = 0,
    licenseType = nil,
    licenseId = nil
}

local loadedTextures = {}

local colors = {
    background = {3, 20, 23},
    primary = {52, 171, 173},
    text = {255, 255, 255},
    secondary = {10, 40, 45},
    error = {255, 100, 100},
    success = {100, 255, 100},
    dark = {50, 50, 50}
}

local backgroundColor = colors.background
local primaryColor = colors.primary
local textColor = colors.text
local secondaryColor = colors.secondary

-- أنواع الرخص
local licenseTypes = {
    [1] = { 
        name = "رخصة قيادة السيارات", 
        icon = "licensecar.png", 
        price = 5000,
        description = "رخصة قيادة المركبات والسيارات الخاصة\nالمتطلبات: عمر 16 سنة فما فوق",
        testType = "car",
        itemId = 133
    },
    [2] = { 
        name = "رخصة قيادة الدراجات النارية", 
        icon = "licensebike.png", 
        price = 3500,
        description = "رخصة قيادة الدراجات النارية\nالمتطلبات: عمر 16 سنة فما فوق", 
        testType = "bike",
        itemId = 153
    },
    [3] = { 
        name = "رخصة صيد الأسماك", 
        icon = "licensefisher.png", 
        price = 2000,
        description = "رخصة مزاولة مهنة الصيد\nالمتطلبات: لا يوجد متطلبات عمرية",
        testType = "fishing",
        itemId = 154
    }
}

-- نظام الأسئلة (مبسط بنسبة نجاح 50%)
local theoryQuestions = {
    car = {
        {
            question = "في أي جانب من الطريق يجب أن تقود؟",
            answers = {"اليسار", "اليمين", "أي منهما"},
            correct = 2
        },
        {
            question = "ماذا تفعل عند الإشارة الحمراء؟",
            answers = {"تتوقف تماماً", "تستمر", "تستمر إذا لم يكن هناك أحد"},
            correct = 1
        },
        {
            question = "ما هو الحد الأقصى للسرعة داخل المدينة؟",
            answers = {"60 كم/س", "80 كم/س", "100 كم/س"},
            correct = 2
        },
        {
            question = "متى يجب استخدام الإشارات؟",
            answers = {"عند الانعطاف فقط", "عند تغيير المسار أو الانعطاف", "لا داعي لاستخدامها"},
            correct = 2
        },
        {
            question = "ما المسافة الآمنة بين السيارات؟",
            answers = {"5 أمتار", "10 أمتار", "مسافة كافية للتوقف الآمن"},
            correct = 3
        },
        {
            question = "ماذا تفعل عند رؤية حافلة مدرسية تتوقف؟",
            answers = {"تتجاوزها", "تتوقف", "تسرع"},
            correct = 2
        },
        {
            question = "ما هو عمر الحصول على رخصة القيادة؟",
            answers = {"16 سنة", "18 سنة", "21 سنة"},
            correct = 1
        }
    },
    
    bike = {
        {
            question = "في أي جانب من الطريق يجب أن تركب؟",
            answers = {"اليسار", "اليمين", "أي منهما"},
            correct = 2
        },
        {
            question = "ما فائدة ارتداء الخوذة؟",
            answers = {"للمظهر", "للحماية", "لجذب الانتباه"},
            correct = 2
        },
        {
            question = "متى يجب استخدام الإشارات؟",
            answers = {"دائماً", "أحياناً", "لا داعي"},
            correct = 1
        },
        {
            question = "ما هي النقاط العمياء للشاحنات؟",
            answers = {"الجانب الأيمن فقط", "الجانب الأيسر فقط", "كلا الجانبين والخلف"},
            correct = 3
        },
        {
            question = "كيف تتجنب الحوادث؟",
            answers = {"بالسرعة", "بالحذر والانتباه", "بالصوت العالي"},
            correct = 2
        },
        {
            question = "ماذا تفعل عند المنعطفات？",
            answers = {"تسرع", "تبطئ", "تستمر بنفس السرعة"},
            correct = 2
        },
        {
            question = "ما هو الحد الأدنى لسن رخصة الدراجة？",
            answers = {"14 سنة", "16 سنة", "18 سنة"},
            correct = 2
        }
    }
}

-- ========== مسارات الاختبار العملي ==========
testRoute = {
    { 1092.20703125, -1759.1591796875, 13.023070335388 },	-- 1. Start Test 
    { 1104.1878662109, -1743.1345214844, 13.043541908264 }, 	-- 2. 
    { 1172.9915771484, -1749.4460449219, 12.997159957886 }, 	-- 3. 
    { 1173.3139648438, -1809.0072021484, 13.004528045654 }, 	-- 4. 
    { 1165.9608154297, -1849.8544921875, 12.999576568604 },	-- 5. 
    { 1117.17578125, -1849.7673339844, 12.98407459259 },	-- 6. 
    { 1063.5953369141, -1842.3752441406, 13.038996696472 },	-- 7. 
    { 1035.9447021484, -1793.5300292969, 13.292297363281 }, -- 8.
    { 1057.875, -1777.5161132812, 13.176018714905 }, 	-- 9.
    { 1097.658203125, -1772.037109375, 12.948340415955 }, 	-- 10. End Test
}

testBikeRoute = {
    { 1092.20703125, -1759.1591796875, 13.023070335388 },	-- 1. Start Test 
    { 1104.1878662109, -1743.1345214844, 13.043541908264 }, 	-- 2. 
    { 1172.9915771484, -1749.4460449219, 12.997159957886 }, 	-- 3. 
    { 1173.3139648438, -1809.0072021484, 13.004528045654 }, 	-- 4. 
    { 1165.9608154297, -1849.8544921875, 12.999576568604 },	-- 5. 
    { 1117.17578125, -1849.7673339844, 12.98407459259 },	-- 6. 
    { 1063.5953369141, -1842.3752441406, 13.038996696472 },	-- 7. 
    { 1035.9447021484, -1793.5300292969, 13.292297363281 }, -- 8.
    { 1057.875, -1777.5161132812, 13.176018714905 }, 	-- 9.
    { 1097.658203125, -1772.037109375, 12.948340415955 }, 	-- 10. End Test
}

-- أنواع المركبات المسموحة للاختبار
testVehicle = { [410]=true } -- Mananas للسيارات
testBike = { [468]=true } -- Sanchez للدراجات

-- ========== متغيرات الاختبار العملي ==========
local practicalTestData = {
    active = false,
    licenseType = nil,
    vehicleId = nil,
    currentMarker = 1,
    blip = nil,
    marker = nil,
    exitTimer = nil,
    exitTimeLeft = 20
}

-- ========== نظام العداد الزمني للخروج من المركبة ==========
function startExitTimer()
    if practicalTestData.exitTimer then
        killTimer(practicalTestData.exitTimer)
    end
    
    practicalTestData.exitTimeLeft = 20
    practicalTestData.exitTimer = setTimer(function()
        practicalTestData.exitTimeLeft = practicalTestData.exitTimeLeft - 1
        
        if practicalTestData.exitTimeLeft <= 0 then
            endTestDueToExit()
        end
    end, 1000, 20)
end

function stopExitTimer()
    if practicalTestData.exitTimer then
        killTimer(practicalTestData.exitTimer)
        practicalTestData.exitTimer = nil
    end
end

function endTestDueToExit()
    if practicalTestData.active then
        showToast("❌ فشلت في الاختبار - تجاوزت الوقت المسموح للعودة للمركبة", true)
        
        -- إخفاء المركبة
        local vehicle = getPedOccupiedVehicle(localPlayer)
        if not vehicle then
            -- البحث عن مركبة الاختبار بالقرب من اللاعب
            local vehicles = getElementsByType("vehicle")
            for _, v in ipairs(vehicles) do
                if getElementData(v, "dbid") == practicalTestData.vehicleId then
                    vehicle = v
                    break
                end
            end
        end
        
        if vehicle then
            triggerServerEvent("removeTestVehicle", localPlayer, vehicle)
        end
        
        -- إنهاء الاختبار
        if practicalTestData.licenseType == "car" then
            endCarTest(false)
        else
            endBikeTest(false)
        end
    end
end

-- ========== نظام الاختبار العملي ==========
function initiateDrivingTest()
    showToast("جاري بدء الاختبار العملي للسيارة...")
    
    practicalTestData.active = true
    practicalTestData.licenseType = "car"
    practicalTestData.currentMarker = 1
    
    local x, y, z = testRoute[1][1], testRoute[1][2], testRoute[1][3]
    practicalTestData.blip = createBlip(x, y, z, 0, 2, 0, 255, 0, 255)
    practicalTestData.marker = createMarker(x, y, z, "cylinder", 2.5, 0, 255, 0, 150)
    
    addEventHandler("onClientMarkerHit", practicalTestData.marker, startCarTest)
    
    outputChatBox("#FF9933You are now ready to take your practical driving examination. Collect a DoL test car and begin the route.", 255, 194, 14, true)
end

function initiateBikeTest()
    showToast("جاري بدء الاختبار العملي للدراجة...")
    
    practicalTestData.active = true
    practicalTestData.licenseType = "bike"
    practicalTestData.currentMarker = 1
    
    local x, y, z = testBikeRoute[1][1], testBikeRoute[1][2], testBikeRoute[1][3]
    practicalTestData.blip = createBlip(x, y, z, 0, 2, 0, 255, 0, 255)
    practicalTestData.marker = createMarker(x, y, z, "cylinder", 2.5, 0, 255, 0, 150)
    
    addEventHandler("onClientMarkerHit", practicalTestData.marker, startBikeTest)
    
    outputChatBox("#FF9933You are now ready to take your practical driving examination. Collect a DoL test bike and begin the route.", 255, 194, 14, true)
end

function startCarTest(element)
    if element == localPlayer then
        local vehicle = getPedOccupiedVehicle(localPlayer)
        if not vehicle or not testVehicle[getElementModel(vehicle)] then
            showToast("❌ يجب أن تكون في مركبة اختبار صالحة", true)
            return
        end
        
        destroyElement(practicalTestData.blip)
        destroyElement(practicalTestData.marker)
        
        practicalTestData.vehicleId = getElementData(vehicle, "dbid")
        practicalTestData.currentMarker = 2
        
        local x1, y1, z1 = testRoute[2][1], testRoute[2][2], testRoute[2][3]
        practicalTestData.blip = createBlip(x1, y1, z1, 0, 2, 52, 171, 173, 255)
        practicalTestData.marker = createMarker(x1, y1, z1, "cylinder", 2.5, 52, 171, 173, 150)
        
        addEventHandler("onClientMarkerHit", practicalTestData.marker, updateCarCheckpoints)
        
        showToast("ابدأ القيادة في المسار المحدد")
    end
end

function startBikeTest(element)
    if element == localPlayer then
        local vehicle = getPedOccupiedVehicle(localPlayer)
        if not vehicle or not testBike[getElementModel(vehicle)] then
            showToast("❌ يجب أن تكون في دراجة اختبار صالحة", true)
            return
        end
        
        destroyElement(practicalTestData.blip)
        destroyElement(practicalTestData.marker)
        
        practicalTestData.vehicleId = getElementData(vehicle, "dbid")
        practicalTestData.currentMarker = 2
        
        local x1, y1, z1 = testBikeRoute[2][1], testBikeRoute[2][2], testBikeRoute[2][3]
        practicalTestData.blip = createBlip(x1, y1, z1, 0, 2, 52, 171, 173, 255)
        practicalTestData.marker = createMarker(x1, y1, z1, "cylinder", 2.5, 52, 171, 173, 150)
        
        addEventHandler("onClientMarkerHit", practicalTestData.marker, updateBikeCheckpoints)
        
        showToast("ابدأ القيادة في المسار المحدد")
    end
end

function updateCarCheckpoints(element)
    if element == localPlayer then
        local vehicle = getPedOccupiedVehicle(localPlayer)
        if not vehicle or not testVehicle[getElementModel(vehicle)] then
            showToast("❌ يجب أن تكون في مركبة اختبار صالحة", true)
            return
        end
        
        if getElementData(vehicle, "dbid") ~= practicalTestData.vehicleId then
            showToast("❌ يجب استخدام نفس المركبة التي بدأت بها الاختبار", true)
            return
        end
        
        destroyElement(practicalTestData.blip)
        destroyElement(practicalTestData.marker)
        
        local nextMarker = practicalTestData.currentMarker + 1
        practicalTestData.currentMarker = nextMarker
        
        if nextMarker > #testRoute then
            endCarTest(true)
            return
        end
        
        if nextMarker == #testRoute then
            showToast("🅿️ أوقف المركبة في منطقة الانتظار")
        end
        
        local x, y, z = testRoute[nextMarker][1], testRoute[nextMarker][2], testRoute[nextMarker][3]
        practicalTestData.blip = createBlip(x, y, z, 0, 2, 52, 171, 173, 255)
        practicalTestData.marker = createMarker(x, y, z, "cylinder", 2.5, 52, 171, 173, 150)
        
        addEventHandler("onClientMarkerHit", practicalTestData.marker, updateCarCheckpoints)
    end
end

function updateBikeCheckpoints(element)
    if element == localPlayer then
        local vehicle = getPedOccupiedVehicle(localPlayer)
        if not vehicle or not testBike[getElementModel(vehicle)] then
            showToast("❌ يجب أن تكون في دراجة اختبار صالحة", true)
            return
        end
        
        if getElementData(vehicle, "dbid") ~= practicalTestData.vehicleId then
            showToast("❌ يجب استخدام نفس الدراجة التي بدأت بها الاختبار", true)
            return
        end
        
        destroyElement(practicalTestData.blip)
        destroyElement(practicalTestData.marker)
        
        local nextMarker = practicalTestData.currentMarker + 1
        practicalTestData.currentMarker = nextMarker
        
        if nextMarker > #testBikeRoute then
            endBikeTest(true)
            return
        end
        
        if nextMarker == #testBikeRoute then
            showToast("🅿️ أوقف الدراجة في منطقة الانتظار")
        end
        
        local x, y, z = testBikeRoute[nextMarker][1], testBikeRoute[nextMarker][2], testBikeRoute[nextMarker][3]
        practicalTestData.blip = createBlip(x, y, z, 0, 2, 52, 171, 173, 255)
        practicalTestData.marker = createMarker(x, y, z, "cylinder", 2.5, 52, 171, 173, 150)
        
        addEventHandler("onClientMarkerHit", practicalTestData.marker, updateBikeCheckpoints)
    end
end

function endCarTest(success)
    if practicalTestData.active then
        local vehicle = getPedOccupiedVehicle(localPlayer)
        
        if practicalTestData.blip then destroyElement(practicalTestData.blip) end
        if practicalTestData.marker then destroyElement(practicalTestData.marker) end
        stopExitTimer()
        
        practicalTestData.active = false
        
        if success and vehicle then
            local vehicleHealth = getElementHealth(vehicle)
            if vehicleHealth >= 800 then
                showToast("نجحت في الاختبار العملي للسيارة!")
                triggerServerEvent("acceptCarLicense", localPlayer, false)
                -- إخفاء المركبة بعد النجاح
                triggerServerEvent("removeTestVehicle", localPlayer, vehicle)
            else
                showToast("❌ فشلت في الاختبار بسبب تلف المركبة", true)
                triggerServerEvent("removeTestVehicle", localPlayer, vehicle)
            end
        else
            showToast("❌ فشلت في الاختبار العملي", true)
            if vehicle then
                triggerServerEvent("removeTestVehicle", localPlayer, vehicle)
            end
        end
    end
end

function endBikeTest(success)
    if practicalTestData.active then
        local vehicle = getPedOccupiedVehicle(localPlayer)
        
        if practicalTestData.blip then destroyElement(practicalTestData.blip) end
        if practicalTestData.marker then destroyElement(practicalTestData.marker) end
        stopExitTimer()
        
        practicalTestData.active = false
        
        if success and vehicle then
            local vehicleHealth = getElementHealth(vehicle)
            if vehicleHealth >= 800 then
                showToast("نجحت في الاختبار العملي للدراجة!")
                triggerServerEvent("acceptBikeLicense", localPlayer, false)
                -- إخفاء المركبة بعد النجاح
                triggerServerEvent("removeTestVehicle", localPlayer, vehicle)
            else
                showToast("❌ فشلت في الاختبار بسبب تلف الدراجة", true)
                triggerServerEvent("removeTestVehicle", localPlayer, vehicle)
            end
        else
            showToast("❌ فشلت في الاختبار العملي", true)
            if vehicle then
                triggerServerEvent("removeTestVehicle", localPlayer, vehicle)
            end
        end
    end
end

-- تنظيف الاختبار إذا خرج اللاعب من المركبة
addEventHandler("onClientPlayerVehicleExit", localPlayer, function(vehicle)
    if practicalTestData.active then
        if practicalTestData.licenseType == "car" and testVehicle[getElementModel(vehicle)] then
            startExitTimer()
        elseif practicalTestData.licenseType == "bike" and testBike[getElementModel(vehicle)] then
            startExitTimer()
        end
    end
end)

-- إعادة تشغيل العداد عند دخول المركبة
addEventHandler("onClientPlayerVehicleEnter", localPlayer, function(vehicle)
    if practicalTestData.active then
        if (practicalTestData.licenseType == "car" and testVehicle[getElementModel(vehicle)]) or
           (practicalTestData.licenseType == "bike" and testBike[getElementModel(vehicle)]) then
            stopExitTimer()
            showToast("✅ عدت للمركبة - استمر في الاختبار")
        end
    end
end)

-- ========== تحميل الـ Textures ==========
function loadTextures()
    for i, license in ipairs(licenseTypes) do
        if fileExists(license.icon) then
            loadedTextures[i] = dxCreateTexture(license.icon)
        else
            loadedTextures[i] = nil
            outputDebugString("❌ ملف الصورة غير موجود: " .. license.icon)
        end
    end
end

-- ========== الواجهة الرئيسية ==========
addEventHandler("onClientRender", root, function()
    -- رسم التوستات أولاً
    drawToastMessages()
    
    -- رسم عداد الخروج من المركبة
    if practicalTestData.active and practicalTestData.exitTimer and practicalTestData.exitTimeLeft > 0 then
        local timerWidth, timerHeight = 200, 40
        local timerX = (screenW - timerWidth) / 2
        local timerY = screenH * 0.25
        
        -- خلفية العداد
        dxDrawRectangle(timerX, timerY, timerWidth, timerHeight, tocolor(0, 0, 0, 180))
        dxDrawRectangle(timerX, timerY, timerWidth, 3, tocolor(255, 100, 100, 255))
        
        -- النص
        local timeColor = practicalTestData.exitTimeLeft <= 5 and tocolor(255, 100, 100, 255) or tocolor(255, 255, 255, 255)
        dxDrawText("⏰ العودة للمركبة: " .. practicalTestData.exitTimeLeft .. " ثانية", 
                  timerX, timerY, timerX + timerWidth, timerY + timerHeight, 
                  timeColor, 1, dxfont_bold, "center", "center")
    end
    
    -- رسم واجهة الرخص
    if isLicenseMenuOpen then
        drawLicenseSelectionWindow()
    end
    
    -- رسم الاختبار النظري
    if currentTestData.active then
        drawTheoryTest()
    end
    
    -- رسم رسالة التفاعل مع الـ Ped
    if getElementData(localPlayer, "loggedin") ~= 1 then return end

    local nearLicenseNPC = false
    local peds = getElementsByType("ped", root, true)

    for k, element in ipairs(peds) do
        local npcType = getElementData(element, "npc.type")
        if not npcType then
            npcType = getElementData(element, "rpp.npc.type")
        end

        if npcType == "dmv.license" then
            local px, py, pz = getElementPosition(element)
            local x, y, z = getElementPosition(localPlayer)

            if getDistanceBetweenPoints3D(px, py, pz, x, y, z) <= 3 then
                nearLicenseNPC = true
                local text = isLicenseMenuOpen and "[E] لإغلاق القائمة" or "[E] لاستخراج رخصة قيادة"
                
                local textWidth = dxGetTextWidth(text, 1, dxfont_small)
                local startX = screenW/2 - (textWidth/2) - 30
                local startY = screenH - 130
                local width = textWidth + (30 * 2)
                local height = 25
                
                -- خلفية الرسالة
                dxDrawRectangle(startX, startY, width, height, tocolor(3, 20, 23, 200))
                
                -- الخط العلوي
                dxDrawRectangle(startX, startY, width, 2, tocolor(52, 171, 173, 255))
                
                -- النص
                dxDrawText(text, startX, startY, startX + width, startY + height, 
                          tocolor(255, 255, 255, 255), 1, dxfont_small, "center", "center")
                break
            end
        end
    end
end)

function drawLicenseSelectionWindow()
    local width, height = 550, 500
    local x = (screenW - width) / 2
    local y = (screenH - height) / 2
    
    -- الخلفية الرئيسية
    dxDrawRectangle(x, y, width, height, tocolor(backgroundColor[1], backgroundColor[2], backgroundColor[3], 255))
    
    -- الحدود
    dxDrawRectangle(x, y, width, 3, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255)) -- علوي
    dxDrawRectangle(x, y + height - 3, width, 3, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255)) -- سفلي
    dxDrawRectangle(x, y, 3, height, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255)) -- أيسر
    dxDrawRectangle(x + width - 3, y, 3, height, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255)) -- أيمن
    
    -- العنوان الرئيسي
    dxDrawText("مسؤول رخص القيادة", x, y + 20, x + width, y + 50, 
              tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255), 1.3, dxfont_black, "center", "center")
    
    -- الخط تحت العنوان
    dxDrawRectangle(x + 50, y + 52, width - 100, 1, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    
    -- مساحة الرخص
    local licenseHeight = 100
    local startY = y + 80
    
    for i = 1, 3 do
        local licenseY = startY + ((i-1) * (licenseHeight + 15))
        local isSelected = (selectedLicense == i)
        
        -- خلفية الرخصة
        local bgColor = isSelected and tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 40) 
                              or tocolor(secondaryColor[1], secondaryColor[2], secondaryColor[3], 255)
        dxDrawRectangle(x + 25, licenseY, width - 50, licenseHeight, bgColor)
        
        -- الخط العلوي لكل رخصة
        dxDrawRectangle(x + 25, licenseY, width - 50, 2, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
        
        -- الخط السفلي لكل رخصة  
        dxDrawRectangle(x + 25, licenseY + licenseHeight - 2, width - 50, 2, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
        
        -- الأيقونة
        local iconX, iconY = x + 35, licenseY + 20
        if loadedTextures[i] then
            dxDrawImage(iconX, iconY, 60, 60, loadedTextures[i])
        else
            dxDrawRectangle(iconX, iconY, 60, 60, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
            dxDrawText("رخصة", iconX, iconY, iconX + 60, iconY + 60, tocolor(textColor[1], textColor[2], textColor[3], 255), 1, dxfont_small, "center", "center")
        end
        
        -- اسم الرخصة
        dxDrawText(licenseTypes[i].name, x + 110, licenseY + 15, x + width - 30, licenseY + 35, 
                  tocolor(textColor[1], textColor[2], textColor[3], 255), 1.1, dxfont_bold, "left", "center")
        
        -- السعر
        dxDrawText("السعر: $" .. licenseTypes[i].price, x + 110, licenseY + 35, x + width - 30, licenseY + 55, 
                  tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255), 1, dxfont_small, "left", "center")
        
        -- الوصف
        dxDrawText(licenseTypes[i].description, x + 110, licenseY + 55, x + width - 30, licenseY + 90, 
                  tocolor(200, 200, 200, 255), 0.9, dxfont_small, "left", "top")
    end
    
    -- الأزرار
    local buttonWidth = (width - 70) / 2
    local buttonHeight = 40
    local buttonY = y + height - 60
    
    -- زر البدء
    local startHover = isMouseInPosition(x + 25, buttonY, buttonWidth, buttonHeight)
    local startColor = startHover and tocolor(52, 171, 173, 255) or tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255)
    dxDrawRectangle(x + 25, buttonY, buttonWidth, buttonHeight, startColor)
    dxDrawText("بدء الإجراءات", x + 25, buttonY, x + 25 + buttonWidth, buttonY + buttonHeight, 
              tocolor(textColor[1], textColor[2], textColor[3], 255), 1, dxfont_bold, "center", "center")
    
    -- زر الإلغاء
    local cancelHover = isMouseInPosition(x + 35 + buttonWidth, buttonY, buttonWidth, buttonHeight)
    local cancelColor = cancelHover and tocolor(60, 60, 60, 255) or tocolor(80, 80, 80, 255)
    dxDrawRectangle(x + 35 + buttonWidth, buttonY, buttonWidth, buttonHeight, cancelColor)
    dxDrawText("إلغاء", x + 35 + buttonWidth, buttonY, x + 35 + buttonWidth + buttonWidth, buttonY + buttonHeight, 
              tocolor(textColor[1], textColor[2], textColor[3], 255), 1, dxfont_bold, "center", "center")
    
    -- رسالة التوجيه
    dxDrawText("اختر نوع الرخصة المناسب ثم اضغط على 'بدء الإجراءات'", x, buttonY - 30, x + width, buttonY, 
              tocolor(150, 150, 150, 255), 0.9, dxfont_small, "center", "center")
end

-- ========== واجهة الاختبار النظري ==========
function drawTheoryTest()
    if not currentTestData.active then return end
    
    local width, height = 600, 400
    local x = (screenW - width) / 2
    local y = (screenH - height) / 2
    
    -- خلفية الاختبار
    dxDrawRectangle(x, y, width, height, tocolor(backgroundColor[1], backgroundColor[2], backgroundColor[3], 255))
    dxDrawRectangle(x, y, width, 3, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    
    -- العنوان
    dxDrawText("الاختبار النظري - سؤال " .. currentTestData.currentQuestion .. " من 7", 
              x, y + 15, x + width, y + 45, tocolor(textColor[1], textColor[2], textColor[3], 255), 1.1, dxfont_bold, "center", "center")
    
    -- الخط تحت العنوان
    dxDrawRectangle(x + 50, y + 47, width - 100, 1, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    
    local currentQ = currentTestData.questions[currentTestData.currentQuestion]
    
    -- السؤال
    dxDrawText(currentQ.question, x + 30, y + 70, x + width - 30, y + 140, 
              tocolor(textColor[1], textColor[2], textColor[3], 255), 1, dxfont_bold, "center", "top", true, true)
    
    -- الإجابات
    local answerHeight = 45
    local startY = y + 150
    
    for i, answer in ipairs(currentQ.answers) do
        local answerY = startY + ((i-1) * (answerHeight + 10))
        local isHovered = isMouseInPosition(x + 50, answerY, width - 100, answerHeight)
        
        local bgColor = isHovered and tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 80) or tocolor(secondaryColor[1], secondaryColor[2], secondaryColor[3], 255)
        
        dxDrawRectangle(x + 50, answerY, width - 100, answerHeight, bgColor)
        dxDrawRectangle(x + 50, answerY, width - 100, 2, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
        
        dxDrawText(tostring(i) .. ". " .. answer, x + 50, answerY, x + width - 50, answerY + answerHeight,
                  tocolor(textColor[1], textColor[2], textColor[3], 255), 0.95, dxfont_small, "center", "center")
    end
    
    -- التقدم
    local progress = (currentTestData.currentQuestion - 1) / 7
    dxDrawRectangle(x + 50, y + height - 30, width - 100, 15, tocolor(secondaryColor[1], secondaryColor[2], secondaryColor[3], 255))
    dxDrawRectangle(x + 50, y + height - 30, (width - 100) * progress, 15, tocolor(primaryColor[1], primaryColor[2], primaryColor[3], 255))
    
    dxDrawText("التقدم: " .. currentTestData.currentQuestion .. "/7", x, y + height - 30, x + width, y + height - 10,
              tocolor(textColor[1], textColor[2], textColor[3], 255), 0.9, dxfont_small, "center", "center")
end

-- ========== نظام الاختبار النظري ==========
function startTheoryTest(licenseType, licenseId)
    if currentTestData.active then return end
    
    currentTestData = {
        active = true,
        questions = getRandomQuestions(licenseType),
        currentQuestion = 1,
        correctAnswers = 0,
        licenseType = licenseType,
        licenseId = licenseId
    }
    
    showCursor(true)
    showToast("بدأ الاختبار النظري - لديك 7 أسئلة للإجابة عليها")
end

function getRandomQuestions(licenseType)
    local allQuestions = theoryQuestions[licenseType]
    local selected = {}
    local usedIndices = {}
    
    while #selected < 7 do
        local randomIndex = math.random(1, #allQuestions)
        if not usedIndices[randomIndex] then
            table.insert(selected, allQuestions[randomIndex])
            usedIndices[randomIndex] = true
        end
    end
    
    return selected
end

function finishTheoryTest()
    local score = (currentTestData.correctAnswers / 7) * 100
    local licenseType = currentTestData.licenseType
    local licenseId = currentTestData.licenseId
    
    currentTestData.active = false
    showCursor(false)
    
    if score >= 50 then -- 50% للنجاح كما طلبت
        showToast("🎉 نجحت في الاختبار النظري بنسبة " .. math.floor(score) .. "%")
        
        -- إرسال النتيجة للسيرفر
        triggerServerEvent("onTheoryTestPassed", localPlayer, licenseType)
        
    else
        showToast("❌ رسبت في الاختبار النظري بنسبة " .. math.floor(score) .. "%", true)
    end
end

-- ========== التحكم في الواجهة ==========
bindKey("e", "down", function()
    if getElementData(localPlayer, "loggedin") ~= 1 then return end
    if currentTestData.active then 
        showToast("❌ لا يمكن فتح القائمة أثناء الاختبار", true)
        return 
    end
    
    local nearLicenseNPC = false
    local peds = getElementsByType("ped", root, true)

    for k, element in ipairs(peds) do
        local npcType = getElementData(element, "npc.type")
        if not npcType then
            npcType = getElementData(element, "rpp.npc.type")
        end

        if npcType == "dmv.license" then
            local px, py, pz = getElementPosition(element)
            local x, y, z = getElementPosition(localPlayer)

            if getDistanceBetweenPoints3D(px, py, pz, x, y, z) <= 3 then
                nearLicenseNPC = true
                
                if not isLicenseMenuOpen then
                    openLicenseMenu()
                else
                    closeLicenseMenu()
                end
                break
            end
        end
    end
    
    if not nearLicenseNPC and isLicenseMenuOpen then
        closeLicenseMenu()
    end
end)

function openLicenseMenu()
    if isLicenseMenuOpen then return end
    
    isLicenseMenuOpen = true
    selectedLicense = 0
    showCursor(true)
    --showToast("مرحباً بك في إدارة المرور - اختر نوع الرخصة المناسب")
end

function closeLicenseMenu()
    if not isLicenseMenuOpen then return end
    
    isLicenseMenuOpen = false
    selectedLicense = 0
    showCursor(false)
end

-- معالجة النقر على الواجهة
addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY)
    if button ~= "left" or state ~= "down" then return end
    
    -- النقر على واجهة الرخص
    if isLicenseMenuOpen then
        local width, height = 550, 500
        local x = (screenW - width) / 2
        local y = (screenH - height) / 2
        
        -- التحقق من النقر على الرخص
        local licenseHeight = 100
        local startY = y + 80
        
        for i = 1, 3 do
            local licenseY = startY + ((i-1) * (licenseHeight + 15))
            if isMouseInPosition(x + 25, licenseY, width - 50, licenseHeight) then
                selectedLicense = i
                showToast("تم اختيار: " .. licenseTypes[i].name)
                return
            end
        end
        
        -- التحقق من النقر على الأزرار
        local buttonWidth = (width - 70) / 2
        local buttonHeight = 40
        local buttonY = y + height - 60
        
        -- زر البدء
        if isMouseInPosition(x + 25, buttonY, buttonWidth, buttonHeight) then
            if selectedLicense == 0 then
                showToast("❌ يرجى اختيار نوع الرخصة أولاً", true)
                return
            end
            startLicenseProcess(selectedLicense)
        end
        
        -- زر الإلغاء
        if isMouseInPosition(x + 35 + buttonWidth, buttonY, buttonWidth, buttonHeight) then
            closeLicenseMenu()
        end
        
        return
    end
    
    -- النقر على الاختبار النظري
    if currentTestData.active then
        local width, height = 600, 400
        local x = (screenW - width) / 2
        local y = (screenH - height) / 2
        
        local currentQ = currentTestData.questions[currentTestData.currentQuestion]
        local answerHeight = 45
        local startY = y + 150
        
        for i, answer in ipairs(currentQ.answers) do
            local answerY = startY + ((i-1) * (answerHeight + 10))
            
            if isMouseInPosition(x + 50, answerY, width - 100, answerHeight) then
                -- التحقق من الإجابة
                if i == currentQ.correct then
                    currentTestData.correctAnswers = currentTestData.correctAnswers + 1
                end
                
                -- الانتقال للسؤال التالي أو إنهاء الاختبار
                if currentTestData.currentQuestion < 7 then
                    currentTestData.currentQuestion = currentTestData.currentQuestion + 1
                else
                    finishTheoryTest()
                end
                break
            end
        end
    end
end)

function startLicenseProcess(licenseId)
    local license = licenseTypes[licenseId]
    
    -- التحقق من العمر للرخص التي تحتاج عمر 16
    if license.testType == "car" or license.testType == "bike" then
        local playerAge = getElementData(localPlayer, "age") or 0
        if playerAge < 16 then
            showToast("❌ يجب أن يكون عمرك 16 سنة على الأقل لهذه الرخصة", true)
            return
        end
    end
    
    -- رخصة الصيد مباشرة بدون اختبار
    if license.testType == "fishing" then
        showToast("🎣 جاري استخراج رخصة الصيد...")
        triggerServerEvent("acceptFishLicense", localPlayer, false)
        closeLicenseMenu()
        return
    end
    
    startTheoryTest(license.testType, licenseId)
    closeLicenseMenu()
end

-- ========== أحداث من السيرفر ==========
addEvent("startCarPracticalTest", true)
addEventHandler("startCarPracticalTest", root, function()    

    if type(initiateDrivingTest) == "function" then
        setTimer(function()
            initiateDrivingTest()
            showToast("🚗 مركبة الاختبار جاهزة - ابدأ القيادة في المسار المحدد")
        end, 2000, 1)
    end
end)

addEvent("startBikePracticalTest", true)
addEventHandler("startBikePracticalTest", root, function()    
    if type(initiateBikeTest) == "function" then
        setTimer(function()
            initiateBikeTest()
            showToast("🏍️ دراجة الاختبار جاهزة - ابدأ القيادة في المسار المحدد")
        end, 2000, 1)
    end
end)

addEvent("onLicenseGranted", true)
addEventHandler("onLicenseGranted", root, function(licenseType)
    showToast("🎉 تم منح الرخصة بنجاح! يمكنك استخدامها الآن")
end)

-- ========== تحميل الأنظمة الأصلية ==========
addEventHandler("onClientResourceStart", resourceRoot, function()
    outputDebugString("✅ تم تحميل نظام الرخص الجديد بنجاح")
    loadTextures() -- تحميل الـ Textures عند بدء التشغيل
end)

-- ========== دالة التحقق من موضع الماوس ==========
function isMouseInPosition(x, y, width, height)
    if not isCursorShowing() then return false end
    local cursorX, cursorY = getCursorPosition()
    cursorX, cursorY = cursorX * screenW, cursorY * screenH
    return cursorX >= x and cursorX <= x + width and cursorY >= y and cursorY <= y + height
end
