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
	["ent_aboot_ezcannon_shot_tungsten"] = true,
	["prop_physics"] = true -- Allow props too
}

ENT.MaxCapacity = 10 -- Maximum number of explosives that can be stored

function ENT:CustomSetupDataTables()
	self:NetworkVar("Int", 2, "LoadedCount")
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
		self.EZpowerSocket = Vector(0, 0, 20) -- Connection point for cables
		self.ConnectionResourceType = "Entity" -- Use Entity as resource type for connections
		self:SetLoadedCount(0)
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
					else
						-- Otherwise, load the first explosive in the list
						ConnectedEnt:TryLoadProjectileClass(self.LoadedExplosives[1])
						self:UnloadExplosive(1)
					end
				end
				if #self.LoadedExplosives <= 0 then break end
			end
		end
	end

	function ENT:SetupWire()
		if not(istable(WireLib)) then return end
		local WireInputs = {"Toggle [NORMAL]", "On-Off [NORMAL]"}
		local WireInputDesc = {"Greater than 1 toggles machine on and off", "1 turns on, 0 turns off"}
		self.Inputs = WireLib.CreateInputs(self, WireInputs, WireInputDesc)
		
		local WireOutputs = {"State [NORMAL]", "Grade [NORMAL]", "Loaded [NORMAL]", "Capacity [NORMAL]"}
		local WireOutputDesc = {"The state of the machine \n-1 is broken \n0 is off \n1 is on", "The machine grade", "Number of loaded explosives", "Maximum capacity"}
		self.Outputs = WireLib.CreateOutputs(self, WireOutputs, WireOutputDesc)
	end

	function ENT:UpdateWireOutputs()
		if not istable(WireLib) then return end
		WireLib.TriggerOutput(self, "State", self:GetState())
		WireLib.TriggerOutput(self, "Grade", self:GetGrade())
		WireLib.TriggerOutput(self, "Loaded", #self.LoadedExplosives)
		WireLib.TriggerOutput(self, "Capacity", self.MaxCapacity)
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
		self:SetState(JMod.EZ_STATE_ON)
		if IsValid(dude) then
			self.EZstayOn = true
		end
	end

	function ENT:TurnOff(dude)
		if self:GetState() ~= JMod.EZ_STATE_ON then return end
		self:SetState(JMod.EZ_STATE_OFF)
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

	function ENT:OnRemove()
		if IsValid(self.EZconnectorPlug) then SafeRemoveEntity(self.EZconnectorPlug) end
	end

	function ENT:Think()
		local Time, State = CurTime(), self:GetState()
		
		-- Distribute explosives to connected cannons
		if State == JMod.EZ_STATE_ON and #self.LoadedExplosives > 0 then
			self:DistributeExplosives()
		end
		
		self:NextThink(Time + 1)
		return true
	end

	function ENT:PostEntityPaste(ply, ent, createdEntities)
		self.BaseClass.PostEntityPaste(self, ply, ent, createdEntities)
		self.LoadedExplosives = {}
		self:SetLoadedCount(0)
	end

elseif CLIENT then
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
			local LadderPos = SelfPos + Up * 20 + Forward * 20
			local LadderAng = SelfAng:GetCopy()
			
			if State ~= JMod.EZ_STATE_BROKEN then
				-- Show ladder when not broken
				JMod.RenderModel(self.Ladder, LadderPos, LadderAng, nil, Vector(1, 1, 1))
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

				cam.Start3D2D(SelfPos + Forward * 25 + Up * 20, DisplayAng, .08)
				draw.SimpleTextOutlined("AUTOLOADER", "JMod-Display", 0, 0, Color(200, 255, 255, Opacity), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3, Color(0, 0, 0, Opacity))
				draw.SimpleTextOutlined(tostring(Loaded) .. "/" .. tostring(Capacity), "JMod-Display", 0, 30, Color(R, G, B, Opacity), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3, Color(0, 0, 0, Opacity))
				if State == JMod.EZ_STATE_ON then
					draw.SimpleTextOutlined("ON", "JMod-Display", 0, 60, Color(200, 255, 255, Opacity), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3, Color(0, 0, 0, Opacity))
				elseif State == JMod.EZ_STATE_OFF then
					draw.SimpleTextOutlined("OFF", "JMod-Display", 0, 60, Color(200, 255, 255, Opacity), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3, Color(0, 0, 0, Opacity))
				end
				cam.End3D2D()
			end
		end
		
		language.Add("ent_aboot_ezautoloader", "EZ Autoloader")
	end
end

