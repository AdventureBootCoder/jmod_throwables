--AdventureBoots 2025
-- Networking for autoloader entity
JModBallistics = JModBallistics or {}

JModBallistics.ProjectileSpecs = {}
JModBallistics.ProjectileSpecs["ent_aboot_ezcannon"] = {
	includes = {}, -- special table for referencing other specs
	types = {
		["prop_physics"] = {
			UsePropModel = true,
			DisplayName = "Prop Physics"
		},
		["ent_jack_gmod_ezincendiarybomb"] = {
			ArmDelay = .1,
			DisplayName = "Incendiary Bomb"
		},
		["ent_jack_gmod_ezthermobaricbomb"] = {
			ArmDelay = .1,
			DisplayName = "Thermobaric Bomb"
		},
		["ent_jack_gmod_ezclusterbomb"] = {
			ArmDelay = .1,
			DisplayName = "Cluster Bomb"
		},
		["ent_jack_gmod_ezsmallbomb"] = {
			ArmDelay = 1,
			DisplayName = "Small Bomb"
		},
		["ent_jack_gmod_ezhebomb"] = {
			ArmDelay = .2,
			DisplayName = "HE Bomb"
		},
		["ent_jack_gmod_ezfumigator"] = {
			ArmDelay = .5,
			ArmMethod = "Fume",
			RightCorrection = -90,
			DisplayName = "Fumigator"
		},
		["ent_jack_gmod_ezflareprojectile"] = {
			ForceMult = .1,
			DisplayName = "Flare Projectile"
		},
		["ent_jack_gmod_eznuke_small"] = {	
			ArmDelay = 1,
			DisplayName = "Small Nuke"
		},
		["ent_jack_gmod_ezcriticalityweapon"] = {
			ArmDelay = 3,
			ArmMethod = "Detonate",
			DisplayName = "Criticality Weapon"
		},
		["ent_jack_gmod_ezpowderkeg"] = {
			ArmDelay = .2,
			ArmMethod = "Detonate",
			DisplayName = "Powder Keg"
		},
		["ent_aboot_ezshot"] = {
			ArmDelay = .1,
			DisplayName = "Cannon Shot"
		},
		["ent_aboot_ezshot_plasma"] = {
			ArmDelay = .1,
			DisplayName = "Plasma Shot"
		},
		["ent_aboot_ezshot_cannister"] = {
			ArmDelay = .05,
			DisplayName = "Cannister Shot"
		},
		["ent_aboot_ezshot_angler"] = {
			ArmDelay = .1,
			Angles = Angle(0, 90, 0),
			DisplayName = "Angler Shot"
		},
		["ent_aboot_ezshot_ceramic"] = {
			ArmDelay = .1,
			DisplayName = "Ceramic Shot"
		},
		["ent_aboot_ezshot_copper"] = {
			ArmDelay = .1,
			DisplayName = "Copper Shot"
		},
		["ent_aboot_ezshot_uranium"] = {
			ArmDelay = .1,
			DisplayName = "Uranium Shot"
		},
		["ent_aboot_ezshot_silver"] = {
			ArmDelay = .1,
			DisplayName = "Silver Shot"
		},
		["ent_aboot_ezshot_gold"] = {
			ArmDelay = .1,
			DisplayName = "Gold Shot"
		},
		["ent_aboot_ezshot_platinum"] = {
			ArmDelay = .1,
			DisplayName = "Platinum Shot"
		},
		["ent_aboot_ezshot_rubber"] = {
			ArmDelay = .1,
			DisplayName = "Rubber Shot"
		},
		["ent_aboot_ezshot_tungsten"] = {
			ArmDelay = .1,
			DisplayName = "Tungsten Shot"
		}
	}
}
JModBallistics.ProjectileSpecs["ent_aboot_ezcannon_small"] = {
	types = {
		["prop_physics"] = {
			UsePropModel = true
		},
		["ent_aboot_ezshot_shell"] = {
			PowderAdd = 25,
			DisplayName = "Shell Shot",
			Angles = Angle(-90, 0, 0),
			ArmMethod = "Launch"
		},
		["ent_jack_gmod_ezherocket"] = {
			ArmDelay = .2,
			PowderAdd = 50,
			Angles = Angle(0, 0, 90),
			LaunchOffset = Vector(-30, 1.5, 0)
		},
		["ent_jack_gmod_ezheatrocket"] = {
			ArmDelay = .2,
			PowderAdd = 50,
			Angles = Angle(0, 0, 90),
			LaunchOffset = Vector(-30, 1.5, 0)
		},
		["ent_jack_gmod_ezstickynade"] = {
			Angles = Angle(180, 0, 0)
		},
		["ent_jack_gmod_ezfragnade"] = {
			ArmDelay = 0
		},
		["ent_jack_gmod_ezimpactnade"] = {
			Angles = Angle(180, 0, 0),
			LaunchOffset = Vector(-4.25, 0, -3),
		},
		["ent_jack_gmod_ezfirenade"] = {
			ArmDelay = .05
		},
		["ent_jack_gmod_ezflashbang"] = {
			ArmDelay = .05
		},
		["ent_jack_gmod_ezsmokegrenade"] = {
			ArmDelay = .05
		},
		["ent_jack_gmod_ezroadflare"] = {
			ArmDelay = .5
		},
		["ent_jack_gmod_ezflareprojectile"] = {
			ForceMult = .1
		}
	}
}

