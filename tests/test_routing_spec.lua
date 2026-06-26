--- Unit tests for main.lua routing logic and URL construction.
--- Run with: busted tests/

package.path = package.path .. ";tests/?.lua"
local utils = require("utils")

describe("Route map (main.lua logic)", function()
    it("maps Kalb place ID to Kalb.lua", function()
        assert.are.equal("Kalb.lua", utils.ResolveRoute(89469502395769))
    end)

    it("maps first speed keyboard escape place ID", function()
        assert.are.equal("speed keyboard escape.lua", utils.ResolveRoute(95082159892680))
    end)

    it("maps second speed keyboard escape place ID", function()
        assert.are.equal("speed keyboard escape.lua", utils.ResolveRoute(118941584817777))
    end)

    it("maps grow a garden 2 place ID", function()
        assert.are.equal("grow a garden 2.lua", utils.ResolveRoute(97598239454123))
    end)

    it("returns nil for unknown place ID", function()
        assert.is_nil(utils.ResolveRoute(0))
    end)

    it("returns nil for arbitrary place ID", function()
        assert.is_nil(utils.ResolveRoute(99999999999999))
    end)

    it("route map has exactly 4 entries", function()
        local map = utils.BuildRouteMap()
        local count = 0
        for _ in pairs(map) do count = count + 1 end
        assert.are.equal(4, count)
    end)

    it("all route values end with .lua", function()
        local map = utils.BuildRouteMap()
        for _, v in pairs(map) do
            assert.is_truthy(v:match("%.lua$"), "Expected .lua suffix: " .. v)
        end
    end)
end)

describe("BuildScriptURL", function()
    it("constructs correct URL for Kalb.lua", function()
        local url = utils.BuildScriptURL("Kalb.lua", "12345")
        assert.are.equal(
            "https://raw.githubusercontent.com/Omnie7/Luxy-Hub/refs/heads/main/Game/Kalb.lua?nocache=12345",
            url
        )
    end)

    it("constructs correct URL with numeric cache buster", function()
        local url = utils.BuildScriptURL("grow a garden 2.lua", 55555)
        assert.are.equal(
            "https://raw.githubusercontent.com/Omnie7/Luxy-Hub/refs/heads/main/Game/grow a garden 2.lua?nocache=55555",
            url
        )
    end)

    it("includes nocache parameter", function()
        local url = utils.BuildScriptURL("test.lua", "99999")
        assert.is_truthy(url:find("nocache=99999", 1, true))
    end)

    it("starts with the raw GitHub base URL", function()
        local url = utils.BuildScriptURL("any.lua", "1")
        assert.is_truthy(url:find("https://raw.githubusercontent.com/Omnie7/Luxy%-Hub", 1))
    end)
end)
