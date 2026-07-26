-- GetSpellInfo was removed on retail in patch 11.0 in favor of C_Spell.GetSpellInfo
-- (which returns a table instead of positional values) -- Classic Era hasn't removed the
-- old global as of this writing, but InviteUnit's removal (see RP_Queue.lua in the Gabba
-- addon) shows these deprecations do eventually land here too, so this shims proactively
-- rather than waiting for it to break. No-op while the old global still exists.
local ADDON_NAME, ns = ...

local GetSpellInfo = GetSpellInfo
if not GetSpellInfo and C_Spell and C_Spell.GetSpellInfo then
    GetSpellInfo = function(spellID)
        local info = C_Spell.GetSpellInfo(spellID)
        if not info then return nil end
        return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID, info.originalIconID
    end
end

local lastTrigger = {}
local castCount = {}
local lastLineIndex = {}
local playerGUID

-- Layered on top of the per-spell cooldown/interval below: a floor on how close
-- together ANY two lines can land (regardless of which skill triggered them, so a DoT
-- + Shadow Bolt opener can't fire three lines back to back), plus a random chance to
-- stay quiet even when nothing else would've blocked it. Both configurable in the RP
-- settings tab -- this is what keeps the module from commenting on literally everything.
local lastAnyTrigger = 0
-- Returns pass, reason -- reason is nil when pass is true, otherwise a short string for
-- /gabbarp triggerdebug explaining which of the two checks blocked it.
local function PassesGlobalGate()
    local db = GabbaRPCharDB.rp
    local now = GetTime()
    if now - lastAnyTrigger < (db.globalCooldown or 0) then
        return false, string.format("global cooldown active (%.1fs left)", (db.globalCooldown or 0) - (now - lastAnyTrigger))
    end

    local chance = db.triggerChance
    if chance and chance < 100 and math.random(100) > chance then
        return false, "chance roll failed (" .. chance .. "%)"
    end

    lastAnyTrigger = now
    return true
end

-- Plain math.random(#lines) can look suspiciously patterned with only a couple of
-- lines to choose from -- picking a small range like 1-2 leans on the PRNG's low-order
-- bits, which are much less random than the rest of its output for many generators.
-- Excluding whichever line was said last time (per spell) rules out the most noticeable
-- symptom of that: the same line firing twice in a row.
local function PickLine(spellName, lines)
    if #lines <= 1 then return lines[1] end
    local idx
    repeat
        idx = math.random(#lines)
    until idx ~= lastLineIndex[spellName]
    lastLineIndex[spellName] = idx
    return lines[idx]
end

-- A custom line list, once created via the editor UI, is the COMPLETE line list for
-- that spell (not merged with the shipped default) -- simplest mental model.
local function GetLines(spellName)
    return GabbaRPCharDB.rp.customLines[spellName] or ns.GRP_Spells[spellName]
end

-- Confirmed via testing: Say/Yell have required a real hardware event (an actual click
-- or keypress) to send since patch 8.2.5/Classic 1.13.3 -- an automatic trigger like a
-- spell cast or combat log event can never provide one directly. Libs/MessageQueue.lua
-- (LenweSaralonde/MessageQueue, embedded) works around this legitimately: it queues the
-- message and flushes it on the player's next real hardware input (any click/keypress),
-- which satisfies Blizzard's requirement without user-visible delay in practice. Only
-- falls back to Emote if that library somehow failed to load.
local function GetChatType(spellName)
    local chatType = GabbaRPCharDB.rp.customChatType[spellName] or ns.GRP_SpellChatType[spellName] or "EMOTE"
    if (chatType == "SAY" or chatType == "YELL") and not (MessageQueue and MessageQueue.SendChatMessage) then
        return "EMOTE"
    end
    return chatType
end

-- Checks guild membership against YOUR OWN guild roster (GetGuildRosterInfo) instead of
-- GetGuildInfo(unit)/GetGuildInfo(name) -- the private Gabba addon confirmed via debug
-- logging that GetGuildInfo(unit) can return nil for an actual party member well after
-- both have been grouped and online for a while, making it just as unreliable as the
-- name-string lookup it was meant to replace. Your own guild roster has no such per-unit
-- sync dependency, so this works the instant the party roster itself (just names, always
-- reliable) is available.
-- Deliberately global (not local) -- RP_Greeting.lua, loaded after this file, reuses it
-- for the "welcome" greeting's per-target guild check too.
function ns.GabbaRP_IsInPlayerGuild(name)
    if not name then return false end
    local shortName = name:match("^[^-]+")
    for i = 1, GetNumGuildMembers() do
        local guildName = GetGuildRosterInfo(i)
        if guildName and guildName:match("^[^-]+") == shortName then
            return true
        end
    end
    return false
end

-- Determines which language the RP module should currently speak: solo (nobody in a
-- group to measure against) uses the configured GabbaRPCharDB.rp.soloLanguage; grouped
-- play switches to the local language once more than half the party/raid shares your own
-- guild, English otherwise. Computed fresh at every trigger rather than cached once,
-- since group composition can change mid-session (people join/leave). Gated by
-- localLanguageEnabled (off by default -- see Core.lua) since this addon ships
-- English-only; the local language only ever fires once a user has both turned this on
-- AND filled in their own translated lines.
-- Deliberately global (not local) -- RP_Greeting.lua, loaded after this file, reuses it
-- for the "join" greeting's language too.
function ns.GabbaRP_GetGroupLanguage()
    if not GabbaRPCharDB.rp.localLanguageEnabled then
        return "en" -- master switch off -- skip the group/solo check entirely
    end
    if not (IsInGroup() or IsInRaid()) then
        return GabbaRPCharDB.rp.soloLanguage or "en"
    end
    local playerGuild = GetGuildInfo("player")
    if not playerGuild then
        if GabbaRPCharDB.rp.greetDebugLog then
            ns.GabbaRP_DebugLog("greeting", "ns.GabbaRP_GetGroupLanguage: GetGuildInfo('player') returned nil -> en")
        end
        return "en" -- no guild of your own, no "majority" to compute
    end

    local total, guildCount = 0, 0
    local debugParts = {}
    if IsInRaid() then
        -- Raid unit tokens include the player.
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            if UnitExists(unit) then
                total = total + 1
                local unitName = UnitName(unit)
                local isGuildmate = unitName == UnitName("player") or ns.GabbaRP_IsInPlayerGuild(unitName)
                if isGuildmate then
                    guildCount = guildCount + 1
                end
                if GabbaRPCharDB.rp.greetDebugLog then
                    table.insert(debugParts, unit .. "=" .. tostring(unitName) .. ":" .. tostring(isGuildmate))
                end
            end
        end
    else
        -- Party tokens (party1..N-1) exclude the player -- counted separately here, same
        -- convention already used by this file's own unit-token loops below.
        total, guildCount = 1, 1
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = "party" .. i
            if UnitExists(unit) then
                total = total + 1
                local unitName = UnitName(unit)
                local isGuildmate = ns.GabbaRP_IsInPlayerGuild(unitName)
                if isGuildmate then
                    guildCount = guildCount + 1
                end
                if GabbaRPCharDB.rp.greetDebugLog then
                    table.insert(debugParts, unit .. "=" .. tostring(unitName) .. ":" .. tostring(isGuildmate))
                end
            end
        end
    end

    if total == 0 then return GabbaRPCharDB.rp.soloLanguage or "en" end
    local result = (guildCount / total > 0.5) and "local" or "en"
    if GabbaRPCharDB.rp.greetDebugLog then
        ns.GabbaRP_DebugLog("greeting", string.format(
            "ns.GabbaRP_GetGroupLanguage: playerGuild=%s guildCount=%d/%d -> %s | %s",
            tostring(playerGuild), guildCount, total, result, table.concat(debugParts, ", ")))
    end
    return result
end

-- Redirects to the local-language entry for this spell/reaction key if the computed
-- language calls for it AND a local-language entry actually exists (checked in either the
-- shipped defaults or a live customLines override) -- falls back to the plain English key
-- otherwise, so anything not translated yet stays in English instead of going silent.
local function ResolveSpellKey(spellName, lang)
    if lang == "local" then
        local localKey = spellName .. " (LOCAL)"
        if ns.GRP_Spells[localKey] or GabbaRPCharDB.rp.customLines[localKey] then
            return localKey
        end
    end
    return spellName
end

-- %t/%p/%w are plain gsub substitutions, not string.format -- a user typing a stray "%" in
-- their own custom line would otherwise error out of string.format entirely.
-- Optional per-line chat-type override: a line can start with "[SAY]", "[YELL]", or
-- "[EMOTE]" (whitespace after the tag is optional -- "[SAY] text" and "[SAY]text" both
-- work) to say THIS line differently than the skill's normal chat type, e.g. one line
-- that reads better shouted than emoted. GROUP_ANNOUNCE is deliberately not a valid tag
-- here -- that chat type is driven entirely by AnnounceGroupCast on cast start, never by
-- an individual line.
local VALID_LINE_CHATTYPE_OVERRIDES = { SAY = true, YELL = true, EMOTE = true }
local function ExtractLineChatTypeOverride(line)
    local tag, rest = line:match("^%[(%a+)%]%s*(.*)$")
    if tag and VALID_LINE_CHATTYPE_OVERRIDES[tag:upper()] then
        return tag:upper(), rest
    end
    return nil, line
end

local function ApplyPlaceholders(line, targetName, lastWords)
    line = line:gsub("%%t", targetName and targetName:match("^[^-]+") or "you")
    line = line:gsub("%%p", UnitExists("pet") and UnitName("pet") or "my pet")
    -- %w: the deceased's last words, only ever populated for "Death: Guild" (the only
    -- reaction sourced from DeathNotificationLib's playerData, which is the only place
    -- last words come from -- Death: Group/Raid fire off the combat log directly and have
    -- no such data). Falls back to "nothing" so a custom line using %w still reads fine
    -- when the player never set any.
    line = line:gsub("%%w", (lastWords and lastWords ~= "") and lastWords or "nothing")
    return line
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
frame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_AURA")

-- /gabbarp triggerdebug -- explains why TriggerLine did or didn't produce a line for a
-- given skill, e.g. for "this skill never comments" reports. A no-op call when the flag
-- is off, so it's cheap to sprinkle at every early-return point below.
local function TDebug(spellName, msg)
    if GabbaRPCharDB.rp.triggerDebugLog then
        ns.GabbaRP_DebugLog("trigger", spellName .. ": " .. msg)
    end
end

local function TriggerLine(spellName, targetName, publicChatType, lastWords)
    local db = GabbaRPCharDB.rp
    if not db.enabled then return end

    local lines = GetLines(spellName)
    if not lines or #lines == 0 then
        TDebug(spellName, "no lines configured")
        return
    end

    -- Partition into %w lines (only make sense when there's an actual last-words string
    -- to put there) and plain lines. When last words ARE available, only the %w lines are
    -- eligible -- otherwise a %w line competes on equal footing with plain ones and
    -- usually loses, so the whole point of writing one rarely pays off. Falls back to the
    -- plain pool if last words exist but nothing with %w has been authored yet, so Death:
    -- Guild doesn't go silent just because no %w line exists. GetLines/customLines itself
    -- still reports the full authored list everywhere else (editor, export, etc.) -- this
    -- filtering is local to picking a line to actually say right now.
    local hasLastWords = lastWords and lastWords ~= ""
    local wLines, plainLines = {}, {}
    for _, l in ipairs(lines) do
        if l:find("%w", 1, true) then
            table.insert(wLines, l)
        else
            table.insert(plainLines, l)
        end
    end
    if hasLastWords and #wLines > 0 then
        lines = wLines
    else
        lines = plainLines
        if #lines == 0 then
            TDebug(spellName, "no lines configured (only %w lines, no last words)")
            return
        end
    end

    if db.disabledSpells[spellName] then
        TDebug(spellName, "skill disabled")
        return
    end

    -- GROUP_ANNOUNCE spells are handled entirely by AnnounceGroupCast on cast start
    -- instead (see below) -- they never produce a normal emote/self/public line here.
    local chatType = publicChatType or GetChatType(spellName)
    if chatType == "GROUP_ANNOUNCE" then return end

    -- Imp reactions, Death reactions, and Create Soulstone all bypass the per-spell
    -- cooldown AND the shared global gate below. The Imp only talks back when it actually
    -- says something (a handful of times per fight at most), so there's no realistic spam
    -- risk, and throttling it just made it feel unresponsive. A death is rarer still and
    -- far more important to actually see -- the global gate's random triggerChance (35% by
    -- default) was silently swallowing real guild/group/raid death announcements most of
    -- the time, which defeats the entire point of the feature. Handing someone a
    -- soulstone is just as rare/deliberate as either -- it should never get randomly
    -- swallowed.
    local bypassesGlobalGate = spellName:match("^Imp: ") ~= nil or spellName:match("^Death: ") ~= nil
        or spellName == "Create Soulstone" or spellName == "Create Soulstone (LOCAL)"

    if not bypassesGlobalGate then
        local interval = ns.GRP_SpellInterval and ns.GRP_SpellInterval[spellName]
        if interval then
            castCount[spellName] = (castCount[spellName] or 0) + 1
            if castCount[spellName] % interval ~= 1 then
                TDebug(spellName, string.format("waiting for interval (cast %d, every %dth)", castCount[spellName], interval))
                return
            end
        else
            local now = GetTime()
            local perSkillCooldown = db.perSkillCooldown or ns.GRP_DEFAULT_PER_SKILL_COOLDOWN
            if lastTrigger[spellName] and (now - lastTrigger[spellName]) < perSkillCooldown then
                TDebug(spellName, string.format("per-skill cooldown active (%.1fs left)", perSkillCooldown - (now - lastTrigger[spellName])))
                return
            end
            lastTrigger[spellName] = now
        end

        local passes, reason = PassesGlobalGate()
        if not passes then
            TDebug(spellName, "blocked by global gate: " .. reason)
            return
        end
    end

    TDebug(spellName, "fired")
    local lineChatType, strippedLine = ExtractLineChatTypeOverride(PickLine(spellName, lines))
    local line = ApplyPlaceholders(strippedLine, targetName, lastWords)

    -- A line's own [SAY]/[YELL]/[EMOTE] tag wins over the skill's normal chat type, with
    -- the same MessageQueue-availability downgrade GetChatType applies above (Say/Yell
    -- need a real hardware event to send at all -- see the C_Timer.After comment below --
    -- so without MessageQueue loaded, an override to either just falls back to Emote
    -- instead of silently never sending). Not honored when the CALLER forced a specific
    -- channel (publicChatType, e.g. Create Soulstone's dynamic RAID/PARTY targeting) --
    -- that's a delivery guarantee the line-level tag must not be able to break.
    local effectiveChatType = chatType
    if lineChatType and not publicChatType then
        effectiveChatType = lineChatType
        if (effectiveChatType == "SAY" or effectiveChatType == "YELL") and not (MessageQueue and MessageQueue.SendChatMessage) then
            effectiveChatType = "EMOTE"
        end
    end

    if db.anim then
        local token = ns.GRP_EmoteTokens[spellName]
        if token then
            DoEmote(token)
        end
    end

    if db.mode == "self" or db.mode == "both" then
        ns.GabbaRP_Print(line)
    end

    if db.mode == "public" or db.mode == "both" then
        if (effectiveChatType == "SAY" or effectiveChatType == "YELL") and MessageQueue and MessageQueue.SendChatMessage then
            -- Say/Yell need a real hardware event to send at all (see GetChatType above)
            -- -- MessageQueue queues it and flushes on the player's next actual
            -- click/keypress, which satisfies that requirement.
            MessageQueue.SendChatMessage(line, effectiveChatType)
        else
            -- Deferred by one frame on purpose: TriggerLine can run synchronously inside
            -- the COMBAT_LOG_EVENT_UNFILTERED dispatch (e.g. for a self-cast like Life
            -- Tap), and that same tick sometimes carries taint from Blizzard's own secure
            -- combat processing (or another addon hooking the same event) -- calling the
            -- deprecated SendChatMessage wrapper directly from inside that tainted stack
            -- can trip ADDON_ACTION_BLOCKED even though nothing about the call itself is
            -- invalid. Pushing it to the next frame runs it in a clean, untainted context
            -- instead.
            C_Timer.After(0, function() SendChatMessage(line, effectiveChatType) end)
        end
    end
end

-- Food/Drink don't reliably generate a COMBAT_LOG_EVENT_UNFILTERED SPELL_AURA_APPLIED
-- for the player (confirmed via debug logging: it never fired while eating/drinking) --
-- so these two are detected directly off the buff bar instead, same UnitBuff-scanning
-- approach ProtectionBar.lua uses for shield auras. Edge-triggered so it only fires once
-- per meal, not on every UNIT_AURA tick while the buff is still up.
--
-- Eating and drinking at once (the common case -- right-clicking both stacks back to
-- back) used to fire both lines almost simultaneously. Instead of reacting to either
-- onset immediately, a short delay lets the other one catch up so a single combined
-- line can be picked once it's clear whether it's really both at once or just one.
local FOOD_DRINK_COMBINE_DELAY = 0.5
local wasEating, wasDrinking = false, false
local pendingFoodDrinkTimer

local function DecideFoodDrinkLine()
    pendingFoodDrinkTimer = nil
    local lang = ns.GabbaRP_GetGroupLanguage()
    if wasEating and wasDrinking then
        TriggerLine(ResolveSpellKey("Food and Drink", lang))
    elseif wasEating then
        TriggerLine(ResolveSpellKey("Food", lang))
    elseif wasDrinking then
        TriggerLine(ResolveSpellKey("Drink", lang))
    end
end

local function CheckFoodDrink()
    local eating, drinking = false, false
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        if name == "Food" then eating = true
        elseif name == "Drink" then drinking = true end
    end

    local newlyEating = eating and not wasEating
    local newlyDrinking = drinking and not wasDrinking
    wasEating, wasDrinking = eating, drinking

    if newlyEating or newlyDrinking then
        if pendingFoodDrinkTimer then
            pendingFoodDrinkTimer:Cancel()
        end
        pendingFoodDrinkTimer = C_Timer.NewTimer(FOOD_DRINK_COMBINE_DELAY, DecideFoodDrinkLine)
    end
end

-- Announces GROUP_ANNOUNCE spells (e.g. Ritual of Summoning) to party/raid chat the
-- moment you START casting, not when the (long) cast finishes -- and always, regardless
-- of /gabba rp mode, since the point is warning the group before the cast completes.
local lastAnnounce = {}
local function AnnounceGroupCast(spellName, targetName)
    local db = GabbaRPCharDB.rp
    if not db.enabled then return end
    if GetChatType(spellName) ~= "GROUP_ANNOUNCE" then return end

    local lines = GetLines(spellName)
    if not lines or #lines == 0 then return end
    if db.disabledSpells[spellName] then return end

    local now = GetTime()
    if lastAnnounce[spellName] and (now - lastAnnounce[spellName]) < (db.perSkillCooldown or ns.GRP_DEFAULT_PER_SKILL_COOLDOWN) then return end
    lastAnnounce[spellName] = now

    local chatType
    if IsInRaid() then
        chatType = "RAID"
    elseif IsInGroup() then
        chatType = "PARTY"
    end
    if not chatType then return end

    local line = ApplyPlaceholders(PickLine(spellName, lines), targetName)
    -- Same taint-avoidance reasoning as TriggerLine's SendChatMessage call above.
    C_Timer.After(0, function() SendChatMessage(line, chatType) end)
end

function ns.GabbaRP_HandleCommand(msg)
    local db = GabbaRPCharDB.rp
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    arg = (arg or ""):lower()

    if cmd == "on" then
        db.enabled = true
        ns.GabbaRP_Print("RP module enabled.")
    elseif cmd == "off" then
        db.enabled = false
        ns.GabbaRP_Print("RP module disabled.")
    elseif cmd == "mode" and (arg == "self" or arg == "public" or arg == "both") then
        db.mode = arg
        ns.GabbaRP_Print("RP mode set to: " .. arg)
    elseif cmd == "anim" and (arg == "on" or arg == "off") then
        db.anim = (arg == "on")
        ns.GabbaRP_Print("RP emote animation " .. (db.anim and "on" or "off") .. ".")
    elseif cmd == "greetings" and (arg == "on" or arg == "off") then
        GabbaRPCharDB.greetings.enabled = (arg == "on")
        ns.GabbaRP_Print("Group greetings " .. arg .. ".")
    elseif cmd == "impdebug" and (arg == "on" or arg == "off") then
        db.impDebugLog = (arg == "on")
        ns.GabbaRP_Print("Imp backtalk debug log " .. (db.impDebugLog and "on" or "off") .. ".")
    elseif cmd == "greetdebug" and (arg == "on" or arg == "off") then
        db.greetDebugLog = (arg == "on")
        ns.GabbaRP_Print("Greeting/language debug log " .. (db.greetDebugLog and "on" or "off") .. ".")
    elseif cmd == "triggerdebug" and (arg == "on" or arg == "off") then
        db.triggerDebugLog = (arg == "on")
        ns.GabbaRP_Print("Trigger/spam-gate debug log " .. (db.triggerDebugLog and "on" or "off") .. ".")
    elseif cmd == "debuglog" then
        if arg == "clear" then
            wipe(GabbaRPCharDB.debugLog)
            ns.GabbaRP_Print("Debug log cleared.")
        else
            ns.GabbaRP_Print(#GabbaRPCharDB.debugLog .. " debug log entries stored (also readable straight from the saved GabbaRP.lua file after a /reload). /gabbarp debuglog clear to wipe.")
        end
    elseif cmd == "report" then
        ns.GabbaRP_PrintReport()
    elseif cmd == "testdeath" then
        -- Debug helper: fires the exact same Death: Guild dispatch DeathNotificationLib's
        -- HookOnNewEntry callback would, without needing an actual death to test against --
        -- handy for testing %w (last words) or the Death: Guild line pool in general.
        -- Re-parses the raw msg instead of using the already-lowercased arg above, since a
        -- player name and last words shouldn't be forced to lowercase.
        local name, lastWords = msg:match("^%S+%s+(%S+)%s*(.-)$")
        if not name then
            ns.GabbaRP_Print("Usage: /gabbarp testdeath <name> [last words]")
        else
            lastWords = lastWords ~= "" and lastWords or nil
            local lang = GabbaRPCharDB.rp.localLanguageEnabled and "local" or "en"
            TriggerLine(ResolveSpellKey("Death: Guild", lang), name, nil, lastWords)
            ns.GabbaRP_Print(string.format("Simulated Death: Guild for %s (last words: %s)", name, lastWords or "none"))
        end
    else
        ns.GabbaRP_Print("Commands:")
        ns.GabbaRP_Print("  /gabbarp on | off")
        ns.GabbaRP_Print("  /gabbarp mode self|public|both  (current: " .. db.mode .. ")")
        ns.GabbaRP_Print("  /gabbarp anim on|off  (current: " .. (db.anim and "on" or "off") .. ")")
        ns.GabbaRP_Print("  /gabbarp greetings on|off  (current: " .. (GabbaRPCharDB.greetings.enabled and "on" or "off") .. ")")
        ns.GabbaRP_Print("  /gabbarp impdebug on|off  (noisy Imp Backtalk troubleshooting log, current: " .. (db.impDebugLog and "on" or "off") .. ")")
        ns.GabbaRP_Print("  /gabbarp greetdebug on|off  (LOCAL/EN language decision troubleshooting log, current: " .. (db.greetDebugLog and "on" or "off") .. ")")
        ns.GabbaRP_Print("  /gabbarp triggerdebug on|off  (why a skill did/didn't comment, current: " .. (db.triggerDebugLog and "on" or "off") .. ")")
        ns.GabbaRP_Print("  /gabbarp debuglog [clear]  (persisted debug trail, readable from the saved GabbaRP.lua file)")
        ns.GabbaRP_Print("  /gabbarp report  (copy-pasteable diagnostic summary for bug reports)")
        ns.GabbaRP_Print("  /gabbarp testdeath <name> [last words]  (simulate a Death: Guild reaction)")
    end
end

-- Matches an overheard Imp Say/Yell against the known real voice lines (see
-- ns.GRP_ImpQuotePatterns in RP_Data.lua) to find which category it's talking back to. Plain
-- substring search, not exact equality or Lua patterns -- imp lines contain punctuation
-- that would need escaping as Lua patterns, and this is more forgiving of any minor text
-- variance anyway. Case-insensitive since Blizzard's exact casing isn't something worth
-- depending on.
local function MatchImpCategory(text)
    if not text then return nil end
    local lowerText = text:lower()
    for category, patterns in pairs(ns.GRP_ImpQuotePatterns) do
        for _, pattern in ipairs(patterns) do
            if lowerText:find(pattern:lower(), 1, true) then
                return category
            end
        end
    end
    -- Doesn't match any known Common/Orcish line -- the Imp says things in Demonic
    -- gibberish about as often as it does English, so fall back to its own category
    -- instead of staying silent on those.
    return "Imp: Gibberish"
end

StaticPopupDialogs["GABBARP_SAYYELL_WARNING"] = {
    text = "|cffffd200GabbaRP|r\n\n|cffff8800Heads up:|r you have a skill set to Say/Yell chat.\n\nSending a Say/Yell message this way needs a real click or keypress, so it's queued and sent on your very next one. For mouse players, that means one click (e.g. your next action bar press) gets eaten by this instead of doing what you clicked.\n\nSwitch the skill to Emote in the editor if that bothers you.",
    button1 = "Got it",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Warns once per login (as a popup, not a chat line that's easy to miss/scroll past) if
-- the Say/Yell workaround (Libs/MessageQueue.lua) is actually going to matter for this
-- character right now -- i.e. at least one of their own class's enabled skills currently
-- resolves to Say or Yell. That workaround needs a real click/keypress to legally send a
-- chat message Blizzard didn't originate from one, so it grabs the player's very next
-- click/keypress ANYWHERE on screen to use as that trigger -- for a mouse player, that
-- means one click that was meant for something else (like the next action bar button)
-- gets eaten instead. Silent when nothing's actually configured for Say/Yell, since the
-- workaround only ever runs when a Say/Yell line can fire.
local function WarnIfSayYellConfigured()
    local db = GabbaRPCharDB.rp
    local _, playerClass = UnitClass("player")
    for spellName, class in pairs(ns.GRP_SpellClass) do
        if class == playerClass and not db.disabledSpells[spellName] then
            local ct = GetChatType(spellName)
            if ct == "SAY" or ct == "YELL" then
                StaticPopup_Show("GABBARP_SAYYELL_WARNING")
                return
            end
        end
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        playerGUID = UnitGUID("player")
        WarnIfSayYellConfigured()

        -- Guild death reactions ride on DeathNotificationLib (a separate, optional addon
        -- -- Deathlog and others already depend on it) instead of anything homegrown: it's
        -- the thing that actually receives Blizzard's server-wide Hardcore death broadcast
        -- (HARDCORE_DEATHS channel) plus peer sync, so a guildmate's death is known even
        -- if you never witnessed it yourself. Group/raid deaths below don't need this --
        -- combat log already sees those directly since you're grouped with them.
        if DeathNotificationLib and DeathNotificationLib.HookOnNewEntry then
            DeathNotificationLib.HookOnNewEntry(function(playerData, _, _, inGuild)
                -- pcall-wrapped: this runs inside DeathNotificationLib's own callback loop,
                -- not ours -- an uncaught error here (e.g. from a future signature change on
                -- their end) would otherwise surface confusingly attributed to that addon,
                -- and could potentially stop it from notifying any callbacks registered
                -- after ours in the same loop.
                local ok, err = pcall(function()
                    if inGuild and playerData and playerData.name then
                        -- Always the local language when the master switch is on, unconditionally
                        -- otherwise -- this goes to GUILD chat, whose audience is the guild by
                        -- definition, so there's no group composition to measure (the person who
                        -- died may not even be in your party/raid).
                        local lang = GabbaRPCharDB.rp.localLanguageEnabled and "local" or "en"
                        TriggerLine(ResolveSpellKey("Death: Guild", lang), playerData.name, nil, playerData.last_words)
                    end
                end)
                if not ok then
                    ns.GabbaRP_Print("|cffff4444Error in DeathNotificationLib callback:|r " .. tostring(err))
                end
            end)
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subevent, _, sourceGUID, _, _, _, destGUID, destName, _, _, _, spellName = CombatLogGetCurrentEventInfo()
        if subevent == "SPELL_CAST_SUCCESS" and sourceGUID == playerGUID then
            -- GROUP_ANNOUNCE spells are already announced on cast start (see
            -- AnnounceGroupCast below) -- TriggerLine self-guards against those too, but
            -- no need to even attempt it here.
            if spellName == "Create Soulstone" or spellName == "Create Soulstone (Lesser)"
                or spellName == "Create Soulstone (Minor)" then
                -- All three ranks share one reaction/line pool under the max-rank name --
                -- targets party/raid chat dynamically (so it always resolves to a channel
                -- you're actually in) instead of a fixed chatType like most other spells.
                -- Falls back to the default (EMOTE) when not grouped at all.
                local key = ResolveSpellKey("Create Soulstone", ns.GabbaRP_GetGroupLanguage())
                if IsInRaid() then
                    TriggerLine(key, destName, "RAID")
                elseif IsInGroup() then
                    TriggerLine(key, destName, "PARTY")
                else
                    TriggerLine(key, destName)
                end
            else
                TriggerLine(ResolveSpellKey(spellName, ns.GabbaRP_GetGroupLanguage()), destName)
            end
        elseif subevent == "SPELL_AURA_APPLIED" and destGUID == playerGUID and sourceGUID == playerGUID then
            -- for buff procs like Nightfall/"Shadow Trance" that aren't a cast of your own --
            -- sourceGUID must ALSO be the player, not just destGUID, otherwise this fires
            -- whenever anyone else's buff lands on you (e.g. another priest's Power Word:
            -- Shield/Fortitude), reacting as if you had cast it yourself
            TriggerLine(ResolveSpellKey(spellName, ns.GabbaRP_GetGroupLanguage()))
        elseif subevent == "UNIT_DIED" and destGUID ~= playerGUID and destName then
            -- Party/raid membership MUST be checked before scheduling anything below --
            -- UNIT_DIED fires for any unit, including NPCs/mobs, and UnitIsDeadOrGhost's
            -- name-based resolution only works for actual party/raid members. Checking it
            -- first (like this used to) avoids misfiring "looked like Feign Death" for
            -- every mob kill, since a mob name never resolves as party/raid at all.
            local isRaidMember = UnitInRaid(destName)
            if UnitInParty(destName) or isRaidMember then
                -- Feign Death can trigger a bogus UNIT_DIED without an actual death --
                -- confirm before reacting. Checks BOTH UnitIsDeadOrGhost (should be true
                -- for a real death) AND the dedicated UnitIsFeignDeath (should be false)
                -- -- belt and suspenders, since UnitIsDeadOrGhost alone wasn't reliably
                -- catching every feign in testing. Delayed briefly since these flags
                -- aren't always set the instant UNIT_DIED fires.
                C_Timer.After(0.5, function()
                    if not UnitIsDeadOrGhost(destName) or UnitIsFeignDeath(destName) then
                        ns.GabbaRP_Print(destName .. "'s death looked like Feign Death, ignoring.")
                        return
                    end
                    local db = GabbaRPCharDB.rp
                    -- If this person is a guildmate, DeathNotificationLib will separately
                    -- announce the death in guild chat a few seconds from now (it has its
                    -- own ~5s grace period) -- skip the immediate group/raid reaction here
                    -- so the same death isn't announced twice. Only skip if we're sure the
                    -- guild announcement will actually happen: the library has to be
                    -- installed and "Death: Guild" has to still be enabled.
                    local guildWillCover = false
                    if db.suppressGroupRaidIfGuild and DeathNotificationLib and DeathNotificationLib.HookOnNewEntry
                        and not db.disabledSpells["Death: Guild"] then
                        local destGuild = GetGuildInfo(destName)
                        local playerGuild = GetGuildInfo("player")
                        guildWillCover = destGuild and playerGuild and destGuild == playerGuild
                    end
                    if not guildWillCover then
                        local lang = ns.GabbaRP_GetGroupLanguage()
                        if isRaidMember then
                            TriggerLine(ResolveSpellKey("Death: Raid", lang), destName)
                        else
                            TriggerLine(ResolveSpellKey("Death: Group", lang), destName)
                        end
                    end
                end)
            end
        end
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            CheckFoodDrink()
        end
    elseif event == "UNIT_SPELLCAST_START" then
        local unit, _, spellID = ...
        if unit == "player" then
            local spellName = GetSpellInfo(spellID)
            if spellName then
                AnnounceGroupCast(ResolveSpellKey(spellName, ns.GabbaRP_GetGroupLanguage()), UnitName("target"))
            end
        end
    elseif event == "CHAT_MSG_MONSTER_SAY" or event == "CHAT_MSG_MONSTER_YELL" then
        local text, sender = ...
        -- Off by default (/gabbarp impdebug on|off) -- noisy, fires for every nearby
        -- monster Say/Yell, not just your own Imp's; only useful for troubleshooting
        -- "Imp Backtalk doesn't fire" reports.
        if GabbaRPCharDB.rp.impDebugLog then
            ns.GabbaRP_Print(string.format("[imp debug] %s text=%q sender=%q petExists=%s petName=%s petFamily=%s",
                event, tostring(text), tostring(sender),
                tostring(UnitExists("pet")), tostring(UnitExists("pet") and UnitName("pet")),
                tostring(UnitExists("pet") and UnitCreatureFamily("pet"))))
        end
        -- The GUID argument this event provides is always nil on this client (confirmed
        -- via a raw arg dump -- every other CHAT_MSG_MONSTER_SAY/YELL field comes through
        -- fine, but the guid slot itself is never populated here), so matching by name
        -- instead -- reliable in practice since UnitName("pet") is exactly what shows up
        -- as the sender in chat, custom pet name or not.
        if UnitExists("pet") and sender == UnitName("pet") and UnitCreatureFamily("pet") == "Imp" then
            -- No chatType override here -- Say/Yell can never be sent by an automatic
            -- trigger (see GetChatType above), so this resolves through the normal
            -- default/custom chat type like every other line instead of mirroring the
            -- overheard event type.
            local category = MatchImpCategory(text)
            if category then
                TriggerLine(ResolveSpellKey(category, ns.GabbaRP_GetGroupLanguage()), UnitName("pet"))
            end
        end
    end
end)
