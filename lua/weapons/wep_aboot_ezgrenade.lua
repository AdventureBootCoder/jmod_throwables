﻿-- AdventureBoots 2024
AddCSLuaFile()
SWEP.PrintName = "EZ Grenade"
SWEP.Author = "AdventureBoots"
SWEP.Purpose = ""
--JMod.SetWepSelectIcon(SWEP, "entities/ent_jack_gmod_ezmedkit")
SWEP.Spawnable = false
SWEP.UseHands = true
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.InstantPickup = true -- Fort Fights compatibility
SWEP.EZdroppable = true
SWEP.ViewModel = "models/weapons/c_grenade.mdl"
SWEP.WorldModel = "models/weapons/w_grenade.mdl"
SWEP.ViewModelFOV = 52
SWEP.Slot = 4
SWEP.SlotPos = 1
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.ShowWorldModel = false
SWEP.VMangleCorrection = Angle(0, 24, 180)
SWEP.WMangleCorrection = Angle(142, 0, -90)

SWEP.VElements = {
	["grenade"] = { 
		type = "Model", 
		--model = "models/weapons/w_grenade.mdl",--"models/jmod/explosives/grenades/firenade/incendiary_grenade.mdl", 
		bone = "ValveBiped.Grenade_body", 
		rel = "", 
		pos = Vector(0.238, 0.3, -0.718),
		angle = Angle(0, 24, 180), 
		size = Vector(1, 1, 1), 
		color = Color(255, 255, 255, 255), 
		surpresslightning = false,
		material = "", 
		skin = 0, 
		bodygroup = {} 
	}
}

SWEP.WElements = {
	["grenade"] = { 
		type = "Model", 
		--model = "models/weapons/w_grenade.mdl",--"models/jmod/explosives/grenades/firenade/incendiary_grenade.mdl", 
		bone = "ValveBiped.Anim_Attachment_RH", 
		rel = "", 
		pos = Vector(0, 0, 0), 
		angle = Angle(142, 0, -90), 
		size = Vector(0.8, 0.8, 0.8), 
		color = Color(255, 255, 255, 255), 
		surpresslightning = false, 
		material = "", 
		skin = 0, 
		bodygroup = {} 
	}
}

local Wepify = CreateConVar("jmod_ezgrenade_wepify", "0", FCVAR_ARCHIVE, "Wepify the grenades")

if SERVER then
	util.AddNetworkString("JMod_EZGrenadeData")
	hook.Add("OnPlayerPhysicsPickup", "JMod_EZGrenadePickup", function(ply, ent)
		if not Wepify:GetBool() then return end
		if not(IsValid(ent:GetParent())) and ent.EZinvPrime and not(ent.JModGUIcolorable) and not(ent:GetState() >= JMod.EZ_STATE_ON) then
			local GrenadeSWEP
			local PickedUp = true
			if ply:HasWeapon("wep_aboot_ezgrenade") then
				GrenadeSWEP = ply:GetWeapon("wep_aboot_ezgrenade")
				-- Store the old grenade before setting the new one
				local OldGrenade = GrenadeSWEP.GrenadeEntity
				-- Stow the old grenade if it exists
				if IsValid(OldGrenade) then
					GrenadeSWEP:StowGrenade()
				end
				GrenadeSWEP:GrabNewGrenade(ent)
			else
				-- Give the player a grenade swep
				GrenadeSWEP = ents.Create("wep_aboot_ezgrenade")
				GrenadeSWEP.GrenadeEntity = ent
				GrenadeSWEP:Spawn()
				GrenadeSWEP:Activate()
				PickedUp = ply:PickupWeapon(GrenadeSWEP)
			end
			ent:SetOwner(ply)

			timer.Simple(0, function()
				if not PickedUp then 
					if IsValid(GrenadeSWEP) then GrenadeSWEP:Remove() end
					return 
				end
				if IsValid(ply) and IsValid(ent) and IsValid(GrenadeSWEP) then
					ent:ForcePlayerDrop()
					ply:SelectWeapon("wep_aboot_ezgrenade")
				end
			end)

			return false
		end
	end)
	hook.Add("PlayerSwitchWeapon", "JMod_EZGrenadeDrop", function(ply, oldWeapon, newWeapon)
		if IsValid(newWeapon) and newWeapon:GetClass() == "wep_aboot_ezgrenade" then
			if IsValid(oldWeapon) and oldWeapon:GetClass() ~= "wep_aboot_ezgrenade" then
				ply.EZoldNonGrenadeSwep = oldWeapon
			end

			return 
		end
		if IsValid(oldWeapon) and oldWeapon:GetClass() == "wep_aboot_ezgrenade" then
			oldWeapon:StowGrenade()
			oldWeapon.EZdropper = ply
			ply:DropNamedWeapon("wep_aboot_ezgrenade")
		end
	end)
