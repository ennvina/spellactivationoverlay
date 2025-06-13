--[[
Copyright (c) 2015-2020, Hendrik "nevcairiel" Leppkes <h.leppkes@gmail.com>

All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.
    * Neither the name of the developer nor the names of its contributors 
      may be used to endorse or promote products derived from this software without 
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
--[[
Cooldown functionality added by Ennvina/Vinny for SpellActivationOverlay
]]
local MAJOR_VERSION = "LibButtonGlow-1.0-SAO"
local MINOR_VERSION = 9

if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib, oldversion = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

-- Optimize frequent calls
local GetTime = GetTime

-- Option to use or avoid Cooldown-based layouts
local supportCooldown = true

local Masque = LibStub("Masque", true)

lib.unusedOverlays = lib.unusedOverlays or {}
lib.numOverlays = lib.numOverlays or 0

local tinsert, tremove, tostring = table.insert, table.remove, tostring

local function OverlayGlowAnimOutFinished(animGroup)
	local overlay = animGroup:GetParent()
	local frame = overlay:GetParent()
	overlay:Hide()
	tinsert(lib.unusedOverlays, overlay)
	frame.__LBGoverlay = nil
end

local function OverlayGlow_OnHide(self)
	if self.animOut:IsPlaying() then
		self.animOut:Stop()
		OverlayGlowAnimOutFinished(self.animOut)
	end
end

local function OverlayGlow_OnUpdate(self, elapsed)
	AnimateTexCoords(self.ants, 256, 256, 48, 48, 22, elapsed, 0.01)
	local cooldown = self:GetParent().cooldown
	-- we need some threshold to avoid dimming the glow during the gdc
	-- (using 1500 exactly seems risky, what if casting speed is slowed or something?)
	if cooldown and cooldown:IsShown() and cooldown:GetCooldownDuration() > 3000 then
		self:SetAlpha(0.5)
	else
		self:SetAlpha(1.0)
	end
end

local function CreateScaleAnim(group, target, order, duration, x, y, delay)
	local scale = group:CreateAnimation("Scale")
	scale:SetTarget(target)
	scale:SetOrder(order)
	scale:SetDuration(duration)
	scale:SetScale(x, y)

	-- Manual scale for Cooldown objects, because the scale animation is buggy as hell for them
	if target.__scale then
		local prevAnimProps
		if target.__scale.animations then
			prevAnimProps = target.__scale.animations[#target.__scale.animations]
		else
			target.__scale.animations = {}
		end
		local animProps = { x = x, y = y, startTime = nil, throttle = nil }
		tinsert(target.__scale.animations, animProps)

		local throttleMin = 0.01

		scale:SetScript("OnPlay", function(self)
			animProps.startTime = GetTime() + (delay or 0)
			animProps.throttle = throttleMin
		end)

		scale:SetScript("OnUpdate", function(self, elapsed)
			local baseScale, startTime = target.__scale.baseScale, animProps.startTime
			if not baseScale or not startTime or GetTime() < startTime then
				return
			end

			if animProps.throttle < throttleMin then
				animProps.throttle = animProps.throttle + elapsed
				return
			end
			animProps.throttle = 0

			local frame = group:GetParent()
			local frameWidth, frameHeight = frame:GetSize()
			local scaleWidth, scaleHeight = prevAnimProps and prevAnimProps.x or baseScale, prevAnimProps and prevAnimProps.y or baseScale
			local initialWidth, initialHeight = scaleWidth*frameWidth, scaleHeight*frameHeight
			local finalWidth, finalHeight = x*initialWidth, y*initialHeight
			local t = (GetTime() - startTime) / duration
			local newWidth, newHeight = (1-t) * initialWidth + t * finalWidth, (1-t) * initialHeight + t * finalHeight
			target:SetSize(newWidth, newHeight)
		end)

		scale:SetScript("OnFinished", function(self)
			animProps.startTime = nil
		end)
	end

	if delay then
		scale:SetStartDelay(delay)
	end
end

local function CreateAlphaAnim(group, target, order, duration, fromAlpha, toAlpha, delay)
	local alpha = group:CreateAnimation("Alpha")
	alpha:SetTarget(target)
	alpha:SetOrder(order)
	alpha:SetDuration(duration)
	alpha:SetFromAlpha(fromAlpha)
	alpha:SetToAlpha(toAlpha)

	if delay then
		alpha:SetStartDelay(delay)
	end
end

local function AnimIn_OnPlay(group)
	local frame = group:GetParent()
	local frameWidth, frameHeight = frame:GetSize()

	local setInitialScaleAlpha = function(layout, scaleFactor, alpha)
		if layout.__scale then
			layout.__scale.baseScale = scaleFactor
		end
		layout.__baseScale = scaleFactor
		layout:SetSize(frameWidth * scaleFactor, frameHeight * scaleFactor)
		layout:SetAlpha(alpha)
	end

	setInitialScaleAlpha(frame.spark, 1, 0.3)

	setInitialScaleAlpha(frame.innerGlow, 0.5, 1.0)
	frame.innerGlowOver:SetAlpha(1.0)

	setInitialScaleAlpha(frame.outerGlow, 2, 1.0)
	frame.outerGlowOver:SetAlpha(1.0)

	setInitialScaleAlpha(frame.ants, 0.85, 0)

	frame:Show()
end

local function AnimIn_OnFinished(group)
	local frame = group:GetParent()
	local frameWidth, frameHeight = frame:GetSize()
	frame.spark:SetAlpha(0)
	frame.innerGlow:SetAlpha(0)
	frame.innerGlow:SetSize(frameWidth, frameHeight)
	frame.innerGlowOver:SetAlpha(0.0)
	frame.outerGlow:SetSize(frameWidth, frameHeight)
	frame.outerGlowOver:SetAlpha(0.0)
	frame.outerGlowOver:SetSize(frameWidth, frameHeight)
	frame.ants:SetAlpha(1.0)
end

local function CreateTexture(overlay, name, drawLayer)
	if not supportCooldown then
		return overlay:CreateTexture(name, drawLayer)
	end

	local frame = CreateFrame("Cooldown", name, overlay)
	frame.__scale = {}

	frame:ClearAllPoints()
	frame:SetDrawBling(false)
	frame:SetDrawEdge(false)
	frame:SetSwipeColor(1, 1, 1, 1);
	frame.SetTexture = function(self, texture)
		self:SetSwipeTexture(texture)
	end
	frame.SetTexCoord = function(self, left, right, top, bottom)
		self:SetTexCoordRange({ x = left, y = top }, { x = right, y = bottom })
	end

	if not overlay.cooldowns then
		overlay.cooldowns = {}
	end
	tinsert(overlay.cooldowns, frame)

	return frame
end

local function SetCooldown(overlay, start, duration)
	start, duration = start or -1, duration or 0 -- By default, disable cooldown clock
	for _, cooldown in pairs(overlay.cooldowns or {}) do
		cooldown:SetCooldown(start, duration)
	end
end

local function CreateOverlayGlow()
	lib.numOverlays = lib.numOverlays + 1

	-- create frame and textures
	local name = "ButtonGlowOverlay" .. tostring(lib.numOverlays)
	local overlay = CreateFrame("Frame", name, UIParent)

	-- spark
	overlay.spark = CreateTexture(overlay, name .. "Spark", "BACKGROUND")
	overlay.spark:SetPoint("CENTER")
	overlay.spark:SetAlpha(0)
	overlay.spark:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
	overlay.spark:SetTexCoord(0.00781250, 0.61718750, 0.00390625, 0.26953125)

	-- inner glow
	overlay.innerGlow = CreateTexture(overlay, name .. "InnerGlow", "ARTWORK")
	overlay.innerGlow:SetPoint("CENTER")
	overlay.innerGlow:SetAlpha(0)
	overlay.innerGlow:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
	overlay.innerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)

	-- inner glow over
	overlay.innerGlowOver = CreateTexture(overlay, name .. "InnerGlowOver", "ARTWORK")
	overlay.innerGlowOver:SetPoint("TOPLEFT", overlay.innerGlow, "TOPLEFT")
	overlay.innerGlowOver:SetPoint("BOTTOMRIGHT", overlay.innerGlow, "BOTTOMRIGHT")
	overlay.innerGlowOver:SetAlpha(0)
	overlay.innerGlowOver:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
	overlay.innerGlowOver:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)

	-- outer glow
	overlay.outerGlow = CreateTexture(overlay, name .. "OuterGlow", "ARTWORK")
	overlay.outerGlow:SetPoint("CENTER")
	overlay.outerGlow:SetAlpha(0)
	overlay.outerGlow:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
	overlay.outerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)

	-- outer glow over
	overlay.outerGlowOver = CreateTexture(overlay, name .. "OuterGlowOver", "ARTWORK")
	overlay.outerGlowOver:SetPoint("TOPLEFT", overlay.outerGlow, "TOPLEFT")
	overlay.outerGlowOver:SetPoint("BOTTOMRIGHT", overlay.outerGlow, "BOTTOMRIGHT")
	overlay.outerGlowOver:SetAlpha(0)
	overlay.outerGlowOver:SetTexture([[Interface\SpellActivationOverlay\IconAlert]])
	overlay.outerGlowOver:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)

	-- ants
	overlay.ants = CreateTexture(overlay, name .. "Ants", "OVERLAY")
	overlay.ants:SetPoint("CENTER")
	overlay.ants:SetAlpha(0)
	overlay.ants:SetTexture([[Interface\SpellActivationOverlay\IconAlertAnts]])

	-- setup antimations
	overlay.animIn = overlay:CreateAnimationGroup()
	CreateScaleAnim(overlay.animIn, overlay.spark,          1, 0.2, 1.5, 1.5)
	CreateAlphaAnim(overlay.animIn, overlay.spark,          1, 0.2, 0, 1)
	CreateScaleAnim(overlay.animIn, overlay.innerGlow,      1, 0.3, 2, 2)
	CreateScaleAnim(overlay.animIn, overlay.innerGlowOver,  1, 0.3, 2, 2)
	CreateAlphaAnim(overlay.animIn, overlay.innerGlowOver,  1, 0.3, 1, 0)
	CreateScaleAnim(overlay.animIn, overlay.outerGlow,      1, 0.3, 0.5, 0.5)
	CreateScaleAnim(overlay.animIn, overlay.outerGlowOver,  1, 0.3, 0.5, 0.5)
	CreateAlphaAnim(overlay.animIn, overlay.outerGlowOver,  1, 0.3, 1, 0)
	CreateScaleAnim(overlay.animIn, overlay.spark,          1, 0.2, 2/3, 2/3, 0.2)
	CreateAlphaAnim(overlay.animIn, overlay.spark,          1, 0.2, 1, 0, 0.2)
	CreateAlphaAnim(overlay.animIn, overlay.innerGlow,      1, 0.2, 1, 0, 0.3)
	CreateAlphaAnim(overlay.animIn, overlay.ants,           1, 0.2, 0, 1, 0.3)
	overlay.animIn:SetScript("OnPlay", AnimIn_OnPlay)
	overlay.animIn:SetScript("OnFinished", AnimIn_OnFinished)

	overlay.animOut = overlay:CreateAnimationGroup()
	CreateAlphaAnim(overlay.animOut, overlay.outerGlowOver, 1, 0.2, 0, 1)
	CreateAlphaAnim(overlay.animOut, overlay.ants,          1, 0.2, 1, 0)
	CreateAlphaAnim(overlay.animOut, overlay.outerGlowOver, 2, 0.2, 1, 0)
	CreateAlphaAnim(overlay.animOut, overlay.outerGlow,     2, 0.2, 1, 0)
	overlay.animOut:SetScript("OnFinished", OverlayGlowAnimOutFinished)

	-- scripts
	overlay:SetScript("OnUpdate", OverlayGlow_OnUpdate)
	overlay:SetScript("OnHide", OverlayGlow_OnHide)

	overlay.__LBGVersion = MINOR_VERSION

	return overlay
