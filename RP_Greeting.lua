-- Time-of-day greetings: says hi to the group when you join one, and personally
-- welcomes anyone who joins your existing group by name. Follows /gabba rp on/off + mode
-- like the rest of the RP module.

-- "join": said once, to the whole group, when you yourself join. No name needed.
-- "welcome": said to a specific new member, %t becomes their name.
local ADDON_NAME, ns = ...

ns.GRP_GreetingLines = {
    join = {
        morning = {
            "Morning, everyone! ready to get moving?",
            "Good morning, let's make it a productive one.",
            "Morning all, coffee's optional, effort isn't.",
            "Rise and shine, party's assembled.",
            "Morning! glad to be grouped up with you all.",
        },
        midday = {
            "Afternoon, everyone! let's get to it.",
            "Good to be here, midday and ready to go.",
            "Hey all, perfect time for a run.",
            "Afternoon crew, let's make some progress.",
            "Glad to join up, let's not waste daylight.",
        },
        evening = {
            "Evening, everyone! good time for a group.",
            "Good evening all, let's get this done.",
            "Evening crew assembled, let's roll.",
            "Hey everyone, evening's the best time to group up.",
            "Good evening, ready when you are.",
        },
        night = {
            "Late one tonight, but glad to be here.",
            "Night owls unite, let's get to work.",
            "Evening turned into night, let's make it count.",
            "Burning the midnight oil with you all.",
            "Night shift assembled, let's go.",
        },
    },
    welcome = {
        morning = {
            "Morning, %t! welcome to the group.",
            "Good morning %t, glad to have you.",
            "Welcome aboard, %t! ready for a good morning run?",
            "Morning, %t! jump in whenever you're ready.",
            "Hey %t, welcome, morning's a good time to start.",
        },
        midday = {
            "Welcome, %t! good afternoon to join up.",
            "Hey %t, glad you're here this afternoon.",
            "Afternoon, %t, welcome to the group.",
            "Welcome aboard, %t, let's make the afternoon count.",
            "Hi %t, perfect time to join for the afternoon.",
        },
        evening = {
            "Evening, %t! welcome to the group.",
            "Good evening %t, glad to have you along.",
            "Welcome, %t, nice evening for a run.",
            "Hey %t, welcome aboard this evening.",
            "Evening, %t! jump in whenever ready.",
        },
        night = {
            "Welcome, %t, are you burning the midnight oil with us?",
            "Hey %t, glad to have another night owl.",
            "Welcome aboard, %t, late night crew right here.",
            "Night shift welcomes you, %t.",
            "Welcome, %t! good to have company this late.",
        },
    },
}

