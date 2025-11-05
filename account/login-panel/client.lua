-- client.lua
local screenWidth, screenHeight = guiGetScreenSize()
local font = dxCreateFont("Tajawal-Black.ttf", 10) or "default"
local titleFont = dxCreateFont("Tajawal-Bold.ttf", 11) or "title-bold"

-- تحميل الصور بشكل صحيح
local backgroundImage = dxCreateTexture("login-panel/background.png")
local logoImage = dxCreateTexture("login-panel/logopr.png")
local userIcon = dxCreateTexture("login-panel/user.png")
local passIcon = dxCreateTexture("login-panel/pass.png")
local passVisibleIcon = dxCreateTexture("login-panel/pass1.png")
local emailIcon = dxCreateTexture("login-panel/email.png")

-- تحميل خلفيات البانلات
local loginBgImage = dxCreateTexture("login-panel/bkg1.png")
local registerBgImage = dxCreateTexture("login-panel/bkg2.png")
local buttonImage = dxCreateTexture("login-panel/button.png")

-- 🎵 إصلاح مشكلة الصوت
function playClickSound()
    local soundPaths = {
        ":account/login-panel/click.mp3",
        "login-panel/click.mp3", 
        ":account/click.mp3",
        "click.mp3"
    }
    
    for _, path in ipairs(soundPaths) do
        local sound = playSound(path)
        if sound then
            setSoundVolume(sound, 0.7)
            return true
        end
    end
    
    outputDebugString("لم يتم العثور على ملف الصوت click.mp3")
    return false
end


-- بانل تسجيل الدخول
local loginPanel = {
    width = 300,
    height = 320,
    x = (screenWidth - 300) / 2,
    y = (screenHeight - 320) / 2,
    visible = true
}

-- بانل إنشاء الحساب
local registerPanel = {
    width = 320,
    height = 380,
    x = (screenWidth - 320) / 2,
    y = (screenHeight - 380) / 2,
    visible = false
}

local logo = {
    width = 40,  
    height = 40, 
    x = loginPanel.x + 10,
    y = loginPanel.y + 5,
    registerX = registerPanel.x + 10,
    registerY = registerPanel.y + 5
}

-- إضافة خيار "تذكرني"
local rememberMe = false

-- متغيرات لإظهار/إخفاء كلمة المرور
local passwordVisible = {
    login = false,
    register = {false, false}
}

local inputFields = {
    login = {
        {text = "", placeholder = "اسم المستخدم", type = "text", active = false},
        {text = "", placeholder = "كلمة المرور", type = "password", active = false}
    },
    register = {
        {text = "", placeholder = "اسم المستخدم", type = "text", active = false},
        {text = "", placeholder = "البريد الإلكتروني", type = "email", active = false},
        {text = "", placeholder = "كلمة المرور", type = "password", active = false},
        {text = "", placeholder = "تأكيد كلمة المرور", type = "password", active = false}
    }
}

-- 🎨 ألوان
local colors = {
    primary = tocolor(220, 20, 60),
    secondary = tocolor(180, 0, 40),
    white = tocolor(255, 255, 255),
    lightText = tocolor(220, 220, 220),
    panel = tocolor(0, 0, 0, 250),
    fieldBg = tocolor(33, 33, 33, 80),
    fieldLine = tocolor(255, 255, 255, 200),
    toastBg = tocolor(0, 0, 0, 100),
    checkbox = tocolor(33, 33, 33, 80),
    checkboxTick = tocolor(255, 255, 255)
}

-- نظام التوست
local toastMessages = {}
local TOAST_DURATION = 3000
local lastToastTime = 0
local TOAST_COOLDOWN = 5000

-- مؤشر الكتابة
local cursorBlink = true
local cursorTimer = nil
local lastBlinkTime = 0

-- تأثير التكبير للروابط
local linkScale = {
    switchToRegister = 1.0,
    forgot = 1.0,
    switchToLogin = 1.0,
    remember = 1.0
}

-- 🆕 متغيرات لتخزين إحداثيات العناصر الحالية
local currentElements = {
    login = {},
    register = {}
}

function startCursorBlink()
    if cursorTimer then
        killTimer(cursorTimer)
    end
    cursorBlink = true
    lastBlinkTime = getTickCount()
    cursorTimer = setTimer(function()
        cursorBlink = not cursorBlink
    end, 500, 0)
end

function stopCursorBlink()
    if cursorTimer then
        killTimer(cursorTimer)
        cursorTimer = nil
    end
    cursorBlink = false
end