end

local function GetOverlayGlow()
	local overlay = tremove(lib.unusedOverlays)
	if not overlay then
		overlay = CreateOverlayGlow()
	end
	return overlay
end

function lib.ShowOverlayGlow(frame, startTime, duration)
	if frame.__LBGoverlay then
		if frame.__LBGoverlay.animOut:IsPlaying() then
			frame.__LBGoverlay.animOut:Stop()
			frame.__LBGoverlay.animIn:Play()
		end
	else
		local overlay = GetOverlayGlow()
		local frameWidth, frameHeight = frame:GetSize()
		overlay:SetParent(frame)
		overlay:SetFrameLevel(frame:GetFrameLevel() + 5)
		overlay:ClearAllPoints()
		--Make the height/width available before the next frame:
		overlay:SetSize(frameWidth * 1.4, frameHeight * 1.4)
		overlay:SetPoint("TOPLEFT", frame, "TOPLEFT", -frameWidth * 0.2, frameHeight * 0.2)
		overlay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", frameWidth * 0.2, -frameHeight * 0.2)
		overlay.animIn:Play()
		frame.__LBGoverlay = overlay

		if Masque and Masque.UpdateSpellAlert and (not frame.overlay or not issecurevariable(frame, "overlay")) then
			local old_overlay = frame.overlay
			frame.overlay = overlay
			Masque:UpdateSpellAlert(frame)

			frame.overlay = old_overlay
		end
	end

	SetCooldown(frame.__LBGoverlay, startTime, duration)
end

function lib.HideOverlayGlow(frame)
	if frame.__LBGoverlay then
		if frame.__LBGoverlay.animIn:IsPlaying() then
			frame.__LBGoverlay.animIn:Stop()
		end
		if frame:IsVisible() then
			frame.__LBGoverlay.animOut:Play()
		else
			OverlayGlowAnimOutFinished(frame.__LBGoverlay.animOut)
		end
	end
end

function lib.UpdateOverlayGlowCooldown(frame, startTime, duration)
	if frame.__LBGoverlay then
		SetCooldown(frame.__LBGoverlay, startTime, duration)
	end
end
