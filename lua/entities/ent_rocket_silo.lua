AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName = "Rocket Silo"
ENT.Category = "JMod - EZ Misc."

-- It's important that we use the translucent rendergroup because it renders last
-- If we used opaque instead, translucent objects would draw on top of the impossible geometry
-- and the effect would be ruined.
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.Spawnable = true
ENT.AdminOnly = false
ENT.AutomaticFrameAdvance = true

if SERVER then
	function ENT:Initialize()
		self:SetModel("models/props_silo/silo_hatch_fixed.mdl")
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
		end
		self:CreateBoneFollowers()
		self:ResetSequence(self:LookupSequence("open"))
	end

	function ENT:Think()
		self:UpdateBoneFollowers()
		self:NextThink(CurTime())

		return true
	end
end
if CLIENT then

	local COLOR_BLACK = Color( 0, 0, 0 )

	-- The size of the opening mask
	local OPENING_WIDTH = 175
	local OPENING_HEIGHT = 175
	
	-- How far from the center of the entity to place the opening mask
	local OPENING_DEPTH = -5

	function ENT:OnRemove( isFullUpdate )
		-- Clientside models need to be removed manually
		if self.clientsideModel and IsValid( self.clientsideModel ) then
			self.clientsideModel:Remove()
		end
	end

	local tubeMdl, plateMdl = Model("models/hunter/tubes/tube4x4x16.mdl"), Model("models/props_phx/construct/metal_plate1.mdl")
	local rocketMdl, hatchMdl = Model("models/props_silo/rocket_low.mdl"), Model("models/props_silo/silo_hatch.mdl")
	local wallMat = Material("phoenix_storms/metalfloor_2-3")

	function ENT:Initialize()
		-- We'll be using this Clientside Model to draw the interior of the entity
		self.clientsideModel = ClientsideModel( hatchMdl, RENDERGROUP_OPAQUE )
		self.clientsideModel:SetNoDraw( true )
	end

	local UpSpot = Vector(0, 0, 10)
	-- Just a convenience function.  The main difference between this and 
	-- render.DrawModel() is that this also renders flashlights.
	function ENT:DrawClientsideModel(model, pos, angles, scale, mat)
		
		local GoodPos = self:LocalToWorld(UpSpot)
		local LightColor = render.GetLightColor(GoodPos)
		self.clientsideModel:SetModel(model)
		self.clientsideModel:SetPos(pos)
		self.clientsideModel:SetAngles(angles)
		local Matricks = Matrix()
		Matricks:Scale(scale)
		self.clientsideModel:EnableMatrix("RenderMultiply", Matricks)
		render.SuppressEngineLighting(true)
		render.SetModelLighting(BOX_TOP, LightColor[1], LightColor[2], LightColor[3])
		if mat then
			self.clientsideModel:SetMaterial(mat:GetName())
		end
		self.clientsideModel:DrawModel()
		if mat then
			self.clientsideModel:SetMaterial(nil)
		end
		render.RenderFlashlights( function() self.clientsideModel:DrawModel() end )
		render.SuppressEngineLighting(false)
		self.clientsideModel:DisableMatrix("RenderMultiply")
	end

	function ENT:DrawInterior()
		local interiorAngles = self:GetAngles()
		local interiorPos = self:LocalToWorld( Vector(0, 0, -850))
		local rocketPos = self:LocalToWorld( Vector(0, 0, -1400))
		--local hatchPos = self:LocalToWorld( Vector(0, 0, 0))
		
		--self:DrawClientsideModel( hatchMdl, hatchPos, interiorAngles, Vector(1, 1, 1) )
		self:DrawClientsideModel( tubeMdl, interiorPos, interiorAngles, Vector(2, 2, 2), wallMat )
		--self:DrawClientsideModel( plateMdl, interiorPos, interiorAngles, Vector(12, 12, 1) )
		self:DrawClientsideModel( rocketMdl, rocketPos, interiorAngles, Vector(1, 1, 1) )

		local Up = interiorAngles:Up()
		local Count, Spacing = 50, 20
		for i = 1, Count do
			local pos = self:LocalToWorld( Vector(0, 0, -200 - i * Spacing))
			local t = i / Count
			local darkness = 255 * math.ease.OutExpo(t)
			render.DrawQuadEasy(pos, Up, 500, 500, Color(0, 0, 0, darkness), 0)
		end
	end

	-- The opening mask is a fan of 4 triangular quads arranged to make a circle
	function ENT:DrawOpeningMask()
		render.SetColorMaterial()
		
		local center = self:LocalToWorld( Vector( 0, 0, OPENING_DEPTH ) )
		local radius = OPENING_WIDTH
		
		-- Create 4 triangular quads in a fan pattern to approximate a circle
		for i = 0, 3 do
			local angle1 = math.rad(i * 90)
			local angle2 = math.rad((i + 0.5) * 90)
			local angle3 = math.rad((i + 1) * 90)
			
			-- Calculate the two edge points of the triangle
			local x1, y1 = math.cos(angle1) * radius, math.sin(angle1) * radius
			local x2, y2 = math.cos(angle2) * radius, math.sin(angle2) * radius
			local x3, y3 = math.cos(angle3) * radius, math.sin(angle3) * radius
			
			-- Convert to world positions
			local edge1 = self:LocalToWorld( Vector( x1, y1, OPENING_DEPTH ) )
			local edge2 = self:LocalToWorld( Vector( x2, y2, OPENING_DEPTH ) )
			local edge3 = self:LocalToWorld( Vector( x3, y3, OPENING_DEPTH ) )
			
			-- Draw triangular quad: center -> edge1 -> edge2 -> duplicate edge2 for quad format
			render.DrawQuad(
				center,
				edge3,
				edge2,
				edge1,
				COLOR_BLACK
			)
		end
	end

	function ENT:Draw()
		
		self:DrawModel()

		-- The Halo system also uses Stencils, so we'll be polite and avoid messing with them while it's drawing
		-- If we didn't do this, the Halo system would break and the entire screen would flash very unpleasantly 
		-- when the entity is grabbed with the physgun.
		local isDrawingHalo = halo.RenderedEntity() == self
		if isDrawingHalo then
			return
		end

		-- Reset the Stencil system to values we know aren't going to cause problems
		render.ClearStencil()
		render.SetStencilWriteMask( 255 )
		render.SetStencilTestMask( 255 )
		render.SetStencilPassOperation( STENCILOPERATION_KEEP )
		render.SetStencilZFailOperation( STENCILOPERATION_KEEP )

		render.SetStencilEnable( true )

		-- We'll use Stencil Buffer value 1 as the value representing the opening mask
		render.SetStencilReferenceValue( 1 )

		-- We only care about the Depth Test right now, so don't bother with the compare function
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_ALWAYS )
		
		-- Start creating the opening mask
		render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
	
		-- Here we rely on the fact that a quad only draws when viewed from the front.
		-- From the back, it doesn't draw at all. This is called "backface culling" and
		-- without it the interior would draw on top of the entity even when viewed from the back.
		self:DrawOpeningMask()
		
		-- Don't modify the mask now that it's created
		render.SetStencilFailOperation( STENCILOPERATION_KEEP )
		
		-- We now want to only draw where the mask is set (Stencil Buffer values match the Reference Value)
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )

		-- Clear the Depth Buffer on the masked pixels
		-- Otherwise, the pixels from the entity and any surface behind it will always be 
		-- in front of the interior and thus the interior will never draw.
		render.ClearBuffersObeyStencil( 0, 0, 0, 255, true )

		self:DrawModel()
		self:DrawInterior()

		render.SetStencilEnable( false )
		--self:DrawInterior()
	end
end