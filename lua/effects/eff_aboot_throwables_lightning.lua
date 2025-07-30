--AdventureBoots 2025
function EFFECT:Init(data)
	local startPos = data:GetOrigin()
	local endPos = data:GetStart()
	local scale = data:GetScale() or 1
	
	if not startPos or not endPos then return end
	
	local emitter = ParticleEmitter(startPos)
	if not emitter then return end
	
	-- Create lightning bolt effect
	local distance = startPos:Distance(endPos)
	local segments = math.floor(distance / 20)
	
	for i = 1, segments do
		local progress = i / segments
		local basePos = LerpVector(progress, startPos, endPos)
		local offset = VectorRand() * 10 * scale
		local pos = basePos + offset
		
		-- Lightning spark
		local particle = emitter:Add("sprites/mat_jack_nicespark", pos)
		if particle then
			particle:SetVelocity(VectorRand() * 50)
			particle:SetLifeTime(0)
			particle:SetDieTime(math.Rand(0.05, 0.15))
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(0)
			particle:SetStartSize(math.Rand(2, 4) * scale)
			particle:SetEndSize(0)
			particle:SetRoll(math.Rand(-360, 360))
			particle:SetRollDelta(math.Rand(-2, 2))
			particle:SetAirResistance(100)
			particle:SetGravity(Vector(0, 0, 0))
			particle:SetColor(100, 150, 255) -- Blue lightning
			particle:SetLighting(false)
			particle:SetCollide(false)
		end
		
		-- Additional smaller sparks
		if math.random(1, 3) == 1 then
			local sparkPos = pos + VectorRand() * 5
			local spark = emitter:Add("sprites/mat_jack_nicespark", sparkPos)
			if spark then
				spark:SetVelocity(VectorRand() * 30)
				spark:SetLifeTime(0)
				spark:SetDieTime(math.Rand(0.02, 0.08))
				spark:SetStartAlpha(200)
				spark:SetEndAlpha(0)
				spark:SetStartSize(math.Rand(1, 2) * scale)
				spark:SetEndSize(0)
				spark:SetRoll(math.Rand(-360, 360))
				spark:SetRollDelta(math.Rand(-1, 1))
				spark:SetAirResistance(50)
				spark:SetGravity(Vector(0, 0, 0))
				spark:SetColor(150, 200, 255) -- Lighter blue
				spark:SetLighting(false)
				spark:SetCollide(false)
			end
		end
	end
	
	emitter:Finish()
	
	-- Dynamic light for lightning
	local dlight = DynamicLight(self:EntIndex())
	if dlight then
		dlight.Pos = startPos
		dlight.r = 100
		dlight.g = 150
		dlight.b = 255
		dlight.Brightness = 2 * scale
		dlight.Size = 100 * scale
		dlight.Decay = 1000
		dlight.DieTime = CurTime() + 0.1
		dlight.Style = 0
	end
	
	-- Sound effect
	sound.Play("ambient/energy/zap" .. math.random(1, 3) .. ".wav", startPos, 75, math.Rand(90, 110))
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end 