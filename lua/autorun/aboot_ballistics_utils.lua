-- AdventureBoots 2026
JModBallistics = JModBallistics or {}


-- WIP
function JModBallistics.CalculateEstimatedRange(startPos, ent, mass, force, launchDir, maxTime, timeStep)
	local timeStep = math.max(0.01, timeStep) --or GetConVar(""):GetFloat())
	local ent = IsValid(ent) and ent or nil
	if not ent and not(mass and force) or (not launchDir or not startPos) then
		return 0
	end
	
	-- Get launch angle for display
	local WorldUp = Vector(0, 0, 1)
	local DotProduct = launchDir:Dot(WorldUp)
	local RawAngle = math.deg(math.acos(math.Clamp(DotProduct, -1, 1)))
	local LaunchAngle = 0
	if RawAngle <= 90 then
		LaunchAngle = 90 - RawAngle
	end
	
	-- Get mass and drag for trajectory calculation
	-- Use the stored projectile mass, and a reasonable default drag value
	-- Most physics objects in GMod have drag around 0-0.1, we'll use a small default
	local drag = 0.1 -- Default drag coefficient
	
	-- Simulate trajectory until projectile hits ground or stops moving forward
	local currentPos = startPos
	local currentVel = (launchDir * force) / mass
	local maxTime = math.min(maxTime or 1, 60) -- Maximum simulation time (60 seconds)
	local peakHeight = startPos.z -- Track the highest point reached
	local hasReachedPeak = false
	local timeElapsed = 0
	
	while timeElapsed < maxTime do
		timeElapsed = timeElapsed + timeStep
		-- Calculate next position and velocity using trajectory function
		local nextPos, nextVel = JMod.CalculateProjectileTrajectory(
			currentPos,
			currentVel,
			timeStep,
			ent,
			mass,
			drag
		)
		
		-- Check if projectile has hit the ground
		local currentHeight = nextPos.z
		local horizontalPos = Vector(nextPos.x, nextPos.y, 0)
		
		-- Track peak height
		if currentHeight > peakHeight then
			peakHeight = currentHeight
		elseif not hasReachedPeak and currentHeight < peakHeight then
			-- We've passed the peak and are now descending
			hasReachedPeak = true
		end
		
		-- If we've reached peak and are descending below starting height, we've hit ground
		-- (Assuming ground is at or near the starting height)
		if hasReachedPeak and currentHeight <= startPos.z and nextVel.z <= 0 then
			-- Projectile has landed
			local horizontalRange = Vector(startPos.x, startPos.y, 0):Distance(horizontalPos)
			
			-- Convert to meters (1 Source unit = 0.01905 meters)
			local MetersPerUnit = 0.01905
			local EstimatedRangeMeters = horizontalRange * MetersPerUnit
			
			return math.floor(horizontalRange), math.floor(EstimatedRangeMeters), math.floor(LaunchAngle), nextPos
		end
		
		-- If horizontal velocity is very low and we're moving downward, projectile has essentially stopped
		local horizontalVel = Vector(nextVel.x, nextVel.y, 0):Length()
		if horizontalVel < 10 and nextVel.z < 0 then
			local horizontalRange = Vector(startPos.x, startPos.y, 0):Distance(horizontalPos)
			local MetersPerUnit = 0.01905
			local EstimatedRangeMeters = horizontalRange * MetersPerUnit
			return math.floor(horizontalRange), math.floor(EstimatedRangeMeters), math.floor(LaunchAngle), nextPos
		end
		
		-- Update for next iteration
		currentPos = nextPos
		currentVel = nextVel
		lastHeight = currentHeight
		lastHorizontalPos = horizontalPos
	end
	
	-- If we've exceeded max time, return the final position
	local horizontalPos = Vector(currentPos.x, currentPos.y, 0)
	local horizontalRange = Vector(startPos.x, startPos.y, 0):Distance(horizontalPos)
	local MetersPerUnit = 0.01905
	local EstimatedRangeMeters = horizontalRange * MetersPerUnit
	return math.floor(horizontalRange), math.floor(EstimatedRangeMeters), math.floor(LaunchAngle), currentPos
end

