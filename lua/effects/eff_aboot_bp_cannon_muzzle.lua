function EFFECT:Init(data)
	local Pos, Dir, Scl = data:GetOrigin(), data:GetNormal(), data:GetScale()
	local BaseVelocity = 1000
	local emitter = ParticleEmitter(Pos)

	if emitter then
		for i = 1, 40 do
			local InverseProgress = 1 - (i / 40)
			local ParticlePos = Pos + Dir * math.random(-5, 5)
			local particle = emitter:Add("mats_jack_gmod_sprites/flamelet" .. math.random(1, 5), ParticlePos)
			particle:SetVelocity(Dir * 1000 * i * .25 * Scl + VectorRand() * 500 * Scl)
			particle:SetAirResistance(400)
			particle:SetGravity(Vector(0, 0, math.random(5, 50)) + JMod.Wind * 100)
			particle:SetDieTime(i * 0.015)
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(0)
			local Siz = i * 1 * Scl
			particle:SetStartSize(Siz)
			particle:SetEndSize(Siz * 2)
			particle:SetRoll(math.Rand(-2, 2))
			particle:SetRollDelta(math.Rand(-2, 2))
			particle:SetColor(255, 255, 255)
			particle:SetLighting(false)
			particle:SetCollide(true)
		end

		local SmokeCount = 50
		for i = 1, SmokeCount do
			local ParticlePos = Pos + Dir * math.random(1, 15)
			local particle = emitter:Add("particle/smokestack", ParticlePos)

			local Progress = i / SmokeCount -- 0.0 to 1.0
			local ProgressInverse = 1 - Progress
			
			local VelocityMultiplier = (2 + Scl) * Progress * 2
			
			local DispersionMultiplier = Progress * 1
			
			local AirResistance = 100 * i
			
			local Lifetime = ProgressInverse * 3
			
			local BaseSize = (10 + ProgressInverse * 10) * Scl
			
			particle:SetVelocity(Dir * BaseVelocity * VelocityMultiplier + VectorRand() * math.random(20, 40) * DispersionMultiplier)
			particle:SetAirResistance(AirResistance)
			particle:SetGravity(Vector(0, 0, 50) + JMod.Wind * AirResistance)
			particle:SetDieTime(Lifetime)
			particle:SetStartAlpha(ProgressInverse * 80)
			particle:SetEndAlpha(0)
			particle:SetStartSize(BaseSize)
			particle:SetEndSize(BaseSize * 2)
			particle:SetRoll(math.Rand(-2, 2))
			particle:SetRollDelta(math.Rand(-2, 2))
			local Col = math.random(180, 255)
			particle:SetColor(Col, Col, Col)
			particle:SetLighting(math.random(1, 2) == 1)
			particle:SetCollide(true)
		end

		for i = 1, SmokeCount * .5 do
			local Progress = i / (SmokeCount * .5)
			local ProgressInverse = 1 - Progress
			local AirResistance = 500
			local ParticlePos = Pos + Dir * math.random(1, 15)
			local particle = emitter:Add("particle/smokestack", ParticlePos)
			particle:SetVelocity(Dir * 5000 * math.random(1, 2) * Scl + VectorRand() * 1200 * Scl)
			particle:SetAirResistance(AirResistance)
			particle:SetGravity(Vector(0, 0, 50) + JMod.Wind * AirResistance)
			particle:SetDieTime(ProgressInverse * 4)
			particle:SetStartAlpha(ProgressInverse * 80)
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(10, 30))
			particle:SetEndSize(600 * Scl)
			particle:SetRoll(math.Rand(-2, 2))
			particle:SetRollDelta(math.Rand(-2, 2))
			local Col = math.random(180, 255)
			particle:SetColor(Col, Col, Col)
			particle:SetLighting(math.random(1, 2) == 1)
			particle:SetCollide(true)
		end

		for i = 1, 80 do
			local particle = emitter:Add("sprites/mat_jack_basicglow", Pos + Dir)
			particle:SetVelocity(Dir * math.Rand(40, 400) + VectorRand() * math.Rand(50, 500))
			particle:SetAirResistance(100)
			particle:SetGravity(VectorRand() * 600)
			particle:SetDieTime(math.Rand(.2, 2))
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(0)
			local Size = 2
			particle:SetStartSize(Size)
			particle:SetEndSize(0)
			particle:SetRoll(0)

			if math.random(1, 2) == 1 then
				particle:SetRollDelta(0)
			else
				particle:SetRollDelta(math.Rand(-.5, .5))
			end

			particle:SetColor(255, 150, 100)
			particle:SetLighting(false)
			particle:SetCollide(true)
			particle:SetBounce(1)
		end
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
--
