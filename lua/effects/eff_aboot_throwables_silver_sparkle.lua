--AdventureBoots 2025
function EFFECT:Init(data)
	local pos = data:GetOrigin()
	local scale = data:GetScale() or 1
	local normal = data:GetNormal() or Vector(0, 0, 1)
	
	local emitter = ParticleEmitter(pos)
	if not emitter then return end
	
	-- Create silver sparkles
	for i = 1, 8 * scale do
		local sparklePos = pos + VectorRand() * 15 * scale
		local particle = emitter:Add("sprites/mat_jack_nicespark", sparklePos)
		
		if particle then
			particle:SetVelocity(VectorRand() * 100 * scale)
			particle:SetLifeTime(0)
			particle:SetDieTime(math.Rand(0.5, 1.5))
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(1, 3) * scale)
			particle:SetEndSize(0)
			particle:SetRoll(math.Rand(-360, 360))
			particle:SetRollDelta(math.Rand(-2, 2))
			particle:SetAirResistance(50)
			particle:SetGravity(Vector(0, 0, -50))
			particle:SetColor(200, 200, 200) -- Silver color
			particle:SetLighting(false)
			particle:SetCollide(true)
			particle:SetBounce(0.3)
		end
	end
	
	-- Create shimmer particles
	for i = 1, 5 * scale do
		local shimmerPos = pos + VectorRand() * 10 * scale
		local particle = emitter:Add("sprites/light_glow02_add", shimmerPos)
		
		if particle then
			particle:SetVelocity(VectorRand() * 30 * scale)
			particle:SetLifeTime(0)
			particle:SetDieTime(math.Rand(0.3, 0.8))
			particle:SetStartAlpha(100)
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(2, 4) * scale)
			particle:SetEndSize(0)
			particle:SetRoll(math.Rand(-360, 360))
			particle:SetRollDelta(math.Rand(-1, 1))
			particle:SetAirResistance(30)
			particle:SetGravity(Vector(0, 0, -20))
			particle:SetColor(255, 255, 255) -- White shimmer
			particle:SetLighting(false)
			particle:SetCollide(false)
		end
	end
	
	emitter:Finish()
	
	-- Dynamic light for silver sparkle
	local dlight = DynamicLight(self:EntIndex())
	if dlight then
		dlight.Pos = pos
		dlight.r = 200
		dlight.g = 200
		dlight.b = 200
		dlight.Brightness = 1 * scale
		dlight.Size = 50 * scale
		dlight.Decay = 500
		dlight.DieTime = CurTime() + 0.2
		dlight.Style = 0
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end 