if SERVER then
	function JModBallistics.CreateProjectileTracker(projectile, launchVector, hadMotion, hullSize, filter)
		local timerName = "JMod_EZCannon_Tracker_" .. projectile:EntIndex()

		local phys = projectile:GetPhysicsObject()
		if not IsValid(phys) then return end
		filter = filter or {projectile}
		
		-- Get server tick rate for consistent step timing
		local tickRate = engine.TickInterval()
		local maxVelLimit = GetConVar("sv_maxvelocity"):GetFloat()
		
		-- Initialize velocity tracking (as a vector)
		local currentVelVector = launchVector
		
		-- Get projectile center offset from origin (local space)
		local projectileCenterLocal = projectile:OBBCenter()
		
		-- Track center position (not origin position) to account for origin offset
		-- Use LocalToWorld to convert local center to world space (accounts for position and rotation)
		local currentCenterPos = projectile:LocalToWorld(projectileCenterLocal)
		
		-- Step-based teleportation and velocity reduction timer
		timer.Create(timerName, tickRate, 0, function()
			if not IsValid(projectile) or not IsValid(phys) or (hadMotion and phys:IsMotionEnabled()) then
				timer.Remove(timerName)
				return
			end
			
			-- Use the unified trajectory calculation function on the center position
			local nextCenterPos, nextVelVector = JMod.CalculateProjectileTrajectory(
				currentCenterPos,
				currentVelVector,
				tickRate,
				projectile
			)
			
			-- Get current velocity magnitude for limit checking
			local currentVelocity = currentVelVector:Length()
			
			-- Trace from center to center to check for obstructions
			-- Hull bounds are centered at 0 since we're tracing from the center
			local tr = util.TraceHull({
				start = currentCenterPos,
				endpos = nextCenterPos,
				mins = -hullSize * 0.5,
				maxs = hullSize * 0.5,
				filter = filter
			})

			-- Calculate origin position from center position
			-- Get current center offset in world space (accounts for rotation)
			local currentProjectileCenter = projectile:LocalToWorld(projectileCenterLocal)
			local currentProjectilePos = projectile:GetPos()
			local centerOffsetWorld = currentProjectileCenter - currentProjectilePos
			
			if tr.Hit then
				-- Hit detected at center position
				local hitCenterPos = tr.HitPos

				debugoverlay.Cross(hitCenterPos, 10, 5, Color(255, 0, 0), true)
				debugoverlay.Line(currentCenterPos, hitCenterPos, 5, Color(255, 0, 0), true)
				debugoverlay.Box(hitCenterPos, -hullSize * 0.5, hullSize * 0.5, 5, Color(255, 0, 0))
				
				if hadMotion then
					phys:EnableMotion(true)
				end
				-- Use the calculated velocity, but ensure it's at least maxVelLimit
				local finalVel = nextVelVector:Length()
				if finalVel < maxVelLimit then
					phys:SetVelocity(launchDir * maxVelLimit)
				else
					phys:SetVelocity(nextVelVector)
				end

				timer.Remove(timerName)

				return
			end
			-- Set origin position so center ends up at nextCenterPos
			local nextOriginPos = nextCenterPos - centerOffsetWorld
			
			-- Update position (set origin, which will place center at nextCenterPos)
			projectile:SetPos(nextOriginPos)
			
			-- Update state for next iteration
			-- Recalculate center position after setting position (accounts for any rotation changes)
			currentCenterPos = projectile:LocalToWorld(projectileCenterLocal)
			currentVelVector = nextVelVector
			debugoverlay.Line(currentCenterPos, nextCenterPos, 5, Color(0, 204, 255), true)
			
			-- Check if velocity has dropped below max limit
			local nextVelocity = nextVelVector:Length()
			
			if nextVelocity <= maxVelLimit then
				-- Velocity reduced to max, hand off to physics
				if hadMotion then
					phys:EnableMotion(true)
				end
				-- Normalize direction and apply max velocity
				local finalDir = nextVelVector:GetNormalized()
				phys:SetVelocity(finalDir * maxVelLimit)
				timer.Remove(timerName)
				return
			end
			
			-- Update state for next iteration (track center position)
			currentCenterPos = nextCenterPos
			currentVelVector = nextVelVector
		end)
	end
end