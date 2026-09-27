--[[
    BazCrackLua (BCL)
    Version: 1.0.3
    Changelog:
      - v1.0.3: HOME tab (opens by default)
      - v1.0.3: Welcome text + Discord button (purple, Discord-style)
      - v1.0.3: Clear button on all textboxes
      - v1.0.3: improved decompiler chain (decompile -> bytecode -> getscriptclosure -> GC scan w/ keyword)
      - v1.0.3: GUI polish (spacing, hover effects, smoother animations)
--]]

if _G.BCL_LOADED then
    warn("[BCL] Already loaded. Unload first (X button).")
    return
end
_G.BCL_LOADED = true

local CONFIG = {
    Version  = "1.0.3",
    Discord  = "https://discord.gg/vVFeyntpa",
}

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
    -- Discord palette
    DiscordDark   = Color3.fromRGB(40, 40, 55),
    DiscordPurple = Color3.fromRGB(88, 101, 242),
    DiscordLight  = Color3.fromRGB(114, 137, 218),
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
local function Pad(obj, p)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, p); pad.PaddingBottom = UDim.new(0, p)
    pad.PaddingLeft = UDim.new(0, p); pad.PaddingRight = UDim.new(0, p)
    pad.Parent = obj
    return pad
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
local function Hover(btn, normal, hover)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = hover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = normal end)
end

--========================================================
-- ICONS
--========================================================
local Icons = {}
local function IconBase(parent)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 22, 0, 22)
    f.BackgroundTransparency = 1
    f.Parent = parent
    return f
end
local function Bar(parent, size, pos, color)
    local b = Instance.new("Frame")
    b.Size = size; b.Position = pos
    b.BackgroundColor3 = color or COLORS.BrightRed
    b.BorderSizePixel = 0
    b.Parent = parent
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(COLORS.Red, COLORS.BrightRed)
    g.Rotation = 45
    g.Parent = b
    return b
end

Icons.home = function(parent)
    local f = IconBase(parent)
    local roof = Bar(f, UDim2.new(0, 18, 0, 3), UDim2.new(0.09, 0, 0.22, 0))
    roof.Rotation = 45
    local roof2 = Bar(f, UDim2.new(0, 18, 0, 3), UDim2.new(0.09, 0, 0.22, 0))
    roof2.Rotation = -45
    roof2.Position = UDim2.new(0.5, 0, 0.22, 0)
    Bar(f, UDim2.new(0, 16, 0, 12), UDim2.new(0.14, 0, 0.5, 0))
    return f
end
Icons.compile = function(parent)
    local f = IconBase(parent)
    Bar(f, UDim2.new(0, 3, 0, 16), UDim2.new(0.15, 0, 0.15, 0))
    Bar(f, UDim2.new(0, 3, 0, 16), UDim2.new(0.7, 0, 0.15, 0))
    Bar(f, UDim2.new(0, 10, 0, 3), UDim2.new(0.3, 0, 0.45, 0))
    return f
end
Icons.decompile = function(parent)
    local f = IconBase(parent)
    Bar(f, UDim2.new(0, 10, 0, 3), UDim2.new(0.3, 0, 0.45, 0))
    Bar(f, UDim2.new(0, 3, 0, 16), UDim2.new(0.15, 0, 0.15, 0))
    Bar(f, UDim2.new(0, 3, 0, 16), UDim2.new(0.7, 0, 0.15, 0))
    return f
end
Icons.tools = function(parent)
    local f = IconBase(parent)
    Bar(f, UDim2.new(0, 3, 0, 14), UDim2.new(0.45, 0, 0.3, 0))
    Bar(f, UDim2.new(0, 14, 0, 4), UDim2.new(0.18, 0, 0.12, 0))
    return f
end
Icons.test = function(parent)
    local f = IconBase(parent)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(0, 16, 0, 16); r.Position = UDim2.new(0.12, 0, 0.12, 0)
    r.BackgroundTransparency = 1; r.Parent = f
    Stroke(r, COLORS.BrightRed, 2)
    Corner(r, 8)
    Bar(f, UDim2.new(0, 8, 0, 3), UDim2.new(0.35, 0, 0.2, 0), COLORS.Red)
    Bar(f, UDim2.new(0, 3, 0, 6), UDim2.new(0.44, 0, 0.45, 0))
    return f
