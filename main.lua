local HttpService = game:GetService("HttpService")
local genv = getgenv and getgenv()
if not genv then return end

if genv.luxy_router_debounce and (tick() - genv.luxy_router_debounce) <= 5 then
    return
end
genv.luxy_router_debounce = tick()

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local LuxyLib = genv.LuxyLib or genv.Library
if not LuxyLib then
    local LibraryURL = "https://raw.githubusercontent.com/Anonimusluxydev404/Luxy/refs/heads/main/LibraryV5/LuxyLibrary.lua"
    local libSuccess, libContent = pcall(function() return game:HttpGet(LibraryURL) end)
    if libSuccess and libContent and libContent ~= "404: Not Found" then
        local compiledLib = loadstring(libContent)
        if compiledLib then
            LuxyLib = compiledLib()
            genv.Library = LuxyLib
        end
    end
end

if not LuxyLib then return end

local DatabaseURL = "https://raw.githubusercontent.com/Omnie7/Luxy-Core/refs/heads/main/Modules/keys.json"
local DiscordLink = "https://discord.gg/Gr5UQUKp7"

local KeyWindow = LuxyLib:CreateWindow({
    Title = "Luxy Hub | Licensing System",
    Size = UDim2.fromOffset(450, 330),
    Resizable = false,
    DisableSearch = true,
    AutoShow = true
})

local KeyTab = KeyWindow:CreateTab("Verification", "key")
local KeyGroup = KeyTab:CreateGroup("Enter License Key")
local KeyInput = KeyGroup:CreateInput("License Key", "Paste LuXyHuB/## format here...", function() end)

local function LoadMainGameLogic()
    local LuxyGameList: { [number]: string } = {
        [89469502395769]  = "Kick%20A%20Lucky%20Blox.lua",
        [107646426076756] = "Build%20A%20Ring%20Farm.lua",
        [92416421522960]  = "Slime%20RNG.lua",
    }

    local targetFile = LuxyGameList[game.PlaceId]
    if targetFile then
        local baseURL = "https://raw.githubusercontent.com/Omnie7/Luxy-Scripts/main/Games/"
        local fullURL = baseURL .. targetFile

        local success, scriptCode = pcall(function()
            return game:HttpGet(fullURL .. "?t=" .. tick())
        end)

        if success and scriptCode and not string.find(scriptCode, "404: Not Found") then
            local func, err = loadstring(scriptCode)
            if func then
                task.spawn(func)
            else
                warn("[Luxy Hub] Parse Error: " .. tostring(err))
            end
        else
            warn("[Luxy Hub] Failed to fetch secure game script.")
        end
    else
        warn("[Luxy Hub] Game tidak terdaftar di database.")
    end
end

KeyGroup:CreateButton("Get Key (Discord)", function()
    if setclipboard then setclipboard(DiscordLink) end
end)

KeyGroup:CreateButton("Verify & Load", function()
    local enteredKey = KeyInput:GetText()
    if #enteredKey:gsub("%s+", "") == 0 then return end

    local networkSuccess, rawJSON = pcall(function()
        return game:HttpGet(DatabaseURL .. "?t=" .. tick())
    end)
    if not networkSuccess then return end

    local parseSuccess, keysTable = pcall(function()
        return HttpService:JSONDecode(rawJSON)
    end)
    if not parseSuccess or type(keysTable) ~= "table" then return end

    if keysTable[enteredKey] == true then
        if LuxyLib and LuxyLib.Unload then
            pcall(function() LuxyLib:Unload() end)
        end
        LoadMainGameLogic()
    else
        LuxyLib:CreateNotification({
            Title = "Invalid Key",
            Content = "Key salah atau kadaluwarsa! Ambil baru di Discord.",
            Duration = 4
        })
    end
end)

KeyGroup:AddLabel({
    Text = "Every execution requires you to grab a fresh format key from our official community.",
    DoesWrap = true,
    Size = 12
})

return LuxyLib
