local _, addon = ...

local CVarNames = {
    "Sound_EnableAllSound",
    "Sound_EnableAmbience",
    "Sound_EnablePetSounds",
    "Sound_EnableSFX",
    "Sound_EnableSoundWhenGameIsInBG",
    "Sound_MasterVolume",
    "Sound_MusicVolume",
    "Sound_SFXVolume",
}

local SavedCVars

local function SaveCVars()
    SavedCVars = {}
    for _, cv in ipairs(CVarNames) do
        SavedCVars[cv] = GetCVar(cv)
    end
end

local function RestoreCVars()
    for k, v in pairs(SavedCVars) do
        SetCVar(k, v)
    end
end

local function EnhanceSounds()
    SetCVar("Sound_EnableAllSound", 1)
    SetCVar("Sound_EnableAmbience", 0)
    SetCVar("Sound_EnablePetSounds", 0)
    SetCVar("Sound_EnableSFX", 1)
    SetCVar("Sound_EnableSoundWhenGameIsInBG", 1)
    SetCVar("Sound_MasterVolume", 1)
    SetCVar("Sound_MusicVolume", 0)
    SetCVar("Sound_SFXVolume", 1)
end

local function PrintVenom()
    local ttInfo = C_TooltipInfo.GetItemByID(244790)
    for _, line in ipairs(ttInfo.lines) do
        local venom = line.leftText:match('%+%d+ Venom')
        if venom then
            addon.printf(venom)
            return
        end
    end
end

local FishingSpells = {
    [131476] = "SPELL Fishing",     -- Base
    [1224771] = "INTERACTTARGET",   -- Void Hole Fishing
}

local isFishing = false

-- This works a bit weirdly, because the bindings are run on both keydown and
-- keyup. And you can change them in between. So after the first trigger,
-- space does INTERRACTTARGET on keydown and SPELL Fishing on keyup: if you
-- press slowly you get the interract and the recast in one push. If you are
-- too quick you will get the recast before the interact has time to finish
-- looting.

local function OnEvent(self, event, ...)
    if event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unitToken, _, spellID = ...
        if unitToken == "player" and FishingSpells[spellID] then
            -- print('fish')
            SaveCVars()
            EnhanceSounds()
            SetOverrideBinding(self, true, "SPACE", "INTERACTTARGET")
            isFishing = true
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        local unitToken, _, spellID = ...
        if unitToken == "player" and FishingSpells[spellID] then
            -- print('unfish')
            RestoreCVars()
            SetOverrideBinding(self, true, "SPACE", FishingSpells[spellID])
            C_Timer.After(2, function () if not isFishing then ClearOverrideBindings(self) end end)
            isFishing = false
            C_Timer.After(1, PrintVenom)
        end
    end
end

local function Initialize()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    eventFrame:SetScript("OnEvent", OnEvent)
end

addon.RegisterModule({ Initialize = Initialize })