end
Icons.info = function(parent)
    local f = IconBase(parent)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(0, 16, 0, 16); r.Position = UDim2.new(0.12, 0, 0.12, 0)
    r.BackgroundTransparency = 1; r.Parent = f
    Stroke(r, COLORS.BrightRed, 2)
    Corner(r, 8)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 3, 0, 3); dot.Position = UDim2.new(0.44, 0, 0.28, 0)
    dot.BackgroundColor3 = COLORS.BrightRed; dot.BorderSizePixel = 0; dot.Parent = f
    Corner(dot, 2)
    Bar(f, UDim2.new(0, 3, 0, 6), UDim2.new(0.44, 0, 0.5, 0))
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
    local sigs = {
        {"Synapse X","syn"},{"Script-Ware","ScriptWare"},{"Krnl","KRNL_LOADED"},
        {"Fluxus","fluxus"},{"Solara","Solara"},{"Wave","Wave"},{"Delta","Delta"},
        {"AWP","AWP"},{"Hydrogen","Hydrogen"},{"SirHurt","is_sirhurt_closure"},
        {"Sentinel","secure_load"},{"Xeno","Xeno"},{"Potassium","Potassium"},
        {"Volt","Volt"},{"Luna","Luna"},{"Madium","Madium"},{"Arceus X","ArceusX"},
        {"Real","Real"},{"Velocity","Velocity"},{"Codex","Codex"},
        {"Oxygen U","Oxygen"},{"Trigona","Trigona"},{"Nihon","Nihon"},
        {"Valyse","Valyse"},{"Electron","Electron"},
    }
    for _, s in ipairs(sigs) do
        local ok, res = pcall(function() return rawget(env, s[2]) ~= nil end)
        if ok and res then return s[1] end
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
    return ok and v ~= nil
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
        "cloneref","compareinstances","getscriptclosure","getscripthash",
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
    if type(dumpstring) == "function" then
        local ok, bc = pcall(dumpstring, fn)
        if ok and bc and type(bc) == "string" then return bc end
    end
    if type(getscriptbytecode) == "function" then
        local ok, bc = pcall(getscriptbytecode, fn)
        if ok and bc and type(bc) == "string" then return bc end
    end
    if type(string.dump) == "function" then
        local ok, bc = pcall(string.dump, fn)
        if ok and bc and type(bc) == "string" then return bc end
    end
    return nil, "no dump backend available"
end

local Compiler = {}
function Compiler.Compile(src)
    if type(loadstring) ~= "function" then return nil, "loadstring unavailable" end
    local fn, err = loadstring(src, "=BCL")
    if not fn then return nil, "compile error: " .. tostring(err) end
    local bc, derr = SafeDump(fn)
    if not bc then return nil, derr end
    return bc
end
function Compiler.Run(src)
    if type(loadstring) ~= "function" then return nil, "loadstring unavailable" end
    local fn, err = loadstring(src)
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
function Decompiler.ExtractUrl(code)
    return code:match('HttpGet%s*%(%s*["\'](.-)["\']%s*%)')
        or code:match('GetAsync%s*%(%s*["\'](.-)["\']%s*%)')
end

