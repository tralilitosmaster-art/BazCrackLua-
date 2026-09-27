--[[
    BazCrackLua (BCL)
    Version: 1.0.0
--]]

local CONFIG = { Version = "1.0.0" }

local COLORS = {
    Black     = Color3.fromRGB(0, 0, 0),
    DeepRed   = Color3.fromRGB(60, 0, 0),
    DarkRed   = Color3.fromRGB(100, 0, 0),
    Red       = Color3.fromRGB(180, 0, 0),
    BrightRed = Color3.fromRGB(255, 40, 40),
    Text      = Color3.fromRGB(255, 255, 255),
    SubText   = Color3.fromRGB(200, 150, 150),
    Green     = Color3.fromRGB(40, 220, 100),
    Yellow    = Color3.fromRGB(255, 210, 60),
}

local STATE = { StartTime = os.time() }

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

--========================================================
-- UI HELPERS
--========================================================
local function Gradient(obj, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 45
    g.Parent = obj
    return g
end
local function Corner(obj, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = obj; return c
end
local function Stroke(obj, color, th)
    local s = Instance.new("UIStroke"); s.Color = color or COLORS.BrightRed; s.Thickness = th or 1.5; s.Parent = obj; return s
end
local function AnimateIn(obj, targetPos, dur)
    dur = dur or 0.4
    local startY = targetPos.Y.Scale - 0.25
    obj.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, startY, targetPos.Y.Offset)
    obj.BackgroundTransparency = 1
    local t0 = tick()
    local conn
    conn = game:GetService("RunService").RenderStepped:Connect(function()
        local a = math.min((tick() - t0) / dur, 1)
        local e = 1 - (1 - a)^3
        obj.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, startY + (targetPos.Y.Scale - startY) * e, targetPos.Y.Offset)
        obj.BackgroundTransparency = 1 - e
        if a >= 1 then conn:Disconnect() end
    end)
end
local function Pulse(obj, min, max, dur)
    dur = dur or 1.2
    task.spawn(function()
        while obj.Parent do
            local t0 = tick()
            while tick() - t0 < dur do
                local a = (tick() - t0) / dur
                obj.Thickness = min + (max - min) * (0.5 + 0.5 * math.sin(a * math.pi * 2))
                task.wait(0.03)
            end
        end
    end)
end
local function Breathe(obj, c1, c2, dur)
    dur = dur or 3
    task.spawn(function()
        while obj.Parent do
            local t0 = tick()
            while tick() - t0 < dur do
                local a = (tick() - t0) / dur
                local mix = 0.5 + 0.5 * math.sin(a * math.pi * 2)
                obj.Color = c1:Lerp(c2, mix)
                task.wait(0.05)
            end
        end
    end)
end

--========================================================
-- EXECUTOR DETECTION (рабочий)
--========================================================
local function GetEnv()
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then return env end
    end
    if type(getfenv) == "function" then
        local ok, env = pcall(getfenv)
        if ok and type(env) == "table" then return env end
    end
    return _G
end

local function DetectExecutor()
    -- 1. Прямые API инжекторов
    if type(identifyexecutor) == "function" then
        local ok, n = pcall(identifyexecutor)
        if ok and n and n ~= "" then return tostring(n) end
    end
    if type(getexecutorname) == "function" then
        local ok, n = pcall(getexecutorname)
        if ok and n and n ~= "" then return tostring(n) end
    end

    -- 2. По уникальным глобалам
    local env = GetEnv()
    local signatures = {
        { name = "Synapse X",        check = function() return rawget(env, "syn") ~= nil end },
        { name = "Script-Ware",      check = function() return rawget(env, "ScriptWare") ~= nil or rawget(env, "SW") ~= nil end },
        { name = "Krnl",             check = function() return rawget(env, "KRNL_LOADED") ~= nil end },
        { name = "Fluxus",           check = function() return rawget(env, "fluxus") ~= nil end },
        { name = "Solara",           check = function() return rawget(env, "Solara") ~= nil end },
        { name = "Wave",             check = function() return rawget(env, "Wave") ~= nil end },
        { name = "Delta",            check = function() return rawget(env, "Delta") ~= nil end },
        { name = "AWP",              check = function() return rawget(env, "AWP") ~= nil end },
        { name = "Hydrogen",         check = function() return rawget(env, "Hydrogen") ~= nil end },
        { name = "SirHurt",          check = function() return rawget(env, "is_sirhurt_closure") ~= nil end },
        { name = "Sentinel",         check = function() return rawget(env, "secure_load") ~= nil end },
        { name = "Oxygen U",         check = function() return rawget(env, "Oxygen") ~= nil end },
        { name = "Trigona",          check = function() return rawget(env, "Trigona") ~= nil end },
        { name = "Nihon",            check = function() return rawget(env, "Nihon") ~= nil end },
        { name = "Valyse",           check = function() return rawget(env, "Valyse") ~= nil end },
        { name = "Xeno",             check = function() return rawget(env, "Xeno") ~= nil end },
        { name = "Electron",         check = function() return rawget(env, "Electron") ~= nil end },
        { name = "Codex",            check = function() return rawget(env, "Codex") ~= nil end },
    }
    for _, sig in ipairs(signatures) do
        local ok, res = pcall(sig.check)
        if ok and res then return sig.name end
    end

    -- 3. По косвенным признакам
    if type(request) == "function" or type(http_request) == "function" then
        return "Неизвестный (HTTP API)"
    end

    return "Неизвестный"
