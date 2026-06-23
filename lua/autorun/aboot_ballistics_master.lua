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
			UsePropModel = true,
			DisplayName = "Prop Physics"
		},
		["ent_aboot_ezshot_shell"] = {
			PowderAdd = 25,
			DisplayName = "Shell Shot",
			Angles = Angle(-90, 0, 0),
			ArmMethod = "Launch"
		},
		["ent_jack_gmod_ezherocket"] = {
			ArmDelay = .2,
			PowderAdd = 100,
			Angles = Angle(0, 0, 90),
			LaunchOffset = Vector(-30, 1.5, 0),
			DisplayName = "HE Rocket"
		},
		["ent_jack_gmod_ezheatrocket"] = {
			ArmDelay = .2,
			PowderAdd = 100,
			Angles = Angle(0, 0, 90),
			LaunchOffset = Vector(-30, 1.5, 0),
			DisplayName = "HEAT Rocket"
		},
		["ent_jack_gmod_ezstickynade"] = {
			Angles = Angle(180, 0, 0),
			DisplayName = "Sticky Grenade"
		},
		["ent_jack_gmod_ezfragnade"] = {
			ArmDelay = 0,
			DisplayName = "Frag Grenade"
		},
		["ent_jack_gmod_ezimpactnade"] = {
			Angles = Angle(180, 0, 0),
			LaunchOffset = Vector(1, 0, 0),
			DisplayName = "Impact Grenade"
		},
		["ent_jack_gmod_ezfirenade"] = {
			ArmDelay = .05,
			DisplayName = "Incendiary Grenade"
		},
		["ent_jack_gmod_ezflashbang"] = {
			ArmDelay = .05,
			DisplayName = "Flashbang"
		},
		["ent_jack_gmod_ezsmokegrenade"] = {
			ArmDelay = .05,
			DisplayName = "Smoke Grenade"
		},
		["ent_jack_gmod_ezroadflare"] = {
			ArmDelay = .5,
			DisplayName = "Road Flare"
		},
		["ent_jack_gmod_ezflareprojectile"] = {
			ForceMult = .1,
			DisplayName = "Flare Projectile"
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

JModBallistics.NETWORK_INDEX = {
	CANNON_COMMAND = {OPEN = 1, FIRE = 2, UNLOAD = 3, SETPROPLELLETPERSHOT = 4, SETDESIREDPROJECTILECLASS = 5, SETAUTOLOADING = 6, STATESYNC = 7},
}

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
		local command = net.ReadUInt(4)
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
		if command == JModBallistics.NETWORK_INDEX.CANNON_COMMAND.OPEN then
			net.Start("JMod_EZCannon_Command")
				net.WriteEntity(cannon)
				net.WriteUInt(JModBallistics.NETWORK_INDEX.CANNON_COMMAND.OPEN, 4)
				net.WriteEntity(IsValid(cannon.LoadedProjectileEnt) and cannon.LoadedProjectileEnt or NULL)
				net.WriteUInt(cannon.Propellant or 0, 8)
				net.WriteUInt(cannon.CurrentPropellantPerShot or 20, 8)
				net.WriteString(cannon:GetDesiredProjectileClass() or "")
			net.Send(ply)
		elseif command == JModBallistics.NETWORK_INDEX.CANNON_COMMAND.FIRE then
			if IsValid(cannon.LoadedProjectileEnt) then
				cannon:LaunchProjectile(false, ply)
			end
		elseif command == JModBallistics.NETWORK_INDEX.CANNON_COMMAND.UNLOAD then
			cannon:UnloadProjectile()
		elseif command == JModBallistics.NETWORK_INDEX.CANNON_COMMAND.SETPROPLELLETPERSHOT then
			local propellant = net.ReadUInt(8)
			-- Validate propellant value
			cannon.CurrentPropellantPerShot = math.Clamp(propellant, 1, cannon.MaxPropellant or 100)
			cannon:UpdateWireOutputs()
		elseif command == JModBallistics.NETWORK_INDEX.CANNON_COMMAND.SETDESIREDPROJECTILECLASS then
			local projectileClass = net.ReadString()
			cannon:SetDesiredProjectileClass(projectileClass)
			cannon:SyncStateToClients()
		elseif command == JModBallistics.NETWORK_INDEX.CANNON_COMMAND.SETAUTOLOADING then
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
		if not IsValid(cannon) then return end
		local command = net.ReadUInt(4)
		
		if command == JModBallistics.NETWORK_INDEX.CANNON_COMMAND.OPEN then
			cannon.LoadedProjectileEnt = net.ReadEntity()
			cannon.LoadedProjectileType = IsValid(cannon.LoadedProjectileEnt) and cannon.LoadedProjectileEnt:GetClass() or ""
			cannon.Propellant = net.ReadUInt(8)
			cannon.CurrentPropellantPerShot = net.ReadUInt(8)
			cannon.ProjectileMass = net.ReadUInt(16)
			cannon.DesiredProjectileClass = net.ReadString()
			JMod_EZCannon_OpenGUI(cannon)
		elseif command == JModBallistics.NETWORK_INDEX.CANNON_COMMAND.STATESYNC then
			cannon.LoadedProjectileType = net.ReadString()
			cannon.Propellant = net.ReadUInt(8)
			cannon.CurrentPropellantPerShot = net.ReadUInt(8)
			cannon.ProjectileMass = net.ReadUInt(16)
			cannon.DesiredProjectileClass = net.ReadString()
		end
	end)

	surface.CreateFont("JMod_EZCannon_Body", {font = "Tahoma", size = 16, weight = 500, antialias = true})
	surface.CreateFont("JMod_EZCannon_Header", {font = "Tahoma", size = 18, weight = 800, antialias = true})

	-- GUI function
	function JMod_EZCannon_OpenGUI(cannon)
		if not IsValid(cannon) then return end
		local CannonClass = cannon:GetClass()
		local ProjectileSpecs = JModBallistics.ProjectileSpecs[CannonClass].types
		
		local frame = IsValid(JMod_EZCannon_GUI) and JMod_EZCannon_GUI or vgui.Create("DFrame")
		frame:SetSize(280, 450)
		frame:Center()
		frame:SetTitle("EZ Cannon Control")
		frame:MakePopup()
		frame:SetDraggable(true)
		frame:ShowCloseButton(true)
		frame:DockPadding(8, 28, 8, 8)
		
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
		
		local headerColor = Color(255, 220, 120, 255)
		local bodyColor = Color(255, 255, 255, 220)

		-- Helper: format muzzle velocity preview from a propellant-to-load value
		local function FormatVelText(propLoad)
			if not (cannon.LoadedProjectileType and cannon.LoadedProjectileType ~= "") then
				return "No projectile loaded", Color(150, 150, 150, 220)
			end
			local mass = cannon.ProjectileMass or 0
			if mass <= 0 then
				return "No mass data", Color(255, 165, 0, 220)
			end
			local specs = ProjectileSpecs[cannon.LoadedProjectileType]
			local powderAdd = (specs and specs.PowderAdd) or 0
			local power = (propLoad or cannon.CurrentPropellantPerShot or 0) + powderAdd
			local vel = cannon:CalculateForceCurve(power) / mass
			local ms = math.Round(vel * 0.01905)
			local us = math.Round(vel)
			local quality = math.Clamp(vel / 5000, 0, 1)
			return ms .. " m/s (" .. us .. " u/s)", JMod.GoodBadColor(quality, 220)
		end

		-- Helper: docked, horizontally-centered single-line label that auto-sizes its height
		local function MakeLabel(parent, font, color)
			local l = vgui.Create("DLabel", parent)
			l:Dock(TOP)
			l:DockMargin(0, 0, 0, 2)
			l:SetFont(font)
			l:SetTextColor(color)
			l:SetContentAlignment(5)
			l:SetAutoStretchVertical(true)
			return l
		end

		-- Helper: docked section panel that auto-sizes its height to its children
		local function MakeSection(dock)
			local p = vgui.Create("DPanel", frame)
			p:Dock(dock)
			p:DockMargin(0, 0, 0, 8)
			p:DockPadding(8, 6, 8, 6)
			p.Paint = function(_, w, h)
				surface.SetDrawColor(0, 0, 0, 100)
				surface.DrawRect(0, 0, w, h)
			end
			if dock ~= FILL then
				p.PerformLayout = function(s) s:SizeToChildren(false, true) end
			end
			return p
		end

		-- ===== Top: Calculation Data =====
		local calcPanel = MakeSection(TOP)

		local calcHeader = MakeLabel(calcPanel, "JMod_EZCannon_Header", headerColor)
		calcHeader:SetText("Calculation Data")

		local massLabel = MakeLabel(calcPanel, "JMod_EZCannon_Body", bodyColor)
		massLabel:SetText("Mass: " .. math.max(0, cannon.ProjectileMass or 0) .. " kg")

		local muzzleLabel = MakeLabel(calcPanel, "JMod_EZCannon_Body", bodyColor)
		do
			local velText, velCol = FormatVelText(cannon.CurrentPropellantPerShot)
			muzzleLabel:SetText("Muzzle Vel: " .. velText)
			muzzleLabel:SetTextColor(velCol)
		end

		-- ===== Middle: Cannon Configuration =====
		local cfgPanel = MakeSection(TOP)

		local cfgHeader = MakeLabel(cfgPanel, "JMod_EZCannon_Header", headerColor)
		cfgHeader:SetText("Cannon Configuration")

		local loadedHeader = MakeLabel(cfgPanel, "JMod_EZCannon_Body", bodyColor)
		loadedHeader:SetText("Loaded Projectile:")

		if cannon.LoadedProjectileType and cannon.LoadedProjectileType ~= "" then
			local specs = ProjectileSpecs[cannon.LoadedProjectileType]
			local primaryName
			if cannon.LoadedProjectileType == "prop_physics" and IsValid(cannon.LoadedProjectileEnt) then
				primaryName = cannon.LoadedProjectileEnt:GetModel()
			else
				primaryName = (specs and specs.DisplayName) or cannon.LoadedProjectileType
			end
			MakeLabel(cfgPanel, "JMod_EZCannon_Body", bodyColor):SetText(primaryName)
			MakeLabel(cfgPanel, "JMod_EZCannon_Body", bodyColor):SetText("(" .. cannon.LoadedProjectileType .. ")")
		else
			MakeLabel(cfgPanel, "JMod_EZCannon_Body", bodyColor):SetText("None")
		end

		local loadedSpecs = ProjectileSpecs[cannon.LoadedProjectileType or ""]
		local loadedPowderAdd = (loadedSpecs and loadedSpecs.PowderAdd) or 0
		local powderLabel = MakeLabel(cfgPanel, "JMod_EZCannon_Body", bodyColor)
		powderLabel:SetText("Total Powder: (" .. (cannon.Propellant or 0) .. " + " .. loadedPowderAdd .. ") / " .. (cannon.MaxPropellant or 100))
		
		-- ===== Buttons (pinned to bottom) =====
		local buttonRow = vgui.Create("DPanel", frame)
		buttonRow:Dock(BOTTOM)
		buttonRow:SetPaintBackground(false)
		buttonRow.PerformLayout = function(s) s:SizeToChildren(false, true) end

		-- ===== Bottom: Controls (fills remaining space) =====
		local controlsPanel = MakeSection(FILL)

		local propellantLabel = MakeLabel(controlsPanel, "JMod_EZCannon_Body", bodyColor)
		propellantLabel:SetText("Propellant To Load:")

		local slider = vgui.Create("DNumSlider", controlsPanel)
		slider:Dock(TOP)
		slider:SetTall(30)
		slider:DockMargin(-100, 0, 0, 6)
		slider:SetText("")
		slider:SetMin(1)
		slider:SetMax(cannon.MaxPropellant or 100)
		slider:SetValue(cannon.CurrentPropellantPerShot or 20)
		slider:SetDecimals(0)
		if IsValid(slider.Label) then slider.Label:SetFont("JMod_EZCannon_Body") end

		local projectileLabel = MakeLabel(controlsPanel, "JMod_EZCannon_Body", bodyColor)
		projectileLabel:SetText("Desired Projectile:")

		local projectileCombo = vgui.Create("DComboBox", controlsPanel)
		projectileCombo:Dock(TOP)
		projectileCombo:SetTall(26)
		projectileCombo:DockMargin(0, 0, 0, 6)
		projectileCombo:SetFont("JMod_EZCannon_Body")

		local projectileKeys = {}
		for class, _ in pairs(ProjectileSpecs) do
			table.insert(projectileKeys, class)
		end
		table.sort(projectileKeys)

		local noneChoice = true
		for _, class in ipairs(projectileKeys) do
			local specs = ProjectileSpecs[class]
			local displayName = (specs and specs.DisplayName) or class
			if cannon.DesiredProjectileClass and cannon.DesiredProjectileClass == class then
				projectileCombo:AddChoice(displayName, class, true)
				noneChoice = false
			else
				projectileCombo:AddChoice(displayName, class)
			end
		end
		projectileCombo:AddChoice(" None", "", noneChoice)

		projectileCombo.OnMenuOpened = function(self, menu)
			menu:SetMaxHeight(200)
		end

		projectileCombo.OnSelect = function(self, index, value, data)
			if IsValid(cannon) then
				surface.PlaySound("snds_jack_gmod/ez_gui/click_smol.ogg")
				net.Start("JMod_EZCannon_Command")
					net.WriteEntity(cannon)
					net.WriteUInt(JModBallistics.NETWORK_INDEX.CANNON_COMMAND.SETDESIREDPROJECTILECLASS, 4)
					net.WriteString(data or "")
				net.SendToServer()
			end
		end

		local autoloadingCheckbox = vgui.Create("DCheckBoxLabel", controlsPanel)
		autoloadingCheckbox:Dock(TOP)
		autoloadingCheckbox:SetTall(20)
		autoloadingCheckbox:SetFont("JMod_EZCannon_Body")
		autoloadingCheckbox:SetText("Enable Autoloading")
		autoloadingCheckbox:SetTextColor(bodyColor)
		autoloadingCheckbox:SetChecked(cannon:GetIsAutoLoading() or false)
		autoloadingCheckbox.OnChange = function(self, val)
			if IsValid(cannon) then
				surface.PlaySound("snds_jack_gmod/ez_gui/click_smol.ogg")
				net.Start("JMod_EZCannon_Command")
					net.WriteEntity(cannon)
					net.WriteUInt(JModBallistics.NETWORK_INDEX.CANNON_COMMAND.SETAUTOLOADING, 4)
					net.WriteBool(val)
				net.SendToServer()
			end
		end
		
		local fireButton = vgui.Create("DButton", buttonRow)
		fireButton:Dock(TOP)
		fireButton:SetTall(30)
		fireButton:DockMargin(0, 0, 0, 4)
		fireButton:SetFont("JMod_EZCannon_Body")
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
				if cannon:GetPowder() <= 0 then
					surface.PlaySound("snds_jack_gmod/ez_gui/miss.ogg")
					notification.AddLegacy("Not enough propellant!", NOTIFY_ERROR, 2)
					return
				end

				surface.PlaySound("snds_jack_gmod/ez_gui/click_big.ogg")
				net.Start("JMod_EZCannon_Command")
				net.WriteEntity(cannon)
				net.WriteUInt(JModBallistics.NETWORK_INDEX.CANNON_COMMAND.FIRE, 4)
				net.SendToServer()
				frame:Close()
			else
				surface.PlaySound("snds_jack_gmod/ez_gui/miss.ogg")
				notification.AddLegacy("No projectile loaded!", NOTIFY_ERROR, 2)
			end
		end
		
		local unloadButton = vgui.Create("DButton", buttonRow)
		unloadButton:Dock(TOP)
		unloadButton:SetTall(30)
		unloadButton:DockMargin(0, 0, 0, 4)
		unloadButton:SetFont("JMod_EZCannon_Body")
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
				net.WriteUInt(JModBallistics.NETWORK_INDEX.CANNON_COMMAND.UNLOAD, 4)
				net.SendToServer()
				frame:Close()
			end
		end
		
		
		-- Update propellant + muzzle velocity preview when slider changes
		slider.OnValueChanged = function(self, value)
			if IsValid(cannon) then
				local floored = math.floor(value)
				cannon.CurrentPropellantPerShot = floored
				net.Start("JMod_EZCannon_Command")
				net.WriteEntity(cannon)
				net.WriteUInt(JModBallistics.NETWORK_INDEX.CANNON_COMMAND.SETPROPLELLETPERSHOT, 4)
				net.WriteUInt(floored, 8)
				net.SendToServer()

				local velText, velCol = FormatVelText(floored)
				muzzleLabel:SetText("Muzzle Vel: " .. velText)
				muzzleLabel:SetTextColor(velCol)
			end
		end
		JMod_EZCannon_GUI = frame

		-- Play menu open sound
		surface.PlaySound("snds_jack_gmod/ez_gui/menu_open.ogg")
	end
end