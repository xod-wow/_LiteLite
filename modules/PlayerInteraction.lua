local _, addon = ...

local function OnShow(_ownerID, id)
    if id == Enum.PlayerInteractionType.ItemUpgrade then
        ToggleCharacter("PaperDollFrame")
    end
end

EventRegistry:RegisterFrameEventAndCallback('PLAYER_INTERACTION_MANAGER_FRAME_SHOW', OnShow)
