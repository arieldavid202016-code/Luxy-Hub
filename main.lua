local genv = getgenv and getgenv()
if not genv then return end

-- Anti Spam Execute
if genv.luxy_execute_debounce and (tick() - genv.luxy_execute_debounce) <= 5 then 
    return 
end
genv.luxy_execute_debounce = tick()

if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

local Players = game:GetService("Players")
-- Safe wait untuk LocalPlayer (Emulator sering inject sebelum player ready)
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    LocalPlayer = Players.LocalPlayer
    task.wait(0.5)
end

-- Anti AFK
local VU = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VU:CaptureController()
    VU:ClickButton2(Vector2.new())
end)

local function NotifyError(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 10,
            Icon = "rbxassetid://6031154871"
        })
    end)
end

-- ==========================================
-- [ LUXY HUB - GAME DATA ]
-- ==========================================
local Scripts = {
    {
        Name = "Kick A Lucky Blox",
        PlaceIds = { 89469502395769 },
        ScriptURL = "https://raw.githubusercontent.com/Omnie7/Luxy-Scripts/main/Games/Kick%20A%20Lucky%20Blox.lua"
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
-- [ MAIN EXECUTOR (MOBILE SAFE) ]
-- ==========================================
local GameFound = false

for _, ScriptData in ipairs(Scripts) do
    if IsPlace(ScriptData) then
        GameFound = true
        
        -- STEP 1: AMBIL SCRIPT DARI GITHUB (DENGAN TIMEOUT/ERROR HANDLING)
        local success, response = pcall(function()
            return game:HttpGet(ScriptData.ScriptURL, true)
        end)

        if not success then
            NotifyError("Luxy Hub Error", "Internet/HTTP Failed! Check connection.")
            return
        end

        if not response or response == "" then
            NotifyError("Luxy Hub Error", "Script empty! GitHub might be down.")
            return
        end

        -- STEP 2: LOAD STRING (PARSING)
        local func, err = loadstring(response)
        if not func then
            NotifyError("Luxy Hub Error", "Parse error! Code is broken.")
            return
        end

        -- STEP 3: JALANKAN SCRIPT
        task.spawn(func)
        break
    end
end

if not GameFound then
    NotifyError("Luxy Hub", "This game is not yet supported by Luxy Hub!")
end
