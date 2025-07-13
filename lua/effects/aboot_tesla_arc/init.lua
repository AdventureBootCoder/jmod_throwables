local LightningMat = Material("cable/blue_elec")
function EFFECT:Init(data)
	self.AttachEntity = data:GetEntity()
	self.Origin = data:GetOrigin()
	if IsValid(self.AttachEntity) then self.Origin = self.AttachEntity:GetPos() end
	local magnitude = data:GetScale() or 1
	self.Radius = data:GetRadius() or 100
	local numTraces = math.floor(magnitude * 3) -- Base 3 traces, multiplied by magnitude
	
	self.ZapPositions = {}
	for i = 1, numTraces do
		local trace = util.TraceLine({
			start = self.Origin,
			endpos = self.Origin + VectorRand() * self.Radius
		})
		self.ZapPositions[i] = trace.HitPos
	end

	self.RemoveTime = CurTime() + 5
end

function EFFECT:Think()
	if IsValid(self.AttachEntity) then self.Origin = self.AttachEntity:GetPos() end
	if (self.RemoveTime >= CurTime()) then
		self:Remove()
	end
end

local SpriteMat = Material("sprites/light_glow02_add")
local SpriteColor = Color(100, 150, 255)

function EFFECT:Render()
	for i = 1, #self.ZapPositions do
		local ZapPos = self.ZapPositions[i] + VectorRand() * 2
		render.SetMaterial(LightningMat)
			render.StartBeam(3)
			render.AddBeam(self.Origin, 10, 0, SpriteColor)
			local Halfway = self.Origin + (ZapPos - self.Origin) / 2
			render.AddBeam(Halfway + VectorRand() * self.Radius * 0.25, 10, .5, SpriteColor)
			render.AddBeam(ZapPos, 10, 1, SpriteColor)
			render.DrawSprite(ZapPos, 5, 5)
		render.EndBeam()
	end
end 