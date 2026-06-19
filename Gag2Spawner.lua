local RS = game:GetService("ReplicatedStorage")
local LP = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")
local PlantVisualizerController = nil
local FruitVisualizerController = nil

pcall(function()
    local controllers = LP.PlayerScripts:FindFirstChild("Controllers")
    if controllers then
        local pvc = controllers:FindFirstChild("PlantVisualizerController")
        if pvc then
            PlantVisualizerController = require(pvc)
            print("[LUXY] PlantVisualizerController successfully required!")
        end
        local fvc = controllers:FindFirstChild("FruitVisualizerController")
        if fvc then
            FruitVisualizerController = require(fvc)
            print("[LUXY] FruitVisualizerController successfully required!")
        end
    end
end)

print("[LUXY] Starts Loading DATA...")
local LuxyLib = nil
local libOk, libErr = pcall(function() -- FIX DI SINI: Menyimpan hasil return pcall
    local code = game:HttpGet("https://raw.githubusercontent.com/Omnie7/Luxy-Hub/main/Library/LuxyHub.lua")
    if code and code ~= "" then
        local func = loadstring(code)
        if func then LuxyLib = func() end
    end
end)
if not libOk or not LuxyLib then
    warn("[LUXY] Error Loading Library:", libErr)
    return
end

local PetData = nil
local PetTypes = nil
local PlayerStateClient = nil
local PetHandleController = nil
local PlantController = nil

pcall(function()
    PetData = require(RS.SharedData.PetData)
end)
pcall(function()
    PetTypes = require(RS.SharedData.PetTypes)
end)
pcall(function()
    PlayerStateClient = require(RS.ClientModules.PlayerStateClient)
end)
pcall(function()
    local playerScripts = LP:FindFirstChild("PlayerScripts")
    if playerScripts then
        local controllers = playerScripts:FindFirstChild("Controllers")
        if controllers then
            local phc = controllers:FindFirstChild("PetHandleController")
            if phc then
                PetHandleController = require(phc)
            end
            local pc = controllers:FindFirstChild("PlantController")
            if pc then
                PlantController = require(pc)
                print("[LUXY] Done phase 1 !")
            end
        end
    end
end)

local petDisplayNames = {}
local petDisplayToKey = {}

if PetData then
    for petKey, data in pairs(PetData) do
        if type(data) == "table" and data.DisplayName then
            local displayName = data.DisplayName
            table.insert(petDisplayNames, displayName)
            petDisplayToKey[displayName] = petKey
        end
    end
    table.sort(petDisplayNames)
else
    petDisplayNames = { "Frog", "Bunny", "Deer", "Owl", "Raccoon", "Unicorn", "Black Dragon", "Ice Serpent", "Golden Dragonfly" }
    for _, name in ipairs(petDisplayNames) do
        local key = name:gsub(" ", "")
        petDisplayToKey[name] = key
    end
end

local seedList = {}
local seedRealNames = {}

pcall(function()
    local sData = require(RS.SharedModules.SeedData)
    for _, v in pairs(sData) do
        if type(v) == "table" and v.SeedName then
            local cleanName = v.SeedName:gsub(" Seed$", ""):gsub(" SeedPack$", ""):gsub(" Seed Pack$", "")
            if not table.find(seedList, cleanName) then
                table.insert(seedList, cleanName)
            end
            seedRealNames[cleanName] = v.SeedName
        end
    end
end)

if #seedList == 0 then
    seedList = { "Romanesco", "Venus Fly Trap", "Strawberry", "Tomato", "Blueberry", "Carrot", "Moon Bloom" }
    for _, name in ipairs(seedList) do
        seedRealNames[name] = name .. " Seed"
    end
end
table.sort(seedList)

local function getSeedImage(seedName)
    local img = ""
    pcall(function()
        for _, v in ipairs(RS.SharedModules:GetDescendants()) do
            if v:IsA("StringValue") and (v.Name == seedName or v.Name == seedName .. " Seed" or v.Name == seedName .. " Seed Pack") then
                img = v.Value
                break
            end
        end
    end)
    return img
