--[[
    BazCrackLua (BCL)
    Version: 1.0.1
    Changelog:
      - Fixed Info tab (real player profile, executor detection, function count)
      - Added sidebar navigation with custom vector icons
      - Default language: English
      - Improved compiler (multiple dump backends)
      - Improved decompiler (auto-detect loadstring / bytecode / hex)
      - Fixed SafeDump crash on executors without string.dump
--]]

local CONFIG = { Version = "1.0.1" }

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
-- VECTOR ICONS (draw with Frame)
--========================================================
local Icons = {}

local function IconBase(parent)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 20, 0, 20)
    f.BackgroundTransparency = 1
    f.Parent = parent
    return f
end

Icons.compile = function(parent)
    local f = IconBase(parent)
    local l = Instance.new("Frame"); l.Size = UDim2.new(0, 3, 0, 14); l.Position = UDim2.new(0.2, 0, 0.15, 0); l.BackgroundColor3 = COLORS.BrightRed; l.BorderSizePixel = 0; l.Parent = f
    local r = Instance.new("Frame"); r.Size = UDim2.new(0, 3, 0, 14); r.Position = UDim2.new(0.6, 0, 0.15, 0); r.BackgroundColor3 = COLORS.BrightRed; r.BorderSizePixel = 0; r.Parent = f
    local t = Instance.new("Frame"); t.Size = UDim2.new(0, 8, 0, 3); t.Position = UDim2.new(0.3, 0, 0.5, 0); t.BackgroundColor3 = COLORS.BrightRed; t.BorderSizePixel = 0; t.Parent = f
    return f
end

Icons.decompile = function(parent)
    local f = IconBase(parent)
    local t = Instance.new("Frame"); t.Size = UDim2.new(0, 8, 0, 3); t.Position = UDim2.new(0.3, 0, 0.5, 0); t.BackgroundColor3 = COLORS.BrightRed; t.BorderSizePixel = 0; t.Parent = f
    local l = Instance.new("Frame"); l.Size = UDim2.new(0, 3, 0, 14); l.Position = UDim2.new(0.2, 0, 0.15, 0); l.BackgroundColor3 = COLORS.BrightRed; l.BorderSizePixel = 0; l.Parent = f
    local r = Instance.new("Frame"); r.Size = UDim2.new(0, 3, 0, 14); r.Position = UDim2.new(0.6, 0, 0.15, 0); r.BackgroundColor3 = COLORS.BrightRed; r.BorderSizePixel = 0; r.Parent = f
    return f
end

Icons.tools = function(parent)
    local f = IconBase(parent)
    local h = Instance.new("Frame"); h.Size = UDim2.new(0, 3, 0, 12); h.Position = UDim2.new(0.45, 0, 0.35, 0); h.BackgroundColor3 = COLORS.BrightRed; h.BorderSizePixel = 0; h.Parent = f
    local head = Instance.new("Frame"); head.Size = UDim2.new(0, 12, 0, 4); head.Position = UDim2.new(0.2, 0, 0.15, 0); head.BackgroundColor3 = COLORS.BrightRed; head.BorderSizePixel = 0; head.Parent = f
    return f
end

Icons.info = function(parent)
    local f = IconBase(parent)
    local c = Instance.new("Frame"); c.Size = UDim2.new(0, 14, 0, 14); c.Position = UDim2.new(0.15, 0, 0.15, 0); c.BackgroundTransparency = 1; c.Parent = f
    local cs = Instance.new("UIStroke"); cs.Color = COLORS.BrightRed; cs.Thickness = 2; cs.Parent = c
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = c
    local dot = Instance.new("Frame"); dot.Size = UDim2.new(0, 3, 0, 3); dot.Position = UDim2.new(0.42, 0, 0.25, 0); dot.BackgroundColor3 = COLORS.BrightRed; dot.BorderSizePixel = 0; dot.Parent = f
    local cc2 = Instance.new("UICorner"); cc2.CornerRadius = UDim.new(1, 0); cc2.Parent = dot
    local stem = Instance.new("Frame"); stem.Size = UDim2.new(0, 3, 0, 6); stem.Position = UDim2.new(0.42, 0, 0.5, 0); stem.BackgroundColor3 = COLORS.BrightRed; stem.BorderSizePixel = 0; stem.Parent = f
    return f
