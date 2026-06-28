local _E = getgenv().LuxyHub_State or {}
_E.Tracker = _E.Tracker or {}
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MutationData = { SurfaceApearances = {}, Mutations = {} }
pcall(function()
	MutationData = require(ReplicatedStorage.Shared.Data.MutationData)
end)

local EntitiesData = { Brainrots = {}, LuckyBlocks = {} }
pcall(function()
	EntitiesData = require(ReplicatedStorage.Shared.Data.EntitiesData)
end)

local localPlayer = game:GetService("Players").LocalPlayer
_E.Tracker.UserAvatarUrl = ""
pcall(function()
	if localPlayer then
		local url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="
			.. tostring(localPlayer.UserId)
			.. "&size=150x150&format=Png&isCircular=true"
		local raw = game:HttpGet(url)
		local data = HttpService:JSONDecode(raw)
		if data and data.data and data.data[1] then
			_E.Tracker.UserAvatarUrl = data.data[1].imageUrl
		end
	end
end)

_E.Tracker.Database = { Images = {} }
pcall(function()
	local rawJson = game:HttpGet(
		"https://raw.githubusercontent.com/Omnie7/Luxy-Hub/refs/heads/main/Data/Kick%20A%20Lucky%20Blox.json"
	)
	if rawJson and rawJson ~= "" then
		_E.Tracker.Database = HttpService:JSONDecode(rawJson)
	end
end)

_E.Tracker.RarityColors = {
	Common = 7506394,
	Uncommon = 32768,
	Rare = 4886754,
	Epic = 10181046,
	Legendary = 16312092,
	Mythical = 16508821,
	Mythic = 16508821,
	Secret = 16508821,
	Divine = 16711935,
	Hacked = 3066993,
	OG = 9109500,
	Celestial = 16763904,
	Ethernal = 8092526,
	Eternal = 11272192,
	Exclusive = 11272192,
	Random = 7506394,
}

_E.Tracker.RarityEmojis = {
	Common = "⚪",
	Uncommon = "🟢",
	Rare = "🔵",
	Epic = "🟣",
	Legendary = "🟡",
	Mythical = "🔴",
	Mythic = "🔴",
	Secret = "❓",
	Divine = "👑",
	Hacked = "💀",
	OG = "🔥",
	Celestial = "✨",
	Eternal = "🌟",
	Ethernal = "🌙",
	Exclusive = "💎",
}

local function getRarityEmoji(rarity)
	return _E.Tracker.RarityEmojis[rarity] or "❓"
end

local function getPingContent(rarity)
	local highPing = { Celestial = true, Eternal = true, Ethernal = true, Divine = true }
	local medPing = { Mythical = true, Secret = true, OG = true, Exclusive = true, Mythic = true }
	if highPing[rarity] then
		return "@everyone"
	elseif medPing[rarity] then
		return "@here"
	end
	return ""
end

local function colorToDecimal(color)
	if not color then
		return nil
	end
	local r = math.floor(color.R * 255)
	local g = math.floor(color.G * 255)
	local b = math.floor(color.B * 255)
	return r * 65536 + g * 256 + b
end

local function getDynamicColor(rarity, mutation)
	if mutation and mutation ~= "None" and mutation ~= "" then
		local mutationColor = MutationData.SurfaceApearances[mutation]
		local decimalColor = colorToDecimal(mutationColor)
		if decimalColor then
			return decimalColor
		end
	end
	return _E.Tracker.RarityColors[rarity] or 7506394
end

