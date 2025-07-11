--AdventureBoots 2025
AddCSLuaFile()
if SERVER then
	util.AddNetworkString("JMod_EZCannon_Command")
end
ENT.Type = "anim"
ENT.Author = "Jackarunda, AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "EZ method for loading anything"
ENT.PrintName = "EZ Cannon"
ENT.Spawnable = true
ENT.AdminSpawnable = false
---
ENT.JModPreferredCarryAngles = Angle(90, 0, 0)
ENT.EZcolorable = false
ENT.EZlowFragPlease = true
ENT.EZbuoyancy = .3
ENT.JModHighlyFlammableFunc = "LaunchProjectile"
---
ENT.EZconsumes = {
	JMod.EZ_RESOURCE_TYPES.BASICPARTS,
	JMod.EZ_RESOURCE_TYPES.PROPELLANT,
	JMod.EZ_RESOURCE_TYPES.STEEL,
	JMod.EZ_RESOURCE_TYPES.LEAD,
	JMod.EZ_RESOURCE_TYPES.TITANIUM,
	JMod.EZ_RESOURCE_TYPES.COPPER,
	JMod.EZ_RESOURCE_TYPES.ANTIMATTER
}

ENT.DefaultPropellantPerShot = 20

ENT.ProjectileSpecs = {
	["prop_physics"] = {
		UsePropModel = true
	},
	["ent_jack_gmod_ezincendiarybomb"] = {
		ArmDelay = .1
	},
	["ent_jack_gmod_ezthermobaricbomb"] = {
		ArmDelay = .1
	},
	["ent_jack_gmod_ezclusterbomb"] = {
		ArmDelay = .1
	},
	["ent_jack_gmod_ezsmallbomb"] = {
		ArmDelay = 1
	},
	--["ent_jack_gmod_ezstickynade"] = {
	--	ArmDelay = .1
	--},
	["ent_jack_gmod_ezhebomb"] = {
		ArmDelay = .2
	},
	["ent_jack_gmod_ezfumigator"] = {
		ArmDelay = .5,
		ArmMethod = "Fume",
		SpecialCorrection = true
	},
	["ent_jack_gmod_eznuke_small"] = {	
		ArmDelay = 1
	},
	["ent_aboot_ezcannon_shot"] = {
		ArmDelay = .1
	},
	["ent_aboot_ezcannon_shot_plasma"] = {
		ArmDelay = .1,
		ForceMult = 2
	},
	["ent_aboot_ezcannon_shot_cannister"] = {
		ArmDelay = .05
	},
	["ent_jack_gmod_ezcriticalityweapon"] = {
		ArmDelay = 3,
		ArmMethod = "Detonate",
		ForceMult = 2
	},
	["ent_jack_gmod_ezpowderkeg"] = {
		ArmDelay = .2,
		ArmMethod = "Detonate"
	}
}

