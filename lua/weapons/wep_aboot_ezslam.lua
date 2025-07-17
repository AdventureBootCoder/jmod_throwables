-- AdventureBoots 2024
AddCSLuaFile()
SWEP.PrintName = "EZ SLAM"
SWEP.Author = "AdventureBoots"
SWEP.Purpose = ""
--JMod.SetWepSelectIcon(SWEP, "entities/ent_jack_gmod_ezmedkit")
SWEP.Spawnable = true
SWEP.UseHands = true
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.InstantPickup = true -- Fort Fights compatibility
SWEP.EZdroppable = true
SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
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
SWEP.ShowWorldModel = true
SWEP.SCKPreDrawViewModel = true
SWEP.VMangleCorrection = Angle(0, 24, 180)
SWEP.WMangleCorrection = Angle(142, 0, -90)

SWEP.VElements = {
	--[[["slam"] = { 
		type = "Model", 
		model = "models/weapons/c_slam.mdl",
		bone = "Slam_base", 
		rel = "", 
		pos = Vector(0.238, 0.3, -0.718),
		angle = Angle(0, 24, 180), 
		size = Vector(1, 1, 1), 
		color = Color(255, 255, 255, 255), 
		surpresslightning = false,
		material = "", 
		skin = 0, 
		bodygroup = {} 
	}--]]
}

SWEP.WElements = {
	--[[["slam"] = { 
		type = "Model", 
		model = "models/weapons/w_slam.mdl",
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
	}--]]
}

local Wepify = CreateConVar("jmod_ezslam_wepify", "0", FCVAR_ARCHIVE, "Wepify the slams")

if SERVER then
	hook.Add("OnPlayerPhysicsPickup", "JMod_EZslamPickup", function(ply, ent)
		if not Wepify:GetBool() then return end
		if not(IsValid(ent:GetParent())) and ent:GetClass() == "ent_jack_gmod_ezslam" and not(ent:GetState() >= JMod.EZ_STATE_ON) then
			local SlamSWEP
			local PickedUp = true
			if ply:HasWeapon("wep_aboot_ezslam") then
				SlamSWEP = ply:GetWeapon("wep_aboot_ezslam")
				-- Store the old SLAM before setting the new one
				local OldSlam = SlamSWEP.SlamEntity
				-- Stow the old SLAM if it exists
				if IsValid(OldSlam) then
					SlamSWEP:StowSlam()
				end
				SlamSWEP:GrabNewSlam(ent)
			else
				-- Give the player a SLAM swep
				SlamSWEP = ents.Create("wep_aboot_ezslam")
				SlamSWEP.SlamEntity = ent
				SlamSWEP:Spawn()
				SlamSWEP:Activate()
				PickedUp = ply:PickupWeapon(SlamSWEP)
			end
			ent:SetOwner(ply)

			timer.Simple(0, function()
				if not PickedUp then 
					if IsValid(SlamSWEP) then SlamSWEP:Remove() end
					return 
				end
				if IsValid(ply) and IsValid(ent) and IsValid(SlamSWEP) then
					ent:ForcePlayerDrop()
					ply:SelectWeapon("wep_aboot_ezslam")
				end
			end)

			return false
		end
	end)
	hook.Add("PlayerSwitchWeapon", "JMod_EZslamDrop", function(ply, oldWeapon, newWeapon)
		if IsValid(newWeapon) and newWeapon:GetClass() == "wep_aboot_ezslam" then return end
		if IsValid(oldWeapon) and oldWeapon:GetClass() == "wep_aboot_ezslam" then
			oldWeapon:StowSlam()
			oldWeapon.EZdropper = ply
			ply:DropNamedWeapon("wep_aboot_ezslam")
		end
	end)
end

function SWEP:GrabNewSlam(entity)
	self.NextIdle = self.NextIdle or 0
	self.FinishThrowTime = 0
	
	-- Set a safe position before parenting to prevent coordinate issues
	entity:SetPos(self:GetPos() + Vector(0, 0, 10))
	entity:SetParent(self)
	entity:SetNoDraw(true)
	entity:SetNotSolid(true)
	
	-- Hide the SLAM after a second
	timer.Simple(.1, function()
		if IsValid(entity) and entity:GetParent() == self then
			entity:SetNoDraw(true)
		end
	end)
	
	self.SlamEntity = entity
end

