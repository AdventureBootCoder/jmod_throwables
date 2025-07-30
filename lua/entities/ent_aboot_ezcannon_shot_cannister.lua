--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_aboot_ezcannon_shot"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "Canister shot that explodes into shrapnel"
ENT.PrintName = "EZ Cannon Shot (Canister)"
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.Model = "models/props_junk/metal_paintcan001a.mdl"
ENT.Material = "phoenix_storms/gear"
ENT.ModelScale = nil
ENT.ImpactSound = "Grenade.ImpactHard"
ENT.CollisionGroup = COLLISION_GROUP_NONE
ENT.JModEZstorable = true

ENT.CollisionSpeedThreshold = 400
ENT.CollisionRequiresArmed = true
ENT.CollisionDelay = 0.1
ENT.FuseTime = 0.05
ENT.TrailEffectScale = 1
ENT.TrailSoundVolume = 35
ENT.ShardCount = 500
ENT.ShardDamage = 80
ENT.ShardSpeed = 2000
ENT.HorizontalSpread = 60
ENT.VerticalSpread = 15

if SERVER then
	-- Custom trail effect for canister
	function ENT:CreateTrailEffect()
		-- Minimal trail effect
		local Fsh = EffectData()
		Fsh:SetOrigin(self:GetPos())
		Fsh:SetScale(1)
		Fsh:SetNormal(self:GetUp() * -1)
		util.Effect("eff_jack_gmod_fuzeburn_smoky", Fsh, true, true)
		
		self:EmitSound("snd_jack_sss.wav", 35, math.Rand(90, 110)) -- Quieter
	end

	function ENT:Detonate(collisionData)
		local Attacker = JMod.GetEZowner(self)
		local Pos = (collisionData and collisionData.HitPos + collisionData.HitNormal * -10) or self:GetPos()
		local Vel = (collisionData and collisionData.OurOldVelocity) or self:GetVelocity()
		local Direction = Vel:GetNormalized()
		local VelocityModifier = Vel:Length() / 2000
		
		JMod.FragSplosion(Attacker, Pos, self.ShardCount, self.ShardDamage, self.ShardSpeed * VelocityModifier, Attacker, Direction, .25, 5, true)
		
		-- Minimal explosion effect
		local Effect = EffectData()
		Effect:SetOrigin(Pos)
		Effect:SetScale(1.5)
		Effect:SetNormal(Vector(0, 0, 1))
		util.Effect("eff_jack_gmod_bpsmoke", Effect, true, true)
		
		-- Canister break sound
		self:EmitSound("physics/metal/metal_canister_impact_hard" .. math.random(1, 3) .. ".wav", 85, math.Rand(90, 110))
		
		SafeRemoveEntityDelayed(self, 0.01)
	end

elseif CLIENT then
	function ENT:Initialize()
		self.NoDrawTime = CurTime() + .5
	end

	function ENT:Draw()
		self:DrawModel()
		
		-- Minimal glow effect when armed
		if self.IsArmed then
			local pos = self:GetPos()
			local size = 15
			local glowmat = Material("sprites/light_glow02_add")
			render.SetMaterial(glowmat)
			render.DrawSprite(pos, size, size, Color(255, 200, 100, 80)) -- Orange glow
		end
	end
end 