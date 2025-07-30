--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_aboot_ezcannon_shot"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "glhfggwpezpznore"
ENT.PrintName = "EZ Cannon Shot Ceramic"
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.Model = "models/props_phx/misc/smallcannonball.mdl"
ENT.Material = "models/props_building_details/courtyard_template001c_bars"
ENT.ModelScale = nil
ENT.ImpactSound = "Boulder.Impact"
ENT.CollisionGroup = COLLISION_GROUP_NONE
ENT.JModEZstorable = true

-- Base class configurable collision behavior
ENT.CollisionSpeedThreshold = 800
ENT.CollisionRequiresArmed = true
ENT.CollisionDelay = 0
ENT.FuseTime = 100
ENT.TrailEffectScale = 3
ENT.TrailSoundVolume = 65
ENT.CreateTrailEffect = false
ENT.Mass = 35 -- Ceramic is lighter than metal

if SERVER then
	function ENT:Detonate(collisionData)
		-- Do some shrapnel
		local Attacker = JMod.GetEZowner(self)
		local Pos = (collisionData and collisionData.HitPos + collisionData.HitNormal * -10) or self:GetPos()
		JMod.FragSplosion(self, Pos + Vector(0, 0, 10), 1000, 100, 300, Attacker, nil, nil, nil, true)
		JMod.WreckBuildings(self, Pos, 1, 1, true)
		-- Break like a rock
		self:EmitSound("Boulder.Break")
		self:Remove()
	end

elseif CLIENT then
	function ENT:Initialize()
		self.NoDrawTime = CurTime() + .5
	end

	function ENT:Draw()
		self:DrawModel()
	end
end