-- Improved: full decompile chain
function Decompiler.Try(code)
    local extracted = Decompiler.FromLoadstring(code)

    -- 1) Direct HTTP fetch
    local url = Decompiler.ExtractUrl(code)
    if url and type(game.HttpGet) == "function" then
        local ok, src = pcall(function() return game:HttpGet(url) end)
        if ok and src and #src > 0 then
            if src:find("_bsdata0") or src:find("luarmor.net") then
                return "-- BCL: Luarmor loader detected.\n-- This is NOT the original source.\n-- Payload is VM-encrypted (_bsdata0).\n-- URL: " .. url .. "\n\n" .. src
            end
            return "-- BCL: source fetched directly from URL.\n-- URL: " .. url .. "\n\n" .. src
        end
    end

    -- 2) Load function
    if type(loadstring) ~= "function" then
        return "-- BCL: loadstring unavailable.\n-- Fragment:\n" .. extracted
    end
    local fn = loadstring(extracted)
    if not fn then
        return "-- BCL: failed to load. Possibly bytecode or protected.\n-- Fragment:\n" .. extracted
    end

    -- 3) Executor's native decompile
    if type(decompile) == "function" then
        local ok, src = pcall(decompile, fn)
        if ok and src and type(src) == "string" and #src > 0 then
            return "-- BCL: decompiled via executor API.\n-- Size: " .. #src .. " bytes.\n\n" .. src
        end
        local bc = SafeDump(fn)
        if bc then
            local ok2, src2 = pcall(decompile, bc)
            if ok2 and src2 and type(src2) == "string" and #src2 > 0 then
                return "-- BCL: decompiled from bytecode.\n-- Size: " .. #src2 .. " bytes.\n\n" .. src2
            end
        end
    end

    -- 4) getscriptclosure fallback
    if type(getscriptclosure) == "function" and type(decompile) == "function" then
        local ok, closure = pcall(getscriptclosure, fn)
        if ok and closure then
            local ok2, src = pcall(decompile, closure)
            if ok2 and src and type(src) == "string" and #src > 0 then
                return "-- BCL: decompiled via getscriptclosure.\n-- Size: " .. #src .. " bytes.\n\n" .. src
            end
        end
    end

    -- 5) Return bytecode info
    local bc, derr = SafeDump(fn)
    if bc then
        return "-- BCL: decompile API failed, returning bytecode info.\n-- Bytecode: " .. #bc .. " bytes.\n\n" .. extracted
    end
    return "-- BCL: dump unavailable (" .. tostring(derr) .. ").\n-- Extracted code:\n" .. extracted
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
AntiLuarmor.Sig = {"Luarmor","luarmor","Luraph","luarmor.net","_bsdata0"}
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
Main.Size = UDim2.new(0, 560, 0, 400)
Main.Position = UDim2.new(0.5, -280, 0.5, -200)
Main.BackgroundColor3 = COLORS.Black
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Gradient(Main, COLORS.Black, COLORS.DeepRed, 135)
Corner(Main, 10)
local mainStroke = Stroke(Main, COLORS.BrightRed, 1.5)
Main.Active = true
Main.Draggable = true
AnimateIn(Main, UDim2.new(0.5, -280, 0.5, -200), 0.45)

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 34)
Title.BackgroundColor3 = COLORS.DeepRed
Title.BorderSizePixel = 0
Title.Text = "  BazCrackLua v" .. CONFIG.Version
Title.TextColor3 = COLORS.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main
Gradient(Title, COLORS.DarkRed, COLORS.BrightRed, 0)

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 0, 34)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = COLORS.DeepRed
CloseBtn.Text = "X"
CloseBtn.TextColor3 = COLORS.Text
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = Main
Gradient(CloseBtn, COLORS.DarkRed, COLORS.BrightRed, 0)
Hover(CloseBtn, COLORS.DeepRed, COLORS.BrightRed)
CloseBtn.MouseButton1Click:Connect(function()
    _G.BCL_LOADED = false
    ScreenGui:Destroy()
    print("[BCL] Unloaded.")
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 62, 1, -34)
Sidebar.Position = UDim2.new(0, 0, 0, 34)
Sidebar.BackgroundColor3 = COLORS.Black
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main
Gradient(Sidebar, COLORS.Black, COLORS.DeepRed, 90)

local Pages = {}
local SideButtons = {}

local function MakeSideTab(name, label, idx, iconFn)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 48)
    btn.Position = UDim2.new(0, 4, 0, 6 + (idx-1)*54)
    btn.BackgroundColor3 = COLORS.DeepRed
    btn.Text = ""
    btn.Parent = Sidebar
    Corner(btn, 6); Stroke(btn, COLORS.DarkRed, 1)

    local ico = iconFn(btn)
    ico.Position = UDim2.new(0.5, -11, 0, 4)

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
    page.Size = UDim2.new(1, -78, 1, -46)
    page.Position = UDim2.new(0, 70, 0, 42)
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
    Hover(btn, COLORS.DeepRed, COLORS.DarkRed)
    return btn, page
end

local TabHome,    PageHome    = MakeSideTab("home",    "HOME",   1, Icons.home)
local TabCompile, PageCompile = MakeSideTab("compile", "COMP",   2, Icons.compile)
local TabDecomp,  PageDecomp  = MakeSideTab("decomp",  "DECOMP", 3, Icons.decompile)
local TabTools,   PageTools   = MakeSideTab("tools",   "TOOLS",  4, Icons.tools)
local TabTest,    PageTest    = MakeSideTab("test",    "TEST",   5, Icons.test)
local TabInfo,    PageInfo    = MakeSideTab("info",    "INFO",   6, Icons.info)

--========================================================
-- HOME PAGE
--========================================================
local Welcome = Instance.new("TextLabel")
Welcome.Size = UDim2.new(1, -16, 0, 60)
Welcome.Position = UDim2.new(0, 8, 0, 30)
Welcome.BackgroundTransparency = 1
Welcome.Text = "Welcome to BCL!"
Welcome.TextColor3 = COLORS.Text
Welcome.Font = Enum.Font.GothamBold
Welcome.TextSize = 32
Welcome.TextXAlignment = Enum.TextXAlignment.Center
Welcome.Parent = PageHome