-- Local-language mirror -- ships with every slot EMPTY (this addon is English-only by
-- default; a user who wants their own language enables it and fills these in themselves
-- via the line editor, see ns.GabbaRP_BuildGeneralPanel's "Use local language" checkbox).
ns.GRP_GreetingLines_Local = {
    join = { morning = {}, midday = {}, evening = {}, night = {} },
    welcome = { morning = {}, midday = {}, evening = {}, night = {} },
}

-- Overridden per (category, timeOfDay) via GabbaRPCharDB.greetings.customLines (English)
-- or customLinesLocal (local language), edited live via the native options panel. An
-- override, once created, is the COMPLETE line list for that slot -- same semantics as
-- GabbaRPCharDB.rp.customLines. Falls back to English if the local language is requested
-- but nothing exists for that slot yet (custom or default), so an untranslated slot
-- doesn't just stay silent.
function ns.GabbaRP_GetEffectiveGreetingLines(category, timeOfDay, lang)
    if lang == "local" then
        local customLocal = GabbaRPCharDB.greetings.customLinesLocal[category]
        local localLines = (customLocal and customLocal[timeOfDay]) or ns.GRP_GreetingLines_Local[category][timeOfDay]
        if localLines and #localLines > 0 then return localLines end
    end
    local custom = GabbaRPCharDB.greetings.customLines[category]
    return (custom and custom[timeOfDay]) or ns.GRP_GreetingLines[category][timeOfDay]
end

local wasInGroup = false
local knownMembers = {}

local function GetTimeOfDay()
    local hour = date("*t").hour
    if hour >= 5 and hour < 12 then
        return "morning"
    elseif hour >= 12 and hour < 18 then
        return "midday"
    elseif hour >= 18 and hour < 22 then
        return "evening"
    else
        return "night"
    end
end

-- Plain math.random(#lines) can look suspiciously patterned with only a handful of lines
-- to choose from (relies on the PRNG's weaker low-order bits for a small range). Keyed by
-- the line-set table itself (e.g. ns.GRP_GreetingLines.join.morning) rather than a name,
-- since these greetings aren't tied to a spell -- excludes whichever line was said last
-- from that same set, so it can't repeat back-to-back.
local lastGreetingIndex = {}
local function PickLine(lines)
    if #lines <= 1 then return lines[1] end
    local idx
    repeat
        idx = math.random(#lines)
    until idx ~= lastGreetingIndex[lines]
    lastGreetingIndex[lines] = idx
    return lines[idx]
end

local function DoSayLine(category, timeOfDay, name, lang)
    if not GabbaRPCharDB.greetings.enabled then return end
    local lines = ns.GabbaRP_GetEffectiveGreetingLines(category, timeOfDay, lang)
    if not lines or #lines == 0 then return end
    local line = PickLine(lines)
    if name then
        line = line:gsub("%%t", name)
    end

    if GabbaRPCharDB.rp.mode == "self" or GabbaRPCharDB.rp.mode == "both" then
        ns.GabbaRP_Print(line)
    end
    if GabbaRPCharDB.rp.mode == "public" or GabbaRPCharDB.rp.mode == "both" then
        local chatType
        if IsInRaid() then
            chatType = "RAID"
        elseif IsInGroup() then
            chatType = "PARTY"
        end
        if chatType then
            -- Deferred by one frame to avoid inheriting taint from whatever ran earlier
            -- in this same GROUP_ROSTER_UPDATE tick -- same reasoning as RP_Core.lua's
            -- SendChatMessage calls.
            C_Timer.After(0, function() SendChatMessage(line, chatType) end)
        end
    end
end

-- "welcome" (a specific new member joining a group you're already in) uses THAT player's
-- own guild membership -- a non-guildmate joining a mostly-local-language group still
-- gets welcomed in English. "join" (the whole-group greeting when you yourself join) has
-- no single target to check, so it follows the overall group's guild-majority instead
-- (ns.GabbaRP_GetGroupLanguage, RP_Core.lua). Both gated by the localLanguageEnabled master switch.
local function SayLine(category, timeOfDay, name)
    if category == "welcome" and name then
        local lang = (GabbaRPCharDB.rp.localLanguageEnabled and ns.GabbaRP_IsInPlayerGuild(name)) and "local" or "en"
        if GabbaRPCharDB.rp.greetDebugLog then
            ns.GabbaRP_DebugLog("greeting", string.format(
                "welcome: name=%s isGuildmate=%s -> %s",
                tostring(name), tostring(ns.GabbaRP_IsInPlayerGuild(name)), lang))
        end
        DoSayLine(category, timeOfDay, name, lang)
        return
    end
    DoSayLine(category, timeOfDay, name, ns.GabbaRP_GetGroupLanguage())
end

local function SnapshotMembers()
    local members = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name = GetRaidRosterInfo(i)
            if name then
                members[name] = true
            end
        end
    elseif IsInGroup() then
        members[UnitName("player")] = true
        for i = 1, GetNumGroupMembers() - 1 do
            local name = UnitName("party" .. i)
            if name then
                members[name] = true
            end
        end
    end
    return members
end

-- GROUP_ROSTER_UPDATE fires repeatedly while a group is still coming together (invite
-- accepted, then each member's info syncing in separately) -- reacting to the very first
-- one greets a roster that isn't fully settled yet. Debounced instead: each event pushes
-- the actual check back by ROSTER_SETTLE_DELAY, so it only runs once the roster has
-- stopped changing for a moment.
local ROSTER_SETTLE_DELAY = 1.5 -- seconds
local settleTimer = nil

local function EvaluateRoster()
    settleTimer = nil
    local inGroup = IsInGroup() or IsInRaid()
    local currentMembers = SnapshotMembers()

    -- "join" is for joining a group that already existed without you -- if you're the
    -- leader at the first transition into a group, you almost certainly just formed it
    -- yourself by inviting people, not joined someone else's. Firing "join" there doubled
    -- up with "welcome" for the very first invitee, greeting the same single person twice
    -- within a couple seconds. Falling through to the per-member welcome loop instead
    -- (same as the "already in a group, someone new joined" case) means every initial
    -- invitee still gets welcomed individually, even if several joined in the same
    -- settle-delay window.
    if inGroup and not wasInGroup and not UnitIsGroupLeader("player") then
        SayLine("join", GetTimeOfDay())
    elseif inGroup then
        local playerName = UnitName("player")
        for name in pairs(currentMembers) do
            if not knownMembers[name] and name ~= playerName then
                SayLine("welcome", GetTimeOfDay(), name:match("^[^-]+"))
            end
        end
    end

    wasInGroup = inGroup
    knownMembers = currentMembers
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:SetScript("OnEvent", function(self, event, isLogin, isReload)
    if event == "PLAYER_ENTERING_WORLD" then
        -- PLAYER_ENTERING_WORLD fires on EVERY zone transition (dungeon entry, portal,
        -- etc.), not just login/reload -- isLogin/isReload are both false for those, and
        -- must be checked explicitly rather than assuming "not a reload" means "a login".
        if isLogin then
            -- Fresh login (or came back from a loading screen into an already-formed
            -- group, e.g. logging in already invited) -- you haven't greeted this session
            -- yet, so treat it like a genuine join even though there's no "transition" to
            -- observe. Debounced the same way, in case the roster is still syncing in
            -- right after login.
            wasInGroup = false
            knownMembers = {}
            if IsInGroup() or IsInRaid() then
                if settleTimer then settleTimer:Cancel() end
                settleTimer = C_Timer.NewTimer(ROSTER_SETTLE_DELAY, EvaluateRoster)
            end
        elseif isReload then
            -- /reload while already grouped -- don't re-greet, you were already here and
            -- already said hi; just re-seed silently so the next real roster change
            -- doesn't misread this as "I just joined".
            wasInGroup = IsInGroup() or IsInRaid()
            knownMembers = SnapshotMembers()
        end
        -- else: an ordinary zone transition -- neither login nor reload, group membership
        -- didn't change just because you walked into a dungeon. Do nothing; a real
        -- membership change fires its own GROUP_ROSTER_UPDATE independently.
        return
    end

    if settleTimer then
        settleTimer:Cancel()
    end
    settleTimer = C_Timer.NewTimer(ROSTER_SETTLE_DELAY, EvaluateRoster)
end)
