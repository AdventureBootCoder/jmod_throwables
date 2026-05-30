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
ENT.AutomaticFrameAdvance = true
---
ENT.JModPreferredCarryAngles = Angle(90, 0, 0)
ENT.EZcolorable = false
ENT.EZlowFragPlease = true
ENT.EZbuoyancy = .3
ENT.JModHighlyFlammableFunc = "LaunchProjectile"
ENT.Mass = 300
ENT.Model = "models/props_phx/misc/smallcannon.mdl"
---
ENT.EZconsumes = {
	JMod.EZ_RESOURCE_TYPES.BASICPARTS,
	JMod.EZ_RESOURCE_TYPES.PROPELLANT
}

ENT.DefaultPropellantPerShot = 20
ENT.MaxPropellant = 100
ENT.NextRefillTime = 0
ENT.BarrelLength = 50
ENT.BreachOffset = -20 -- Extra offset along barrel (Up) when seating a loaded projectile; launch alignment uses BarrelLength only
ENT.MaxPropellantForce = 500000 * 3.3
ENT.TargetPropellant = 50
ENT.TargetPercentage = .5
ENT.FireDelay = 1.5
ENT.Spread = 0.01
ENT.MaxPropSize = Vector(50, 15, 15) -- Max dimensions: largest, second largest, smallest
ENT.MaxDurability = 1000 -- Maximum durability, can be overridden by other cannons

ENT.OpenSequence = "open"
ENT.IdleSequence = "idle_close"
ENT.IdleEmptySequence = "idle_open"
ENT.LoadSequence = "load_close"
ENT.NextIdle = 0
ENT.NextLaunchTime = 0

ENT.WireInputSetup = {
	LAUNCH = {"Launch", "[NORMAL]", "Fires the loaded Projectile"},
	UNLOAD = {"Unload", "[NORMAL]", "Unloads Projectile"},
	PROPELLETPERSHOT = {"PropellantPerShot", "[NORMAL]", "Sets the amount of propellant used per shot (1-100)"},
	DESIREDPROJECTILECLASS = {"DesiredProjectileClass", "[STRING]", "Sets the desired projectile class for autoloading"},
	AUTOLOADING = {"AutoLoading", "[NORMAL]", "Enable (1) or disable (0) autoloading"},
	DURABILITY = {"Durability", "[NORMAL]", "Current durability"},
}
ENT.WireOutputSetup = {
	LOADEDPROJECTILE = {"LoadedProjectile", "[STRING]", "The currently loaded Projectile type"},
	ISLOADED = {"IsLoaded", "[NORMAL]", "Whether a projectile is loaded (1) or not (0)"},
	PROPLEL = {"Propellant", "[NORMAL]", "Current propellant amount"},
	PROPMODEL = {"PropModel", "[STRING]", "Model name of loaded prop (if applicable)"},
	CURRENTPROPELLETPERSHOT = {"CurrentPropellantPerShot", "[NORMAL]", "Current propellant amount per shot"},
	MUZZLEVELOCITY = {"MuzzleVelocity", "[NORMAL]", "Calculated muzzle velocity in units/second"},
	DESIREDPROJECTILECLASS = {"DesiredProjectileClass", "[STRING]", "The desired projectile class for autoloading"},
	AUTOLOADING = {"AutoLoading", "[NORMAL]", "Whether autoloading is enabled (1) or disabled (0)"},
	DURABILITY = {"Durability", "[NORMAL]", "Current durability"},
}

-- Function to calculate force based on propellant amount using exponential curve
-- Formula: force = MaxForce * (1 - e^(-propellant * k))
-- Where k is calculated to give us targetpower% at targetpropellant amount
function ENT:CalculateForceCurve(propellantAmount)
	-- Calculate the curve parameter k
	local k = -math.log(1 - self.TargetPercentage) / self.TargetPropellant
	
	-- Calculate and return the force magnitude
	return self.MaxPropellantForce * (1 - math.exp(-propellantAmount * k))
end

-- Calculate muzzle velocity using powder force curve and projectile mass
function ENT:CalculateMuzzleVelocity(propellantAmount)
	-- Return 0 if no valid projectile is loaded
	if not IsValid(self.LoadedProjectileEnt) then
		return 0
	end
	
	-- Get the force from the powder curve
	local force = self:CalculateForceCurve(propellantAmount or self:GetPowder())
	
	-- Get projectile mass (use stored mass or get from physics object)
	local mass = self.ProjectileMass or 1
	if IsValid(self.LoadedProjectileEnt) then
		local phys = self.LoadedProjectileEnt:GetPhysicsObject()
		if IsValid(phys) then
			local physMass = phys:GetMass()
			-- Use physics mass if reasonable, otherwise use stored/default
			if physMass > 0 and physMass <= 20000 then
				mass = physMass
			end
		end
	end
	
	-- Calculate muzzle velocity: velocity = force / mass
	return force / mass
end

-- Combined powder available for a shot: loaded charge + projectile's built-in PowderAdd
function ENT:GetPowder()
	local PowderAdd = 0
	if self.LoadedProjectileType and self.LoadedProjectileType ~= "" and self.ProjectileSpecs then
		local Specs = self.ProjectileSpecs[self.LoadedProjectileType]
		if Specs and Specs.PowderAdd then PowderAdd = Specs.PowderAdd end
	end
	return (self.Propellant or 0) + PowderAdd
end

function ENT:GetLaunchDir()
	return self:GetUp()
end

