--- Unit tests for Data/ JSON files validation.
--- Run with: busted tests/

package.path = package.path .. ";tests/?.lua"
local utils = require("utils")

-- Minimal JSON parser for the simple structure we need
local function parse_json_file(path)
    local f = io.open(path, "r")
    if not f then return nil, "cannot open file" end
    local content = f:read("*a")
    f:close()
    -- Decode using Lua pattern matching (handles the flat {Images: {k:v}} structure)
    local images = {}
    local images_block = content:match('"Images"%s*:%s*{(.-)}%s*}')
    if not images_block then
        return nil, "Images block not found"
    end
    for key, val in images_block:gmatch('"([^"]+)"%s*:%s*"([^"]+)"') do
        images[key] = val
    end
    return { Images = images }
end

describe("Data/Kick A Lucky Blox.json", function()
    local data

    before_each(function()
        data = parse_json_file("Data/Kick A Lucky Blox.json")
    end)

    it("loads successfully", function()
        assert.is_not_nil(data)
    end)

    it("has an Images table", function()
        assert.is_not_nil(data.Images)
        assert.are.equal("table", type(data.Images))
    end)

    it("passes ValidateImagesData", function()
        local ok, err = utils.ValidateImagesData(data)
        assert.is_true(ok, err)
    end)

    it("contains known character entries", function()
        assert.is_not_nil(data.Images["Trippi Troppi"])
        assert.is_not_nil(data.Images["Bombardiro Crocodilo"])
        assert.is_not_nil(data.Images["Sigma Boy"])
    end)

    it("all image IDs are numeric strings", function()
        for name, id in pairs(data.Images) do
            assert.is_truthy(
                id:match("^%d+$"),
                "Expected numeric string for " .. name .. ", got: " .. id
            )
        end
    end)

    it("contains map/location entries", function()
        assert.is_not_nil(data.Images["Stadium"])
        assert.is_not_nil(data.Images["Disco"])
        assert.is_not_nil(data.Images["Void"])
    end)

    it("has a reasonable number of entries", function()
        local count = 0
        for _ in pairs(data.Images) do count = count + 1 end
        assert.is_true(count > 100, "Expected >100 entries, got " .. count)
    end)
end)

describe("ValidateImagesData edge cases", function()
    it("rejects non-table input", function()
        local ok, err = utils.ValidateImagesData("string")
        assert.is_false(ok)
        assert.is_truthy(err:find("not a table"))
    end)

    it("rejects missing Images field", function()
        local ok, err = utils.ValidateImagesData({ Other = {} })
        assert.is_false(ok)
        assert.is_truthy(err:find("Images"))
    end)

    it("accepts empty Images table", function()
        local ok = utils.ValidateImagesData({ Images = {} })
        assert.is_true(ok)
    end)

    it("rejects non-string values in Images", function()
        local ok, err = utils.ValidateImagesData({ Images = { valid = 123 } })
        assert.is_false(ok)
        assert.is_truthy(err:find("non%-string value"))
    end)
end)
