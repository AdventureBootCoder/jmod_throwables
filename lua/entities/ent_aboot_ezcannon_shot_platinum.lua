--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_aboot_ezcannon_shot"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "Platinum shot with ultimate luxury effects"
ENT.PrintName = "Shot Platinum"
ENT.NoSitAllowed = true
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.Model = "models/props_phx/misc/smallcannonball.mdl"
ENT.Material = "models/props_mining/ingot_jack_platinum"
ENT.ModelScale = nil
ENT.ImpactSound = "Grenade.ImpactHard"
ENT.CollisionGroup = COLLISION_GROUP_NONE
ENT.JModEZstorable = true

-- Platinum-specific properties
ENT.CollisionSpeedThreshold = 550
ENT.CollisionRequiresArmed = true
ENT.CollisionDelay = 0.1
ENT.FuseTime = 10
ENT.TrailEffectScale = 6
ENT.TrailSoundVolume = 95
ENT.CreateTrailEffect = true
ENT.Mass = 70 -- Platinum is very dense and heavy
ENT.UltimateTrailDuration = 4
ENT.PlatinumSparkleEffect = true
ENT.UltimateFanfare = true
ENT.PlatinumAura = true

if SERVER then
	function ENT:CreateTrailEffect()
		-- Ultimate platinum trail effect
		local Fsh = EffectData()
		Fsh:SetOrigin(self:GetPos())
		Fsh:SetScale(self.TrailEffectScale or 6)
		Fsh:SetNormal(self:GetUp() * -1)
		--util.Effect("eff_jack_gmod_fuzeburn_smoky", Fsh, true, true)
		
		-- Create platinum sparkle effects
		if self.PlatinumSparkleEffect and math.random(1, 2) == 1 then
			local SparkleEffect = EffectData()
			SparkleEffect:SetOrigin(self:GetPos() + VectorRand() * 20)
			SparkleEffect:SetScale(1.5)
			SparkleEffect:SetNormal(Vector(0, 0, 1))
			util.Effect("eff_aboot_throwables_platinum_sparkle", SparkleEffect, true, true)
		end
		
		-- Ultimate trail sound
		self:EmitSound("snd_jack_sss.wav", self.TrailSoundVolume or 95, math.Rand(90, 110))
		
		-- Add ultimate fanfare sounds
		if self.UltimateFanfare and math.random(1, 6) == 1 then
			self:EmitSound("ambient/machines/steam_release_1.wav", 80, math.Rand(90, 110))
			self:EmitSound("ambient/energy/zap" .. math.random(1, 3) .. ".wav", 70, math.Rand(100, 120))
			self:EmitSound("ambient/machines/steam_release_2.wav", 75, math.Rand(90, 110))
		end
	end

	function ENT:Detonate(collisionData)
		local Attacker = JMod.GetEZowner(self)
		local Pos = (collisionData and collisionData.HitPos + collisionData.HitNormal * -10) or self:GetPos()
		
		-- Ultimate explosion
		JMod.Sploom(Attacker, Pos, 60, 120)
		JMod.FragSplosion(self, Pos + Vector(0, 0, 10), 1500, 100, 400, Attacker, nil, nil, nil, true)
		JMod.WreckBuildings(self, Pos, 3, 1.5, true)
		
		-- Create platinum sparkle explosion
		for i = 1, 40 do
			timer.Simple(i * 0.02, function()
				if not IsValid(self) then return end
				
				local SparkleEffect = EffectData()
				SparkleEffect:SetOrigin(Pos + VectorRand() * 200)
				SparkleEffect:SetScale(2)
				SparkleEffect:SetNormal(Vector(0, 0, 1))
				util.Effect("eff_aboot_throwables_platinum_sparkle", SparkleEffect, true, true)
			end)
		end
		
		-- Ultimate explosion effect
		local Effect = EffectData()
		Effect:SetOrigin(Pos)
		Effect:SetScale(5)
		Effect:SetNormal(Vector(0, 0, 1))
		util.Effect("eff_jack_gmod_bpsmoke", Effect, true, true)
		
		-- Ultimate explosion sound
		self:EmitSound("physics/metal/metal_box_break" .. math.random(1, 2) .. ".wav", 110, math.Rand(90, 110))
		self:EmitSound("ambient/machines/steam_release_1.wav", 100, math.Rand(80, 100))
		self:EmitSound("ambient/energy/zap" .. math.random(1, 3) .. ".wav", 90, math.Rand(90, 110))
		self:EmitSound("ambient/machines/steam_release_2.wav", 95, math.Rand(90, 110))
		
		-- Ultimate fanfare for nearby players
		for _, ply in pairs(player.GetAll()) do
			local dist = ply:GetPos():Distance(Pos)
			if dist < 1000 then
				sound.Play("ambient/machines/steam_release_1.wav", ply:GetPos(), 70, math.Rand(90, 110))
				sound.Play("ambient/energy/zap" .. math.random(1, 3) .. ".wav", ply:GetPos(), 60, math.Rand(100, 120))
			end
		end
		
		-- Screen shake for nearby players
		for _, ply in pairs(player.GetAll()) do
			local dist = ply:GetPos():Distance(Pos)
			if dist < 1200 then
				local intensity = math.Clamp(1 - (dist / 1200), 0, 1)
				util.ScreenShake(ply:GetPos(), intensity * 8, intensity * 4, 3, 600)
			end
		end
		
		self:Remove()
	end

