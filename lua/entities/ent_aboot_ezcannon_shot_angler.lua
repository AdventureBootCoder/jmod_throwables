--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_aboot_ezcannon_shot"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "glhfggwpezpznore"
ENT.PrintName = "EZ Cannon Shot Angler"
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
ENT.CollisionRequiresArmed = false
ENT.CollisionDelay = 0.1
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

		timer.Simple(0, function()
			if IsValid(self) then
				self:GetPhysicsObject():SetMass(50)
			end
		end)

		self.IsArmed = false
		self.SpinStartTime = CurTime()
		self:SetColor(Color(0, 0, 0, 255))
	end

	function ENT:Detonate()
		-- Do focused shrapnel explosion
		local Attacker = JMod.GetEZowner(self)
		local Pos = self:GetPos()
		
		-- Smaller, more focused explosion
		--JMod.FragSplosion(self, Pos + Vector(0, 0, 10), 500, 50, 150, Attacker, nil, nil, nil, true)
		
		-- Focused building wrecking with high power
		-- This is really hacky, but it works for now
		JMod.WreckBuildings(self, Pos, self.FocusedWreckPower, self.FocusedDamageRadius, true)
		
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

	function ENT:Arm()
		self.IsArmed = true
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
	function ENT:Initialize()
		self.NoDrawTime = CurTime() + .5
	end

	function ENT:Draw()
		self:DrawModel()
	end
end 