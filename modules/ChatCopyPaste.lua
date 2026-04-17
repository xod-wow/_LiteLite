-- Copy chat, chat paste and run each line as a macro, decode
-- C_EncodingUtil blobs to look at.

local _, addon = ...

local function CopyChat(sourceFrame)
    sourceFrame = sourceFrame or SELECTED_CHAT_FRAME
    local lines = {}
    for i = 1, sourceFrame:GetNumMessages() do
        local msg = sourceFrame:GetMessageInfo(i)
        msg = msg:gsub("|K(.-)|k", "<kstring>")
        table.insert(lines, msg or "")
    end
    _LiteLiteText.EditBox:SetText(table.concat(lines, "\n"))
    _LiteLiteText:Show()
end

local function ApplyPaste()
    local text = _LiteLiteText.EditBox:GetText()
    ChatFrame_OpenChat("")
    local edit = ChatEdit_GetActiveWindow()
    for _, line in ipairs({ string.split("\n", text) }) do
        edit:SetText(line)
        ChatEdit_SendText(edit, 1)
        ChatEdit_DeactivateChat(edit)
    end
end

local function CopyPaste()
    _LiteLiteText.ApplyFunc = ApplyPaste
    _LiteLiteText.EditBox:SetText('')
    _LiteLiteText:Show()
end

local function ApplyDecode()
    local encoded = _LiteLiteText.EditBox:GetText()
    local compressed = C_EncodingUtil.DecodeBase64(encoded)
    if not compressed then return end
    local serialized = C_EncodingUtil.DecompressString(compressed)
    if not serialized then return end
    local data = C_EncodingUtil.DeserializeCBOR(serialized)
    if not data then return end
    _LiteLiteText.EditBox:SetText(LM.TableToString(data))
end

local function Decode()
    _LiteLiteText.ApplyFunc = ApplyDecode
    _LiteLiteText.EditBox:SetText('')
    _LiteLiteText:Show()
end

local moduleInfo = {
    HelpLines = {
        "copy-chat | cc",
        "decode",
        "paste",
    },
    SlashCommands = {
        ['copy-chat'] = CopyChat,
        ['cc'] = CopyChat,
        ['paste'] = CopyPaste,
        ['decode'] = Decode,
    }
}
addon.RegisterModule(moduleInfo)