end

--========================================================
-- EXECUTOR + FUNCTIONS
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
    if type(identifyexecutor) == "function" then
        local ok, n = pcall(identifyexecutor)
        if ok and n and n ~= "" then return tostring(n) end
    end
    if type(getexecutorname) == "function" then
        local ok, n = pcall(getexecutorname)
        if ok and n and n ~= "" then return tostring(n) end
    end
    local env = GetEnv()
    local signatures = {
        { name = "Synapse X",   check = function() return rawget(env, "syn") ~= nil end },
        { name = "Script-Ware", check = function() return rawget(env, "ScriptWare") ~= nil or rawget(env, "SW") ~= nil end },
        { name = "Krnl",        check = function() return rawget(env, "KRNL_LOADED") ~= nil end },
        { name = "Fluxus",      check = function() return rawget(env, "fluxus") ~= nil end },
        { name = "Solara",      check = function() return rawget(env, "Solara") ~= nil end },
        { name = "Wave",        check = function() return rawget(env, "Wave") ~= nil end },
        { name = "Delta",       check = function() return rawget(env, "Delta") ~= nil end },
        { name = "AWP",         check = function() return rawget(env, "AWP") ~= nil end },
        { name = "Hydrogen",    check = function() return rawget(env, "Hydrogen") ~= nil end },
        { name = "SirHurt",     check = function() return rawget(env, "is_sirhurt_closure") ~= nil end },
        { name = "Sentinel",    check = function() return rawget(env, "secure_load") ~= nil end },
        { name = "Xeno",        check = function() return rawget(env, "Xeno") ~= nil end },
    }
    for _, sig in ipairs(signatures) do
        local ok, res = pcall(sig.check)
        if ok and res then return sig.name end
    end
    if type(request) == "function" or type(http_request) == "function" then
        return "Unknown (HTTP API)"
    end
    return "Unknown"
end

local function HasGlobal(name)
    local env = GetEnv()
    if env[name] ~= nil then return true end
    if _G[name] ~= nil then return true end
    local ok, v = pcall(function() return rawget(env, name) end)
    if ok and v ~= nil then return true end
    return false
end

local function CountFunctions()
    local checks = {
        "loadstring","getgenv","getfenv","setfenv","getsenv","gettenv",
        "setclipboard","toclipboard","writefile","readfile","isfile","isfolder",
        "makefolder","delfile","listfiles","HttpGet","request","http_request",
        "hookfunction","hookmetamethod","getrawmetatable","setreadonly",
        "getnamecallmethod","checkcaller","getconnections","firesignal",
        "firetouchinterest","getgc","getinstances","getnilinstances",
        "getloadedmodules","getupvalues","getconstants","setupvalue",
        "queue_on_teleport","setfpscap","identifyexecutor","getexecutorname",
        "getscriptbytecode","getcustomasset","mousemoverel","mouse1click",
        "keypress","keyrelease","decompile","dumpstring","gethui","protectgui",
        "cloneref","compareinstances",
    }
    local loaded, total = 0, #checks
    local missing = {}
    for _, name in ipairs(checks) do
        if HasGlobal(name) then loaded = loaded + 1
        else table.insert(missing, name) end
    end
    return loaded, total, missing
end

local function Evaluate(loaded, total)
    if total == 0 then return 0, "F — No data", COLORS.BrightRed end
    local pct = math.floor((loaded / total) * 100)
    local grade, color
    if pct >= 95 then grade, color = "S — Fully functional", COLORS.Green
    elseif pct >= 80 then grade, color = "A — Excellent executor", COLORS.Green
    elseif pct >= 60 then grade, color = "B — Good executor", COLORS.Yellow
    elseif pct >= 40 then grade, color = "C — Average executor", COLORS.Yellow
    elseif pct >= 20 then grade, color = "D — Weak executor", COLORS.BrightRed
    else grade, color = "F — Unsupported executor", COLORS.BrightRed end
    return pct, grade, color
end