function SWEP:StowSlam()
	if not IsFirstTimePredicted() then return end
	local Owner = self.Owner
	if not(IsValid(Owner)) and IsValid(self.EZdropper) then Owner = self.EZdropper end
	if not IsValid(Owner) then return end
	
	-- Use the original SLAM entity instead of creating a new one
	local Slam = self.SlamEntity
	if IsValid(Slam) then
		-- Unparent and restore the SLAM
		Slam:SetParent(nil)
		Slam:SetNoDraw(false)
		Slam:SetNotSolid(false)
		
		-- Set position for inventory
		Slam:SetPos(util.QuickTrace(Owner:GetShootPos(), Owner:GetAimVector() * 60, {Owner, Slam}).HitPos)
		
		local Successful = JMod.AddToInventory(Owner, Slam)
		
		if not Successful then
			-- If inventory is full, drop the SLAM
			Slam:SetPos(Owner:GetPos() + Vector(0, 0, 10))
		end
		
		-- Clear the reference
		self.SlamEntity = nil
	end
end

function SWEP:Initialize()
	self:SetHoldType("slam")
	self.NextIdle = 0
	self.FinishThrowTime = 0
	self.WasLookingAtWall = false
	self.IsLookingAtWall = false
	if SERVER then
		if IsValid(self.SlamEntity) then
			self:GrabNewSlam(self.SlamEntity)
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
		vm:SendViewModelMatchingSequence(vm:LookupSequence("throw_draw_ND"))
		self:UpdateNextIdle()
	end

	return true
end

function SWEP:CreateSlam()
	if not IsFirstTimePredicted() then return NULL end
	local Owner = (IsValid(self:GetOwner()) and self:GetOwner()) or self.EZdropper
	
	-- Use the original SLAM entity instead of creating a new one
	local Slam = self.SlamEntity
	if IsValid(Slam) then
		-- Unparent and restore the SLAM
		Slam:SetParent(nil)
		Slam:SetNoDraw(false)
		Slam:SetNotSolid(false)
		
		-- Set a safe position relative to the owner
		local safePos = Owner:GetPos() + Vector(0, 0, 10)
		Slam:SetPos(safePos)
		
		JMod.SetEZowner(Slam, Owner)
		Slam:SetOwner(Owner)
		
		-- Clear the reference since we're using it
		self.SlamEntity = nil
		
		timer.Simple(0.1, function()
			if IsValid(Slam) then
				Slam:SetOwner(nil)
			end
		end)
		
		return Slam
	end
	
	return NULL
end

function SWEP:Throw(hardThrow)
	--if not IsFirstTimePredicted() then return end
	local Owner = self:GetOwner()
	local vm = Owner:GetViewModel()

	if SERVER then
		local Slam = self:CreateSlam()
		if not IsValid(Slam) then return end

		local AimVec, ShootPos = Owner:GetAimVector(), Owner:GetShootPos()
		local ThrowPos = ShootPos + AimVec * 25
		local Bone = Owner:LookupBone("ValveBiped.Bip01_R_Hand")
		if Bone then
			ThrowPos = Owner:GetBonePosition(Bone) + AimVec * 50
		end
		local ThrowTr = util.QuickTrace(ShootPos, (ThrowPos - ShootPos)*.5, {Owner, Slam})

		if ThrowTr.Hit then
			Slam:SetPos(ThrowTr.HitPos + ThrowTr.HitNormal * 5)
		else
			Slam:SetPos(ThrowTr.HitPos)
		end
		Slam:SetAngles(AimVec:Angle())
		
		-- Ensure physics object is properly initialized
		local Phys = Slam:GetPhysicsObject()
		if IsValid(Phys) then
			Phys:Wake()
			Phys:EnableMotion(true)
		end
		
		Slam:Plant(Owner)
		Slam:Arm(Owner)

		local ShootTr = util.QuickTrace(ShootPos, AimVec * 9e9, {Owner, Slam})
		local ThrowDir = (ShootTr.HitPos - ThrowPos):GetNormalized()

		local ThrowTime = vm:SequenceDuration()
		self.FinishThrowTime = CurTime() + ThrowTime

	elseif CLIENT and IsFirstTimePredicted() then
		
	end

	Owner:SetAnimation(PLAYER_ATTACK1)
	self:UpdateNextIdle()
end

function SWEP:PrimaryAttack()
	--if not IsFirstTimePredicted() then return end
	local Owner = self:GetOwner()
	local vm = Owner:GetViewModel()

	vm:SendViewModelMatchingSequence(vm:LookupSequence("tripmine_attach1"))
	self:UpdateNextIdle()
	self:Throw(true)

	self:SetNextPrimaryFire(CurTime() + 1)
	self:SetNextSecondaryFire(CurTime() + 1)
