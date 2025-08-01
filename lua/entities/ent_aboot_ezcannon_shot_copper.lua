--AdventureBoots 2025
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ent_aboot_ezcannon_shot"
ENT.Author = "AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "Copper shot that creates chain lightning effects"
ENT.PrintName = "EZ Cannon Shot (Copper)"
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.Model = "models/props_phx/misc/smallcannonball.mdl"
ENT.Material = "models/props_mining/ingot_jack_copper"
ENT.ModelScale = nil
ENT.ImpactSound = "Grenade.ImpactHard"
ENT.CollisionGroup = COLLISION_GROUP_NONE
ENT.JModEZstorable = true

-- Copper-specific properties
ENT.CollisionSpeedThreshold = 600
ENT.CollisionRequiresArmed = true
ENT.CollisionDelay = 0.1
ENT.FuseTime = 8
ENT.TrailEffectScale = 2
ENT.TrailSoundVolume = 55
ENT.CreateTrailEffect = true
ENT.Mass = 50
ENT.ShellColor = Color(150, 100, 80, 255)
ENT.LightningRadius = 300
ENT.LightningDamage = 100
ENT.MaxChainJumps = 10
ENT.ChainJumpRange = 256

if SERVER then
	function ENT:CreateTrailEffect()
		-- Copper electrical trail effect
		local Zap = EffectData()
		Zap:SetEntity(self)
		Zap:SetScale(self.TrailEffectScale or 1)
		Zap:SetRadius(256)
		util.Effect("aboot_tesla_arc", Zap, true, true)
		
		-- Add electrical crackle sound
		if math.random(1, 3) == 1 then
			self:EmitSound("ambient/energy/zap" .. math.random(1, 3) .. ".wav", self.TrailSoundVolume or 55, math.Rand(90, 110))
		end
		
		self:EmitSound("snd_jack_sss.wav", self.TrailSoundVolume or 55, math.Rand(90, 110))
	end

	local function ChainLightning(startPos, attacker, damage, range, maxJumps, currentJump)
		if currentJump >= maxJumps then return end

		-- Find nearby targets
		local targets = {}
		for _, ent in pairs(ents.FindInSphere(startPos, range)) do
			if ent:GetClass() ~= "ent_aboot_ezcannon_shot_copper" and IsValid(ent:GetPhysicsObject()) then
				table.insert(targets, ent)
			end
		end
		
		if #targets == 0 then return end
		
		-- Pick a random target
		local target = targets[math.random(1, #targets)]
		if not IsValid(target) then return end
		
		-- Create lightning effect
		local Effect = EffectData()
		Effect:SetOrigin(startPos)
		Effect:SetStart(target:GetPos())
		Effect:SetScale(1)
		util.Effect("eff_aboot_throwables_lightning", Effect, true, true)
		
		-- Damage the target
		if target:IsPlayer() or target:IsNPC() then
			local dmginfo = DamageInfo()
			dmginfo:SetDamage(damage * (1 - currentJump * 0.2)) -- Damage decreases with each jump
			dmginfo:SetAttacker(attacker)
			dmginfo:SetDamagePosition(target:GetPos())
			dmginfo:SetDamageForce(VectorRand() * 1000)
			dmginfo:SetDamageType(DMG_SHOCK)
			target:TakeDamageInfo(dmginfo)
			
			-- Stun effect for players
			if target:IsPlayer() then
				target:ViewPunch(Angle(math.random(-10, 10), math.random(-10, 10), 0))
			end
		elseif target:GetClass() == "prop_physics" then
			-- Electrify props
			target:Ignite(2, 0)
			local phys = target:GetPhysicsObject()
			if IsValid(phys) then
				phys:ApplyForceCenter(VectorRand() * 1000)
			end
		end
		
		-- Play lightning sound
		sound.Play("ambient/energy/zap" .. math.random(1, 3) .. ".wav", target:GetPos(), 75, math.Rand(90, 110))
		
		-- Continue chain
		local NextPos = target:GetPos()
		timer.Simple(0.1, function()
			ChainLightning(NextPos, attacker, damage, range, maxJumps, currentJump + 1)
		end)
	end

	function ENT:Detonate(collisionData)
		local Attacker = JMod.GetEZowner(self)
		local Pos = (collisionData and collisionData.HitPos + collisionData.HitNormal * -10) or self:GetPos()
		
		-- Initial explosion
		JMod.Sploom(Attacker, Pos, 40, 60)
		
		-- Start chain lightning from impact point
		ChainLightning(Pos, Attacker, self.LightningDamage, self.ChainJumpRange, self.MaxChainJumps, 0)
		
		-- Create electrical explosion effect
		local Effect = EffectData()
		Effect:SetOrigin(Pos)
		Effect:SetScale(3)
		Effect:SetNormal(Vector(0, 0, 1))
		util.Effect("eff_aboot_throwables_electricalexplosion", Effect, true, true)
		
		-- Play electrical explosion sound
		self:EmitSound("ambient/energy/zap" .. math.random(1, 3) .. ".wav", 100, math.Rand(80, 100))
		self:EmitSound("physics/metal/metal_box_break" .. math.random(1, 2) .. ".wav", 85, math.Rand(90, 110))
		
		timer.Simple(0.1, function()
			if IsValid(self) then
				self:Remove()
			end
		end)
	end

elseif CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end
end 