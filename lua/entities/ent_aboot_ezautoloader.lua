--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_jack_gmod_ezmachine_base"
ENT.PrintName = "EZ Autoloader"
ENT.Author = "Jackarunda, AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "EZ method for loading cannons"
ENT.Spawnable = true
ENT.AdminSpawnable = true
----
ENT.JModPreferredCarryAngles = Angle(0, 0, 0)
ENT.EZcolorable = false
ENT.EZlowFragPlease = true
ENT.EZbuoyancy = .3
ENT.Mass = 300
ENT.Model = "models/props_junk/TrashDumpster01a.mdl"
ENT.MaxConnectionRange = 200
ENT.EZupgradable = false
----
ENT.StaticPerfSpecs = {
	MaxElectricity = 100,
	MaxDurability = 100,
	Armor = 2
}

--[[ TODO:
- Fix the autoload checkbox and validate it works with wiremod and through the autoloader gui
- Balance autoloader durability and energy consumption
--]]

-- Valid explosive classes that can be loaded
local ValidExplosiveClasses = {
	["ent_jack_gmod_ezincendiarybomb"] = true,
	["ent_jack_gmod_ezthermobaricbomb"] = true,
	["ent_jack_gmod_ezclusterbomb"] = true,
	["ent_jack_gmod_ezsmallbomb"] = true,
	["ent_jack_gmod_ezhebomb"] = true,
	["ent_jack_gmod_ezfumigator"] = true,
	["ent_jack_gmod_ezflareprojectile"] = true,
	["ent_jack_gmod_eznuke_small"] = true,
	["ent_jack_gmod_ezcriticalityweapon"] = true,
	["ent_jack_gmod_ezpowderkeg"] = true,
	["ent_aboot_ezcannon_shot"] = true,
	["ent_aboot_ezcannon_shot_plasma"] = true,
	["ent_aboot_ezcannon_shot_cannister"] = true,
	["ent_aboot_ezcannon_shot_angler"] = true,
	["ent_aboot_ezcannon_shot_ceramic"] = true,
	["ent_aboot_ezcannon_shot_copper"] = true,
	["ent_aboot_ezcannon_shot_uranium"] = true,
	["ent_aboot_ezcannon_shot_silver"] = true,
	["ent_aboot_ezcannon_shot_gold"] = true,
	["ent_aboot_ezcannon_shot_platinum"] = true,
	["ent_aboot_ezcannon_shot_rubber"] = true,
	["ent_aboot_ezcannon_shot_tungsten"] = true--,
	--["prop_physics"] = true -- Allow props too
}

ENT.MaxCapacity = 10 -- Maximum number of explosives that can be stored
ENT.MaxPropellant = 1000 -- Maximum propellant storage capacity

function ENT:CustomSetupDataTables()
	self:NetworkVar("Int", 2, "LoadedCount")
	self:NetworkVar("Int", 3, "Propellant")
end