if SERVER then
	function ENT:SpawnFunction(ply, tr)
		local SpawnPos = tr.HitPos + tr.HitNormal * 40
		local ent = ents.Create(self.ClassName)
		ent:SetAngles(self.JModPreferredCarryAngles or Angle(0, 0, 0) + Angle(0, ply:GetAngles().y, 0))
		ent:SetPos(SpawnPos)
		JMod.SetEZowner(ent, ply, true)
		ent:Spawn()
		ent:Activate()
		--local effectdata=EffectData()
		--effectdata:SetEntity(ent)
		--util.Effect("propspawn",effectdata)

		return ent
	end

	function ENT:Initialize()
		self:SetModel("models/props_phx/misc/smallcannon.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:DrawShadow(true)
		self:SetUseType(SIMPLE_USE)
		---
		local phys = self:GetPhysicsObject()
		timer.Simple(.01, function()
			if IsValid(phys) then
				phys:SetMass(300)
				phys:Wake()
				phys:EnableDrag(false)
				phys:SetBuoyancyRatio(self.EZbuoyancy)
			end
		end)
		self.LoadedProjectileType = self.LoadedProjectileType
		self.Propellant = self.Propellant or 0
		self.MaxPropellant = 100
		self.CurrentPropellantPerShot = self.CurrentPropellantPerShot or self.DefaultPropellantPerShot
		self.NextRefillTime = 0
		---
		if istable(WireLib) then
			self.Inputs = WireLib.CreateInputs(self, {"Launch [NORMAL]", "Unload [NORMAL]", "PropellantPerShot [NORMAL]"}, {"Fires the loaded Projectile", "Unloads Projectile", "Sets the amount of propellant used per shot (1-100)"})
			self.Outputs = WireLib.CreateOutputs(self, {"LoadedProjectile [STRING]", "IsLoaded [NORMAL]", "Propellant [NORMAL]", "PropModel [STRING]", "CurrentPropellantPerShot [NORMAL]"}, {"The currently loaded Projectile type", "Whether a projectile is loaded (1) or not (0)", "Current propellant amount", "Model name of loaded prop (if applicable)", "Current propellant amount per shot"})
		end
		
		-- Sync initial state to clients
		timer.Simple(0.1, function()
			if IsValid(self) then
				self:SyncStateToClients()
			end
		end)
	end

	function ENT:UpdateWireOutputs()
		if istable(WireLib) then
			WireLib.TriggerOutput(self, "IsLoaded", self.LoadedProjectileType and 1 or 0)
			WireLib.TriggerOutput(self, "LoadedProjectile", self.LoadedProjectileType or "")
			WireLib.TriggerOutput(self, "Propellant", self.Propellant or 0)
			WireLib.TriggerOutput(self, "PropModel", self.PropModel or "")
			WireLib.TriggerOutput(self, "CurrentPropellantPerShot", self.CurrentPropellantPerShot or 0)
		end
	end
	
	function ENT:SyncStateToClients()
		net.Start("JMod_EZCannon_Command")
		net.WriteEntity(self)
		net.WriteString("state_sync")
		net.WriteString(self.LoadedProjectileType or "")
		net.WriteInt(self.Propellant or 0, 8)
		net.WriteInt(self.CurrentPropellantPerShot or 20, 8)
		net.Broadcast()
	end
	
	function ENT:TriggerInput(iname, value)
		if iname == "Launch" and value > 0 then
			self:LaunchProjectile(false)
		elseif iname == "Unload" and value > 0 then
			self:UnloadProjectile()
		elseif iname == "PropellantPerShot" then
			self.CurrentPropellantPerShot = math.Clamp(value, 1, 100)
			self:UpdateWireOutputs()
		end
	end

	-- Function to check if a prop_physics entity is suitable for loading
	function ENT:IsPropSuitable(prop)
		if not IsValid(prop) or prop:GetClass() ~= "prop_physics" then return false end
		
		-- Get the model bounds
		local mins, maxs = prop:GetCollisionBounds()
		local size = maxs - mins
		
		-- Check if any two sides are greater than 8 units
		local sides = {size.x, size.y, size.z}
		table.sort(sides, function(a, b) return a > b end)
		
		-- If the two largest sides are both > 8, reject the prop
		if sides[1] > 8 and sides[2] > 8 and sides[3] > 20 then
			return false
		end
		
		return true
	end

	-- Function to calculate optimal launch angle for a prop
	function ENT:CalculatePropLaunchAngle(prop)
		if not IsValid(prop) then return 1, 0 end
		
		local mins, maxs = prop:GetCollisionBounds()
		local size = maxs - mins
		
		-- Find the longest dimension
		local longestAxis = 1 -- 1 = X, 2 = Y, 3 = Z
		local longestSize = size.x
		
		if size.y > longestSize then
			longestSize = size.y
			longestAxis = 2
		end
		
		if size.z > longestSize then
			longestSize = size.z
			longestAxis = 3
		end
		
		-- Return the axis index and size
		return longestAxis, longestSize
	end

	--]]
	function ENT:PhysicsCollide(data, physobj)
		if not IsValid(self) then return end
		local ent = data.HitEntity

		if data.DeltaTime > 0.2 then
			if data.Speed > 50 then
				self:EmitSound("Metal_Box.ImpactHard")
			end

			if self.Destroyed then return end

			-- Check for supported projectile types
			if self.ProjectileSpecs[ent:GetClass()] then
				self:LoadProjectile(ent)
			end

			if (ent:GetClass() == "ent_jack_gmod_ezrocketmotor") and not self.HasRocketMotor and not ent.StuckTo then
				self.HasRocketMotor = true
				self:EmitSound("snd_jack_metallicload.ogg", 65, 90)
				SafeRemoveEntity(ent)
			end

			if data.Speed > 5000 and not(ent:IsPlayerHolding()) then
				self:Destroy()
			end
		end
	end

	function ENT:TryLoadResource(typ, amt)
		if(amt <= 0)then return 0 end
		local Time = CurTime()
		if (self.NextRefillTime > Time) or (typ == "generic") then return 0 end
		
		if not self.LoadedProjectileType then
			-- Check for antimatter loading and set plasma projectile
			if typ == JMod.EZ_RESOURCE_TYPES.ANTIMATTER and amt >= 10 then
				self:SetProjectileType("ent_aboot_ezcannon_shot_plasma")
				return 10
			elseif typ == JMod.EZ_RESOURCE_TYPES.LEAD and amt >= 20 then
				self:SetProjectileType("ent_aboot_ezcannon_shot_cannister")
				return 20
			end
		end
		
		if typ == JMod.EZ_RESOURCE_TYPES.PROPELLANT then
			local SpaceLeft = self.MaxPropellant - self.Propellant
			local ToLoad = math.min(amt, SpaceLeft)
			
			if ToLoad > 0 then
				self.Propellant = self.Propellant + ToLoad
				self.NextRefillTime = CurTime() + 0.1
				self:EmitSound("snd_jack_metallicload.ogg", 65, 90)
				self:UpdateWireOutputs()
				self:SyncStateToClients()
				return ToLoad
			end
		end
		
		return 0
	end

	function ENT:SetProjectileType(projectileType)
		self.LoadedProjectileType = projectileType
		self.EZlaunchableWeaponLoadTime = CurTime()
		self:EmitSound("snd_jack_metallicload.ogg", 65, 90)
		self:UpdateWireOutputs()
		self:SyncStateToClients()
	end

	function ENT:LoadProjectile(Projectile)
		if not IsValid(Projectile) then return end
		
		-- Only load if player is holding it or force load is enabled
		if not (Projectile:IsPlayerHolding() or JMod.Config.ResourceEconomy.ForceLoadAllResources) then return end
		
		-- Check if the entity is constrained
		if constraint.HasConstraints(Projectile) then return end
		
		if Projectile.AlreadyLoaded then return end
		
		-- Check if the projectile type is supported
		local Specs = self.ProjectileSpecs[Projectile:GetClass()]
		if not Specs then return end
		
		-- For prop_physics, check if it's suitable
		if Projectile:GetClass() == "prop_physics" and not self:IsPropSuitable(Projectile) then return end
		
		-- Check if cannon is already loaded
		if self.LoadedProjectileType then return end

		Projectile.AlreadyLoaded = true
		
		-- Store the model name for prop_physics
		if Projectile:GetClass() == "prop_physics" then
			self.PropModel = Projectile:GetModel()
		end

		SafeRemoveEntityDelayed(Projectile, 0.1)

		self:SetProjectileType(Projectile:GetClass())
	end

	function ENT:UnloadProjectile()
		if not self.LoadedProjectileType then return end
		self:LaunchProjectile(true)
	end

	function ENT:LaunchProjectile(unload, ply)
		local Time = CurTime()
		if self.NextLaunchTime and (self.NextLaunchTime > Time) then return end
		self.NextLaunchTime = Time + .1
		
		-- Check if we have a projectile loaded
		if not self.LoadedProjectileType then return end
		
		ply = ply or JMod.GetEZowner(self)
		local Up, Ford, Right = self:GetUp(), self:GetForward(), self:GetRight()
		local SelfPos, LaunchAngle = self:GetPos(), self:GetAngles()
		local Specs = self.ProjectileSpecs[self.LoadedProjectileType]

		-- Create the projectile entity
		local LaunchedProjectile = ents.Create(self.LoadedProjectileType)
		LaunchedProjectile:SetPos(SelfPos)
		-- Special handling for prop_physics
		if Specs.UsePropModel then
			LaunchedProjectile:SetModel(self.PropModel)
			LaunchedProjectile:Spawn()
			LaunchedProjectile:Activate()
			
			-- Calculate optimal launch angle for the prop
			local longestAxis, longestSize = self:CalculatePropLaunchAngle(LaunchedProjectile)
			
			-- Align the longest axis with the launch direction (Up vector)
			if longestAxis == 1 then -- X axis is longest
				LaunchAngle:RotateAroundAxis(LaunchAngle:Right(), 90)
			elseif longestAxis == 2 then -- Y axis is longest
				LaunchAngle:RotateAroundAxis(LaunchAngle:Forward(), 90)
			elseif longestAxis == 3 then -- Z axis is longest
				LaunchAngle:RotateAroundAxis(LaunchAngle:Up(), 90)
			end
		else
			-- Handle regular projectiles
			if Specs.SpecialCorrection then
				--
			else
				LaunchAngle:RotateAroundAxis(LaunchAngle:Right(), 90)
			end

			if Specs.Angles then
				--
			elseif LaunchedProjectile.JModPreferredCarryAngles then
				LaunchAngle:RotateAroundAxis(LaunchAngle:Right(), -LaunchedProjectile.JModPreferredCarryAngles.p)
				LaunchAngle:RotateAroundAxis(LaunchAngle:Up(), LaunchedProjectile.JModPreferredCarryAngles.y)
				LaunchAngle:RotateAroundAxis(LaunchAngle:Forward(), LaunchedProjectile.JModPreferredCarryAngles.r)
			elseif LaunchedProjectile.EZrackAngles then
				--
			end
			
			-- Spawn regular projectiles
			LaunchedProjectile:Spawn()
			LaunchedProjectile:Activate()
		end
		JMod.SetEZowner(LaunchedProjectile, ply)
		LaunchedProjectile:SetAngles(LaunchAngle)
		
		-- Calculate the offset needed to align physics centers
		local CannonCenter = self:LocalToWorld(self:OBBCenter())
		local ProjectileCenter = LaunchedProjectile:LocalToWorld(LaunchedProjectile:OBBCenter())
		local CenterOffset = CannonCenter - ProjectileCenter
		
		-- Apply the center alignment offset plus the launch offset
		local LaunchPos = SelfPos + CenterOffset + Up * 30
		
		-- Apply special offset if specified
		if Specs.Offset then
			LaunchPos = LaunchPos + Specs.Offset
		end
		
		-- Set the final position
		LaunchedProjectile:SetPos(LaunchPos)
		local Nocollider = constraint.NoCollide(self, LaunchedProjectile, 0, 0, true)
	
		timer.Simple(0, function()
			if not IsValid(LaunchedProjectile) or not IsValid(self) then return end
			LaunchedProjectile:GetPhysicsObject():SetVelocity(self:GetPhysicsObject():GetVelocity())

			if unload then
				if LaunchedProjectile.SetState then
					LaunchedProjectile:SetState(JMod.EZ_STATE_OFF)
				end
			else
				LaunchedProjectile.DropOwner = self
				
				if Specs.UsePropModel then
					-- Have a chance to ignite it
					LaunchedProjectile:Ignite(10, 0)
				else
					if Specs.ArmMethod and LaunchedProjectile[Specs.ArmMethod] then
						timer.Simple(Specs.ArmDelay or 0, function()
							if IsValid(LaunchedProjectile) then
								LaunchedProjectile[Specs.ArmMethod](LaunchedProjectile)
							end
						end)
					elseif LaunchedProjectile.Launch then
						LaunchedProjectile:SetState(JMod.EZ_STATE_ON)
						LaunchedProjectile:Launch(ply)
					elseif LaunchedProjectile.Arm then
						timer.Simple(Specs.ArmDelay or 0, function()
							if IsValid(LaunchedProjectile) then
								LaunchedProjectile:Arm(ply)
							end
						end)
					elseif LaunchedProjectile.SetState then
						LaunchedProjectile:SetState(JMod.EZ_STATE_ON)
					end
				end
				
				-- Check if we have enough propellant
				if self.Propellant < self.CurrentPropellantPerShot then 
					self:EmitSound("snd_jack_metallicclick.ogg", 65, 100)

					return 
				end
				local LaunchPhys = LaunchedProjectile:GetPhysicsObject()
				local LaunchForce = Up * 250000 * (Specs.ForceMult or 1) * (self.CurrentPropellantPerShot / self.DefaultPropellantPerShot)

				-- Get server's max velocity setting and calculate overflow force
				local MaxVelocity = GetConVar("sv_maxvelocity"):GetFloat()
				local MaxForce = MaxVelocity * LaunchPhys:GetMass()
				local LaunchForceLength = LaunchForce:Length()
				local OverflowForce = LaunchForceLength - MaxForce
				if OverflowForce > 0 then
					local OverflowBursts = math.min(math.ceil(OverflowForce / (MaxForce * 0.2)), 20)

					timer.Simple(0.1, function()
						timer.Create("OverflowForce"..LaunchedProjectile:EntIndex(), 0.1, OverflowBursts, function()
							OverflowBursts = OverflowBursts - 1
							if IsValid(LaunchedProjectile) and IsValid(LaunchPhys) and LaunchPhys:IsMotionEnabled() then
								local ForceDir = LaunchPhys:GetVelocity():GetNormalized()
								local ForceToApply = math.min(OverflowForce, MaxVelocity * 0.2)
								LaunchPhys:ApplyForceCenter(ForceDir * ForceToApply)
								OverflowForce = OverflowForce - ForceToApply
								if OverflowForce <= 0 then
									timer.Remove("OverflowForce"..LaunchedProjectile:EntIndex())
								end
								if OverflowBursts <= 0 then
								end
							else
								timer.Remove("OverflowForce"..LaunchedProjectile:EntIndex())
							end
						end)
					end)
				end

				LaunchedProjectile:GetPhysicsObject():ApplyForceCenter(LaunchForce)
				self:GetPhysicsObject():ApplyForceCenter(-LaunchForce)

				-- Consume propellant
				self.Propellant = self.Propellant - self.CurrentPropellantPerShot
				self:UpdateWireOutputs()
				
				if self.HasRocketMotor and not Specs.NoRocketMotor then
					-- Spawn and parent a rocket motor to the projectile
					local RocketMotor = ents.Create("ent_jack_gmod_ezrocketmotor")
					RocketMotor:SetPos(CannonCenter)
					RocketMotor:SetAngles(self:GetAngles())
					RocketMotor:Spawn()
					RocketMotor:Activate()
					RocketMotor:SetParent(LaunchedProjectile)
					RocketMotor.StuckTo = LaunchedProjectile
					
					timer.Simple(.5, function()
						if IsValid(RocketMotor) and IsValid(LaunchedProjectile) then
							RocketMotor:Launch()
							RocketMotor.ThrustStuckTo = true
						end
					end)
					self.HasRocketMotor = false
				end

				self:EmitSound("snd_jack_metallicclick.ogg", 65, 90)
				local Poof = EffectData()
				Poof:SetOrigin(SelfPos + Up * 85)
				Poof:SetNormal(Up)
				Poof:SetScale(1.5 * (self.CurrentPropellantPerShot / 100))
				util.Effect("eff_jack_gmod_bphmuzzle", Poof, true, true)
				self:EmitSound("snds_jack_gmod/ez_weapons/flintlock_musketoon.ogg", 70, 80)
			end
		end)
		-- Clear the loaded projectile after launching
		self.LoadedProjectileType = nil
		self.PropModel = nil
		self.EZlaunchableWeaponLoadTime = nil

		self:UpdateWireOutputs()
		
		-- Delay state sync to allow projectile to launch first
		timer.Simple(0.5, function()
			if IsValid(self) then
				self:SyncStateToClients()
			end
		end)

		-- Remove nocollide after a short time (using the one created earlier)
		timer.Simple(2, function()
			if IsValid(Nocollider) then
				Nocollider:Remove()
			end
		end)
	end

	function ENT:OnTakeDamage(dmginfo)
		self:TakePhysicsDamage(dmginfo)

		if JMod.LinCh(dmginfo:GetDamage(), 160, 300) then
			self:Destroy(dmginfo)
		end
	end

	function ENT:Destroy(dmginfo)
		if self.Destroyed then return end
		self.Destroyed = true
		self:EmitSound("snd_jack_turretbreak.ogg", 70, math.random(80, 120))

		for i = 1, 20 do
			JMod.DamageSpark(self)
		end

		-- Launch any loaded projectile when destroyed
		if self.LoadedProjectileType then
			timer.Simple(0.1, function()
				if IsValid(self) then
					self:LaunchProjectile(false, self.EZowner)
				end
			end)
		end

		timer.Simple(2, function()
			SafeRemoveEntity(self)
		end)
	end

	function ENT:Use(activator)
		if IsValid(activator) then
			JMod.Hint(activator, "Projectile pod")
			JMod.SetEZowner(self, activator)
		end

		if JMod.IsAltUsing(activator) then
			-- Open GUI instead of immediately firing
			net.Start("JMod_EZCannon_Command")
			net.WriteEntity(self)
			net.WriteString("open")
			net.WriteString(self.LoadedProjectileType or "")
			net.WriteInt(self.Propellant, 8)
			net.WriteInt(self.CurrentPropellantPerShot, 8)
			net.Send(activator)
		else
			self:LaunchProjectile(false, activator)
		end
	end

	function ENT:PreEntityCopy()
		self.DupeLoadedProjectileType = self.LoadedProjectileType
		self.DupePropellant = self.Propellant
		self.DupePropModel = self.PropModel
		self.DupeCurrentPropellantPerShot = self.CurrentPropellantPerShot
	end

	function ENT:PostEntityPaste(ply, ent, createdEnts)
		local Time = CurTime()
		ent.NextLaunchTime = Time + 1
		if ent.DupeLoadedProjectileType then
			ent.LoadedProjectileType = ent.DupeLoadedProjectileType
			ent.EZlaunchableWeaponLoadTime = Time
		else
			ent.EZlaunchableWeaponLoadTime = nil
		end
		ent.Propellant = ent.DupePropellant or 0
		ent.PropModel = ent.DupePropModel
		ent.CurrentPropellantPerShot = ent.DupeCurrentPropellantPerShot or ent.DefaultPropellantPerShot
		JMod.SetEZowner(ent, ply, true)
		ent:SyncStateToClients()
	end

	net.Receive("JMod_EZCannon_Command", function(len, ply)
		local cannon = net.ReadEntity()
		local command = net.ReadString()
		
		-- Security checks
		if not IsValid(cannon) then return end
		if not IsValid(ply) or not ply:IsPlayer() then return end
		
		-- Check ownership
		local owner = JMod.GetEZowner(cannon)
		local isOwner = not(IsValid(owner)) or (owner and owner == ply)
		local distance = cannon:GetPos():Distance(ply:GetPos())

		if not isOwner or (distance > 100) then

			return
		end
		
		-- Process commands
		if command == "open" then
			-- Only allow opening GUI if player is close enough
			if distance <= 200 then
				net.Start("JMod_EZCannon_Command")
					net.WriteEntity(cannon)
					net.WriteString("open")
					net.WriteString(cannon.LoadedProjectileType or "")
					net.WriteInt(cannon.Propellant or 0, 8)
					net.WriteInt(cannon.CurrentPropellantPerShot or 20, 8)
				net.Send(ply)
			end
		elseif command == "fire" then
			-- Additional check for firing - must have projectile
			if cannon.LoadedProjectileType then
				cannon:LaunchProjectile(false, ply)
			end
		elseif command == "unload" then
			cannon:UnloadProjectile()
		elseif command == "setpropellant" then
			local propellant = net.ReadInt(8)
			-- Validate propellant value
			if propellant and propellant >= 1 and propellant <= 100 then
				cannon.CurrentPropellantPerShot = propellant
				cannon:UpdateWireOutputs()
			end
		elseif command == "state_sync" then
			cannon.LoadedProjectileType = net.ReadString()
			cannon.Propellant = net.ReadInt(8)
			cannon.CurrentPropellantPerShot = net.ReadInt(8)
			cannon:UpdateWireOutputs()
		end
	end)