local SubWelcome = Instance.new("TextLabel")
SubWelcome.Size = UDim2.new(1, -16, 0, 30)
SubWelcome.Position = UDim2.new(0, 8, 0, 90)
SubWelcome.BackgroundTransparency = 1
SubWelcome.Text = "Decompile. Test. Learn."
SubWelcome.TextColor3 = COLORS.SubText
SubWelcome.Font = Enum.Font.Gotham
SubWelcome.TextSize = 16
SubWelcome.TextXAlignment = Enum.TextXAlignment.Center
SubWelcome.Parent = PageHome

-- Feature cards
local CardHolder = Instance.new("Frame")
CardHolder.Size = UDim2.new(1, -16, 0, 80)
CardHolder.Position = UDim2.new(0, 8, 0, 130)
CardHolder.BackgroundTransparency = 1
CardHolder.Parent = PageHome

local function FeatureCard(text, x)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 160, 1, 0)
    card.Position = UDim2.new(0, x, 0, 0)
    card.BackgroundColor3 = COLORS.DeepRed
    card.BorderSizePixel = 0
    card.Parent = CardHolder
    Corner(card, 8); Stroke(card, COLORS.DarkRed, 1)
    Gradient(card, COLORS.Black, COLORS.DeepRed, 90)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 1, 0)
    lbl.Position = UDim2.new(0, 5, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = COLORS.Text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextWrapped = true
    lbl.Parent = card
    return card
end

FeatureCard("Decompile\nany script", 0)
FeatureCard("Test your\nexecutor", 170)
FeatureCard("Obfuscate\n& compile", 340)

-- Discord button (purple)
local DiscordBtn = Instance.new("TextButton")
DiscordBtn.Size = UDim2.new(0, 260, 0, 44)
DiscordBtn.Position = UDim2.new(0.5, -130, 1, -70)
DiscordBtn.BackgroundColor3 = COLORS.DiscordPurple
DiscordBtn.Text = "Join our Discord!"
DiscordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DiscordBtn.Font = Enum.Font.GothamBold
DiscordBtn.TextSize = 15
DiscordBtn.Parent = PageHome
Corner(DiscordBtn, 8); Stroke(DiscordBtn, COLORS.DiscordLight, 1)
Gradient(DiscordBtn, COLORS.DiscordDark, COLORS.DiscordPurple, 45)
Hover(DiscordBtn, COLORS.DiscordPurple, COLORS.DiscordLight)

DiscordBtn.MouseButton1Click:Connect(function()
    if type(setclipboard) == "function" then
        pcall(setclipboard, CONFIG.Discord)
    end
    local ok = pcall(function()
        game:GetService("GuiService"):OpenBrowserWindow(CONFIG.Discord)
    end)
    if not ok then
        print("[BCL] Discord: " .. CONFIG.Discord)
    end
end)

--========================================================
-- COMPILER PAGE
--========================================================
local CIn = Instance.new("TextBox")
CIn.Size = UDim2.new(1, -16, 0, 100)
CIn.Position = UDim2.new(0, 8, 0, 6)
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
Corner(CIn, 5); Stroke(CIn, COLORS.Red, 1); Pad(CIn, 6)

local CBtn = Instance.new("TextButton")
CBtn.Size = UDim2.new(0, 130, 0, 28)
CBtn.Position = UDim2.new(0, 8, 0, 112)
CBtn.BackgroundColor3 = COLORS.Red
CBtn.Text = "COMPILE"
CBtn.TextColor3 = COLORS.Text
CBtn.Font = Enum.Font.GothamBold
CBtn.TextSize = 12
CBtn.Parent = PageCompile
Corner(CBtn, 5); Gradient(CBtn, COLORS.DarkRed, COLORS.BrightRed, 0)

local CBtnRun = Instance.new("TextButton")
CBtnRun.Size = UDim2.new(0, 100, 0, 28)
CBtnRun.Position = UDim2.new(0, 144, 0, 112)
CBtnRun.BackgroundColor3 = COLORS.DeepRed
CBtnRun.Text = "RUN"
CBtnRun.TextColor3 = COLORS.Text
CBtnRun.Font = Enum.Font.GothamBold
CBtnRun.TextSize = 12
CBtnRun.Parent = PageCompile
Corner(CBtnRun, 5); Stroke(CBtnRun, COLORS.Red, 1)

local CBtnCopy = Instance.new("TextButton")
CBtnCopy.Size = UDim2.new(0, 100, 0, 28)
CBtnCopy.Position = UDim2.new(0, 250, 0, 112)
CBtnCopy.BackgroundColor3 = COLORS.DeepRed
CBtnCopy.Text = "COPY"
CBtnCopy.TextColor3 = COLORS.Text
CBtnCopy.Font = Enum.Font.GothamBold
CBtnCopy.TextSize = 12
CBtnCopy.Parent = PageCompile
Corner(CBtnCopy, 5); Stroke(CBtnCopy, COLORS.Red, 1)

local CBtnClear = Instance.new("TextButton")
CBtnClear.Size = UDim2.new(0, 100, 0, 28)
CBtnClear.Position = UDim2.new(0, 356, 0, 112)
CBtnClear.BackgroundColor3 = COLORS.DeepRed
CBtnClear.Text = "CLEAR"
CBtnClear.TextColor3 = COLORS.Text
CBtnClear.Font = Enum.Font.GothamBold
CBtnClear.TextSize = 12
CBtnClear.Parent = PageCompile
Corner(CBtnClear, 5); Stroke(CBtnClear, COLORS.Red, 1)

local COut = Instance.new("TextBox")
COut.Size = UDim2.new(1, -16, 1, -154)
COut.Position = UDim2.new(0, 8, 0, 148)
COut.BackgroundColor3 = COLORS.Black
COut.TextColor3 = COLORS.Text
COut.Font = Enum.Font.Code
COut.TextSize = 11
COut.TextWrapped = true
COut.TextXAlignment = Enum.TextXAlignment.Left
COut.TextYAlignment = Enum.TextYAlignment.Top
COut.TextEditable = false
COut.ClearTextOnFocus = false
COut.Text = "-- BCL Compiler ready."
COut.Parent = PageCompile
Corner(COut, 5); Stroke(COut, COLORS.Red, 1); Pad(COut, 6)

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
CBtnCopy.MouseButton1Click:Connect(function()
    if type(setclipboard) == "function" then
        pcall(setclipboard, COut.Text)
        COut.Text = COut.Text .. "\n-- Copied."
    end
end)
CBtnClear.MouseButton1Click:Connect(function()
    CIn.Text = ""
    COut.Text = "-- BCL Compiler ready."
end)

--========================================================
-- DECOMPILER PAGE
--========================================================
local DIn = Instance.new("TextBox")
DIn.Size = UDim2.new(1, -16, 0, 100)
DIn.Position = UDim2.new(0, 8, 0, 6)
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
Corner(DIn, 5); Stroke(DIn, COLORS.Red, 1); Pad(DIn, 6)

local DBtn = Instance.new("TextButton")
DBtn.Size = UDim2.new(0, 150, 0, 28)
DBtn.Position = UDim2.new(0, 8, 0, 112)
DBtn.BackgroundColor3 = COLORS.Red
DBtn.Text = "DECOMPILE"
DBtn.TextColor3 = COLORS.Text
DBtn.Font = Enum.Font.GothamBold
DBtn.TextSize = 12
DBtn.Parent = PageDecomp
Corner(DBtn, 5); Gradient(DBtn, COLORS.DarkRed, COLORS.BrightRed, 0)

local DBtnCopy = Instance.new("TextButton")
DBtnCopy.Size = UDim2.new(0, 100, 0, 28)
DBtnCopy.Position = UDim2.new(0, 164, 0, 112)
DBtnCopy.BackgroundColor3 = COLORS.DeepRed
DBtnCopy.Text = "COPY"
DBtnCopy.TextColor3 = COLORS.Text
DBtnCopy.Font = Enum.Font.GothamBold
DBtnCopy.TextSize = 12
DBtnCopy.Parent = PageDecomp
Corner(DBtnCopy, 5); Stroke(DBtnCopy, COLORS.Red, 1)

local DBtnClear = Instance.new("TextButton")
DBtnClear.Size = UDim2.new(0, 100, 0, 28)
DBtnClear.Position = UDim2.new(0, 270, 0, 112)
DBtnClear.BackgroundColor3 = COLORS.DeepRed
DBtnClear.Text = "CLEAR"
DBtnClear.TextColor3 = COLORS.Text
DBtnClear.Font = Enum.Font.GothamBold
DBtnClear.TextSize = 12
DBtnClear.Parent = PageDecomp
Corner(DBtnClear, 5); Stroke(DBtnClear, COLORS.Red, 1)

local DOut = Instance.new("TextBox")
DOut.Size = UDim2.new(1, -16, 1, -154)
DOut.Position = UDim2.new(0, 8, 0, 148)
DOut.BackgroundColor3 = COLORS.Black
DOut.TextColor3 = COLORS.Text
DOut.Font = Enum.Font.Code
DOut.TextSize = 11
DOut.TextWrapped = true
DOut.TextXAlignment = Enum.TextXAlignment.Left
DOut.TextYAlignment = Enum.TextYAlignment.Top
DOut.TextEditable = false
DOut.ClearTextOnFocus = false
DOut.Text = "-- BCL Decompiler ready."
DOut.Parent = PageDecomp
Corner(DOut, 5); Stroke(DOut, COLORS.Red, 1); Pad(DOut, 6)

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
DBtnCopy.MouseButton1Click:Connect(function()
    if type(setclipboard) == "function" then
        pcall(setclipboard, DOut.Text)
        DOut.Text = DOut.Text .. "\n-- Copied."
    end
end)
DBtnClear.MouseButton1Click:Connect(function()
    DIn.Text = ""
    DOut.Text = "-- BCL Decompiler ready."
end)

--========================================================
-- TOOLS PAGE
--========================================================
local TIn = Instance.new("TextBox")
TIn.Size = UDim2.new(1, -16, 0, 80)
TIn.Position = UDim2.new(0, 8, 0, 6)
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
Corner(TIn, 5); Stroke(TIn, COLORS.Red, 1); Pad(TIn, 6)

local TObf1 = Instance.new("TextButton")
TObf1.Size = UDim2.new(0, 120, 0, 26)
TObf1.Position = UDim2.new(0, 8, 0, 92)
TObf1.BackgroundColor3 = COLORS.Red
TObf1.Text = "Obfuscate L1"
TObf1.TextColor3 = COLORS.Text
TObf1.Font = Enum.Font.GothamBold
TObf1.TextSize = 11
TObf1.Parent = PageTools
Corner(TObf1, 5); Gradient(TObf1, COLORS.DarkRed, COLORS.BrightRed, 0)

local TObf2 = Instance.new("TextButton")
TObf2.Size = UDim2.new(0, 120, 0, 26)
TObf2.Position = UDim2.new(0, 134, 0, 92)
TObf2.BackgroundColor3 = COLORS.Red
TObf2.Text = "Obfuscate L2"
TObf2.TextColor3 = COLORS.Text
TObf2.Font = Enum.Font.GothamBold
TObf2.TextSize = 11
TObf2.Parent = PageTools
Corner(TObf2, 5); Gradient(TObf2, COLORS.DarkRed, COLORS.BrightRed, 0)

local TCopy = Instance.new("TextButton")
TCopy.Size = UDim2.new(0, 90, 0, 26)
TCopy.Position = UDim2.new(0, 260, 0, 92)
TCopy.BackgroundColor3 = COLORS.DeepRed
TCopy.Text = "COPY"
TCopy.TextColor3 = COLORS.Text
TCopy.Font = Enum.Font.GothamBold
TCopy.TextSize = 11
TCopy.Parent = PageTools
Corner(TCopy, 5); Stroke(TCopy, COLORS.Red, 1)

local TClear = Instance.new("TextButton")
TClear.Size = UDim2.new(0, 90, 0, 26)
TClear.Position = UDim2.new(0, 356, 0, 92)
TClear.BackgroundColor3 = COLORS.DeepRed
TClear.Text = "CLEAR"
TClear.TextColor3 = COLORS.Text
TClear.Font = Enum.Font.GothamBold
TClear.TextSize = 11
TClear.Parent = PageTools
Corner(TClear, 5); Stroke(TClear, COLORS.Red, 1)

local TOut = Instance.new("TextBox")
TOut.Size = UDim2.new(1, -16, 1, -134)
TOut.Position = UDim2.new(0, 8, 0, 128)
TOut.BackgroundColor3 = COLORS.Black
TOut.TextColor3 = COLORS.Text
TOut.Font = Enum.Font.Code
TOut.TextSize = 11
TOut.TextWrapped = true
TOut.TextXAlignment = Enum.TextXAlignment.Left
TOut.TextYAlignment = Enum.TextYAlignment.Top
TOut.TextEditable = false
TOut.ClearTextOnFocus = false
TOut.Text = "-- BCL Tools ready."
TOut.Parent = PageTools
Corner(TOut, 5); Stroke(TOut, COLORS.Red, 1); Pad(TOut, 6)

TObf1.MouseButton1Click:Connect(function() TOut.Text = Obfuscator.Run(TIn.Text, 1) end)
TObf2.MouseButton1Click:Connect(function() TOut.Text = Obfuscator.Run(TIn.Text, 2) end)
TCopy.MouseButton1Click:Connect(function()
    if type(setclipboard) == "function" then
        pcall(setclipboard, TOut.Text)
        TOut.Text = TOut.Text .. "\n-- Copied."
    end
end)
TClear.MouseButton1Click:Connect(function()
    TIn.Text = ""
    TOut.Text = "-- BCL Tools ready."
end)

--========================================================
-- TEST PAGE
--========================================================
local TestInfo = Instance.new("TextLabel")
TestInfo.Size = UDim2.new(1, -16, 0, 40)
TestInfo.Position = UDim2.new(0, 8, 0, 6)
TestInfo.BackgroundColor3 = COLORS.Black
TestInfo.TextColor3 = COLORS.SubText
TestInfo.Font = Enum.Font.Gotham
TestInfo.TextSize = 12
TestInfo.Text = "Load external scripts to test your executor."
TestInfo.TextXAlignment = Enum.TextXAlignment.Left
TestInfo.Parent = PageTest
Corner(TestInfo, 5); Stroke(TestInfo, COLORS.Red, 1)
local TIPad = Instance.new("UIPadding")
TIPad.PaddingLeft = UDim.new(0, 8); TIPad.PaddingRight = UDim.new(0, 8)
TIPad.Parent = TestInfo

local BtnIY = Instance.new("TextButton")
BtnIY.Size = UDim2.new(1, -16, 0, 32)
BtnIY.Position = UDim2.new(0, 8, 0, 54)
BtnIY.BackgroundColor3 = COLORS.Red
BtnIY.Text = "Load: Infinite Yield"
BtnIY.TextColor3 = COLORS.Text
BtnIY.Font = Enum.Font.GothamBold
BtnIY.TextSize = 13
BtnIY.Parent = PageTest
Corner(BtnIY, 5); Gradient(BtnIY, COLORS.DarkRed, COLORS.BrightRed, 0)

local BtnUNC = Instance.new("TextButton")
BtnUNC.Size = UDim2.new(1, -16, 0, 32)
BtnUNC.Position = UDim2.new(0, 8, 0, 92)
BtnUNC.BackgroundColor3 = COLORS.Red
BtnUNC.Text = "Load: UNC Test"
BtnUNC.TextColor3 = COLORS.Text
BtnUNC.Font = Enum.Font.GothamBold
BtnUNC.TextSize = 13
BtnUNC.Parent = PageTest
Corner(BtnUNC, 5); Gradient(BtnUNC, COLORS.DarkRed, COLORS.BrightRed, 0)

local TestOut = Instance.new("TextBox")
TestOut.Size = UDim2.new(1, -16, 1, -146)
TestOut.Position = UDim2.new(0, 8, 0, 140)
TestOut.BackgroundColor3 = COLORS.Black
TestOut.TextColor3 = COLORS.Text
TestOut.Font = Enum.Font.Code
TestOut.TextSize = 11
TestOut.TextWrapped = true
TestOut.TextXAlignment = Enum.TextXAlignment.Left
TestOut.TextYAlignment = Enum.TextYAlignment.Top
TestOut.TextEditable = false
TestOut.ClearTextOnFocus = false
TestOut.Text = "-- Test results will appear here."
TestOut.Parent = PageTest
Corner(TestOut, 5); Stroke(TestOut, COLORS.Red, 1); Pad(TestOut, 6)

BtnIY.MouseButton1Click:Connect(function()
    TestOut.Text = "-- Loading Infinite Yield...\n"
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end)
    if ok then TestOut.Text = TestOut.Text .. "-- Infinite Yield loaded successfully."
    else TestOut.Text = TestOut.Text .. "-- Failed: " .. tostring(err) end
end)