end

--========================================================
-- FUNCTION COUNT (рабочий)
--========================================================
local function HasGlobal(name)
    local env = GetEnv()
    -- Прямой доступ
    if env[name] ~= nil then return true end
    if _G[name] ~= nil then return true end
    -- Через rawget
    local ok, v = pcall(function() return rawget(env, name) end)
    if ok and v ~= nil then return true end
    return false
end

local function CountFunctions()
    local checks = {
        "loadstring", "getgenv", "getfenv", "setfenv", "getsenv", "gettenv",
        "setclipboard", "toclipboard",
        "writefile", "readfile", "appendfile", "isfile", "isfolder",
        "makefolder", "delfile", "delfolder", "listfiles",
        "HttpGet", "HttpPost", "request", "http_request", "http",
        "hookfunction", "hookmetamethod", "getrawmetatable", "setreadonly",
        "getnamecallmethod", "checkcaller", "islclosed", "islclosure",
        "getconnections", "firesignal", "fireclickdetector",
        "firetouchinterest", "fireproximityprompt",
        "getgc", "getinstances", "getnilinstances", "getloadedmodules",
        "getreg", "getupvalues", "getconstants", "setupvalue", "setconstant",
        "queue_on_teleport", "setfpscap", "getfpscap",
        "identifyexecutor", "getexecutorname", "getscriptbytecode",
        "getcustomasset", "mousemoverel", "mouse1click", "mouse1press",
        "mouse2click", "keypress", "keyrelease",
        "decompile", "dumpstring", "getscripthash", "getscriptclosure",
        "getcallingscript", "getfunctionhash", "gethui", "protectgui",
        "cloneref", "compareinstances", "getactors", "run_secure",
    }
    local loaded, total = 0, #checks
    local missing = {}
    for _, name in ipairs(checks) do
        if HasGlobal(name) then
            loaded = loaded + 1
        else
            table.insert(missing, name)
        end
    end
    return loaded, total, missing
end

local function Evaluate(loaded, total)
    if total == 0 then return 0, "F — нет данных", COLORS.BrightRed end
    local pct = math.floor((loaded / total) * 100)
    local grade, color
    if pct >= 95 then grade, color = "S — Полностью работоспособен", COLORS.Green
    elseif pct >= 80 then grade, color = "A — Отличный инжектор", COLORS.Green
    elseif pct >= 60 then grade, color = "B — Хороший инжектор", COLORS.Yellow
    elseif pct >= 40 then grade, color = "C — Средний инжектор", COLORS.Yellow
    elseif pct >= 20 then grade, color = "D — Слабый инжектор", COLORS.BrightRed
    else grade, color = "F — Неподходящий инжектор", COLORS.BrightRed end
    return pct, grade, color
end

--========================================================
-- COMPILER / DECOMPILER
--========================================================
local function SafeDump(fn)
    if type(string.dump) == "function" then
        local ok, bc = pcall(string.dump, fn)
        if ok and bc then return bc end
    end
    if type(dumpstring) == "function" then
        local ok, bc = pcall(dumpstring, fn)
        if ok and bc then return bc end
    end
    if type(getscriptbytecode) == "function" then
        local ok, bc = pcall(getscriptbytecode, fn)
        if ok and bc then return bc end
    end
    return nil, "дамп недоступен"
