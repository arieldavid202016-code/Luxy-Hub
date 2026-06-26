--- Minimal mock layer for Roblox globals so Library modules can be
--- partially loaded in a standard Lua 5.3 environment for unit testing.

local M = {}

-- Color3 mock
local Color3 = {}
Color3.__index = Color3
function Color3.new(r, g, b)
    return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, Color3)
end
function Color3.fromRGB(r, g, b)
    return Color3.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255)
end
function Color3.fromHSV(h, s, v)
    return Color3.new(h, s, v)
end
function Color3:ToHSV()
    return self.R, self.G, self.B
end
M.Color3 = Color3

-- Vector2 mock
local Vector2 = {}
Vector2.__index = Vector2
Vector2.zero = setmetatable({ X = 0, Y = 0 }, Vector2)
function Vector2.new(x, y)
    return setmetatable({ X = x or 0, Y = y or 0 }, Vector2)
end
M.Vector2 = Vector2

-- UDim2 mock
local UDim2 = {}
UDim2.__index = UDim2
function UDim2.fromOffset(x, y) return setmetatable({ X = x, Y = y, kind = "offset" }, UDim2) end
function UDim2.fromScale(x, y) return setmetatable({ X = x, Y = y, kind = "scale" }, UDim2) end
M.UDim2 = UDim2

-- Font mock
local Font = {}
Font.__index = Font
function Font.new(family, weight)
    return setmetatable({ Family = family, Weight = weight }, Font)
end
M.Font = Font

-- Enum mock
local function enum_item(name)
    return { Name = name, EnumType = "mock" }
end
M.Enum = {
    KeyCode        = { RightControl = enum_item("RightControl") },
    EasingStyle    = { Quad = enum_item("Quad") },
    EasingDirection = { Out = enum_item("Out") },
    SortOrder      = { LayoutOrder = enum_item("LayoutOrder") },
    ApplyStrokeMode = { Border = enum_item("Border") },
    ScaleType      = { Fit = enum_item("Fit") },
    UserInputType  = {
        MouseButton1 = enum_item("MouseButton1"),
        MouseButton2 = enum_item("MouseButton2"),
        Touch        = enum_item("Touch"),
        MouseMovement = enum_item("MouseMovement"),
    },
    UserInputState = {
        Begin  = enum_item("Begin"),
        Change = enum_item("Change"),
    },
    PlaybackState  = { Playing = enum_item("Playing") },
    FontWeight     = { Medium = enum_item("Medium") },
    Platform       = {
        Android = enum_item("Android"),
        IOS     = enum_item("IOS"),
    },
}

-- TweenInfo mock
local TweenInfo = {}
TweenInfo.__index = TweenInfo
function TweenInfo.new(time, style, direction)
    return setmetatable({ Time = time, EasingStyle = style, EasingDirection = direction }, TweenInfo)
end
M.TweenInfo = TweenInfo

-- Instance mock
local Instance = {}
Instance.__index = Instance
function Instance.new(className)
    local obj = setmetatable({ ClassName = className }, Instance)
    if className == "BindableEvent" then
        obj.Event = { Wait = function() return true end }
        obj.Fire  = function() end
        obj.Destroy = function() end
    end
    return obj
end
M.Instance = Instance

-- typeof mock: fallback to Lua type()
M.typeof = function(v)
    local mt = getmetatable(v)
    if mt == Color3  then return "Color3" end
    if mt == Vector2 then return "Vector2" end
    if type(v) == "table" then return "table" end
    return type(v)
end

-- Service stubs
local function service_stub(name)
    return setmetatable({}, {
        __index = function(_, k)
            if k == "IsStudio" then return function() return true end end
            if k == "TouchEnabled" then return false end
            if k == "MouseEnabled" then return true end
            if k == "GetPlatform" then return function() return nil end end
            if k == "GetPlayers" then return function() return {} end end
            if k == "GetTeams" then return function() return {} end end
            if k == "LocalPlayer" then
                return {
                    GetMouse = function() return {} end,
                    Name = "TestPlayer",
                }
            end
            if k == "PlayerAdded" then return { Wait = function() return { GetMouse = function() return {} end, Name = "TestPlayer" } end } end
            return nil
        end,
    })
end

-- game mock
M.game = setmetatable({}, {
    __index = function(_, k)
        if k == "GetService" then
            return function(_, name) return service_stub(name) end
        end
        if k == "IsLoaded" then
            return function() return true end
        end
        if k == "PlaceId" then return 0 end
        if k == "HttpGet" then
            return function() return "" end
        end
        return nil
    end,
})

-- Other Roblox globals
M.warn = function(...) end
M.task = { delay = function() end, wait = function() end }
M.shared = {}
M.pcall = pcall

-- Install into _G so require'd modules see them
function M.install()
    for k, v in pairs(M) do
        if k ~= "install" and k ~= "extract_utils" then
            rawset(_G, k, v)
        end
    end
    rawset(_G, "typeof", M.typeof)
    rawset(_G, "cloneref", function(i) return i end)
    rawset(_G, "clonereference", function(i) return i end)
    rawset(_G, "getgenv", function() return _G end)
    rawset(_G, "setclipboard", nil)
    rawset(_G, "protectgui", function() end)
    rawset(_G, "gethui", function() return {} end)
    rawset(_G, "syn", nil)
    rawset(_G, "getfenv", getfenv or function() return _G end)
end

return M
