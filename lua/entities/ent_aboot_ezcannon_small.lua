--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_aboot_ezcannon"
ENT.Author = "Jackarunda, AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "EZ method for loading rockets and grenades"
ENT.PrintName = "EZ Cannon (Small)"
ENT.Spawnable = true
ENT.AdminSpawnable = false

-- Override properties for smaller cannon
ENT.JModPreferredCarryAngles = Angle(90, 0, 0)
ENT.EZbuoyancy = .3
ENT.Mass = 150 -- Lighter than the main cannon
ENT.Model = "models/props_phx/misc/potato_launcher.mdl"

-- Override propellant settings for smaller cannon
ENT.DefaultPropellantPerShot = 10 -- Less propellant per shot
ENT.MaxPropellant = 100 -- Smaller propellant capacity
ENT.BarrelLength = 40

ENT.ProjectileSpecs = {
	BaseClass = nil,
	["prop_physics"] = {
		UsePropModel = true
	},
	["ent_jack_gmod_ezherocket"] = {
		ArmDelay = .1
	},
	["ent_jack_gmod_ezheatrocket"] = {
		ArmDelay = .1
	},
	["ent_jack_gmod_ezsmallbomb"] = {
		ArmDelay = 1
	},
	["ent_jack_gmod_ezstickynade"] = {
		ArmDelay = .1
	},
	["ent_jack_gmod_ezfragnade"] = {
		ArmDelay = .1
	},
	["ent_jack_gmod_ezimpactnade"] = {
		ArmDelay = .1
	},
	["ent_jack_gmod_ezfirenade"] = {
		ArmDelay = .1
	},
	["ent_jack_gmod_ezflashbang"] = {
		ArmDelay = .1
	},
	["ent_jack_gmod_ezsmokegrenade"] = {
		ArmDelay = .1
	},
	["ent_jack_gmod_ezroadflare"] = {
		ArmDelay = 1
	},
	["ent_jack_gmod_ezflareprojectile"] = {
		ForceMult = .1
	}
}

-- Override EZconsumes to remove some expensive resources
ENT.EZconsumes = {
	JMod.EZ_RESOURCE_TYPES.BASICPARTS,
	JMod.EZ_RESOURCE_TYPES.PROPELLANT,
	JMod.EZ_RESOURCE_TYPES.CHEMICALS,
	JMod.EZ_RESOURCE_TYPES.PAPER,
	JMod.EZ_RESOURCE_TYPES.STEEL,
	JMod.EZ_RESOURCE_TYPES.LEAD
}

if SERVER then
	-- Override prop suitability check for smaller projectiles
	function ENT:IsPropSuitable(prop)
		if not IsValid(prop) or prop:GetClass() ~= "prop_physics" then return false end
		
		-- Get the model bounds
		local mins, maxs = prop:GetCollisionBounds()
		local size = maxs - mins
		
		-- Check if any two sides are greater than 6 units (smaller than main cannon)
		local sides = {size.x, size.y, size.z}
		table.sort(sides, function(a, b) return a > b end)
		
		-- If the two largest sides are both > 6, reject the prop
		if sides[1] > 6 and sides[2] > 6 and sides[3] > 15 then
			return false
		end
		
		return true
	end
end

