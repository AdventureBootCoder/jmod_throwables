--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_aboot_ezshot"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "Explosive cannon shot"
ENT.PrintName = "Shot Explosive"
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.AdminSpawnable = false

ENT.CollisionSpeedThreshold = 600
ENT.CollisionRequiresArmed = true
ENT.CollisionDelay = 0.1
ENT.FuseTime = 15
ENT.TrailEffectScale = 3
ENT.TrailSoundVolume = 100

if SERVER then
	function ENT:Initialize()
		-- Call base class initialize
		if self.BaseClass and self.BaseClass.Initialize then
			self.BaseClass.Initialize(self)
		end
		-- Set armed state for explosive shots
		self:SetIsArmed(false)
	end

	function ENT:Detonate(collisionData)
		-- Do some shrapnel
		local Attacker = JMod.GetEZowner(self)
		local Pos = (collisionData and collisionData.HitPos + collisionData.HitNormal * -10) or self:GetPos()
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

	function ENT:CreateTrailEffect()
		if self:GetNoDraw() then return end
		local Fsh = EffectData()
		Fsh:SetOrigin(self:GetPos())
		Fsh:SetScale(self.TrailEffectScale or 3)
		Fsh:SetNormal(self:GetUp() * -1)
		util.Effect("eff_jack_gmod_fuzeburn_smoky", Fsh, true, true)
		self:EmitSound("snd_jack_sss.wav", self.TrailSoundVolume or 65, math.Rand(90, 110))
	end
end