elseif CLIENT then
	net.Receive("JMod_EZGrenadeData", function(len)
		local GrenadeSWEP = net.ReadEntity()
		local GrenadeTypeInfo = net.ReadTable()

		if IsValid(GrenadeSWEP) then
			GrenadeSWEP:SetupGrenadeInfo(GrenadeTypeInfo)
		end
	end)
end

function SWEP:SetupGrenadeInfo(entityOrTable)
	if type(entityOrTable) == "table" then
		self.GrenadeTypeInfo = entityOrTable
	else
		self.GrenadeTypeInfo = {}
		local entity = entityOrTable
		local NeededInfo = {
			"Model",
			"Material",
			"ModelScale",
			"PinBodygroup",
			"SpoonBodygroup",
			"JModPreferredCarryAngles"
		}

		for k, v in pairs(NeededInfo) do
			if type(entity[v]) == "table" then
				self.GrenadeTypeInfo[v] = table.Copy(entity[v])
				self.GrenadeTypeInfo[v].BaseClass = nil
			else
				self.GrenadeTypeInfo[v] = entity[v]
			end
		end

		-- Default bodygroups
		self.GrenadeTypeInfo.DefaultBodygroups = self.GrenadeTypeInfo.DefaultBodygroups or {}
		for i = 0, entity:GetNumBodyGroups() - 1 do
			self.GrenadeTypeInfo.DefaultBodygroups[i] = entity:GetBodygroup(i)
		end
		-- Extra stuff
		self.GrenadeTypeInfo.Color = entity:GetColor()

		self:SetGrenadeType(entity:GetClass())
	end
	

	if SERVER then
		timer.Simple(0.1, function()
			if not IsValid(self) then return end
			net.Start("JMod_EZGrenadeData")
				net.WriteEntity(self)
				net.WriteTable(self.GrenadeTypeInfo)
				--print("Sent grenade info")
			net.Broadcast()
		end)
	end

	local CombineNade = false
	if (self:GetGrenadeType() == "ent_aboot_gmod_ezcombinenade") then CombineNade = true end

	local GrenadeVElements = self.VElements["grenade"]
	local GrenadeWElements = self.WElements["grenade"]
	if CombineNade then
		GrenadeVElements.model = ""
		GrenadeWElements.model = ""
		if IsValid(GrenadeVElements.modelEnt) then GrenadeVElements.modelEnt:Remove() end
		if IsValid(GrenadeWElements.modelEnt) then GrenadeWElements.modelEnt:Remove() end
		self.ShowWorldModel = true 
		self.SCKPreDrawViewModel = true
	else
		GrenadeVElements.model = self.GrenadeTypeInfo.Model
		GrenadeWElements.model = self.GrenadeTypeInfo.Model
		self.ShowWorldModel = false 
		self.SCKPreDrawViewModel = false
	end
	GrenadeVElements.material = self.GrenadeTypeInfo.Material
	GrenadeWElements.material = self.GrenadeTypeInfo.Material

	if self.GrenadeTypeInfo.ModelScale then
		GrenadeVElements.size = Vector(self.GrenadeTypeInfo.ModelScale, self.GrenadeTypeInfo.ModelScale, self.GrenadeTypeInfo.ModelScale)
		GrenadeWElements.size = Vector(self.GrenadeTypeInfo.ModelScale, self.GrenadeTypeInfo.ModelScale, self.GrenadeTypeInfo.ModelScale)
	end

	if self.GrenadeTypeInfo.JModPreferredCarryAngles then
		GrenadeVElements.angle = self.VMangleCorrection + self.GrenadeTypeInfo.JModPreferredCarryAngles
		GrenadeWElements.angle = self.WMangleCorrection --+ self.GrenadeTypeInfo.JModPreferredCarryAngles
	end

	GrenadeVElements.color = self.GrenadeTypeInfo.Color
	GrenadeWElements.color = self.GrenadeTypeInfo.Color

	GrenadeVElements.bodygroup = self.GrenadeTypeInfo.DefaultBodygroups
	GrenadeWElements.bodygroup = self.GrenadeTypeInfo.DefaultBodygroups

	self:SCKInitialize()

	local PinInfo = self.GrenadeTypeInfo.PinBodygroup
	if PinInfo then
		timer.Simple(.5, function()
			if not (IsValid(self) and IsValid(self.Owner)) then return end
			self:EmitSound("weapons/pinpull.wav", 60, 100)
			--sound.Play("weapons/pinpull.wav", self.Owner:GetShootPos(), 60, 100, 1)
			self.VElements["grenade"].bodygroup[PinInfo[1]] = PinInfo[2]
			self.WElements["grenade"].bodygroup[PinInfo[1]] = PinInfo[2]
		end)
	end