local function UpdateProjectileSpecs()
	for class, specsTable in pairs(JModBallistics.ProjectileSpecs) do
		if specsTable.includes then
			for _, includeStr in pairs(specsTable.includes) do -- This might not actually work, we'll see
				table.Merge(specsTable.types, JModBallistics.ProjectileSpecs[includeStr].types, true)
			end
		end

		for _, ent in pairs(ents.FindByClass(class)) do
			if IsValid(ent) then ent.ProjectileSpecs = specsTable.types end
		end
	end
end

JModBallistics.ProjectilesInitialized = JModBallistics.ProjectilesInitialized or false

hook.Add("InitPostEntity", "JMod_Ballistics_UpdateProjectileSpecs", function()
	UpdateProjectileSpecs()
	JModBallistics.ProjectilesInitialized = true
end)

if JModBallistics.ProjectilesInitialized then
	UpdateProjectileSpecs()
end

if SERVER then
	util.AddNetworkString("JMod_EZAutoloader_ModifyConnections")

	net.Receive("JMod_EZAutoloader_ModifyConnections", function(ln, ply)
		if not ply:Alive() then return end
		local Ent, Action = net.ReadEntity(), net.ReadString()
		if not IsValid(Ent) then return end
		local Ent2 = net.ReadEntity()
		if (JMod.GetEZowner(Ent) ~= ply) or (ply:GetPos():Distance(Ent:GetPos()) > 500) then return end

		if Action == "connect" then
			-- Start resource connection - creates a plug the player can drag
			JMod.StartResourceConnection(Ent, ply, "Entity")
		elseif Action == "disconnect" then
			if not IsValid(Ent2) then return end
			JMod.RemoveResourceConnection(Ent, Ent2)
		elseif Action == "disconnect_all" then
			if Ent.DisconnectAll then
				Ent:DisconnectAll()
			else
				JMod.RemoveResourceConnection(Ent)
			end
		elseif Action == "toggle" then
			if IsValid(Ent2) and JMod.ConnectionValid(Ent, Ent2) and Ent2.GetState then 
				if Ent2:GetState() == JMod.EZ_STATE_OFF then
					Ent2:TurnOn(ply)
				elseif Ent2:GetState() >= JMod.EZ_STATE_ON then
					Ent2:TurnOff(ply)
				end
			end
		elseif Action == "toggle_autoloading" then
			if IsValid(Ent2) and JMod.ConnectionValid(Ent, Ent2) and Ent2.GetIsAutoLoading then
				Ent2:SetIsAutoLoading(not Ent2:GetIsAutoLoading())
			end
		end
	end)

	net.Receive("JMod_EZCannon_Command", function(len, ply)
		local cannon = net.ReadEntity()
		local command = net.ReadString()
		
		-- Security checks
		if not IsValid(cannon) then return end
		if not IsValid(ply) or not ply:IsPlayer() then return end
		
		-- Check ownership
		local owner = JMod.GetEZowner(cannon)
		local isOwner = not(IsValid(owner)) or (owner and owner == ply)
		local distance = cannon:GetPos():Distance(ply:GetPos())

		if not isOwner or (distance > 256) then

			return
		end
		
		-- Process commands
		if command == "open" then
			net.Start("JMod_EZCannon_Command")
				net.WriteEntity(cannon)
				net.WriteString("open")
				net.WriteString(IsValid(cannon.LoadedProjectileEnt) and (cannon.LoadedProjectileType or "") or "")
				net.WriteUInt(cannon.Propellant or 0, 8)
				net.WriteUInt(cannon.CurrentPropellantPerShot or 20, 8)
				net.WriteString(cannon:GetDesiredProjectileClass() or "")
			net.Send(ply)
		elseif command == "fire" then
			if IsValid(cannon.LoadedProjectileEnt) and cannon.LoadedProjectileType then
				cannon:LaunchProjectile(false, ply)
			end
		elseif command == "unload" then
			cannon:UnloadProjectile()
		elseif command == "setpropellant" then
			local propellant = net.ReadUInt(8)
			-- Validate propellant value
			cannon.CurrentPropellantPerShot = math.Clamp(propellant, 1, cannon.MaxPropellant or 100)
			cannon:UpdateWireOutputs()
		elseif command == "setdesiredprojectile" then
			local projectileClass = net.ReadString()
			cannon:SetDesiredProjectileClass(projectileClass)
			cannon:SyncStateToClients()
		elseif command == "setautoloading" then
			local isAutoLoading = net.ReadBool()
			cannon:SetIsAutoLoading(isAutoLoading)
		end
	end)