elseif CLIENT then
	local MetalMat = Material("phoenix_storms/metal_plate")
	function ENT:Initialize()
		self.LoadedProjectileType = nil
		self.Propellant = 0
		self.PropModel = nil
		self.CurrentPropellantPerShot = self.DefaultPropellantPerShot
		
		-- Custom model initialization
		self:DrawShadow(true)
		self.Hatch = JMod.MakeModel(self, "models/props_phx/construct/metal_plate_curve180x2.mdl", "phoenix_storms/metal_plate")
		self.Breech = JMod.MakeModel(self, "models/props_phx/construct/metal_angle360.mdl", "phoenix_storms/metal_plate")
		
		-- Animation variables
		self.HatchAngle = 0
		self.BreechSlide = 0
		self.HatchTargetAngle = 0
		self.BreechTargetSlide = 0
	end

	function ENT:Think()
		local FT = FrameTime()
		
		-- Smooth animation for hatch
		self.HatchAngle = Lerp(FT * 5, self.HatchAngle, self.HatchTargetAngle)
		
		-- Smooth animation for breech
		self.BreechSlide = Lerp(FT * 5, self.BreechSlide, self.BreechTargetSlide)
		
		-- Update target angles based on cannon state
		if self.LoadedProjectileType and self.LoadedProjectileType ~= "" then
			-- Hatch closed when loaded
			self.HatchTargetAngle = 90
		else
			-- Hatch open when not loaded
			self.HatchTargetAngle = 45
		end
		
		-- Override breech animation based on propellant availability
		if self.Propellant and self.CurrentPropellantPerShot then
			if self.Propellant >= self.CurrentPropellantPerShot then
				self.BreechTargetSlide = 0
			else
				self.BreechTargetSlide = 20
			end
		end
	end

	local hatch_scale, breech_scale = Vector(.2, .2, .25), Vector(.25, .25, 1)
	function ENT:Draw()
		self:DrawModel()
		
		-- Get entity position and angles
		local SelfPos, SelfAng = self:GetPos(), self:GetAngles()
		local Up, Right, Forward = SelfAng:Up(), SelfAng:Right(), SelfAng:Forward()
		
		-- Calculate detail draw based on distance
		local Closeness = LocalPlayer():GetFOV() * (EyePos():Distance(SelfPos))
		local DetailDraw = Closeness < 120000 -- cutoff point is 400 units when the fov is 90 degrees
		
		if DetailDraw then
			-- Render hatch model
			if IsValid(self.Hatch) then
				local HatchPos = SelfPos + Up * -0 + Forward * -10 -- Adjust these offsets as needed
				local HatchAng = SelfAng:GetCopy()
				HatchAng:RotateAroundAxis(Forward, 90)
				HatchAng:RotateAroundAxis(Up, 270)
				HatchAng:RotateAroundAxis(Right, self.HatchAngle) -- Rotate around right axis
				JMod.RenderModel(self.Hatch, HatchPos, HatchAng, hatch_scale, nil, nil)
			end
			
			-- Render breech model
			if IsValid(self.Breech) then
				local BreechPos = SelfPos + Up * -43 + Forward * -10 -- Adjust these offsets as needed
				BreechPos = BreechPos + Forward * self.BreechSlide
				local BreechAng = SelfAng:GetCopy()
				JMod.RenderModel(self.Breech, BreechPos, BreechAng, breech_scale, nil, nil)
			end
		end
	end

	-- Networking receiver for opening GUI
	net.Receive("JMod_EZCannon_Command", function()
		local cannon = net.ReadEntity()
		local command = net.ReadString()
		
		if command == "open" then
			cannon.LoadedProjectileType = net.ReadString()
			cannon.Propellant = net.ReadInt(8)
			cannon.CurrentPropellantPerShot = net.ReadInt(8)

			if IsValid(cannon) then
				JMod_EZCannon_OpenGUI(cannon)
			end
		elseif command == "state_sync" then
			if IsValid(cannon) then
				cannon.LoadedProjectileType = net.ReadString()
				cannon.Propellant = net.ReadInt(8)
				cannon.CurrentPropellantPerShot = net.ReadInt(8)
			end
		end
	end)

	-- GUI function
	function JMod_EZCannon_OpenGUI(cannon)
		if not IsValid(cannon) then return end
		
		local frame = vgui.Create("DFrame")
		frame:SetSize(400, 320)
		frame:Center()
		frame:SetTitle("EZ Cannon Control")
		frame:MakePopup()
		frame:SetDraggable(true)
		frame:ShowCloseButton(true)
		
		function frame:Paint()
			EZBlurBackground(frame)
		end
		
		function frame:OnKeyCodePressed(key)
			if key == KEY_Q or key == KEY_ESCAPE then
				self:Close()
			end
		end
		
		function frame:OnClose()
			surface.PlaySound("snds_jack_gmod/ez_gui/menu_close.ogg")
		end
		
		-- Status panel
		local statusPanel = vgui.Create("DPanel", frame)
		statusPanel:SetPos(10, 30)
		statusPanel:SetSize(380, 80)
		
		function statusPanel:Paint(w, h)
			surface.SetDrawColor(0, 0, 0, 100)
			surface.DrawRect(0, 0, w, h)
		end
		
		local infoLabel = vgui.Create("DLabel", statusPanel)
		infoLabel:SetPos(10, 10)
		infoLabel:SetSize(360, 60)
		infoLabel:SetText("Cannon Status:\n" .. 
			"Loaded: " .. (cannon.LoadedProjectileType or "None") .. "\n" ..
			"Propellant: " .. (cannon.Propellant or 0) .. "/100")
		infoLabel:SetWrap(true)
		infoLabel:SetTextColor(Color(255, 255, 255, 200))
		
		-- Propellant control panel
		local controlPanel = vgui.Create("DPanel", frame)
		controlPanel:SetPos(10, 120)
		controlPanel:SetSize(380, 100)
		
		function controlPanel:Paint(w, h)
			surface.SetDrawColor(0, 0, 0, 100)
			surface.DrawRect(0, 0, w, h)
		end
		
		local propellantLabel = vgui.Create("DLabel", controlPanel)
		propellantLabel:SetPos(10, 10)
		propellantLabel:SetSize(360, 20)
		propellantLabel:SetText("Propellant per shot: " .. (cannon.CurrentPropellantPerShot or 20))
		propellantLabel:SetTextColor(Color(255, 255, 255, 200))
		
		local slider = vgui.Create("DNumSlider", controlPanel)
		slider:SetPos(10, 35)
		slider:SetSize(360, 30)
		slider:SetText("Propellant Amount")
		slider:SetMin(1)
		slider:SetMax(100)
		slider:SetValue(cannon.CurrentPropellantPerShot or 20)
		slider:SetDecimals(0)
		
		-- Button panel
		local buttonPanel = vgui.Create("DPanel", frame)
		buttonPanel:SetPos(10, 230)
		buttonPanel:SetSize(380, 80)
		
		function buttonPanel:Paint(w, h)
			surface.SetDrawColor(0, 0, 0, 100)
			surface.DrawRect(0, 0, w, h)
		end
		
		local fireButton = vgui.Create("DButton", buttonPanel)
		fireButton:SetPos(10, 10)
		fireButton:SetSize(175, 30)
		fireButton:SetText("FIRE CANNON")
		fireButton:SetTextColor(Color(255, 255, 255))
		
		function fireButton:Paint(w, h)
			local hovered = self:IsHovered()
			local color = hovered and Color(200, 50, 50, 200) or Color(200, 50, 50, 150)
			surface.SetDrawColor(color)
			surface.DrawRect(0, 0, w, h)
			
			if hovered then
				surface.SetDrawColor(255, 255, 255, 50)
				surface.DrawRect(0, 0, w, h)
			end
		end
		
		fireButton.DoClick = function()
			if IsValid(cannon) and cannon.LoadedProjectileType and cannon.LoadedProjectileType ~= "" then
				if cannon.Propellant < cannon.CurrentPropellantPerShot then
					surface.PlaySound("snds_jack_gmod/ez_gui/miss.ogg")
					notification.AddLegacy("Not enough propellant!", NOTIFY_ERROR, 2)
					return
				end

				surface.PlaySound("snds_jack_gmod/ez_gui/click_big.ogg")
				net.Start("JMod_EZCannon_Command")
				net.WriteEntity(cannon)
				net.WriteString("fire")
				net.SendToServer()
				frame:Close()
			else
				surface.PlaySound("snds_jack_gmod/ez_gui/miss.ogg")
				notification.AddLegacy("No projectile loaded!", NOTIFY_ERROR, 2)
			end
		end
		
		local unloadButton = vgui.Create("DButton", buttonPanel)
		unloadButton:SetPos(195, 10)
		unloadButton:SetSize(175, 30)
		unloadButton:SetText("UNLOAD")
		unloadButton:SetTextColor(Color(255, 255, 255))
		
		function unloadButton:Paint(w, h)
			local hovered = self:IsHovered()
			local color = hovered and Color(100, 100, 100, 200) or Color(100, 100, 100, 150)
			surface.SetDrawColor(color)
			surface.DrawRect(0, 0, w, h)
			
			if hovered then
				surface.SetDrawColor(255, 255, 255, 50)
				surface.DrawRect(0, 0, w, h)
			end
		end
		
		unloadButton.DoClick = function()
			if IsValid(cannon) then
				surface.PlaySound("snds_jack_gmod/ez_gui/click_smol.ogg")
				net.Start("JMod_EZCannon_Command")
				net.WriteEntity(cannon)
				net.WriteString("unload")
				net.SendToServer()
				frame:Close()
			end
		end
		
		local closeButton = vgui.Create("DButton", buttonPanel)
		closeButton:SetPos(10, 45)
		closeButton:SetSize(360, 25)
		closeButton:SetText("CLOSE")
		closeButton:SetTextColor(Color(255, 255, 255))
		
		function closeButton:Paint(w, h)
			local hovered = self:IsHovered()
			local color = hovered and Color(80, 80, 80, 200) or Color(80, 80, 80, 150)
			surface.SetDrawColor(color)
			surface.DrawRect(0, 0, w, h)
			
			if hovered then
				surface.SetDrawColor(255, 255, 255, 50)
				surface.DrawRect(0, 0, w, h)
			end
		end
		
		closeButton.DoClick = function()
			frame:Close()
		end
		
		-- Update propellant when slider changes
		slider.OnValueChanged = function(self, value)
			if IsValid(cannon) then
				cannon.CurrentPropellantPerShot = math.floor(value)
				net.Start("JMod_EZCannon_Command")
				net.WriteEntity(cannon)
				net.WriteString("setpropellant")
				net.WriteInt(math.floor(value), 8)
				net.SendToServer()
			end
		end
		
		-- Play menu open sound
		surface.PlaySound("snds_jack_gmod/ez_gui/menu_open.ogg")
	end

	function ENT:OnRemove()
		self.RenderProjectiles = self.RenderProjectiles or {}
		for num, model in pairs(self.RenderProjectiles) do
			if IsValid(model) then
				model:Remove()
			end
		end
		
		-- Clean up custom models
		if IsValid(self.Hatch) then
			self.Hatch:Remove()
		end
		if IsValid(self.Breech) then
			self.Breech:Remove()
		end
	end
end
