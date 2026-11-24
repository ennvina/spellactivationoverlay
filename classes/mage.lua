local AddonName,SAO=...
local Module="mage"
local CombatLogGetCurrentEventInfo=CombatLogGetCurrentEventInfo
local UnitCanAttack=UnitCanAttack
local UnitDebuff=UnitDebuff
local UnitExists=UnitExists
local UnitGUID=UnitGUID
local UnitHealth=UnitHealth
local clearcastingVariants
local isCompatibleWithClearcasting=not SAO.IsProject(SAO.FOREVER + SAO.RETAIL)
local isCompatibleWithFrozen=not SAO.IsProject(SAO.FOREVER + SAO.RETAIL)
local isCompatibleWithCustomHotStreak=not SAO.IsProject(SAO.FOREVER + SAO.RETAIL + SAO.MOP)
local arcaneExplosion=1449
local arcaneMissiles=5143
local fireball=133
local fireBlast=2136
local flamestrike=2120
local frostfireBolt=44614
local frostfireBoltSoD=401502
local infernoBlast=108853
local spellfrostBoltSoD=412532
local pyroblast=11366
local pyroblastBang=92315
local hotStreakSpellID=48108
local heatingUpSpellID=48107
local hotStreakHeatingUpSpellID=hotStreakSpellID+heatingUpSpellID
local improvedHotStreakSpellID=44446
local hotStreakSoDSpellID=400625
local HotStreakHandler={}
HotStreakHandler.init=function(self,talentName)
local fire_blast_ids={2136,2137,2138,8412,8413,10197,10199,27078,27079,42872,42873}
local fire_blast_sod_ids={400618,400619,400616,400620,400621,400622,400623}
local fireball_ids={133,143,145,3140,8400,8401,8402,10148,10149,10150,10151,25306,27070,38692,42832,42833}
local frostfire_bolt_ids={frostfireBolt,47610}
local frostfire_bolt_sod_ids={401502}
local living_bomb_ids={44461,55361,55362}
local living_bomb_sod_ids={401731}
local scorch_ids={2948,8444,8445,8446,10205,10206,10207,27073,27074,42858,42859}
local pyroblast_cata_ids={pyroblast}
local balefire_bolt_sod_ids={428878}
self.spells={}
local function addSpellPack(spellPack,project)
if project and not SAO.IsProject(project)then
return
end
for _,spellID in pairs(spellPack)do
self.spells[spellID]=true
end
end
addSpellPack(fire_blast_ids)
addSpellPack(fire_blast_sod_ids,SAO.SOD)
addSpellPack(fireball_ids)
addSpellPack(frostfire_bolt_ids)
addSpellPack(frostfire_bolt_sod_ids,SAO.SOD)
addSpellPack(scorch_ids)
addSpellPack(pyroblast_cata_ids,SAO.CATA)
addSpellPack(living_bomb_ids,SAO.WRATH)
addSpellPack(living_bomb_sod_ids,SAO.SOD)
addSpellPack(balefire_bolt_sod_ids,SAO.SOD)
local _,_,tab,index=SAO:GetTalentByName(talentName)
if (tab and index)then
self.talent={tab,index}
end
self.state='cold'
self.banked=false
end
HotStreakHandler.isSpellTracked=function(self,spellID)
return self.spells[spellID]
end
HotStreakHandler.hasHotStreakTalent=function(self)
if (SAO.IsSoD())then
return C_Engraving and C_Engraving.IsRuneEquipped(48202)
end
if (not self.talent)then
return false
end
local rank=SAO:GetNbTalentPoints(self.talent[1],self.talent[2])
return rank > 0
end
local function activateHeatingUp(self,spellID)
self:ActivateOverlay(0,spellID,self.TexName["hot_streak"], "Left + Right (Flipped)",0.5,255,255,255,255,false,nil,nil,true)
end
local function deactivateHeatingUp(self,spellID)
self:DeactivateOverlay(spellID)
end
local function hotStreakCLEU(self,...)
local timestamp,event,_,sourceGUID,sourceName,sourceFlags,sourceRaidFlags,destGUID,destName,destFlags,destRaidFlags=CombatLogGetCurrentEventInfo()
if (event~="SPELL_DAMAGE"
and event~="SPELL_AURA_APPLIED"
and event~="SPELL_AURA_REFRESH"
and event~="SPELL_AURA_REMOVED")then return end
if (sourceGUID~=UnitGUID("player"))then return end
local spellID,spellName,spellSchool=select(12,CombatLogGetCurrentEventInfo())
if (event=="SPELL_AURA_APPLIED")then
if (spellID==hotStreakSpellID or spellID==hotStreakSoDSpellID)then
deactivateHeatingUp(self,heatingUpSpellID)
HotStreakHandler.state='hot_streak'
end
return
elseif (event=="SPELL_AURA_REFRESH")then
if (spellID==hotStreakSpellID or spellID==hotStreakSoDSpellID)then
deactivateHeatingUp(self,hotStreakHeatingUpSpellID)
HotStreakHandler.state='hot_streak'
end
return
elseif (event=="SPELL_AURA_REMOVED")then
if (spellID==hotStreakSpellID or spellID==hotStreakSoDSpellID)then
if (HotStreakHandler.state=='hot_streak_heating_up')then
deactivateHeatingUp(self,hotStreakHeatingUpSpellID)
activateHeatingUp(self,heatingUpSpellID)
HotStreakHandler.state='heating_up'
else
HotStreakHandler.state='cold'
end
end
return
end
if (not HotStreakHandler:hasHotStreakTalent())then return end
if (not HotStreakHandler:isSpellTracked(spellID))then return end
local amount,overkill,school,resisted,blocked,absorbed,critical,glancing,crushing,isOffHand=select(15,CombatLogGetCurrentEventInfo())
if (HotStreakHandler.state=='cold')then
if (critical)then
HotStreakHandler.state='heating_up'
activateHeatingUp(self,heatingUpSpellID)
end
elseif (HotStreakHandler.state=='heating_up')then
if (not critical)then
HotStreakHandler.state='cold'
deactivateHeatingUp(self,heatingUpSpellID)
end
elseif (HotStreakHandler.state=='hot_streak')then
if (critical)then
HotStreakHandler.state='hot_streak_heating_up'
activateHeatingUp(self,hotStreakHeatingUpSpellID)
end
elseif (HotStreakHandler.state=='hot_streak_heating_up')then
if (not critical)then
HotStreakHandler.state='hot_streak'
deactivateHeatingUp(self,hotStreakHeatingUpSpellID)
end
else
SAO:Debug(Module, "Unknown HotStreakHandler state")
end
end
local function recheckTalents(self)
local hasHotStreakTalent=HotStreakHandler:hasHotStreakTalent()
if not hasHotStreakTalent and HotStreakHandler.state=='heating_up' then
HotStreakHandler.state='cold'
HotStreakHandler.banked=true
deactivateHeatingUp(self,heatingUpSpellID)
elseif not hasHotStreakTalent and HotStreakHandler.state=='hot_streak_heating_up' then
HotStreakHandler.state='hot_streak'
HotStreakHandler.banked=true
deactivateHeatingUp(self,hotStreakHeatingUpSpellID)
elseif hasHotStreakTalent and HotStreakHandler.banked then
HotStreakHandler.state='heating_up'
HotStreakHandler.banked=false
activateHeatingUp(self,heatingUpSpellID)
end
end
local FrozenHandler={
frostbite={12494},
frost_nova={122,865,6131,10230,27088,42917},
freezing_trap={3355,14308,14309},
freeze={33395},
shattered_barrier={55080},
ice_lance={30455,42913,42914},
ice_lance_sod={400640},
deep_freeze={44572},
deep_freeze_sod={428739},
hungering_cold={49203},
improved_cone_of_cold={83301,83302},
ring_of_frost={82691},
freezeID=5276,
freezeTalent=5276,
fakeSpellID=5276+1000000,
saoTexture="frozen_fingers",
saoPosition=SAO.IsCata() and "Top" or "Top (CW)",
saoScaleFactor=SAO.IsProject(SAO.FOREVER + SAO.ERA + SAO.TBC) and 1 or 0.75,
allSpellIDs={},
allSpellNames={},
initialized=false,
freezable=false,
frozen=false,
saoActive=nil,
gabIceLinceActive=nil,
gabDeepFreezeActive=nil,
init=function(self)
self:addSpellIDCandidates(self.frostbite)
self:addSpellIDCandidates(self.frost_nova)
self:addSpellIDCandidates(self.freezing_trap)
self:addSpellIDCandidates(self.freeze)
self:addSpellIDCandidates(self.shattered_barrier)
self:addSpellIDCandidates(self.deep_freeze)
self:addSpellIDCandidates(self.deep_freeze_sod)
self:addSpellIDCandidates(self.hungering_cold)
self:addSpellIDCandidates(self.improved_cone_of_cold)
self:addSpellIDCandidates(self.ring_of_frost)
self.freezable=self:isTargetFreezable()
if (self.freezable and self:isTargetFrozen())then
self.frozen=true
self:activate()
end
if SAO.IsProject(SAO.ERA + SAO.TBC + SAO.WRATH)then
SAO:RegisterGlowIDs({
SAO:GetSpellName(self.ice_lance[1]),
SAO:GetSpellName(self.ice_lance_sod[1]),
SAO:GetSpellName(self.deep_freeze[1]),
SAO:GetSpellName(self.deep_freeze_sod[1]),
})
else
SAO:RegisterGlowIDs({
self.ice_lance[1],
self.ice_lance_sod[1],
self.deep_freeze[1],
self.deep_freeze_sod[1],
})
end
self.initialized=true
end,
addSpellIDCandidates=function(self,ids)
for _,id in pairs(ids)do
local name=SAO:GetSpellName(id)
if name then
self.allSpellIDs[id]=true
self.allSpellNames[name]=true
end
end
end,
cleu=function(self)
local _,event,_,_,_,_,_,destGUID=CombatLogGetCurrentEventInfo()
if (not destGUID) or (destGUID~=UnitGUID("target"))then return end
if (event:sub(0,11)~="SPELL_AURA_")then return end
if not self:isTargetFreezable()then
self.freezable=false
self:setFrozen(false)
return
end
local spellID,spellName=select(12,CombatLogGetCurrentEventInfo())
if (self.allSpellIDs[spellID])then
if (event=="SPELL_AURA_APPLIED" or event=="SPELL_AURA_REFRESH")then
self.freezable=true
self:setFrozen(true)
elseif (event=="SPELL_AURA_REMOVED")then
self.freezable=true
self:setFrozen(self:isTargetFrozen())
end
elseif (spellID==0 and spellName and self.allSpellNames[spellName])then
self.freezable=true
self:setFrozen(self:isTargetFrozen())
end
end,
isTargetFreezable=function(self)
return UnitExists("target") and UnitCanAttack("player", "target") and UnitHealth("target")~=0
end,
isTargetFrozen=function(self)
for i=1,200 do
local name,_,_,_,_,_,_,_,_,id=UnitDebuff("target",i)
if not name then
return false
end
if self.allSpellIDs[id] then
return true
end
end
end,
longestFrozenTime=function(self)
local longestTime,durationOfLongestTime=0,0
for i=1,200 do
local name,_,_,_,duration,expirationTime,_,_,_,id=UnitDebuff("target",i)
if not name then
break
end
if self.allSpellIDs[id] and expirationTime > longestTime then
longestTime=expirationTime
durationOfLongestTime=duration
end
end
local startTime,endTime=longestTime-durationOfLongestTime,longestTime
return startTime,endTime
end,
getEndTime=function(self)
if not SAO.Frame.useTimer then
return
end
local startTime,endTime=self:longestFrozenTime()
return {startTime=startTime,endTime=endTime}
end,
retarget=function(self,...)
if (self.freezable~=self:isTargetFreezable())then
self.freezable=not self.freezable
end
self:setFrozen(self.freezable and self:isTargetFrozen())
end,
checkTargetHealth=function(self)
if (self.freezable~=self:isTargetFreezable())then
self.freezable=not self.freezable
self:setFrozen(self.freezable and self:isTargetFrozen())
end
end,
setFrozen=function(self,frozen)
if frozen and not self.frozen then
self.frozen=true
self:activate()
elseif not frozen and self.frozen then
self.frozen=false
self:deactivate()
elseif frozen and self.frozen then
self:reactivate()
end
end,
activate=function(self)
local saoOption=SAO:GetOverlayOptions(self.freezeID)
local hasSAO=not saoOption or type(saoOption[0])=="nil" or saoOption[0]
if (hasSAO)then
local endTime=self:getEndTime()
SAO:ActivateOverlay(0,self.freezeID,SAO.TexName[self.saoTexture],self.saoPosition,self.saoScaleFactor,255,255,255,255,false,nil,endTime)
end
local gabOption=SAO:GetGlowingOptions(self.freezeID)
local iceLance=self.ice_lance[1]
local hasIceLanceGAB=not gabOption or type(gabOption[iceLance])=="nil" or gabOption[iceLance]
if (hasIceLanceGAB)then
SAO:AddGlow(iceLance,self.ice_lance)
end
local iceLanceSoD=self.ice_lance_sod[1]
local hasIceLanceSoDGAB=not gabOption or type(gabOption[iceLanceSoD])=="nil" or gabOption[iceLanceSoD]
if (hasIceLanceSoDGAB)then
SAO:AddGlow(iceLanceSoD,self.ice_lance_sod)
end
local deepFreeze=self.deep_freeze[1]
local hasDeepFreezeGAB=not gabOption or type(gabOption[deepFreeze])=="nil" or gabOption[deepFreeze]
if (hasDeepFreezeGAB)then
SAO:AddGlow(deepFreeze,self.deep_freeze)
end
local deepFreezeSoD=self.deep_freeze_sod[1]
local hasDeepFreezeSoDGAB=not gabOption or type(gabOption[deepFreezeSoD])=="nil" or gabOption[deepFreezeSoD]
if (hasDeepFreezeSoDGAB)then
SAO:AddGlow(deepFreezeSoD,self.deep_freeze_sod)
end
end,
deactivate=function(self)
SAO:DeactivateOverlay(self.freezeID)
SAO:RemoveGlow(self.ice_lance[1])
SAO:RemoveGlow(self.ice_lance_sod[1])
SAO:RemoveGlow(self.deep_freeze[1])
SAO:RemoveGlow(self.deep_freeze_sod[1])
end,
reactivate=function(self)
local saoOption=SAO:GetOverlayOptions(self.freezeID)
local hasSAO=not saoOption or type(saoOption[0])=="nil" or saoOption[0]
if (hasSAO)then
local endTime=self:getEndTime()
SAO:RefreshOverlayTimer(self.freezeID,endTime)
end
end,
}
local function customLogin(self,...)
if isCompatibleWithCustomHotStreak then
local hotStreakSpellName
if SAO.IsSoD()then
hotStreakSpellName=self:GetSpellName(hotStreakSoDSpellID)
elseif SAO.IsCata()then
hotStreakSpellName=self:GetSpellName(improvedHotStreakSpellID)
else
hotStreakSpellName=self:GetSpellName(hotStreakSpellID)
end
if (hotStreakSpellName)then
HotStreakHandler:init(hotStreakSpellName)
end
end
if isCompatibleWithFrozen then
if not FrozenHandler.initialized then
FrozenHandler:init()
end
end
end
local function customCLEU(self,...)
if isCompatibleWithCustomHotStreak then
hotStreakCLEU(self,...)
end
if FrozenHandler.initialized then
FrozenHandler:cleu()
end
end
local function retarget(self,...)
if FrozenHandler.initialized then
FrozenHandler:retarget(...)
end
end
local function unitHealth(self,unitID)
if FrozenHandler.initialized and unitID=="target" then
FrozenHandler:checkTargetHealth()
end
end
local function unitHealthFrequent(self,unitID)
if self:IsResponsiveMode()then
unitHealth(self,unitID)
end
end
local function lazyCreateClearcastingVariants(self)
if clearcastingVariants then
return
end
if self.IsProject(SAO.MOP_AND_ONWARD)then
return
end
local spellID=12536
local textureVariant1="genericarc_05"
local textureVariant2="genericarc_02"
local weakText=PET_BATTLE_COMBAT_LOG_DAMAGE_WEAK:gsub("[ ()]","")
local strongText=PET_BATTLE_COMBAT_LOG_DAMAGE_STRONG:gsub("[ ()]","")
clearcastingVariants=self:CreateTextureVariants(spellID,0,{
self:TextureVariantValue(textureVariant1,false,weakText),
self:TextureVariantValue(textureVariant2,false,strongText),
})
end
local function useImpact()
local impactBuff=64343
local impactTalent=11103
SAO:CreateEffect(
"impact",
SAO.WRATH + SAO.CATA,
impactBuff,
"aura",
{
talent=impactTalent,
requireTalent=true,
action=fireBlast,
actionUsable=true,
overlay={texture="lock_and_load",position="Top"},
button=fireBlast,
}
)
end
local function useArcaneMissiles()
local arcaneMissilesBuff=79683
if SAO.IsCata()then
SAO:CreateEffect(
"arcane_missiles",
SAO.CATA,
arcaneMissilesBuff,
"aura",
{
overlay={texture="arcane_missiles",position="Left + Right (Flipped)",scale=0.6},
button=arcaneMissiles,
handler={
onRepeat=function(bucket) bucket:refresh(); end,
}
}
)
elseif SAO.IsMoP()then
local hash0Stacks=SAO:HashNameFromStacks(0)
local hash2Stacks=SAO:HashNameFromStacks(2)
SAO:CreateEffect(
"arcane_missiles",
SAO.MOP,
arcaneMissilesBuff,
"aura",
{
aka=79808,
overlays={
{stacks=1,texture="arcane_missiles",position="Left",option=false},
{stacks=2,texture="arcane_missiles",position="Left + Right (Flipped)",option={setupHash=hash0Stacks,testHash=hash2Stacks}},
},
button=arcaneMissiles,
}
)
end
end
local function useMissileBarrage()
if SAO.IsSoD()then
SAO:RegisterAura("missile_barrage",0,400589, "arcane_missiles", "Left + Right (Flipped)",0.8,103,184,238,true,{SAO:GetSpellName(arcaneMissiles)})
elseif SAO.IsWrath()then
SAO:RegisterAura("missile_barrage",0,44401, "arcane_missiles", "Left + Right (Flipped)",1,255,255,255,true,{SAO:GetSpellName(arcaneMissiles)})
else
SAO:CreateEffect(
"missile_barrage",
SAO.FOREVER,
400589,
"aura",
{
overlay={texture="arcane_missiles",position="Left + Right (Flipped)",outer=0.32,level=5},
}
)
end
end
local function useArcaneBlast()
if SAO.IsSoD()then
local arcaneBlastSoDBuff=400573
local arcaneMissiles=5143
local arcaneExplosion=1449
local resettingSpells={SAO:GetSpellName(arcaneMissiles),SAO:GetSpellName(arcaneExplosion)}
for nbStacks=1,4 do
local scale=nbStacks==4 and 1.2 or 0.6
local pulse=nbStacks==4
local glowIDs=nbStacks==4 and resettingSpells or nil
local texture=({"arcane_missiles_1", "arcane_missiles_2", "arcane_missiles_3", "arcane_missiles"})[nbStacks]
SAO:RegisterAura("arcane_blast_sod",nbStacks,arcaneBlastSoDBuff,texture, "Left + Right (Flipped)",scale,255,255,255,pulse,glowIDs)
end
end
end
local function useClearcasting()
local clearcastingBuff=SAO.IsRetail() and 276743 or 12536
SAO:CreateEffect(
"clearcasting",
SAO.FOREVER + SAO.RETAIL,
clearcastingBuff,
"aura",
{
overlay={texture="genericarc_02",position="Left + Right (Flipped)",outer=0.75,pulse=false,level=7},
}
)
end
local function useFreezeDebuff()
local freezeID=5276
local frozenAKAs={}
local addSpellIDCandidates=function(ids)
for _,id in pairs(ids)do
if SAO:GetSpellName(id)then
table.insert(frozenAKAs,id)
end
end
end
addSpellIDCandidates(FrozenHandler.frostbite)
addSpellIDCandidates(FrozenHandler.frost_nova)
addSpellIDCandidates(FrozenHandler.freezing_trap)
addSpellIDCandidates(FrozenHandler.freeze)
addSpellIDCandidates(FrozenHandler.shattered_barrier)
addSpellIDCandidates(FrozenHandler.deep_freeze)
addSpellIDCandidates(FrozenHandler.deep_freeze_sod)
addSpellIDCandidates(FrozenHandler.hungering_cold)
addSpellIDCandidates(FrozenHandler.improved_cone_of_cold)
addSpellIDCandidates(FrozenHandler.ring_of_frost)
SAO:CreateEffect(
"freeze",
SAO.FOREVER,
freezeID,-- Not the real spellID,but useful because it has an informative "Freeze" name and icon
"aura",
{
aka=frozenAKAs,
auraProps={debuff=true},
overlay={texture="frozen_fingers",position="Top (CW)",pulse=false},
}
)
end
local function useFingersOfFrost()
local hash0Stacks=SAO:HashNameFromStacks(0)
local hash1Stack=SAO:HashNameFromStacks(1)
local hash2Stacks=SAO:HashNameFromStacks(2)
if SAO.IsMoP()then
local fingersOfFrostBuff=44544
SAO:CreateEffect(
"fingers_of_frost",
SAO.MOP,
fingersOfFrostBuff,
"aura",
{
aka=126084,
overlays={
{stacks=1,texture="frozen_fingers",position="Left",scale=1.1,color={222,222,222},option=false},
{stacks=2,texture="frozen_fingers",position="Left + Right (Flipped)",scale=1.1,color={222,222,222},option={setupHash=hash0Stacks,testHash=hash2Stacks}},
},
buttons={FrozenHandler.ice_lance[1],FrozenHandler.deep_freeze[1],default={option={isNative=true}}},
}
)
elseif SAO.IsForever() or SAO.IsRetail()then
local fingersOfFrostBuff=SAO.IsForever() and 400670 or 44544
SAO:CreateEffect(
"fingers_of_frost",
SAO.FOREVER + SAO.RETAIL,
fingersOfFrostBuff,
"aura",
{
overlays={
{stacks=1,texture="frozen_fingers",position="Left",option=false},
{stacks=2,texture="frozen_fingers",position="Right (Flipped)",option={
setupHash=hash0Stacks,
testHash={hash1Stack,hash2Stacks}
}},
},
}
)
end
end
local function useBrainFreeze()
local brainFreezeBuff=57761
SAO:CreateEffect(
"brain_freeze",
SAO.MOP,
brainFreezeBuff,
"aura",
{
overlay={texture="brain_freeze",position="Top"},
button={spellID=frostfireBolt,option={isNative=true}},
}
)
end
local function useIceBarrier()
local iceBarrier=11426
SAO:CreateEffect(
"ice_barrier",
SAO.FOREVER,
iceBarrier,
"counter",
{combatOnly=true}
)
end
local function useHeatingUpAndHotStreak()
SAO:CreateEffect(
"heating_up",
SAO.MOP + SAO.RETAIL,
heatingUpSpellID,
"aura",
{
overlay={texture="hot_streak",position="Left + Right (Flipped)",scale=0.5,pulse=false},
buttons={
[SAO.MOP]=infernoBlast,
},
}
)
SAO:CreateEffect(
"hot_streak",
SAO.MOP + SAO.RETAIL,
hotStreakSpellID,
"aura",
{
overlay={texture="hot_streak",position="Left + Right (Flipped)"},
button={spellID=pyroblast,option={isNative=true}},
}
)
SAO:CreateEffect(
"heating_up_forever",
SAO.FOREVER,
400625,
"aura",
{
overlays={
{stacks=1,texture="hot_streak",position="Left + Right (Flipped)",scale=0.5,pulse=false,text=true ,level=1,color={200,200,200},option=false},
{stacks=2,texture="hot_streak",position="Left + Right (Flipped)",scale=0.7,pulse=false,text=false,level=2,color={222,222,222},option=false},
{stacks=3,texture="hot_streak",position="Left + Right (Flipped)",scale=0.9,pulse=true ,text=false,level=3,color={255,255,255},option={
setupHash=SAO:HashNameFromStacks(0),
testHash={SAO:HashNameFromStacks(1),SAO:HashNameFromStacks(2),SAO:HashNameFromStacks(3)},
}},
},
}
)
end
local function registerFire(self)
useImpact()
if self.IsWrath()then
self:RegisterAura("firestarter",0,54741, "impact", "Top",0.8,255,255,255,true,{self:GetSpellName(flamestrike)})
end
if self.IsSoD()then
self:RegisterAura("hot_streak_full",0,hotStreakSoDSpellID, "hot_streak", "Left + Right (Flipped)",1,255,255,255,true,{self:GetSpellName(pyroblast)})
elseif SAO.IsWrath()then
self:RegisterAura("hot_streak_full",0,hotStreakSpellID, "hot_streak", "Left + Right (Flipped)",1,255,255,255,true,{self:GetSpellName(pyroblast)})
elseif self.IsCata()then
self:RegisterAura("hot_streak_full",0,hotStreakSpellID, "hot_streak", "Left + Right (Flipped)",1,255,255,255,true,{pyroblastBang})
elseif self.IsProject(SAO.FOREVER + SAO.MOP + SAO.RETAIL)then
useHeatingUpAndHotStreak()
end
if self.IsProject(SAO.SOD + SAO.WRATH + SAO.CATA)then
self:RegisterAura("hot_streak_half",0,heatingUpSpellID, "hot_streak", "Left + Right (Flipped)",0.5,255,255,255,false)
end
if self.IsProject(SAO.SOD + SAO.WRATH)then
self:RegisterAura("hot_streak_duo",0,hotStreakHeatingUpSpellID, "hot_streak", "Left + Right (Flipped)",0.5,255,255,255,false)
self:RegisterAura("hot_streak_duo",0,hotStreakHeatingUpSpellID, "hot_streak", "Left + Right (Flipped)",1,255,255,255,true)
end
end
local function registerFrost(self)
if self.IsProject(SAO.ERA + SAO.TBC + SAO.WRATH + SAO.CATA + SAO.MOP)then
self:RegisterAura("freeze",0,FrozenHandler.fakeSpellID,FrozenHandler.saoTexture,FrozenHandler.saoPosition,FrozenHandler.saoScaleFactor,255,255,255,false)
elseif self.IsProject(SAO.FOREVER)then
useFreezeDebuff()
end
if self.IsSoD()then
local iceLanceAndDeepFreezeSoD={self:GetSpellName(FrozenHandler.ice_lance_sod[1]),self:GetSpellName(FrozenHandler.deep_freeze_sod[1])}
self:RegisterAura("fingers_of_frost_1_sod",1,400670, "frozen_fingers", "Left",1,255,255,255,true,iceLanceAndDeepFreezeSoD)
self:RegisterAura("fingers_of_frost_2_sod",2,400670, "frozen_fingers", "Left + Right (Flipped)",1,255,255,255,true,iceLanceAndDeepFreezeSoD)
elseif self.IsWrath()then
local iceLanceAndDeepFreeze={self:GetSpellName(FrozenHandler.ice_lance[1]),self:GetSpellName(FrozenHandler.deep_freeze[1])}
self:RegisterAura("fingers_of_frost_1",1,74396, "frozen_fingers", "Left",1,255,255,255,true,iceLanceAndDeepFreeze)
self:RegisterAura("fingers_of_frost_2",2,74396, "frozen_fingers", "Left + Right (Flipped)",1,255,255,255,true,iceLanceAndDeepFreeze)
elseif self.IsCata()then
local iceLanceAndDeepFreeze={self:GetSpellName(FrozenHandler.ice_lance[1]),self:GetSpellName(FrozenHandler.deep_freeze[1])}
self:RegisterAura("fingers_of_frost_1",1,44544, "frozen_fingers", "Left (CCW)",1.1,222,222,222,true,iceLanceAndDeepFreeze)
self:RegisterAura("fingers_of_frost_2",2,44544, "frozen_fingers", "Left (CCW)",1.1,222,222,222,true,iceLanceAndDeepFreeze)
self:RegisterAura("fingers_of_frost_2",2,44544, "frozen_fingers", "Right (CW)",1.1,222,222,222,true)
elseif self.IsProject(SAO.FOREVER + SAO.MOP + SAO.RETAIL)then
useFingersOfFrost()
end
if self.IsSoD()then
self:RegisterAura("brain_freeze",0,400730, "brain_freeze", "Top",1,255,255,255,true,{self:GetSpellName(fireball),self:GetSpellName(spellfrostBoltSoD),self:GetSpellName(frostfireBoltSoD)})
elseif self.IsWrath()then
self:RegisterAura("brain_freeze",0,57761, "brain_freeze", "Top",1,255,255,255,true,{self:GetSpellName(fireball),self:GetSpellName(frostfireBolt)})
elseif self.IsCata()then
self:RegisterAura("brain_freeze",0,57761, "brain_freeze", "Top (CW)",1,255,255,255,true,{self:GetSpellName(fireball),self:GetSpellName(frostfireBolt)})
elseif self.IsMoP()then
useBrainFreeze()
end
useIceBarrier()
end
local function registerArcane(self)
useArcaneMissiles()
useMissileBarrage()
if self.IsCata()then
local arcanePotency1=57529
local arcanePotency2=57531
self:AddOverlayLink(arcanePotency2,arcanePotency1)
self:RegisterAura("arcane_potency_low",1,arcanePotency1, "surge_of_light", "Left",1.1,255,255,255,true,nil,true)
self:RegisterAura("arcane_potency_low",2,arcanePotency1, "surge_of_light", "Left + Right (Flipped)",1.1,255,255,255,true,nil,true)
self:RegisterAura("arcane_potency_high",1,arcanePotency2, "surge_of_light", "Left",1.1,255,255,255,true,nil,true)
self:RegisterAura("arcane_potency_high",2,arcanePotency2, "surge_of_light", "Left + Right (Flipped)",1.1,255,255,255,true,nil,true)
end
if isCompatibleWithClearcasting then
lazyCreateClearcastingVariants(self)
if clearcastingVariants then
local texture=function()
return clearcastingVariants.textureFunc() or self.TexName["genericarc_02"]
end
self:CreateEffect(
"clearcasting",
SAO.ALL_PROJECTS,
12536,
"aura",
{
overlay={texture=texture,position="Left + Right (Flipped)",outer=0.5,pulse=false},
}
)
end
end
useArcaneBlast()
useClearcasting()
end
local function registerItems(self)
SAO:CreateRevelationEffect("revelation_mage",1248808)
end
local function registerClass(self)
registerArcane(self)
registerFire(self)
registerFrost(self)
registerItems(self)
end
local function loadOptions(self)
local clearcastingTalent=12536
local clearcastingBuff=12536
local missileBarrageBuff=44401
local missileBarrageTalent=44404
local arcanePotencyBuff2=57531
local arcanePotencyTalent=31572
local heatingUpBuff=heatingUpSpellID
local hotStreakBuff=hotStreakSpellID
local hotStreakSoDBuff=hotStreakSoDSpellID
local hotStreakHeatingUpBuff=hotStreakHeatingUpSpellID
local hotStreakSoDRune=400624
local hotStreakTalent=44445
local firestarterBuff=54741
local firestarterTalent=44442
local brainFreezeBuff=57761
local brainFreezeTalent=44546
local brainFreezeSoDRune=400731
local brainFreezeSoDBuff=400730
local fingersOfFrostBuffWrath=74396
local fingersOfFrostBuffCata=44544
local fingersOfFrostTalent=44543
local fingersOfFrostSoDBuff=400670
local fingersOfFrostSoDTalent=fingersOfFrostSoDBuff
local arcaneBlastSoDBuff=400573
local missileBarrageSoDRune=400588
local missileBarrageSoDBuff=400589
local iceLance=FrozenHandler.ice_lance[1]
local iceLanceSoD=FrozenHandler.ice_lance_sod[1]
local deepFreeze=FrozenHandler.deep_freeze[1]
local deepFreezeSoD=FrozenHandler.deep_freeze_sod[1]
local oneToThreeStacks=self:NbStacks(1,3)
local fourStacks=self:NbStacks(4)
if isCompatibleWithClearcasting then
lazyCreateClearcastingVariants(self)
if clearcastingVariants then
self:AddOverlayOption(clearcastingTalent,clearcastingBuff,0,nil,clearcastingVariants)
end
end
if self.IsSoD()then
self:AddOverlayOption(missileBarrageSoDRune,missileBarrageSoDBuff)
elseif self.IsWrath()then
self:AddOverlayOption(missileBarrageTalent,missileBarrageBuff)
end
if self.IsSoD()then
self:AddOverlayOption(arcaneBlastSoDBuff,arcaneBlastSoDBuff,0,oneToThreeStacks,nil,3)
self:AddOverlayOption(arcaneBlastSoDBuff,arcaneBlastSoDBuff,self:HashNameFromStacks(4))
end
if self.IsCata()then
self:AddOverlayOption(arcanePotencyTalent,arcanePotencyBuff2,0,nil,nil,2)
end
if self.IsSoD()then
self:AddGlowingOption(missileBarrageSoDRune,missileBarrageSoDBuff,arcaneMissiles)
elseif self.IsWrath()then
self:AddGlowingOption(missileBarrageTalent,missileBarrageBuff,arcaneMissiles)
end
if self.IsSoD()then
self:AddGlowingOption(arcaneBlastSoDBuff,arcaneBlastSoDBuff,arcaneMissiles,fourStacks)
self:AddGlowingOption(arcaneBlastSoDBuff,arcaneBlastSoDBuff,arcaneExplosion,fourStacks)
end
local heatingUpDetails=self:translateHeatingUp()
local hotStreakDetails=self.IsSoD() and self:GetSpellName(hotStreakSoDBuff) or self:GetSpellName(hotStreakBuff)
local hotStreakHeatingUpDetails=string.format("%s %s",STATUS_TEXT_BOTH,ACTION_SPELL_AURA_APPLIED_DOSE)
if self.IsSoD()then
self:AddOverlayOption(hotStreakSoDRune,heatingUpBuff,0,heatingUpDetails)
self:AddOverlayOption(hotStreakSoDRune,hotStreakSoDBuff,0,hotStreakDetails)
self:AddOverlayOption(hotStreakSoDRune,hotStreakHeatingUpBuff,0,hotStreakHeatingUpDetails)
elseif self.IsWrath() or self.IsCata()then
self:AddOverlayOption(hotStreakTalent,heatingUpBuff,0,heatingUpDetails)
self:AddOverlayOption(hotStreakTalent,hotStreakBuff,0,hotStreakDetails)
self:AddOverlayOption(hotStreakTalent,hotStreakHeatingUpBuff,0,hotStreakHeatingUpDetails)
end
if self.IsWrath()then
self:AddOverlayOption(firestarterTalent,firestarterBuff)
end
if self.IsSoD()then
self:AddGlowingOption(hotStreakSoDRune,hotStreakSoDBuff,pyroblast)
elseif self.IsWrath()then
self:AddGlowingOption(hotStreakTalent,hotStreakBuff,pyroblast)
elseif self.IsCata()then
self:AddGlowingOption(hotStreakTalent,hotStreakBuff,pyroblastBang)
end
if self.IsWrath()then
self:AddGlowingOption(firestarterTalent,firestarterBuff,flamestrike)
end
if FrozenHandler.initialized then
self:AddOverlayOption(FrozenHandler.freezeTalent,FrozenHandler.freezeID,0,self:translateDebuff(),nil,nil,FrozenHandler.fakeSpellID)
end
if self.IsSoD()then
self:AddOverlayOption(fingersOfFrostSoDTalent,fingersOfFrostSoDBuff,0,nil,nil,2)
elseif self.IsWrath()then
self:AddOverlayOption(fingersOfFrostTalent,fingersOfFrostBuffWrath,0,nil,nil,2)
elseif self.IsCata()then
self:AddOverlayOption(fingersOfFrostTalent,fingersOfFrostBuffCata,0,nil,nil,2)
end
if self.IsSoD()then
self:AddOverlayOption(brainFreezeSoDRune,brainFreezeSoDBuff)
elseif self.IsWrath() or self.IsCata()then
self:AddOverlayOption(brainFreezeTalent,brainFreezeBuff)
end
if self.IsProject(SAO.TBC_AND_ONWARD)then
self:AddGlowingOption(FrozenHandler.freezeTalent,FrozenHandler.freezeID,iceLance)
end
if self.IsProject(SAO.WRATH_AND_ONWARD)then
self:AddGlowingOption(FrozenHandler.freezeTalent,FrozenHandler.freezeID,deepFreeze)
end
if self.IsSoD()then
self:AddGlowingOption(brainFreezeSoDRune,brainFreezeSoDBuff,fireball)
self:AddGlowingOption(brainFreezeSoDRune,brainFreezeSoDBuff,spellfrostBoltSoD)
self:AddGlowingOption(brainFreezeSoDRune,brainFreezeSoDBuff,frostfireBoltSoD)
elseif self.IsWrath() or self.IsCata()then
self:AddGlowingOption(brainFreezeTalent,brainFreezeBuff,fireball)
self:AddGlowingOption(brainFreezeTalent,brainFreezeBuff,frostfireBolt)
end
if self.IsSoD()then
self:AddGlowingOption(fingersOfFrostSoDTalent,fingersOfFrostSoDBuff,iceLanceSoD)
self:AddGlowingOption(fingersOfFrostSoDTalent,fingersOfFrostSoDBuff,deepFreezeSoD)
self:AddGlowingOption(FrozenHandler.freezeTalent,FrozenHandler.freezeID,iceLanceSoD)
self:AddGlowingOption(FrozenHandler.freezeTalent,FrozenHandler.freezeID,deepFreezeSoD)
elseif self.IsWrath()then
self:AddGlowingOption(fingersOfFrostTalent,fingersOfFrostBuffWrath,iceLance)
self:AddGlowingOption(fingersOfFrostTalent,fingersOfFrostBuffWrath,deepFreeze)
elseif self.IsCata()then
self:AddGlowingOption(fingersOfFrostTalent,fingersOfFrostBuffCata,iceLance)
self:AddGlowingOption(fingersOfFrostTalent,fingersOfFrostBuffCata,deepFreeze)
end
end
SAO.Class["MAGE"]={
["Register"]=registerClass,
["LoadOptions"]=loadOptions,
["COMBAT_LOG_EVENT_UNFILTERED"]=(isCompatibleWithFrozen or isCompatibleWithCustomHotStreak) and customCLEU or nil,
["PLAYER_LOGIN"]=(isCompatibleWithFrozen or isCompatibleWithCustomHotStreak) and customLogin or nil,
["CHARACTER_POINTS_CHANGED"]=isCompatibleWithCustomHotStreak and recheckTalents or nil,
["PLAYER_TARGET_CHANGED"]=isCompatibleWithFrozen and retarget or nil,
["UNIT_HEALTH"]=isCompatibleWithFrozen and unitHealth or nil,
["UNIT_HEALTH_FREQUENT"]=(isCompatibleWithFrozen and not SAO.HasMidnightEvents()) and unitHealthFrequent or nil,
[SAO.IsWrath() and "PLAYER_TALENT_UPDATE" or "CHARACTER_POINTS_CHANGED"]=isCompatibleWithCustomHotStreak and recheckTalents or nil,
["RUNE_UPDATED"]=(isCompatibleWithCustomHotStreak and SAO.IsSoD()) and recheckTalents or nil,
}
