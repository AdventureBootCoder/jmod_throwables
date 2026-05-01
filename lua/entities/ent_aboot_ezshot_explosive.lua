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
	function ENT:PhysicsCollide(data, physobj)
		if data.DeltaTime > 0.2 then
			-- Call base class collision handling first
			local SelfPos = self:GetPos()
			if data.HitEntity == game.GetWorld() then
				local WorldTr = util.TraceLine({
					start = data.HitPos,
					endpos = data.HitPos + data.OurOldVelocity,
					filter = {self}
				})

				local Constrained = self:IsPlayerHolding() or constraint.HasConstraints(self) or not self:GetPhysicsObject():IsMotionEnabled()

				if WorldTr.HitSky and not(Constrained) then
					local NewPos, TravelTime, NewVel = self:FindNextEmptySpace(data.OurOldVelocity)

					if NewPos then
						timer.Simple(0, function()
							if IsValid(self) then
								self:SetNoDraw(true)
								self:SetNotSolid(true)
								self:GetPhysicsObject():EnableMotion(false)
							end
						end)
						timer.Simple(TravelTime, function()
							if IsValid(self) then
								self:SetNoDraw(false)
								self:SetNotSolid(false)
								self:SetPos(NewPos)
								self:SetAngles(NewVel:Angle())
								self:GetPhysicsObject():EnableMotion(true)
								self:GetPhysicsObject():SetVelocity(NewVel)
							end
						end)
					else
						SafeRemoveEntityDelayed(self, 0)
					end

					return
				end

				local OurSpeed = data.OurOldVelocity:Length()
				local Mass = physobj:GetMass()
				local SurfaceData = util.GetSurfaceData(WorldTr.SurfaceProps)
				local Hardness = (SurfaceData and SurfaceData.hardnessFactor) or 1
				local OurNoseDir = -self:GetRight()
				local AngleDiff = (OurNoseDir):Dot(-WorldTr.HitNormal)

				if WorldTr.HitWorld and not(Constrained) and (AngleDiff > .75) and (OurSpeed * Mass > Hardness * 1000000) then
					local Eff = EffectData()
					Eff:SetOrigin(WorldTr.HitPos)
					Eff:SetScale(10)
					Eff:SetNormal(WorldTr.HitNormal)
					util.Effect("eff_jack_sminebury", Eff, true, true)
					
					timer.Simple(0.1, function()
						if IsValid(self) then
							local OldAngle = self:GetAngles()
							local BuryAngle = data.OurOldVelocity:Angle()
							if self.JModPreferredCarryAngles then
								BuryAngle:RotateAroundAxis(BuryAngle:Right(), self.JModPreferredCarryAngles.p)
								BuryAngle:RotateAroundAxis(BuryAngle:Up(), self.JModPreferredCarryAngles.y)
								BuryAngle:RotateAroundAxis(BuryAngle:Forward(), self.JModPreferredCarryAngles.r)
							end
							BuryAngle = LerpAngle(Hardness - .2, BuryAngle, OldAngle)
							self:SetAngles(BuryAngle)
							local StickOffSet = self:GetPos() - self:WorldSpaceCenter()
							self:SetPos(WorldTr.HitPos + StickOffSet + WorldTr.HitNormal * 10)
							self:GetPhysicsObject():EnableMotion(false)
						end
					end)

					if math.random(1, 1000) == 1 then
						-- A small chance for the bomb to not go off.
						return
					end
				end
			end

			-- Explosive collision detonation logic
			local shouldDetonate = data.Speed > (self.CollisionSpeedThreshold or 600)

			if self.CollisionRequiresArmed then
				shouldDetonate = shouldDetonate and self:GetIsArmed()
			end

			if shouldDetonate then
				timer.Simple(self.CollisionDelay or 0, function()
					if IsValid(self) then
						self:Detonate(data)
					end
				end)
			else
				self:EmitSound(self.ImpactSound)
			end
		end
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
		if self:GetNoDraw() then return end
		local Fsh = EffectData()
		Fsh:SetOrigin(self:GetPos())
		Fsh:SetScale(self.TrailEffectScale or 3)
		Fsh:SetNormal(self:GetUp() * -1)
		util.Effect("eff_jack_gmod_fuzeburn_smoky", Fsh, true, true)
		self:EmitSound("snd_jack_sss.wav", self.TrailSoundVolume or 65, math.Rand(90, 110))
	end

	function ENT:Think()
		if self:GetIsArmed() then
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
		if self:GetIsArmed() then return end
		self:SetIsArmed(true)
		if self.FuseTime <= 0.05 then
			self:Detonate()
		else
			self.NextDetonate = CurTime() + (self.FuseTime or 5)
		end
		if self.OnArmed then
			self:OnArmed()
		end
	end

	function ENT:GetIsArmed()
		return self.IsArmed
	end

	function ENT:SetIsArmed(state)
		self.IsArmed = tobool(state)
	end

	function ENT:Initialize()
		-- Call base class initialize
		if self.BaseClass and self.BaseClass.Initialize then
			self.BaseClass.Initialize(self)
		end
		-- Set armed state for explosive shots
		self:SetIsArmed(false)
	end
end