end

function SWEP:GrabNewGrenade(entity)
	self.GrenadeTypeInfo = self.GrenadeTypeInfo or {}
	self.NextIdle = self.NextIdle or 0
	self.ReadyToThrow = false
	self.ReadyToLob = false
	self.FinishThrowTime = 0
	
	-- Set a safe position before parenting to prevent coordinate issues
	entity:SetPos(self:GetPos() + Vector(0, 0, 10))
	entity:SetParent(self)
	entity:SetNoDraw(true)
	entity:SetNotSolid(true)
	
	-- Hide the grenade after a second
	timer.Simple(.1, function()
		if IsValid(entity) and entity:GetParent() == self then
			entity:SetNoDraw(true)
		end
	end)
	
	self.GrenadeEntity = entity
	self:SetupGrenadeInfo(entity)
end

function SWEP:StowGrenade()
	if not IsFirstTimePredicted() then return end
	local Owner = self.Owner
	if not(IsValid(Owner)) and IsValid(self.EZdropper) then Owner = self.EZdropper end
	if not IsValid(Owner) then return end
	if self:GetGrenadeType() == "" then return end
	
	-- Use the original grenade entity instead of creating a new one
	local Grenade = self.GrenadeEntity
	if IsValid(Grenade) then
		-- Unparent and restore the grenade
		Grenade:SetParent(nil)
		Grenade:SetNoDraw(false)
		Grenade:SetNotSolid(false)
		
		-- Set position for inventory
		Grenade:SetPos(util.QuickTrace(Owner:GetShootPos(), Owner:GetAimVector() * 60, {Owner, Grenade}).HitPos)
		
		local Successful = JMod.AddToInventory(Owner, Grenade)
		
		-- Clear the reference
		self.GrenadeEntity = nil
	end
end

function SWEP:SetupDataTables()
	self:NetworkVar("String", 0, "GrenadeType")
end

function SWEP:Initialize()
	self:SetHoldType("grenade")
	self.GrenadeTypeInfo = self.GrenadeTypeInfo or {}
	self.NextIdle = 0
	self.ReadyToThrow = false
	self.ReadyToLob = false
	self.FinishThrowTime = 0
	if SERVER then
		if IsValid(self.GrenadeEntity) then
			self:GrabNewGrenade(self.GrenadeEntity)
		end
	end
end

function SWEP:Deploy()
	local Owner = self.Owner
	if not IsValid(Owner) then return end
	--if not IsFirstTimePredicted() then return end
	local vm = Owner:GetViewModel()

	self:SetNextPrimaryFire(CurTime() + .75)
	self:SetNextSecondaryFire(CurTime() + .75)

	if IsValid(vm) then
		vm:SendViewModelMatchingSequence(vm:LookupSequence("draw"))
		self:UpdateNextIdle()
	end

	return true
end

function SWEP:CreateGrenade()
	if not IsFirstTimePredicted() then return NULL end
	local GrenadeType = self:GetGrenadeType() --table.Random(GrenadeTypes)
	if GrenadeType == "" then return NULL end
	local Owner = (IsValid(self:GetOwner()) and self:GetOwner()) or self.EZdropper
	
	-- Use the original grenade entity instead of creating a new one
	local Grenade = self.GrenadeEntity
	if IsValid(Grenade) then
		-- Unparent and restore the grenade
		Grenade:SetParent(nil)
		Grenade:SetNoDraw(false)
		Grenade:SetNotSolid(false)
		
		-- Set a safe position relative to the owner
		local safePos = Owner:GetPos() + Vector(0, 0, 10)
		Grenade:SetPos(safePos)
		
		JMod.SetEZowner(Grenade, Owner)
		Grenade:SetOwner(Owner)
		
		-- Clear the reference since we're using it
		self.GrenadeEntity = nil
		
		timer.Simple(0.1, function()
			if IsValid(Grenade) then
				Grenade:SetOwner(nil)
			end
		end)
		
		return Grenade
	end
	
	return NULL
end

