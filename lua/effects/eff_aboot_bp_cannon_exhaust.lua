function EFFECT:Init(data)
	local Pos, Dir, Scl = data:GetOrigin(), data:GetNormal(), data:GetScale()
	local BaseVelocity = 100
	local emitter = ParticleEmitter(Pos)

	if emitter then
		for i = 1, 20 do
			local ParticlePos = Pos - Dir * math.random(1, 10)
			local particle = emitter:Add("mats_jack_gmod_sprites/flamelet" .. math.random(1, 5), ParticlePos)
			particle:SetVelocity(Dir * 100 * i * .25 * Scl + VectorRand() * math.random(1, 2) * Scl)
			particle:SetAirResistance(50)
			particle:SetGravity(Vector(0, 0, math.random(5, 50)) + JMod.Wind * 100)
			particle:SetDieTime(math.Rand(.5, .75))
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(0)
			local Size = (50 / i) * Scl
			particle:SetStartSize(Size)
			particle:SetEndSize(Size)
			particle:SetRoll(math.Rand(-2, 2))
			particle:SetRollDelta(math.Rand(-2, 2))
			particle:SetColor(255, 255, 255)
			particle:SetLighting(false)
			particle:SetCollide(true)
		end

		local SmokeCount = 50
		for i = 1, SmokeCount do
			local ParticlePos = Pos + Dir * math.random(-5, 15)
			local particle = emitter:Add("particle/smokestack", ParticlePos)

			local Progress = i / SmokeCount -- 0.0 to 1.0
			local ProgressInverse = 1 - Progress
			
			local VelocityMultiplier = Progress * 2
			
			local DispersionMultiplier = Progress * 1
			
			local AirResistance = 200
			
			local Lifetime = ProgressInverse * 5
			
			local BaseSize = (20 + ProgressInverse * 10) * Scl
			
			particle:SetVelocity(Dir * BaseVelocity * VelocityMultiplier + VectorRand() * math.random(20, 40))
			particle:SetAirResistance(AirResistance)
			particle:SetGravity(Vector(0, 0, math.random(5, 50)) + JMod.Wind * AirResistance * math.Rand(0.1, 1))
			particle:SetDieTime(Lifetime)
			particle:SetStartAlpha(math.random(50, 100))
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

		for i = 1, 40 do
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
