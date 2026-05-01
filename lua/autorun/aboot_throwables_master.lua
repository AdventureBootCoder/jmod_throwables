--AdventureBoots 2025
-- Networking for autoloader entity
JModBallistics = JModBallistics or {}

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
			local specs = (cannon.ProjectileSpecs or ProjectileSpecs)[cannon.LoadedProjectileType]
			if specs and specs.DisplayName then
				loadedDisplayName = specs.DisplayName
			else
				loadedDisplayName = cannon.LoadedProjectileType
			end
		end
		
		infoLabel:SetText("Cannon Status:\n" .. 
			"Loaded: " .. loadedDisplayName .. "\n" ..
			"Propellant: " .. (cannon.Propellant or 0) .. "/" .. (cannon.MaxPropellant or 100))
		infoLabel:SetWrap(true)
		infoLabel:SetTextColor(Color(255, 255, 255, 200))
		
		-- Range info panel (right side)
		local rangePanel = vgui.Create("DPanel", frame)
		rangePanel:SetPos(210, 30)
		rangePanel:SetSize(180, 100)
		
		function rangePanel:Paint(w, h)
			surface.SetDrawColor(0, 0, 0, 100)
			surface.DrawRect(0, 0, w, h)
		end
		
		local rangeLabel = vgui.Create("DLabel", rangePanel)
		rangeLabel:SetPos(10, 10)
		rangeLabel:SetSize(160, 80)
		
		-- Calculate range and angle on client side
		local estimatedRange, estimatedRangeMeters, currentLaunchAngle, EndPos = JModBallistics.CalculateEstimatedRange(
			cannon:LocalToWorld(cannon:OBBCenter()), 
			nil, 
			cannon.ProjectileMass, 
			cannon:CalculateForceCurve(cannon.CurrentPropellantPerShot), 
			cannon:GetLaunchDir(), 
			60, 
			0.1
		)
		
		local rangeText = "Range Info:\n"
		local rangeColor = Color(255, 255, 255, 200)
		if cannon.LoadedProjectileType and cannon.LoadedProjectileType ~= "" then
			-- Always show range if projectile is loaded, even if low
			if estimatedRange and estimatedRange > 0 then
				rangeText = rangeText .. "Estimated: " .. estimatedRangeMeters .. " m\n"
				rangeText = rangeText .. "Launch Angle: " .. tostring(currentLaunchAngle) .. "°\n"
				rangeText = rangeText .. "End Pos: " .. math.Round(math.ceil(EndPos.x * 100) / 10000) .. ", " .. math.Round(math.ceil(EndPos.y * 100) / 10000)
				-- Use JMod.GoodBadColor for dynamic color coding
				local rangeQuality = math.Clamp(estimatedRange / 200, 0, 1) -- Normalize to 0-1 (200m = max quality)
				rangeColor = JMod.GoodBadColor(rangeQuality, 200)
			else
				-- Show that range is being calculated
				rangeText = rangeText .. "Calculating...\n"
				rangeText = rangeText .. "Launch Angle: " .. tostring(currentLaunchAngle) .. "°\n"
				rangeText = rangeText .. "Range Unknown"
				rangeColor = Color(255, 165, 0, 200) -- Orange for calculating
			end
		else
			rangeText = rangeText .. "No projectile\nloaded"
			rangeColor = Color(150, 150, 150, 200) -- Gray when no projectile
		end
		
		rangeLabel:SetText(rangeText)
		rangeLabel:SetWrap(true)
		rangeLabel:SetTextColor(rangeColor)
		
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
		for class, _ in pairs(cannon.ProjectileSpecs or ProjectileSpecs) do
			table.insert(projectileKeys, class)
		end
		table.sort(projectileKeys)
		
		for _, class in ipairs(projectileKeys) do
			local specs = (cannon.ProjectileSpecs or ProjectileSpecs)[class]
			local displayName = (specs and specs.DisplayName) or class
			projectileCombo:AddChoice(displayName, class)
		end

		-- Add "None" option
		projectileCombo:AddChoice("None", "")

		-- Get current display name for desired projectile
		local currentDisplayName = "None"
		if cannon.DesiredProjectileClass and cannon.DesiredProjectileClass ~= "" then
			local specs = (cannon.ProjectileSpecs or ProjectileSpecs)[cannon.DesiredProjectileClass]
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
				if cannon.Propellant < cannon.CurrentPropellantPerShot then
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
				
				-- Update range display in real-time
				local newEstimatedRange, newEstimatedRangeMeters, newCurrentLaunchAngle, newEndPos = JModBallistics.CalculateEstimatedRange(
					cannon:LocalToWorld(cannon:OBBCenter()), 
					nil, 
					cannon.ProjectileMass, 
					cannon:CalculateForceCurve(cannon.CurrentPropellantPerShot), 
					cannon:GetLaunchDir(), 
					60, 
					0.1
				)
				
				if newEstimatedRange and newEstimatedRange > 0 then
					local newRangeText = "Range Info:\n"
					newRangeText = newRangeText .. "Estimated: " .. newEstimatedRangeMeters .. " m\n"
					newRangeText = newRangeText .. "Launch Angle: " .. newCurrentLaunchAngle .. "°\n"
					newRangeText = newRangeText .. "End Pos: " .. math.Round(math.ceil(newEndPos.x * 100) / 10000) .. ", " .. math.Round(math.ceil(newEndPos.y * 100) / 10000)
					
					local newRangeQuality = math.Clamp(newEstimatedRange / 200, 0, 1)
					local newRangeColor = JMod.GoodBadColor(newRangeQuality, 200)
					
					rangeLabel:SetText(newRangeText)
					rangeLabel:SetTextColor(newRangeColor)
				end
			end
		end
		
		-- Play menu open sound
		surface.PlaySound("snds_jack_gmod/ez_gui/menu_open.ogg")
	end
end