function showToastMessage(message, r, g, b)
    local currentTime = getTickCount()
    if currentTime - lastToastTime < TOAST_COOLDOWN then
        return
    end
    
    lastToastTime = currentTime
    table.insert(toastMessages, {
        text = message,
        color = tocolor(r or 255, g or 255, b or 255),
        startTime = currentTime,
        y = -50
    })
end

function drawToastMessages()
    local currentTime = getTickCount()
    local toastHeight = 30
    local toastWidth = 250
    local toastX = (screenWidth - toastWidth) / 2
    
    for i = #toastMessages, 1, -1 do
        local toast = toastMessages[i]
        local elapsed = currentTime - toast.startTime
        
        if elapsed < TOAST_DURATION then
            local progress = elapsed / TOAST_DURATION
            local targetY = 50
            local startY = -50
            
            if progress < 0.2 then
                local enterProgress = progress / 0.2
                toast.y = startY + (targetY - startY) * enterProgress
            elseif progress > 0.8 then
                local exitProgress = (progress - 0.8) / 0.2
                toast.y = targetY - 50 * exitProgress
            else
                toast.y = targetY
            end
            
            dxDrawRectangle(toastX, toast.y, toastWidth, toastHeight, colors.toastBg)
            dxDrawText(toast.text, toastX, toast.y, toastX + toastWidth, toast.y + toastHeight, colors.white, 0.8, font, "center", "center", false, false, true)
        else
            table.remove(toastMessages, i)
        end
    end
end

-- متغيرات التحكم في الكتابة
local backspaceTimer = nil
local capsLockEnabled = false

-- متغيرات تأثير الأزرار
local buttonHover = {
    login = false,
    register = false,
    forgot = false,
    remember = false,
    switchToRegister = false,
    switchToLogin = false
}

local loginPanelVisible = true

function toggleLoginPanel(state)
    if state ~= nil then
        loginPanelVisible = state
    else
        loginPanelVisible = not loginPanelVisible
    end
    
    if loginPanelVisible then
        resetInputFields()
        addEventHandler("onClientRender", root, drawLoginPanel)
        addEventHandler("onClientClick", root, handleClick)
        addEventHandler("onClientDoubleClick", root, handleDoubleClick)
        showCursor(true)
        toggleControl("all", false)
    else
        removeEventHandler("onClientRender", root, drawLoginPanel)
        removeEventHandler("onClientClick", root, handleClick)
        removeEventHandler("onClientDoubleClick", root, handleDoubleClick)
        stopCursorBlink()
        showCursor(false)
        toggleControl("all", true)
    end
end

function resetInputFields()
    for _, fields in pairs(inputFields) do
        for _, field in ipairs(fields) do
            field.text = ""
            field.active = false
        end
    end
    passwordVisible.login = false
    passwordVisible.register = {false, false}
    stopCursorBlink()
end

function switchToRegister()
    loginPanel.visible = false
    registerPanel.visible = true
    resetInputFields()
    playClickSound()
end

function switchToLogin()
    registerPanel.visible = false
    loginPanel.visible = true
    resetInputFields()
    playClickSound()
end

-- تحديث تأثيرات التكبير
addEventHandler("onClientRender", root, function()
    if loginPanel.visible then
        if buttonHover.switchToRegister and linkScale.switchToRegister < 1.05 then
            linkScale.switchToRegister = linkScale.switchToRegister + 0.02
        elseif not buttonHover.switchToRegister and linkScale.switchToRegister > 1.0 then
            linkScale.switchToRegister = linkScale.switchToRegister - 0.02
        end
        
        if buttonHover.forgot and linkScale.forgot < 1.05 then
            linkScale.forgot = linkScale.forgot + 0.02
        elseif not buttonHover.forgot and linkScale.forgot > 1.0 then
            linkScale.forgot = linkScale.forgot - 0.02
        end
        
        if buttonHover.remember and linkScale.remember < 1.1 then
            linkScale.remember = linkScale.remember + 0.02
        elseif not buttonHover.remember and linkScale.remember > 1.0 then
            linkScale.remember = linkScale.remember - 0.02
        end
    elseif registerPanel.visible then
        if buttonHover.switchToLogin and linkScale.switchToLogin < 1.05 then
            linkScale.switchToLogin = linkScale.switchToLogin + 0.02
        elseif not buttonHover.switchToLogin and linkScale.switchToLogin > 1.0 then
            linkScale.switchToLogin = linkScale.switchToLogin - 0.02
        end
    end
end)