end

local selectedPetDisplay = petDisplayNames[1] or "Frog"
local selectedPetKey = petDisplayToKey[selectedPetDisplay] or "Frog"
local selectedSize = "Normal"
local selectedVariant = "Normal"
local spawnAmount = 1
local selectedSeed = seedList[1] or "Romanesco"
local seedSpawnAmount = 5
local selectedSeedSize = "Random"
local selectedSeedMutation = "Normal"
local currentSlotIndex = 5
local selectedWeather = "Rainbow"
local weatherDuration = 300
local weatherList = {}

pcall(function()
    local WeatherData = require(RS.SharedModules.WeatherData)
    if WeatherData and WeatherData.Data then
        for _, v in pairs(WeatherData.Data) do
            if v.Name then
                table.insert(weatherList, v.Name)
            end
        end
    end
end)

if #weatherList == 0 then
    weatherList = { "Rainbow", "Golden", "Storm" }
end
table.sort(weatherList)
selectedWeather = weatherList[1] or "Rainbow"

local selectedPhase = "Day"
local phaseList = {}
local originalPhase = workspace:GetAttribute("ActivePhase") or "Day"
local originalWeather = workspace:GetAttribute("ActiveWeather") or "Normal"
local originalDuration = workspace:GetAttribute("PhaseDuration") or (workspace:GetServerTimeNow() + 450)

pcall(function()
    local controllers = LP.PlayerScripts:FindFirstChild("Controllers")
    if controllers then
        local tcc = controllers:FindFirstChild("TimeCycleController")
        if tcc then
            local phasesFolder = tcc:FindFirstChild("Phases")
            if phasesFolder then
                for _, child in ipairs(phasesFolder:GetChildren()) do
                    if child:IsA("ModuleScript") then
                        table.insert(phaseList, child.Name)
                    end
                end
            end
        end
    end
end)

if #phaseList == 0 then
    phaseList = { "Day", "Sunset", "Moon", "Bloodmoon", "Chained Moon", "Goldmoon", "Pizza Moon", "Rainbow Moon" }
end
table.sort(phaseList)
selectedPhase = phaseList[1] or "Day"

local function spawnVisualPlant(position, seedName)
    local plotId = LP:GetAttribute("PlotId")
    if not plotId then return end

    local plot = workspace.Gardens:FindFirstChild("Plot" .. plotId)
    if not plot then return end

    local spawnPoint = plot:FindFirstChild("SpawnPoint")
    if not spawnPoint then return end

    if not PlantVisualizerController then
        warn("[LUXY] Not Detected!")
        return
    end

    local localPos = spawnPoint.CFrame:PointToObjectSpace(position)

    local cleanSeedName = seedName:gsub(" Seed$", ""):gsub(" SeedPack$", ""):gsub(" Seed Pack$", "")

    local maxAge = 100
    pcall(function()
        local sData = require(RS.SharedModules.SeedData)
        for _, v in pairs(sData) do
            if v.SeedName == cleanSeedName or v.SeedName == seedName then
                maxAge = v.MaxAge or v.GrowTime or 100
                break
            end
        end
    end)

    local sizeMulti = 1.0
    if selectedSeedSize == "Random" then
        sizeMulti = math.random(8, 25) / 10
    else
        sizeMulti = tonumber(selectedSeedSize) or 1.0
    end

    local mutation = nil
    if selectedSeedMutation ~= "Normal" then
        mutation = selectedSeedMutation
    end
    local plantId = "FakePlant_" .. HttpService:GenerateGUID(false)

    local plantData = {
        PlantName = cleanSeedName, -- FIX: Gunakan nama bersih untuk memicu model pertumbuhan asli
        Positions = {
            PosX = localPos.X,
            PosY = localPos.Y,
            PosZ = localPos.Z,
            Rotation = math.random(0, 360)
        },
        MaxAge = maxAge,
        Age = 0,
        Seed = math.random(1, 100000),
        SizeMultiplier = sizeMulti,
        Mutation = mutation,
        PlantedAt = os.time(),
        PrimeStartedAt = os.time(),
        ReviveProgress = 0,
        IsPotted = false
    }

    pcall(function()
        PlantVisualizerController:SpawnPlantFromData(LP.UserId, plantId, plantData)
    end)

    task.spawn(function()
        task.wait(0.2)
        local fakePlant = PlantVisualizerController:GetSpawnedPlant(LP.UserId, plantId)
        if fakePlant then
            fakePlant:SetAttribute("_LuxyVisual", true)
        end
    end)

    task.spawn(function()
        task.wait(0.5)
        local growthData = PlantVisualizerController:GetPlantGrowthData(LP.UserId, plantId)
        if growthData then
            growthData.StableGrowthAmount = (growthData.StableGrowthAmount or 0.2) * 15
        end
    end)

    task.spawn(function()
        task.wait(0.8)
        local fakePlant = PlantVisualizerController:GetSpawnedPlant(LP.UserId, plantId)
        if not fakePlant then return end
        local FruitSpawnLocations = fakePlant:FindFirstChild("FruitSpawnLocations")
        if FruitSpawnLocations and FruitVisualizerController then
            for index, child in ipairs(FruitSpawnLocations:GetChildren()) do
                if child:IsA("BasePart") then
                    local fruitId = "FakeFruit_" .. HttpService:GenerateGUID(false)
                    local fruitData = {
                        MaxAge = 100,
                        Age = 0,
                        GrowRate = 0.35,
                        SizeMultiplier = sizeMulti,
                        Mutation = mutation,
                        Seed = math.random(1, 100000),
                        SpawnLocationIndex = index,
                        OvertimeGrowth = 1
                    }
                    pcall(function()
                        FruitVisualizerController:SpawnFruitFromData(LP.UserId, plantId, fruitId, fruitData,
                            { SpawnLocationIndex = index })
                    end)
                end
            end
        end
    end)
