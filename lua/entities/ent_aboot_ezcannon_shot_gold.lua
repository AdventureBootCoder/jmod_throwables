--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_aboot_ezcannon_shot"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "Gold shot with royal trail effects"
ENT.PrintName = "EZ Cannon Shot (Gold)"
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.Model = "models/props_phx/misc/smallcannonball.mdl"
ENT.Material = "models/props_mining/ingot_jack_gold"
ENT.ModelScale = nil
ENT.ImpactSound = "Grenade.ImpactHard"
ENT.CollisionGroup = COLLISION_GROUP_NONE
ENT.JModEZstorable = true

-- Gold-specific properties
ENT.CollisionSpeedThreshold = 600
ENT.CollisionRequiresArmed = true
ENT.CollisionDelay = 0.1
ENT.FuseTime = 10
ENT.TrailEffectScale = 5
ENT.TrailSoundVolume = 85
ENT.CreateTrailEffect = true
ENT.Mass = 65 -- Gold is very dense and heavy
ENT.ShellColor = Color(150, 120, 50, 255)
ENT.RoyalTrailDuration = 3
ENT.GoldenSparkleEffect = true
ENT.RoyalFanfare = true

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Armed")
end

if SERVER then
	function ENT:OnArmed()
		self:SetArmed(true)
	end

	function ENT:CreateTrailEffect()
		-- Royal gold trail effect
		local Fsh = EffectData()
		Fsh:SetOrigin(self:GetPos())
		Fsh:SetScale(self.TrailEffectScale or 5)
		Fsh:SetNormal(self:GetUp() * -1)
		--util.Effect("eff_jack_gmod_fuzeburn_smoky", Fsh, true, true)
		
		-- Create golden sparkle effects
		if self.GoldenSparkleEffect and math.random(1, 2) == 1 then
			local SparkleEffect = EffectData()
			SparkleEffect:SetOrigin(self:GetPos() + VectorRand() * 15)
			SparkleEffect:SetScale(1)
			SparkleEffect:SetNormal(Vector(0, 0, 1))
			util.Effect("eff_aboot_throwables_gold_sparkle", SparkleEffect, true, true)
		end
		
		-- Royal trail sound
		self:EmitSound("snd_jack_sss.wav", self.TrailSoundVolume or 85, math.Rand(90, 110))
		
		-- Add royal fanfare sounds
		if self.RoyalFanfare and math.random(1, 8) == 1 then
			self:EmitSound("ambient/machines/steam_release_1.wav", 70, math.Rand(90, 110))
			self:EmitSound("ambient/energy/zap" .. math.random(1, 3) .. ".wav", 60, math.Rand(100, 120))
		end
	end

	function ENT:Detonate(collisionData)
		local Attacker = JMod.GetEZowner(self)
		local Pos = (collisionData and collisionData.HitPos + collisionData.HitNormal * -10) or self:GetPos()
		
		-- Royal explosion
		JMod.Sploom(Attacker, Pos, 50, 100)
		JMod.FragSplosion(self, Pos + Vector(0, 0, 10), 1200, 80, 350, Attacker, nil, nil, nil, true)
		JMod.WreckBuildings(self, Pos, 2.5, 1.2, true)
		
		-- Create golden sparkle explosion
		for i = 1, 30 do
			timer.Simple(i * 0.03, function()
				if not IsValid(self) then return end
				
				local SparkleEffect = EffectData()
				SparkleEffect:SetOrigin(Pos + VectorRand() * 150)
				SparkleEffect:SetScale(1.5)
				SparkleEffect:SetNormal(Vector(0, 0, 1))
				util.Effect("eff_aboot_throwables_gold_sparkle", SparkleEffect, true, true)
			end)
		end
		
		-- Royal explosion effect
		local Effect = EffectData()
		Effect:SetOrigin(Pos)
		Effect:SetScale(4)
		Effect:SetNormal(Vector(0, 0, 1))
		util.Effect("eff_jack_gmod_bpsmoke", Effect, true, true)
		
		-- Royal explosion sound
		self:EmitSound("physics/metal/metal_box_break" .. math.random(1, 2) .. ".wav", 100, math.Rand(90, 110))
		self:EmitSound("ambient/machines/steam_release_1.wav", 90, math.Rand(80, 100))
		self:EmitSound("ambient/energy/zap" .. math.random(1, 3) .. ".wav", 80, math.Rand(90, 110))
		
		-- Royal fanfare for nearby players
		for _, ply in pairs(player.GetAll()) do
			local dist = ply:GetPos():Distance(Pos)
			if dist < 800 then
				sound.Play("ambient/machines/steam_release_1.wav", ply:GetPos(), 60, math.Rand(90, 110))
			end
		end
		
		self:Remove()
	end

elseif CLIENT then
	function ENT:Initialize()
		self.NoDrawTime = CurTime() + .5
		self.TrailParticles = {}
	end

	local SparkleColor = Color(255, 255, 255, 100)
	local GoldGlowColor = Color(255, 215, 0, 50)
	local GoldenColor = Color(255, 215, 0, 30)
	local CrownColor = Color(255, 255, 255, 20)
	local DustColor = Color(255, 215, 0, 50)
	function ENT:Draw()
		self:DrawModel()
		
		-- Add gold royal glow effect
		if self:GetArmed() then
			local pos = self:GetPos()
			
			render.SetMaterial(Material("sprites/light_glow02_add"))
			render.DrawSprite(pos, 20, 20, GoldGlowColor)
			
			-- Add golden shimmer effect
			local time = CurTime() * 3
			local shimmer = math.sin(time) * 0.5 + 0.5
			
			render.DrawSprite(pos, 15 * shimmer, 15 * shimmer, GoldenColor)
			
			-- Add royal crown effect
			local crownTime = CurTime() * 2
			local crownPulse = math.sin(crownTime) * 0.3 + 0.7
			
			render.DrawSprite(pos + Vector(0, 0, 8), 8 * crownPulse, 8 * crownPulse, CrownColor)
			
			-- Add golden sparkle particles
			if math.random(1, 8) == 1 then
				local sparklePos = pos + VectorRand() * 20
				render.DrawSprite(sparklePos, 4, 4, SparkleColor)
			end
			
			-- Add golden dust trail
			for i = 1, 5 do
				local dustPos = pos + VectorRand() * 10
				render.DrawSprite(dustPos, 2, 2, DustColor)
			end
		end
	end
end 