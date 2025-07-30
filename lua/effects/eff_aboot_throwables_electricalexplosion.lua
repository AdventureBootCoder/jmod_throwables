--AdventureBoots 2025
function EFFECT:Init(data)
	local pos = data:GetOrigin()
	local scale = data:GetScale() or 1
	local normal = data:GetNormal() or Vector(0, 0, 1)
	
	local emitter = ParticleEmitter(pos)
	if not emitter then return end
	
	-- Create electrical explosion sparks
	for i = 1, 20 * scale do
		local sparkPos = pos + VectorRand() * 30 * scale
		local particle = emitter:Add("sprites/mat_jack_nicespark", sparkPos)
		
		if particle then
			particle:SetVelocity(VectorRand() * 200 * scale)
			particle:SetLifeTime(0)
			particle:SetDieTime(math.Rand(0.2, 0.8))
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(2, 5) * scale)
			particle:SetEndSize(0)
			particle:SetRoll(math.Rand(-360, 360))
			particle:SetRollDelta(math.Rand(-5, 5))
			particle:SetAirResistance(80)
			particle:SetGravity(Vector(0, 0, -100))
			particle:SetColor(100, 150, 255) -- Blue electrical
			particle:SetLighting(false)
			particle:SetCollide(true)
			particle:SetBounce(0.3)
		end
	end
	
	-- Create electrical smoke
	for i = 1, 8 * scale do
		local smokePos = pos + VectorRand() * 20 * scale
		local particle = emitter:Add("particle/smokestack", smokePos)
		
		if particle then
			particle:SetVelocity(VectorRand() * 50 * scale)
			particle:SetLifeTime(0)
			particle:SetDieTime(math.Rand(1.0, 2.0))
			particle:SetStartAlpha(100)
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(10, 20) * scale)
			particle:SetEndSize(math.Rand(30, 50) * scale)
			particle:SetRoll(math.Rand(-360, 360))
			particle:SetRollDelta(math.Rand(-1, 1))
			particle:SetAirResistance(50)
			particle:SetGravity(Vector(0, 0, 50))
			particle:SetColor(100, 100, 120) -- Electrical smoke
			particle:SetLighting(false)
			particle:SetCollide(false)
		end
	end
	
	emitter:Finish()
	
	-- Dynamic light for electrical explosion
	local dlight = DynamicLight(self:EntIndex())
	if dlight then
		dlight.Pos = pos
		dlight.r = 100
		dlight.g = 150
		dlight.b = 255
		dlight.Brightness = 3 * scale
		dlight.Size = 150 * scale
		dlight.Decay = 800
		dlight.DieTime = CurTime() + 0.3
		dlight.Style = 0
	end
	
	-- Sound effect
	sound.Play("ambient/energy/zap" .. math.random(1, 3) .. ".wav", pos, 100, math.Rand(80, 100))
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end 