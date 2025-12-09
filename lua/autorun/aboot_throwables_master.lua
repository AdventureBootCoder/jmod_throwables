--AdventureBoots 2025
-- Networking for autoloader entity

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
end