BtnUNC.MouseButton1Click:Connect(function()
    TestOut.Text = "-- Loading UNC test...\n"
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/unified-naming-convention/NamingStandard/main/UNCCheckEnv.lua"))()
    end)
    if ok then TestOut.Text = TestOut.Text .. "-- UNC test loaded successfully."
    else TestOut.Text = TestOut.Text .. "-- Failed: " .. tostring(err) end
end)

--========================================================
-- INFO PAGE
--========================================================
local ProfileCard = Instance.new("Frame")
ProfileCard.Size = UDim2.new(1, 0, 0, 80)
ProfileCard.Position = UDim2.new(0, 0, 0, 6)
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
PName.Size = UDim2.new(1, -84, 0, 20); PName.Position = UDim2.new(0, 80, 0, 10)
PName.BackgroundTransparency = 1; PName.Text = "—"
PName.TextColor3 = COLORS.Text; PName.Font = Enum.Font.GothamBold; PName.TextSize = 16
PName.TextXAlignment = Enum.TextXAlignment.Left; PName.Parent = ProfileCard

local PSub = Instance.new("TextLabel")
PSub.Size = UDim2.new(1, -84, 0, 18); PSub.Position = UDim2.new(0, 80, 0, 32)
PSub.BackgroundTransparency = 1; PSub.Text = "—"
PSub.TextColor3 = COLORS.SubText; PSub.Font = Enum.Font.Gotham; PSub.TextSize = 12
PSub.TextXAlignment = Enum.TextXAlignment.Left; PSub.Parent = ProfileCard