function SWEP:Throw(hardThrow)
	--if not IsFirstTimePredicted() then return end
	local Owner = self:GetOwner()
	local vm = Owner:GetViewModel()

	if SERVER then
		local Grenade = self:CreateGrenade()
		if not IsValid(Grenade) then return end
		Grenade:Prime(Owner)

		local AimVec, ShootPos = Owner:GetAimVector(), Owner:GetShootPos()
		local ThrowPos = ShootPos + AimVec * 25
		local Bone = Owner:LookupBone("ValveBiped.Bip01_R_Hand")
		if Bone then
			ThrowPos = Owner:GetBonePosition(Bone) + AimVec * 50
		end
		local ThrowTr = util.QuickTrace(ShootPos, (ThrowPos - ShootPos)*.5, {Owner, Grenade})

		if ThrowTr.Hit then
			Grenade:SetPos(ThrowTr.HitPos + ThrowTr.HitNormal * 5)
		else
			Grenade:SetPos(ThrowTr.HitPos)
		end
		Grenade:SetAngles(AimVec:Angle())

		local ShootTr = util.QuickTrace(ShootPos, AimVec * 9e9, {Owner, Grenade})
		local ThrowDir = (ShootTr.HitPos - ThrowPos):GetNormalized()
		local Phys = Grenade:GetPhysicsObject()

		if Grenade.ShiftAltUse and Owner:IsPlayer() and Owner:KeyDown(JMod.Config.General.AltFunctionKey) then
			Grenade:ShiftAltUse(Owner, true)
		end

		if hardThrow then
			--vm:SendViewModelMatchingSequence(vm:LookupSequence("throw"))
			timer.Simple(0, function()
				if IsValid(Phys) then
					Phys:SetVelocity(Owner:GetVelocity())
					Phys:ApplyForceCenter(ThrowDir * 1.2 * (Grenade.HardThrowStr or 600) * Phys:GetMass() * JMod.GetPlayerStrength(Owner))
					if Grenade.EZspinThrow then
						Phys:ApplyForceOffset(AimVec * Phys:GetMass() * 50, Phys:GetMassCenter() + Vector(0, 0, 10))
						Phys:ApplyForceOffset(-AimVec * Phys:GetMass() * 50, Phys:GetMassCenter() - Vector(0, 0, 10))
					end
				end
			end)
		else
			if Owner:KeyDown(IN_DUCK) then --and not Grenade.EZspinThrow then
				local CurrentAngle = Grenade:GetAngles()
				CurrentAngle:RotateAroundAxis(CurrentAngle:Forward(), 90)
				Grenade:SetAngles(CurrentAngle)
				local FloorPos = util.QuickTrace(ShootPos, AimVec * 30 + Vector(0, 0, Owner:OBBMins().z), {Owner, Grenade}).HitPos
				Grenade:SetPos(FloorPos)
				--vm:SendViewModelMatchingSequence(vm:LookupSequence("roll"))
				timer.Simple(0, function()
					if IsValid(Phys) then
						Phys:ApplyForceCenter(AimVec * 1.2 * (Grenade.SoftThrowStr or 400) * Phys:GetMass() * JMod.GetPlayerStrength(Owner))
						Phys:ApplyForceOffset(AimVec * Phys:GetMass() * 10, Phys:GetMassCenter() + Vector(0, 0, 10))
						Phys:ApplyForceOffset(-AimVec * Phys:GetMass() * 10, Phys:GetMassCenter() - Vector(0, 0, 10))
					end
				end)
			else
				--vm:SendViewModelMatchingSequence(vm:LookupSequence("lob"))
				timer.Simple(0, function()
					if IsValid(Phys) then
						ThrowDir.z = ThrowDir.z + 0.3
						Phys:ApplyForceCenter(ThrowDir * 1.2 * (Grenade.SoftThrowStr or 400) * Phys:GetMass() * JMod.GetPlayerStrength(Owner))
					end
				end)
			end
		end

		local ThrowTime = vm:SequenceDuration()
		self.FinishThrowTime = CurTime() + ThrowTime

	elseif CLIENT and IsFirstTimePredicted() then
		if hardThrow then
			vm:SendViewModelMatchingSequence(vm:LookupSequence("throw"))
		else
			if Owner:KeyDown(IN_DUCK) then
				vm:SendViewModelMatchingSequence(vm:LookupSequence("roll"))
			else
				vm:SendViewModelMatchingSequence(vm:LookupSequence("lob"))
			end
		end
		--self.Owner:ViewPunch(Angle(10, 0, 0))
	end

	Owner:SetAnimation(PLAYER_ATTACK1)
	self:UpdateNextIdle()
end

function SWEP:PrimaryAttack()
	--if not IsFirstTimePredicted() then return end
	local Owner = self:GetOwner()
	local vm = Owner:GetViewModel()

	if not self.ReadyToThrow then
		vm:SendViewModelMatchingSequence(vm:LookupSequence("drawbackhigh"))
		self.ReadyToThrow = true
	end

	self:SetNextPrimaryFire(CurTime() + .75)
	self:SetNextSecondaryFire(CurTime() + .75)
