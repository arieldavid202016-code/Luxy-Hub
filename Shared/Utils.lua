--[[
    Shared utility functions used across LuxyHub and LuxyLibraryV2.
    Avoids duplicating common helpers in both Library files.
]]

local Utils = {}

function Utils.GetTableSize(Table)
    local Size = 0
    for _, _ in Table do
        Size = Size + 1
    end
    return Size
end

function Utils.StopTween(Tween)
    if not (
        Tween
        and Tween.PlaybackState == Enum.PlaybackState.Playing
    ) then
        return
    end
    Tween:Cancel()
end

function Utils.Trim(Text)
    return Text:match("^%s*(.-)%s*$")
end

function Utils.Round(Value, Rounding)
    assert(Rounding >= 0, "Invalid rounding number.")
    if Rounding == 0 then
        return math.floor(Value)
    end
    return tonumber(string.format("%." .. Rounding .. "f", Value))
end

function Utils.WaitForEvent(Event, Timeout, Condition)
    local Bindable = Instance.new("BindableEvent")
    local Connection = Event:Once(function(...)
        if not Condition
            or (typeof(Condition) == "function" and Condition(...))
        then
            Bindable:Fire(true)
        else
            Bindable:Fire(false)
        end
    end)
    task.delay(Timeout, function()
        Connection:Disconnect()
        Bindable:Fire(false)
    end)
    local Result = Bindable.Event:Wait()
    Bindable:Destroy()
    return Result
end

function Utils.IsMouseInput(Input, IncludeM2)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or (IncludeM2 == true
            and Input.UserInputType == Enum.UserInputType.MouseButton2)
        or Input.UserInputType == Enum.UserInputType.Touch
end

function Utils.IsClickInput(Input, IncludeM2, IsRobloxFocused)
    return Utils.IsMouseInput(Input, IncludeM2)
        and Input.UserInputState == Enum.UserInputState.Begin
        and IsRobloxFocused
end

function Utils.IsHoverInput(Input)
    return (
        Input.UserInputType == Enum.UserInputType.MouseMovement
        or Input.UserInputType == Enum.UserInputType.Touch
    )
        and Input.UserInputState == Enum.UserInputState.Change
end

function Utils.IsDragInput(Input, IncludeM2, IsRobloxFocused)
    return Utils.IsMouseInput(Input, IncludeM2)
        and (
            Input.UserInputState == Enum.UserInputState.Begin
            or Input.UserInputState == Enum.UserInputState.Change
        )
        and IsRobloxFocused
end

function Utils.GetPlayers(Players, LocalPlayer, ExcludeLocalPlayer)
    local PlayerList = Players:GetPlayers()
    if ExcludeLocalPlayer then
        local Idx = table.find(PlayerList, LocalPlayer)
        if Idx then
            table.remove(PlayerList, Idx)
        end
    end
    table.sort(PlayerList, function(Player1, Player2)
        return Player1.Name:lower() < Player2.Name:lower()
    end)
    return PlayerList
end

function Utils.GetTeams(Teams)
    local TeamList = Teams:GetTeams()
    table.sort(TeamList, function(Team1, Team2)
        return Team1.Name:lower() < Team2.Name:lower()
    end)
    return TeamList
end

return Utils
