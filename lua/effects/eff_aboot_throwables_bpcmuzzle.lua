function EFFECT:Init(data)
	local Pos, Dir, Scl = data:GetOrigin(), data:GetNormal(), data:GetScale()
	local emitter = ParticleEmitter(Pos)

	if emitter then
		for i = 1, 40 do
			local ParticlePos = Pos + Dir * math.random(-10, 5)
			local particle = emitter:Add("mats_jack_gmod_sprites/flamelet" .. math.random(1, 5), ParticlePos)
			particle:SetVelocity(Dir * math.Rand(100, 1000) * i * Scl + VectorRand() * math.random(1, 2) * Scl)
			particle:SetAirResistance(50)
			particle:SetGravity(Vector(0, 0, math.random(5, 50)) + JMod.Wind * 100)
			particle:SetDieTime(math.Rand(.1, .6))
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(0)
			local Size = (30 / i) * Scl
			particle:SetStartSize(Size)
			particle:SetEndSize(Size)
			particle:SetRoll(math.Rand(-2, 2))
			particle:SetRollDelta(math.Rand(-2, 2))
			particle:SetColor(255, 255, 255)
			particle:SetLighting(false)
			particle:SetCollide(true)
		end

		local SmokeCount = 100
		for i = 1, SmokeCount do
			local ParticlePos = Pos + Dir * math.random(-5, 15)
			local particle = emitter:Add("particle/smokestack", ParticlePos)
			
			-- Use index i to create realistic pressure-based effects with smooth curves
			-- Earlier particles (lower i) have higher velocity and less dispersion
			-- Later particles (higher i) have lower velocity and more dispersion
			local Progress = math.sin(i / SmokeCount) -- 0.0 to 1.0
			local BaseVelocity = 1000 * Scl
			
			-- Smooth velocity curve: starts high, drops off gradually
			local VelocityMultiplier = 4.5 - Progress * 5
			
			-- Smooth dispersion curve: starts low, increases gradually
			local DispersionMultiplier = math.Clamp(Progress * 1.5, 0.5, 2)
			
			-- Smooth air resistance curve: starts low, increases for later particles
			local AirResistance = math.Clamp(100 + Progress * 100, 50, 300)
			
			-- Smooth lifetime curve: starts short, gets longer for lingering particles
			local Lifetime = math.Clamp(1 + Progress * 10, 1, 15)
			
			-- Smooth size curve: starts normal, gets smaller for later particles
			local BaseSize = math.Rand(1, 10 * Scl)--math.Clamp(math.Rand(5, 10) * (1 - Progress * 0.4), 3, 10) * Scl
			
			-- Smooth growth curve: starts high, gets lower for later particles
			local GrowthFactor = math.Clamp((1 - Progress * 0.6) * 120 + 2, 2, 2000)
			
			particle:SetVelocity(Dir * BaseVelocity * VelocityMultiplier + VectorRand() * math.random(20, 40) * DispersionMultiplier)
			particle:SetAirResistance(AirResistance)
			particle:SetGravity(Vector(0, 0, math.random(5, 50)) + JMod.Wind * AirResistance * .1 * math.Rand(0.1, 1))
			particle:SetDieTime(Lifetime)
			particle:SetStartAlpha(math.random(50, 100))
			particle:SetEndAlpha(0)
			
			local StartSize = BaseSize
			local EndSize = BaseSize * GrowthFactor
			
			particle:SetStartSize(StartSize)
			particle:SetEndSize(EndSize)
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