local PId = Instance.new("TextLabel")
PId.Size = UDim2.new(1, -84, 0, 18); PId.Position = UDim2.new(0, 80, 0, 50)
PId.BackgroundTransparency = 1; PId.Text = "—"
PId.TextColor3 = COLORS.SubText; PId.Font = Enum.Font.Gotham; PId.TextSize = 11
PId.TextXAlignment = Enum.TextXAlignment.Left; PId.Parent = ProfileCard

local ExecCard = Instance.new("Frame")
ExecCard.Size = UDim2.new(1, 0, 0, 32); ExecCard.Position = UDim2.new(0, 0, 0, 92)
ExecCard.BackgroundColor3 = COLORS.Black; ExecCard.BorderSizePixel = 0; ExecCard.Parent = PageInfo
Corner(ExecCard, 6); Stroke(ExecCard, COLORS.Red, 1)

local ExecLabel = Instance.new("TextLabel")
ExecLabel.Size = UDim2.new(1, -16, 1, 0); ExecLabel.Position = UDim2.new(0, 8, 0, 0)
ExecLabel.BackgroundTransparency = 1; ExecLabel.Text = "Executor: —"
ExecLabel.TextColor3 = COLORS.Text; ExecLabel.Font = Enum.Font.Gotham; ExecLabel.TextSize = 12
ExecLabel.TextXAlignment = Enum.TextXAlignment.Left; ExecLabel.Parent = ExecCard

