local genv = getgenv and getgenv()
if not genv then return end

if genv.luxy_execute_debounce and (tick() - genv.luxy_execute_debounce) <= 5 then 
    return 
end
genv.luxy_execute_debounce = tick()

if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    LocalPlayer = Players.LocalPlayer
    task.wait(0.5)
end

local VU = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VU:CaptureController()
    VU:ClickButton2(Vector2.new())
end)

-- ==========================================
-- [ SAFE FILE SYSTEM WRAPPER ]
-- ==========================================
local fs = {
    read = readfile or function() return nil end,
    write = writefile or function() end,
    isFile = isfile or function() return false end,
    makeDir = makefolder or function() end
}

local CacheFolder = "LuxyHub_Cache"

-- ==========================================
-- [ MOBILE SAFE ERROR DISPLAY ]
-- ==========================================
local function ShowCriticalError(title, text)
    pcall(function()
        local msg = Instance.new("Message", workspace)
        msg.Text = "[LUXY HUB ERROR]\n" .. title .. "\n\n" .. text
        game:GetService("Debris"):AddItem(msg, 15)
    end)
end

-- ==========================================
-- [ SMART FALLBACK CACHE FETCHER ]
-- ==========================================
local function fetchWithCache(url, cacheFileName)
    local fullPath = CacheFolder .. "/" .. cacheFileName
    
    local success, response = pcall(function()
        return game:HttpGet(url, true)
    end)

    if success and response and response ~= "" then
        task.spawn(function()
            pcall(function()
                if not fs.isFile(CacheFolder) then fs.makeDir(CacheFolder) end
                fs.write(fullPath, response)
            end)
        end)
        return response
    end

    local cacheSuccess, cachedData = pcall(function()
        if fs.isFile(fullPath) then
            return fs.read(fullPath)
        end
        return nil
    end)

    if cacheSuccess and cachedData and cachedData ~= "" then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Luxy Hub (Offline Cache)",
                Text = "Network unstable, loading cached version...",
                Duration = 5
            })
        end)
        return cachedData
    end

    ShowCriticalError(
        "NETWORK ERROR", 
        "Failed to fetch script & no local cache found.\nCheck your internet connection and restart the game!"
    )
    return nil
end

-- ==========================================
-- [ LUXY HUB - GAME DATA ]
-- ==========================================
local Scripts = {
    {
        Name = "Kick A Lucky Blox",
        PlaceIds = { 89469502395769 },
        ScriptURL = "https://raw.githubusercontent.com/Omnie7/Luxy-Scripts/main/Games/Kick%20A%20Lucky%20Blox.lua",
        CacheName = "KickBlox.lua"
    }
}

local function IsPlace(ScriptData)
    if ScriptData.PlaceIds and table.find(ScriptData.PlaceIds, game.PlaceId) then
        return true
    elseif ScriptData.GameId and ScriptData.GameId == game.GameId then
        return true
    end
    return false
end

-- ==========================================
-- [ MAIN EXECUTOR ]
-- ==========================================
local GameFound = false

for _, ScriptData in ipairs(Scripts) do
    if IsPlace(ScriptData) then
        GameFound = true
        
        local scriptCode = fetchWithCache(ScriptData.ScriptURL, ScriptData.CacheName)
        
        if not scriptCode then 
            return
        end

        -- Loadstring
        local func, err = loadstring(scriptCode)
        if not func then
            ShowCriticalError("PARSE ERROR", "Script corrupted or executor unsupported.\nError: " .. tostring(err))
            return
        end

        task.spawn(func)
        break
    end
end

if not GameFound then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Luxy Hub",
            Text = "This game is not yet supported!",
            Duration = 5
        })
    end)
end