end

local Compiler = {}
function Compiler.Compile(src)
    if type(loadstring) ~= "function" then return nil, "loadstring недоступен" end
    local fn, err = loadstring(src, "=BCL")
    if not fn then return nil, "Ошибка компиляции: " .. tostring(err) end
    local bc, derr = SafeDump(fn)
    if not bc then return nil, derr end
    return bc
end
function Compiler.Run(src)
    if type(loadstring) ~= "function" then return nil, "loadstring недоступен" end
    local fn, err = loadstring(src)
    if not fn then return nil, err end
    local ok, res = pcall(fn)
    if not ok then return nil, res end
    return res
end

local Decompiler = {}
function Decompiler.FromLoadstring(code)
    local inner = code:match('loadstring%s*%(%s*["\'](.-)["\']%s*%)')
    return inner or code
end
function Decompiler.Try(code)
    local extracted = Decompiler.FromLoadstring(code)
    if type(loadstring) ~= "function" then
        return "-- BCL: loadstring недоступен.\n-- Фрагмент:\n" .. extracted
    end
    local fn = loadstring(extracted)
    if not fn then
        return "-- BCL: не удалось загрузить. Возможно, байткод или защита.\n-- Фрагмент:\n" .. extracted
    end
    local bc, derr = SafeDump(fn)
    if not bc then
        return "-- BCL: дамп недоступен (" .. tostring(derr) .. ").\n-- Извлечённый код:\n" .. extracted
    end
    return "-- BCL: байткод получен (" .. #bc .. " байт).\n-- Для полной декомпиляции нужен внешний движок.\n\n" .. extracted
end

--========================================================
-- OBFUSCATOR + LUARMOR
--========================================================
local Obfuscator = {}
function Obfuscator.Hex(src)
    return (src:gsub('"([^"]*)"', function(s)
        local h = ""; for i = 1, #s do h = h .. string.format("\\%d", s:byte(i)) end
        return '"' .. h .. '"'
    end))
end
function Obfuscator.Wrap(src)
    local b64 = (src:gsub(".", function(c) return string.format("%%%02X", c:byte()) end))
    return 'loadstring("' .. b64 .. '")()'
end
function Obfuscator.Run(src, lvl)
    lvl = lvl or 1
    local out = src
    if lvl >= 1 then out = Obfuscator.Hex(out) end
    if lvl >= 2 then out = Obfuscator.Wrap(out) end
    return out
end

local AntiLuarmor = {}
AntiLuarmor.Sig = {"Luarmor","luarmor","Luraph","luarmor.net"}
function AntiLuarmor.Detect(code)
    for _, s in ipairs(AntiLuarmor.Sig) do
        if code:find(s, 1, true) then return true end
    end
    return false
end

--========================================================
-- PLAYER PROFILE (реальный)
--========================================================
local function GetPlayerProfile()
    local name, display, userId, avatar = "?", "?", 0, nil
    if LP then
        name = LP.Name or "?"
        display = LP.DisplayName or name
        userId = LP.UserId or 0
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok then avatar = img end
    end
    return name, display, userId, avatar
end

--========================================================
-- UI
--========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BCL_Main"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 440, 0, 360)
Main.Position = UDim2.new(0.5, -220, 0.5, -180)
Main.BackgroundColor3 = COLORS.Black
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Gradient(Main, COLORS.Black, COLORS.DeepRed, 135)
Corner(Main, 10)
local mainStroke = Stroke(Main, COLORS.BrightRed, 1.5)
Main.Active = true
Main.Draggable = true
AnimateIn(Main, UDim2.new(0.5, -220, 0.5, -180), 0.45)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 34)
Title.BackgroundColor3 = COLORS.DeepRed
Title.BorderSizePixel = 0
Title.Text = "  BazCrackLua v" .. CONFIG.Version
Title.TextColor3 = COLORS.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main
Gradient(Title, COLORS.DarkRed, COLORS.BrightRed, 0)

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 26)
TabBar.Position = UDim2.new(0, 0, 0, 34)
TabBar.BackgroundColor3 = COLORS.Black
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