--========================================================
-- COMPILER / DECOMPILER (improved)
--========================================================
local function SafeDump(fn)
    local backends = {
        function() if type(string.dump) == "function" then return string.dump(fn) end end,
        function() if type(dumpstring) == "function" then return dumpstring(fn) end end,
        function() if type(getscriptbytecode) == "function" then return getscriptbytecode(fn) end end,
    }
    for _, fnc in ipairs(backends) do
        local ok, bc = pcall(fnc)
        if ok and bc and type(bc) == "string" then return bc end
    end
    return nil, "no dump backend available"
end

local Compiler = {}
function Compiler.Compile(src)
    if type(loadstring) ~= "function" and type(load) ~= "function" then
        return nil, "loadstring / load unavailable"
    end
    local loader = loadstring or load
    local fn, err = loader(src, "=BCL")
    if not fn then return nil, "compile error: " .. tostring(err) end
    local bc, derr = SafeDump(fn)
    if not bc then return nil, derr end
    return bc
end
function Compiler.Run(src)
    local loader = loadstring or load
    if type(loader) ~= "function" then return nil, "loadstring unavailable" end
    local fn, err = loader(src)
    if not fn then return nil, err end
    local ok, res = pcall(fn)
    if not ok then return nil, res end
    return res
end

local Decompiler = {}
function Decompiler.FromLoadstring(code)
    local inner = code:match('loadstring%s*%(%s*["\'](.-)["\']%s*%)')
            or code:match('load%s*%(%s*["\'](.-)["\']%s*%)')
    return inner or code
end
function Decompiler.Try(code)
    local extracted = Decompiler.FromLoadstring(code)
    local loader = loadstring or load
    if type(loader) ~= "function" then
        return "-- BCL: loadstring unavailable.\n-- Fragment:\n" .. extracted
    end
    local fn = loader(extracted)
    if not fn then
        return "-- BCL: failed to load. Possibly bytecode or protected.\n-- Fragment:\n" .. extracted
    end
    local bc, derr = SafeDump(fn)
    if not bc then
        return "-- BCL: dump unavailable (" .. tostring(derr) .. ").\n-- Extracted code:\n" .. extracted
    end
    return "-- BCL: bytecode acquired (" .. #bc .. " bytes).\n-- Full decompilation requires external engine.\n\n" .. extracted
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
-- PLAYER PROFILE
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
Main.Size = UDim2.new(0, 520, 0, 360)
Main.Position = UDim2.new(0.5, -260, 0.5, -180)
Main.BackgroundColor3 = COLORS.Black
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Gradient(Main, COLORS.Black, COLORS.DeepRed, 135)
Corner(Main, 10)
local mainStroke = Stroke(Main, COLORS.BrightRed, 1.5)
Main.Active = true
Main.Draggable = true
AnimateIn(Main, UDim2.new(0.5, -260, 0.5, -180), 0.45)

-- Title
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

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 56, 1, -34)
Sidebar.Position = UDim2.new(0, 0, 0, 34)
Sidebar.BackgroundColor3 = COLORS.Black
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main
Gradient(Sidebar, COLORS.Black, COLORS.DeepRed, 90)

local Pages = {}
local SideButtons = {}

local function MakeSideTab(name, label, idx, iconFn)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 44)
    btn.Position = UDim2.new(0, 4, 0, 4 + (idx-1)*50)
    btn.BackgroundColor3 = COLORS.DeepRed
    btn.Text = ""
    btn.Parent = Sidebar
    Corner(btn, 6); Stroke(btn, COLORS.DarkRed, 1)

    local ico = iconFn(btn)
    ico.Position = UDim2.new(0.5, -10, 0, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 12)
    lbl.Position = UDim2.new(0, 0, 1, -14)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = COLORS.SubText
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.Parent = btn

    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, -72, 1, -46)
    page.Position = UDim2.new(0, 64, 0, 42)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = Main
    Pages[name] = page
    SideButtons[name] = btn

    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        page.Visible = true
        for _, b in pairs(SideButtons) do b.BackgroundColor3 = COLORS.DeepRed end
        btn.BackgroundColor3 = COLORS.DarkRed
    end)
    return btn, page
end

local TabCompile, PageCompile = MakeSideTab("compile", "COMP", 1, Icons.compile)
local TabDecomp,  PageDecomp  = MakeSideTab("decomp",  "DECOMP", 2, Icons.decompile)
local TabTools,   PageTools   = MakeSideTab("tools",   "TOOLS",  3, Icons.tools)
local TabInfo,    PageInfo    = MakeSideTab("info",    "INFO",   4, Icons.info)

