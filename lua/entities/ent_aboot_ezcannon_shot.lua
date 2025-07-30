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
ENT.Mass = 50 -- Default steel mass

-- Base class configurable collision behavior
ENT.CollisionSpeedThreshold = 600
ENT.CollisionRequiresArmed = true
ENT.CollisionDelay = 0.1
ENT.FuseTime = 10
ENT.TrailEffectScale = 3
ENT.TrailSoundVolume = 65
ENT.ShellColor = nil

if SERVER then
	function ENT:Initialize()
		self:SetModel(self.Model)
		self:SetMaterial(self.Material)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:DrawShadow(true)
		if self.ShellColor then
			self:SetColor(self.ShellColor)
		end
		self:SetUseType(SIMPLE_USE)

		timer.Simple(0, function()
			if IsValid(self) then
				self:GetPhysicsObject():SetMass(self.Mass or 50)
				self:GetPhysicsObject():EnableDrag(false)
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
				timer.Simple(self.CollisionDelay or 0, function()
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
		JMod.WreckBuildings(self, Pos, 1, 1, true)
		-- Do some effects
		local Effect = EffectData()
		Effect:SetOrigin(Pos)
		Effect:SetScale(3)
		Effect:SetNormal(Vector(0, 0, 1))
		util.Effect("eff_jack_gmod_bpsmoke", Effect, true, true)
		self:Remove()
	end

	function ENT:Use(activator, caller, type, value)
		if JMod.IsAltUsing(activator) then
			self:Arm()
		end
		if activator:IsPlayer() then
			if self:IsPlayerHolding() then
				self:ForcePlayerDrop()
			else
				activator:PickupObject(self)
			end
		end
	end

	function ENT:CreateTrailEffect()
		local Fsh = EffectData()
		Fsh:SetOrigin(self:GetPos())
		Fsh:SetScale(self.TrailEffectScale or 3)
		Fsh:SetNormal(self:GetUp() * -1)
		util.Effect("eff_jack_gmod_fuzeburn_smoky", Fsh, true, true)
		self:EmitSound("snd_jack_sss.wav", self.TrailSoundVolume or 65, math.Rand(90, 110))
	end

	function ENT:Think()
		if self.IsArmed then
			if self.CreateTrailEffect then
				self:CreateTrailEffect()
			end
		end
		if self.NextDetonate and self.NextDetonate < CurTime() then
			self:Detonate()
		end
		self:NextThink(CurTime() + .05)
		return true
	end

	function ENT:Arm()
		if self.IsArmed then return end
		self.IsArmed = true
		if self.FuseTime <= 0.05 then
			self:Detonate()
		else
			self.NextDetonate = CurTime() + (self.FuseTime or 5)
		end
		if self.OnArmed then
			self:OnArmed()
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