end

pcall(function()
    local Networking = require(RS.SharedModules.Networking)
    if Networking and Networking.Plant and Networking.Plant.PlantSeed then
        local originalFire = Networking.Plant.PlantSeed.Fire

        Networking.Plant.PlantSeed.Fire = function(self, position, seedName, tool)
            if tool and (tool:GetAttribute("_LuxySpawnedSeed") or tool:GetAttribute("_LuxySpawned")) then
                task.spawn(spawnVisualPlant, position, seedName)

                if PlantController and typeof(PlantController.PlayPlantFx) == "function" then
                    pcall(function()
                        PlantController:PlayPlantFx(position, seedName)
                    end)
                end

                local currentCount = tool:GetAttribute("Count") or 1
                local newCount = currentCount - 1

                if newCount > 0 then
                    tool:SetAttribute("Count", newCount)
                    local cleanName = seedName:gsub(" Seed$", ""):gsub(" SeedPack$", ""):gsub(" Seed Pack$", "")
                    tool.Name = cleanName .. " (" .. tostring(newCount) .. ")"
                else
                    tool:Destroy()
                end

                local replica = nil
                if PlayerStateClient then
                    pcall(function()
                        replica = PlayerStateClient:GetLocalReplica() or PlayerStateClient.GetLocalReplica()
                    end)
                end
                if replica and replica.Data and replica.Data.Inventory and replica.Data.Inventory.Seeds then
                    local invSeed = replica.Data.Inventory.Seeds[seedName]
                    if invSeed then
                        local updatedVal = math.max(0, invSeed - 1)
                        if updatedVal > 0 then
                            replica.Data.Inventory.Seeds[seedName] = updatedVal
                        else
                            replica.Data.Inventory.Seeds[seedName] = nil
                        end
                    end
                end

                return
            end
            if originalFire then
                return originalFire(self, position, seedName, tool)
            end
        end
    end
end)

local Spawner = {}