end

function SWEP:SecondaryAttack()
	--if not IsFirstTimePredicted() then return end
	local Owner = self:GetOwner()
	local vm = Owner:GetViewModel()

	if not self.ReadyToLob then
		vm:SendViewModelMatchingSequence(vm:LookupSequence("drawbacklow"))
		self.ReadyToLob = true
	end
	
	self:SetNextPrimaryFire(CurTime() + .75)
	self:SetNextSecondaryFire(CurTime() + .75)
end

function SWEP:Reload()
	if (self.FinishThrowTime > 0) or not IsFirstTimePredicted() then return end
	if SERVER then
		local Owner = self:GetOwner()
		self.EZdropper = Owner
		if JMod.IsAltUsing(Owner) then
			self.Dropped = true
			Owner:DropWeapon(self)
		else
			self:StowGrenade()
			Owner:DropWeapon(self)
		end
	end
end

function SWEP:OnDrop()
	if not IsFirstTimePredicted() then return end
	local Ply = self.EZdropper
	if self.Dropped then
		-- Use the original grenade entity if available
		local Grenade = self.GrenadeEntity
		if IsValid(Grenade) then
			-- Unparent and restore the grenade
			Grenade:SetParent(nil)
			Grenade:SetNoDraw(false)
			Grenade:SetNotSolid(false)
			Grenade:SetPos(util.QuickTrace(Ply:GetShootPos(), Ply:GetAimVector() * 50, {Ply, Grenade}).HitPos)
		end
	end

	timer.Simple(0, function()
		if IsValid(Ply) and Ply:IsPlayer() then
			local OldSwep = Ply.EZoldNonGrenadeSwep
			
			if IsValid(OldSwep) and OldSwep:IsWeapon() then
				Ply:SelectWeapon(OldSwep:GetClass())
			end
		end
	end)
	self:Remove()
	self.EZdropper = nil
end

function SWEP:Think()
	-- Check if the grenade entity is still valid, remove weapon if not
	if SERVER and not IsValid(self.GrenadeEntity) then
		if IsValid(self.Owner) and self.Owner:IsPlayer() then
			self.Owner:DropWeapon(self)
		end
		return
	end

	local Time = CurTime()
	local Owner = self:GetOwner()
	local vm = Owner:GetViewModel()
	local idletime = self.NextIdle
	local Throwing = (self.FinishThrowTime > 0) and (Time < self.FinishThrowTime)

	if idletime > 0 and idletime < Time and not(Throwing) then
		vm:SendViewModelMatchingSequence(vm:LookupSequence("idle01"))
		self:UpdateNextIdle()
	end

	--if IsFirstTimePredicted() and not self.PinPulled and self:GetNextPrimaryFire() > Time then
	--	--PrintTable(self.GrenadeTypeInfo)
	--	if self.GrenadeTypeInfo.PinBodygroup then
	--		local PinInfo = self.GrenadeTypeInfo.PinBodygroup
	--		--self:EmitSound("weapons/pinpull.wav", 60, 100)
	--		sound.Play("weapons/pinpull.wav", Owner:GetShootPos(), 60, 100, 1)
	--		self.VElements["grenade"].bodygroup[PinInfo[1]] = PinInfo[2]
	--	end
	--	self.PinPulled = true
	--end

	local LeftClickin, RightClickin = Owner:KeyDown(IN_ATTACK), Owner:KeyDown(IN_ATTACK2)

	if self.ReadyToThrow or self.ReadyToLob then
		self.NextIdle = Time + 1
	end

	if self.ReadyToThrow and not LeftClickin then
		self.ReadyToThrow = false
		self:Throw(true)
	elseif self.ReadyToLob and not RightClickin then
		self.ReadyToLob = false
		self:Throw(false)
	end

	if Owner:KeyDown(IN_SPEED) then
		self:SetHoldType("grenade")
	elseif RightClickin then
		self:SetHoldType("grenade")
	else
		self:SetHoldType("grenade")
	end

	if (self.FinishThrowTime > Time) and IsFirstTimePredicted() then
		self:SetGrenadeType("")
		-- Check their inventory for any other grenades
		local FoundGrenade = false
		if Owner.JModInv then
			for k, tbl in ipairs(Owner.JModInv.items) do
				local Nade = tbl.ent
		
				if IsValid(Nade) and Nade.EZinvPrime then
					-- Remove the grenade from the inventory
					Nade = JMod.RemoveFromInventory(Owner, Nade, nil, false, true)
					self:GrabNewGrenade(Nade)
					FoundGrenade = true

					local vm = Owner:GetViewModel()
					if IsValid(vm) then
						vm:SendViewModelMatchingSequence(vm:LookupSequence("draw"))
						self:UpdateNextIdle()
					end

					break
				end
			end
		end

		if not FoundGrenade then
			self.EZdropper = Owner
			Owner:DropWeapon(self)
		end
	end
