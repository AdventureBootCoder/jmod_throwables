--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "Solid cannon shot"
ENT.PrintName = "Shot Solid"
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.Model = "models/props_phx/misc/smallcannonball.mdl"
ENT.Material = "phoenix_storms/gear"
ENT.ModelScale = nil
ENT.ImpactSound = "Grenade.ImpactHard"
ENT.CollisionGroup = COLLISION_GROUP_NONE
ENT.JModEZstorable = true
ENT.Mass = 45

-- Base class configurable collision behavior
ENT.CollisionSpeedThreshold = 1000
ENT.CollisionRequiresArmed = true
ENT.CollisionDelay = 0.1
ENT.CollisionDirection = nil
ENT.FuseTime = .5
ENT.ImpactDetonation = false
ENT.TrailEffectScale = 3
ENT.TrailSoundVolume = 100
ENT.ShellColor = nil

--[[ 
Arm: Prepares an explosive to be fired, or initiates a timer to detonate.
Launch: Provides a boost to movement, or initiates a timer to detonate.
Detonate: Triggers the explosive to detonate.
--]]

function ENT:SpawnFunction(ply, tr, ClassName)
	local SpawnPos = tr.HitPos + tr.HitNormal * 10
	local ent = ents.Create(ClassName)
	ent:SetPos(SpawnPos)
	ent:Spawn()
	ent:Activate()
	return ent
end