function Spawner:Init(Win)
    local TabSpawner = Win:CreateTab("Spawner", "rbxassetid://10709752906", "Visual Spawner Menu")

    local SpawnerGroup = TabSpawner:CreateGroup("PET SPAWNER", "rbxassetid://10709752906")

    SpawnerGroup:AddDropdown("PetName", {
        Text = "Select Pet",
        Values = petDisplayNames,
        Default = selectedPetDisplay,
        MultipleOptions = false,
        Callback = function(Val)
            local chosen = type(Val) == "table" and Val[1] or tostring(Val)
            selectedPetDisplay = chosen
            selectedPetKey = petDisplayToKey[chosen] or chosen
        end,
    })

    SpawnerGroup:AddDropdown("PetSize", {
        Text = "Select Size",
        Values = { "Normal", "Big", "Huge" },
        Default = "Normal",
        MultipleOptions = false,
        Callback = function(Val)
            selectedSize = type(Val) == "table" and Val[1] or tostring(Val)
        end,
    })

    SpawnerGroup:AddDropdown("PetVariant", {
        Text = "Select Variant",
        Values = { "Normal", "Rainbow" },
        Default = "Normal",
        MultipleOptions = false,
        Callback = function(Val)
            selectedVariant = type(Val) == "table" and Val[1] or tostring(Val)
        end,
    })

    SpawnerGroup:AddSlider("SpawnAmount", {
        Text = "Spawn Pet Amount",
        Min = 1,
        Max = 20,
        Default = 1,
        Callback = function(val)
            local cleanVal = tostring(val):match("[%d%.]+")
            spawnAmount = tonumber(cleanVal) or 1
        end,
    })

    SpawnerGroup:CreateButton("Spawn Pet", function()
        local replica = nil
        if PlayerStateClient then
            pcall(function()
                replica = PlayerStateClient:GetLocalReplica() or PlayerStateClient.GetLocalReplica()
            end)
        end

        local backpack = LP:FindFirstChildOfClass("Backpack") or LP:FindFirstChild("Backpack")
        local char = LP.Character
        local playerRefFolder = workspace:WaitForChild("PlayerPetReferences"):WaitForChild(LP.Name, 5)

        if not backpack or not char or not playerRefFolder then
            return
        end

        for i = 1, spawnAmount do
            pcall(function()
                local fakePetId = HttpService:GenerateGUID(false)

                if replica and replica.Data and replica.Data.Inventory and replica.Data.Inventory.Pets then
                    replica.Data.Inventory.Pets[fakePetId] = {
                        Id = fakePetId,
                        Name = selectedPetKey,
                        Equipped = false,
                        Size = selectedSize,
                        PetSize = selectedSize,
                        Type = selectedVariant,
                        PetType = selectedVariant
                    }
                end

                local petIcon = ""
                if PetData and typeof(PetData.GetImage) == "function" then
                    pcall(function()
                        petIcon = PetData.GetImage(selectedPetKey, selectedSize)
                    end)
                end

                local fakeTool = Instance.new("Tool")
                fakeTool.Name = selectedPetDisplay
                fakeTool.TextureId = petIcon

                fakeTool:SetAttribute("MainCategory", "Pet")
                fakeTool:SetAttribute("Pet", selectedPetKey)
                fakeTool:SetAttribute("PetId", fakePetId)

                if selectedVariant == "Rainbow" then
                    fakeTool:SetAttribute("PetType", "Rainbow")
                else
                    fakeTool:SetAttribute("PetType", "Normal")
                end

                if selectedSize ~= "Normal" then
                    fakeTool:SetAttribute("PetSize", selectedSize)
                else
                    fakeTool:SetAttribute("PetSize", nil)
                end

                fakeTool:SetAttribute("ToolDescendants", 0)
                fakeTool:SetAttribute("Count", 0)
                fakeTool:SetAttribute("_LuxySpawned", true) -- FIX: Case disamakan agar ditangkap Hook

                local handle = Instance.new("Part")
                handle.Name = "Handle"
                handle.Transparency = 1
                handle.CanCollide = false
                handle.Size = Vector3.new(1, 1, 1)
                handle.Parent = fakeTool

                local petKeyForClick = selectedPetKey
                local sizeForClick = selectedSize
                local variantForClick = selectedVariant
                local thisPetId = fakePetId

                local clickConnection = nil

                fakeTool.Equipped:Connect(function()
                    local mouse = LP:GetMouse()
                    clickConnection = mouse.Button1Down:Connect(function()
                        local targetPos = mouse.Hit.p

                        if clickConnection then
                            clickConnection:Disconnect()
                            clickConnection = nil
                        end

                        local index = currentSlotIndex
                        currentSlotIndex = currentSlotIndex + 1

                        local spacing = 7.5
                        if sizeForClick == "Huge" then
                            spacing = 15
                        elseif sizeForClick == "Big" then
                            spacing = 10
                        end

                        local row = math.floor((index - 5) / 3)
                        local col = (index - 5) % 3 - 1
                        local offset_x = col * spacing
                        local offset_z = 6 + (row * spacing)

                        local fakePetPart = Instance.new("Part")
                        fakePetPart.Name = "PetPart" .. tostring(index)
                        fakePetPart.Size = Vector3.new(1, 1, 1)
                        fakePetPart.Transparency = 1
                        fakePetPart.CanCollide = false
                        fakePetPart.Anchored = true
                        fakePetPart.CFrame = CFrame.new(targetPos)

                        fakePetPart:SetAttribute("PetSpecies", petKeyForClick)
                        fakePetPart:SetAttribute("PetId", thisPetId)
                        fakePetPart:SetAttribute("SlotOffsetX", offset_x)
                        fakePetPart:SetAttribute("SlotOffsetZ", offset_z)
                        fakePetPart:SetAttribute("SlotHeightOffset",
                            (petKeyForClick == "GoldenDragonfly" or petKeyForClick == "Robin" or petKeyForClick == "Bee" or petKeyForClick == "BlackDragon" or petKeyForClick == "IceSerpent") and
                            4 or 0)
                        fakePetPart:SetAttribute("PetVisible", true)
                        fakePetPart:SetAttribute("PetAttached", true)

                        if variantForClick == "Rainbow" then
                            fakePetPart:SetAttribute("PetType", "Rainbow")
                        else
                            fakePetPart:SetAttribute("PetType", "Normal")
                        end

                        if sizeForClick ~= "Normal" then
                            fakePetPart:SetAttribute("PetSize", sizeForClick)
                        end

                        fakePetPart:SetAttribute("_LUXY_PART", true)
                        fakePetPart:SetAttribute("_LUXY_PET_ID", thisPetId)

                        fakePetPart.Parent = playerRefFolder

                        if replica and replica.Data and replica.Data.Inventory and replica.Data.Inventory.Pets then
                            local pData = replica.Data.Inventory.Pets[thisPetId]
                            if pData then pData.Equipped = true end
                        end

                        local storage = workspace:FindFirstChild("_LuxyPetStorage")
                        if not storage then
                            storage = Instance.new("Folder")
                            storage.Name = "_LuxyPetStorage"
                            storage.Parent = workspace
                        end
                        fakeTool.Parent = storage
                    end)
                end)

                fakeTool.Unequipped:Connect(function()
                    if clickConnection then
                        clickConnection:Disconnect()
                        clickConnection = nil
                    end
                end)

                fakeTool.Parent = backpack

                task.spawn(function()
                    task.wait(0.05)
                    if PetHandleController then
                        pcall(function()
                            PetHandleController:SetupTool(fakeTool, char)
                        end)
                    end
                end)
            end)
        end
    end)

    local SeedGroup = TabSpawner:CreateGroup("SEED SPAWNER", "rbxassetid://10709752906")

    SeedGroup:AddDropdown("SeedName", {
        Text = "Select Seed",
        Values = seedList,
        Default = selectedSeed,
        MultipleOptions = false,
        Callback = function(Val)
            selectedSeed = type(Val) == "table" and Val[1] or tostring(Val)
        end,
    })

    SeedGroup:AddDropdown("SeedMutation", {
        Text = "Select Plant Variant",
        Values = { "Normal", "Gold", "Rainbow" },
        Default = selectedSeedMutation,
        MultipleOptions = false,
        Callback = function(Val)
            selectedSeedMutation = type(Val) == "table" and Val[1] or tostring(Val)
        end,
    })

    SeedGroup:AddDropdown("SeedSize", {
        Text = "Select Plant Size",
        Values = { "Random", "0.5x (Small)", "1.0x (Normal)", "1.8x (Big)", "3.0x (Huge)" },
        Default = selectedSeedSize,
        MultipleOptions = false,
        Callback = function(Val)
            local choice = type(Val) == "table" and Val[1] or tostring(Val)
            if choice == "Random" then
                selectedSeedSize = "Random"
            else
                local num = choice:match("[%d%.]+")
                selectedSeedSize = tonumber(num) or 1.0
            end
        end,
    })

    SeedGroup:AddSlider("SeedAmount", {
        Text = "Spawn Seed Amount",
        Min = 1,
        Max = 100,
        Default = 5,
        Callback = function(val)
            local cleanVal = tostring(val):match("[%d%.]+")
            seedSpawnAmount = tonumber(cleanVal) or 5
        end,
    })

    SeedGroup:CreateButton("Spawn Seed", function()
        local replica = nil
        if PlayerStateClient then
            pcall(function()
                replica = PlayerStateClient:GetLocalReplica() or PlayerStateClient.GetLocalReplica()
            end)
        end

        local backpack = LP:FindFirstChildOfClass("Backpack") or LP:FindFirstChild("Backpack")
        local char = LP.Character
        if not backpack or not char then
            return
        end

        pcall(function()
            local realSeedName = seedRealNames[selectedSeed] or (selectedSeed .. " Seed")

            if replica and replica.Data and replica.Data.Inventory and replica.Data.Inventory.Seeds then
                replica.Data.Inventory.Seeds[realSeedName] = (replica.Data.Inventory.Seeds[realSeedName] or 0) +
                seedSpawnAmount
                print("[LUXY] Successfully added " ..
                tostring(seedSpawnAmount) .. "x " .. realSeedName .. " to replica data!")
            end

            local seedIcon = getSeedImage(selectedSeed)

            local fakeSeedTool = Instance.new("Tool")
            fakeSeedTool.Name = selectedSeed .. " (" .. tostring(seedSpawnAmount) .. ")"
            fakeSeedTool.TextureId = seedIcon

            fakeSeedTool:SetAttribute("MainCategory", "Seed")
            fakeSeedTool:SetAttribute("SeedTool", realSeedName)
            fakeSeedTool:SetAttribute("Count", seedSpawnAmount)
            fakeSeedTool:SetAttribute("ToolDescendants", 0)
            fakeSeedTool:SetAttribute("_LuxySpawnedSeed", true)

            local handle = Instance.new("Part")
            handle.Name = "Handle"
            handle.Transparency = 1
            handle.CanCollide = false
            handle.Size = Vector3.new(1, 1, 1)
            handle.Parent = fakeSeedTool

            fakeSeedTool.Parent = backpack
            print("[LUXY] Successfully spawned " .. realSeedName .. " x" .. tostring(seedSpawnAmount) .. " into Backpack!")
        end)

        pcall(function()
            local displayName = selectedSeed .. " Seed"
            if LuxyLib then
                LuxyLib:Notify({
                    Title = "Visual Seed Spawned!",
                    Content = "Added " .. tostring(seedSpawnAmount) .. "x " .. displayName .. " to your Seed Bag!",
                    Duration = 3
                })
            end
        end)
    end)

    local WeatherGroup = TabSpawner:CreateGroup("WEATHER SPAWNER", "rbxassetid://10709752906")

    WeatherGroup:AddDropdown("WeatherName", {
        Text = "Select Weather",
        Values = weatherList,
        Default = selectedWeather,
        MultipleOptions = false,
        Callback = function(Val)
            selectedWeather = type(Val) == "table" and Val[1] or tostring(Val)
        end,
    })

    WeatherGroup:AddSlider("WeatherDuration", {
        Text = "Duration (Minutes)",
        Min = 1,
        Max = 60,
        Default = 5,
        Callback = function(val)
            local cleanVal = tostring(val):match("[%d%.]+")
            weatherDuration = (tonumber(cleanVal) or 5) * 60
        end
    })

    WeatherGroup:CreateButton("Start Weather", function()
        pcall(function()
            local weatherVal = RS:WaitForChild("WeatherValues")
            local endTime = DateTime.now().UnixTimestamp + weatherDuration

            weatherVal:SetAttribute(selectedWeather .. "_EndTime", endTime)
            weatherVal:SetAttribute(selectedWeather .. "_Playing", true)

            if LuxyLib then
                LuxyLib:Notify({
                    Title = "Weather Activated!",
                    Content = "Locally started " .. selectedWeather .. " weather effect!",
                    Duration = 3
                })
            end
        end)
    end)

    WeatherGroup:CreateButton("Stop Weather", function()
        pcall(function()
            local weatherVal = RS:WaitForChild("WeatherValues")
            weatherVal:SetAttribute(selectedWeather .. "_Playing", false)
            weatherVal:SetAttribute(selectedWeather .. "_EndTime", nil)

            if LuxyLib then
                LuxyLib:Notify({
                    Title = "Weather Deactivated!",
                    Content = "Locally stopped " .. selectedWeather .. " weather effect!",
                    Duration = 3
                })
            end
        end)
    end)

    WeatherGroup:CreateButton("Stop All Weather", function()
        pcall(function()
            local weatherVal = RS:WaitForChild("WeatherValues")
            for _, name in ipairs(weatherList) do
                weatherVal:SetAttribute(name .. "_Playing", false)
                weatherVal:SetAttribute(name .. "_EndTime", nil)
            end

            if LuxyLib then
                LuxyLib:Notify({
                    Title = "All Weathers Cleaned!",
                    Content = "Cleared all local active weather effects!",
                    Duration = 3
                })
            end
        end)
    end)

    local CycleGroup = TabSpawner:CreateGroup("TIME & MOON CYCLE", "rbxassetid://10709752906")

    CycleGroup:AddDropdown("CycleName", {
        Text = "Select Phase/Moon",
        Values = phaseList,
        Default = selectedPhase,
        MultipleOptions = false,
        Callback = function(Val)
            selectedPhase = type(Val) == "table" and Val[1] or tostring(Val)
        end,
    })

    CycleGroup:CreateButton("Apply Visual Cycle", function()
        pcall(function()
            local phase = "Night"
            local weather = "Moon"
            local duration = 120

            if selectedPhase == "Day" then
                phase = "Day"
                weather = "Day"
                duration = 450
            elseif selectedPhase == "Sunset" then
                phase = "Sunset"
                weather = "Sunset"
                duration = 30
            elseif selectedPhase == "Moon" then
                phase = "Night"
                weather = "Moon"
                duration = 120
            elseif selectedPhase == "Bloodmoon" then
                phase = "Night"
                weather = "Bloodmoon"
                duration = 120
            elseif selectedPhase == "Goldmoon" then
                phase = "Night"
                weather = "Goldmoon"
                duration = 120
            elseif selectedPhase == "Rainbow Moon" then
                phase = "Night"
                weather = "Rainbow Moon"
                duration = 120
            else
                phase = "Night"
                weather = selectedPhase
                duration = 120
            end

            local endTime = workspace:GetServerTimeNow() + duration

            workspace:SetAttribute("ActivePhase", phase)
            workspace:SetAttribute("ActiveWeather", weather)
            workspace:SetAttribute("PhaseDuration", endTime)

            if LuxyLib then
                LuxyLib:Notify({
                    Title = "Cycle Applied!",
                    Content = "Locally changed sky & environment to " .. selectedPhase .. "!",
                    Duration = 3
                })
            end
        end)
    end)

    CycleGroup:CreateButton("Reset to Original Cycle", function()
        pcall(function()
            workspace:SetAttribute("ActivePhase", originalPhase)
            workspace:SetAttribute("ActiveWeather", originalWeather)
            workspace:SetAttribute("PhaseDuration", originalDuration)

            print("[LUXY] Local cycle reset to default server.")

            if LuxyLib then
                LuxyLib:Notify({
                    Title = "Cycle Reset!",
                    Content = "Reset environment back to server default!",
                    Duration = 3
                })
            end
        end)
    end)

    TabSpawner:CreateGroup("CLEANER", "rbxassetid://10709752906"):CreateButton("Clear All Visuals", function()
        local replica = nil
        if PlayerStateClient then
            pcall(function()
                replica = PlayerStateClient:GetLocalReplica() or PlayerStateClient.GetLocalReplica()
            end)
        end

        local backpack = LP:FindFirstChild("Backpack")
        local char = LP.Character
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and (tool:GetAttribute("_LUXY_SPAWNED") or tool:GetAttribute("_LuxySpawned") or tool:GetAttribute("_LuxySpawnedSeed")) then
                    local petId = tool:GetAttribute("PetId")
                    local seedName = tool:GetAttribute("SeedTool")
                    if replica and replica.Data and replica.Data.Inventory then
                        if petId and replica.Data.Inventory.Pets then replica.Data.Inventory.Pets[petId] = nil end
                        if seedName and replica.Data.Inventory.Seeds then replica.Data.Inventory.Seeds[seedName] = nil end
                    end
                    tool:Destroy()
                end
            end
        end
        if char then
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") and (tool:GetAttribute("_LUXY_SPAWNED") or tool:GetAttribute("_LuxySpawned") or tool:GetAttribute("_LuxySpawnedSEED")) then
                    local petId = tool:GetAttribute("PetId")
                    local seedName = tool:GetAttribute("SeedTool")
                    if replica and replica.Data and replica.Data.Inventory then
                        if petId and replica.Data.Inventory.Pets then replica.Data.Inventory.Pets[petId] = nil end
                        if seedName and replica.Data.Inventory.Seeds then replica.Data.Inventory.Seeds[seedName] = nil end
                    end
                    tool:Destroy()
                end
            end
        end

        local playerRefFolder = workspace:WaitForChild("PlayerPetReferences"):WaitForChild(LP.Name, 5)
        if playerRefFolder then
            for _, part in ipairs(playerRefFolder:GetChildren()) do
                if part:GetAttribute("_LUXY_PART") then
                    part:Destroy()
                end
            end
        end

        pcall(function()
            local plotId = LP:GetAttribute("PlotId")
            if plotId then
                local plot = workspace.Gardens:FindFirstChild("Plot" .. plotId)
                if plot then
                    local plantsFolder = plot:FindFirstChild("Plants")
                    if plantsFolder then
                        for _, child in ipairs(plantsFolder:GetChildren()) do
                            if child:GetAttribute("_LuxyVisual") then
                                local plantId = child:GetAttribute("PlantId")

                                local FruitsFolder = child:FindFirstChild("Fruits")
                                if FruitsFolder and FruitVisualizerController then
                                    for _, fruit in ipairs(FruitsFolder:GetChildren()) do
                                        local fruitId = fruit:GetAttribute("FruitId")
                                        if fruitId then
                                            pcall(function()
                                                FruitVisualizerController:RemoveFruitById(LP.UserId, plantId, fruitId)
                                            end)
                                        end
                                    end
                                end

                                if PlantVisualizerController and plantId then
                                    pcall(function()
                                        PlantVisualizerController:RemovePlantById(LP.UserId, plantId)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end)

        pcall(function()
            local weatherVal = RS:FindFirstChild("WeatherValues")
            if weatherVal then
                for _, name in ipairs(weatherList) do
                    weatherVal:SetAttribute(name .. "_Playing", false)
                    weatherVal:SetAttribute(name .. "_EndTime", nil)
                end
            end
        end)

        pcall(function()
            workspace:SetAttribute("ActivePhase", originalPhase)
            workspace:SetAttribute("ActiveWeather", originalWeather)
            workspace:SetAttribute("PhaseDuration", originalDuration)
        end)

        local storage = workspace:FindFirstChild("_LuxyPetStorage")
        if storage then storage:Destroy() end

        currentSlotIndex = 5
        print("[LUXY] All pets, seeds, visual plants, and data successfully cleared!")
    end)
end

return Spawner
