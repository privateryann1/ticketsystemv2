local cols = {}
cols.header     =   Color(54, 58, 64)
cols.body       =   Color(72, 77, 84)
cols.close      =   Color(35, 37, 41)
cols.button     =   Color(55, 57, 61, 150)
cols.white      =   Color(255,255,255)
cols.shadow     =   Color(0, 0, 0, 150)
cols.accepted  =   Color(50, 168, 84, 255)

local data = {}

local function sync()
    net.Start("PR_TICKETSYSTEM:sync")
        net.WriteTable(data)
    net.SendToServer()
end

net.Receive("PR_TICKETSYSTEM:sync", function(len, ply) data = net.ReadTable() end)

surface.CreateFont("Roboto.20", {font = "Roboto", size = 20})
surface.CreateFont("Roboto.15", {font = "Roboto", size = 15})
surface.CreateFont("Roboto.22", {font = "Roboto", size = 22})

local function CanSee(ply)
    if ( PR_TICKETSYSTEM.Cfg.AdminMod == "ULX" && ply:query("ulx seeasay") ) then return true end
    if ( PR_TICKETSYSTEM.Cfg.AdminMode == "SAM" && ply:HasPermission("pr_ticketsystem") ) then return true end
end

local function sendMsg(text)
    LocalPlayer():ChatPrint(text)
end

local function svMsg(ply, txt)
    net.Start("PR_TICKETSYSTEM:notify")
        net.WriteEntity(ply)
        net.WriteString(txt)
    net.SendToServer()
end