--========================================================
-- COMPILER PAGE
--========================================================
local CIn = Instance.new("TextBox")
CIn.Size = UDim2.new(1, -16, 0, 90)
CIn.Position = UDim2.new(0, 8, 0, 4)
CIn.BackgroundColor3 = COLORS.Black
CIn.TextColor3 = COLORS.Text
CIn.PlaceholderText = "Enter Lua code..."
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
CBtn.Size = UDim2.new(0, 160, 0, 28)
CBtn.Position = UDim2.new(0, 8, 0, 100)
CBtn.BackgroundColor3 = COLORS.Red
CBtn.Text = "COMPILE"
CBtn.TextColor3 = COLORS.Text
CBtn.Font = Enum.Font.GothamBold
CBtn.TextSize = 12
CBtn.Parent = PageCompile
Corner(CBtn, 5); Gradient(CBtn, COLORS.DarkRed, COLORS.BrightRed, 0)

local CBtnRun = Instance.new("TextButton")
CBtnRun.Size = UDim2.new(0, 130, 0, 28)
CBtnRun.Position = UDim2.new(0, 174, 0, 100)
CBtnRun.BackgroundColor3 = COLORS.DeepRed
CBtnRun.Text = "RUN"
CBtnRun.TextColor3 = COLORS.Text
CBtnRun.Font = Enum.Font.GothamBold
CBtnRun.TextSize = 12
CBtnRun.Parent = PageCompile
Corner(CBtnRun, 5); Stroke(CBtnRun, COLORS.Red, 1)

local COut = Instance.new("TextBox")
COut.Size = UDim2.new(1, -16, 1, -140)
COut.Position = UDim2.new(0, 8, 0, 136)
COut.BackgroundColor3 = COLORS.Black
COut.TextColor3 = COLORS.Text
COut.Font = Enum.Font.Code
COut.TextSize = 11
COut.TextWrapped = true
COut.TextXAlignment = Enum.TextXAlignment.Left
COut.TextYAlignment = Enum.TextYAlignment.Top
COut.TextEditable = false
COut.Text = "-- BCL Compiler ready."
COut.Parent = PageCompile
Corner(COut, 5); Stroke(COut, COLORS.Red, 1)