if SERVER then
	function ENT:SpawnFunction(ply, tr)
		local SpawnPos = tr.HitPos + tr.HitNormal * 20
		local ent = ents.Create(self.ClassName)
		ent:SetPos(SpawnPos)
		JMod.SetEZowner(ent, ply)
		ent:Spawn()
		ent:Activate()
		JMod.Hint(JMod.GetEZowner(ent), "ent_aboot_ezautoloader")
		return ent
	end

	function ENT:CustomInit()
		self.NextUseTime = 0
		self.LoadedExplosives = {}
		self.Propellant = 0
		self.EZpowerSocket = Vector(0, 0, 20) -- Connection point for cables
		self.ConnectionResourceType = "Entity" -- Use Entity as resource type for connections
		self.EZconsumes = {JMod.EZ_RESOURCE_TYPES.PROPELLANT, JMod.EZ_RESOURCE_TYPES.POWER} -- Allow propellant and power to be loaded via resource connections
		self.ShouldBeOn = false -- Remember if we should turn back on when power returns
		self:SetLoadedCount(0)
		self:SetPropellant(0)
	end

	function ENT:Use(activator)
		if self.NextUseTime > CurTime() then return end
		local State = self:GetState()
		local IsPly = (IsValid(activator) and activator:IsPlayer())
		local Alt = IsPly and JMod.IsAltUsing(activator)
		JMod.SetEZowner(self, activator)

		if State == JMod.EZ_STATE_BROKEN then
			JMod.Hint(activator, "destroyed", self)
			return
		end

		if Alt then
			self:ModConnections(activator)
		else
			if State == JMod.EZ_STATE_ON then
				self:TurnOff(activator)
			elseif State == JMod.EZ_STATE_OFF then
				self:TurnOn(activator)
			end
			JMod.Hint(activator, "autoloader")
		end
	end

	function ENT:PhysicsCollide(data, physobj)
		if data.DeltaTime < 0.2 then return end
		if data.Speed < 50 then return end
		if not IsValid(self) then return end
		if self:GetState() == JMod.EZ_STATE_BROKEN then return end
		
		local ent = data.HitEntity
		if not IsValid(ent) then return end
		
		-- Check if entity is constrained
		if constraint.HasConstraints(ent) then return end
		
		-- Check if it's a valid explosive
		local EntClass = ent:GetClass()
		if not ValidExplosiveClasses[EntClass] then return end
		
		-- Check if player is holding it (like bomb bay)
		if not (ent:IsPlayerHolding() or JMod.Config.ResourceEconomy.ForceLoadAllResources) then return end
		
		-- Check capacity
		if #self.LoadedExplosives >= self.MaxCapacity then return end
		
		-- Load the explosive
		self:LoadExplosive(ent)
	end

	function ENT:LoadExplosive(explosive)
		if not IsValid(explosive) then return end
		
		local ExplosiveClass = explosive:GetClass()
		
		-- Add to loaded table
		table.insert(self.LoadedExplosives, ExplosiveClass)
		self:SetLoadedCount(#self.LoadedExplosives)
		
		self:EmitSound("snd_jack_metallicload.ogg", 65, 90)
		
		timer.Simple(0.1, function()
			if IsValid(explosive) then
				SafeRemoveEntity(explosive)
			end
		end)
		
		self:UpdateWireOutputs()
	end

	function ENT:UnloadExplosive(index)
		if #self.LoadedExplosives <= 0 then return nil end
		
		local ExplosiveClass = table.remove(self.LoadedExplosives, index or 1)
		self:SetLoadedCount(#self.LoadedExplosives)
		
		self:EmitSound("snd_jack_metallicclick.ogg", 65, 90)
		self:UpdateWireOutputs()
		
		return ExplosiveClass
	end

	function ENT:DisconnectAll()
		JMod.RemoveResourceConnection(self)
	end

	function ENT:DistributeExplosives()
		if #self.LoadedExplosives <= 0 then return end
		
		-- Check if we have enough power (consume 5 power per explosive loaded)
		local PowerNeeded = 5
		if not self:GetElectricity() or self:GetElectricity() < PowerNeeded then
			return -- Not enough power
		end
		
		-- Find connected cannons
		for _, cable in pairs(constraint.FindConstraints(self, "JModResourceCable")) do
			local ConnectedEnt = cable.Ent1 == self and cable.Ent2 or cable.Ent1

			if IsValid(ConnectedEnt) and ConnectedEnt.GetIsAutoLoading and ConnectedEnt:GetIsAutoLoading() then
				-- Check if cannon needs ammo
				if not ConnectedEnt:GetLoadedProjectileType() then 
					-- Check if the cannon has a preferred projectile type
					local ProjectileToLoad = ConnectedEnt:GetDesiredProjectileClass()

					if ProjectileToLoad and table.HasValue(self.LoadedExplosives, ProjectileToLoad) then
						ConnectedEnt:TryLoadProjectileClass(ProjectileToLoad)
						self:UnloadExplosive(table.KeyFromValue(self.LoadedExplosives, ProjectileToLoad))
						-- Consume power for loading explosive
						self:ConsumeElectricity(PowerNeeded)
					else
						-- Otherwise, load the first explosive in the list
						ConnectedEnt:TryLoadProjectileClass(self.LoadedExplosives[1])
						self:UnloadExplosive(1)
						-- Consume power for loading explosive
						self:ConsumeElectricity(PowerNeeded)
					end
				end
				if #self.LoadedExplosives <= 0 then break end
				
				-- Check power again before continuing
				if not self:GetElectricity() or self:GetElectricity() < PowerNeeded then
					break -- Out of power
				end
			end
		end
	end

	function ENT:DistributePropellant()
		local Propellant = self:GetPropellant()
		if Propellant <= 0 then return end
		
		-- Check if we have enough power (consume 1 power per propellant distribution cycle)
		local PowerNeeded = 1
		if not self:GetElectricity() or self:GetElectricity() < PowerNeeded then
			return -- Not enough power
		end
		
		local PropellantDistributed = false
		
		-- Find connected cannons
		for _, cable in pairs(constraint.FindConstraints(self, "JModResourceCable")) do
			local ConnectedEnt = cable.Ent1 == self and cable.Ent2 or cable.Ent1
			
			if IsValid(ConnectedEnt) and ConnectedEnt.GetIsAutoLoading and ConnectedEnt:GetIsAutoLoading() then
				-- Check if cannon needs propellant
				-- Only fill up to CurrentPropellantPerShot (not MaxPropellant)
				local TargetPropellant = ConnectedEnt.CurrentPropellantPerShot or ConnectedEnt.DefaultPropellantPerShot or 20
				local CurrentPropellant = ConnectedEnt.Propellant or 0
				
				if CurrentPropellant < TargetPropellant then
					local Needed = TargetPropellant - CurrentPropellant
					local ToGive = math.min(Needed, Propellant)
					
					if ToGive > 0 and ConnectedEnt.TryLoadResource then
						local Accepted = ConnectedEnt:TryLoadResource(JMod.EZ_RESOURCE_TYPES.PROPELLANT, ToGive)
						if Accepted > 0 then
							self:SetPropellant(Propellant - Accepted)
							Propellant = self:GetPropellant()
							PropellantDistributed = true
							if Propellant <= 0 then break end
						end
					end
				end
			end
		end
		
		-- Consume power only if we actually distributed propellant
		if PropellantDistributed then
			self:ConsumeElectricity(PowerNeeded)
		end
	end

	function ENT:TryLoadResource(typ, amt)
		if amt <= 0 then return 0 end
		local Time = CurTime()
		if self.NextRefillTime and self.NextRefillTime > Time then return 0 end
		
		if typ == JMod.EZ_RESOURCE_TYPES.PROPELLANT then
			local SpaceLeft = self.MaxPropellant - self:GetPropellant()
			local ToLoad = math.min(amt, SpaceLeft)
			
			if ToLoad > 0 then
				self:SetPropellant(self:GetPropellant() + ToLoad)
				self.NextRefillTime = CurTime() + 0.1
				self:EmitSound("snd_jack_metallicload.ogg", 65, 90)
				self:UpdateWireOutputs()
				return ToLoad
			end
		elseif typ == JMod.EZ_RESOURCE_TYPES.POWER then
			local SpaceLeft = self.MaxElectricity - self:GetElectricity()
			local ToLoad = math.min(amt, SpaceLeft)
			
			if ToLoad > 0 then
				self:SetElectricity(self:GetElectricity() + ToLoad)
				self.NextRefillTime = CurTime() + 0.1
				self:EmitSound("snd_jack_turretbatteryload.ogg", 65, math.random(90, 110))
				self:UpdateWireOutputs()
				return ToLoad
			end
		end
		
		return 0
	end

	function ENT:SetupWire()
		if not(istable(WireLib)) then return end
		local WireInputs = {"Toggle [NORMAL]", "On-Off [NORMAL]"}
		local WireInputDesc = {"Greater than 1 toggles machine on and off", "1 turns on, 0 turns off"}
		self.Inputs = WireLib.CreateInputs(self, WireInputs, WireInputDesc)
		
		local WireOutputs = {"State [NORMAL]", "Grade [NORMAL]", "Loaded [NORMAL]", "Capacity [NORMAL]", "Propellant [NORMAL]", "MaxPropellant [NORMAL]"}
		local WireOutputDesc = {"The state of the machine \n-1 is broken \n0 is off \n1 is on", "The machine grade", "Number of loaded explosives", "Maximum capacity", "Current propellant amount", "Maximum propellant capacity"}
		self.Outputs = WireLib.CreateOutputs(self, WireOutputs, WireOutputDesc)
	end

	function ENT:UpdateWireOutputs()
		if not istable(WireLib) then return end
		WireLib.TriggerOutput(self, "State", self:GetState())
		WireLib.TriggerOutput(self, "Grade", self:GetGrade())
		WireLib.TriggerOutput(self, "Loaded", #self.LoadedExplosives)
		WireLib.TriggerOutput(self, "Capacity", self.MaxCapacity)
		WireLib.TriggerOutput(self, "Propellant", self:GetPropellant())
		WireLib.TriggerOutput(self, "MaxPropellant", self.MaxPropellant)
	end

	function ENT:TriggerInput(iname, value)
		local State, Owner = self:GetState(), JMod.GetEZowner(self)
		if State < 0 then return end
		if iname == "On-Off" then
			if value == 1 then
				self:TurnOn(Owner)
			elseif value == 0 then
				self:TurnOff(Owner)
			end
		elseif iname == "Toggle" then
			if value > 0 then
				if State == 0 then
					self:TurnOn(Owner)
				elseif State > 0 then
					self:TurnOff(Owner)
				end
			end
		end
	end

	function ENT:TurnOn(dude)
		if self:GetState() ~= JMod.EZ_STATE_OFF then return end
		-- Check if we have power before turning on
		if not self:GetElectricity() or self:GetElectricity() <= 0 then
			-- Remember we want to be on, but can't due to lack of power
			self.ShouldBeOn = true
			if IsValid(dude) then
				JMod.Hint(dude, "no power")
			end
			return
		end
		self:SetState(JMod.EZ_STATE_ON)
		self.ShouldBeOn = true -- Remember we want to be on
		if IsValid(dude) then
			self.EZstayOn = true
		end
	end

	function ENT:TurnOff(dude)
		if self:GetState() ~= JMod.EZ_STATE_ON then return end
		self:SetState(JMod.EZ_STATE_OFF)
		self.ShouldBeOn = false -- Remember we want to be off
		if IsValid(dude) then
			self.EZstayOn = nil
		end
	end

	function ENT:ModConnections(dude)
		local Connections = {}
		for _, cable in pairs(constraint.FindConstraints(self, "JModResourceCable")) do
			if (cable.Ent1 == self) and JMod.ConnectionValid(self, cable.Ent2) then
				table.insert(Connections, {DisplayName = cable.Ent2.PrintName or cable.Ent2:GetClass(), Index = cable.Ent2:EntIndex()})
			elseif JMod.ConnectionValid(self, cable.Ent1) then
				table.insert(Connections, {DisplayName = cable.Ent1.PrintName or cable.Ent1:GetClass(), Index = cable.Ent1:EntIndex()})
			else
				JMod.RemoveResourceConnection(self, cable.Ent1)
			end
		end

		if not(IsValid(dude) and dude:IsPlayer()) then return end
		net.Start("JMod_EZAutoloader_ModifyConnections")
			net.WriteEntity(self)
			net.WriteTable(Connections)
		net.Send(dude)
	end

	function ENT:OnDestroy(dmginfo)
		local SelfPos = self:GetPos()
		local Owner = JMod.GetEZowner(self)
		local LeftoverDamage = 0
		
		-- Get leftover damage from dmginfo if available
		if dmginfo then
			LeftoverDamage = dmginfo:GetDamage() or 0
		end
		
		-- Spawn half of the explosives (rounded down)
		local ExplosivesToSpawn = math.floor(#self.LoadedExplosives / 2)
		if ExplosivesToSpawn > 0 then
			for i = 1, ExplosivesToSpawn do
				timer.Simple(i * 0.05, function()
					local ExplosiveClass = self.LoadedExplosives[i]
					if ExplosiveClass then
						local Explosive = ents.Create(ExplosiveClass)
						if IsValid(Explosive) then
							-- Spawn explosive in a random position around the autoloader
							local SpawnOffset = VectorRand() * math.Rand(20, 50)
							local SpawnPos = SelfPos + SpawnOffset
							Explosive:SetPos(SpawnPos)
							Explosive:SetAngles(AngleRand())
							Explosive:Spawn()
							Explosive:Activate()
							JMod.SetEZowner(Explosive, Owner)
							if Explosive.Arm then
								Explosive:Arm()
							end
							
							-- Apply leftover damage to the explosive
							if LeftoverDamage > 0 then
								timer.Simple(0.01, function()
									if IsValid(Explosive) then
										local Dmg = DamageInfo()
										Dmg:SetDamage(LeftoverDamage)
										Dmg:SetDamageType(DMG_BLAST)
										Dmg:SetAttacker(Owner or game.GetWorld())
										Dmg:SetInflictor(self)
										Dmg:SetDamagePosition(SpawnPos)
										Dmg:SetDamageForce(VectorRand() * 1000)
										Explosive:TakeDamageInfo(Dmg)
									end
								end)
							end
							
							-- Give it some velocity
							timer.Simple(0.01, function()
								if IsValid(Explosive) then
									local phys = Explosive:GetPhysicsObject()
									if IsValid(phys) then
										local Vel = SpawnOffset:GetNormalized() * math.Rand(100, 300)
										phys:SetVelocity(Vel)
										phys:ApplyForceCenter(Vel * 10)
									end
								end
							end)
						end
					end
				end)
			end
		end
		
		-- Create explosion based on propellant amount
		local Propellant = self:GetPropellant() or 0
		if Propellant > 0 then
			-- Calculate explosion power based on propellant (scaled appropriately)
			-- Using similar scaling to cannon's BlowUp function
			local ExplosionPower = math.max(10, Propellant * 0.5)
			local ExplosionRadius = math.max(50, Propellant * 2)
			
			-- Create explosion at autoloader position
			JMod.Sploom(Owner, SelfPos, ExplosionPower, ExplosionRadius)
		end
	end

	function ENT:OnRemove()
		if IsValid(self.EZconnectorPlug) then SafeRemoveEntity(self.EZconnectorPlug) end
	end

	function ENT:Think()
		local Time, State = CurTime(), self:GetState()
		
		-- Check if we should turn back on when power returns
		if State == JMod.EZ_STATE_OFF and self.ShouldBeOn then
			if self:GetElectricity() and self:GetElectricity() > 0 then
				-- Power restored, turn back on
				self:SetState(JMod.EZ_STATE_ON)
			end
		end
		
		-- Distribute explosives and propellant to connected cannons
		if State == JMod.EZ_STATE_ON then
			-- Check power before distributing
			if not self:GetElectricity() or self:GetElectricity() <= 0 then
				-- Out of power, turn off but remember we want to be on
				self.ShouldBeOn = true
				self:SetState(JMod.EZ_STATE_OFF)
			else
				if #self.LoadedExplosives > 0 then
					self:DistributeExplosives()
				end
				if self:GetPropellant() > 0 then
					self:DistributePropellant()
				end
			end
		end
		
		self:NextThink(Time + 3)
		return true
	end

	function ENT:PostEntityPaste(ply, ent, createdEntities)
		self.BaseClass.PostEntityPaste(self, ply, ent, createdEntities)
	end

elseif CLIENT then
	local ladder_scale = Vector(1.25, 1.25, 1.25)
	local ladder_mat = Material("models/props_c17/metalladder002b_sheet")
	function ENT:CustomInit()
		self:DrawShadow(true)
		-- Create the ladder model to show broken state
		self.Ladder = JMod.MakeModel(self, "models/props_c17/metalladder002b.mdl")
	end

	function ENT:Draw()
		local SelfPos, SelfAng, State = self:GetPos(), self:GetAngles(), self:GetState()
		local Up, Right, Forward = SelfAng:Up(), SelfAng:Right(), SelfAng:Forward()
		
		local BasePos = SelfPos
		local Obscured = util.TraceLine({start = EyePos(), endpos = BasePos, filter = {LocalPlayer(), self}, mask = MASK_OPAQUE}).Hit
		local Closeness = LocalPlayer():GetFOV() * (EyePos():Distance(SelfPos))
		local DetailDraw = Closeness < 120000 -- cutoff point is 400 units when the fov is 90 degrees
		
		if(Obscured)then DetailDraw = false end -- if obscured, at least disable details
		if(State == JMod.EZ_STATE_BROKEN)then DetailDraw = false end -- look incomplete to indicate damage, save on gpu comp too
		
		self:DrawModel()
		
		-- Draw ladder model when machine is working
		if DetailDraw then
			local LadderPos = SelfPos + Up * 20 + Forward * -12
			local LadderAng = SelfAng:GetCopy()
			LadderAng:RotateAroundAxis(LadderAng:Up(), 0)
			
			if State ~= JMod.EZ_STATE_BROKEN then
				-- Show ladder when not broken
				JMod.RenderModel(self.Ladder, LadderPos, LadderAng, ladder_scale)
			end
		end
		
		-- Display capacity and current load
		if DetailDraw then
			if Closeness < 20000 then
				local DisplayAng = SelfAng:GetCopy()
				DisplayAng:RotateAroundAxis(DisplayAng:Right(), -90)
				DisplayAng:RotateAroundAxis(DisplayAng:Up(), 90)
				local Opacity = math.random(50, 150)
				local Loaded = self:GetLoadedCount() or 0
				local Capacity = self.MaxCapacity or 50
				local LoadFrac = Loaded / Capacity
				local R, G, B = JMod.GoodBadColor(LoadFrac)

				local Propellant = self:GetPropellant() or 0
				local MaxProp = self.MaxPropellant or 1000
				local PropFrac = Propellant / MaxProp
				local PropR, PropG, PropB = JMod.GoodBadColor(PropFrac)
				
				-- Get power level
				local Electricity = self:GetElectricity() or 0
				local MaxElectricity = self.MaxElectricity or 100
				local PowerFrac = MaxElectricity > 0 and (Electricity / MaxElectricity) or 0
				local PowerR, PowerG, PowerB = JMod.GoodBadColor(PowerFrac)
				
				cam.Start3D2D(SelfPos + Forward * 25 + Up * 20, DisplayAng, .08)
				draw.SimpleTextOutlined("AUTOLOADER: " .. (State == JMod.EZ_STATE_ON and "ON" or "OFF"), "JMod-Display", 0, 0, Color(200, 255, 255, Opacity), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3, Color(0, 0, 0, Opacity))
				draw.SimpleTextOutlined(tostring(Loaded) .. "/" .. tostring(Capacity), "JMod-Display", 0, 30, Color(R, G, B, Opacity), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3, Color(0, 0, 0, Opacity))
				draw.SimpleTextOutlined("PROP: " .. tostring(Propellant) .. "/" .. tostring(MaxProp), "JMod-Display", 0, 60, Color(PropR, PropG, PropB, Opacity), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3, Color(0, 0, 0, Opacity))
				draw.SimpleTextOutlined("POWER: " .. math.Round(Electricity) .. "/" .. tostring(MaxElectricity), "JMod-Display", 0, 90, Color(PowerR, PowerG, PowerB, Opacity), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3, Color(0, 0, 0, Opacity))
				cam.End3D2D()
			end
		end
		
		language.Add("ent_aboot_ezautoloader", "EZ Autoloader")
	end
end