function drawLoginPanel()
    dxDrawRectangle(0, 0, screenWidth, screenHeight, tocolor(0, 0, 0, 200))
    
    if backgroundImage then
        dxDrawImage(0, 0, screenWidth, screenHeight, backgroundImage, 0, 0, 0, tocolor(255, 255, 255, 255))
    end

    if loginPanel.visible then
        if logoImage then
            dxDrawImage(logo.x, logo.y, logo.width, logo.height, logoImage, 0, 0, 0, tocolor(255, 255, 255, 255))
        end
        drawLoginForm()
    elseif registerPanel.visible then
        if logoImage then
            dxDrawImage(logo.registerX, logo.registerY, logo.width, logo.height, logoImage, 0, 0, 0, tocolor(255, 255, 255, 255))
        end
        drawRegisterForm()
    end

    drawToastMessages()
end

function drawLoginForm()
    -- 🆕 إعادة تعيين العناصر
    currentElements.login = {}
    
    if loginBgImage then
        dxDrawImage(loginPanel.x, loginPanel.y, loginPanel.width, loginPanel.height, loginBgImage, 0, 0, 0, tocolor(255, 255, 255, 255))
    else
        dxDrawRectangle(loginPanel.x, loginPanel.y, loginPanel.width, loginPanel.height, colors.panel)
    end
    
    dxDrawText("تسجيل الدخول", loginPanel.x, loginPanel.y + 10, loginPanel.x + loginPanel.width, loginPanel.y + 35, colors.white, 1.0, titleFont, "center", "center")
    
    local lineY = loginPanel.y + 45
    dxDrawLine(loginPanel.x + 20, lineY, loginPanel.x + loginPanel.width - 20, lineY, tocolor(33, 33, 33, 90), 1)

    if logoImage then
        dxDrawImage(logo.x, logo.y, logo.width, logo.height, logoImage, 0, 0, 0, tocolor(255, 255, 255, 255))
    end

    local fieldWidth = 260
    local fieldHeight = 32
    local fieldX = loginPanel.x + (loginPanel.width - fieldWidth) / 2
    local startY = loginPanel.y + 80

    -- 🆕 حفظ إحداثيات الحقول
    currentElements.login.fields = {}

    local fields = inputFields.login
    for i, field in ipairs(fields) do
        -- 🆕 حفظ إحداثيات الحقل
        currentElements.login.fields[i] = {
            x = fieldX, 
            y = startY,
            width = fieldWidth,
            height = fieldHeight
        }
        
        dxDrawRectangle(fieldX, startY, fieldWidth, fieldHeight, colors.fieldBg)
        dxDrawLine(fieldX + 20, startY + fieldHeight, fieldX + fieldWidth - 20, startY + fieldHeight, colors.fieldLine, 1.5)

local displayText = ""
local textColor = colors.white
local textScale = 1.0  -- الحجم الافتراضي للنص الفعلي

if field.text == "" and not field.active then
    displayText = field.placeholder
    textColor = tocolor(255, 255, 255, 50)
    textScale = 0.7  -- 🎯 حجم صغير للوصف فقط