if SERVER then
	function ENT:Initialize()
		self:SetModel(self.Model)
		if self.Material then
			self:SetMaterial(self.Material)
		end
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
				self:GetPhysicsObject():Wake()
			end
		end)

		self:SetIsArmed(false)
	end

	function ENT:PhysicsCollide(data, physobj)
		if data.DeltaTime > 0.2 then
			local SelfPos = self:GetPos()
			if data.HitEntity == game.GetWorld() then
				local WorldTr = util.TraceLine({
					start = data.HitPos,
					endpos = data.HitPos + data.OurOldVelocity,
					filter = {self}
				})--]]
				constraint.RemoveConstraints(self, "NoCollide")
				local Constrained = self:IsPlayerHolding() or constraint.HasConstraints(self) or not self:GetPhysicsObject():IsMotionEnabled()

				if WorldTr.HitSky and not(Constrained) then
					local NewPos, TravelTime, NewVel = JMod.FindSkyboxEntryPoint(SelfPos, data.OurOldVelocity, self, self.Mass, 1, 60, 0.25, {self})

					if NewPos then
						JMod.StartEZBombTrail(SelfPos, data.OurOldVelocity, NewPos, TravelTime)
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
				end--]]

				--print(data.Speed * physobj:GetMass())
				local OurSpeed = data.OurOldVelocity:Length()
				local Mass = physobj:GetMass()
				local SurfaceData = util.GetSurfaceData(WorldTr.SurfaceProps)
				local Hardness = (SurfaceData and SurfaceData.hardnessFactor) or 1
				local OurNoseDir = -self:GetRight()
				local AngleDiff = (OurNoseDir):Dot(-WorldTr.HitNormal)
				--print("Pen Force Diff:", (OurSpeed * Mass) - (Hardness * 1000000))

				if WorldTr.HitWorld and not(Constrained) and (AngleDiff > .75) and (OurSpeed * Mass > Hardness * 1000000) then
					DetTime = math.Rand(.5, 2)

					local Eff = EffectData()
					Eff:SetOrigin(WorldTr.HitPos)
					Eff:SetScale(5)
					Eff:SetNormal(WorldTr.HitNormal)
					util.Effect("eff_jack_sminebury", Eff, true, true)
					--
					timer.Simple(0.1, function()
						if IsValid(self) then
							local OldAngle = self:GetAngles()
							local BuryAngle = data.OurOldVelocity:Angle()
							BuryAngle:RotateAroundAxis(BuryAngle:Right(), self.JModPreferredCarryAngles.p)
							BuryAngle:RotateAroundAxis(BuryAngle:Up(), self.JModPreferredCarryAngles.y)
							BuryAngle:RotateAroundAxis(BuryAngle:Forward(), self.JModPreferredCarryAngles.r)
							BuryAngle = LerpAngle(Hardness - .2, BuryAngle, OldAngle)
							self:SetAngles(BuryAngle)
							local StickOffSet = self:GetPos() - self:WorldSpaceCenter()
							self:SetPos(WorldTr.HitPos + StickOffSet + WorldTr.HitNormal * 10)
							--
							self:GetPhysicsObject():EnableMotion(false)
						end
					end)
				end
			end

			local shouldDetonate = data.Speed > self.CollisionSpeedThreshold
			if self.ImpactDetonation then
				shouldDetonate = shouldDetonate and (CurTime() > self.DetonateTime)
			end

			if self.CollisionRequiresArmed then
				shouldDetonate = shouldDetonate and self:GetIsArmed()
			end

			if self.CollisionDirection then
				local Pos = self:GetPos()
				local DetonateDir = (Pos - self:LocalToWorld(self.CollisionDirection)):GetNormalized()
				local Diff = (Pos - data.HitPos)
				local Product = DetonateDir:Dot(Diff) / Diff:Length()
				if Product < 0.60 then
					shouldDetonate = false
				end
			end

			if shouldDetonate then
				timer.Simple(self.CollisionDelay or 0, function()
					if IsValid(self) then
						self:Detonate(data)
					end
				end)
			elseif data.Speed > 500 then
				self:EmitSound(self.ImpactSound)
				self:ImpactEffect(false, data.Speed / 1000)
			end
		end
	end

	function ENT:ImpactEffect(detonate, force)
		local SelfPos = self:LocalToWorld(self:OBBCenter())
		local Up = Vector(0, 0, 1)
		local EffectType = 1
		local Traec = util.QuickTrace(self:GetPos(), Vector(0, 0, -5), self.Entity)
		Up = Traec.HitNormal

		if Traec.Hit then
			if (Traec.MatType == MAT_DIRT) or (Traec.MatType == MAT_SAND) then
				EffectType = 1
			elseif (Traec.MatType == MAT_CONCRETE) or (Traec.MatType == MAT_TILE) then
				EffectType = 2
			elseif (Traec.MatType == MAT_METAL) or (Traec.MatType == MAT_GRATE) then
				EffectType = 3
			elseif Traec.MatType == MAT_WOOD then
				EffectType = 4
			end
		else
			EffectType = 5
		end

		local plooie = EffectData()
		plooie:SetOrigin(Traec.HitPos)
		plooie:SetScale(math.max(force or 1, 10))
		plooie:SetRadius(EffectType)
		plooie:SetNormal(Up)
		util.Effect("eff_jack_sminebury", plooie, true, true)
		if detonate then
			util.ScreenShake(SelfPos, 99999, 99999, 1, 500)
		end
	end

	function ENT:Detonate()
		-- Do some wrecking
		local Pos = self:GetPos()
		JMod.WreckBuildings(self, Pos, 1, 1, true)
		-- Do some effects
		self:ImpactEffect(true, 10)
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
		--[[local Fsh = EffectData()
		Fsh:SetOrigin(self:GetPos())
		Fsh:SetScale(self.TrailEffectScale or 3)
		Fsh:SetNormal(self:GetUp() * -1)
		util.Effect("eff_jack_gmod_fuzeburn_smoky", Fsh, true, true)
		self:EmitSound("snd_jack_sss.wav", self.TrailSoundVolume or 65, math.Rand(90, 110))--]]
	end

	function ENT:Think()
		if self:GetIsArmed() then
			if self.CreateTrailEffect then
				self:CreateTrailEffect()
			end
		end
		if self.ImpactDetonation and self.DetonateTime and self.DetonateTime < CurTime() then
			self:Detonate()
		end
		self:NextThink(CurTime() + .06)
		return true
	end

	function ENT:Arm()
		if self:GetIsArmed() then return end
		self:SetIsArmed(true)
		if self.FuseTime <= 0.05 and not self.ImpactDetonation then
			self:Detonate()
		else
			self.DetonateTime = CurTime() + (self.FuseTime or 5)
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

	function ENT:Launch(ply, shouldForce)
		--
	end

	function ENT:OnTakeDamage(dmginfo)
		self:TakePhysicsDamage(dmginfo)
		if JMod.LinCh(dmginfo:GetDamage(), 50, 300) then
			timer.Simple(0, function()
				if IsValid(self) then
					self:Detonate()
				end
			end)
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
