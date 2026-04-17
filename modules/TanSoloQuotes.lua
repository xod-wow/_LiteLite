-- Print some Star Wars quotes on encounter start and end for my toon TanSolo

local _, addon = ...

local StartQuotes = {
    "I have a bad feeling about this.",
    "Never tell me the odds!",
    "Let's keep a little optimism here.",
    "I expect to be well paid. I'm in it for the money.",
    "What good is a reward if you ain't around to use it?",
    "I take orders from just one person: me.",
    "You said you wanted to be around when I made a mistake, well, this could be it, sweetheart.",
    "Bring em on! I prefer a straight fight to all this sneaking around.",
}

local function StartQuote()
    if UnitName('player') == "Tansolo" and math.random() <= 0.2 then
        local n = math.random(#StartQuotes)
        SendChatMessage(StartQuotes[n], 'SAY')
    end
end

local EndQuotes = {
    "Don't everbody thank me at once.",
    "You know, sometimes I amaze even myself.",
    "You like me because I'm a scoundrel. There aren’t enough scoundrels in your life.",
    "Afraid I was gonna leave without giving you a goodbye kiss?",
    "Sorry about the mess.",
    "Come on, admit it. Sometimes you think I’m all right.",
    "Scoundrel? Scoundrel? I like the sound of that.",
    "No reward is worth this.",
}

local function EndQuote()
    if UnitName('player') == "Tansolo" and math.random() <= 0.2 then
        local n = math.random(#EndQuotes)
        SendChatMessage(EndQuotes[n], 'SAY')
    end
end

EventRegistry:RegisterFrameEventAndCallback("ENCOUNTER_START", StartQuote)
EventRegistry:RegisterFrameEventAndCallback("ENCOUNTER_END", EndQuote)