local function getPetImageUrl(petName)
	local imgStr = EntitiesData
			and EntitiesData.Brainrots
			and EntitiesData.Brainrots[petName]
			and EntitiesData.Brainrots[petName].Image
		or ""

	if imgStr ~= "" then
		local assetId = imgStr:match("rbxassetid://(%d+)")
		if assetId then
			local url = "https://www.roblox.com/asset-thumbnail/image?assetId="
				.. assetId
				.. "&width=420&height=420&format=png"
			return url
		end
	end

	if _E.Tracker.Database then
		local dbId = _E.Tracker.Database[petName]
		if not dbId and _E.Tracker.Database.Images then
			dbId = _E.Tracker.Database.Images[petName]
		end
		if dbId and not string.match(tostring(dbId), "^http") then
			local cdnUrl = ""
			pcall(function()
				local raw = game:HttpGet(
					"https://thumbnails.roblox.com/v1/assets?assetIds=" .. tostring(dbId) .. "&size=420x420&format=Png"
				)
				local data = HttpService:JSONDecode(raw)
				if data and data.data and data.data[1] then
					cdnUrl = data.data[1].imageUrl
				end
			end)
			return cdnUrl
		end
	end

	return ""
end

local function getPetDropChance(petName, mutation)
	local chanceStr = "Unknown"
	if EntitiesData and EntitiesData.LuckyBlocks then
		for _, blockData in pairs(EntitiesData.LuckyBlocks) do
			if blockData.Pool then
				for _, item in ipairs(blockData.Pool) do
					if item.Name == petName and item.Chance then
						chanceStr = tostring(item.Chance) .. "%"
						break
					end
				end
			end
		end
	end
	if mutation and mutation ~= "None" and mutation ~= "" and MutationData and MutationData.Mutations then
		for _, mut in ipairs(MutationData.Mutations) do
			if mut.Name == mutation and mut.Chance then
				if chanceStr ~= "Unknown" then
					chanceStr = chanceStr .. " (Mut: " .. tostring(mut.Chance) .. "%)"
				else
					chanceStr = "Mut: " .. tostring(mut.Chance) .. "%"
				end
				break
			end
		end
	end
	return chanceStr
end

local function SafeRequest(options)
	local req = (syn and syn.request)
		or (http and http.request)
		or http_request
		or request
		or (fluxus and fluxus.request)
	if not req then
		return false, "No executor request function"
	end
	return pcall(req, options)
end

local function getSendCooldownKey(petName, rarity, mutation)
	return petName .. "|" .. rarity .. "|" .. mutation
end

_E.Tracker.SendCooldowns = _E.Tracker.SendCooldowns or {}
local function checkCooldown(key, seconds)
	local last = _E.Tracker.SendCooldowns[key]
	if last and tick() - last < seconds then
		return true
	end
	_E.Tracker.SendCooldowns[key] = tick()
	return false
end

function _E.Tracker:SendToDiscord(webhookUrl, embeds, content)
	if not webhookUrl or webhookUrl == "" then
		return
	end
	if type(embeds) ~= "table" then
		embeds = { embeds }
	end
	content = content or ""

	local sanitizedUrl = string.gsub(webhookUrl, "discord.com", "hooks.hyra.io")
	sanitizedUrl = string.gsub(sanitizedUrl, "discordapp.com", "hooks.hyra.io")

	task.spawn(function()
		local payload = {
			username = "Luxy Hub Notifier",
			avatar_url = "https://raw.githubusercontent.com/Omnie7/Luxy-Hub/main/Library/fsad.png",
			embeds = embeds,
		}
		if content and content ~= "" then
			payload.content = content
		end

		local success, res = SafeRequest({
			Url = webhookUrl,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(payload),
		})
		if not success or (res and res.StatusCode and res.StatusCode >= 400) then
			SafeRequest({
				Url = sanitizedUrl,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode(payload),
			})
		end
	end)
end

function _E.Tracker:SendToGateway(embed, endpointType)
	local requestBody = {
		type = endpointType,
		embed = embed,
	}

	task.spawn(function()
		local success, res = SafeRequest({
			Url = "https://webhookluxyhub.nurisbullah81.workers.dev/",
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["X-API-Key"] = "LuxyHub_123",
			},
			Body = HttpService:JSONEncode(requestBody),
		})

		if success and res and res.StatusCode == 200 then
			print("[Luxy Gateway] Event reported successfully!")
		elseif not _E.Tracker._GatewayWarned then
			_E.Tracker._GatewayWarned = true
			warn("[Luxy Gateway] Gateway unreachable. Dev trackers disabled.")
		end
	end)