end

if CLIENT then
	local MachineStatus = {
		[-1] = {"BROKEN", "icon16/bullet_red.png"},
		[0] = {"OFFLINE", "icon16/bullet_black.png"},
		[1] = {"ONLINE", "icon16/bullet_green.png"}
	}

	net.Receive("JMod_EZAutoloader_ModifyConnections", function()
		local Ent = net.ReadEntity()
		local Connections = net.ReadTable()
		local Frame = vgui.Create("DFrame")
		Frame:SetTitle("Modify Autoloader Connections ["..Ent:EntIndex().."]")
		Frame:SetSize(300, 400)
		Frame:Center()
		Frame:MakePopup()

		function Frame:Paint()
			EZBlurBackground(self)
		end

		local List = vgui.Create("DListView", Frame)
		List:Dock(FILL)
		List:SetMultiSelect(false)
		List:AddColumn("Cannon")
		List:AddColumn("EntID"):SetMaxWidth(35)
		List:AddColumn("Status"):SetMaxWidth(100)
		List:AddColumn("Autoload"):SetMaxWidth(70)

		for _, connection in ipairs(Connections) do
			local Line = List:AddLine(connection.DisplayName, connection.Index)
			local Machine = Entity(connection.Index)
			if IsValid(Machine) then
				local StatusIcon = vgui.Create("DImage", Line)
				if Machine.GetState then
					local State = math.Clamp(Machine:GetState(), -1, 1)
					StatusIcon:SetImage(MachineStatus[State][2])
					Line:SetColumnText(3, MachineStatus[State][1])
				else
					StatusIcon:SetImage("icon16/bullet_black.png")
				end
				StatusIcon:SetSize(16, 16)
				StatusIcon:Dock(RIGHT)
				
				-- Show autoloading status
				if Machine.GetIsAutoLoading then
					local autoloadStatus = Machine:GetIsAutoLoading() and "ON" or "OFF"
					Line:SetColumnText(4, autoloadStatus)
				else
					Line:SetColumnText(4, "N/A")
				end
			end
		end

		local ButtonOptions = {
			{Text = "Connect New", Func = "connect", Icon = "icon16/connect.png"},
			{Text = "Disconnect", Func = "disconnect", Icon = "icon16/disconnect.png"},
			{Text = "Disconnect All", Func = "disconnect_all", Icon = "icon16/disconnect.png"},
			{Text = "Toggle Machine", Func = "toggle", Icon = "icon16/application_lightning.png"}
		}

		List.OnRowSelected = function(panel, rowIndex, row)
			-- Open a dropdown menu to either turn on and off machine or disconnect it
			local DropDown = vgui.Create("DMenu", Frame)
			DropDown:SetSize(150, 20)
			DropDown:SetX(List:GetX() + List:GetWide() - DropDown:GetWide() - 8)
			DropDown:SetY(List:GetY() + 15 + (rowIndex * 17))
			for k, v in ipairs(ButtonOptions) do
				if (v.Func ~= "connect") and (v.Func ~= "disconnect_all") and not ((v.Func == "toggle") and List:GetLine(rowIndex):GetValue(3) == "BROKEN") then
					local Option = DropDown:AddOption(v.Text, function()
						net.Start("JMod_EZAutoloader_ModifyConnections")
							net.WriteEntity(Ent)
							net.WriteString(v.Func)
							net.WriteEntity(Entity(tonumber(row:GetValue(2))))
						net.SendToServer()
						Frame:Close()
					end)
					Option:SetIcon(v.Icon)
				end
			end
			
			-- Add autoloading toggle option if it's a cannon
			local Machine = Entity(tonumber(row:GetValue(2)))
			if IsValid(Machine) and Machine.GetIsAutoLoading then
				local autoloadOption = DropDown:AddOption("Toggle Autoloading", function()
					net.Start("JMod_EZAutoloader_ModifyConnections")
						net.WriteEntity(Ent)
						net.WriteString("toggle_autoloading")
						net.WriteEntity(Machine)
					net.SendToServer()
					Frame:Close()
				end)
				autoloadOption:SetIcon("icon16/arrow_refresh.png")
			end
		end

		for k, v in ipairs(ButtonOptions) do
			if (v.Func ~= "disconnect") then
				local SelectButton = vgui.Create("DButton", Frame)
				SelectButton:SetText(v.Text)
				SelectButton:SetHeight(22)
				SelectButton:Dock(BOTTOM)
				SelectButton.DoClick = function()
					if v.Func == "disconnect_all" then
						local ConfirmPopup = vgui.Create("DFrame")
						ConfirmPopup:SetTitle("Confirm Disconnect All")
						ConfirmPopup:SetSize(300, 100)
						ConfirmPopup:Center()
						ConfirmPopup:MakePopup()

						local ConfirmButton = vgui.Create("DButton", ConfirmPopup)
						ConfirmButton:SetText("Disconnect All")
						ConfirmButton:SetHeight(22)
						ConfirmButton:Dock(BOTTOM)
						ConfirmButton.DoClick = function()
							net.Start("JMod_EZAutoloader_ModifyConnections")
								net.WriteEntity(Ent)
								net.WriteString(v.Func)
								net.WriteEntity(NULL)
							net.SendToServer()
							ConfirmPopup:Close()
						end
						ConfirmButton:DockPadding(2, 2, 2, 2)

						local CancelButton = vgui.Create("DButton", ConfirmPopup)
						CancelButton:SetText("Cancel")
						CancelButton:SetHeight(22)
						CancelButton:Dock(BOTTOM)
						CancelButton.DoClick = function()
							ConfirmPopup:Close()
						end
						CancelButton:DockPadding(2, 2, 2, 2)
					elseif v.Func == "connect" then
						-- For connecting, we need to let the player select a cannon
						-- This will use the StartResourceConnection system
						net.Start("JMod_EZAutoloader_ModifyConnections")
							net.WriteEntity(Ent)
							net.WriteString(v.Func)
							net.WriteEntity(NULL)
						net.SendToServer()
					else
						net.Start("JMod_EZAutoloader_ModifyConnections")
							net.WriteEntity(Ent)
							net.WriteString(v.Func)
							net.WriteEntity(NULL)
						net.SendToServer()
					end
					Frame:Close()
				end
				SelectButton:DockPadding(2, 2, 2, 2)
				local Icon = vgui.Create("DImage", SelectButton)
				Icon:SetImage(v.Icon)
				Icon:SetSize(16, 16)
				Icon:Dock(RIGHT)
			end
		end
	end)

	-- Networking receiver for opening GUI
	net.Receive("JMod_EZCannon_Command", function()
		local cannon = net.ReadEntity()
		local command = net.ReadString()
		
		if command == "open" then
			cannon.LoadedProjectileType = net.ReadString()
			cannon.Propellant = net.ReadUInt(8)
			cannon.CurrentPropellantPerShot = net.ReadUInt(8)
			cannon.ProjectileMass = net.ReadUInt(16)
			cannon.DesiredProjectileClass = net.ReadString()

			if IsValid(cannon) then
				JMod_EZCannon_OpenGUI(cannon)
			end
		elseif command == "state_sync" then
			if IsValid(cannon) then
				cannon.LoadedProjectileType = net.ReadString()
				cannon.Propellant = net.ReadUInt(8)
				cannon.CurrentPropellantPerShot = net.ReadUInt(8)
				cannon.ProjectileMass = net.ReadUInt(16)
				cannon.DesiredProjectileClass = net.ReadString()
			end
		end
	end)

	-- GUI function
	function JMod_EZCannon_OpenGUI(cannon)
		if not IsValid(cannon) then return end
		local CannonClass = cannon:GetClass()
		local ProjectileSpecs = JModBallistics.ProjectileSpecs[CannonClass].types
		
		local frame = vgui.Create("DFrame")
		frame:SetSize(400, 400)
		frame:Center()
		frame:SetTitle("EZ Cannon Control")
		frame:MakePopup()
		frame:SetDraggable(true)
		frame:ShowCloseButton(true)
		
		function frame:Paint()
			EZBlurBackground(frame)
		end
		
		function frame:OnKeyCodePressed(key)
			if key == KEY_Q or key == KEY_ESCAPE then
				self:Close()
			end
		end
		
		function frame:OnClose()
			surface.PlaySound("snds_jack_gmod/ez_gui/menu_close.ogg")
		end
		
		-- Status panel (left side)
		local statusPanel = vgui.Create("DPanel", frame)
		statusPanel:SetPos(10, 30)
		statusPanel:SetSize(180, 100)
		
		function statusPanel:Paint(w, h)
			surface.SetDrawColor(0, 0, 0, 100)
			surface.DrawRect(0, 0, w, h)
		end
		
		local infoLabel = vgui.Create("DLabel", statusPanel)
		infoLabel:SetPos(10, 10)
		infoLabel:SetSize(160, 80)
		
		-- Get display name for loaded projectile
		local loadedDisplayName = "None"
		if cannon.LoadedProjectileType and cannon.LoadedProjectileType ~= "" then
			local specs = ProjectileSpecs[cannon.LoadedProjectileType]
			if specs and specs.DisplayName then
				loadedDisplayName = specs.DisplayName
			else
				loadedDisplayName = cannon.LoadedProjectileType
			end
		end
		
		infoLabel:SetText("Cannon Status:\n" .. 
			"Loaded: " .. loadedDisplayName .. "\n" ..
			"Powder: " .. cannon:GetPowder() .. " (charge " .. (cannon.Propellant or 0) .. "/" .. (cannon.MaxPropellant or 100) .. ")")
		infoLabel:SetWrap(true)
		infoLabel:SetTextColor(Color(255, 255, 255, 200))
		
		-- Muzzle velocity info panel (right side)
		local velocityPanel = vgui.Create("DPanel", frame)
		velocityPanel:SetPos(210, 30)
		velocityPanel:SetSize(180, 100)
		
		function velocityPanel:Paint(w, h)
			surface.SetDrawColor(0, 0, 0, 100)
			surface.DrawRect(0, 0, w, h)
		end
		
		local velocityLabel = vgui.Create("DLabel", velocityPanel)
		velocityLabel:SetPos(10, 10)
		velocityLabel:SetSize(160, 80)
		
		-- Calculate muzzle velocity on client side
		local currentMuzzleVelocity = 0
		if cannon.LoadedProjectileType and cannon.LoadedProjectileType ~= "" and cannon.ProjectileMass and cannon.ProjectileMass > 0 then
			local force = cannon:CalculateForceCurve(cannon:GetPowder())
			currentMuzzleVelocity = force / cannon.ProjectileMass
		end
		
		local velocityText = "Muzzle Velocity:\n"
		local velocityColor = Color(255, 255, 255, 200)
		if cannon.LoadedProjectileType and cannon.LoadedProjectileType ~= "" then
			if currentMuzzleVelocity > 0 then
				-- Convert to more readable units (m/s)
				local velocityMetersPerSec = math.Round(currentMuzzleVelocity * 0.01905)
				velocityText = velocityText .. velocityMetersPerSec .. " m/s\n"
				velocityText = velocityText .. "(" .. math.Round(currentMuzzleVelocity) .. " u/s)\n"
				
				-- Get display name for loaded projectile
				local specs = ProjectileSpecs[cannon.LoadedProjectileType]
				local projectileName = (specs and specs.DisplayName) or cannon.LoadedProjectileType
				velocityText = velocityText .. "Mass: " .. cannon.ProjectileMass .. " kg"
				
				-- Color code based on velocity (higher velocity = greener)
				local velocityQuality = math.Clamp(currentMuzzleVelocity / 5000, 0, 1) -- Normalize to 0-1 (5000 u/s = max quality)
				velocityColor = JMod.GoodBadColor(velocityQuality, 200)
			else
				velocityText = velocityText .. "No mass data\n"
				velocityText = velocityText .. "Cannot calculate"
				velocityColor = Color(255, 165, 0, 200) -- Orange for no data
			end
		else
			velocityText = velocityText .. "No projectile\nloaded"
			velocityColor = Color(150, 150, 150, 200) -- Gray when no projectile
		end
		
		velocityLabel:SetText(velocityText)
		velocityLabel:SetWrap(true)
		velocityLabel:SetTextColor(velocityColor)
		
		-- Propellant control panel
		local controlPanel = vgui.Create("DPanel", frame)
		controlPanel:SetPos(10, 140)
		controlPanel:SetSize(380, 150)
		
		function controlPanel:Paint(w, h)
			surface.SetDrawColor(0, 0, 0, 100)
			surface.DrawRect(0, 0, w, h)
		end
		
		local propellantLabel = vgui.Create("DLabel", controlPanel)
		propellantLabel:SetPos(10, 10)
		propellantLabel:SetSize(360, 20)
		propellantLabel:SetText("Propellant per shot: " .. (cannon.CurrentPropellantPerShot or 20))
		propellantLabel:SetTextColor(Color(255, 255, 255, 200))
		
		local slider = vgui.Create("DNumSlider", controlPanel)
		slider:SetPos(10, 35)
		slider:SetSize(360, 30)
		slider:SetText("Propellant Amount")
		slider:SetMin(1)
		slider:SetMax(cannon.MaxPropellant or 100)
		slider:SetValue(cannon.CurrentPropellantPerShot or 20)
		slider:SetDecimals(0)
		
		-- Desired projectile selector
		local projectileLabel = vgui.Create("DLabel", controlPanel)
		projectileLabel:SetPos(10, 70)
		projectileLabel:SetSize(360, 20)
		projectileLabel:SetText("Desired Projectile Type:")
		projectileLabel:SetTextColor(Color(255, 255, 255, 200))
		
		local projectileCombo = vgui.Create("DComboBox", controlPanel)
		projectileCombo:SetPos(10, 90)
		projectileCombo:SetSize(360, 25)

		-- Add all valid projectile types
		local projectileKeys = {}
		for class, _ in pairs(ProjectileSpecs) do
			table.insert(projectileKeys, class)
		end
		table.sort(projectileKeys)
		
		for _, class in ipairs(projectileKeys) do
			local specs = ProjectileSpecs[class]
			local displayName = (specs and specs.DisplayName) or class
			projectileCombo:AddChoice(displayName, class)
		end

		-- Add "None" option
		projectileCombo:AddChoice("None", "")

		-- Get current display name for desired projectile
		local currentDisplayName = "None"
		if cannon.DesiredProjectileClass and cannon.DesiredProjectileClass ~= "" then
			local specs = ProjectileSpecs[cannon.DesiredProjectileClass]
			if specs and specs.DisplayName then
				currentDisplayName = specs.DisplayName
			else
				currentDisplayName = cannon.DesiredProjectileClass
			end
		end
		projectileCombo:SetValue(currentDisplayName)
		
		-- Customize the dropdown menu to add scrollbar
		projectileCombo.OnMenuOpened = function(self, menu)
			-- Set maximum height for the menu (will show scrollbar if content exceeds this)
			menu:SetMaxHeight(200)
		end
		
		projectileCombo.OnSelect = function(self, index, value, data)
			if IsValid(cannon) then
				surface.PlaySound("snds_jack_gmod/ez_gui/click_smol.ogg")
				net.Start("JMod_EZCannon_Command")
					net.WriteEntity(cannon)
					net.WriteString("setdesiredprojectile")
					net.WriteString(data or "")
				net.SendToServer()
			end
		end
		
		-- Autoloading toggle checkbox
		local autoloadingCheckbox = vgui.Create("DCheckBoxLabel", controlPanel)
		autoloadingCheckbox:SetPos(10, 120)
		autoloadingCheckbox:SetSize(360, 25)
		autoloadingCheckbox:SetText("Enable Autoloading")
		autoloadingCheckbox:SetTextColor(Color(255, 255, 255, 200))
		autoloadingCheckbox:SetChecked(cannon:GetIsAutoLoading() or false)
		autoloadingCheckbox.OnChange = function(self, val)
			if IsValid(cannon) then
				surface.PlaySound("snds_jack_gmod/ez_gui/click_smol.ogg")
				net.Start("JMod_EZCannon_Command")
					net.WriteEntity(cannon)
					net.WriteString("setautoloading")
					net.WriteBool(val)
				net.SendToServer()
			end
		end
		
		-- Button panel
		local buttonPanel = vgui.Create("DPanel", frame)
		buttonPanel:SetPos(10, 300)
		buttonPanel:SetSize(380, 80)
		
		function buttonPanel:Paint(w, h)
			surface.SetDrawColor(0, 0, 0, 100)
			surface.DrawRect(0, 0, w, h)
		end
		
		local fireButton = vgui.Create("DButton", buttonPanel)
		fireButton:SetPos(10, 10)
		fireButton:SetSize(175, 30)
		fireButton:SetText("FIRE CANNON")
		fireButton:SetTextColor(Color(255, 255, 255))
		
		function fireButton:Paint(w, h)
			local hovered = self:IsHovered()
			local color = hovered and Color(200, 50, 50, 200) or Color(200, 50, 50, 150)
			surface.SetDrawColor(color)
			surface.DrawRect(0, 0, w, h)
			
			if hovered then
				surface.SetDrawColor(255, 255, 255, 50)
				surface.DrawRect(0, 0, w, h)
			end
		end
		
		fireButton.DoClick = function()
			if IsValid(cannon) and cannon.LoadedProjectileType and cannon.LoadedProjectileType ~= "" then
				if cannon:GetPowder() < cannon.CurrentPropellantPerShot then
					surface.PlaySound("snds_jack_gmod/ez_gui/miss.ogg")
					notification.AddLegacy("Not enough propellant!", NOTIFY_ERROR, 2)
					return
				end

				surface.PlaySound("snds_jack_gmod/ez_gui/click_big.ogg")
				net.Start("JMod_EZCannon_Command")
				net.WriteEntity(cannon)
				net.WriteString("fire")
				net.SendToServer()
				frame:Close()
			else
				surface.PlaySound("snds_jack_gmod/ez_gui/miss.ogg")
				notification.AddLegacy("No projectile loaded!", NOTIFY_ERROR, 2)
			end
		end
		
		local unloadButton = vgui.Create("DButton", buttonPanel)
		unloadButton:SetPos(195, 10)
		unloadButton:SetSize(175, 30)
		unloadButton:SetText("UNLOAD")
		unloadButton:SetTextColor(Color(255, 255, 255))
		
		function unloadButton:Paint(w, h)
			local hovered = self:IsHovered()
			local color = hovered and Color(100, 100, 100, 200) or Color(100, 100, 100, 150)
			surface.SetDrawColor(color)
			surface.DrawRect(0, 0, w, h)
			
			if hovered then
				surface.SetDrawColor(255, 255, 255, 50)
				surface.DrawRect(0, 0, w, h)
			end
		end
		
		unloadButton.DoClick = function()
			if IsValid(cannon) then
				surface.PlaySound("snds_jack_gmod/ez_gui/click_smol.ogg")
				net.Start("JMod_EZCannon_Command")
				net.WriteEntity(cannon)
				net.WriteString("unload")
				net.SendToServer()
				frame:Close()
			end
		end
		
		local closeButton = vgui.Create("DButton", buttonPanel)
		closeButton:SetPos(10, 45)
		closeButton:SetSize(360, 25)
		closeButton:SetText("CLOSE")
		closeButton:SetTextColor(Color(255, 255, 255))
		
		function closeButton:Paint(w, h)
			local hovered = self:IsHovered()
			local color = hovered and Color(80, 80, 80, 200) or Color(80, 80, 80, 150)
			surface.SetDrawColor(color)
			surface.DrawRect(0, 0, w, h)
			
			if hovered then
				surface.SetDrawColor(255, 255, 255, 50)
				surface.DrawRect(0, 0, w, h)
			end
		end
		
		closeButton.DoClick = function()
			frame:Close()
		end
		
		-- Update propellant when slider changes
		slider.OnValueChanged = function(self, value)
			if IsValid(cannon) then
				cannon.CurrentPropellantPerShot = math.floor(value)
				net.Start("JMod_EZCannon_Command")
				net.WriteEntity(cannon)
				net.WriteString("setpropellant")
				net.WriteUInt(math.floor(value), 8)
				net.SendToServer()
				
				-- Update muzzle velocity display in real-time
				local newMuzzleVelocity = 0
				if cannon.LoadedProjectileType and cannon.LoadedProjectileType ~= "" and cannon.ProjectileMass and cannon.ProjectileMass > 0 then
					local newForce = cannon:CalculateForceCurve(cannon:GetPowder())
					newMuzzleVelocity = newForce / cannon.ProjectileMass
				end
				
				local newVelocityText = "Muzzle Velocity:\n"
				local newVelocityColor = Color(255, 255, 255, 200)
				
				if cannon.LoadedProjectileType and cannon.LoadedProjectileType ~= "" then
					if newMuzzleVelocity > 0 then
						-- Convert to more readable units (m/s)
						local velocityMetersPerSec = math.Round(newMuzzleVelocity * 0.01905)
						newVelocityText = newVelocityText .. velocityMetersPerSec .. " m/s\n"
						newVelocityText = newVelocityText .. "(" .. math.Round(newMuzzleVelocity) .. " u/s)\n"
						newVelocityText = newVelocityText .. "Mass: " .. cannon.ProjectileMass .. " kg"
						
						-- Color code based on velocity (higher velocity = greener)
						local velocityQuality = math.Clamp(newMuzzleVelocity / 5000, 0, 1)
						newVelocityColor = JMod.GoodBadColor(velocityQuality, 200)
					else
						newVelocityText = newVelocityText .. "No mass data\n"
						newVelocityText = newVelocityText .. "Cannot calculate"
						newVelocityColor = Color(255, 165, 0, 200)
					end
				else
					newVelocityText = newVelocityText .. "No projectile\nloaded"
					newVelocityColor = Color(150, 150, 150, 200)
				end
				
				velocityLabel:SetText(newVelocityText)
				velocityLabel:SetTextColor(newVelocityColor)
			end
		end
		
		-- Play menu open sound
		surface.PlaySound("snds_jack_gmod/ez_gui/menu_open.ogg")
	end
end