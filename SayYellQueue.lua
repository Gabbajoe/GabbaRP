-- Non-eating alternative to the vendored Libs/MessageQueue.lua for sending Say/Yell
-- reactions. Blizzard requires a real click/keypress to legally send a Say/Yell
-- message (see RP_Core.lua's GetChatType) -- MessageQueue.lua satisfies that by
-- capturing the player's literal next hardware input ANYWHERE on screen via a
-- screen-covering frame, which means that input's own action never happens (a
-- keybind press or action bar click gets silently swallowed).
--
-- This module gets the same real-hardware-event requirement satisfied differently:
-- hooksecurefunc on the functions actual game actions go through
-- (UseAction/CastSpellByName/CastSpellByID/UseInventoryItem). hooksecurefunc can
-- never cancel or replace what it hooks -- the player's real action always still
-- happens -- so our hook just ALSO sends any pending Say/Yell message from within
-- that same, still-trusted click. Trade-off versus MessageQueue.lua: nothing is ever
-- swallowed, but a pending message can wait longer than "the very next input" if the
-- player doesn't press an actual action for a while (e.g. only auto-attacking).
--
-- Selected via GabbaRPCharDB.rp.sayYellDelivery: "safe" (default, this module) or
-- "instant" (MessageQueue.lua's old behavior) -- see RP_Options.lua for the setting
-- and RP_Core.lua for where the two are actually chosen between.
local ADDON_NAME, ns = ...

local pending = {}

-- Called from RP_Core.lua instead of MessageQueue.SendChatMessage when
-- sayYellDelivery == "safe".
function ns.GabbaRP_QueueSayYell(msg, chatType)
    table.insert(pending, { msg = msg, chatType = chatType })
end

-- Deliberately NOT deferred via C_Timer.After (unlike TriggerLine's plain-chat-type
-- send path) -- a timer callback is never considered hardware-triggered, so pushing
-- this to the next frame would strip away the exact trust this whole mechanism
-- depends on and just recreate the original problem one step later. Must run
-- synchronously, inside the hook, on the real click's own stack.
local function OnRealAction()
    if GabbaRPCharDB.rp.sayYellDelivery == "instant" then return end
    if #pending == 0 then return end
    local entry = table.remove(pending, 1)
    SendChatMessage(entry.msg, entry.chatType)
end

hooksecurefunc("UseAction", OnRealAction)
hooksecurefunc("CastSpellByName", OnRealAction)
hooksecurefunc("CastSpellByID", OnRealAction)
hooksecurefunc("UseInventoryItem", OnRealAction)