elseif CLIENT then
	function ENT:Initialize()
		self.NoDrawTime = CurTime() + .5
		self.TrailParticles = {}
	end

	function ENT:Draw()
		self:DrawModel()
		
		-- Add platinum ultimate glow effect
		if self.IsArmed then
			local pos = self:GetPos()
			local glowColor = Color(255, 255, 255, 60) -- Platinum glow
			
			render.SetMaterial(Material("sprites/light_glow02_add"))
			render.DrawSprite(pos, 25, 25, glowColor)
			
			-- Add platinum shimmer effect
			local time = CurTime() * 4
			local shimmer = math.sin(time) * 0.5 + 0.5
			local platinumColor = Color(255, 255, 255, 40 * shimmer)
			
			render.DrawSprite(pos, 18 * shimmer, 18 * shimmer, platinumColor)
			
			-- Add ultimate crown effect
			local crownTime = CurTime() * 2.5
			local crownPulse = math.sin(crownTime) * 0.4 + 0.6
			local crownColor = Color(255, 255, 255, 30 * crownPulse)
			
			render.DrawSprite(pos + Vector(0, 0, 10), 12 * crownPulse, 12 * crownPulse, crownColor)
			
			-- Add platinum sparkle particles
			if math.random(1, 6) == 1 then
				local sparklePos = pos + VectorRand() * 25
				render.DrawSprite(sparklePos, 5, 5, Color(255, 255, 255, 200))
			end
			
			-- Add platinum dust trail
			for i = 1, 8 do
				local dustPos = pos + VectorRand() * 15
				render.DrawSprite(dustPos, 3, 3, Color(255, 255, 255, 60))
			end
			
			-- Add platinum aura rings
			local auraTime = CurTime() * 1.5
			for i = 1, 3 do
				local auraPulse = math.sin(auraTime + i) * 0.3 + 0.7
				local auraColor = Color(255, 255, 255, 15 * auraPulse)
				local auraSize = (10 + i * 5) * auraPulse
				
				render.DrawSprite(pos + Vector(0, 0, i * 3), auraSize, auraSize, auraColor)
			end
			
			-- Add rainbow platinum effect
			local rainbowTime = CurTime() * 1.2
			local rainbowPulse = math.sin(rainbowTime) * 0.5 + 0.5
			local rainbowColor = HSVToColor(rainbowTime * 30 % 360, 0.2, 0.9)
			rainbowColor.a = 25 * rainbowPulse
			
			render.DrawSprite(pos, 14 * rainbowPulse, 14 * rainbowPulse, rainbowColor)
		end
	end
end 