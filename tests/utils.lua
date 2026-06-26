--- Standalone re-exports of pure utility functions from the Library modules.
--- These are exact copies of the logic, kept in sync for unit-testing
--- without requiring full Roblox runtime initialization.

local M = {}

--------------------------------------------------------------------------
-- GetTableSize: count all entries in a table (works for non-sequential too)
--------------------------------------------------------------------------
function M.GetTableSize(Table)
    local Size = 0
    for _, _ in pairs(Table) do
        Size = Size + 1
    end
    return Size
end

--------------------------------------------------------------------------
-- Trim: strip leading/trailing whitespace
--------------------------------------------------------------------------
function M.Trim(Text)
    return Text:match("^%s*(.-)%s*$")
end

--------------------------------------------------------------------------
-- Round: round a numeric value to a given number of decimal places
--------------------------------------------------------------------------
function M.Round(Value, Rounding)
    assert(Rounding >= 0, "Invalid rounding number.")
    if Rounding == 0 then
        return math.floor(Value)
    end
    return tonumber(string.format("%." .. Rounding .. "f", Value))
end

--------------------------------------------------------------------------
-- GetSchemeValue: resolve scheme aliases with deprecation handling
--------------------------------------------------------------------------
function M.MakeGetSchemeValue(Library, SchemeReplaceAlias, SchemeAlias)
    return function(Index)
        if not Index then
            return nil
        end
        local ReplaceAliasIndex = SchemeReplaceAlias[Index]
        if ReplaceAliasIndex and Library.Scheme[ReplaceAliasIndex] ~= nil then
            Library.Scheme[Index] = Library.Scheme[ReplaceAliasIndex]
            Library.Scheme[ReplaceAliasIndex] = nil
            return Library.Scheme[Index]
        end
        local AliasIndex = SchemeAlias[Index]
        if AliasIndex and Library.Scheme[AliasIndex] ~= nil then
            return Library.Scheme[AliasIndex]
        end
        return Library.Scheme[Index]
    end
end

--------------------------------------------------------------------------
-- CustomImageManager.GetAsset (V2 simplified variant)
--------------------------------------------------------------------------
function M.MakeImageManagerV2()
    local mgr = {}
    function mgr.GetAsset(AssetName)
        if AssetName == "TransparencyTexture" then
            return "rbxassetid://139785960036434"
        elseif AssetName == "SaturationMap" then
            return "rbxassetid://4155801252"
        end
        return ""
    end
    return mgr
end

--------------------------------------------------------------------------
-- CustomImageManager with asset registry (V1 / LuxyHub variant)
--------------------------------------------------------------------------
function M.MakeImageManagerV1()
    local assets = {
        TransparencyTexture = {
            RobloxId = 139785960036434,
            Id = nil,
        },
        SaturationMap = {
            RobloxId = 4155801252,
            Id = nil,
        },
    }
    local mgr = {}

    function mgr.GetAsset(AssetName)
        if not assets[AssetName] then
            return nil
        end
        local data = assets[AssetName]
        if data.Id then
            return data.Id
        end
        local id = string.format("rbxassetid://%s", data.RobloxId)
        data.Id = id
        return id
    end

    function mgr.AddAsset(AssetName, RobloxAssetId)
        if assets[AssetName] ~= nil then
            error(string.format("Asset %q already exists", AssetName))
        end
        assert(type(RobloxAssetId) == "number", "RobloxAssetId must be a number")
        assets[AssetName] = {
            RobloxId = RobloxAssetId,
            Id = nil,
        }
    end

    function mgr.GetAssets() return assets end

    return mgr
end

--------------------------------------------------------------------------
-- BuildRouteMap: replicates the place-ID-to-script mapping from main.lua
--------------------------------------------------------------------------
function M.BuildRouteMap()
    return {
        [89469502395769]  = "Kalb.lua",
        [95082159892680]  = "speed keyboard escape.lua",
        [118941584817777] = "speed keyboard escape.lua",
        [97598239454123]  = "grow a garden 2.lua",
    }
end

--------------------------------------------------------------------------
-- ResolveRoute: given a PlaceId, return the script filename or nil
--------------------------------------------------------------------------
function M.ResolveRoute(placeId)
    local routes = M.BuildRouteMap()
    return routes[placeId]
end

--------------------------------------------------------------------------
-- BuildScriptURL: constructs the raw GitHub URL for a game script
--------------------------------------------------------------------------
function M.BuildScriptURL(scriptName, cacheBuster)
    return "https://raw.githubusercontent.com/Omnie7/Luxy-Hub/refs/heads/main/Game/"
        .. scriptName
        .. "?nocache="
        .. tostring(cacheBuster)
end

--------------------------------------------------------------------------
-- ParseDataJSON: validates structure expectations of Data JSON files
-- (checks that Images is a table of string->string entries)
--------------------------------------------------------------------------
function M.ValidateImagesData(data)
    if type(data) ~= "table" then
        return false, "data is not a table"
    end
    if type(data.Images) ~= "table" then
        return false, "data.Images is not a table"
    end
    for name, id in pairs(data.Images) do
        if type(name) ~= "string" then
            return false, "non-string key found: " .. tostring(name)
        end
        if type(id) ~= "string" then
            return false, "non-string value for key: " .. name
        end
    end
    return true, nil
end

return M