end

function _E.Tracker:SendTestConnection(webhookUrl)
	local embed = {
		title = "WEBHOOK CONNECTED",
		color = 65280,
		fields = {
			{
				name = "Status",
				value = "Luxy Hub connected successfully via Secure Telemetry Channel.",
				inline = false,
			},
			{ name = "Server", value = "```" .. tostring(game.JobId) .. "```", inline = true },
			{ name = "Player", value = localPlayer and localPlayer.Name or "Unknown", inline = true },
		},
		footer = { text = "Luxy Hub v3.7" },
		timestamp = DateTime.now():ToIsoDate(),
	}
	self:SendToDiscord(webhookUrl, embed)
end

function _E.Tracker:SendNewPetClaim(webhookUrl, petName, rarity, mutation, chanceText, cpsText, petImageUrl)
	local cooldownKey = getSendCooldownKey(petName, rarity, mutation)
	if checkCooldown(cooldownKey, 5) then
		return
	end

	local embedColor = getDynamicColor(rarity, mutation)
	local resolvedImageUrl = petImageUrl and petImageUrl ~= "" and petImageUrl or getPetImageUrl(petName)
	local emoji = getRarityEmoji(rarity)

	local embed = {
		title = emoji .. " " .. petName .. " Found!",
		color = embedColor,
		fields = {
			{ name = "Rarity", value = emoji .. " " .. rarity, inline = true },
			{
				name = "Mutation",
				value = (mutation ~= "None" and mutation ~= "") and mutation or "None",
				inline = true,
			},
			{ name = "Drop Chance", value = chanceText, inline = true },
			{ name = "CPS Value", value = cpsText, inline = true },
			{ name = "Server", value = "```" .. tostring(game.JobId) .. "```", inline = false },
		},
		footer = { text = "Luxy Hub | Inventory Notifier" },
		timestamp = DateTime.now():ToIsoDate(),
	}

	if resolvedImageUrl and resolvedImageUrl ~= "" then
		embed.thumbnail = { url = resolvedImageUrl }
	end

	local content = getPingContent(rarity)
	self:SendToDiscord(webhookUrl, embed, content)
end

function _E.Tracker:SendStatusReport(webhookUrl, kickLvl, totalFilteredPets, formattedCash, petData)
	local embed1 = {
		title = "Inventory Status Report",
		color = 16733440,
		fields = {
			{ name = "Wallet", value = tostring(formattedCash), inline = true },
			{ name = "Kick Level", value = tostring(kickLvl), inline = true },
			{ name = "Filtered Brainrots", value = tostring(totalFilteredPets), inline = true },
		},
		footer = { text = "Luxy Premium AFK Reporter" },
		timestamp = DateTime.now():ToIsoDate(),
	}

	local allEmbeds = { embed1 }

	if petData then
		local invLines = {}
		local charCount = 0
		for rarity, pets in pairs(petData) do
			local emoji = getRarityEmoji(rarity)
			table.insert(invLines, "\n" .. emoji .. " **" .. rarity .. "**")
			charCount = charCount + #rarity + 10
			for petName, mutations in pairs(pets) do
				for mutation, count in pairs(mutations) do
					local displayName = petName
					if mutation ~= "None" and mutation ~= "" then
						displayName = petName .. " (" .. mutation .. ")"
					end
					local line = "\n• " .. displayName .. " x" .. tostring(count)
					if charCount + #line > 1000 then
						table.insert(invLines, "\n*...and more*")
						charCount = 9999
						break
					end
					table.insert(invLines, line)
					charCount = charCount + #line
				end
				if charCount >= 9999 then
					break
				end
			end
			if charCount >= 9999 then
				break
			end
		end

		if #invLines > 0 then
			local embed2 = {
				title = "Inventory Breakdown",
				description = table.concat(invLines, ""),
				color = 16733440,
				image = { url = "https://raw.githubusercontent.com/Omnie7/Luxy-Hub/main/Library/fsad.png" },
			}
			table.insert(allEmbeds, embed2)
		end
	end

	self:SendToDiscord(webhookUrl, allEmbeds)
