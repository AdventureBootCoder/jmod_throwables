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
ENT.Model = "models/munitions/dart_100mm.mdl"
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
ENT.PenetrationDamage = 100 -- Increased damage to props when penetrating
ENT.MaxPenetrationDistance = 200 -- Maximum distance for penetration
ENT.Mass = 20 -- Heavier for better penetration
ENT.DensityMultiplier = 0.8 -- How much density affects penetration
local BaseClass = baseclass.Get("ent_aboot_ezcannon_shot")

if SERVER then
	function ENT:PhysicsCollide(data, physobj)
		if data.DeltaTime > 0.2 and self.IsArmed and data.Speed > 100 then
			local hitEntity = data.HitEntity
			local hitSpeed = data.Speed
			local hitPos = data.HitPos
			local hitNormal = data.HitNormal
			local oldVelocity = data.OurOldVelocity
			local flightNormal = data.OurOldVelocity:GetNormalized()
			
			-- Check if we hit an entity that we can penetrate
			if IsValid(hitEntity) and not hitEntity:IsWorld() then
				-- Try to penetrate using JMod.RicPenBullet principles
				local penetrationResult = self:AttemptPenetration(hitPos, oldVelocity, hitEntity)
				
				if penetrationResult.success then
					print("TUNGSTEN: Penetration SUCCESS - " .. hitEntity:GetClass())
					
					-- Create entry shrapnel explosion
					--self:CreateShrapnelExplosion(hitPos, -flightNormal, oldVelocity, hitSpeed)
					
					-- Defer teleportation to avoid collision callback issues
					timer.Simple(0, function()
						if IsValid(self) then
							self:SetPos(penetrationResult.exitPos)
							
							-- Apply velocity reduction based on penetration distance and material
							local phys = self:GetPhysicsObject()
							if IsValid(phys) then
								local velocityReduction = penetrationResult.velocityReduction
								local newVelocity = oldVelocity * velocityReduction
								phys:SetVelocity(newVelocity)
							end
							
							-- Deal damage to all penetrated entities
							self:DealPenetrationDamage(penetrationResult.penetratedEntities, oldVelocity, penetrationResult.velocityReduction, hitSpeed)

							-- Create exit shrapnel explosion
							self:CreateShrapnelExplosion(penetrationResult.exitPos, flightNormal, oldVelocity * penetrationResult.velocityReduction, hitSpeed)
		
							-- Create penetration effects
							self:CreatePenetrationEffects(hitPos, penetrationResult.exitPos, hitNormal)
							
						end
					end)
					return
				else
					timer.Simple(0, function()
						-- Deal damage to all penetrated entities
						if not IsValid(self) then return end
						self:DealPenetrationDamage(penetrationResult.penetratedEntities, oldVelocity, penetrationResult.velocityReduction, hitSpeed)
						self:Detonate()
					end)
					print("TUNGSTEN: Penetration FAILED - " .. hitEntity:GetClass() .. " (Speed: " .. math.Round(hitSpeed) .. ")")
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

	function ENT:AttemptPenetration(hitPos, velocity, hitEntity)
		local result = {
			success = false,
			exitPos = nil,
			velocityReduction = 1.0,
			penetratedEntities = {} -- Track entities and their detection count
		}
		
		local velocityDir = velocity:GetNormalized()
		local speed = velocity:Length()
		
		-- Use the same penetration logic as JMod.RicPenBullet
		local initialTrace = util.TraceLine({
			start = hitPos - velocityDir * 10,
			endpos = hitPos + velocityDir * speed,
			filter = {self}
		})
		
		if not initialTrace.Hit or initialTrace.HitSky then 
			return result
		end
		
		local AVec = initialTrace.Normal
		local IPos = initialTrace.HitPos
		local TNorm = initialTrace.HitNormal
		local SMul = self:GetSurfaceHardness(initialTrace.MatType)
		
		if not util.IsInWorld(IPos) then 
			return result
		end
		
		-- Calculate approach angle (same as JMod.RicPenBullet)
		local ApproachAngle = -math.deg(math.asin(TNorm:Dot(AVec)))
		local MaxRicAngle = 60 * SMul
		
		-- Check if we can penetrate (approach angle > max ricochet angle)
		if ApproachAngle > (MaxRicAngle * 1.05) then
			-- Calculate maximum penetration distance based on kinetic energy
			local mass = self.Mass or 80
			local kineticEnergy = 0.5 * mass * (speed * speed)
			local maxDist = (kineticEnergy / (SMul * 2000)) * 0.06 -- More restrictive penetration calculation
			maxDist = math.min(maxDist, self.MaxPenetrationDistance or 200)
			
			-- Find exit point using the same method as JMod.RicPenBullet
			local SearchPos = IPos
			local SearchDist = 5
			local Penetrated = false
			
			while (not Penetrated) and (SearchDist < maxDist) do
				SearchPos = IPos + AVec * SearchDist
				local PeneTrace = util.QuickTrace(SearchPos, -AVec * SearchDist)
				
				-- Track entities encountered during penetration
				if PeneTrace.Hit and IsValid(PeneTrace.Entity) and not PeneTrace.Entity:IsWorld() then
					local entIndex = PeneTrace.Entity:EntIndex()
					if not result.penetratedEntities[entIndex] then
						result.penetratedEntities[entIndex] = {
							entity = PeneTrace.Entity,
							count = 0
						}
					end
					result.penetratedEntities[entIndex].count = result.penetratedEntities[entIndex].count + 1
					if not result.penetratedEntities[entIndex].penetrationPos then
						result.penetratedEntities[entIndex].penetrationPos = PeneTrace.HitPos
					end
				end
				
				if (not PeneTrace.StartSolid) and PeneTrace.Hit then
					Penetrated = true
				else
					SearchDist = SearchDist + 5
				end
			end
			
			if Penetrated then
				result.success = true
				result.exitPos = SearchPos + AVec * 10 -- Small offset to avoid collision
				
				-- Calculate velocity reduction based on penetration distance and material
				local ThroughFrac = (1 - SearchDist / maxDist)
				local velocityReduction = ThroughFrac * (0.7 + (SMul * 0.3)) -- Material affects velocity loss
				result.velocityReduction = math.max(0.1, velocityReduction)
				
				-- Visual debug
				debugoverlay.Line(hitPos, result.exitPos, 10, Color(255, 0, 0), true)
				debugoverlay.Cross(hitPos, 5, 10, Color(255, 0, 0), true)
				debugoverlay.Cross(result.exitPos, 5, 10, Color(0, 255, 0), true)
				debugoverlay.Text(hitPos + Vector(0, 0, 10), "ENTRY", 10)
				debugoverlay.Text(result.exitPos + Vector(0, 0, 10), "EXIT", 10)
				
				return result
			end
		end
		
		return result
	end
	
	-- Use the same surface hardness table as JMod.RicPenBullet
	local SurfaceHardness = {
		[MAT_METAL] = .95,
		[MAT_COMPUTER] = .95,
		[MAT_VENT] = .95,
		[MAT_GRATE] = .95,
		[MAT_FLESH] = .5,
		[MAT_ALIENFLESH] = .3,
		[MAT_SAND] = .1,
		[MAT_DIRT] = .3,
		[MAT_GRASS] = .2,
		[74] = .1,
		[85] = .2,
		[MAT_WOOD] = .5,
		[MAT_FOLIAGE] = .5,
		[MAT_CONCRETE] = .9,
		[MAT_TILE] = .8,
		[MAT_SLOSH] = .05,
		[MAT_PLASTIC] = .3,
		[MAT_GLASS] = .6
	}

	function ENT:GetSurfaceHardness(matType)

		return SurfaceHardness[matType] or .99
	end
	
	function ENT:CreatePenetrationEffects(entryPos, exitPos, hitNormal)
		-- Create entry penetration effect
		local effect = EffectData()
		effect:SetOrigin(entryPos)
		effect:SetNormal(hitNormal)
		effect:SetScale(1)
		util.Effect("eff_jack_gmod_metalpenetration", effect, true, true)
		
		-- Play penetration sound
		self:EmitSound("physics/metal/metal_sheet_impact_hard" .. math.random(1, 3) .. ".wav", 75, math.Rand(90, 110))
		
		-- Create exit effect on the other side
		if exitPos then
			local exitEffect = EffectData()
			exitEffect:SetOrigin(exitPos)
			exitEffect:SetNormal(-hitNormal)
			exitEffect:SetScale(0.8)
			util.Effect("eff_jack_gmod_metalpenetration", exitEffect, true, true)
		end
	end

	function ENT:CreateShrapnelExplosion(pos, normal, velocity, speed)
		-- Create a small shrapnel explosion at entry/exit points
		local Attacker = JMod.GetEZowner(self)
		if not speed then
			speed = velocity:Length()
		end
		
		-- Scale shrapnel based on velocity
		local shrapnelCount = math.Clamp(speed, 5, 20)
		local shrapnelDamage = math.Clamp(speed / 10, 10, 50)
		local shrapnelRange = math.Clamp(speed / 20, 50, 150)
		
		-- Create shrapnel effect
		JMod.FragSplosion(JMod.GetEZowner(self), pos, shrapnelCount, shrapnelDamage, shrapnelRange, Attacker, normal, .4, 2, true)
		
		-- Create small explosion effect
		local Effect = EffectData()
		Effect:SetOrigin(pos)
		Effect:SetScale(0.5)
		Effect:SetNormal(normal)
		util.Effect("eff_jack_gmod_tungstenexplosion", Effect, true, true)
		
		-- Play shrapnel sound
		self:EmitSound("physics/metal/metal_sheet_impact_hard" .. math.random(1, 3) .. ".wav", 60, math.Rand(90, 110))
	end
	
	function ENT:DealPenetrationDamage(penetratedEntities, originalVelocity, velocityReduction)
		-- Deal damage to all entities that were penetrated
		local Attacker = JMod.GetEZowner(self) or self
		local originalSpeed = originalVelocity:Length()
		
		for entIndex, data in pairs(penetratedEntities) do
			if IsValid(data.entity) then
				-- Calculate damage based on detection count and velocity loss
				local baseDamage = originalSpeed * 0.1 * data.count
				local finalDamage = baseDamage * velocityReduction
				
				-- Ensure minimum damage
				finalDamage = math.max(finalDamage, 1)
				
				-- Create damage info
				local damage = DamageInfo()
				damage:SetDamage(finalDamage)
				damage:SetAttacker(Attacker)
				damage:SetInflictor(self)
				damage:SetDamageType(DMG_SNIPER)
				damage:SetDamageForce(originalVelocity * 10)
				damage:SetDamagePosition(data.penetrationPos or data.entity:GetPos())
				
				-- Apply damage
				data.entity:TakeDamageInfo(damage)
				
				print("TUNGSTEN: Damaged " .. data.entity:GetClass() .. " - Count: " .. data.count .. " Damage: " .. math.Round(finalDamage, 1))
			end
		end
	end

	function ENT:Detonate(hitPos, hitNormal)
		local Pos = hitPos or self:GetPos()
		local Normal = hitNormal or Vector(0, 0, 1)
		-- Tungsten-specific explosion effect
		local Effect = EffectData()
		Effect:SetOrigin(Pos)
		Effect:SetScale(2)
		Effect:SetNormal(Normal)
		util.Effect("eff_jack_gmod_tungstenexplosion", Effect, true, true)
		
		-- Play tungsten explosion sound
		self:EmitSound("physics/metal/metal_box_break" .. math.random(1, 2) .. ".wav", 85, math.Rand(80, 100))
		
		self.IsArmed = false
		timer.Simple(0.1, function()
			if IsValid(self) then
				self:Remove()
			end
		end)
	end

	function ENT:Think()
		-- No trail effects for tungsten rounds
		if self.NextDetonate and self.NextDetonate < CurTime() then
			self:Detonate()
		end
		self:NextThink(CurTime() + 1) -- Less frequent thinking
		return true
	end

	function ENT:OnArmed()
		util.SpriteTrail(self, 0, Color(255, 255, 255, 255), false, 10, 0, .25, 10, "trails/smoke")
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