CBtn.MouseButton1Click:Connect(function()
    local src = CIn.Text
    if src == "" then COut.Text = "-- Empty input." return end
    local bc, err = Compiler.Compile(src)
    if bc then
        COut.Text = string.format("-- Compilation OK.\n-- Bytecode: %d bytes.\n-- First 64 bytes (hex):\n%s", #bc, (bc:sub(1,64):gsub(".", function(c) return string.format("%02X ", c:byte()) end)))
    else
        COut.Text = "-- Error: " .. tostring(err)
    end
end)

CBtnRun.MouseButton1Click:Connect(function()
    local res, err = Compiler.Run(CIn.Text)
    if err then COut.Text = "-- Runtime error: " .. tostring(err)
    else COut.Text = "-- Executed. Result: " .. tostring(res) end
end)

--========================================================
-- DECOMPILER PAGE
--========================================================
local DIn = Instance.new("TextBox")
DIn.Size = UDim2.new(1, -16, 0, 90)
DIn.Position = UDim2.new(0, 8, 0, 4)
DIn.BackgroundColor3 = COLORS.Black
DIn.TextColor3 = COLORS.Text
DIn.PlaceholderText = 'Paste loadstring("...") or bytecode...'
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
DBtn.Position = UDim2.new(0, 8, 0, 100)
DBtn.BackgroundColor3 = COLORS.Red
DBtn.Text = "DECOMPILE"
DBtn.TextColor3 = COLORS.Text
DBtn.Font = Enum.Font.GothamBold
DBtn.TextSize = 12
DBtn.Parent = PageDecomp
Corner(DBtn, 5); Gradient(DBtn, COLORS.DarkRed, COLORS.BrightRed, 0)

local DOut = Instance.new("TextBox")
DOut.Size = UDim2.new(1, -16, 1, -140)
DOut.Position = UDim2.new(0, 8, 0, 136)
DOut.BackgroundColor3 = COLORS.Black
DOut.TextColor3 = COLORS.Text
DOut.Font = Enum.Font.Code
DOut.TextSize = 11
DOut.TextWrapped = true
DOut.TextXAlignment = Enum.TextXAlignment.Left
DOut.TextYAlignment = Enum.TextYAlignment.Top
DOut.TextEditable = false
DOut.Text = "-- BCL Decompiler ready."
DOut.Parent = PageDecomp
Corner(DOut, 5); Stroke(DOut, COLORS.Red, 1)

DBtn.MouseButton1Click:Connect(function()
    local code = DIn.Text
    if code == "" then DOut.Text = "-- Empty input." return end
    if AntiLuarmor.Detect(code) then
        DOut.Text = "-- WARNING: Luarmor detected.\n-- Are you sure you want to decompile? Luarmor is power.\n"
        task.wait(1.2)
    end
    DOut.Text = "-- Decompiling...\n"
    task.wait(0.3)
    DOut.Text = Decompiler.Try(code)
end)

--========================================================
-- TOOLS PAGE
--========================================================
local TIn = Instance.new("TextBox")
TIn.Size = UDim2.new(1, -16, 0, 70)
TIn.Position = UDim2.new(0, 8, 0, 4)
TIn.BackgroundColor3 = COLORS.Black
TIn.TextColor3 = COLORS.Text
TIn.PlaceholderText = "Code to obfuscate..."
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
TObf1.Size = UDim2.new(0, 130, 0, 26)
TObf1.Position = UDim2.new(0, 8, 0, 80)
TObf1.BackgroundColor3 = COLORS.Red
TObf1.Text = "Obfuscate L1"
TObf1.TextColor3 = COLORS.Text
TObf1.Font = Enum.Font.GothamBold
TObf1.TextSize = 11
TObf1.Parent = PageTools
Corner(TObf1, 5); Gradient(TObf1, COLORS.DarkRed, COLORS.BrightRed, 0)

local TObf2 = Instance.new("TextButton")
TObf2.Size = UDim2.new(0, 130, 0, 26)
TObf2.Position = UDim2.new(0, 144, 0, 80)
TObf2.BackgroundColor3 = COLORS.Red
TObf2.Text = "Obfuscate L2"
TObf2.TextColor3 = COLORS.Text
TObf2.Font = Enum.Font.GothamBold
TObf2.TextSize = 11
TObf2.Parent = PageTools
Corner(TObf2, 5); Gradient(TObf2, COLORS.DarkRed, COLORS.BrightRed, 0)

local TCopy = Instance.new("TextButton")
TCopy.Size = UDim2.new(0, 130, 0, 26)
TCopy.Position = UDim2.new(0, 280, 0, 80)
TCopy.BackgroundColor3 = COLORS.DeepRed
TCopy.Text = "Copy"
TCopy.TextColor3 = COLORS.Text
TCopy.Font = Enum.Font.GothamBold
TCopy.TextSize = 11
TCopy.Parent = PageTools
Corner(TCopy, 5); Stroke(TCopy, COLORS.Red, 1)

local TOut = Instance.new("TextBox")
TOut.Size = UDim2.new(1, -16, 1, -120)
TOut.Position = UDim2.new(0, 8, 0, 116)
TOut.BackgroundColor3 = COLORS.Black
TOut.TextColor3 = COLORS.Text
TOut.Font = Enum.Font.Code
TOut.TextSize = 11
TOut.TextWrapped = true
TOut.TextXAlignment = Enum.TextXAlignment.Left
TOut.TextYAlignment = Enum.TextYAlignment.Top
TOut.TextEditable = false
TOut.Text = "-- BCL Tools ready."
TOut.Parent = PageTools
Corner(TOut, 5); Stroke(TOut, COLORS.Red, 1)

TObf1.MouseButton1Click:Connect(function() TOut.Text = Obfuscator.Run(TIn.Text, 1) end)
TObf2.MouseButton1Click:Connect(function() TOut.Text = Obfuscator.Run(TIn.Text, 2) end)
TCopy.MouseButton1Click:Connect(function()
    if type(setclipboard) == "function" then
        pcall(setclipboard, TOut.Text)
        TOut.Text = TOut.Text .. "\n-- Copied."
    else
        TOut.Text = TOut.Text .. "\n-- setclipboard unavailable."
    end
end)

--========================================================
-- INFO PAGE
--========================================================
local ProfileCard = Instance.new("Frame")
ProfileCard.Size = UDim2.new(1, 0, 0, 80)
ProfileCard.Position = UDim2.new(0, 0, 0, 0)
ProfileCard.BackgroundColor3 = COLORS.Black
ProfileCard.BorderSizePixel = 0
ProfileCard.Parent = PageInfo
Corner(ProfileCard, 6); Stroke(ProfileCard, COLORS.Red, 1)
Gradient(ProfileCard, COLORS.Black, COLORS.DeepRed, 135)

local BigAvatar = Instance.new("ImageLabel")
BigAvatar.Size = UDim2.new(0, 60, 0, 60)
BigAvatar.Position = UDim2.new(0, 10, 0, 10)
BigAvatar.BackgroundColor3 = COLORS.Black
BigAvatar.Image = ""
BigAvatar.Parent = ProfileCard
Corner(BigAvatar, 30)
local bigStroke = Stroke(BigAvatar, COLORS.BrightRed, 2)
Pulse(bigStroke, 1, 3.5, 1.5)
local BGL = Instance.new("TextLabel")
BGL.Size = UDim2.new(1,0,1,0); BGL.BackgroundTransparency = 1
BGL.Text = "?"; BGL.TextColor3 = COLORS.BrightRed
BGL.Font = Enum.Font.GothamBold; BGL.TextSize = 28; BGL.Parent = BigAvatar

local PName = Instance.new("TextLabel")
PName.Size = UDim2.new(1, -84, 0, 20)
PName.Position = UDim2.new(0, 80, 0, 10)
PName.BackgroundTransparency = 1
PName.Text = "—"
PName.TextColor3 = COLORS.Text
PName.Font = Enum.Font.GothamBold
PName.TextSize = 16
PName.TextXAlignment = Enum.TextXAlignment.Left
PName.Parent = ProfileCard

local PSub = Instance.new("TextLabel")
PSub.Size = UDim2.new(1, -84, 0, 18)
PSub.Position = UDim2.new(0, 80, 0, 32)
PSub.BackgroundTransparency = 1
PSub.Text = "—"
PSub.TextColor3 = COLORS.SubText
PSub.Font = Enum.Font.Gotham
PSub.TextSize = 12
PSub.TextXAlignment = Enum.TextXAlignment.Left
PSub.Parent = ProfileCard

local PId = Instance.new("TextLabel")
PId.Size = UDim2.new(1, -84, 0, 18)
PId.Position = UDim2.new(0, 80, 0, 50)
PId.BackgroundTransparency = 1
PId.Text = "—"
PId.TextColor3 = COLORS.SubText
PId.Font = Enum.Font.Gotham
PId.TextSize = 11
PId.TextXAlignment = Enum.TextXAlignment.Left
PId.Parent = ProfileCard

local ExecCard = Instance.new("Frame")
ExecCard.Size = UDim2.new(1, 0, 0, 32)
ExecCard.Position = UDim2.new(0, 0, 0, 86)
ExecCard.BackgroundColor3 = COLORS.Black
ExecCard.BorderSizePixel = 0
ExecCard.Parent = PageInfo
Corner(ExecCard, 6); Stroke(ExecCard, COLORS.Red, 1)

local ExecLabel = Instance.new("TextLabel")
ExecLabel.Size = UDim2.new(1, -16, 1, 0)
ExecLabel.Position = UDim2.new(0, 8, 0, 0)
ExecLabel.BackgroundTransparency = 1
ExecLabel.Text = "Executor: —"
ExecLabel.TextColor3 = COLORS.Text
ExecLabel.Font = Enum.Font.Gotham
ExecLabel.TextSize = 12
ExecLabel.TextXAlignment = Enum.TextXAlignment.Left
ExecLabel.Parent = ExecCard

local FuncCard = Instance.new("Frame")
FuncCard.Size = UDim2.new(1, 0, 0, 66)
FuncCard.Position = UDim2.new(0, 0, 0, 124)
FuncCard.BackgroundColor3 = COLORS.Black
FuncCard.BorderSizePixel = 0
FuncCard.Parent = PageInfo
Corner(FuncCard, 6); Stroke(FuncCard, COLORS.Red, 1)

local FuncLabel = Instance.new("TextLabel")
FuncLabel.Size = UDim2.new(1, -16, 0, 20)
FuncLabel.Position = UDim2.new(0, 8, 0, 4)
FuncLabel.BackgroundTransparency = 1
FuncLabel.Text = "Functions loaded: —"
FuncLabel.TextColor3 = COLORS.Text
FuncLabel.Font = Enum.Font.Gotham
FuncLabel.TextSize = 12
FuncLabel.TextXAlignment = Enum.TextXAlignment.Left
FuncLabel.Parent = FuncCard

local BarBg = Instance.new("Frame")
BarBg.Size = UDim2.new(1, -16, 0, 12)
BarBg.Position = UDim2.new(0, 8, 0, 26)
BarBg.BackgroundColor3 = COLORS.DeepRed
BarBg.BorderSizePixel = 0
BarBg.Parent = FuncCard
Corner(BarBg, 6)

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = COLORS.BrightRed
BarFill.BorderSizePixel = 0
BarFill.Parent = BarBg
Corner(BarFill, 6)
Gradient(BarFill, COLORS.Red, COLORS.BrightRed, 0)

local GradeLabel = Instance.new("TextLabel")
GradeLabel.Size = UDim2.new(1, -16, 0, 18)
GradeLabel.Position = UDim2.new(0, 8, 0, 42)
GradeLabel.BackgroundTransparency = 1
GradeLabel.Text = "Grade: —"
GradeLabel.TextColor3 = COLORS.SubText
GradeLabel.Font = Enum.Font.GothamBold
GradeLabel.TextSize = 11
GradeLabel.TextXAlignment = Enum.TextXAlignment.Left
GradeLabel.Parent = FuncCard

local Uptime = Instance.new("TextLabel")
Uptime.Size = UDim2.new(1, -16, 0, 16)
Uptime.Position = UDim2.new(0, 0, 0, 194)
Uptime.BackgroundTransparency = 1
Uptime.Text = "Session: 00:00"
Uptime.TextColor3 = COLORS.SubText
Uptime.Font = Enum.Font.Code
Uptime.TextSize = 11
Uptime.TextXAlignment = Enum.TextXAlignment.Left
Uptime.Parent = PageInfo

task.spawn(function()
    while ScreenGui.Parent do
        local s = os.time() - STATE.StartTime
        Uptime.Text = string.format("Session: %02d:%02d", math.floor(s/60), s%60)
        task.wait(1)
    end
end)

local function RefreshInfo()
    local name, display, userId, avatar = GetPlayerProfile()
    PName.Text = display .. " (@" .. name .. ")"
    PSub.Text = "UserId: " .. tostring(userId)
    PId.Text = "BCL v" .. CONFIG.Version .. " • Status: active"
    PId.TextColor3 = COLORS.Green
    if avatar then
        BigAvatar.Image = avatar
        BGL.Text = ""
    else
        BGL.Text = string.upper(string.sub(name, 1, 1))
    end

    ExecLabel.Text = "Executor: " .. DetectExecutor()

    local loaded, total, missing = CountFunctions()
    FuncLabel.Text = string.format("Functions loaded: %d / %d", loaded, total)
    local pct, grade, color = Evaluate(loaded, total)
    GradeLabel.Text = string.format("Grade: %d%% — %s", pct, grade)
    GradeLabel.TextColor3 = color

    local t0 = tick()
    task.spawn(function()
        while tick() - t0 < 0.6 do
            local a = (tick() - t0) / 0.6
            local e = 1 - (1 - a)^2
            BarFill.Size = UDim2.new((pct/100) * e, 0, 1, 0)
            task.wait(0.02)
        end
        BarFill.Size = UDim2.new(pct/100, 0, 1, 0)
    end)

    print("[BCL] Functions loaded:", loaded, "/", total)
    if #missing > 0 then
        print("[BCL] Missing: " .. table.concat(missing, ", "))
    end
end

RefreshInfo()
Breathe(mainStroke, COLORS.BrightRed, COLORS.DarkRed, 3)
TabCompile.MouseButton1Click:Fire()
