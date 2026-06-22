-- Bind a key to place rotating world markers, as per a very old weakaura
-- and then I made it into this when that stopped working.
--
-- Also does ping mouseover now, just not very well.

local _, addon = ...

-- function (self, button, down)
local function Initialize()
    local b = CreateFrame('Button', 'RotatingMarker', nil, 'SecureActionButtonTemplate')
    -- https://github.com/Stanzilla/WoWUIBugs/issues/317#issuecomment-1510847497
    b:SetAttribute("pressAndHoldAction", true)
    b:SetAttribute("type", "macro")
    b:SetAttribute("typerelease", "macro")

    SecureHandlerWrapScript(b, 'PreClick', b,
        [[
            if button == "0" then
                self:SetAttribute("macrotext", "/cwm all")
            elseif tonumber(button) then
                self:SetAttribute("macrotext", "/wm [@cursor] "..button)
            elseif IsShiftKeyDown() then
                self:SetAttribute("macrotext", "/ping [@mouseover,help] warning; [@mouseover] attack")
            elseif IsControlKeyDown() then
                self:SetAttribute("n", 0)
                self:SetAttribute("macrotext", "/cwm all")
            else
                local n = ( self:GetAttribute("n") or 0 ) % 8 + 1
                self:SetAttribute("n", n)
                self:SetAttribute("macrotext", "/wm [@cursor] " .. n)
            end
        ]])
end

addon.RegisterModule({ Initialize = Initialize })
