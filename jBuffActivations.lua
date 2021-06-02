local AddonName, Addon = ...

-- locals and speed
local pairs = pairs
local select = select

local CreateFrame = CreateFrame
local UIParent = UIParent

local UnitExists = UnitExists
local UnitIsFriend = UnitIsFriend
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitClass = UnitClass

local GetActionInfo = GetActionInfo
local GetSpellInfo = GetSpellInfo
local GetMacroSpell = GetMacroSpell

local ACTION_BUTTON_TEMPLATES = {
  "ActionButton",
  "MultiBarBottomLeftButton",
  "MultiBarBottomRightButton",
  "MultiBarLeftButton",
  "MultiBarRightButton"
}

local UNIT_PLAYER = "player"
local UNIT_TARGET = "target"

local ABILITY_TYPE_SPELL = "spell"
local ABILITY_TYPE_MACRO = "macro"

local SHIELD_BUFF_NAME = "Power Word: Shield"
local SHIELD_DEBUFF_NAME = "Weakened Soul"

local HEALTH_THRESHOLD = 95

-- overlay stuff
local numOverlays = 0
local overlays = {}

local AnimateTexCoords = AnimateTexCoords

-- local DEBUG = true

local function debug(message)
  if (DEBUG or false) then
    print("["..AddonName.."]", message)
  end
end

-- format: ["ability_name"] = "buff_name"
local BUFF_NAMES = {
    -- warrior
    ["Battle Shout"] = "Battle Shout",

    -- priest
    ["Power Word: Fortitude"] = "Power Word: Fortitude",
    ["Divine Spirit"] = "Divine Spirit",
    ["Shadow Protection"] = "Shadow Protection",

    -- warlock
    ["Soulstone"] = "Soulstone",

    -- mage
    ["Arcane Intellect"] = "Arcane Brilliance"
}

local function GetBuffName(name)
    return BUFF_NAMES[name]
end

local function GetOverlay(key)
  return overlays[key]
end

local function AnimIn_OnPlay(self)
  local frame = self:GetParent()
  local width, height = frame:GetSize()

  frame.spark:SetSize(width, height)
  frame.spark:SetAlpha(0.3)

  frame.innerGlow:SetSize(width, height)
  frame.innerGlow:SetAlpha(1.0)

  frame.innerGlowOver:SetAlpha(1.0)

  frame.outerGlow:SetSize(width * 2, height * 2)
  frame.outerGlow:SetAlpha(1.0)

  frame.outerGlowOver:SetAlpha(1.0)

  frame.ants:SetSize(width * 0.85, height * 0.85)
  frame.ants:SetAlpha(0)

  frame:Show()
end

local function AnimIn_OnFinished(self)
  local frame = self:GetParent()
  local width, height = frame:GetSize()

  frame.spark:SetAlpha(0)

  frame.innerGlow:SetAlpha(0)
  frame.innerGlow:SetSize(width, height)

  frame.innerGlowOver:SetAlpha(0)

  frame.outerGlow:SetSize(width, height)

  frame.outerGlowOver:SetAlpha(0)
  frame.outerGlowOver:SetSize(width, height)

  frame.ants:SetAlpha(1)
end

local function AnimOut_OnFinished(self)
  local overlay = self:GetParent()

  overlay:Hide()
end

local function Anim_OnUpdate(self, elapsed)
  AnimateTexCoords(self.ants, 256, 256, 48, 48, 22, elapsed, 0.01)
end

