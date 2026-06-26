--[[local a = getgenv and getgenv()
if not a then
	return
end

if a.luxy_router_debounce and (tick() - a.luxy_router_debounce) <= 5 then
	return
end
a.luxy_router_debounce = tick()

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local b = {
	[89469502395769] = "Kalb.lua",
	[95082159892680] = "speed keyboard escape.lua",
	[118941584817777] = "speed keyboard escape.lua",
	[97598239454123] = "grow a garden 2.lua",
}
local c = b[game.PlaceId]
if not c then
	return
end

pcall(function()
    if not loadstring then
        return
    end

    local d = tostring(math.random(10000, 99999))

    local e = "https://raw.githubusercontent.com/Omnie7/Luxy-Hub/refs/heads/main/Game/" .. c .. "?nocache=" .. d

    local f = game:HttpGet(e)
    if f and f ~= "" then
        getgenv().LUXY_SECURE_LOAD = true 
        loadstring(f)()
    end
end)]]