local Pages = {}
local function MakeTab(name, idx, w)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, w or 100, 1, 0)
    btn.Position = UDim2.new(0, (idx-1)*(w or 100)+3, 0, 0)
    btn.BackgroundColor3 = COLORS.DeepRed
    btn.Text = name
    btn.TextColor3 = COLORS.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = TabBar
    Corner(btn, 5); Stroke(btn, COLORS.DarkRed, 1)

    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, -16, 1, -100)
    page.Position = UDim2.new(0, 8, 0, 66)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = Main
    Pages[name] = page

    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        page.Visible = true
        for _, c in ipairs(TabBar:GetChildren()) do
            if c:IsA("TextButton") then c.BackgroundColor3 = COLORS.DeepRed end
        end
        btn.BackgroundColor3 = COLORS.DarkRed
    end)
    return btn, page
end

local TabCompile, PageCompile = MakeTab("Компил", 1, 100)
local TabDecomp,  PageDecomp  = MakeTab("Декомп", 2, 100)
local TabTools,   PageTools   = MakeTab("Инстр", 3, 100)
local TabInfo,    PageInfo    = MakeTab("Инфо", 4, 100)

-- Compiler page
local CIn = Instance.new("TextBox")
CIn.Size = UDim2.new(1, -16, 0, 80)
CIn.Position = UDim2.new(0, 8, 0, 4)
CIn.BackgroundColor3 = COLORS.Black
CIn.TextColor3 = COLORS.Text
CIn.PlaceholderText = "Введите Lua-код..."
CIn.PlaceholderColor3 = COLORS.SubText
CIn.Font = Enum.Font.Code
CIn.TextSize = 12
CIn.TextWrapped = true
CIn.TextXAlignment = Enum.TextXAlignment.Left
CIn.TextYAlignment = Enum.TextYAlignment.Top
CIn.ClearTextOnFocus = false
CIn.Parent = PageCompile
Corner(CIn, 5); Stroke(CIn, COLORS.Red, 1)

local CBtn = Instance.new("TextButton")
CBtn.Size = UDim2.new(0, 150, 0, 28)
CBtn.Position = UDim2.new(0, 8, 0, 90)
CBtn.BackgroundColor3 = COLORS.Red
CBtn.Text = "СКОМПИЛИРОВАТЬ"
CBtn.TextColor3 = COLORS.Text
CBtn.Font = Enum.Font.GothamBold
CBtn.TextSize = 12
CBtn.Parent = PageCompile
Corner(CBtn, 5); Gradient(CBtn, COLORS.DarkRed, COLORS.BrightRed, 0)

local CBtnRun = Instance.new("TextButton")
CBtnRun.Size = UDim2.new(0, 120, 0, 28)
CBtnRun.Position = UDim2.new(0, 164, 0, 90)
CBtnRun.BackgroundColor3 = COLORS.DeepRed
CBtnRun.Text = "ЗАПУСТИТЬ"
CBtnRun.TextColor3 = COLORS.Text
CBtnRun.Font = Enum.Font.GothamBold
CBtnRun.TextSize = 12
CBtnRun.Parent = PageCompile
Corner(CBtnRun, 5); Stroke(CBtnRun, COLORS.Red, 1)

local COut = Instance.new("TextBox")
COut.Size = UDim2.new(1, -16, 1, -126)
COut.Position = UDim2.new(0, 8, 0, 122)
COut.BackgroundColor3 = COLORS.Black
COut.TextColor3 = COLORS.Text
COut.Font = Enum.Font.Code
COut.TextSize = 11
COut.TextWrapped = true
COut.TextXAlignment = Enum.TextXAlignment.Left
COut.TextYAlignment = Enum.TextYAlignment.Top
COut.TextEditable = false
COut.Text = "-- BCL Компилятор готов."
COut.Parent = PageCompile
Corner(COut, 5); Stroke(COut, COLORS.Red, 1)