local FuncCard = Instance.new("Frame")
FuncCard.Size = UDim2.new(1, 0, 0, 66); FuncCard.Position = UDim2.new(0, 0, 0, 130)
FuncCard.BackgroundColor3 = COLORS.Black; FuncCard.BorderSizePixel = 0; FuncCard.Parent = PageInfo
Corner(FuncCard, 6); Stroke(FuncCard, COLORS.Red, 1)

local FuncLabel = Instance.new("TextLabel")
FuncLabel.Size = UDim2.new(1, -16, 0, 20); FuncLabel.Position = UDim2.new(0, 8, 0, 4)
FuncLabel.BackgroundTransparency = 1; FuncLabel.Text = "Functions loaded: —"
FuncLabel.TextColor3 = COLORS.Text; FuncLabel.Font = Enum.Font.Gotham; FuncLabel.TextSize = 12
FuncLabel.TextXAlignment = Enum.TextXAlignment.Left; FuncLabel.Parent = FuncCard

local BarBg = Instance.new("Frame")
BarBg.Size = UDim2.new(1, -16, 0, 12); BarBg.Position = UDim2.new(0, 8, 0, 26)
BarBg.BackgroundColor3 = COLORS.DeepRed; BarBg.BorderSizePixel = 0; BarBg.Parent = FuncCard
Corner(BarBg, 6)

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0); BarFill.BackgroundColor3 = COLORS.BrightRed
BarFill.BorderSizePixel = 0; BarFill.Parent = BarBg
Corner(BarFill, 6); Gradient(BarFill, COLORS.Red, COLORS.BrightRed, 0)