function ENT:GetLaunchPos()
	return self:LocalToWorld(self:OBBCenter()) + self:GetLaunchDir() * self.BarrelLength
end

function ENT:GetLaunchPosAng()
	if self.MuzzleAttachment then
		local AttachmentIndex = self:LookupAttachment(self.MuzzleAttachment)
		if AttachmentIndex > 0 then
			local AttachmentInfo = self:GetAttachment(AttachmentIndex)

			return AttachmentInfo.Pos, AttachmentInfo.Ang
		end
	end

	return self:GetLaunchPos(), self:GetLaunchDir():Angle()
end

-- World point when seating a loaded projectile along the barrel (includes BreachOffset from breech)
function ENT:GetLoadPosCenter()
	local Up = self:GetUp()
	if self.ProjectileBone then
		local BoneIndex = self:LookupBone(self.ProjectileBone)
		if BoneIndex then
			local BonePos, _ = self:GetBonePosition(BoneIndex)

			return BonePos + Up * (self.BreachOffset or 0)
		end
	end
	return self:LocalToWorld(self:OBBCenter()) + Up * (self.BreachOffset or 0)
end

function ENT:SetCaseBodygroup(bodygroup)
	if self.CaseBodygroup and self.CaseBodygroup[bodygroup] then
		self:SetBodygroup(self.CaseBodygroup[bodygroup][1], self.CaseBodygroup[bodygroup][2])
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "IsAutoLoading")
end

