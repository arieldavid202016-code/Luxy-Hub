local genv = getgenv and getgenv()
if not genv then return end

if genv.luxy_router_debounce and (tick() - genv.luxy_router_debounce) <= 5 then return end
genv.luxy_router_debounce = tick()

if not game:IsLoaded() then game.Loaded:Wait() end

local routes = {
    [89469502395769]  = "kick-lucky-blox",
    [107646426076756] = "build-a-ring-farm",
    [92416421522960]  = "slime-rng",
    [95082159892680]  = "speed-keyboard-escape",
    [118941584817777] = "speed-keyboard-escape",
}

local target = routes[game.PlaceId]
if not target then return end

pcall(function()
    if not loadstring then return end
    local payload = game:HttpGet("https://www.luxyhub.space/api/loader/" .. target)
    if payload and payload ~= "" then
        loadstring(payload)()
    end
end)
