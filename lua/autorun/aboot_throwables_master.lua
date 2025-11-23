--AdventureBoots 2025
-- Convenience function for calculating projectile trajectory

--[[
	Calculates where a solid entity's position will be after a given time,
	taking into account gravity, air density, drag, and mass.
	
	@param startPos Vector - Starting position
	@param startVel Vector - Starting velocity
	@param time number - Time to simulate (in seconds)
	@param entity Entity (optional) - The entity to get physics properties from
	@param mass number (optional) - Mass of the object (used if entity not provided)
	@param drag number (optional) - Drag coefficient (used if entity not provided)
	
	@return Vector newPos - New position after time
	@return Vector newVel - New velocity after time
]]
function ABoot_CalculateProjectileTrajectory(startPos, startVel, time, entity, mass, drag)
	-- Get physics environment settings
	local gravity = physenv.GetGravity()
	local airDensity = physenv.GetAirDensity()
	
	-- Get entity properties if entity is provided
	if IsValid(entity) then
		local phys = entity:GetPhysicsObject()
		if IsValid(phys) then
			mass = mass or phys:GetMass()
			drag = drag or phys:GetSpeedDamping() or 0
		end
	end
	
	-- Default values if not provided
	mass = mass or 1
	drag = drag or 0
	
	-- Ensure minimum mass to avoid division by zero
	mass = math.max(mass, 0.001)
	
	-- Air density factor (normalize to standard air density ~1.225 kg/m³)
	-- Source engine air density is typically around 0.1-0.2, so we'll scale accordingly
	local airDensityFactor = airDensity / 0.15 -- Normalize to typical GMod air density
	
	-- Effective drag coefficient accounting for air density
	-- Drag force: F = -drag_coefficient * velocity * air_density_factor
	-- The drag coefficient from GetSpeedDamping() is already tuned, but we scale by air density
	local effectiveDrag = drag * airDensityFactor
	
	-- Drag decay constant: k = drag / mass
	local dragConstant = effectiveDrag / mass
	
	-- Handle zero or very small drag (linear motion)
	if dragConstant < 0.0001 then
		-- Simple linear motion with gravity
		local newVel = startVel + gravity * time
		local newPos = startPos + startVel * time + 0.5 * gravity * time * time
		return newPos, newVel
	end
	
	-- Analytical solution for velocity with drag and gravity
	-- For each component i: v_i(t) = v0_i * e^(-k*t) + (g_i/k) * (1 - e^(-k*t))
	-- Where k = drag/mass, g_i = gravity component i
	local expTerm = math.exp(-dragConstant * time)
	local oneMinusExp = 1 - expTerm
	local dragReciprocal = 1 / dragConstant
	
	-- Calculate new velocity for all components
	local newVel = Vector(
		startVel.x * expTerm + (gravity.x * dragReciprocal) * oneMinusExp,
		startVel.y * expTerm + (gravity.y * dragReciprocal) * oneMinusExp,
		startVel.z * expTerm + (gravity.z * dragReciprocal) * oneMinusExp
	)
	
	-- Calculate new position
	-- Position integral for each component: p_i(t) = p0_i + (v0_i/k) * (1 - e^(-k*t)) + (g_i/k^2) * (k*t - 1 + e^(-k*t))
	local dragReciprocalSq = dragReciprocal * dragReciprocal
	local gravityTerm = dragConstant * time - 1 + expTerm
	
	local newPos = Vector(
		startPos.x + startVel.x * dragReciprocal * oneMinusExp + gravity.x * dragReciprocalSq * gravityTerm,
		startPos.y + startVel.y * dragReciprocal * oneMinusExp + gravity.y * dragReciprocalSq * gravityTerm,
		startPos.z + startVel.z * dragReciprocal * oneMinusExp + gravity.z * dragReciprocalSq * gravityTerm
	)
	
	return newPos, newVel
end

--[[
	Finds the entry point of a map from the skybox, given the position and velocity
	of an object about to exit through the skybox.
	
	This function simulates the object's trajectory through the skybox and finds where
	it would re-enter the map, taking into account gravity, air density, drag, and mass.
	
	@param exitPos Vector - Position where object exits through skybox
	@param exitVel Vector - Velocity when exiting through skybox
	@param entity Entity (optional) - The entity to get physics properties from
	@param mass number (optional) - Mass of the object (used if entity not provided)
	@param drag number (optional) - Drag coefficient (used if entity not provided)
	@param maxSearchTime number (optional) - Maximum time to search forward (default: 60 seconds)
	@param timeStep number (optional) - Time step for simulation (default: 0.1 seconds)
	@param filter table (optional) - Entities to filter out of traces
	
	@return Vector entryPos - Entry position where object re-enters map (nil if not found)
	@return number travelTime - Time taken to travel from exit to entry (nil if not found)
	@return Vector entryVel - Velocity when re-entering map (nil if not found)
]]
function ABoot_FindSkyboxEntryPoint(exitPos, exitVel, entity, mass, drag, maxSearchTime, timeStep, filter)
	-- Default parameters
	maxSearchTime = maxSearchTime or 60
	timeStep = timeStep or 0.1
	filter = filter or {}
	
	-- Add entity to filter if provided
	if IsValid(entity) then
		filter[#filter + 1] = entity
	end
	
	-- Current simulation state
	local currentPos = exitPos
	local currentVel = exitVel
	local elapsedTime = 0
	local maxIterations = math.ceil(maxSearchTime / timeStep)
	
	-- Step forward through time
	for i = 1, maxIterations do
		-- Calculate next position and velocity using trajectory function
		local nextPos, nextVel = ABoot_CalculateProjectileTrajectory(
			currentPos,
			currentVel,
			timeStep,
			entity,
			mass,
			drag
		)
		
		-- Check if we're back in the world
		if util.IsInWorld(nextPos) then
			-- We're in world, check if we're entering from skybox
			-- Trace backwards opposite to velocity direction to find sky entry point
			-- This matches the original implementation's approach
			local velDir = currentVel:GetNormalized()
			local traceBack = util.TraceLine({
				start = nextPos,
				endpos = nextPos - velDir * 10000,
				filter = filter,
				mask = MASK_SOLID_BRUSHONLY
			})
			
			if traceBack.HitSky then
				-- Found entry point from skybox
				local entryPos = traceBack.HitPos + (traceBack.HitNormal * -10)
				local travelTime = elapsedTime + timeStep
				return entryPos, travelTime, nextVel
			end
		end
		
		-- Update state for next iteration
		currentPos = nextPos
		currentVel = nextVel
		elapsedTime = elapsedTime + timeStep
	end
	
	-- Didn't find entry point within max search time
	return nil, nil, nil
end

