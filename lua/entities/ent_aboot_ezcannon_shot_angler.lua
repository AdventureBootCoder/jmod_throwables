--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_aboot_ezcannon_shot"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "glhfggwpezpznore"
ENT.PrintName = "Shot Angler"
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.Model = "models/aboot/cannon/chain_shot.mdl"
ENT.Material = "phoenix_storms/gear"
ENT.ModelScale = nil
ENT.ImpactSound = "Grenade.ImpactHard"
ENT.CollisionGroup = COLLISION_GROUP_NONE
ENT.JModEZstorable = true

-- Base class configurable collision behavior
ENT.CollisionSpeedThreshold = 1000
ENT.CollisionRequiresArmed = true
ENT.CollisionDelay = 0
ENT.FuseTime = 10

-- Angler-specific properties
ENT.SpinSpeed = 1000
ENT.SpinAxis = Vector(0, 0, 1) -- Spin around X axis
ENT.FocusedDamageRadius = .01 -- Smaller radius for focused damage
ENT.FocusedWreckPower = 40 -- Higher wreck power for focused destruction

if SERVER then
	function ENT:Initialize()
		self:SetModel(self.Model)
		self:SetMaterial(self.Material)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:DrawShadow(true)
		self:GetPhysicsObject():EnableDrag(false)
		self:SetUseType(SIMPLE_USE)

		timer.Simple(0, function()
			if IsValid(self) then
				self:GetPhysicsObject():SetMass(50)
			end
		end)

		self.IsArmed = false
		self:SetColor(Color(0, 0, 0, 255))
	end

	function ENT:PhysicsCollide(data, physobj)
		if data.DeltaTime > 0.2 then
			if data.Speed > (self.CollisionSpeedThreshold or 600) then
				local DeWeldMult = data.Speed / 1000
				local EntToDeconstruct = data.HitEntity
				timer.Simple(0, function()
					if IsValid(EntToDeconstruct) then
						local Phys = EntToDeconstruct:GetPhysicsObject()
						if IsValid(Phys) and Phys:GetMass() < (5000 * DeWeldMult) then
							constraint.RemoveAll(EntToDeconstruct)
							Phys:EnableMotion(true)
						end
					end
				end)
				
				self.NextDetonate = CurTime() + self.FuseTime
			end
			if data.Speed > 10 then
				self:EmitSound(self.ImpactSound)
			end
		end
	end

	function ENT:Detonate()
		local Pos = self:GetPos()
		
		-- Do some effects
		local Effect = EffectData()
		Effect:SetOrigin(Pos)
		Effect:SetScale(2)
		Effect:SetNormal(Vector(0, 0, 1))
		util.Effect("eff_jack_gmod_bpsmoke", Effect, true, true)
		-- Play breaking sound
		sound.Play("physics/metal/metal_box_impact_bullet1.wav", Pos, 100, math.random(90, 110))
		self:Remove()
	end

	function ENT:OnArmed()
		local Phys = self:GetPhysicsObject()
		if IsValid(Phys) then
			Phys:AddAngleVelocity(self.SpinAxis * self.SpinSpeed)
		end
	end

	function ENT:Think()
		if self.IsArmed and self.NextDetonate and self.NextDetonate < CurTime() then
			self:Detonate()
		end
		self:NextThink(CurTime() + 1)
		return true
	end

elseif CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end
end 