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
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

local VU = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
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

local GameFound = false
for _, ScriptData in ipairs(Scripts) do
    if IsPlace(ScriptData) then
        GameFound = true
        print("🚀 [Luxy Hub] Detecting Games: " .. ScriptData.Name)
        
        local success, runScript = pcall(function()
            return loadstring(game:HttpGet(ScriptData.ScriptURL))
        end)

        if success and type(runScript) == "function" then
            task.spawn(runScript)
        else
            NotifyError("Luxy Hub Error", "Failed to load script from server!")
        end
        break
    end
end
if not GameFound then
    NotifyError("Luxy Hub", "This game is not yet supported by Luxy Hub!")
end
