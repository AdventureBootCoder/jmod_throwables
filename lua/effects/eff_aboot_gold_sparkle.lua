--AdventureBoots 2025
function EFFECT:Init(data)
	local pos = data:GetOrigin()
	local scale = data:GetScale() or 1
	local normal = data:GetNormal() or Vector(0, 0, 1)
	
	local emitter = ParticleEmitter(pos)
	if not emitter then return end
	
	-- Create golden sparkles
	for i = 1, 10 * scale do
		local sparklePos = pos + VectorRand() * 20 * scale
		local particle = emitter:Add("sprites/mat_jack_nicespark", sparklePos)
		
		if particle then
			particle:SetVelocity(VectorRand() * 120 * scale)
			particle:SetLifeTime(0)
			particle:SetDieTime(math.Rand(0.6, 1.8))
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(1, 4) * scale)
			particle:SetEndSize(0)
			particle:SetRoll(math.Rand(-360, 360))
			particle:SetRollDelta(math.Rand(-3, 3))
			particle:SetAirResistance(40)
			particle:SetGravity(Vector(0, 0, -60))
			particle:SetColor(255, 215, 0) -- Gold color
			particle:SetLighting(false)
			particle:SetCollide(true)
			particle:SetBounce(0.4)
		end
	end
	
	-- Create golden shimmer particles
	for i = 1, 6 * scale do
		local shimmerPos = pos + VectorRand() * 15 * scale
		local particle = emitter:Add("sprites/light_glow02_add", shimmerPos)
		
		if particle then
			particle:SetVelocity(VectorRand() * 40 * scale)
			particle:SetLifeTime(0)
			particle:SetDieTime(math.Rand(0.4, 1.0))
			particle:SetStartAlpha(120)
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(3, 5) * scale)
			particle:SetEndSize(0)
			particle:SetRoll(math.Rand(-360, 360))
			particle:SetRollDelta(math.Rand(-1, 1))
			particle:SetAirResistance(25)
			particle:SetGravity(Vector(0, 0, -25))
			particle:SetColor(255, 215, 0) -- Gold shimmer
			particle:SetLighting(false)
			particle:SetCollide(false)
		end
	end
	
	-- Create golden dust particles
	for i = 1, 4 * scale do
		local dustPos = pos + VectorRand() * 10 * scale
		local particle = emitter:Add("particle/smokestack", dustPos)
		
		if particle then
			particle:SetVelocity(VectorRand() * 20 * scale)
			particle:SetLifeTime(0)
			particle:SetDieTime(math.Rand(1.0, 2.0))
			particle:SetStartAlpha(80)
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(2, 4) * scale)
			particle:SetEndSize(math.Rand(4, 8) * scale)
			particle:SetRoll(math.Rand(-360, 360))
			particle:SetRollDelta(math.Rand(-1, 1))
			particle:SetAirResistance(20)
			particle:SetGravity(Vector(0, 0, -10))
			particle:SetColor(255, 215, 0) -- Gold dust
			particle:SetLighting(false)
			particle:SetCollide(false)
		end
	end
	
	emitter:Finish()
	
	-- Dynamic light for gold sparkle
	local dlight = DynamicLight(self:EntIndex())
	if dlight then
		dlight.Pos = pos
		dlight.r = 255
		dlight.g = 215
		dlight.b = 0
		dlight.Brightness = 1.5 * scale
		dlight.Size = 60 * scale
		dlight.Decay = 400
		dlight.DieTime = CurTime() + 0.3
		dlight.Style = 0
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end 