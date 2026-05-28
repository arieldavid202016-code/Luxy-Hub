local genv = getgenv and getgenv()
if not genv then return end

if genv.luxy_execute_debounce and (tick() - genv.luxy_execute_debounce) <= 5 then 
    return 
end
genv.luxy_execute_debounce = tick()

if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

local LuxyGameList = {
    {
        Name = "Kick A Lucky Blox",
        PlaceIds = { 89469502395769 },
        ScriptURL = "https://raw.githubusercontent.com/Omnie7/Luxy-Scripts/main/Games/Kick%20A%20Lucky%20Blox.lua",
        CacheName = "KickBlox.lua"
    },
    
     {
        Name = "Build A Ring Farm",
        PlaceIds = { 107646426076756 },
        ScriptURL = "https://raw.githubusercontent.com/Omnie7/Luxy-Scripts/refs/heads/main/Games/Build%20A%20Ring%20Farm.lua",
        CacheName = "BuildRingFarm.lua"
    }
}

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    LocalPlayer = Players.LocalPlayer
    task.wait(0.5)
end

local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)

local CacheFolder = "LuxyHub_Cache"

local function fsRead(path)
    local s, r = pcall(readfile, path)
    return s and r
end

local function fsWrite(path, data)
    pcall(writefile, path, data)
end

local function fsIsFile(path)
    local s, r = pcall(isfile, path)
    return s and r == true
end

local function fsMakeDir(path)
    pcall(makefolder, path)
end

local function ShowCriticalError(title, text)
    pcall(function()
        local msg = Instance.new("Message", workspace)
        msg.Text = "[LUXY HUB ERROR]\n" .. title .. "\n\n" .. text
        game:GetService("Debris"):AddItem(msg, 15)
    end)
end

local function fetchWithCache(url, cacheFileName)
    local fullPath = CacheFolder .. "/" .. cacheFileName
    local success, response = pcall(function()
        return game:HttpGet(url, true)
    end)
    if success and response and response ~= "" and #response > 100 and not response:find("<!DOCTYPE html>") then
        task.spawn(function()
            fsMakeDir(CacheFolder)
            fsWrite(fullPath, response)
        end)
        return response
    end
    local cachedData = fsRead(fullPath)
    if cachedData and cachedData ~= "" and #cachedData > 100 then
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
        "Failed to fetch script & no valid local cache found.\nCheck your internet connection and restart the game!"
    )
    return nil
end

local function IsPlace(ScriptData)
    if ScriptData.PlaceIds and table.find(ScriptData.PlaceIds, game.PlaceId) then
        return true
    elseif ScriptData.GameId and ScriptData.GameId == game.GameId then
        return true
    end
    return false
end

local GameFound = false

for _, ScriptData in ipairs(LuxyGameList) do
    if IsPlace(ScriptData) then
        GameFound = true
        
        local scriptCode = fetchWithCache(ScriptData.ScriptURL, ScriptData.CacheName)
        
        if not scriptCode then 
            return 
        end

        local func, err = loadstring(scriptCode)
        if not func then
            ShowCriticalError("PARSE ERROR", "Script is corrupted or incomplete.\nPlease restart the game to re-download.\nError: " .. tostring(err))
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
