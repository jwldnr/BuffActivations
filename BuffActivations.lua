local AddonName, Addon = ...

-- locals and speed
local _G = _G
local ActionButton_ShowOverlayGlow = _G.ActionButton_ShowOverlayGlow
local ActionButton_HideOverlayGlow = _G.ActionButton_HideOverlayGlow
local GetActionInfo = _G.GetActionInfo
local GetMacroSpell = _G.GetMacroSpell
local IsSpellOverlayed = _G.IsSpellOverlayed    

local OnlyShowInCombat = true

local ACTION_BARS = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarLeftButton",
    "MultiBarRightButton"
}

local TRACKED_BUFFS = {
    [6673] = "Battle Shout", -- rank 1
    [5242] = "Battle Shout", -- rank 2
}

local function ShouldTrackBuff(id)
    return TRACKED_BUFFS[id] ~= nil
end


function Addon:HasBuff(id)
    for i = 1, #self.buffs do
        if (self.buffs[i] == id) then
            return true
        end
    end

    return false
end

function Addon:GetButtonsById(id)
    local buttons = {}

    for button, value in pairs(self.buttons) do
        if (value == id) then
            buttons[button] = value
        end
    end

    return buttons
end

function Addon:OnEvent(event, ...)
    local action = self[event]
  
    if (action) then
        action(self, ...)
    end
end

function Addon:UpdateActionButtons()
    self.buttons = {}

    for _, bar in ipairs(ACTION_BARS) do
        for i = 1, 12 do
            local button = _G[bar..i]
            local type, id = GetActionInfo(button.action)

            if (id and type == "spell") then
                if (ShouldTrackBuff(id)) then
                    self.buttons[button] = id
                end
            end

            if (id and type == "macro") then
                local spellId = GetMacroSpell(id)

                if (ShouldTrackBuff(spellId)) then
                    self.buttons[button] = spellId
                end
            end
        end
    end
end

function Addon:HideButtonOverlays()
    for button, value in pairs(self.buttons) do
        if (button.overlay and button.overlay:IsVisible()) then
            button.overlay.animOut:Play()

            ActionButton_HideOverlayGlow(button)
        end
    end
end

function Addon:UpdateButtonOverlays()
    self.buffs = {}

    local i = 1
    local name, _, _, _, _, _, _, _, _, id = UnitBuff("player", i)

    while (name) do
        self.buffs[#self.buffs + 1] = id

        i = i + 1
        name, _, _, _, _, _, _, _, _, id = UnitBuff("player", i)
    end

    if (self.onlyShowInCombat and not UnitAffectingCombat("player")) then
        return
    end

    for button, value in pairs(self.buttons) do
        if (self:HasBuff(value)) then
            -- print("got buff, hide overlay")

            ActionButton_HideOverlayGlow(button)
        else
            -- print("missing buff, show overlay")

            ActionButton_ShowOverlayGlow(button)
        end
    end
end

function Addon:ADDON_LOADED(name)
    if (AddonName == name) then
        self.frame:UnregisterEvent("ADDON_LOADED")
        
        print("BuffActivations loaded")
    end
end

function Addon:ACTIONBAR_SLOT_CHANGED(slot)
    local type, id = GetActionInfo(slot)

    self:UpdateActionButtons()
    self:UpdateButtonOverlays()
end

function Addon:UNIT_AURA()
    self:UpdateActionButtons()
    self:UpdateButtonOverlays()
end

function Addon:PLAYER_REGEN_ENABLED()
    self:HideButtonOverlays()
end

function Addon:PLAYER_ENTERING_WORLD()
    self:UpdateActionButtons()
    self:UpdateButtonOverlays()
end

function Addon:Load()
    self.buttons = {}
    self.onlyShowInCombat = true -- TODO

    self.frame = CreateFrame("Frame", nil)
    
    self.frame:SetScript("OnEvent", function(_, ...)
        self:OnEvent(...)
    end)

    self.frame:RegisterEvent("ADDON_LOADED")

    self.frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    self.frame:RegisterUnitEvent("UNIT_AURA", "player")

    self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
end

Addon:Load()