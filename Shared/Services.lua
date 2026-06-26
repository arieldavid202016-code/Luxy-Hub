--[[
    Shared service initialization used by both LuxyHub and LuxyLibraryV2.
    Centralizes the cloneref pattern and common Roblox service access.
]]

local Services = {}

local cloneref = (
    cloneref
    or clonereference
    or function(instance)
        return instance
    end
)

Services.cloneref = cloneref
Services.CoreGui = cloneref(game:GetService("CoreGui"))
Services.Players = cloneref(game:GetService("Players"))
Services.RunService = cloneref(game:GetService("RunService"))
Services.SoundService = cloneref(game:GetService("SoundService"))
Services.UserInputService = cloneref(game:GetService("UserInputService"))
Services.TextService = cloneref(game:GetService("TextService"))
Services.Teams = cloneref(game:GetService("Teams"))
Services.TweenService = cloneref(game:GetService("TweenService"))

Services.getgenv = getgenv or function()
    return shared
end
Services.setclipboard = setclipboard or nil
Services.protectgui = protectgui or (syn and syn.protect_gui) or function() end
Services.gethui = gethui or function()
    return Services.CoreGui
end

Services.LocalPlayer = Services.Players.LocalPlayer or Services.Players.PlayerAdded:Wait()
Services.Mouse = cloneref(Services.LocalPlayer:GetMouse())

return Services