local function CreateOverlay(button)
  numOverlays = numOverlays + 1

  -- create overlay
  local name = button:GetName()
  local frame = CreateFrame("Frame", name.."ShieldOverlay"..numOverlays, UIParent)
  frame:SetFrameStrata("HIGH")

  local width, height = button:GetSize()

  frame:SetParent(button)
  frame:ClearAllPoints()

  --Make the height/width available before the next frame:
  frame:SetSize(width * 1.4, height * 1.4)
  frame:SetPoint("TOPLEFT", button, "TOPLEFT", -width * 0.2, height * 0.2)
  frame:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", width * 0.2, -height * 0.2)

  -- create textures
  -- spark
  frame.spark = frame:CreateTexture("$parentSpark", "BACKGROUND")
  frame.spark:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
  frame.spark:SetTexCoord(0.00781250, 0.61718750, 0.00390625, 0.26953125)
  -- frame.spark:SetVertexColor(0, 1, 1)
  frame.spark:SetAlpha(0)
  frame.spark:SetPoint("CENTER", frame)

  -- inner glow
  frame.innerGlow = frame:CreateTexture("$parentInnerGlow", "ARTWORK")
  frame.innerGlow:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
  frame.innerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
  -- frame.innerGlow:SetVertexColor(0, 1, 1)
  frame.innerGlow:SetAlpha(0)
  frame.innerGlow:SetPoint("CENTER", frame)

  -- inner glow over
  frame.innerGlowOver = frame:CreateTexture("$parentInnerGlowOver", "ARTWORK")
  frame.innerGlowOver:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
  frame.innerGlowOver:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)
  -- frame.innerGlowOver:SetVertexColor(0, 1, 1)
  frame.innerGlowOver:SetAlpha(0)
  frame.innerGlowOver:SetPoint("TOPLEFT", frame.innerGlow, "TOPLEFT")
  frame.innerGlowOver:SetPoint("BOTTOMRIGHT", frame.innerGlow, "BOTTOMRIGHT")

  -- outer glow
  frame.outerGlow = frame:CreateTexture("$parentOuterGlow", "ARTWORK")
  frame.outerGlow:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
  frame.outerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
  -- frame.outerGlow:SetVertexColor(0, 1, 1)
  frame.outerGlow:SetAlpha(0)
  frame.outerGlow:SetPoint("CENTER", frame)

  -- outer glow over
  frame.outerGlowOver = frame:CreateTexture("$parentOuterGlowOver", "ARTWORK")
  frame.outerGlowOver:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
  frame.outerGlowOver:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)
  -- frame.outerGlowOver:SetVertexColor(0, 1, 1)
  frame.outerGlowOver:SetAlpha(0)
  frame.outerGlowOver:SetPoint("TOPLEFT", frame.outerGlow, "TOPLEFT")
  frame.outerGlowOver:SetPoint("BOTTOMRIGHT", frame.outerGlow, "BOTTOMRIGHT")

  -- ants
  frame.ants = frame:CreateTexture("$parentAnts", "OVERLAY")
  frame.ants:SetTexture([[Interface\SpellActivationOverlay\IconAlertAnts]])
  -- frame.ants:SetVertexColor(0, 1, 1)
  frame.ants:SetPoint("CENTER", frame)

  -- create "animation in"
  frame.animIn = frame:CreateAnimationGroup()

  -- set animation in scripts
  frame.animIn:SetScript("OnPlay", AnimIn_OnPlay)
  frame.animIn:SetScript("OnFinished", AnimIn_OnFinished)

  -- <Scale target="$parentSpark" duration="0.2" scaleX="1.5" scaleY="1.5" order="1"/>
  local scale1 = frame.animIn:CreateAnimation("Scale")
  scale1:SetTarget("$parentSpark")
  scale1:SetDuration(0.2)
  scale1:SetScale(1.5, 1.5)
  scale1:SetOrder(1)

  -- <Alpha target="$parentSpark" duration="0.2" fromAlpha="0" toAlpha="1" order="1"/>
  local alpha1 = frame.animIn:CreateAnimation("Alpha")
  alpha1:SetTarget("$parentSpark")
  alpha1:SetDuration(0.2)
  alpha1:SetFromAlpha(0)
  alpha1:SetToAlpha(1)
  alpha1:SetOrder(1)

  -- <Scale target="$parentInnerGlow" duration="0.3" scaleX="2" scaleY="2" order="1"/>
  local scale2 = frame.animIn:CreateAnimation("Scale")
  scale2:SetTarget("$parentInnerGlow")
  scale2:SetDuration(0.3)
  scale2:SetScale(1, 1)
  scale2:SetOrder(1)

  -- <Scale target="$parentInnerGlowOver" duration="0.3" scaleX="2" scaleY="2" order="1"/>
  local scale3 = frame.animIn:CreateAnimation("Scale")
  scale3:SetTarget("$parentInnerGlowOver")
  scale3:SetDuration(0.3)
  scale3:SetScale(1, 1)
  scale3:SetOrder(1)

  -- <Alpha target="$parentInnerGlowOver" duration="0.3" fromAlpha="1" toAlpha="0" order="1"/>
  local alpha2 = frame.animIn:CreateAnimation("Alpha")
  alpha2:SetTarget("$parentInnerGlowOver")
  alpha2:SetDuration(0.3)
  alpha2:SetFromAlpha(1)
  alpha2:SetToAlpha(0)
  alpha2:SetOrder(1)

  -- <Scale target="$parentOuterGlow" duration="0.3" scaleX="0.5" scaleY="0.5" order="1"/>
  local scale4 = frame.animIn:CreateAnimation("Scale")
  scale4:SetTarget("$parentOuterGlow")
  scale4:SetDuration(0.3)
  scale4:SetScale(0.5, 0.5)
  scale4:SetOrder(1)

  -- <Scale target="$parentOuterGlowOver" duration="0.3" scaleX="0.5" scaleY="0.5" order="1"/>
  local scale5 = frame.animIn:CreateAnimation("Scale")
  scale5:SetTarget("$parentOuterGlowOver")
  scale5:SetDuration(0.3)
  scale5:SetScale(0.5, 0.5)
  scale5:SetOrder(1)

  -- <Alpha target="$parentOuterGlowOver" duration="0.3" fromAlpha="1" toAlpha="0" order="1"/>
  local alpha3 = frame.animIn:CreateAnimation("Alpha")
  alpha3:SetTarget("$parentOuterGlowOver")
  alpha3:SetDuration(0.3)
  alpha3:SetFromAlpha(1)
  alpha3:SetToAlpha(0)
  alpha3:SetOrder(1)

  -- <Scale target="$parentSpark" startDelay="0.2" duration="0.2" scaleX="0.666666" scaleY="0.666666" order="1"/>
  local scale6 = frame.animIn:CreateAnimation("Scale")
  scale6:SetTarget("$parentSpark")
  scale6:SetStartDelay(0.2)
  scale6:SetDuration(0.2)
  scale6:SetScale(0.666, 0.666)
  scale6:SetOrder(1)

  -- <Alpha target="$parentSpark" startDelay="0.2" duration="0.2" fromAlpha="1" toAlpha="0" order="1"/>
  local alpha4 = frame.animIn:CreateAnimation("Alpha")
  alpha4:SetTarget("$parentSpark")
  alpha4:SetStartDelay(0.2)
  alpha4:SetDuration(0.2)
  alpha4:SetFromAlpha(1)
  alpha4:SetToAlpha(0)
  alpha4:SetOrder(1)

  -- <Alpha target="$parentInnerGlow" startDelay="0.3" duration="0.2" fromAlpha="1" toAlpha="0" order="1"/>
  local alpha5 = frame.animIn:CreateAnimation("Alpha")
  alpha5:SetTarget("$parentInnerGlow")
  alpha5:SetStartDelay(0.3)
  alpha5:SetDuration(0.2)
  alpha5:SetFromAlpha(1)
  alpha5:SetToAlpha(0)
  alpha5:SetOrder(1)

  -- <Alpha target="$parentAnts" startDelay="0.3" duration="0.2" fromAlpha="0" toAlpha="1" order="1"/>
  local alpha6 = frame.animIn:CreateAnimation("Alpha")
  alpha6:SetTarget("$parentAnts")
  alpha6:SetStartDelay(0.3)
  alpha6:SetDuration(0.2)
  alpha6:SetFromAlpha(0)
  alpha6:SetToAlpha(1)
  alpha6:SetOrder(1)

  -- create "animation out"
  frame.animOut = frame:CreateAnimationGroup()

  -- set animation out scripts
  frame.animOut:SetScript("OnFinished", AnimOut_OnFinished)
  
  -- <Alpha target="$parentOuterGlowOver" duration="0.2" fromAlpha="0" toAlpha="1" order="1"/>
  local alpha7 = frame.animOut:CreateAnimation("Alpha")
  alpha7:SetTarget("$parentOuterGlowOver")
  alpha7:SetDuration(0.2)
  alpha7:SetFromAlpha(0)
  alpha7:SetToAlpha(1)
  alpha7:SetOrder(1)

  -- <Alpha target="$parentAnts" duration="0.2" fromAlpha="1" toAlpha="0" order="1"/>
  local alpha8 = frame.animOut:CreateAnimation("Alpha")
  alpha8:SetTarget("$parentAnts")
  alpha8:SetDuration(0.2)
  alpha8:SetFromAlpha(1)
  alpha8:SetToAlpha(0)
  alpha8:SetOrder(1)

  -- <Alpha target="$parentOuterGlowOver" duration="0.2" fromAlpha="1" toAlpha="0" order="2"/>
  local alpha9 = frame.animOut:CreateAnimation("Alpha")
  alpha9:SetTarget("$parentOuterGlowOver")
  alpha9:SetDuration(0.2)
  alpha9:SetFromAlpha(1)
  alpha9:SetToAlpha(0)
  alpha9:SetOrder(2)

  -- <Alpha target="$parentOuterGlow" duration="0.2" fromAlpha="1" toAlpha="0" order="2"/>
  local alpha10 = frame.animOut:CreateAnimation("Alpha")
  alpha10:SetTarget("$parentOuterGlow")
  alpha10:SetDuration(0.2)
  alpha10:SetFromAlpha(1)
  alpha10:SetToAlpha(0)
  alpha10:SetOrder(2)

  -- set frame update script
  frame:SetScript("OnUpdate", Anim_OnUpdate)

  return frame
