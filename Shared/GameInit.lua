--[[
    Shared game initialization boilerplate used by Game scripts and Webhook scripts.
    Ensures the game is loaded, the local player exists, the character is ready,
    and provides a short delay before script execution.
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

repeat task.wait() until LocalPlayer.Character
    and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

task.wait(2)

return {
    Players = Players,
    LocalPlayer = LocalPlayer,
    Character = LocalPlayer.Character,
    HumanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart"),
    Humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid"),
}
