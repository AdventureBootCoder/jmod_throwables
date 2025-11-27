--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_aboot_ezcannon_shot"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "Plasma cannon ball that ignores gravity"
ENT.PrintName = "Shot Plasma"
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.Model = "models/props_phx/misc/smallcannonball.mdl"
ENT.Material = "models/props_combine/stasisshield_sheet"
ENT.ModelScale = nil
ENT.ImpactSound = "Grenade.ImpactHard"
ENT.CollisionGroup = COLLISION_GROUP_NONE
ENT.JModEZstorable = true

ENT.CollisionSpeedThreshold = 100
ENT.CollisionRequiresArmed = true
ENT.CollisionDelay = 0
ENT.FuseTime = 3
ENT.TrailEffectScale = 2
ENT.TrailSoundVolume = 45
ENT.PlasmaRadius = 250
ENT.PlasmaPower = 1

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "IsArmed")
end

if SERVER then
	function ENT:Initialize()
		self:SetModel(self.Model)
		self:SetMaterial(self.Material)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:DrawShadow(true)
		
		-- Disable gravity for plasma effect
		self:GetPhysicsObject():EnableGravity(false)
		self:GetPhysicsObject():EnableDrag(false)

		timer.Simple(0, function()
			if IsValid(self) then
				self:GetPhysicsObject():SetMass(25) -- Lighter mass for plasma
			end
		end)
	end

	-- Custom trail effect for plasma
	function ENT:CreateTrailEffect()
		local vel = self:GetVelocity()
		local pos = self:GetPos()
		local backPos = pos - vel:GetNormalized() * 20
		sound.Play("ambient/energy/zap" .. math.random(1, 3) .. ".wav", pos, 75, math.Rand(90, 110))

		-- Electrical Arc effects
		local ElectricEffect = EffectData()
		ElectricEffect:SetEntity(self)
		ElectricEffect:SetScale(1)
		ElectricEffect:SetRadius(200)
		util.Effect("aboot_tesla_arc", ElectricEffect, true)
		
		self:EmitSound("snd_jack_sss.wav", 45, math.Rand(90, 110))
	end

	function ENT:Detonate(collisionData)
		if self.Sploomd then return end
		self.Sploomd = true
		-- Do plasma damage instead of explosive
		local Attacker = JMod.GetEZowner(self)
		local Pos = (collisionData and collisionData.HitPos + collisionData.HitNormal * -10) or self:GetPos()
		
		JMod.AntimatterExplosion(Pos, Attacker, self.PlasmaPower, self.PlasmaRadius)
		-- Plasma sound
		self:EmitSound("ambient/energy/zap" .. math.random(1, 3) .. ".wav", 85, math.Rand(90, 110))
		
		self:Remove()
	end

elseif CLIENT then
	function ENT:Initialize()
		self.NoDrawTime = CurTime() + .5
		self.EffectRadius = 50
	end

	local glowmat = Material("sprites/light_glow02_add")
	local LightningMat = Material("cable/blue_elec")
	function ENT:Draw()
		self:DrawModel()
		
		-- Add plasma glow effect
		if self:GetIsArmed() then
			local pos = self:LocalToWorld(Vector(-7, 0, 0))
			local size = 50
			render.SetMaterial(glowmat)
			render.DrawSprite(pos, size, size, Color(255, 0, 242, 100))

			--[[for i = 1, 5 do
				local trace = util.TraceLine({
					start = pos,
					endpos = pos + VectorRand() * self.EffectRadius,
					filter = self
				})
				render.SetMaterial(LightningMat)
				render.StartBeam(3)
				render.AddBeam(pos, 10, 0, Color(100, 150, 255))
				local Halfway = pos + (trace.HitPos - pos) / 2
				render.AddBeam(Halfway + VectorRand() * self.EffectRadius * 0.25, 10, .5, Color(100, 150, 255))
				render.AddBeam(trace.HitPos, 10, 1, Color(100, 150, 255))
				render.EndBeam()
			end--]]
		end
	end
end 