end

function _E.Tracker:SendGlobalLog(maskedName, petName, mutation, rarity, formattedCPS)
	local embedColor = getDynamicColor(rarity, mutation)
	local resolvedImageUrl = getPetImageUrl(petName)
	local dropChance = EntitiesData and EntitiesData.LuckyBlocks and getPetDropChance(petName, mutation) or "Unknown"
	local emoji = getRarityEmoji(rarity)

	local embed = {
		title = emoji .. " " .. petName .. " Found!",
		color = embedColor,
		fields = {
			{ name = "Rarity", value = emoji .. " " .. rarity, inline = true },
			{
				name = "Mutation",
				value = (mutation ~= "None" and mutation ~= "") and mutation or "None",
				inline = true,
			},
			{ name = "Drop Chance", value = dropChance, inline = true },
			{ name = "CPS Value", value = formattedCPS, inline = true },
			{ name = "Player", value = "`" .. maskedName .. "`", inline = false },
		},
		footer = { text = "Luxy Hub | Global Notifier" },
		timestamp = DateTime.now():ToIsoDate(),
	}

	if _E.Tracker.UserAvatarUrl and _E.Tracker.UserAvatarUrl ~= "" then
		embed.footer.icon_url = _E.Tracker.UserAvatarUrl
	end

	if resolvedImageUrl and resolvedImageUrl ~= "" then
		embed.thumbnail = { url = resolvedImageUrl }
	end

	self:SendToGateway(embed, "brainrot")
end

_E.Tracker.LoggedEvents = _E.Tracker.LoggedEvents or {}
function _E.Tracker:SendSatelliteLog(actualKey, timeLeft, luxySignature, playersCount, placeVersion, joinLink)
	if game.PrivateServerId ~= "" or game.PrivateServerOwnerId ~= 0 then
		return
	end

	local eventKey = actualKey .. "_" .. tostring(timeLeft)
	if _E.Tracker.LoggedEvents[eventKey] then
		return
	end
	_E.Tracker.LoggedEvents[eventKey] = true

	local resolvedImageUrl = getPetImageUrl(actualKey)

	local embed = {
		title = "Luxy Hub Server Finder",
		description = "Enter this job ID using Luxy Hub to join.",
		color = 11272192,
		fields = {
			{
				name = "Event",
				value = "```🎪 Event: " .. actualKey .. "\n⏰ Time Remaining: " .. timeLeft .. "```",
				inline = false,
			},
			{ name = "JobId PC", value = "```" .. luxySignature .. "```", inline = false },
			{ name = "JobId Mobile (Hold)", value = "`" .. luxySignature .. "`", inline = false },
			{ name = "Players", value = "```" .. playersCount .. "```", inline = true },
			{ name = "Version", value = "```" .. placeVersion .. "```", inline = true },
			{ name = "Quick Link", value = "[Click To Join](" .. joinLink .. ")", inline = false },
		},
		footer = { text = "Luxy Hub | Server Finder" },
		timestamp = DateTime.now():ToIsoDate(),
	}

	if resolvedImageUrl and resolvedImageUrl ~= "" then
		embed.thumbnail = { url = resolvedImageUrl }
	end

	self:SendToGateway(embed, "weather")
end

_E.Tracker.SendRequest = _E.Tracker.SendToGateway
print("[Luxy Hub] Secure Event Platform Tracker Module loaded successfully!")
return true
