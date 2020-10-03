local AddonName, Addon = ...

-- locals and speed
local select = select

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

local ABILITIES = {
    -- warrior
    ["Battle Shout"] = true,

    -- priest
    ["Power Word: Fortitude"] = true,

    -- warlock
    ["Soulstone"] = true
}

function Addon:HasBuff(name)
    for i = 1, #self.buffs do
        if (self.buffs[i] == name) then
            return true
        end
    end

    return false
end

function Addon:OnEvent(event, ...)
    local action = self[event]
  
    if (action) then
        action(self, ...)
    end
end

function Addon:UpdateActionButtons()
    self.buttons = {}

    for _, template in ipairs(ACTION_BUTTON_TEMPLATES) do
        for i = 1, 12 do
            local button = _G[template..i]
            local type, id = GetActionInfo(button.action)
            local name = nil

            if (id and type == ABILITY_TYPE_SPELL) then
                name = GetSpellInfo(id)
            end

            if (id and type == ABILITY_TYPE_MACRO) then
                name = GetSpellInfo(select(1, GetMacroSpell(id)))
            end

            if (name and ABILITIES[name]) then
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
    if (ONLY_SHOW_IN_COMBAT and not UnitAffectingCombat(PLAYER)) then
        return
    end

    self.buffs = {}

    local i = 1
    local buff = UnitBuff(UNIT_TAG_PLAYER, i)

    while (buff) do
        self.buffs[#self.buffs + 1] = buff

        i = i + 1
        buff = UnitBuff(UNIT_TAG_PLAYER, i)
    end

    for button, name in pairs(self.buttons) do
        if (self:HasBuff(name)) then
            ActionButton_HideOverlayGlow(button)
        else
            ActionButton_ShowOverlayGlow(button)
        end
    end
end

function Addon:ADDON_LOADED(name)
    if (AddonName == name) then
        self.frame:UnregisterEvent("ADDON_LOADED")
        
        print(AddonName, "loaded")
    end
end

function Addon:UNIT_AURA()
    self:UpdateActionButtons()
    self:ToggleButtonOverlays()
end

function Addon:PLAYER_REGEN_ENABLED()
    self:HideButtonOverlays()
end

function Addon:PLAYER_ENTERING_WORLD()
    self:UpdateActionButtons()
    self:ToggleButtonOverlays()
end

function Addon:Load()
    self.frame = CreateFrame("Frame", nil)
    
    self.frame:SetScript("OnEvent", function(_, ...)
        self:OnEvent(...)
    end)

    self.frame:RegisterEvent("ADDON_LOADED")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")

    self.frame:RegisterUnitEvent("UNIT_AURA", UNIT_TAG_PLAYER)
end

Addon:Load()