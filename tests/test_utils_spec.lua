--- Unit tests for pure utility functions extracted from the Library modules.
--- Run with: busted tests/

package.path = package.path .. ";tests/?.lua"
local utils = require("utils")

describe("GetTableSize", function()
    it("returns 0 for an empty table", function()
        assert.are.equal(0, utils.GetTableSize({}))
    end)

    it("counts sequential entries", function()
        assert.are.equal(3, utils.GetTableSize({ "a", "b", "c" }))
    end)

    it("counts non-sequential (hash) entries", function()
        assert.are.equal(2, utils.GetTableSize({ x = 1, y = 2 }))
    end)

    it("counts mixed sequential and hash entries", function()
        assert.are.equal(4, utils.GetTableSize({ "a", "b", x = 1, y = 2 }))
    end)

    it("counts a single entry", function()
        assert.are.equal(1, utils.GetTableSize({ key = "val" }))
    end)

    it("counts entries with false values", function()
        assert.are.equal(2, utils.GetTableSize({ a = false, b = false }))
    end)

    it("ignores nil values", function()
        local t = { a = 1, b = nil, c = 3 }
        assert.are.equal(2, utils.GetTableSize(t))
    end)
end)

describe("Trim", function()
    it("removes leading whitespace", function()
        assert.are.equal("hello", utils.Trim("   hello"))
    end)

    it("removes trailing whitespace", function()
        assert.are.equal("hello", utils.Trim("hello   "))
    end)

    it("removes both leading and trailing whitespace", function()
        assert.are.equal("hello", utils.Trim("  hello  "))
    end)

    it("preserves inner whitespace", function()
        assert.are.equal("hello world", utils.Trim("  hello world  "))
    end)

    it("returns empty string for all-whitespace input", function()
        assert.are.equal("", utils.Trim("     "))
    end)

    it("returns the same string when no whitespace", function()
        assert.are.equal("hello", utils.Trim("hello"))
    end)

    it("handles tabs and newlines", function()
        assert.are.equal("data", utils.Trim("\t\n data \n\t"))
    end)

    it("handles empty string", function()
        assert.are.equal("", utils.Trim(""))
    end)
end)

describe("Round", function()
    it("floors when rounding is 0", function()
        assert.are.equal(3, utils.Round(3.7, 0))
    end)

    it("floors negative numbers towards negative infinity when rounding is 0", function()
        assert.are.equal(-4, utils.Round(-3.2, 0))
    end)

    it("rounds to 1 decimal place", function()
        assert.are.equal(3.1, utils.Round(3.14, 1))
    end)

    it("rounds to 2 decimal places", function()
        assert.are.equal(3.14, utils.Round(3.14159, 2))
    end)

    it("rounds to 3 decimal places", function()
        assert.are.equal(2.718, utils.Round(2.71828, 3))
    end)

    it("handles exact values", function()
        assert.are.equal(5.0, utils.Round(5.0, 1))
    end)

    it("handles zero", function()
        assert.are.equal(0, utils.Round(0, 0))
        assert.are.equal(0.0, utils.Round(0.0, 2))
    end)

    it("errors on negative rounding", function()
        assert.has_error(function()
            utils.Round(3.14, -1)
        end, "Invalid rounding number.")
    end)

    it("rounds 0.5 with rounding=0 to 0 (floor)", function()
        assert.are.equal(0, utils.Round(0.5, 0))
    end)

    it("handles large rounding precision", function()
        local result = utils.Round(1.123456789, 5)
        assert.are.equal(1.12346, result)
    end)
end)

describe("GetSchemeValue", function()
    local SchemeReplaceAlias = {
        RedColor   = "Red",
        WhiteColor = "White",
        DarkColor  = "Dark",
    }
    local SchemeAlias = {
        Red   = "RedColor",
        White = "WhiteColor",
        Dark  = "DarkColor",
    }

    it("returns nil for nil index", function()
        local lib = { Scheme = {} }
        local get = utils.MakeGetSchemeValue(lib, SchemeReplaceAlias, SchemeAlias)
        assert.is_nil(get(nil))
    end)

    it("returns direct scheme value", function()
        local lib = { Scheme = { AccentColor = "red" } }
        local get = utils.MakeGetSchemeValue(lib, SchemeReplaceAlias, SchemeAlias)
        assert.are.equal("red", get("AccentColor"))
    end)

    it("returns nil for unknown index", function()
        local lib = { Scheme = {} }
        local get = utils.MakeGetSchemeValue(lib, SchemeReplaceAlias, SchemeAlias)
        assert.is_nil(get("NonExistent"))
    end)

    it("replaces old alias with new key (RedColor -> Red migration)", function()
        local lib = { Scheme = { Red = "custom_red" } }
        local get = utils.MakeGetSchemeValue(lib, SchemeReplaceAlias, SchemeAlias)
        local val = get("RedColor")
        assert.are.equal("custom_red", val)
        assert.are.equal("custom_red", lib.Scheme.RedColor)
        assert.is_nil(lib.Scheme.Red)
    end)

    it("resolves deprecated alias (Red -> RedColor)", function()
        local lib = { Scheme = { RedColor = "the_red" } }
        local get = utils.MakeGetSchemeValue(lib, SchemeReplaceAlias, SchemeAlias)
        assert.are.equal("the_red", get("Red"))
    end)

    it("handles WhiteColor replace alias", function()
        local lib = { Scheme = { White = "w_value" } }
        local get = utils.MakeGetSchemeValue(lib, SchemeReplaceAlias, SchemeAlias)
        local val = get("WhiteColor")
        assert.are.equal("w_value", val)
        assert.is_nil(lib.Scheme.White)
    end)

    it("handles DarkColor replace alias", function()
        local lib = { Scheme = { Dark = "d_value" } }
        local get = utils.MakeGetSchemeValue(lib, SchemeReplaceAlias, SchemeAlias)
        local val = get("DarkColor")
        assert.are.equal("d_value", val)
    end)
end)
