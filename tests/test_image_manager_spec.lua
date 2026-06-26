--- Unit tests for CustomImageManager (both V1 and V2 variants).
--- Run with: busted tests/

package.path = package.path .. ";tests/?.lua"
local utils = require("utils")

describe("CustomImageManager V2 (LuxyLibraryV2)", function()
    local mgr

    before_each(function()
        mgr = utils.MakeImageManagerV2()
    end)

    it("returns TransparencyTexture asset id", function()
        assert.are.equal("rbxassetid://139785960036434", mgr.GetAsset("TransparencyTexture"))
    end)

    it("returns SaturationMap asset id", function()
        assert.are.equal("rbxassetid://4155801252", mgr.GetAsset("SaturationMap"))
    end)

    it("returns empty string for unknown asset", function()
        assert.are.equal("", mgr.GetAsset("DoesNotExist"))
    end)

    it("returns empty string for nil-ish name", function()
        assert.are.equal("", mgr.GetAsset(""))
    end)

    it("is case-sensitive", function()
        assert.are.equal("", mgr.GetAsset("transparencytexture"))
        assert.are.equal("", mgr.GetAsset("SATURATIONMAP"))
    end)
end)

describe("CustomImageManager V1 (LuxyHub)", function()
    local mgr

    before_each(function()
        mgr = utils.MakeImageManagerV1()
    end)

    it("returns TransparencyTexture with rbxassetid prefix", function()
        local id = mgr.GetAsset("TransparencyTexture")
        assert.are.equal("rbxassetid://139785960036434", id)
    end)

    it("returns SaturationMap with rbxassetid prefix", function()
        local id = mgr.GetAsset("SaturationMap")
        assert.are.equal("rbxassetid://4155801252", id)
    end)

    it("caches the id after first call", function()
        local id1 = mgr.GetAsset("TransparencyTexture")
        local id2 = mgr.GetAsset("TransparencyTexture")
        assert.are.equal(id1, id2)
    end)

    it("returns nil for unknown asset", function()
        assert.is_nil(mgr.GetAsset("UnknownAsset"))
    end)

    describe("AddAsset", function()
        it("registers a new asset", function()
            mgr.AddAsset("CustomIcon", 12345)
            local id = mgr.GetAsset("CustomIcon")
            assert.are.equal("rbxassetid://12345", id)
        end)

        it("errors when adding duplicate asset", function()
            assert.has_error(function()
                mgr.AddAsset("TransparencyTexture", 999)
            end)
        end)

        it("errors when RobloxAssetId is not a number", function()
            assert.has_error(function()
                mgr.AddAsset("Bad", "not_a_number")
            end)
        end)

        it("allows adding multiple unique assets", function()
            mgr.AddAsset("Icon1", 111)
            mgr.AddAsset("Icon2", 222)
            assert.are.equal("rbxassetid://111", mgr.GetAsset("Icon1"))
            assert.are.equal("rbxassetid://222", mgr.GetAsset("Icon2"))
        end)
    end)
end)
