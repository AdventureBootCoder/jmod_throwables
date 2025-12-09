--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_aboot_ezcannon_shot"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "Uranium shot that creates radioactive fallout"
ENT.PrintName = "Shot Uranium"
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.Model = "models/props_phx/misc/smallcannonball.mdl"
ENT.Material = "models/shiny"
ENT.ModelScale = nil
ENT.ImpactSound = "Grenade.ImpactHard"
ENT.CollisionGroup = COLLISION_GROUP_NONE
ENT.JModEZstorable = true

-- Uranium-specific properties
ENT.CollisionSpeedThreshold = 700
ENT.CollisionRequiresArmed = true
ENT.CollisionDelay = 0.1
ENT.FuseTime = 12
ENT.TrailEffectScale = 1.5
ENT.TrailSoundVolume = 45
ENT.CreateTrailEffect = true
ENT.Mass = 75 -- Uranium is very dense and heavy
ENT.FalloutRadius = 400
ENT.FalloutDuration = 30
ENT.FalloutDamage = 5
ENT.FalloutParticleCount = 8
ENT.ShellColor = Color(38, 173, 38)

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Armed")
end

if SERVER then
	function ENT:OnArmed()
		self:SetArmed(true)
	end

	function ENT:CreateTrailEffect()
		-- Uranium radioactive trail effect
		local Fsh = EffectData()
		Fsh:SetOrigin(self:GetPos())
		Fsh:SetScale(self.TrailEffectScale or 1.5)
		Fsh:SetNormal(self:GetUp() * -1)
		util.Effect("eff_jack_gmod_fuzeburn_smoky", Fsh, true, true)
		
		-- Add radioactive particle trail
		if math.random(1, 4) == 1 then
			local FalloutParticle = ents.Create("ent_jack_gmod_ezfalloutparticle")
			if IsValid(FalloutParticle) then
				FalloutParticle:SetPos(self:GetPos() + VectorRand() * 20)
				FalloutParticle.EZowner = self.EZowner
				FalloutParticle.MaxLife = 8
				FalloutParticle.AffectRange = 100
				FalloutParticle:Spawn()
				FalloutParticle:Activate()
			end
		end
		
		self:EmitSound("snd_jack_sss.wav", self.TrailSoundVolume or 45, math.Rand(90, 110))
	end

	function ENT:CreateFalloutZone(pos)
		-- Create multiple fallout particles in a zone
		for i = 1, self.FalloutParticleCount do
			timer.Simple(i * 0.5, function()
				if not IsValid(self) then return end
				
				local FalloutParticle = ents.Create("ent_jack_gmod_ezfalloutparticle")
				if IsValid(FalloutParticle) then
					local offset = VectorRand() * self.FalloutRadius
					FalloutParticle:SetPos(pos + offset)
					FalloutParticle.EZowner = self.EZowner
					FalloutParticle.MaxLife = self.FalloutDuration
					FalloutParticle.AffectRange = 200
					FalloutParticle:Spawn()
					FalloutParticle:Activate()
				end
			end)
		end
		
		-- Create a persistent radioactive zone
		local RadioactiveZone = ents.Create("ent_jack_gmod_ezradioactivezone")
		if IsValid(RadioactiveZone) then
			RadioactiveZone:SetPos(pos)
			RadioactiveZone.EZowner = self.EZowner
			RadioactiveZone.Damage = self.FalloutDamage
			RadioactiveZone.Radius = self.FalloutRadius
			RadioactiveZone.Duration = self.FalloutDuration
			RadioactiveZone:Spawn()
			RadioactiveZone:Activate()
		end
	end

	function ENT:Detonate(collisionData)
		local Attacker = JMod.GetEZowner(self)
		local Pos = (collisionData and collisionData.HitPos + collisionData.HitNormal * -10) or self:GetPos()
		
		-- Nuclear explosion effect
		JMod.Sploom(Attacker, Pos, 60, 120)
		JMod.FragSplosion(self, Pos + Vector(0, 0, 10), 1200, 80, 400, Attacker, nil, nil, nil, true)
		JMod.WreckBuildings(self, Pos, 3, 1.5, true)
		
		-- Create fallout zone
		self:CreateFalloutZone(Pos)
		
		-- Nuclear explosion sound
		self:EmitSound("snd_jack_c4splodeclose.ogg", 120, math.Rand(90, 110))
		self:EmitSound("physics/metal/metal_box_break" .. math.random(1, 2) .. ".wav", 100, math.Rand(80, 100))
		
		-- Screen shake for nearby players
		for _, ply in pairs(player.GetAll()) do
			local dist = ply:GetPos():Distance(Pos)
			if dist < 1000 then
				local intensity = math.Clamp(1 - (dist / 1000), 0, 1)
				util.ScreenShake(ply:GetPos(), intensity * 10, intensity * 5, 2, 500)
			end
		end
		
		self:Remove()
	end

elseif CLIENT then
	function ENT:Initialize()
		self.NoDrawTime = CurTime() + .5
	end

	function ENT:Draw()
		self:DrawModel()
		
		-- Add uranium radioactive glow effect
		if self:GetArmed() then
			local pos = self:GetPos()
			
			render.SetMaterial(Material("sprites/light_glow02_add"))
			render.DrawSprite(pos, 15, 15, self.ShellColor)
			
			-- Add pulsing effect
			local pulse = math.sin(CurTime() * 3) * 0.5 + 0.5
			render.DrawSprite(pos, 8 * pulse, 8 * pulse, Color(50, 255, 50, 20 * pulse))
		end
	end
end 