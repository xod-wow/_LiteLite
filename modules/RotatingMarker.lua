local _, addon = ...

-- Also does ping mouseover now

local function Initialize()
    local b = CreateFrame('Button', 'RotatingMarker', nil, 'SecureActionButtonTemplate')
    -- https://github.com/Stanzilla/WoWUIBugs/issues/317#issuecomment-1510847497
    b:SetAttribute("pressAndHoldAction", true)
    b:SetAttribute("type", "macro")
    b:SetAttribute("typerelease", "macro")

    SecureHandlerWrapScript(b, 'PreClick', b,
        [[
            if IsShiftKeyDown() then
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
