function EFFECT:Init(data)
	local Pos, Dir, Scl = data:GetOrigin(), data:GetNormal(), data:GetScale()
	self.Pos = Pos
	self.Dir = Dir
	self.Scl = Scl
	self.Speed = data:GetMagnitude()
	self.FireParticles = {}

	local FireCount = 50
	local emitter = ParticleEmitter(Pos)

	if emitter then
		for i = 1, FireCount do
			local Progress = i / FireCount
			local ProgressInverse = 1 - Progress
			local Straight = Progress >= 0.5
			local ParticlePos = Pos + Dir * math.random(-5, 5)
			local particle = emitter:Add("mats_jack_gmod_sprites/flamelet" .. math.random(1, 5), ParticlePos)

			if particle then
				local Siz

				if Straight then
					local Speed = (self.Speed * 2 * Progress) * Scl
					particle:SetVelocity(Dir * Speed + VectorRand() * 100 * Scl)
					Siz = math.max(5, 20 * ProgressInverse) * Scl
				else
					Siz = math.Rand(15, 25) * Scl
					local ForwardSpeed = self.Speed * math.Rand(1, 2) * Scl
					local RadialAng = Dir:Angle()
					RadialAng:RotateAroundAxis(Dir, math.Rand(0, 360))
					local RadialSpeed = Siz * math.Rand(10, 100) * Scl
					particle:SetVelocity(Dir * ForwardSpeed + RadialAng:Up() * RadialSpeed)
				end

				particle:SetAirResistance(100 * Siz)
				particle:SetGravity(Vector(0, 0, math.random(5, 50)) + JMod.Wind * 100)
				particle:SetDieTime(math.Rand(.15, .75))
				particle:SetStartAlpha(255)
				particle:SetEndAlpha(10)
				particle:SetStartSize(Siz)
				particle:SetEndSize(Siz * 2)
				particle:SetRoll(math.Rand(-2, 2))
				particle:SetRollDelta(math.Rand(-2, 2))
				particle:SetColor(255, 255, 255)
				particle:SetLighting(false)
				particle:SetCollide(true)
				table.insert(self.FireParticles, particle)
			end
		end

		emitter:Finish()
	end

	local dlight = DynamicLight(self:EntIndex())

	if dlight then
		dlight.Pos = Pos + Dir * 10
		dlight.r = 255
		dlight.g = 180
		dlight.b = 120
		dlight.Brightness = 1 * Scl ^ 0.5
		dlight.Size = 1000 * Scl ^ 0.5
		dlight.Decay = 4000
		dlight.DieTime = CurTime() + 0.25
	end
end

function EFFECT:Think()
	local Time = CurTime()

	if not IsValid(self.SmokeEmitter) then
		self.SmokeEmitter = ParticleEmitter(self.Pos)

		if not IsValid(self.SmokeEmitter) then

			return true
		end
	end

	if not next(self.FireParticles) then
		if IsValid(self.SmokeEmitter) then
			self.SmokeEmitter:Finish()
			self.SmokeEmitter = nil
		end

		return false
	end

	self.Pos = self.Pos + self.Dir * 1

	for index, p in ipairs(self.FireParticles) do
		if p then
			local Remaining = p:GetDieTime() - p:GetLifeTime()
			if Remaining < 0.15 then
				local ParticlePos = p:GetPos()
				local particle = self.SmokeEmitter:Add("particle/smokestack", ParticlePos)

				if particle then
					local BaseSize = p:GetEndSize() * .75
					local NewTime = math.max(0.15, Remaining) * BaseSize * .75

					particle:SetVelocity(p:GetVelocity())
					particle:SetAirResistance(100 * BaseSize)
					particle:SetGravity(Vector(0, 0, 80) + JMod.Wind * 300)
					particle:SetDieTime(NewTime)
					particle:SetStartAlpha(250)
					particle:SetEndAlpha(0)
					particle:SetStartSize(BaseSize)
					particle:SetEndSize(BaseSize * 4)
					particle:SetRoll(p:GetRoll())
					particle:SetRollDelta(math.Rand(-2, 2))
					local Col = math.random(180, 255)
					particle:SetColor(Col, Col, Col)
					particle:SetLighting(math.random(1, 2) == 1)
					particle:SetCollide(true)
				end

				table.remove(self.FireParticles, index)
				index = index - 1
			end
		end
	end

	return true
end

function EFFECT:Render()
end
