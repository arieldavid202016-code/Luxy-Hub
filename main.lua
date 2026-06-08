local genv = getgenv and getgenv()
if not genv then
	return
end

if genv.luxy_router_debounce and (tick() - genv.luxy_router_debounce) <= 5 then
	return
end
genv.luxy_router_debounce = tick()

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local LuxyGameList: { [number]: string } = {
	[89469502395769] = "Kick%20A%20Lucky%20Blox.lua",
	[107646426076756] = "Build%20A%20Ring%20Farm.lua",
	[92416421522960] = "Slime%20RNG.lua",
}

local targetFile = LuxyGameList[game.PlaceId]
if targetFile then
	local baseURL = "https://raw.githubusercontent.com/Omnie7/Luxy-Scripts/main/Games/"
	local fullURL = baseURL .. targetFile

	local success, scriptCode = pcall(function()
		return game:HttpGet(fullURL)
	end)

	if success and scriptCode and #scriptCode > 100 then
		local func, err = loadstring(scriptCode)
		if func then
			task.spawn(func)
		else
			warn("[Luxy Hub] Parse Error: " .. tostring(err))
		end
	else
		warn("[Luxy Hub] Failed to fetch secure game script from GitHub.")
	end
else
	warn("[Luxy Hub] Game PlaceId " .. tostring(game.PlaceId) .. " not registered in the router database.")
end