if CLIENT then
	-- Override client initialization for custom models
	function ENT:Initialize()
		self.LoadedProjectileType = nil
		self.Propellant = 0
		self.PropModel = nil
		self.CurrentPropellantPerShot = self.DefaultPropellantPerShot
		
		-- Custom model initialization for small cannon
		self:DrawShadow(true)
		
		-- Create custom models for small cannon
		self.Chamber = JMod.MakeModel(self, "models/props_phx/misc/potato_launcher_chamber.mdl", "phoenix_storms/metal_plate")
		self.Cap = JMod.MakeModel(self, "models/props_phx/misc/potato_launcher_cap.mdl", "phoenix_storms/metal_plate")
		
		-- Animation variables
		self.ChamberAngle = 0
		self.CapAngle = 0
		self.ChamberTargetAngle = 0
		self.CapTargetAngle = 0
		self.ChamberPos = Vector(0, 0, 0)
		self.CapPos = Vector(0, 0, 0)
		self.ChamberTargetPos = Vector(0, 0, 0)
		self.CapTargetPos = Vector(0, 0, 0)

		local mins, maxs = self:GetRenderBounds()
		self:SetRenderBounds(mins + Vector(-3, -3, -32), maxs + Vector(13, 3, 0))
	end

	function ENT:Think()
		local FT = FrameTime()
		
		-- Smooth animation for chamber
		self.ChamberAngle = Lerp(FT * 8, self.ChamberAngle, self.ChamberTargetAngle)
		self.ChamberPos = Lerp(FT * 8, self.ChamberPos, self.ChamberTargetPos)
		-- Smooth animation for cap
		self.CapAngle = Lerp(FT * 8, self.CapAngle, self.CapTargetAngle)
		self.CapPos = Lerp(FT * 8, self.CapPos, self.CapTargetPos)
		-- Update target angles based on cannon state
		if self.LoadedProjectileType and self.LoadedProjectileType ~= "" then
			-- Chamber closed when loaded
			self.ChamberTargetAngle = 0
			self.ChamberTargetPos = Vector(0, 0, 0)
		else
			-- Chamber open when not loaded
			self.ChamberTargetAngle = 90
			self.ChamberTargetPos = Vector(0, 8, 0)
		end
		
		-- Update cap based on propellant availability
		if self.Propellant and self.CurrentPropellantPerShot then
			if self.Propellant >= self.CurrentPropellantPerShot then
				-- Cap closed when enough propellant
				self.CapTargetPos = Vector(0, 0, 0)
			self.CapTargetAngle = 0
			else
				-- Cap open when not enough propellant
				self.CapTargetAngle = 90
				self.CapTargetPos = Vector(0, 7, -5)
			end
		else
			-- Cap open when no propellant info
			self.CapTargetAngle = 90
			self.CapTargetPos = Vector(0, 5, -5)
		end
	end

	-- Override draw function for custom model rendering
	function ENT:Draw()
		self:DrawModel()
		
		-- Get entity position and angles
		local SelfPos, SelfAng = self:GetPos(), self:GetAngles()
		local Up, Right, Forward = SelfAng:Up(), SelfAng:Right(), SelfAng:Forward()
		
		-- Calculate detail draw based on distance
		local Closeness = LocalPlayer():GetFOV() * (EyePos():Distance(SelfPos))
		local DetailDraw = Closeness < 120000 -- cutoff point is 400 units when the fov is 90 degrees
		
		if DetailDraw then
			-- Render chamber model
			local ChamberPos = SelfPos + Up * self.ChamberPos.z + Right * self.ChamberPos.x + Forward * self.ChamberPos.y
			local ChamberAng = SelfAng:GetCopy()
			ChamberAng:RotateAroundAxis(Up, self.ChamberAngle)
			if IsValid(self.Chamber) then
				JMod.RenderModel(self.Chamber, ChamberPos, ChamberAng, Vector(0.8, 0.8, 0.8), nil, nil)
			end
			
			-- Render cap model (parented to chamber)
			if IsValid(self.Cap) then
				local CapPos = ChamberPos + Up * (-18 + (1 * self.CapPos.z)) + Right * self.CapPos.x + Forward * self.CapPos.y
				local CapAng = SelfAng:GetCopy()
				CapAng:RotateAroundAxis(Right, self.CapAngle) -- Add cap rotation
				JMod.RenderModel(self.Cap, CapPos, CapAng, Vector(0.8, 0.8, 0.8), nil, nil)
			end
		end
	end

	function ENT:OnRemove()
		-- Clean up custom models
		if IsValid(self.Chamber) then
			self.Chamber:Remove()
		end
		if IsValid(self.Cap) then
			self.Cap:Remove()
		end
	end
end 