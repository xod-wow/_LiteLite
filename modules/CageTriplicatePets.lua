local _, addon = ...

-- Cage any battle pets we have 3 of
local function CageTriplicatePets()
    local counts = {}

    -- Assumption is that the pet indexes are ordered by level
    -- with the highest first, so we will always cage the lowest
    -- level one.

    for i = 1, C_PetJournal.GetNumPets() do
       local info = { C_PetJournal.GetPetInfoByIndex(i) }
       counts[info[2]] = ( counts[info[2]] or 0 ) + 1
       if counts[info[2]] > 2 and info[16] and info[1] then
          C_PetJournal.CagePetByID(info[1])
       end
    end
end

local moduleInfo = {
    HelpLines = {
        "cage-pets | cp",
    },
    SlashCommands = {
        ['cage-pets'] = CageTriplicatePets,
        ['cp'] = CageTriplicatePets,
    }
}
addon.RegisterModule(moduleInfo)