if SERVER then
	function ENT:SpawnFunction(ply, tr)
		local SpawnPos = tr.HitPos + tr.HitNormal * 20
		local ent = ents.Create(self.ClassName)
		ent:SetAngles((self.JModPreferredCarryAngles or Angle(0, 0, 0)) + Angle(0, ply:GetAngles().y, 0))
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
		self:SetModel(self.Model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:DrawShadow(true)
		self:SetUseType(SIMPLE_USE)
		---
		local phys = self:GetPhysicsObject()
		timer.Simple(.01, function()
			if IsValid(phys) then
				phys:SetMass(self.Mass)
				phys:Wake()
				phys:EnableDrag(false)
				phys:SetBuoyancyRatio(self.EZbuoyancy)
			end
		end)
		self.LoadedProjectileType = self.LoadedProjectileType
		self.Propellant = self.Propellant or 0
		self.CurrentPropellantPerShot = self.CurrentPropellantPerShot or self.DefaultPropellantPerShot
		self.ProjectileMass = self.ProjectileMass or 0
		self.ProjectileSpecs = JModBallistics.ProjectileSpecs[self:GetClass()].types or {}
		self.DesiredProjectileClass = self.DesiredProjectileClass or ""
		self:SetDesiredProjectileClass(self.DesiredProjectileClass)
		self:SetIsAutoLoading(true)
		self.Durability = self.Durability or (self.MaxDurability or 1000)
		self.MaxDurability = self.MaxDurability or 1000
		self.LoadedProjectileEnt = nil
		self.CannonProjectileNoCollide = nil
		---
		if istable(WireLib) then
			local InputNames, InputDescs = {}, {}
			local OutputNames, OutputDescs = {}, {}
			for id, info in pairs(self.WireInputSetup) do
				table.insert(InputNames, info[1]..info[2])
				table.insert(InputDescs, info[3])
			end
			for id, info in pairs(self.WireOutputSetup) do
				table.insert(OutputNames, info[1]..info[2])
				table.insert(OutputDescs, info[3])
			end
			self.Inputs = WireLib.CreateInputs(self, InputNames, InputDescs)
			self.Outputs = WireLib.CreateOutputs(self, OutputNames, OutputDescs)
		end
		
		-- Sync initial state to clients
		timer.Simple(0.1, function()
			if IsValid(self) then
				self:SyncStateToClients()
			end
		end)
	end
	function ENT:UpdateWireOutputs(outputName)
		if istable(WireLib) then
			-- Calculate current muzzle velocity
			local MuzzleVelocity = self:CalculateMuzzleVelocity(self:GetPowder())
			
			WireLib.TriggerOutput(self, "IsLoaded", IsValid(self.LoadedProjectileEnt) and 1 or 0)
			WireLib.TriggerOutput(self, "LoadedProjectile", IsValid(self.LoadedProjectileEnt) and (self.LoadedProjectileType or "") or "")
			WireLib.TriggerOutput(self, "Propellant", self.Propellant or 0)
			WireLib.TriggerOutput(self, "PropModel", self.PropModel or "")
			WireLib.TriggerOutput(self, "CurrentPropellantPerShot", self.CurrentPropellantPerShot or 0)
			WireLib.TriggerOutput(self, "MuzzleVelocity", MuzzleVelocity or 0)
			WireLib.TriggerOutput(self, "DesiredProjectileClass", self:GetDesiredProjectileClass() or "")
			WireLib.TriggerOutput(self, "AutoLoading", self:GetIsAutoLoading() and 1 or 0)
			WireLib.TriggerOutput(self, "Durability", self.Durability or 0)
		end
	end
	
	function ENT:SyncStateToClients()
		net.Start("JMod_EZCannon_Command")
		net.WriteEntity(self)
		net.WriteString("state_sync")
		net.WriteString(IsValid(self.LoadedProjectileEnt) and (self.LoadedProjectileType or "") or "")
		net.WriteUInt(self.Propellant or 0, 8)
		net.WriteUInt(self.CurrentPropellantPerShot or 20, 8)
		net.WriteUInt(self.ProjectileMass or 0, 16) -- Send projectile mass instead of calculated range
		net.WriteString(self:GetDesiredProjectileClass() or "")
		net.Broadcast()
	end
	
	function ENT:TriggerInput(iname, value)
		if iname == "Launch" and value > 0 then
			self:LaunchProjectile(false)
		elseif iname == "Unload" and value > 0 then
			self:UnloadProjectile()
		elseif iname == "PropellantPerShot" then
			self.CurrentPropellantPerShot = math.Clamp(value, 1, self.MaxPropellant or 100)
			self:UpdateWireOutputs()
			self:SyncStateToClients()
		elseif iname == "DesiredProjectileClass" then
			if isstring(value) then
				self:SetDesiredProjectileClass(value)
				self:SyncStateToClients()
			end
		elseif iname == "AutoLoading" then
			self:SetIsAutoLoading(value > 0)
			self:UpdateWireOutputs()
			self:SyncStateToClients()
		end
	end

	-- Function to check if a prop_physics entity is suitable for loading
	function ENT:IsPropSuitable(prop)
		if not IsValid(prop) or prop:GetClass() ~= "prop_physics" then return false end
		
		-- Get the model bounds
		local mins, maxs = prop:GetCollisionBounds()
		local size = maxs - mins
		
		-- Sort sides by size (largest first)
		local sides = {math.Round(size.x), math.Round(size.y), math.Round(size.z)}
		table.sort(sides, function(a, b) return a > b end)
		
		-- Check size constraints using MaxPropSize vector
		-- MaxPropSize components: x = max largest dimension, y = max second dimension, z = max third dimension
		if sides[1] > self.MaxPropSize.x then
			return false
		end
		
		if sides[2] > self.MaxPropSize.y and sides[3] > self.MaxPropSize.z then
			return false
		end
		
		return true
	end

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

	-- Seats an existing spawned projectile: NoCollide, barrel pose, parent. classOverride for ReplaceEnt edge cases.
	function ENT:FinishLoadingProjectile(Projectile, classOverride)
		if not IsValid(Projectile) or not IsValid(self) then return false end
		if IsValid(self.LoadedProjectileEnt) then return false end

		local cls = classOverride or Projectile:GetClass()
		local Specs = self.ProjectileSpecs[cls]
		if not Specs then return false end

		if cls == "prop_physics" then
			self.PropModel = Projectile:GetModel()
		end

		local phys = Projectile:GetPhysicsObject()
		local mass = 100
		if IsValid(phys) then
			mass = phys:GetMass()
			if mass > 20000 then
				if Specs.DefaultMass then
					mass = Specs.DefaultMass
				else
					mass = 100
				end
			end
		else
			if Specs.DefaultMass then
				mass = Specs.DefaultMass
			end
		end
		self.ProjectileMass = mass

		local Up, Forward, Right = self:GetUp(), self:GetForward(), self:GetRight()
		local LaunchAngle = self:GetAngles()
		if Specs.UsePropModel then
			local longestAxis = select(1, self:CalculatePropLaunchAngle(Projectile))
			if longestAxis == 1 then
				LaunchAngle:RotateAroundAxis(LaunchAngle:Right(), 90)
			elseif longestAxis == 2 then
				LaunchAngle:RotateAroundAxis(LaunchAngle:Forward(), 90)
			elseif longestAxis == 3 then
				LaunchAngle:RotateAroundAxis(LaunchAngle:Up(), 90)
			end
		else
			LaunchAngle:RotateAroundAxis(LaunchAngle:Right(), 90 + (Specs.RightCorrection or 0))
			if Specs.Angles then
				LaunchAngle:RotateAroundAxis(LaunchAngle:Right(), Specs.Angles.p)
				LaunchAngle:RotateAroundAxis(LaunchAngle:Up(), Specs.Angles.y)
				LaunchAngle:RotateAroundAxis(LaunchAngle:Forward(), Specs.Angles.r)
			elseif Projectile.JModPreferredCarryAngles then
				LaunchAngle:RotateAroundAxis(LaunchAngle:Right(), -Projectile.JModPreferredCarryAngles.p)
				LaunchAngle:RotateAroundAxis(LaunchAngle:Up(), Projectile.JModPreferredCarryAngles.y)
				LaunchAngle:RotateAroundAxis(LaunchAngle:Forward(), Projectile.JModPreferredCarryAngles.r)
			end
		end
		Projectile:SetAngles(LaunchAngle)

		-- Same as legacy launch: OBB alignment must use the projectile at cannon origin first,
		-- or LocalToWorld(OBBCenter) is wrong and the shot ends up under/off the barrel.
		local SelfPos = self:GetPos()
		local CannonBarrelCenter = self:GetLoadPosCenter()
		local ProjectileCenter = Projectile:LocalToWorld(Projectile:OBBCenter() + (Specs.LaunchOffset or vector_origin))
		-- Seat the bottom of the projectile's longest OBB axis (post-rotation, aligned with cannon Up) at the breach anchor
		local _, longestSize = self:CalculatePropLaunchAngle(Projectile)
		local LaunchOffset = Specs.LaunchOffset or vector_origin
		local LaunchPos = SelfPos + (CannonBarrelCenter - ProjectileCenter) + Up * (longestSize * 0.5)
		Projectile:SetPos(LaunchPos)

		self.CannonProjectileNoCollide = constraint.NoCollide(self, Projectile, 0, 0, true)

		Projectile:SetNotSolid(true)
		Projectile:SetMoveType(MOVETYPE_NONE)
		Projectile:ForcePlayerDrop()
		Projectile:SetParent(self, self:LookupBone(self.ProjectileBone or ""))

		self.LoadedProjectileEnt = Projectile
		self.LoadedProjectileType = cls
		local Time = CurTime()
		self.EZlaunchableWeaponLoadTime = Time

		if self.LoadSequence then
			local LoadSeqID, LoadSeqLength = self:LookupSequence(self.LoadSequence)
			if LoadSeqLength > 0 then
				self:ResetSequence(LoadSeqID)
				self.NextIdle = Time + LoadSeqLength
				self.NextLaunchTime = Time + LoadSeqLength
			end
		end

		self:EmitSound("snd_jack_metallicload.ogg", 65, 90)
		self:UpdateWireOutputs()
		self:SyncStateToClients()

		self:SetCaseBodygroup("LOADED")

		return true
	end

	function ENT:InsideBreechHB(hitPos, hitNormal, physobj)
		if not self.BreechHB or self.BreechHB == "" then return true end

		local tr = util.TraceLine({
			start = hitPos + hitNormal * 10,
			endpos = hitPos,
			filter = {self},
			whitelist = true,
			ignoreworld = true
		})

		--print(tr.HitBox)
		--self:SetHitboxSet(tr.HitBox)

		--local hitboxID, hitboxGroup = self:GetHitboxSet(self.BreechHB)
		--print(hitboxID, hitboxGroup, hitboxGroup == self.BreechHB)
		--debugoverlay.Cross(hitPos, 10, 1, Color(255, 0, 0), true)
		return true--hitboxGroup == self.BreechHB
	end

	function ENT:PhysicsCollide(data, physobj)
		if not IsValid(self) then return end
		local ent = data.HitEntity

		if data.DeltaTime > 0.2 then
			if data.Speed > 50 then
				self:EmitSound("Metal_Box.ImpactHard")
			end

			if self.Destroyed then return end

			if data.Speed > 5000 and not(ent:IsPlayerHolding()) then
				--self:Destroy()
			end

			if not self:InsideBreechHB(data.HitPos, data.HitNormal, physobj) then return end

			local desiredClass = self:GetDesiredProjectileClass()
			local entClass = ent:GetClass()

			if self.ProjectileSpecs[entClass] and (desiredClass == "" or desiredClass == entClass) then
				if entClass == "prop_physics" and desiredClass == "" then
					
					return
				end
				local cannon, hitEnt = self, ent
				timer.Simple(0, function()
					if not IsValid(cannon) or not IsValid(hitEnt) then return end
					cannon:LoadProjectile(hitEnt)
				end)
			end
		end
	end

	function ENT:TryLoadResource(typ, amt)
		if(amt <= 0)then return 0 end
		local Time = CurTime()
		if (self.NextRefillTime > Time) or (typ == "generic") then return 0 end
		
		if typ == JMod.EZ_RESOURCE_TYPES.PROPELLANT then
			local SpaceLeft = math.max(0, (self.CurrentPropellantPerShot or self.DefaultPropellantPerShot) - self.Propellant)
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
		
		-- Repair durability with basic parts at 4x efficiency
		if typ == JMod.EZ_RESOURCE_TYPES.BASICPARTS then
			local MissingDurability = self.MaxDurability - (self.Durability or 0)
			if MissingDurability > 0 then
				-- 4x efficiency: 1 basic part = 4 durability
				local DurabilityToRestore = math.min(amt * 4, MissingDurability)
				local PartsUsed = math.ceil(DurabilityToRestore / 4)
				
				if PartsUsed > 0 then
					self.Durability = math.min((self.Durability or 0) + DurabilityToRestore, self.MaxDurability)
					self.NextRefillTime = CurTime() + 0.1
					self:EmitSound("snd_jack_turretrepair.ogg", 65, math.random(90, 110))
					self:UpdateWireOutputs()
					return PartsUsed
				end
			end
		end
		
		return 0
	end

	function ENT:GetDesiredProjectileClass()
		return self.DesiredProjectileClass
	end

	function ENT:SetDesiredProjectileClass(projectileClass)
		if not(isstring(projectileClass)) or projectileClass == "" then
			self.DesiredProjectileClass = ""
			self:UpdateWireOutputs()
			
			return
		end
		if not self.ProjectileSpecs[projectileClass] then return end

		self.DesiredProjectileClass = projectileClass
		self:UpdateWireOutputs()
	end

	function ENT:GetLoadedProjectileType()
		if not IsValid(self.LoadedProjectileEnt) then return nil end
		return self.LoadedProjectileType
	end

	function ENT:LoadProjectile(Projectile)
		if not IsValid(Projectile) then return end
		if IsValid(self.LoadedProjectileEnt) then return end
		if Projectile.EZalreadyLoaded then return end
		if not (Projectile:IsPlayerHolding() or JMod.Config.ResourceEconomy.ForceLoadAllResources) then return end
		if next(Projectile:GetChildren()) then return end

		constraint.RemoveConstraints(Projectile, "NoCollide")

		local Specs = self.ProjectileSpecs[Projectile:GetClass()]
		if not Specs then return end

		if Projectile:GetClass() == "prop_physics" then
			if not self:IsPropSuitable(Projectile) then
				local owner = JMod.GetEZowner(self)
				if IsValid(owner) and owner:IsPlayer() then
					JMod.Hint(owner, "cannon prop size")
				end
				return
			end
		end

		Projectile.EZalreadyLoaded = true
		if not self:FinishLoadingProjectile(Projectile) then
			Projectile.EZalreadyLoaded = false
		end
	end

	function ENT:EjectPropellant()
		local Amount = self.Propellant or 0
		if Amount <= 0 then return end
		JMod.MachineSpawnResource(self, JMod.EZ_RESOURCE_TYPES.PROPELLANT, Amount, self:OBBCenter(), Angle(0, 0, 0), self:OBBCenter(), 150)
		self.Propellant = 0
		self:UpdateWireOutputs()
		self:SyncStateToClients()
	end

	function ENT:UnloadProjectile()
		if not IsValid(self.LoadedProjectileEnt) then return end
		self:EjectPropellant()
		self:LaunchProjectile(true)
	end

	function ENT:LaunchEffects()
		local Up, Forward, Right = self:GetUp(), self:GetForward(), self:GetRight()
		local SelfPos = self:GetPos()
		local LaunchPos, LaunchDir = self:GetLaunchPos(), self:GetLaunchDir()

		-- Enhanced cannon firing sound system
		--self:EmitSound("snd_jack_metallicclick.ogg", 65, 90)
		local CannonFireSound = "^phx/explode0"..math.random(0, 6)..".wav"
		
		-- Calculate sound volume based on propellant amount
		local BaseSoundLevel = 70
		local PropellantMultiplier = self.CurrentPropellantPerShot / self.DefaultPropellantPerShot
		
		-- Calculate pitch variation based on propellant
		local BasePitch = 70
		local PitchVariation = math.random(-10, 10)
		local FinalPitch = math.Clamp(BasePitch + PitchVariation, 50, 100)
		
		self:EmitSound(CannonFireSound, 160, FinalPitch, 200)
		
		local Poof = EffectData()
		Poof:SetOrigin(LaunchPos)
		Poof:SetNormal(LaunchDir)
		Poof:SetScale(1 * (self.CurrentPropellantPerShot / 100))
		util.Effect("eff_aboot_bp_cannon_muzzle", Poof, true, true)
		
		if self.CurrentPropellantPerShot > self.TargetPropellant then
			timer.Simple(.15, function()
				if not IsValid(self) then return end
				local Pos, Dir = self:GetLaunchPos(), self:GetLaunchDir()
				local ExplosionPos = Pos + Dir * 300
				local ExplosionPower = 10 * (self.CurrentPropellantPerShot / self.TargetPropellant)

				JMod.Sploom(JMod.GetEZowner(self), ExplosionPos, ExplosionPower, 180)
			end)
		end
		
		-- Minor screen shake
		util.ScreenShake(LaunchPos, 100 * PropellantMultiplier, 10, .5 * PropellantMultiplier, 200, true)
	end

	function ENT:EjectCase()
		if self.CaseModel then
			self:SetCaseBodygroup("EMPTY")
			local Pos = self:GetBonePosition(self:LookupBone(self.ProjectileBone))
			local Case = ents.Create("prop_physics")
			Case:SetModel(self.CaseModel)
			Case:SetPos(Pos)
			Case:SetAngles(self:GetAngles())
			Case:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			Case:Spawn()
			Case:Activate()
			timer.Simple(0, function()
				Case:SetVelocity(self:GetPhysicsObject():GetVelocity() - self:GetLaunchDir() * 200)
				--[[if IsValid(Case) and IsValid(self) then
					local LaunchDir = self:GetLaunchDir()
					Case:GetPhysicsObject():SetVelocity(self:GetPhysicsObject():GetVelocity() - LaunchDir * 200)
				end--]]
			end)
			SafeRemoveEntityDelayed(Case, 10)
		end
	end

	function ENT:ArmProjectile(projectile, ply)
		if not IsValid(projectile) then return end
		local ArmMethod = self.ProjectileSpecs[projectile:GetClass()].ArmMethod or projectile.ArmMethod
		if ArmMethod and isfunction(projectile[ArmMethod]) then
			projectile[ArmMethod](projectile, ply)
		elseif isfunction(projectile.Arm) then
			projectile:Arm(ply)
		elseif isfunction(projectile.SetState) then
			projectile:SetState(JMod.EZ_STATE_ON)
		end	
	end

	function ENT:LaunchProjectile(unload, ply)
		local Time = CurTime()

		if not unload and self.NextLaunchTime and (self.NextLaunchTime >= Time) then return end

		if not self.LoadedProjectileType or not IsValid(self.LoadedProjectileEnt) then 
			self.EZlaunchableWeaponLoadTime = nil
			
			return 
		end
		local Specs = self.ProjectileSpecs[self.LoadedProjectileType]

		if not Specs then return end

		if not unload and self:GetPowder() < self.CurrentPropellantPerShot then
			self:EmitSound("snd_jack_metallicclick.ogg", 65, 100)

			return
		end

		self.NextLaunchTime = Time + (self.FireDelay or 1.5)

		if not unload then
			local durabilityPercent = (self.Durability or self.MaxDurability) / (self.MaxDurability or 1000)
			if durabilityPercent <= 0.4 then
				local blowUpChance = (0.4 - durabilityPercent) * 2.5
				if JMod.LinCh(blowUpChance * 100, 0, 100) then
					self:BlowUp(false, nil)

					return
				end
			end

			self.Durability = math.max(0, (self.Durability or self.MaxDurability) - 0.5)
			self:UpdateWireOutputs()
		end

		ply = ply or JMod.GetEZowner(self)
		local Up, Forward, Right = self:GetUp(), self:GetForward(), self:GetRight()
		local SelfPos = self:GetPos()

		local LaunchedProjectile = self.LoadedProjectileEnt
		local Nocollider = self.CannonProjectileNoCollide
		self.LoadedProjectileEnt = nil
		self.CannonProjectileNoCollide = nil

		if not IsValid(LaunchedProjectile) then return end

		LaunchedProjectile:SetParent(nil)
		LaunchedProjectile:SetNotSolid(false)
		LaunchedProjectile:SetNoDraw(false)
		LaunchedProjectile:SetMoveType(MOVETYPE_VPHYSICS)
		local LaunchPhys = LaunchedProjectile:GetPhysicsObject()
		if IsValid(LaunchPhys) then
			LaunchPhys:EnableMotion(true)
			LaunchPhys:Wake()
		end

		local CannonBarrelCenter, CannonBarrelAng = self:GetLaunchPosAng()
		local CenterPosOffset = LaunchedProjectile:GetPos() - LaunchedProjectile:LocalToWorld(LaunchedProjectile:OBBCenter())
		local LaunchPos = self:GetLaunchPos() + CenterPosOffset
		LaunchedProjectile:SetPos(LaunchPos)

		local LaunchAngle = CannonBarrelAng or LaunchedProjectile:GetAngles()
		local CannonPhys = self:GetPhysicsObject()
		LaunchPhys:SetVelocity(IsValid(CannonPhys) and CannonPhys:GetVelocity() or vector_origin)
		if unload then
			LaunchPhys:SetAngleVelocity(vector_origin)
		elseif IsValid(CannonPhys) then
			LaunchPhys:SetAngleVelocity(CannonPhys:GetAngleVelocity())
		end

		if Specs.UsePropModel then
			LaunchPhys:SetMass(self.ProjectileMass)
		end

		if unload then
			if LaunchedProjectile.SetState then
				LaunchedProjectile:SetState(JMod.EZ_STATE_OFF)
			end
		else
			LaunchedProjectile.DropOwner = self

			if Specs.UsePropModel then
				LaunchedProjectile:Ignite(10, 0)
			else
				if Specs.ArmDelay then 
					timer.Simple(Specs.ArmDelay, function() self:ArmProjectile(LaunchedProjectile, ply) end)
				else
					self:ArmProjectile(LaunchedProjectile, ply)
				end
			end

			local CalculatedForce = self:CalculateForceCurve(self:GetPowder())
			local Spread = self.Spread or 0.01
			local LaunchDir = self:GetLaunchDir()
			local LaunchForce = LaunchDir * CalculatedForce * (Specs.ForceMult or 1)

			local ProjectileMass = LaunchPhys:GetMass()
			local LaunchForceLength = LaunchForce:Length()
			local LaunchVelocity = LaunchForceLength / ProjectileMass

			local MaxVelocity = GetConVar("sv_maxvelocity"):GetFloat()
			local MaxForce = ProjectileMass * MaxVelocity
			local OverflowForce = LaunchForceLength - MaxForce
			local IsSupersonic = LaunchVelocity >= 13500

			if OverflowForce > 0 then
				local HullSize = Vector(self.MaxPropSize.y, self.MaxPropSize.z, self.MaxPropSize.z)
				local MinSafeDistance = self.MaxPropSize.x * 2

				local initialTr = util.TraceHull({
					start = CannonBarrelCenter,
					endpos = CannonBarrelCenter + LaunchDir * MinSafeDistance,
					mins = -HullSize * 0.5,
					maxs = HullSize * 0.5,
					filter = {self, LaunchedProjectile}
				})

				if not initialTr.Hit then
					local HadMotion = LaunchPhys:IsMotionEnabled()
					if HadMotion then
						LaunchPhys:EnableMotion(false)
					end

					JModBallistics.CreateProjectileTracker(
						LaunchedProjectile, 
						(LaunchDir * LaunchVelocity), 
						HadMotion, 
						HullSize,
						{self, LaunchedProjectile}
					)
				end
				debugoverlay.Cross(CannonBarrelCenter, 10, 5, Color(229, 255, 0), true)
			else
				LaunchPhys:ApplyForceCenter(LaunchForce)
			end
			self:GetPhysicsObject():ApplyForceCenter(-LaunchForce)

			self.Propellant = 0
			self:UpdateWireOutputs()
			self:LaunchEffects(LaunchPos, LaunchDir, LaunchForce, LaunchVelocity, IsSupersonic)
		end

		self.LoadedProjectileType = nil
		self.PropModel = nil
		self.EZlaunchableWeaponLoadTime = nil
		if IsValid(LaunchedProjectile) then
			LaunchedProjectile.EZalreadyLoaded = false
		end

		self.NextIdle = Time + 1
		timer.Simple(0.5, function()
			if IsValid(self) then
				self:UpdateWireOutputs()
				self:SyncStateToClients()

				local OpenSeqID, OpenSeqLength = self:LookupSequence(self.OpenSequence)
				if OpenSeqLength > 0 then
					self:ResetSequence(OpenSeqID)
					local ExtractSeqID, ExtractSeqLength = self:LookupSequence(self.ExtractSequence)
					if ExtractSeqLength > 0 then
						self:SetCaseBodygroup("EJECTING")
						self:ResetSequence(ExtractSeqID)
						self.NextIdle = CurTime() + ExtractSeqLength
						timer.Simple(ExtractSeqLength - 0.1, function()
							if IsValid(self) then
								self:EjectCase()
							end
						end)
					else
						self.NextIdle = CurTime() + OpenSeqLength
					end
				end
			end
		end)

		timer.Simple(2, function()
			if IsValid(Nocollider) then
				Nocollider:Remove()
			end
		end)
	end

	function ENT:BlowUp(fromDamage, projectileToDetonate)
		-- Return early if no propellant
		if not self.Propellant or self.Propellant <= 0 then
			return
		end
		
		local Up, Forward, Right = self:GetUp(), self:GetForward(), self:GetRight()
		local SelfPos = self:GetPos()
		
		-- Calculate breach position (opposite of barrel)
		local BreachPos = SelfPos - Up * (self.BreachOffset or 0)
		
		-- Calculate explosion power based on propellant amount
		local ExplosionPower = math.max(10, (self.Propellant or 0) * 0.5)
		local ExplosionRadius = math.max(50, (self.Propellant or 0) * 2)
		
		-- Create explosion at breach position
		local owner = JMod.GetEZowner(self)
		JMod.Sploom(owner, BreachPos, ExplosionPower, ExplosionRadius)
		
		if self.LoadedProjectileType and self.LoadedProjectileType ~= "" then
			if fromDamage and projectileToDetonate and IsValid(projectileToDetonate) then
				timer.Simple(0.01, function()
					if IsValid(projectileToDetonate) then
						if projectileToDetonate.Detonate then
							projectileToDetonate:Detonate()
						elseif projectileToDetonate.SetState then
							projectileToDetonate:SetState(JMod.EZ_STATE_ON)
							timer.Simple(0.1, function()
								if IsValid(projectileToDetonate) and projectileToDetonate.Detonate then
									projectileToDetonate:Detonate()
								end
							end)
						end
					end
				end)
			elseif IsValid(self.LoadedProjectileEnt) then
				local Specs = self.ProjectileSpecs[self.LoadedProjectileType]
				if Specs then
					if IsValid(self.CannonProjectileNoCollide) then
						self.CannonProjectileNoCollide:Remove()
						self.CannonProjectileNoCollide = nil
					end
					local LaunchedProjectile = self.LoadedProjectileEnt
					LaunchedProjectile:SetParent(nil)
					LaunchedProjectile:SetNotSolid(false)
					LaunchedProjectile:SetNoDraw(false)
					LaunchedProjectile:SetMoveType(MOVETYPE_VPHYSICS)
					local pobj = LaunchedProjectile:GetPhysicsObject()
					if IsValid(pobj) then
						pobj:EnableMotion(true)
						pobj:Wake()
					end
					LaunchedProjectile:SetPos(SelfPos)
					JMod.SetEZowner(LaunchedProjectile, owner)
					timer.Simple(0.01, function()
						if IsValid(LaunchedProjectile) then
							local phys = LaunchedProjectile:GetPhysicsObject()
							if IsValid(phys) then
								local tossDir = (Up + VectorRand() * 0.5):GetNormalized()
								phys:SetVelocity(tossDir * 200)
								phys:ApplyForceCenter(tossDir * 500)
							end
						end
					end)
				end
			end
		end

		self.LoadedProjectileType = nil
		self.PropModel = nil
		self.LoadedProjectileEnt = nil
		self.CannonProjectileNoCollide = nil
		
		-- Clear propellant after explosion
		self.Propellant = 0
		
		-- Play breaking sound and sparks
		self:EmitSound("snd_jack_turretbreak.ogg", 70, math.random(80, 120))
		for i = 1, 20 do
			JMod.DamageSpark(self)
		end
	end

	function ENT:OnTakeDamage(dmginfo)
		self:TakePhysicsDamage(dmginfo)

		-- Reduce all incoming non-explosive damage by 50%
		local damage = dmginfo:GetDamage()
		local isExplosive = dmginfo:IsDamageType(DMG_BLAST) or dmginfo:IsDamageType(DMG_BURN) or dmginfo:IsExplosionDamage()
		if not isExplosive then
			damage = damage * 0.5
		end
		
		-- Reduce durability based on damage
		self.Durability = (self.Durability or self.MaxDurability) - damage
		self:EmitSound("Canister.ImpactHard", 65, 90)
		self:UpdateWireOutputs()
		
		-- Check if cannon should blow up from damage
		-- Higher chance with more damage and lower durability
		local durabilityPercent = (self.Durability or 0) / (self.MaxDurability or 1000)
		local blowUpChance = math.max(0, (damage / 50) * (1 - durabilityPercent))
		
		if JMod.LinCh(blowUpChance * 100, 0, 100) then
			local projectileToDetonate = nil
			if IsValid(self.LoadedProjectileEnt) then
				projectileToDetonate = self.LoadedProjectileEnt
				if IsValid(self.CannonProjectileNoCollide) then
					self.CannonProjectileNoCollide:Remove()
					self.CannonProjectileNoCollide = nil
				end
				projectileToDetonate:SetParent(nil)
				projectileToDetonate:SetNotSolid(false)
				projectileToDetonate:SetNoDraw(false)
				projectileToDetonate:SetMoveType(MOVETYPE_VPHYSICS)
				local po = projectileToDetonate:GetPhysicsObject()
				if IsValid(po) then
					po:EnableMotion(true)
					po:Wake()
				end
				projectileToDetonate:SetPos(self:GetPos())
				self.LoadedProjectileEnt = nil
			end

			self:BlowUp(true, projectileToDetonate)
		end
		
		-- Check if durability is below 0 and destroy
		if self.Durability <= 0 then
			self:EmitSound("snd_jack_turretbreak.ogg", 70, math.random(80, 120))
			for i = 1, 20 do
				JMod.DamageSpark(self)
			end
			self:Destroy(dmginfo)
			return
		end

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

		if IsValid(self.LoadedProjectileEnt) and self.LoadedProjectileType then
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
			net.WriteString(IsValid(self.LoadedProjectileEnt) and (self.LoadedProjectileType or "") or "")
			net.WriteUInt(self.Propellant, 8)
			net.WriteUInt(self.CurrentPropellantPerShot, 8)
			net.WriteUInt(self.ProjectileMass or 0, 16)
			net.Send(activator)
		else
			self:LaunchProjectile(false, activator)
		end
	end

	function ENT:Think()
		local Time = CurTime()
		if self.NextIdle and Time >= self.NextIdle then
			if IsValid(self.LoadedProjectileEnt) then
				self:ResetSequence(self.IdleSequence)
			else
				self:ResetSequence(self.IdleEmptySequence)
			end
			self.NextIdle = Time + 1
		elseif self.ProjectileBone and IsValid(self.LoadedProjectileEnt) then
			local bonePos, boneAng = self:GetBonePosition(self:LookupBone(self.ProjectileBone))
			local Specs = self.ProjectileSpecs[self.LoadedProjectileType]
			local LaunchOffset = Specs.LaunchOffset or vector_origin
			self.LoadedProjectileEnt:SetLocalPos(self:WorldToLocal(bonePos) + LaunchOffset)
		end
		self:NextThink(Time)
		return true
	end

	function ENT:PreEntityCopy()
		self.DupeLoadedProjectileType = self.LoadedProjectileType
		self.DupePropellant = self.Propellant
		self.DupePropModel = self.PropModel
		self.DupeCurrentPropellantPerShot = self.CurrentPropellantPerShot
		self.DupeProjectileMass = self.ProjectileMass
		self.DupeDurability = self.Durability
		self.DupeMaxDurability = self.MaxDurability
		if IsValid(self.LoadedProjectileEnt) then
			self.DupeLoadedProjectileEntIndex = self.LoadedProjectileEnt:EntIndex()
		else
			self.DupeLoadedProjectileEntIndex = nil
		end
	end

	function ENT:PostEntityPaste(ply, ent, createdEnts)
		local Time = CurTime()
		ent.NextLaunchTime = Time + 1
		ent.Propellant = ent.DupePropellant or 0
		ent.CurrentPropellantPerShot = ent.DupeCurrentPropellantPerShot or ent.DefaultPropellantPerShot
		ent.ProjectileMass = ent.DupeProjectileMass or 0
		ent.Durability = ent.DupeDurability or (ent.MaxDurability or 100)
		ent.MaxDurability = ent.DupeMaxDurability or 100
		ent.LoadedProjectileType = nil
		ent.PropModel = ent.DupePropModel
		ent.LoadedProjectileEnt = nil
		ent.CannonProjectileNoCollide = nil
		ent.EZlaunchableWeaponLoadTime = nil

		local pastedProj = ent.DupeLoadedProjectileEntIndex and createdEnts[ent.DupeLoadedProjectileEntIndex]
		if IsValid(pastedProj) and ent.DupeLoadedProjectileType and ent.DupeLoadedProjectileType ~= "" then
			pastedProj.EZalreadyLoaded = false
			if ent:FinishLoadingProjectile(pastedProj, ent.DupeLoadedProjectileType) then
				ent.EZlaunchableWeaponLoadTime = Time
			else
				ent.LoadedProjectileType = nil
				ent.PropModel = nil
			end
		else
			ent.LoadedProjectileType = nil
			ent.PropModel = nil
		end

		JMod.SetEZowner(ent, ply, true)
		ent:SyncStateToClients()
	end

elseif CLIENT then
	local MetalMat = Material("phoenix_storms/metal_plate")
	function ENT:Initialize()
		self.LoadedProjectileType = nil
		self.Propellant = 0
		self.PropModel = nil
		self.CurrentPropellantPerShot = self.CurrentPropellantPerShot or self.DefaultPropellantPerShot
		self.ProjectileMass = 0
		self.ProjectileSpecs = self.ProjectileSpecs or ProjectileSpecs
		
		-- Custom model initialization
		self:DrawShadow(true)
		self.Hatch = JMod.MakeModel(self, "models/props_phx/construct/metal_plate_curve180x2.mdl", "phoenix_storms/metal_plate")
		self.Breech = JMod.MakeModel(self, "models/props_phx/construct/metal_angle360.mdl", "phoenix_storms/metal_plate")
		
		-- Animation variables
		self.HatchAngle = 0
		self.BreechSlide = 0
		self.HatchTargetAngle = 0
		self.BreechTargetSlide = 0

		-- To stop the breech and hatch from disappearing
		local mins, maxs = self:GetRenderBounds()
		self:SetRenderBounds(mins + Vector(-22, 0, 0), maxs + Vector(22, 0, 0))
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
			if self:GetPowder() >= self.CurrentPropellantPerShot then
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
		local DetailDraw = true--Closeness < 120000 -- cutoff point is 400 units when the fov is 90 degrees
		
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