end

function SWEP:SecondaryAttack()
	--if not IsFirstTimePredicted() then return end
	local Owner = self:GetOwner()
	local vm = Owner:GetViewModel()
	
	self:SetNextPrimaryFire(CurTime() + .75)
	self:SetNextSecondaryFire(CurTime() + .75)
end

function SWEP:Reload()
	if (self.FinishThrowTime > 0) or not IsFirstTimePredicted() then return end
	if SERVER then
		self:StowSlam()
		self.Owner:DropWeapon(self)
	end
end

function SWEP:OnDrop()
	if not IsFirstTimePredicted() then return end
	local Ply = self.EZdropper
	if self.Dropped then
		-- Use the original SLAM entity if available
		local Slam = self.SlamEntity
		if IsValid(Slam) then
			-- Unparent and restore the SLAM
			Slam:SetParent(nil)
			Slam:SetNoDraw(false)
			Slam:SetNotSolid(false)
			Slam:SetPos(util.QuickTrace(Ply:GetShootPos(), Ply:GetAimVector() * 50, {Ply, Slam}).HitPos)
		end
	end

	timer.Simple(0, function()
		if IsValid(Ply) and Ply:IsPlayer() then
			local OldSwep = Ply:GetPreviousWeapon()

			if IsValid(OldSwep) and OldSwep:IsWeapon() then
				Ply:SelectWeapon(OldSwep:GetClass())
			end
		end
	end)
	self:Remove()
	self.EZdropper = nil
end

function SWEP:OnRemove()
	self:SCKHolster()

	-- Clean up the parented SLAM entity
	if IsValid(self.SlamEntity) then
		self.SlamEntity:SetParent(nil)
		self.SlamEntity:SetNoDraw(false)
		self.SlamEntity:SetNotSolid(false)
		self.SlamEntity:SetPos(self:GetPos() + Vector(0, 0, 10))
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

function SWEP:Think()
	-- Check if the SLAM entity is still valid, remove weapon if not
	if SERVER and not IsValid(self.SlamEntity) then
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
	local FinishedThrowing = (self.FinishThrowTime > 0) and (Time > self.FinishThrowTime)
	self.IsLookingAtWall = util.QuickTrace(Owner:GetShootPos(), Owner:GetAimVector() * 100, {Owner, self}).Hit

	if not(Throwing) then
		if self.IsLookingAtWall and not(self.WasLookingAtWall) then
			vm:SendViewModelMatchingSequence(vm:LookupSequence("throw_to_tripmine_ND"))
			self:UpdateNextIdle()
			self.WasLookingAtWall = true
		elseif not(self.IsLookingAtWall) and self.WasLookingAtWall then
			vm:SendViewModelMatchingSequence(vm:LookupSequence("tripmine_to_throw"))
			self:UpdateNextIdle()
			self.WasLookingAtWall = false
		end

		if idletime	> 0 and (idletime < Time) then
			if self.IsLookingAtWall then
				vm:SendViewModelMatchingSequence(vm:LookupSequence("tripmine_idle"))
			else
				vm:SendViewModelMatchingSequence(vm:LookupSequence("throw_idle_ND"))
			end
			self:UpdateNextIdle()
		end
	end

	if SERVER and FinishedThrowing and IsFirstTimePredicted() then
		-- Check their inventory for any other slams
		local FoundSlam = false
		if Owner.JModInv then
			for k, tbl in ipairs(Owner.JModInv.items) do
				local Slam = tbl.ent
		
				if IsValid(Slam) and Slam:GetClass() == "ent_jack_gmod_ezslam" then
					--
					Slam = JMod.RemoveFromInventory(Owner, Slam, nil, false, true)
					self:GrabNewSlam(Slam)
					FoundSlam = true

					local vm = Owner:GetViewModel()
					if IsValid(vm) then
						if self.IsLookingAtWall then
							vm:SendViewModelMatchingSequence(vm:LookupSequence("tripmine_draw"))
						else
							vm:SendViewModelMatchingSequence(vm:LookupSequence("throw_draw_ND"))
						end
						self:UpdateNextIdle()
					end

					break
				end
			end
		end

		if not FoundSlam then
			Owner:DropWeapon(self)
		end
	end
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