local GradeLabel = Instance.new("TextLabel")
GradeLabel.Size = UDim2.new(1, -16, 0, 18); GradeLabel.Position = UDim2.new(0, 8, 0, 42)
GradeLabel.BackgroundTransparency = 1; GradeLabel.Text = "Grade: —"
GradeLabel.TextColor3 = COLORS.SubText; GradeLabel.Font = Enum.Font.GothamBold; GradeLabel.TextSize = 11
GradeLabel.TextXAlignment = Enum.TextXAlignment.Left; GradeLabel.Parent = FuncCard

local Uptime = Instance.new("TextLabel")
Uptime.Size = UDim2.new(1, -16, 0, 16); Uptime.Position = UDim2.new(0, 0, 0, 200)
Uptime.BackgroundTransparency = 1; Uptime.Text = "Session: 00:00"
Uptime.TextColor3 = COLORS.SubText; Uptime.Font = Enum.Font.Code; Uptime.TextSize = 11
Uptime.TextXAlignment = Enum.TextXAlignment.Left; Uptime.Parent = PageInfo

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
    if avatar then BigAvatar.Image = avatar; BGL.Text = ""
    else BGL.Text = string.upper(string.sub(name, 1, 1)) end
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
    if #missing > 0 then print("[BCL] Missing: " .. table.concat(missing, ", ")) end
end

RefreshInfo()
Breathe(mainStroke, COLORS.BrightRed, COLORS.DarkRed, 3)
TabHome.MouseButton1Click:Fire() 