else
    if field.type == "password" and not passwordVisible.login then
        displayText = string.rep("*", #field.text)
    else
        displayText = field.text
    end
    textScale = 1.0  -- 🎯 حجم كبير للنص الفعلي فقط
end

-- حساب العرض باستخدام المقياس الصحيح
local textWidth = dxGetTextWidth(displayText, textScale, font)
local cursorX = fieldX + fieldWidth - 10 - textWidth

-- الرسم باستخدام المقياس الصحيح
dxDrawText(displayText, fieldX + 30, startY, fieldX + fieldWidth - 10, startY + fieldHeight, textColor, textScale, font, "right", "center")

-- المؤشر
if field.active and cursorBlink then
    dxDrawRectangle(cursorX, startY + 8, 2, fieldHeight - 16, colors.white)
end
        
        local icon = nil
        if i == 1 then 
            icon = userIcon
        elseif i == 2 then 
            icon = passwordVisible.login and passVisibleIcon or passIcon
        end
        
        if icon then
            -- 🆕 حفظ إحداثيات الأيقونة
            currentElements.login.passIcon = {
                x = fieldX + 6,
                y = startY + 5,
                width = 16,
                height = 16
            }
            dxDrawImage(fieldX + 6, startY + 5, 16, 16, icon, 0, 0, 0, tocolor(255, 255, 255, 200))
        end
        
        startY = startY + fieldHeight + 12
    end

    local optionsY = startY
    local rememberSize = 16
    
    local cursorX, cursorY = 0, 0
    if isCursorShowing() then
        cursorX, cursorY = getCursorPosition()
        cursorX, cursorY = cursorX * screenWidth, cursorY * screenHeight
    end
    
    -- خيار "تذكرني"
    local rememberText = "تذكرني"
    local rememberTextWidth = dxGetTextWidth(rememberText, 0.8 * linkScale.remember, font)
    local rememberAreaWidth = rememberSize + 6 + rememberTextWidth
    
    -- 🆕 حفظ إحداثيات تذكرني
    currentElements.login.remember = {
        x = fieldX,
        y = optionsY,
        width = rememberAreaWidth,
        height = rememberSize
    }
    
    local isHoveringRemember = isInBox(cursorX, cursorY, fieldX, fieldX + rememberAreaWidth, optionsY, optionsY + rememberSize)
    buttonHover.remember = isHoveringRemember
    
    dxDrawRectangle(fieldX, optionsY, rememberSize, rememberSize, colors.checkbox)
    
    if rememberMe then
        dxDrawText("✓", fieldX, optionsY, fieldX + rememberSize, optionsY + rememberSize, colors.checkboxTick, 1.0, titleFont, "center", "center")
    end
    
    dxDrawText(rememberText, fieldX + rememberSize + 6, optionsY, fieldX + fieldWidth, optionsY + rememberSize, colors.white, 0.8 * linkScale.remember, font, "left", "center")

    -- رابط "نسيت كلمة المرور"
    local forgotText = "نسيت كلمة المرور؟"
    local forgotFontScale = 0.7 * linkScale.forgot
    local forgotWidth = dxGetTextWidth(forgotText, forgotFontScale, font)
    local forgotX = fieldX + fieldWidth - forgotWidth
    
    -- 🆕 حفظ إحداثيات نسيت كلمة المرور
    currentElements.login.forgot = {
        x = forgotX,
        y = optionsY,
        width = forgotWidth,
        height = 16
    }
    
    local isHoveringForgot = isInBox(cursorX, cursorY, forgotX, forgotX + forgotWidth, optionsY, optionsY + 16)
    buttonHover.forgot = isHoveringForgot
    
    local forgotColor = colors.white
    dxDrawText(forgotText, forgotX, optionsY, fieldX + fieldWidth, optionsY + 16, forgotColor, forgotFontScale, font, "right", "center")

-- زر تسجيل الدخول
local buttonY = optionsY + 40
local buttonWidth = 150
local buttonHeight = 28
local buttonX = fieldX + (fieldWidth - buttonWidth) / 2

-- 🆕 حفظ إحداثيات زر تسجيل الدخول
currentElements.login.loginButton = {
    x = buttonX,
    y = buttonY,
    width = buttonWidth,
    height = buttonHeight
}

local isHoveringLogin = isInBox(cursorX, cursorY, buttonX, buttonX + buttonWidth, buttonY, buttonY + buttonHeight)
buttonHover.login = isHoveringLogin

-- 🎨 استخدام صورة الزر مع تأثير التعتيم عند Hover
if buttonImage then
    local buttonAlpha = isHoveringLogin and 180 or 255  -- 🎯 يتعتّم شوية لما الماوس يعدي
    dxDrawImage(buttonX, buttonY, buttonWidth, buttonHeight, buttonImage, 0, 0, 0, tocolor(255, 255, 255, buttonAlpha))
else
    -- Fallback إذا الصورة ما اتحملتش
    local buttonColor = isHoveringLogin and colors.secondary or colors.primary
    dxDrawRectangle(buttonX, buttonY, buttonWidth, buttonHeight, buttonColor)
end

dxDrawText("تسجيل الدخول", buttonX, buttonY, buttonX + buttonWidth, buttonY + buttonHeight, colors.white, 1, font, "center", "center")

    -- رابط "إنشاء حساب جديد"
    local switchText = "إنشاء حساب جديد"
    local switchFontScale = 0.8 * linkScale.switchToRegister
    local switchWidth = dxGetTextWidth(switchText, switchFontScale, font)
    local switchX = fieldX + (fieldWidth - switchWidth) / 2
    local switchY = buttonY + 40
    
    -- 🆕 حفظ إحداثيات رابط إنشاء حساب
    currentElements.login.switchToRegister = {
        x = switchX,
        y = switchY,
        width = switchWidth,
        height = 16
    }
    
    local isHoveringSwitch = isInBox(cursorX, cursorY, switchX, switchX + switchWidth, switchY, switchY + 16)
    buttonHover.switchToRegister = isHoveringSwitch
    
    local switchColor = colors.white
    dxDrawText(switchText, fieldX, switchY, fieldX + fieldWidth, switchY + 16, switchColor, switchFontScale, font, "center", "center")
end

function drawRegisterForm()
    -- 🆕 إعادة تعيين العناصر
    currentElements.register = {}
    
    if registerBgImage then
        dxDrawImage(registerPanel.x, registerPanel.y, registerPanel.width, registerPanel.height, registerBgImage, 0, 0, 0, tocolor(255, 255, 255, 255))
    else
        dxDrawRectangle(registerPanel.x, registerPanel.y, registerPanel.width, registerPanel.height, colors.panel)
    end
    
    dxDrawText("إنشاء حساب جديد", registerPanel.x, registerPanel.y + 10, registerPanel.x + registerPanel.width, registerPanel.y + 35, colors.white, 1.0, titleFont, "center", "center")

    local lineY = registerPanel.y + 45
    dxDrawLine(registerPanel.x + 20, lineY, registerPanel.x + registerPanel.width - 20, lineY, tocolor(33, 33, 33, 90), 1)

    if logoImage then
        dxDrawImage(logo.registerX, logo.registerY, logo.width, logo.height, logoImage, 0, 0, 0, tocolor(255, 255, 255, 255))
    end

    local fieldWidth = 280
    local fieldHeight = 32
    local fieldX = registerPanel.x + (registerPanel.width - fieldWidth) / 2
    local startY = registerPanel.y + 80

    -- 🆕 حفظ إحداثيات الحقول
    currentElements.register.fields = {}
    currentElements.register.passIcons = {}

    local fields = inputFields.register
    for i, field in ipairs(fields) do
        -- 🆕 حفظ إحداثيات الحقول
        currentElements.register.fields[i] = {
            x = fieldX,
            y = startY,
            width = fieldWidth,
            height = fieldHeight
        }
        
        dxDrawRectangle(fieldX, startY, fieldWidth, fieldHeight, colors.fieldBg)
        dxDrawLine(fieldX + 20, startY + fieldHeight, fieldX + fieldWidth - 20, startY + fieldHeight, colors.fieldLine, 1.5)

local displayText = ""
local textColor = colors.white
local textScale = 1.0  -- الحجم الافتراضي للنص الفعلي

if field.text == "" and not field.active then
    displayText = field.placeholder
    textColor = tocolor(255, 255, 255, 50)
    textScale = 0.7  -- 🎯 حجم صغير للوصف فقط
else
    if field.type == "password" then
        if i == 3 and not passwordVisible.register[1] then
            displayText = string.rep("*", #field.text)
        elseif i == 4 and not passwordVisible.register[2] then
            displayText = string.rep("*", #field.text)
        else
            displayText = field.text
        end
    else
        displayText = field.text
    end
    textScale = 1.0  -- 🎯 حجم كبير للنص الفعلي فقط
end

-- حساب العرض باستخدام المقياس الصحيح
local textWidth = dxGetTextWidth(displayText, textScale, font)
local cursorX = fieldX + fieldWidth - 10 - textWidth

-- الرسم باستخدام المقياس الصحيح
dxDrawText(displayText, fieldX + 30, startY, fieldX + fieldWidth - 10, startY + fieldHeight, textColor, textScale, font, "right", "center")

-- المؤشر
if field.active and cursorBlink then
    dxDrawRectangle(cursorX, startY + 8, 2, fieldHeight - 16, colors.white)
end
        
        local icon = nil
        if i == 1 then icon = userIcon
        elseif i == 2 then icon = emailIcon
        elseif i == 3 then 
            icon = passwordVisible.register[1] and passVisibleIcon or passIcon
            -- 🆕 حفظ إحداثيات أيقونة كلمة المرور الأولى
            currentElements.register.passIcons[1] = {
                x = fieldX + 6,
                y = startY + 5,
                width = 16,
                height = 16
            }
        elseif i == 4 then 
            icon = passwordVisible.register[2] and passVisibleIcon or passIcon
            -- 🆕 حفظ إحداثيات أيقونة كلمة المرور الثانية
            currentElements.register.passIcons[2] = {
                x = fieldX + 6,
                y = startY + 5,
                width = 16,
                height = 16
            }
        end
        
        if icon then
            dxDrawImage(fieldX + 6, startY + 5, 16, 16, icon, 0, 0, 0, tocolor(255, 255, 255, 200))
        end
        
        startY = startY + fieldHeight + 10
    end

-- زر إنشاء الحساب
local buttonY = startY + 25
local buttonWidth = 150
local buttonHeight = 28
local buttonX = fieldX + (fieldWidth - buttonWidth) / 2

-- 🆕 حفظ إحداثيات زر إنشاء الحساب
currentElements.register.registerButton = {
    x = buttonX,
    y = buttonY,
    width = buttonWidth,
    height = buttonHeight
}

local cursorX, cursorY = 0, 0
if isCursorShowing() then
    cursorX, cursorY = getCursorPosition()
    cursorX, cursorY = cursorX * screenWidth, cursorY * screenHeight
end

local isHoveringRegister = isInBox(cursorX, cursorY, buttonX, buttonX + buttonWidth, buttonY, buttonY + buttonHeight)
buttonHover.register = isHoveringRegister

-- 🎨 استخدام صورة الزر مع تأثير التعتيم عند Hover
if buttonImage then
    local buttonAlpha = isHoveringRegister and 180 or 255  -- 🎯 يتعتّم شوية لما الماوس يعدي
    dxDrawImage(buttonX, buttonY, buttonWidth, buttonHeight, buttonImage, 0, 0, 0, tocolor(255, 255, 255, buttonAlpha))
else
    -- Fallback إذا الصورة ما اتحملتش
    local buttonColor = isHoveringRegister and colors.secondary or colors.primary
    dxDrawRectangle(buttonX, buttonY, buttonWidth, buttonHeight, buttonColor)
end

dxDrawText("إنشاء الحساب", buttonX, buttonY, buttonX + buttonWidth, buttonY + buttonHeight, colors.white, 1, font, "center", "center")
    -- رابط الرجوع لتسجيل الدخول
    local backText = "العودة لتسجيل الدخول"
    local backFontScale = 0.8 * linkScale.switchToLogin
    local backWidth = dxGetTextWidth(backText, backFontScale, font)
    local backX = fieldX + (fieldWidth - backWidth) / 2
    local backY = buttonY + 40
    
    -- 🆕 حفظ إحداثيات رابط العودة
    currentElements.register.switchToLogin = {
        x = backX,
        y = backY,
        width = backWidth,
        height = 16
    }
    
    local isHoveringBack = isInBox(cursorX, cursorY, backX, backX + backWidth, backY, backY + 16)
    buttonHover.switchToLogin = isHoveringBack
    
    local backColor = colors.white
    dxDrawText(backText, fieldX, backY, fieldX + fieldWidth, backY + 16, backColor, backFontScale, font, "center", "center")
end

-- 🔧 دالة التحقق من وجود الماوس في منطقة
function isInBox(x, y, xmin, xmax, ymin, ymax)
    return x and y and x >= xmin and x <= xmax and y >= ymin and y <= ymax
end

-- 🔘 معالجة النقر - 🆕 محدث باستخدام العناصر المحفوظة
function handleClick(button, state, x, y)
    if button ~= "left" or state ~= "up" then return end

    if loginPanel.visible then
        -- استخدام العناصر المحفوظة بدلاً من الحساب المباشر
        local elements = currentElements.login
        
        -- رابط "إنشاء حساب جديد"
        if elements.switchToRegister and isInBox(x, y, elements.switchToRegister.x, elements.switchToRegister.x + elements.switchToRegister.width, elements.switchToRegister.y, elements.switchToRegister.y + elements.switchToRegister.height) then
            playClickSound()
            switchToRegister()
            return
        end
        
        -- رابط "نسيت كلمة المرور"
        if elements.forgot and isInBox(x, y, elements.forgot.x, elements.forgot.x + elements.forgot.width, elements.forgot.y, elements.forgot.y + elements.forgot.height) then
            playClickSound()
            showToastMessage("🛠️ جاري تطوير هذه الميزة", 255, 200, 0)
            return
        end
        
        -- خيار "تذكرني"
        if elements.remember and isInBox(x, y, elements.remember.x, elements.remember.x + elements.remember.width, elements.remember.y, elements.remember.y + elements.remember.height) then
            playClickSound()
            rememberMe = not rememberMe
            return
        end
        
        -- النقر على أيقونة كلمة المرور
        if elements.passIcon and isInBox(x, y, elements.passIcon.x, elements.passIcon.x + elements.passIcon.width, elements.passIcon.y, elements.passIcon.y + elements.passIcon.height) then
            playClickSound()
            passwordVisible.login = not passwordVisible.login
            return
        end
        
        -- زر تسجيل الدخول
        if elements.loginButton and isInBox(x, y, elements.loginButton.x, elements.loginButton.x + elements.loginButton.width, elements.loginButton.y, elements.loginButton.y + elements.loginButton.height) then
            playClickSound()
            submitForm()
            return
        end
        
        -- التحقق من الحقول
        if elements.fields then
            for i, field in ipairs(elements.fields) do
                if isInBox(x, y, field.x, field.x + field.width, field.y, field.y + field.height) then
                    playClickSound()
                    for j, f in ipairs(inputFields.login) do
                        f.active = (i == j)
                        if i == j then
                            startCursorBlink()
                        end
                    end
                    return
                end
            end
        end
        
    elseif registerPanel.visible then
        local elements = currentElements.register
        
        -- رابط الرجوع لتسجيل الدخول
        if elements.switchToLogin and isInBox(x, y, elements.switchToLogin.x, elements.switchToLogin.x + elements.switchToLogin.width, elements.switchToLogin.y, elements.switchToLogin.y + elements.switchToLogin.height) then
            playClickSound()
            switchToLogin()
            return
        end
        
        -- النقر على أيقونات كلمة المرور
        if elements.passIcons then
            if elements.passIcons[1] and isInBox(x, y, elements.passIcons[1].x, elements.passIcons[1].x + elements.passIcons[1].width, elements.passIcons[1].y, elements.passIcons[1].y + elements.passIcons[1].height) then
                playClickSound()
                passwordVisible.register[1] = not passwordVisible.register[1]
                return
            end
            
            if elements.passIcons[2] and isInBox(x, y, elements.passIcons[2].x, elements.passIcons[2].x + elements.passIcons[2].width, elements.passIcons[2].y, elements.passIcons[2].y + elements.passIcons[2].height) then
                playClickSound()
                passwordVisible.register[2] = not passwordVisible.register[2]
                return
            end
        end
        
        -- زر إنشاء الحساب
        if elements.registerButton and isInBox(x, y, elements.registerButton.x, elements.registerButton.x + elements.registerButton.width, elements.registerButton.y, elements.registerButton.y + elements.registerButton.height) then
            playClickSound()
            submitForm()
            return
        end
        
        -- التحقق من الحقول
        if elements.fields then
            for i, field in ipairs(elements.fields) do
                if isInBox(x, y, field.x, field.x + field.width, field.y, field.y + field.height) then
                    playClickSound()
                    for j, f in ipairs(inputFields.register) do
                        f.active = (i == j)
                        if i == j then
                            startCursorBlink()
                        end
                    end
                    return
                end
            end
        end
    end
    
    -- إذا لم يتم النقر على أي عنصر، قم بإلغاء تفعيل الحقول
    stopCursorBlink()
    if loginPanel.visible then
        for _, field in ipairs(inputFields.login) do
            field.active = false
        end
    elseif registerPanel.visible then
        for _, field in ipairs(inputFields.register) do
            field.active = false
        end
    end
end

function handleDoubleClick(button, state, x, y)
    if button ~= "left" or state ~= "down" then return end
    
    local currentFields = loginPanel.visible and inputFields.login or inputFields.register
    for _, field in ipairs(currentFields) do
        if field.active then
            field.text = ""
            return
        end
    end
end

-- لوحة المفاتيح - 🛠️ محدث لدعم الرموز الخاصة
function handleKey(key, state)
    if not (loginPanel.visible or registerPanel.visible) then return end
    
    local currentFields = loginPanel.visible and inputFields.login or inputFields.register
    local activeIndex = nil

    for i, f in ipairs(currentFields) do
        if f.active then
            activeIndex = i
            break
        end
    end

    if state and activeIndex then
        local field = currentFields[activeIndex]

        local char = nil

        if #key == 1 then
            -- 🛠️ إصلاح الرموز الخاصة
            if getKeyState("lshift") or getKeyState("rshift") then
                -- الرموز مع Shift
                local shiftChars = {
                    ["1"] = "!", ["2"] = "@", ["3"] = "#", ["4"] = "$", ["5"] = "%",
                    ["6"] = "^", ["7"] = "&", ["8"] = "*", ["9"] = "(", ["0"] = ")",
                    ["-"] = "_", ["="] = "+", ["["] = "{", ["]"] = "}", ["\\"] = "|",
                    [";"] = ":", ["'"] = "\"", [","] = "<", ["."] = ">", ["/"] = "?",
                    ["`"] = "~"
                }
                char = shiftChars[key] or key:upper()
            elseif capsLockEnabled then
                -- حالة CapsLock
                char = key:upper()
            else
                -- الرموز العادية
                char = key:lower()
            end
        else
            -- 🛠️ الرموز الرقمية من لوحة الأرقام
            local numKey = key:match("num_(%d)")
            if numKey then 
                char = numKey 
            elseif key == "num_div" then
                char = "/"
            elseif key == "num_mult" then
                char = "*"
            elseif key == "num_sub" then
                char = "-"
            elseif key == "num_add" then
                char = "+"
            elseif key == "num_dec" then
                char = "."
            end
            
            if key == "capslock" then
                capsLockEnabled = not capsLockEnabled
                return
            end
        end

        if char then
            field.text = field.text .. char
            if not cursorTimer then
                startCursorBlink()
            end
            return
        end
    end

    if key == "backspace" then
        if state then
            if activeIndex then
                local field = currentFields[activeIndex]
                field.text = field.text:sub(1, -2)
                if not cursorTimer then
                    startCursorBlink()
                end
                backspaceTimer = setTimer(function()
                    if field.text ~= "" then
                        field.text = field.text:sub(1, -2)
                    end
                end, 100, 0)
            end
        else
            if isTimer(backspaceTimer) then
                killTimer(backspaceTimer)
            end
        end
        return
    end

    if (key == "enter" or key == "num_enter") and state then
     submitForm()
     return
    end

    if key == "tab" and state then
        if #currentFields > 0 then
            if activeIndex then
                currentFields[activeIndex].active = false
                local nextIndex = activeIndex + 1
                if nextIndex > #currentFields then nextIndex = 1 end
                currentFields[nextIndex].active = true
                startCursorBlink()
            else
                currentFields[1].active = true
                startCursorBlink()
            end
        end
        cancelEvent()
        return
    end

    if key == "escape" and state then
        showToastMessage("يجب تسجيل الدخول للعب!", 255, 100, 100)
        cancelEvent()
    end
end
addEventHandler("onClientKey", root, handleKey)

-- إرسال البيانات
function submitForm()
    if loginPanel.visible then
        local username = inputFields.login[1].text
        local password = inputFields.login[2].text
        local bannedWords = {"a7a", "kos", "kosom", "fuck", "shit", "wtf", "bitch"}
        local lowerName = string.lower(username)
        for _, word in ipairs(bannedWords) do
            if string.find(lowerName, word) then
                   showToastMessage("❌ اسم المستخدم يحتوي على كلمات غير لائقة", 255, 80, 80)
                return
            end
        end

        if username == "" or password == "" then
            showToastMessage("⚠️ يرجى ملء جميع الحقول", 255, 100, 100)
            return
        end
        
        triggerServerEvent("accounts:login:attempt", localPlayer, username, password, rememberMe)
        
    elseif registerPanel.visible then
        local fullname = inputFields.register[1].text
        local email = inputFields.register[2].text
        local password = inputFields.register[3].text
        local confirm = inputFields.register[4].text

        if fullname == "" or email == "" or password == "" or confirm == "" then
            showToastMessage("⚠️ يرجى ملء جميع الحقول", 255, 100, 100)
            return
        end
        if password ~= confirm then
            showToastMessage("❌ كلمات المرور غير متطابقة", 255, 80, 80)
            return
        end

        triggerServerEvent("accounts:register:attempt", localPlayer, fullname, password, confirm, email)
    end
end

-- 🟢 إظهار تلقائي عند البداية
addEventHandler("onClientResourceStart", resourceRoot, function()
    setTimer(function()
        toggleLoginPanel(true)
        showToastMessage("مرحباً! يرجى تسجيل الدخول للعب.", 220, 20, 60)
    end, 2000, 1)
end)

addCommandHandler("login", function()
    if not (loginPanel.visible or registerPanel.visible) then 
        toggleLoginPanel(true)
        switchToLogin()
    end
end)

-- 🔔 استقبال نتيجة تسجيل الدخول أو التسجيل من السيرفر
addEvent("accounts:login:result", true)
addEventHandler("accounts:login:result", root, function(success, message)
    if success then
        showToastMessage(message or "✅ تم تسجيل الدخول بنجاح!", 100, 255, 100)
        setTimer(function()
            triggerEvent("hideLoginPanel", localPlayer)
        end, 1500, 1)
    else
        showToastMessage(message or "❌ فشل تسجيل الدخول!", 255, 80, 80)
    end
end)

addEvent("accounts:register:result", true)
addEventHandler("accounts:register:result", root, function(success, message)
    if success then
        showToastMessage(message or "✅ تم إنشاء الحساب بنجاح! جاري تسجيل الدخول...", 100, 255, 100)
        setTimer(switchToLogin, 2000, 1)
    else
        showToastMessage(message or "❌ فشل إنشاء الحساب!", 255, 80, 80)
    end
end)

addEvent("hideLoginPanel", true)
addEventHandler("hideLoginPanel", root, function()
    toggleLoginPanel(false)
    showCursor(false)
    stopCursorBlink()
end)

-- 📦 لما يتم تسجيل الدخول بنجاح
addEvent("accounts:login:success", true)
addEventHandler("accounts:login:success", root, function()
    toggleLoginPanel(false)
    showCursor(false)
    stopCursorBlink()

    if getResourceFromName("character-system") and getResourceState(getResourceFromName("character-system")) == "running" then
        triggerEvent("onCharacterCreationStart", localPlayer)
    end
end)