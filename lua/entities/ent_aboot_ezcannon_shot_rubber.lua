--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_aboot_ezcannon_shot"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "Rubber shot that bounces around like crazy"
ENT.PrintName = "EZ Cannon Shot (Rubber)"
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.Model = "models/props_phx/misc/smallcannonball.mdl"
ENT.Material = "phoenix_storms/road"
ENT.ModelScale = nil
ENT.ImpactSound = "Rubber_Tire.ImpactHard"
ENT.CollisionGroup = COLLISION_GROUP_NONE
ENT.JModEZstorable = true

-- Rubber-specific properties
ENT.BounceMultiplier = 2.5
ENT.BounceCount = 0
ENT.MaxBounces = 8
ENT.BounceDecay = 16
ENT.ShellColor = Color(50, 50, 50, 255) -- Dark rubber color

-- Base class configurable collision behavior
ENT.CollisionSpeedThreshold = 200 -- Lower threshold for rubber
ENT.CollisionRequiresArmed = true
ENT.CollisionDelay = 0
ENT.FuseTime = 30 -- Longer fuse time for bouncing
ENT.TrailEffectScale = 2
ENT.TrailSoundVolume = 50
ENT.CreateTrailEffect = false
local BaseClass = baseclass.Get("ent_aboot_ezcannon_shot")

if SERVER then
	function ENT:Initialize()
		self:SetModel(self.Model)
		self:SetMaterial(self.Material)
		self:SetColor(self.RubberColor)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:DrawShadow(true)
		self:GetPhysicsObject():EnableDrag(false)

		timer.Simple(0, function()
			if IsValid(self) then
				local Phys = self:GetPhysicsObject()
				if IsValid(Phys) then
					Phys:SetMass(self.Mass or 30) -- Lighter than normal shots
					Phys:SetMaterial("rubber") -- Use rubber physics material
					self:SetElasticity(1) -- Very bouncy
					self:SetFriction(0.3) -- Low friction
				end
			end
		end)

		self.IsArmed = false
		self.BounceCount = 0
	end

	function ENT:PhysicsCollide(data, physobj)
		if data.DeltaTime > 0.2 and data.Speed > 100 then
			-- Always bounce for rubber shots, regardless of speed
			if self.CollisionRequiresArmed and not self.IsArmed then
				self:EmitSound(self.ImpactSound, 75, math.Rand(90, 110))
				return
			end

			-- Handle bouncing
			if self.BounceCount < self.MaxBounces then
				self.BounceCount = self.BounceCount + 1
				
				-- Apply bounce force
				local Phys = self:GetPhysicsObject()
				timer.Simple(0, function()
					if IsValid(Phys) then
						local bounceSpeed = data.Speed * self.BounceMultiplier * (self.BounceDecay / (self.BounceCount / self.MaxBounces))
						local bounceDir = (data.OurNewVelocity):GetNormalized()
						
						if math.random(1, 2) == 1 then
							local Nearby = ents.FindInSphere(data.HitPos, bounceSpeed * 0.25)
							for _, ent in pairs(Nearby) do
								if ent:IsNPC() then
									local aimPos = ent:GetPos()
									local aimDir = (aimPos - data.HitPos):GetNormal()
									
									bounceDir = (bounceDir + aimDir):GetNormal()

									break
								end
							end
						end
						
						--debugoverlay.Line(data.HitPos, data.HitPos + bounceDir * bounceSpeed, 1, Color(255, 0, 0), true)
						Phys:SetVelocity(bounceDir * bounceSpeed)
					end
				end)
				
				-- Play bounce sound
				self:EmitSound(self.ImpactSound, 75, math.Rand(90, 110))
				
				-- Create bounce effect
				local Effect = EffectData()
				Effect:SetOrigin(data.HitPos)
				Effect:SetScale(1)
				Effect:SetNormal(data.HitNormal)
				util.Effect("eff_jack_gmod_bpsmoke", Effect, true, true)
				
				-- Screen shake for nearby players
				util.ScreenShake(data.HitPos, 2, 0.5, 0.5, 100)
				
			else
				-- Max bounces reached, detonate
				timer.Simple(self.CollisionDelay or 0, function()
					if IsValid(self) then
						self:Detonate()
					end
				end)
			end
		end
	end

	function ENT:Detonate()
		local Attacker = JMod.GetEZowner(self)
		local Pos = self:GetPos()
		
		-- Create rubber explosion effect
		local Effect = EffectData()
		Effect:SetOrigin(Pos)
		Effect:SetScale(2)
		Effect:SetNormal(Vector(0, 0, 1))
		util.Effect("eff_jack_gmod_bpsmoke", Effect, true, true)
		
		-- Rubber explosion sound
		self:EmitSound("Rubber_Tire.ImpactHard", 100, math.Rand(80, 100))
		self:EmitSound("physics/rubber/rubber_tire_impact_hard" .. math.random(1, 3) .. ".wav", 90, math.Rand(90, 110))
		
		-- Create bouncing rubber pieces
		local rubberColor = self.ShellColor
		local rubberVisMat = self.Material
		for i = 1, 8 do
			timer.Simple(i * 0.1, function()
				local piecePos = Pos + VectorRand() * 50
				local piece = ents.Create("prop_physics")
				if IsValid(piece) then
					piece:SetModel("models/props_junk/watermelon01_chunk02a.mdl") -- Small round object
					piece:SetPos(piecePos)
					piece:SetAngles(AngleRand())
					piece:SetColor(rubberColor)
					piece:SetMaterial(rubberVisMat)
					piece:Spawn()
					
					local piecePhys = piece:GetPhysicsObject()
					if IsValid(piecePhys) then
						piecePhys:SetVelocity(VectorRand() * 300)
						piecePhys:SetMaterial("rubber")
						piece:SetElasticity(0.8)
					end
					
					-- Remove after some time
					timer.Simple(10, function()
						if IsValid(piece) then
							piece:Remove()
						end
					end)
				end
			end)
		end
		
		self:Remove()
	end
end 