end

function SWEP:OnRemove()
	self:SCKHolster()

	-- Clean up the parented grenade entity
	if IsValid(self.GrenadeEntity) then
		self.GrenadeEntity:SetParent(nil)
		self.GrenadeEntity:SetNoDraw(false)
		self.GrenadeEntity:SetNotSolid(false)
		self.GrenadeEntity:SetPos(self:GetPos() + Vector(0, 0, 10))
		
		-- If the player who was holding it is dead, prime the grenade
		local Owner = JMod.GetEZowner(self.GrenadeEntity)
		print("Deadman's trigger: "..tostring(Owner))
		if IsValid(Owner) and Owner:IsPlayer() and not Owner:Alive() then
			if self.GrenadeEntity.Prime then
				self.GrenadeEntity:Prime(Owner)
			end
		end
		
		-- Don't remove it, let it fall to the ground or be handled by other systems
	end

	if IsValid(self.Owner) and CLIENT and self.Owner:IsPlayer() then
		local vm = self.Owner:GetViewModel()

		if IsValid(vm) then
			vm:SetMaterial("")
		end
	end

	-- ADDED :
	if CLIENT then
		-- Removes V Models
		for k, v in pairs(self.VElements) do
			local model = v.modelEnt

			if v.type == "Model" and IsValid(model) then
				model:Remove()
			end
		end

		-- Removes W Models
		for k, v in pairs(self.WElements) do
			local model = v.modelEnt

			if v.type == "Model" and IsValid(model) then
				model:Remove()
			end
		end
	end
end

function SWEP:Holster(wep)
	-- Not calling OnRemove to keep the models
	self:SCKHolster()

	if IsValid(self.Owner) and CLIENT and self.Owner:IsPlayer() then
		local vm = self.Owner:GetViewModel()

		if IsValid(vm) then
			vm:SetMaterial("")
		end
	end

	return true
end

function SWEP:PreDrawViewModel(vm, wep, ply)
	if not self.SCKPreDrawViewModel then
		vm:SetMaterial("engine/occlusionproxy") -- Hide that view model with hacky material
	else
		vm:SetMaterial()
	end
end

function SWEP:ViewModelDrawn()
	self:SCKViewModelDrawn()
end

function SWEP:DrawWorldModel()
	self:SCKDrawWorldModel()
end

local Downness = 0

function SWEP:GetViewModelPosition(pos, ang)
	local FT = FrameTime()

	if self.Owner:KeyDown(IN_SPEED) or self.Owner:KeyDown(IN_ATTACK2) then
		Downness = Lerp(FT * 2, Downness, 0)
	else
		Downness = Lerp(FT * 2, Downness, 0)
	end

	ang:RotateAroundAxis(ang:Right(), -Downness * 5)

	return pos, ang
end

function SWEP:UpdateNextIdle()
	if not(self.Owner:IsPlayer()) then return end
	local vm = self.Owner:GetViewModel()
	self.NextIdle = CurTime() + vm:SequenceDuration()
end

function SWEP:DrawHUD()
	if GetConVar("cl_drawhud"):GetBool() == false then return end
	if self.Owner:ShouldDrawLocalPlayer() then return end
	local W, H = ScrW(), ScrH()
end

----------------- shit -------------------
function SWEP:SCKHolster()
	if CLIENT and IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()

		if IsValid(vm) then
			self:ResetBonePositions(vm)
		end
	end
end

function SWEP:SCKInitialize()
	if CLIENT then
		-- Create a new table for every weapon instance
		self.VElements = table.FullCopy(self.VElements)
		self.WElements = table.FullCopy(self.WElements)
		self.ViewModelBoneMods = table.FullCopy(self.ViewModelBoneMods)
		self:CreateModels(self.VElements) -- create viewmodels
		self:CreateModels(self.WElements) -- create worldmodels

		-- init view model bone build function
		if IsValid(self.Owner) then
			local vm = self.Owner:GetViewModel()

			if IsValid(vm) then
				self:ResetBonePositions(vm)
			end

			-- Init viewmodel visibility
			if self.ShowViewModel == nil or self.ShowViewModel then
				if IsValid(vm) then
					vm:SetColor(Color(255, 255, 255, 255))
				end
			else
				-- we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
				vm:SetColor(Color(255, 255, 255, 1))
				-- ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
				-- however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
				vm:SetMaterial("Debug/hsv")
			end
		end
	end
