--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_aboot_ezshot"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "Explosive cannon shell"
ENT.PrintName = "Shell 120 MM"
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.AdminSpawnable = false

ENT.CollisionSpeedThreshold = 200
ENT.CollisionRequiresArmed = true
ENT.CollisionDelay = 0
ENT.CollisionDirection = Vector(-1, 0, 0)
ENT.FuseTime = 30
ENT.TrailEffectScale = 3
ENT.TrailSoundVolume = 100

ENT.Model = Model("models/jmod_shot/shell_120_full.mdl")
ENT.ShellModel = Model("models/jmod_shot/shell_120.mdl")
ENT.CaseModel = Model("models/jmod_shot/shell_120_case.mdl")
ENT.Material = ""
ENT.Mass = 15

if SERVER then
	function ENT:Initialize()
		-- Call base class initialize
		if self.BaseClass and self.BaseClass.Initialize then
			self.BaseClass.Initialize(self)
		end
		-- Set armed state for explosive shots
		self:SetIsArmed(false)
	end

	function ENT:Launch(ply, force)
		self:SetModel(self.ShellModel)
		//self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():SetMass(10)
		if force then
			self:GetPhysicsObject():ApplyForceCenter(self:GetUp() * 10000)
		end
		self:SetBodygroup(1, 1)
		self:SetIsArmed(true)
	end

	function ENT:Detonate(collisionData)
		local Pos = self:GetPos()
		local Dir = self:GetUp() * -1
		if collisionData then
			Pos = (collisionData and collisionData.HitPos + collisionData.HitNormal * -10)
		end
		if self.Detonated then return end
		self.Detonated = true
		-- Do some shrapnel
		local Attacker = JMod.GetEZowner(self)
		local BlastDmg = DamageInfo()
		BlastDmg:SetDamageType(DMG_BLAST)
		BlastDmg:SetDamage(2500)
		BlastDmg:SetAttacker(Attacker)
		BlastDmg:SetInflictor(self)
		BlastDmg:SetDamageForce(Dir * 2500)
		util.BlastDamageInfo(BlastDmg, Pos, 300)
		JMod.FragSplosion(self, Pos, 250, 500, 1000, Attacker, nil, nil, nil, true)
		JMod.WreckBuildings(self, Pos, 1, 1, true)
		-- Do some effects
		timer.Simple(.1, function()
			ParticleEffect("50lb_air", Pos, Dir:Angle())
		end)

		self:Remove()
	end

	function ENT:OnTakeDamage(dmginfo)
		self:TakePhysicsDamage(dmginfo)
		if JMod.LinCh(dmginfo:GetDamage(), 1, 100) then
			local Attacker = dmginfo:GetAttacker()
			timer.Simple(0, function()
				if IsValid(self) then
					self:Launch(Attacker, true)
				end
			end)
		end
	end

	function ENT:CreateTrailEffect()
		if not self.Launched then return end
		if self:GetNoDraw() then return end
		local Fsh = EffectData()
		Fsh:SetOrigin(self:GetPos())
		Fsh:SetScale(self.TrailEffectScale or 3)
		Fsh:SetNormal(self:GetUp() * -1)
		util.Effect("eff_jack_gmod_fuzeburn_smoky", Fsh, true, true)
		self:EmitSound("snd_jack_sss.wav", self.TrailSoundVolume or 65, math.Rand(90, 110))
	end--]]
end

