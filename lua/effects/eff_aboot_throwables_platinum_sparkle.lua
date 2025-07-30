--AdventureBoots 2025
function EFFECT:Init(data)
	local pos = data:GetOrigin()
	local scale = data:GetScale() or 1
	local normal = data:GetNormal() or Vector(0, 0, 1)
	
	local emitter = ParticleEmitter(pos)
	if not emitter then return end
	
	-- Create platinum sparkles
	for i = 1, 12 * scale do
		local sparklePos = pos + VectorRand() * 25 * scale
		local particle = emitter:Add("sprites/mat_jack_nicespark", sparklePos)
		
		if particle then
			particle:SetVelocity(VectorRand() * 150 * scale)
			particle:SetLifeTime(0)
			particle:SetDieTime(math.Rand(0.8, 2.0))
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(2, 5) * scale)
			particle:SetEndSize(0)
			particle:SetRoll(math.Rand(-360, 360))
			particle:SetRollDelta(math.Rand(-4, 4))
			particle:SetAirResistance(35)
			particle:SetGravity(Vector(0, 0, -70))
			particle:SetColor(255, 255, 255) -- Platinum white
			particle:SetLighting(false)
			particle:SetCollide(true)
			particle:SetBounce(0.5)
		end
	end
	
	-- Create platinum shimmer particles
	for i = 1, 8 * scale do
		local shimmerPos = pos + VectorRand() * 20 * scale
		local particle = emitter:Add("sprites/light_glow02_add", shimmerPos)
		
		if particle then
			particle:SetVelocity(VectorRand() * 50 * scale)
			particle:SetLifeTime(0)
			particle:SetDieTime(math.Rand(0.5, 1.2))
			particle:SetStartAlpha(150)
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(4, 6) * scale)
			particle:SetEndSize(0)
			particle:SetRoll(math.Rand(-360, 360))
			particle:SetRollDelta(math.Rand(-1, 1))
			particle:SetAirResistance(20)
			particle:SetGravity(Vector(0, 0, -30))
			particle:SetColor(255, 255, 255) -- Platinum shimmer
			particle:SetLighting(false)
			particle:SetCollide(false)
		end
	end
	
	-- Create platinum dust particles
	for i = 1, 6 * scale do
		local dustPos = pos + VectorRand() * 15 * scale
		local particle = emitter:Add("particle/smokestack", dustPos)
		
		if particle then
			particle:SetVelocity(VectorRand() * 25 * scale)
			particle:SetLifeTime(0)
			particle:SetDieTime(math.Rand(1.2, 2.5))
			particle:SetStartAlpha(100)
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(3, 5) * scale)
			particle:SetEndSize(math.Rand(5, 10) * scale)
			particle:SetRoll(math.Rand(-360, 360))
			particle:SetRollDelta(math.Rand(-1, 1))
			particle:SetAirResistance(15)
			particle:SetGravity(Vector(0, 0, -15))
			particle:SetColor(255, 255, 255) -- Platinum dust
			particle:SetLighting(false)
			particle:SetCollide(false)
		end
	end
	
	-- Create rainbow sparkles for ultimate luxury
	for i = 1, 4 * scale do
		local rainbowPos = pos + VectorRand() * 12 * scale
		local particle = emitter:Add("sprites/mat_jack_nicespark", rainbowPos)
		
		if particle then
			particle:SetVelocity(VectorRand() * 80 * scale)
			particle:SetLifeTime(0)
			particle:SetDieTime(math.Rand(1.0, 1.8))
			particle:SetStartAlpha(200)
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(2, 4) * scale)
			particle:SetEndSize(0)
			particle:SetRoll(math.Rand(-360, 360))
			particle:SetRollDelta(math.Rand(-2, 2))
			particle:SetAirResistance(30)
			particle:SetGravity(Vector(0, 0, -40))
			
			-- Rainbow color cycling
			local hue = (CurTime() * 100 + i * 90) % 360
			local color = HSVToColor(hue, 0.8, 1.0)
			particle:SetColor(color.r, color.g, color.b)
			
			particle:SetLighting(false)
			particle:SetCollide(true)
			particle:SetBounce(0.6)
		end
	end
	
	emitter:Finish()
	
	-- Dynamic light for platinum sparkle
	local dlight = DynamicLight(self:EntIndex())
	if dlight then
		dlight.Pos = pos
		dlight.r = 255
		dlight.g = 255
		dlight.b = 255
		dlight.Brightness = 2 * scale
		dlight.Size = 80 * scale
		dlight.Decay = 300
		dlight.DieTime = CurTime() + 0.4
		dlight.Style = 0
	end
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end 