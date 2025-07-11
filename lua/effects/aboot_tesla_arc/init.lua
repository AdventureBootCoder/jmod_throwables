local LightningMat = Material("cable/blue_elec")
function EFFECT:Init(data)
	local origin = data:GetOrigin()
	local magnitude = data:GetScale() or 1
	local radius = data:GetRadius() or 100
	local numTraces = math.floor(magnitude * 3) -- Base 3 traces, multiplied by magnitude
	
	for i = 1, numTraces do
		local trace = util.TraceLine({
			start = origin,
			endpos = origin + VectorRand() * radius
		})
		if trace.Hit then
			render.SetMaterial(LightningMat)
			render.StartBeam(3)
			render.AddBeam(origin, 10, 0, Color(100, 150, 255))
			local Halfway = origin + (trace.HitPos - origin) / 2
			render.AddBeam(Halfway + VectorRand() * radius * 0.25, 10, .5, Color(100, 150, 255))
			render.AddBeam(trace.HitPos, 10, 1, Color(100, 150, 255))
			render.EndBeam()
		end
	end
end

--function EFFECT:Think()
	--return false -- Effect is instant, no thinking needed
--end

--function EFFECT:Render()
	-- No custom rendering needed, effects are handled by other effects
--end 