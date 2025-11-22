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

ENT.DefaultPropellantPerShot = 10
ENT.MaxPropellant = 50 
ENT.BarrelLength = 40
--ENT.PropellantForce = 5000
ENT.MaxPropellantForce = 500000
ENT.TargetPropellant = 40
ENT.TargetPercentage = .8
ENT.FireDelay = 1
ENT.Spread = 0.001
ENT.MaxPropSize = Vector(45, 6, 6) -- Max dimensions: largest, second largest, smallest (smaller than main cannon)

ENT.ProjectileSpecs = {
	["prop_physics"] = {
		UsePropModel = true
	},
	["ent_jack_gmod_ezherocket"] = {
		ArmDelay = .5,
		LaunchOffset = 10,
		ForceMult = 2
	},
	["ent_jack_gmod_ezheatrocket"] = {
		ArmDelay = .5,
		LaunchOffset = 10,
		ForceMult = 2
	},
	["ent_jack_gmod_ezstickynade"] = {
		ArmDelay = .05
	},
	["ent_jack_gmod_ezfragnade"] = {
		ArmDelay = 0
	},
	["ent_jack_gmod_ezimpactnade"] = {
		ArmDelay = 0
	},
	["ent_jack_gmod_ezfirenade"] = {
		ArmDelay = .05
	},
	["ent_jack_gmod_ezflashbang"] = {
		ArmDelay = .05
	},
	["ent_jack_gmod_ezsmokegrenade"] = {
		ArmDelay = .05
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
	JMod.EZ_RESOURCE_TYPES.EXPLOSIVES,
	JMod.EZ_RESOURCE_TYPES.CHEMICALS,
	JMod.EZ_RESOURCE_TYPES.PAPER,
	JMod.EZ_RESOURCE_TYPES.STEEL,
	JMod.EZ_RESOURCE_TYPES.LEAD,
	JMod.EZ_RESOURCE_TYPES.TITANIUM,
	JMod.EZ_RESOURCE_TYPES.COPPER,
	JMod.EZ_RESOURCE_TYPES.URANIUM,
	JMod.EZ_RESOURCE_TYPES.SILVER,
	JMod.EZ_RESOURCE_TYPES.GOLD,
	JMod.EZ_RESOURCE_TYPES.PLATINUM,
	JMod.EZ_RESOURCE_TYPES.RUBBER,
	JMod.EZ_RESOURCE_TYPES.TUNGSTEN,
	JMod.EZ_RESOURCE_TYPES.CERAMIC,
	JMod.EZ_RESOURCE_TYPES.ANTIMATTER
}

if CLIENT then
	-- Override client initialization for custom models
	function ENT:Initialize()
		self.LoadedProjectileType = nil
		self.Propellant = 0
		self.PropModel = nil
		self.CurrentPropellantPerShot = self.DefaultPropellantPerShot
		self.ProjectileSpecs = self.ProjectileSpecs
		
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