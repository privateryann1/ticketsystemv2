
util.AddNetworkString("PR_TICKETSYSTEM")
util.AddNetworkString("PR_TICKETSYSTEM:sync")
util.AddNetworkString("PR_TICKETSYSTEM:notify")

PR_TICKETSYSTEM.Active = {}

local function sync()
    net.Start("PR_TICKETSYSTEM:sync")
        net.WriteTable(PR_TICKETSYSTEM.Active)
    net.Broadcast()
end

net.Receive("PR_TICKETSYSTEM:sync", function(len, ply) PR_TICKETSYSTEM.Active = net.ReadTable() sync() end)

function PR_TICKETSYSTEM.Notify(ply, text)
    net.Start("PR_TICKETSYSTEM")
        net.WriteInt(1, 8)
        net.WriteString(text)
    net.Send(ply)
end

if (PR_TICKETSYSTEM.Cfg.AdminMod == "SAM") then
    sam.permissions.add("pr_ticketsystem", "Ticket System")
end

function PR_TICKETSYSTEM.NewTicket(ply, msg)
    net.Start("PR_TICKETSYSTEM")
        net.WriteInt(2, 8)
        net.WriteEntity(ply)
        net.WriteString(msg)
        net.WriteInt(#PR_TICKETSYSTEM.Active + 1, 8)
    net.Broadcast()
    PR_TICKETSYSTEM.Active[ply] = {
        active = true,
        claimer = nil
    }
    sync()
end

net.Receive("PR_TICKETSYSTEM:notify", function(len, ply)
    local ent = net.ReadEntity()
    local txt = net.ReadString()
    ent:ChatPrint(txt)
end)

local function HandleChat(ply, text)
    if ( string.sub(text, 1, 1) != PR_TICKETSYSTEM.Cfg.ChatPrefix ) then return end
    local content = string.sub(text, 2)

    PR_TICKETSYSTEM.NewTicket(ply, content)
    PR_TICKETSYSTEM.Notify(ply, PR_TICKETSYSTEM.Cfg.NewMessage)
    ply:SetNWBool("pr_ticketsystem:active", true)
    return ""

end
hook.Add("PlayerSay", "pr_ticketsystem", HandleChat)