local function HandleNetWork(len, ply)
    local num = net.ReadInt(8)

    if ( num == 1 ) then     // Send Chat Message
        LocalPlayer():ChatPrint(net.ReadString())
    end

    if ( num == 2 && CanSee(LocalPlayer()) ) then     // Create Ticket Window

        ply = net.ReadEntity()
        local content = net.ReadString()
        local id = net.ReadInt(8)

        local width, height = ScrW(), ScrH()
        local frame_width, frame_height = width * 0.15, height * 0.13
        local frame = vgui.Create("DFrame")
        frame:SetSize( frame_width, frame_height )
        frame:SetPos( -frame_width, 10 )
        frame:MoveTo( 10, 10, .5, 0 )
        frame:SetTitle("")
        frame:SetDraggable(false)
        frame.accepted = false
        frame:ShowCloseButton(false)
        frame.Paint = function(self, w, h)
            if ( data[ply] == nil ) then frame:Remove() return end

            if ( frame.accepted ) then
                DisableClipping(true)
                draw.RoundedBox(10, -2, -2, w + 4, h + 4, cols.accepted)
            end

            draw.RoundedBox(10, 0, 0, w, h, cols.body)  // Body paint

            draw.RoundedBoxEx(10, 0, 0, w, frame_height * 0.15, cols.header, true, true, false, false)  // Header paint
            draw.RoundedBox(0, 0,  frame_height * 0.15 , w, 2, cols.shadow)

            draw.SimpleText(ply:Nick(), "Roboto.20", 10, (frame_height * 0.15) / 2, cols.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)    // Username text

        end

        hook.Add("Think", "ShowPanelStuff", function()
            if ( !IsValid(frame) ) then hook.Remove("Think", "ShowPanelStuff") return end
            if ( data[ply] == nil ) then frame:Remove() hook.Remove("Think", "ShowPanelStuff") return end
            if ( data[ply].claimer != nil && data[ply].claimer != LocalPlayer() ) then
                frame:Hide()
            else
                frame:Show()
            end
        end)

        local text_body = vgui.Create("DPanel", frame)
        text_body:SetSize(frame_width - 20, frame_height - (frame_height * 0.15) - (frame_height * 0.3) - 10)
        text_body:SetPos(10, (frame_height * 0.15) + 10)
        text_body.Paint = function(self, w, h) end

        local text_font = "Roboto.22"

        local text = vgui.Create("DLabel", text_body)
        text:SetTextColor(cols.white)
        text:SetFont(text_font)
        text:SetText(PR_TICKETSYSTEM.textWrap(content, text_font, text_body:GetWide()))
        text:SizeToContents()

        local close = vgui.Create("DButton", frame)
        close:SetSize(21, 21)
        close:SetText("")
        close:SetPos( frame_width - 30, 6 )
        close.Paint = function(self, w, h)
            draw.RoundedBox(20, 0, 0, w, h, cols.close)
        end
        close.DoClick = function(self)
            if frame.accepted then
                sendMsg("Please close or cancel the ticket.")
            return end
            frame:MoveTo( -(frame:GetWide() + frame:GetX()), frame:GetY(), .5, 0, -1, function() frame:Remove() end )
        end

        local container = vgui.Create("DPanel", frame)
        container:SetPos(0, frame_height - 60)
        container:SetSize(frame_width, frame_height * 0.3)
        container:DockMargin(0, 0, 0, 0)
        container:DockPadding(frame_width * 0.12,0,0,0)
        container.Paint = function(self, w, h) end

        local but_w, but_h = frame_width * 0.2, frame_height * 0.05
        local round = 3

        local accept_but = vgui.Create( "DButton", container )
        accept_but:SetText( "" )
        accept_but:SetSize( but_w, but_h )
        accept_but:Dock(LEFT)
        accept_but:DockMargin(0, 0, 30, 20)
        accept_but.text = "Accept"
        accept_but.Paint = function(self, w, h)
            draw.RoundedBox(round, 0, 0, w, h, cols.button)
            draw.SimpleText(accept_but.text, "Roboto.15", accept_but:GetWide() / 2, accept_but:GetTall() / 2, cols.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local ignore_but = vgui.Create( "DButton", container )
        ignore_but:SetText( "" )
        ignore_but:SetSize( but_w, but_h )
        ignore_but:Dock(LEFT)
        ignore_but:DockMargin(0, 0, 30, 20)
        ignore_but.text = "Ignore"
        ignore_but.Paint = function(self, w, h)
            draw.RoundedBox(round, 0, 0, w, h, cols.button)
            draw.SimpleText(ignore_but.text, "Roboto.15", ignore_but:GetWide() / 2, ignore_but:GetTall() / 2, cols.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        ignore_but.DoClick = function()
            if ( ignore_but.text == "Cancel" ) then
                data[ply].claimer = nil
                accept_but.text = "Accept"
                frame.accepted = false
                ignore_but.text = "Ignore"
                sendMsg("You are no longer taking " .. ply:Nick() .. "'s ticket.")
                svMsg(ply, LocalPlayer():Nick() .. " is no longer taking your ticket.")
                sync()
            return end
            frame:MoveTo( -(frame:GetWide() + frame:GetX()), frame:GetY(), .5, 0, -1, function() frame:Remove() end )
        end

        accept_but.DoClick = function()
            if accept_but.text == "Close" then
                frame:MoveTo( -(frame:GetWide() + frame:GetX()), frame:GetY(), .5, 0, -1, function() frame:Remove() data[id] = nil sync() end )
                sendMsg("You have closed " .. ply:Nick() .. "'s ticket.")
                svMsg(ply, LocalPlayer():Nick() .. " has closed your ticket.")
            return end
            data[ply].claimer = LocalPlayer()
            frame.accepted = true
            accept_but.text = "Close"
            ignore_but.text = "Cancel"
            sendMsg("You have accepted " .. ply:Nick() .. "'s ticket.")
            svMsg(ply, LocalPlayer():Nick() .. " has accepted your ticket.")
            sync()
        end

        local actions_but = vgui.Create( "DButton", container )
        actions_but:SetText( "" )
        actions_but:SetSize( but_w, but_h )
        actions_but:Dock(LEFT)
        actions_but:DockMargin(0, 0, 30, 20)
        actions_but.Paint = function(self, w, h)
            draw.RoundedBox(round, 0, 0, w, h, cols.button)
            draw.SimpleText("Actions", "Roboto.15", actions_but:GetWide() / 2, actions_but:GetTall() / 2, cols.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        actions_but.DoClick = function()
            local actions_menu = DermaMenu(actions_but)
            actions_menu:SetPos(input.GetCursorPos())
            local steamidbut = actions_menu:AddOption("Copy SteamID", function()
                SetClipboardText(tostring(ply:SteamID()))
                sendMsg("You copied " .. ply:Nick() .. "'s SteamID.")
            end)
            steamidbut:SetIcon("icon16/page_copy.png")
            actions_menu:AddSpacer()
            local bringbut = actions_menu:AddOption("Bring", function()
                if PR_TICKETSYSTEM.Cfg.AdminMod == "ULX" then
                    LocalPlayer():ConCommand("ulx bring " .. ply:Nick())
                else
                    LocalPlayer():ConCommand("sam bring " .. ply:Nick())
                end
            end)
            bringbut:SetIcon("icon16/arrow_left.png")
            local gotobut = actions_menu:AddOption("Goto", function()
                if PR_TICKETSYSTEM.Cfg.AdminMod == "ULX" then
                    LocalPlayer():ConCommand("ulx goto " .. ply:Nick())
                else
                    LocalPlayer():ConCommand("sam bring " .. ply:Nick())
                end
            end)
            gotobut:SetIcon("icon16/arrow_right.png")
            local returnbut = actions_menu:AddOption("Return", function()
                if PR_TICKETSYSTEM.Cfg.AdminMod == "ULX" then
                    LocalPlayer():ConCommand("ulx return " .. ply:Nick())
                else
                    LocalPlayer():ConCommand("sam bring " .. ply:Nick())
                end
            end)
            returnbut:SetIcon("icon16/arrow_refresh.png")
        end
    end
end
net.Receive("PR_TICKETSYSTEM", HandleNetWork)