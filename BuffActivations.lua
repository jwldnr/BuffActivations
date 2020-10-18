local AddonName, Addon = ...

-- locals and speed
local select = select
local pairs = pairs

local _G = _G
local CreateFrame = CreateFrame
local UnitBuff = UnitBuff

local ActionButton_ShowOverlayGlow = ActionButton_ShowOverlayGlow
local ActionButton_HideOverlayGlow = ActionButton_HideOverlayGlow

local GetActionInfo = GetActionInfo

local GetSpellInfo = GetSpellInfo
local GetMacroSpell = GetMacroSpell

local UnitAffectingCombat = UnitAffectingCombat

local ACTION_BUTTON_TEMPLATES = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarLeftButton",
    "MultiBarRightButton"
}

local UNIT_TAG_PLAYER = "player"

local ONLY_SHOW_IN_COMBAT = false

local ABILITY_TYPE_SPELL = "spell"
local ABILITY_TYPE_MACRO = "macro"

-- format: ["ability_name"] = "buff_name"
local BUFF_NAMES = {
    -- warrior
    ["Battle Shout"] = "Battle Shout",

    -- priest
    ["Power Word: Fortitude"] = "Power Word: Fortitude",

    -- warlock
    ["Soulstone"] = "Soulstone",

    -- mage
    ["Arcane Intellect"] = "Arcane Brilliance"
}

function Addon:GetBuffName(spell)
    return BUFF_NAMES[spell]
end

-- main
function Addon:Load()
    self.frame = CreateFrame("Frame", nil)
    
    self.frame:SetScript("OnEvent", function(_, ...)
        self:OnEvent(...)
    end)

    self.frame:RegisterEvent("ADDON_LOADED")
    self.frame:RegisterEvent("PLAYER_LOGIN")
end

function Addon:OnEvent(event, ...)
    local action = self[event]
  
    if (action) then
        action(self, ...)
    end
end

function Addon:UpdateActionButtons()
    self.buttons = {}

    for _, template in pairs(ACTION_BUTTON_TEMPLATES) do
        for i = 1, 12 do
            local button = _G[template..i]
            local type, id = GetActionInfo(button.action)
            local spell = nil

            if (id and type == ABILITY_TYPE_SPELL) then
                spell = GetSpellInfo(id)
            end

            if (id and type == ABILITY_TYPE_MACRO) then
                spell = GetSpellInfo(select(1, GetMacroSpell(id)))
            end

            local name = self:GetBuffName(spell)
            if (name) then
                self.buttons[button] = name
            end
        end
    end
end

function Addon:HideButtonOverlays()
    for button, _ in pairs(self.buttons) do
        if (button.overlay and button.overlay:IsVisible()) then
            button.overlay.animOut:Play()

            ActionButton_HideOverlayGlow(button)
        end
    end
end

function Addon:ToggleButtonOverlays()
    if (ONLY_SHOW_IN_COMBAT and not UnitAffectingCombat(UNIT_TAG_PLAYER)) then
        return
    end

    self.buffs = {}

    local i = 1
    local name = UnitBuff(UNIT_TAG_PLAYER, i)

    while (name) do
        self.buffs[name] = true

        i = i + 1
        name = UnitBuff(UNIT_TAG_PLAYER, i)
    end

    for button, buff in pairs(self.buttons) do
        if (self.buffs[buff]) then
            ActionButton_HideOverlayGlow(button)
        else
            ActionButton_ShowOverlayGlow(button)
        end
    end
end

function Addon:ADDON_LOADED(name)
    if (name == AddonName) then
        -- self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.frame:RegisterUnitEvent("UNIT_AURA", UNIT_TAG_PLAYER)

        print(name, "loaded")

        self.frame:UnregisterEvent("ADDON_LOADED")
    end
end

function Addon:UNIT_AURA()
    self:UpdateActionButtons()
    self:ToggleButtonOverlays()
end

function Addon:PLAYER_REGEN_ENABLED()
    self:HideButtonOverlays()
end

function Addon:PLAYER_LOGIN()
    self:UpdateActionButtons()
    self:ToggleButtonOverlays()

    self.frame:UnregisterEvent("PLAYER_LOGIN")
end

-- begin
Addon:Load()