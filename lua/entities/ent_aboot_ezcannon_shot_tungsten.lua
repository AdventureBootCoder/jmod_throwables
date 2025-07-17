--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_aboot_ezcannon_shot"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "Tungsten penetration round designed to pierce through props"
ENT.PrintName = "EZ Cannon Shot (Tungsten)"
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.Model = "models/props_phx/misc/smallcannonball.mdl"
ENT.Material = "pheonix_storm/gear"
ENT.ModelScale = nil
ENT.ImpactSound = "Metal_Box.ImpactHard"
ENT.CollisionGroup = COLLISION_GROUP_NONE
ENT.JModEZstorable = true

-- Tungsten round specific properties
ENT.CollisionSpeedThreshold = 800 -- Higher threshold for penetration
ENT.CollisionRequiresArmed = false
ENT.CollisionDelay = 0.05 -- Faster detonation
ENT.FuseTime = 8 -- Longer fuse time
ENT.TrailEffectScale = 0 -- No trail effects
ENT.TrailSoundVolume = 0 -- No trail sound
ENT.PenetrationPower = 3 -- Number of props it can go through
ENT.PenetrationDamage = 25 -- Damage to props when penetrating
ENT.MaxPenetrationDistance = 200 -- Maximum distance for penetration

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
				self:GetPhysicsObject():SetMass(80) -- Heavier for better penetration
			end
		end)

		self.IsArmed = false
		self.Penetrations = 0 -- Track how many props we've gone through
		self.LastPenetrationTime = 0
	end

	function ENT:PhysicsCollide(data, physobj)
		if data.DeltaTime > 0.2 then
			local hitEntity = data.HitEntity
			local hitSpeed = data.Speed
			
			-- Check if we hit a prop that we can penetrate
			if IsValid(hitEntity) and hitEntity:GetClass() == "prop_physics" then
				if self:CanPenetrate(hitEntity, hitSpeed) then
					self:PenetrateProp(hitEntity, data.HitPos, data.HitNormal)
					return -- Don't detonate, continue flying
				end
			end
			
			-- Check for detonation conditions
			local shouldDetonate = hitSpeed > (self.CollisionSpeedThreshold or 800)
			if self.CollisionRequiresArmed then
				shouldDetonate = shouldDetonate and self.IsArmed
			end
			
			if shouldDetonate then
				timer.Simple(self.CollisionDelay or 0.05, function()
					if IsValid(self) then
						self:Detonate()
					end
				end)
			else
				self:EmitSound(self.ImpactSound)
			end
		end
	end

	function ENT:CanPenetrate(prop, speed)
		-- Check if we have penetration power left
		if self.Penetrations >= self.PenetrationPower then
			return false
		end
		
		-- Check if we're going fast enough
		if speed < 500 then
			return false
		end
		
		-- Check if enough time has passed since last penetration
		if CurTime() - self.LastPenetrationTime < 0.1 then
			return false
		end
		
		-- Check prop health and material
		if prop:GetHealth() > 1000 then
			return false -- Too strong to penetrate
		end
		
		return true
	end

	function ENT:PenetrateProp(prop, hitPos, hitNormal)
		-- Increment penetration counter
		self.Penetrations = self.Penetrations + 1
		self.LastPenetrationTime = CurTime()
		
		-- Damage the prop
		local damage = DamageInfo()
		damage:SetDamage(self.PenetrationDamage)
		damage:SetAttacker(JMod.GetEZowner(self) or self)
		damage:SetInflictor(self)
		damage:SetDamageType(DMG_BULLET)
		damage:SetDamagePosition(hitPos)
		prop:TakeDamageInfo(damage)
		
		-- Create penetration effect
		local effect = EffectData()
		effect:SetOrigin(hitPos)
		effect:SetNormal(hitNormal)
		effect:SetScale(1)
		util.Effect("eff_jack_gmod_metalpenetration", effect, true, true)
		
		-- Play penetration sound
		self:EmitSound("physics/metal/metal_sheet_impact_hard" .. math.random(1, 3) .. ".wav", 75, math.Rand(90, 110))
		
		-- Slight velocity reduction
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			local vel = phys:GetVelocity()
			phys:SetVelocity(vel * 0.9) -- Reduce velocity by 10%
		end
		
		-- Create exit effect on the other side
		timer.Simple(0.05, function()
			if IsValid(self) then
				local exitPos = self:GetPos()
				local exitEffect = EffectData()
				exitEffect:SetOrigin(exitPos)
				exitEffect:SetNormal(-hitNormal)
				exitEffect:SetScale(0.8)
				util.Effect("eff_jack_gmod_metalpenetration", exitEffect, true, true)
			end
		end)
	end

	function ENT:Detonate()
		-- Tungsten rounds create focused explosions
		local Attacker = JMod.GetEZowner(self)
		local Pos = self:GetPos()
		
		-- Smaller, more focused explosion
		JMod.Sploom(Attacker, Pos, 30, 80) -- Reduced radius and damage
		
		-- Create tungsten shrapnel effect
		JMod.FragSplosion(self, Pos + Vector(0, 0, 10), 800, 50, 200, Attacker, nil, nil, nil, true)
		
		-- Minimal building damage
		JMod.WreckBuildings(self, Pos, 1.5, 0.5, true)
		
		-- Tungsten-specific explosion effect
		local Effect = EffectData()
		Effect:SetOrigin(Pos)
		Effect:SetScale(2)
		Effect:SetNormal(Vector(0, 0, 1))
		util.Effect("eff_jack_gmod_tungstenexplosion", Effect, true, true)
		
		-- Play tungsten explosion sound
		self:EmitSound("physics/metal/metal_box_break" .. math.random(1, 2) .. ".wav", 85, math.Rand(80, 100))
		
		self:Remove()
	end

	function ENT:Think()
		-- No trail effects for tungsten rounds
		if self.NextDetonate and self.NextDetonate < CurTime() then
			self:Detonate()
		end
		self:NextThink(CurTime() + .1) -- Less frequent thinking
		return true
	end

	function ENT:Arm()
		self.IsArmed = true
		if self.FuseTime <= 0.05 then
			self:Detonate()
		else
			self.NextDetonate = CurTime() + (self.FuseTime or 8)
		end
	end

elseif CLIENT then
	function ENT:Initialize()
		self.NoDrawTime = CurTime() + .5
	end

	function ENT:Draw()
		self:DrawModel()
		
		-- Add a subtle tungsten glow effect
		if self.IsArmed then
			local pos = self:GetPos()
			local glowColor = Color(150, 150, 170, 50) -- Tungsten-like color
			
			render.SetMaterial(Material("sprites/light_glow02_add"))
			render.DrawSprite(pos, 8, 8, glowColor)
		end
	end
end 