--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_aboot_ezcannon_shot"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "Silver shot with luxury trail effects"
ENT.PrintName = "Shot Silver"
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.Model = "models/props_phx/misc/smallcannonball.mdl"
ENT.Material = "models/props_mining/ingot_jack_silver"
ENT.ModelScale = nil
ENT.ImpactSound = "Grenade.ImpactHard"
ENT.CollisionGroup = COLLISION_GROUP_NONE
ENT.JModEZstorable = true

-- Silver-specific properties
ENT.CollisionSpeedThreshold = 650
ENT.CollisionRequiresArmed = true
ENT.CollisionDelay = 0.1
ENT.FuseTime = 10
ENT.TrailEffectScale = 4
ENT.TrailSoundVolume = 75
ENT.CreateTrailEffect = true
ENT.Mass = 60 -- Silver is heavier than steel
ENT.LuxuryTrailDuration = 2
ENT.SparkleEffect = true
ENT.ShellColor = Color(150, 150, 150, 255)

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Armed")
end

if SERVER then
	function ENT:OnArmed()
		self:SetArmed(true)
	end

	function ENT:CreateTrailEffect()
		-- Luxury silver trail effect
		local Fsh = EffectData()
		Fsh:SetOrigin(self:GetPos())
		Fsh:SetScale(self.TrailEffectScale or 4)
		Fsh:SetNormal(self:GetUp() * -1)
		--util.Effect("eff_jack_gmod_fuzeburn_smoky", Fsh, true, true)
		
		-- Create sparkle effects
		if self.SparkleEffect and math.random(1, 2) == 1 then
			local SparkleEffect = EffectData()
			SparkleEffect:SetOrigin(self:GetPos() + VectorRand() * 10)
			SparkleEffect:SetScale(0.5)
			SparkleEffect:SetNormal(Vector(0, 0, 1))
			util.Effect("eff_aboot_throwables_silver_sparkle", SparkleEffect, true, true)
		end
		
		-- Elegant trail sound
		self:EmitSound("snd_jack_sss.wav", self.TrailSoundVolume or 75, math.Rand(90, 110))
		
		-- Add occasional luxury sound effects
		if math.random(1, 5) == 1 then
			self:EmitSound("ambient/machines/steam_release_1.wav", 60, math.Rand(90, 110))
		end
	end

	function ENT:Detonate(collisionData)
		local Attacker = JMod.GetEZowner(self)
		local Pos = (collisionData and collisionData.HitPos + collisionData.HitNormal * -10) or self:GetPos()
		
		-- Elegant explosion
		JMod.Sploom(Attacker, Pos, 45, 80)
		JMod.FragSplosion(self, Pos + Vector(0, 0, 10), 1000, 60, 300, Attacker, nil, nil, nil, true)
		JMod.WreckBuildings(self, Pos, 2, 1, true)
		
		-- Create silver sparkle explosion
		for i = 1, 20 do
			timer.Simple(i * 0.05, function()
				if not IsValid(self) then return end
				
				local SparkleEffect = EffectData()
				SparkleEffect:SetOrigin(Pos + VectorRand() * 100)
				SparkleEffect:SetScale(1)
				SparkleEffect:SetNormal(Vector(0, 0, 1))
				util.Effect("eff_aboot_throwables_silver_sparkle", SparkleEffect, true, true)
			end)
		end
		
		-- Luxury explosion effect
		local Effect = EffectData()
		Effect:SetOrigin(Pos)
		Effect:SetScale(3)
		Effect:SetNormal(Vector(0, 0, 1))
		util.Effect("eff_jack_gmod_bpsmoke", Effect, true, true)
		
		-- Elegant explosion sound
		self:EmitSound("physics/metal/metal_box_break" .. math.random(1, 2) .. ".wav", 90, math.Rand(90, 110))
		self:EmitSound("ambient/machines/steam_release_1.wav", 80, math.Rand(80, 100))
		
		self:Remove()
	end

elseif CLIENT then
	function ENT:Initialize()
		self.NoDrawTime = CurTime() + .5
		self.TrailParticles = {}
	end

	local SparkleColor = Color(255, 255, 255, 100)
	local SilverGlowColor = Color(200, 200, 200, 40)
	function ENT:Draw()
		self:DrawModel()
		
		-- Add silver luxury glow effect
		if self:GetArmed() then
			local pos = self:GetPos()
			
			render.SetMaterial(Material("sprites/light_glow02_add"))
			render.DrawSprite(pos, 18, 18, SilverGlowColor)
			
			-- Add rainbow shimmer effect
			local time = CurTime() * 2
			local shimmer = math.sin(time) * 0.5 + 0.5
			local rainbowColor = HSVToColor(time * 50 % 360, 0.3, 0.8)
			rainbowColor.a = 20 * shimmer
			
			render.DrawSprite(pos, 12 * shimmer, 12 * shimmer, rainbowColor)
			
			-- Add sparkle particles
			if math.random(1, 10) == 1 then
				local sparklePos = pos + VectorRand() * 15
				render.DrawSprite(sparklePos, 3, 3, SparkleColor)
			end
		end
	end
end 