--[[
    Shared scheme/theme helper functions and constants.
    Used by both LuxyHub and LuxyLibraryV2 for color scheme resolution.
]]

local SchemeHelpers = {}

SchemeHelpers.Places = { Bottom = { 0, 1 }, Right = { 1, 0 } }
SchemeHelpers.Sizes = { Left = { 0.5, 1 }, Right = { 0.5, 1 } }

SchemeHelpers.SchemeReplaceAlias = {
    RedColor = "Red",
    WhiteColor = "White",
    DarkColor = "Dark",
}

SchemeHelpers.SchemeAlias = {
    Red = "RedColor",
    White = "WhiteColor",
    Dark = "DarkColor",
}

function SchemeHelpers.GetSchemeValue(Library, Index)
    if not Index then
        return nil
    end
    local ReplaceAliasIndex = SchemeHelpers.SchemeReplaceAlias[Index]
    if ReplaceAliasIndex
        and Library.Scheme[ReplaceAliasIndex] ~= nil
    then
        Library.Scheme[Index] = Library.Scheme[ReplaceAliasIndex]
        Library.Scheme[ReplaceAliasIndex] = nil
        return Library.Scheme[Index]
    end
    local AliasIndex = SchemeHelpers.SchemeAlias[Index]
    if AliasIndex and Library.Scheme[AliasIndex] ~= nil then
        warn(string.format(
            "Scheme Value %q is deprecated, please use %q instead.",
            Index,
            AliasIndex
        ))
        return Library.Scheme[AliasIndex]
    end
    return Library.Scheme[Index]
end

return SchemeHelpers