CBtn.MouseButton1Click:Connect(function()
    local src = CIn.Text
    if src == "" then COut.Text = "-- Пустой ввод." return end
    local bc, err = Compiler.Compile(src)
    if bc then
        COut.Text = string.format("-- Компиляция успешна.\n-- Байткод: %d байт.\n-- Первые 48 байт (hex):\n%s", #bc, (bc:sub(1,48):gsub(".", function(c) return string.format("%02X ", c:byte()) end)))
    else
        COut.Text = "-- Ошибка: " .. tostring(err)
    end
end)

CBtnRun.MouseButton1Click:Connect(function()
    local res, err = Compiler.Run(CIn.Text)
    if err then COut.Text = "-- Ошибка выполнения: " .. tostring(err)
    else COut.Text = "-- Выполнено. Результат: " .. tostring(res) end
end)

-- Decompiler page
local DIn = Instance.new("TextBox")
DIn.Size = UDim2.new(1, -16, 0, 80)
DIn.Position = UDim2.new(0, 8, 0, 4)
DIn.BackgroundColor3 = COLORS.Black
DIn.TextColor3 = COLORS.Text
DIn.PlaceholderText = 'Вставьте loadstring("...")...'
DIn.PlaceholderColor3 = COLORS.SubText
DIn.Font = Enum.Font.Code
DIn.TextSize = 12
DIn.TextWrapped = true
DIn.TextXAlignment = Enum.TextXAlignment.Left
DIn.TextYAlignment = Enum.TextYAlignment.Top
DIn.ClearTextOnFocus = false
DIn.Parent = PageDecomp
Corner(DIn, 5); Stroke(DIn, COLORS.Red, 1)

local DBtn = Instance.new("TextButton")
DBtn.Size = UDim2.new(0, 180, 0, 28)
DBtn.Position = UDim2.new(0, 8, 0, 90)
DBtn.BackgroundColor3 = COLORS.Red
DBtn.Text = "ДЕКОМПИЛИРОВАТЬ"
DBtn.TextColor3 = COLORS.Text
DBtn.Font = Enum.Font.GothamBold
DBtn.TextSize = 12
DBtn.Parent = PageDecomp
Corner(DBtn, 5); Gradient(DBtn, COLORS.DarkRed, COLORS.BrightRed, 0)

local DOut = Instance.new("TextBox")
DOut.Size = UDim2.new(1, -16, 1, -126)
DOut.Position = UDim2.new(0, 8, 0, 122)
DOut.BackgroundColor3 = COLORS.Black
DOut.TextColor3 = COLORS.Text
DOut.Font = Enum.Font.Code
DOut.TextSize = 11
DOut.TextWrapped = true
DOut.TextXAlignment = Enum.TextXAlignment.Left
DOut.TextYAlignment = Enum.TextYAlignment.Top
DOut.TextEditable = false
DOut.Text = "-- BCL Декомпилятор готов."
DOut.Parent = PageDecomp
Corner(DOut, 5); Stroke(DOut, COLORS.Red, 1)

DBtn.MouseButton1Click:Connect(function()
    local code = DIn.Text
    if code == "" then DOut.Text = "-- Пустой ввод." return end
    if AntiLuarmor.Detect(code) then
        DOut.Text = "-- ВНИМАНИЕ: обнаружен Luarmor.\n-- Вы точно хотите декомпилировать? Luarmor — это мощь.\n"
        task.wait(1.2)
    end
    DOut.Text = "-- Декомпиляция...\n"
    task.wait(0.3)
    DOut.Text = Decompiler.Try(code)
end)

-- Tools page
local TIn = Instance.new("TextBox")
TIn.Size = UDim2.new(1, -16, 0, 70)
TIn.Position = UDim2.new(0, 8, 0, 4)
TIn.BackgroundColor3 = COLORS.Black
TIn.TextColor3 = COLORS.Text
TIn.PlaceholderText = "Код для обфускации..."
TIn.PlaceholderColor3 = COLORS.SubText
TIn.Font = Enum.Font.Code
TIn.TextSize = 12
TIn.TextWrapped = true
TIn.TextXAlignment = Enum.TextXAlignment.Left
TIn.TextYAlignment = Enum.TextYAlignment.Top
TIn.ClearTextOnFocus = false
TIn.Parent = PageTools
Corner(TIn, 5); Stroke(TIn, COLORS.Red, 1)

local TObf1 = Instance.new("TextButton")
TObf1.Size = UDim2.new(0, 120, 0, 26)
TObf1.Position = UDim2.new(0, 8, 0, 80)
TObf1.BackgroundColor3 = COLORS.Red
TObf1.Text = "Обфускация L1"
TObf1.TextColor3 = COLORS.Text
TObf1.Font = Enum.Font.GothamBold
TObf1.TextSize = 11
TObf1.Parent = PageTools
Corner(TObf1, 5); Gradient(TObf1, COLO
