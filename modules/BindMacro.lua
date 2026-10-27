-- Quickly bind a key to run an ad-hoc macro, so I can set up spammable
-- /tar X etc.

local _, addon = ...

local BindMacroButton = CreateFrame('Button', '_LLBM', nil, 'SecureActionButtonTemplate')
BindMacroButton:RegisterForClicks('AnyDown', 'AnyUp')

local function SetBindMacro()
    if addon.db.bindKey and addon.db.bindMacro then
        BindMacroButton:SetAttribute('type', 'macro')
        BindMacroButton:SetAttribute('macrotext', addon.db.bindMacro)
        SetOverrideBindingClick(BindMacroButton, true, addon.db.bindKey, BindMacroButton:GetName())
    end
end

local function SlashCommand(arg)
    if not arg or arg == '' then
        addon.printf('BindMacro key=%s', tostring(addon.db.bindKey))
        addon.printf(addon.db.bindMacro)
        return true
    end
    local arg1, arg2 = string.split(' ', arg, 2)
    if arg1 and arg1 ~= '' and arg2 and arg2 ~= '' then
        addon.db.bindKey = arg1
        addon.db.bindMacro = arg2:gsub("%|", "\n")
        SetBindMacro()
    end
end

local moduleInfo = {
    Initialize = SetBindMacro,
    HelpLines = {
        "bind-macro | bm <key> <macrocommand>",
    },
    SlashCommands = {
        ['bind-macro'] = SlashCommand,
        ['bm'] = SlashCommand,
    }
}
addon.RegisterModule(moduleInfo)