end

if CLIENT then
	SWEP.vRenderOrder = nil

	function SWEP:SCKViewModelDrawn()
		local vm = self.Owner:GetViewModel()
		if not IsValid(vm) then return end
		if not self.VElements then return end
		self:UpdateBonePositions(vm)

		if not self.vRenderOrder then
			-- we build a render order because sprites need to be drawn after models
			self.vRenderOrder = {}

			for k, v in pairs(self.VElements) do
				if v.type == "Model" then
					table.insert(self.vRenderOrder, 1, k)
				elseif v.type == "Sprite" or v.type == "Quad" then
					table.insert(self.vRenderOrder, k)
				end
			end
		end

		for k, name in ipairs(self.vRenderOrder) do
			local v = self.VElements[name]

			if not v then
				self.vRenderOrder = nil
				break
			end

			if v.hide then continue end
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			if not v.bone then continue end
			local pos, ang = self:GetBoneOrientation(self.VElements, v, vm)
			if not pos then continue end

			if v.type == "Model" and IsValid(model) then
				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				model:SetAngles(ang)
				--model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix("RenderMultiply", matrix)

				if v.material == "" then
					model:SetMaterial("")
				elseif model:GetMaterial() ~= v.material then
					model:SetMaterial(v.material)
				end

				if v.skin and v.skin ~= model:GetSkin() then
					model:SetSkin(v.skin)
				end

				if v.bodygroup then
					for k, v in pairs(v.bodygroup) do
						if model:GetBodygroup(k) ~= v then
							model:SetBodygroup(k, v)
						end
					end
				end

				if v.surpresslightning then
					render.SuppressEngineLighting(true)
				end

				render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
				render.SetBlend(v.color.a / 255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)

				if v.surpresslightning then
					render.SuppressEngineLighting(false)
				end
			elseif v.type == "Sprite" and sprite then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
			elseif v.type == "Quad" and v.draw_func then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				cam.Start3D2D(drawpos, ang, v.size)
				v.draw_func(self)
				cam.End3D2D()
			end
		end
	end

	SWEP.wRenderOrder = nil

	function SWEP:SCKDrawWorldModel()
		if self.ShowWorldModel == nil or self.ShowWorldModel then
			self:DrawModel()
		end

		if not self.WElements then return end

		if not self.wRenderOrder then
			self.wRenderOrder = {}

			for k, v in pairs(self.WElements) do
				if v.type == "Model" then
					table.insert(self.wRenderOrder, 1, k)
				elseif v.type == "Sprite" or v.type == "Quad" then
					table.insert(self.wRenderOrder, k)
				end
			end
		end

		local bone_ent

		if IsValid(self.Owner) then
			bone_ent = self.Owner
		else
			-- when the weapon is dropped
			bone_ent = self
		end

		for k, name in pairs(self.wRenderOrder) do
			local v = self.WElements[name]

			if not v then
				self.wRenderOrder = nil
				break
			end

			if v.hide then continue end
			local pos, ang

			if v.bone then
				pos, ang = self:GetBoneOrientation(self.WElements, v, bone_ent)
			else
				pos, ang = self:GetBoneOrientation(self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand")
			end

			if not pos then continue end
			local model = v.modelEnt
			local sprite = v.spriteMaterial

			if v.type == "Model" and IsValid(model) then
				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				model:SetAngles(ang)
				--model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix("RenderMultiply", matrix)

				if v.material == "" then
					model:SetMaterial("")
				elseif model:GetMaterial() ~= v.material then
					model:SetMaterial(v.material)
				end

				if v.skin and v.skin ~= model:GetSkin() then
					model:SetSkin(v.skin)
				end

				if v.bodygroup then
					for k, v in pairs(v.bodygroup) do
						if model:GetBodygroup(k) ~= v then
							model:SetBodygroup(k, v)
						end
					end
				end

				if v.surpresslightning then
					render.SuppressEngineLighting(true)
				end

				render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
				render.SetBlend(v.color.a / 255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)

				if v.surpresslightning then
					render.SuppressEngineLighting(false)
				end
			elseif v.type == "Sprite" and sprite then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
			elseif v.type == "Quad" and v.draw_func then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				cam.Start3D2D(drawpos, ang, v.size)
				v.draw_func(self)
				cam.End3D2D()
			end
		end
	end

	function SWEP:GetBoneOrientation(basetab, tab, ent, bone_override)
		local bone, pos, ang

		if tab.rel and tab.rel ~= "" then
			local v = basetab[tab.rel]
			if not v then return end
			-- Technically, if there exists an element with the same name as a bone
			-- you can get in an infinite loop. Let's just hope nobody's that stupid.
			pos, ang = self:GetBoneOrientation(basetab, v, ent)
			if not pos then return end
			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
		else
			bone = ent:LookupBone(bone_override or tab.bone)
			if not bone then return end
			pos, ang = Vector(0, 0, 0), Angle(0, 0, 0)
			local m = ent:GetBoneMatrix(bone)

			if m then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end

			if IsValid(self.Owner) and self.Owner:IsPlayer() and ent == self.Owner:GetViewModel() and self.ViewModelFlip then
				ang.r = -ang.r -- Fixes mirrored models
			end
		end

		return pos, ang
	end

	function SWEP:CreateModels(tab)
		if not tab then return end

		-- Create the clientside models here because Garry says we can't do it in the render hook
		for k, v in pairs(tab) do
			if v.type == "Model" and v.model and v.model ~= "" and (not IsValid(v.modelEnt) or v.createdModel ~= v.model) and string.find(v.model, ".mdl") and file.Exists(v.model, "GAME") then
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)

				if IsValid(v.modelEnt) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel = v.model
				else
					v.modelEnt = nil
				end
			elseif v.type == "Sprite" and v.sprite and v.sprite ~= "" and (not v.spriteMaterial or v.createdSprite ~= v.sprite) and file.Exists("materials/" .. v.sprite .. ".vmt", "GAME") then
				local name = v.sprite .. "-"

				local params = {
					["$basetexture"] = v.sprite
				}

				-- make sure we create a unique name based on the selected options
				local tocheck = {"nocull", "additive", "vertexalpha", "vertexcolor", "ignorez"}

				for i, j in pairs(tocheck) do
					if v[j] then
						params["$" .. j] = 1
						name = name .. "1"
					else
						name = name .. "0"
					end
				end

				v.createdSprite = v.sprite
				v.spriteMaterial = CreateMaterial(name, "UnlitGeneric", params)
			end
		end
	end

	local allbones
	local hasGarryFixedBoneScalingYet = false

	function SWEP:UpdateBonePositions(vm)
		if self.ViewModelBoneMods then
			if not vm:GetBoneCount() then return end
			-- !! WORKAROUND !! //
			-- We need to check all model names :/
			local loopthrough = self.ViewModelBoneMods

			if not hasGarryFixedBoneScalingYet then
				allbones = {}

				for i = 0, vm:GetBoneCount() do
					local bonename = vm:GetBoneName(i)

					if self.ViewModelBoneMods[bonename] then
						allbones[bonename] = self.ViewModelBoneMods[bonename]
					else
						allbones[bonename] = {
							scale = Vector(1, 1, 1),
							pos = Vector(0, 0, 0),
							angle = Angle(0, 0, 0)
						}
					end
				end

				loopthrough = allbones
			end

			-- !! ----------- !! //
			for k, v in pairs(loopthrough) do
				local bone = vm:LookupBone(k)
				if not bone then continue end
				-- !! WORKAROUND !! //
				local s = Vector(v.scale.x, v.scale.y, v.scale.z)
				local p = Vector(v.pos.x, v.pos.y, v.pos.z)
				local ms = Vector(1, 1, 1)

				if not hasGarryFixedBoneScalingYet then
					local cur = vm:GetBoneParent(bone)

					while cur >= 0 do
						local pscale = loopthrough[vm:GetBoneName(cur)].scale
						ms = ms * pscale
						cur = vm:GetBoneParent(cur)
					end
				end

				s = s * ms

				-- !! ----------- !! //
				if vm:GetManipulateBoneScale(bone) ~= s then
					vm:ManipulateBoneScale(bone, s)
				end

				if vm:GetManipulateBoneAngles(bone) ~= v.angle then
					vm:ManipulateBoneAngles(bone, v.angle)
				end

				if vm:GetManipulateBonePosition(bone) ~= p then
					vm:ManipulateBonePosition(bone, p)
				end
			end
		else
			self:ResetBonePositions(vm)
		end
	end

	function SWEP:ResetBonePositions(vm)
		if not vm:GetBoneCount() then return end

		for i = 0, vm:GetBoneCount() do
			vm:ManipulateBoneScale(i, Vector(1, 1, 1))
			vm:ManipulateBoneAngles(i, Angle(0, 0, 0))
			vm:ManipulateBonePosition(i, Vector(0, 0, 0))
		end
	end
end
