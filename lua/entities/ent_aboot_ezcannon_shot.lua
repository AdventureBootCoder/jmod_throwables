--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "glhfggwpezpznore"
ENT.PrintName = "EZ Cannon Shot"
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.Model = "models/props_phx/misc/smallcannonball.mdl"
ENT.Material = "phoenix_storms/gear"
ENT.ModelScale = nil
ENT.ImpactSound = "Grenade.ImpactHard"
ENT.CollisionGroup = COLLISION_GROUP_NONE
ENT.JModEZstorable = true

-- Base class configurable collision behavior
ENT.CollisionSpeedThreshold = 600
ENT.CollisionRequiresArmed = false
ENT.CollisionDelay = 0.1
ENT.FuseTime = 5
ENT.TrailEffectScale = 3
ENT.TrailSoundVolume = 65

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
	end

	function ENT:PhysicsCollide(data, physobj)
		if data.DeltaTime > 0.2 then
			local shouldDetonate = data.Speed > (self.CollisionSpeedThreshold or 600)
			if self.CollisionRequiresArmed then
				shouldDetonate = shouldDetonate and self.IsArmed
			end
			if shouldDetonate then
				timer.Simple(self.CollisionDelay or 0.1, function()
					if IsValid(self) then
						self:Detonate()
					end
				end)
			else
				self:EmitSound(self.ImpactSound)
			end
		end
	end

	function ENT:Detonate()
		-- Do some shrapnel
		local Attacker = JMod.GetEZowner(self)
		local Pos = self:GetPos()
		JMod.Sploom(Attacker, Pos, 50, 100)
		JMod.FragSplosion(self, Pos + Vector(0, 0, 10), 1000, 100, 300, Attacker, nil, nil, nil, true)
		JMod.WreckBuildings(self, Pos, 2.5, 1, true)
		-- Do some effects
		local Effect = EffectData()
		Effect:SetOrigin(Pos)
		Effect:SetScale(3)
		Effect:SetNormal(Vector(0, 0, 1))
		util.Effect("eff_jack_gmod_bpsmoke", Effect, true, true)
		self:Remove()
	end

	function ENT:Use(activator, caller, type, value)
		if activator:IsPlayer() then
			if JMod.IsAltUsing(activator) then
				self:Arm()
			end
			activator:PickupObject(self)
		end
	end

	function ENT:Think()
		if self.IsArmed then
			if self.CreateTrailEffect then
				self:CreateTrailEffect()
			else
				local Fsh = EffectData()
				Fsh:SetOrigin(self:GetPos())
				Fsh:SetScale(self.TrailEffectScale or 3)
				Fsh:SetNormal(self:GetUp() * -1)
				util.Effect("eff_jack_gmod_fuzeburn_smoky", Fsh, true, true)
				self:EmitSound("snd_jack_sss.wav", self.TrailSoundVolume or 65, math.Rand(90, 110))
			end
		end
		if self.NextDetonate and self.NextDetonate < CurTime() then
			self:Detonate()
		end
		self:NextThink(CurTime() + .05)
		return true
	end

	function ENT:Arm()
		self.IsArmed = true
		if self.FuseTime <= 0.05 then
			self:Detonate()
		else
			self.NextDetonate = CurTime() + (self.FuseTime or 5)
		end
	end

elseif CLIENT then
	function ENT:Initialize()
		self.NoDrawTime = CurTime() + .5
	end

	function ENT:Draw()
		self:DrawModel()
	end
end
