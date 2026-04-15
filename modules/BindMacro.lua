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
    local arg1, arg2 = string.split(' ', arg, 2)
    addon.db.bindKey = arg2
    addon.db.bindMacro = arg3:gsub("\\n", "\n")
    self:SetBindMacro()
end

local moduleInfo = {
    Initialize = SetBindMacro,
    SlashCommands = {
        ['bind-macro'] = SlashCommand,
        ['bm'] = SlashCommand,
    }
}
addon.RegisterModule(moduleInfo)