end

local function ShowOverlay(button)
  local name = button:GetName()
  local overlay = GetOverlay(name)
  if (overlay) then
    if (overlay.animOut:IsPlaying()) then
      overlay.animOut:Stop()
    end

    overlay.animIn:Play()
  else
    overlay = CreateOverlay(button)
    overlays[name] = overlay

    overlay.animIn:Play()
  end
end

local function HideOverlay(button)
  local overlay = GetOverlay(button:GetName())
  if (overlay) then
    if (overlay.animIn:IsPlaying()) then
      overlay.animIn:Stop()
    end

    overlay.animOut:Play()
  end
end

local function ToggleButtonOverlays(buttons)
    local buffs = {}

    local i = 1
    local name = UnitBuff(UNIT_PLAYER, i)

    while (name) do
        buffs[name] = true

        i = i + 1
        name = UnitBuff(UNIT_PLAYER, i)
    end

    for button, buff in pairs(buttons) do
        if (buffs[buff]) then
            HideOverlay(button)
        else
            ShowOverlay(button)
        end
    end
end

local function GetActionButtons()
  local buttons = {}

  for _, template in pairs(ACTION_BUTTON_TEMPLATES) do
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

      local buff = GetBuffName(name)
      if (buff) then
        buttons[button] = buff
      end
    end
  end

  return buttons
end

-- main
function Addon:Load()
  self.frame = CreateFrame("Frame", nil)

  self.frame:SetScript("OnEvent", function(_frame, ...)
      self:OnEvent(...)
    end)

  self.frame:RegisterEvent("ADDON_LOADED")
end

function Addon:OnEvent(event, ...)
  local action = self[event]
  
  if (action) then
    action(self, ...)
  end
end

function Addon:ADDON_LOADED(name)
  if (AddonName == name) then
    self.frame:RegisterUnitEvent("UNIT_AURA", UNIT_PLAYER)

    print(name, "loaded")

    self.frame:UnregisterEvent("ADDON_LOADED")
  end
end

function Addon:UNIT_AURA()
    ToggleButtonOverlays(GetActionButtons())
end

Addon:Load()
