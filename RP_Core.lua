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

-- Some spells share the exact same effect/line pool across ranks but Blizzard gives
-- each rank tier a genuinely different name (unlike most spells, where every rank
-- shares one name) -- normalized here, at the one place spellName comes straight from
-- the combat log, so the rest of the pipeline (lines, chatType, disabledSpells,
-- export/import, the line editor) only ever has to know about the canonical name.
local RANK_ALIASES = {
    ["Demon Skin"] = "Demon Armor",
    ["Detect Greater Invisibility"] = "Detect Invisibility",
    -- Casting "Create Soulstone" only conjures the item into your bags -- no target
    -- involved yet, see UNIT_SPELLCAST_START below. "Soulstone Resurrection" is the
    -- cast that actually fires when the conjured item gets USED on someone, which is
    -- the real "giving" moment these lines are meant for -- reuses the same stored
    -- lines/chatType/settings under the "Create Soulstone" key rather than needing a
    -- separate entry.
    ["Soulstone Resurrection"] = "Create Soulstone",
}

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
-- spell cast or combat log event can never provide one directly. Two ways around
-- that, picked via GabbaRPCharDB.rp.sayYellDelivery: "safe" (default, SayYellQueue.lua
-- -- hooks real game actions, never swallows a click, just possibly a beat slower)
-- or "instant" (Libs/MessageQueue.lua -- near-zero delay, swallows the player's next
-- input). Only falls back to Emote if "instant" is selected and that library somehow
-- failed to load -- SayYellQueue.lua is part of this addon itself, so "safe" is
-- always available.
local function SayYellAvailable()
    if GabbaRPCharDB.rp.sayYellDelivery == "instant" then
        return MessageQueue and MessageQueue.SendChatMessage and true or false
    end
    return true
end

local function GetChatType(spellName)
    local chatType = GabbaRPCharDB.rp.customChatType[spellName] or ns.GRP_SpellChatType[spellName] or "EMOTE"
    if (chatType == "SAY" or chatType == "YELL") and not SayYellAvailable() then
        return "EMOTE"
    end
    return chatType
end

-- Shared "does this spell skip the cooldown/global gate BY DEFAULT" rule -- single
-- source of truth used by both the actual dispatch (TriggerLine/AnnounceGroupCast
-- below) and the line editor UI (RP_Options.lua's "Always react" checkbox), so the
-- checkbox always accurately reflects what will really happen. db.customSkipGate
-- always wins over this default once explicitly set either way -- see call sites.
-- Imp/Death reactions and "Group Start" (cast-start announcements) all skip by
-- default for the same reason: they're rare/deliberate enough that throttling them
-- just means rarely ever seeing them at all. ns.GRP_SkipGlobalGate (RP_Data.lua)
-- covers additional individual spells that don't fit either category, e.g. Shadow
-- Trance.
function ns.GabbaRP_DefaultSkipGate(spellName, chatType)
    return spellName:match("^Imp: ") ~= nil
        or spellName:match("^Death: ") ~= nil
        or chatType == "GROUP_ANNOUNCE"
        or (ns.GRP_SkipGlobalGate and ns.GRP_SkipGlobalGate[spellName] and true or false)
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
-- Optional per-line chat-type override: a line can start with "[SAY]", "[YELL]",
-- "[EMOTE]", "[PARTY]", or "[RAID]" (whitespace after the tag is optional -- "[SAY]
-- text" and "[SAY]text" both work) to say THIS line differently than the skill's
-- normal chat type, e.g. one line that reads better shouted than emoted, or a specific
-- line that should always go to a fixed channel even though the skill itself uses the
-- dynamic "Group Start"/"Group Success" auto-channel types. GROUP_ANNOUNCE/GROUP_SUCCESS
-- are deliberately not valid tags here -- those are skill-level, dynamic-channel
-- concepts, not something a single static line tag can express.
local VALID_LINE_CHATTYPE_OVERRIDES = { SAY = true, YELL = true, EMOTE = true, PARTY = true, RAID = true }
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

-- Zoning (entering/leaving an instance, taking a portal, etc.) can make the server
-- resend SPELL_AURA_APPLIED for a long-duration self-buff you already had up (Demon
-- Armor and the like), not a real new cast -- confirmed live: a "Demon Armor" line
-- fired the instant a character zoned into an instance despite no cast happening.
-- Suppressed for a couple seconds after PLAYER_ENTERING_WORLD so this resync artifact
-- doesn't read as a genuine cast.
local justZoned = false

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
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

-- Mind Control / Mind Vision get an ADDITIONAL whisper-to-target reaction, on top of
-- (not instead of) their normal group-facing line -- separate dummy entries ("Mind
-- Control Whisper"/"Mind Vision Whisper", plus (LOCAL) mirrors, RP_Data.lua) hold this
-- line pool. Always a whisper to whoever was actually targeted, or (Mind Control
-- against the opposing faction only) a Say translated through the Hermes addon's
-- global sayToOtherFaction(msg, "SAY"|"YELL") function if it's installed -- never a
-- fixed chat type a user picks, hence no "Send as" selector for these two in the
-- editor (see ShowLineEditor's isWhisperDummy handling, RP_Options.lua). Skipped
-- entirely if the target isn't an actual player (an NPC/critter/etc. can't be
-- whispered, and Hermes only ever applies to real opposing-faction players) or if no
-- lines are configured, same as any other reaction.
local WHISPER_REACTION_SPELLS = {
    ["Mind Control"] = { key = "Mind Control Whisper", hermesFallback = true },
    ["Mind Vision"] = { key = "Mind Vision Whisper", hermesFallback = false },
}

local function TryTargetWhisperReaction(spellName, destGUID, destName)
    local reaction = WHISPER_REACTION_SPELLS[spellName]
    if not reaction then return end
    if not destGUID or not destGUID:match("^Player%-") or not destName then
        TDebug(reaction.key, "target isn't a player, nothing to whisper")
        return
    end

    local db = GabbaRPCharDB.rp
    if not db.enabled then return end
    if db.disabledSpells[reaction.key] then
        TDebug(reaction.key, "skill disabled")
        return
    end

    local resolvedKey = ResolveSpellKey(reaction.key, ns.GabbaRP_GetGroupLanguage())
    local lines = GetLines(resolvedKey)
    if not lines or #lines == 0 then
        TDebug(resolvedKey, "no lines configured")
        return
    end

    local sameFaction = UnitFactionGroup("player") == UnitFactionGroup(destName)
    local line = ApplyPlaceholders(PickLine(resolvedKey, lines), destName)

    if sameFaction then
        TDebug(resolvedKey, "fired (whisper to " .. destName .. ")")
        SendChatMessage(line, "WHISPER", nil, destName)
    elseif reaction.hermesFallback and sayToOtherFaction then
        TDebug(resolvedKey, "fired (Hermes Say fallback, opposing faction)")
        sayToOtherFaction(line, "SAY")
    else
        TDebug(resolvedKey, "opposing faction, no Hermes fallback available -- skipped")
    end
end

local function TriggerLine(spellName, targetName, lastWords)
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
    local chatType = GetChatType(spellName)
    if chatType == "GROUP_ANNOUNCE" then
        TDebug(spellName, "chatType is GROUP_ANNOUNCE, handled by AnnounceGroupCast instead")
        return
    end

    -- See ns.GabbaRP_DefaultSkipGate above for the default rule (Imp/Death/rare procs);
    -- db.customSkipGate (line editor's "Always react" checkbox) always wins over it
    -- once explicitly set either way.
    local skipGate = ns.GabbaRP_DefaultSkipGate(spellName, chatType)
    if db.customSkipGate[spellName] ~= nil then
        skipGate = db.customSkipGate[spellName]
    end
    local bypassesGlobalGate = skipGate

    if not bypassesGlobalGate then
        -- db.customInterval (line editor's "React every N casts" field) overrides the
        -- code default when set; there's no override for "explicitly disable a
        -- code-default interval" -- customSkipGate above already covers "never
        -- throttle this spell at all", which is the only override direction requested.
        local interval = db.customInterval[spellName] or (ns.GRP_SpellInterval and ns.GRP_SpellInterval[spellName])
        -- x % 1 is always 0, never 1 -- an interval of 1 (or 0) would never pass the
        -- check below at all, silently going permanently silent instead of "every
        -- cast". User-entered values can be 0/1 (the code defaults above never are),
        -- so clamp here rather than trust the input.
        if interval and interval < 2 then interval = nil end
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

    -- A line's own [SAY]/[YELL]/[EMOTE]/[PARTY]/[RAID] tag wins over the skill's normal
    -- chat type, with the same availability downgrade GetChatType applies above
    -- (Say/Yell need a real hardware event to send at all -- falls back to Emote
    -- instead of silently never sending if "instant" delivery is selected and that
    -- library isn't available).
    local effectiveChatType = chatType
    if lineChatType then
        effectiveChatType = lineChatType
        if (effectiveChatType == "SAY" or effectiveChatType == "YELL") and not SayYellAvailable() then
            effectiveChatType = "EMOTE"
        end
    end

    -- "Group Success": same dynamic party-or-raid auto-channel as "Group Start"
    -- (GROUP_ANNOUNCE/AnnounceGroupCast), but resolved here at send time since this
    -- type fires on cast success through the normal cooldown/gate rules above instead
    -- of bypassing them. Falls back to Emote when there's no group to send to at all.
    if effectiveChatType == "GROUP_SUCCESS" then
        if IsInRaid() then
            effectiveChatType = "RAID"
        elseif IsInGroup() then
            effectiveChatType = "PARTY"
        else
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
        if (effectiveChatType == "SAY" or effectiveChatType == "YELL") and SayYellAvailable() then
            -- Say/Yell need a real hardware event to send at all (see GetChatType
            -- above) -- routed to whichever delivery mechanism is selected.
            if GabbaRPCharDB.rp.sayYellDelivery == "instant" then
                MessageQueue.SendChatMessage(line, effectiveChatType)
            else
                ns.GabbaRP_QueueSayYell(line, effectiveChatType)
            end
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
local function AnnounceGroupCast(spellName, targetName)
    local db = GabbaRPCharDB.rp
    if not db.enabled then return end
    if GetChatType(spellName) ~= "GROUP_ANNOUNCE" then return end

    local lines = GetLines(spellName)
    if not lines or #lines == 0 then
        TDebug(spellName, "AnnounceGroupCast: no lines configured")
        return
    end
    if db.disabledSpells[spellName] then
        TDebug(spellName, "AnnounceGroupCast: skill disabled")
        return
    end

    -- Shares customSkipGate/customInterval/castCount/lastTrigger with TriggerLine's own
    -- gate below instead of keeping a separate dedicated cooldown table -- GROUP_ANNOUNCE
    -- skips by default (ns.GabbaRP_DefaultSkipGate), same "always sent" behavior as
    -- before, but now a user CAN throttle a specific Announce-type spell via the line
    -- editor if they want to (e.g. Ritual of Summoning feeling too chatty), which was
    -- never possible while this was a hardcoded, non-overridable bypass.
    local skipGate = ns.GabbaRP_DefaultSkipGate(spellName, "GROUP_ANNOUNCE")
    if db.customSkipGate[spellName] ~= nil then
        skipGate = db.customSkipGate[spellName]
    end
    if not skipGate then
        local interval = db.customInterval[spellName]
        if interval and interval < 2 then interval = nil end
        if interval then
            castCount[spellName] = (castCount[spellName] or 0) + 1
            if castCount[spellName] % interval ~= 1 then
                TDebug(spellName, string.format("AnnounceGroupCast: waiting for interval (cast %d, every %dth)", castCount[spellName], interval))
                return
            end
        else
            local now = GetTime()
            local perSkillCooldown = db.perSkillCooldown or ns.GRP_DEFAULT_PER_SKILL_COOLDOWN
            if lastTrigger[spellName] and (now - lastTrigger[spellName]) < perSkillCooldown then
                TDebug(spellName, "AnnounceGroupCast: per-skill cooldown active")
                return
            end
            lastTrigger[spellName] = now
        end
    end

    local chatType
    if IsInRaid() then
        chatType = "RAID"
    elseif IsInGroup() then
        chatType = "PARTY"
    elseif spellName == "Create Soulstone" or spellName == "Create Soulstone (LOCAL)" then
        -- Soulstones are routinely made solo (unlike Ritual of Summoning or a Portal,
        -- which only make sense with a group to summon/port into) -- narrate it
        -- locally via emote instead of just going silent like other GROUP_ANNOUNCE
        -- spells do when there's no group to announce to.
        chatType = "EMOTE"
    end
    if not chatType then
        TDebug(spellName, "AnnounceGroupCast: not in a group, nothing to announce to")
        return
    end

    TDebug(spellName, "AnnounceGroupCast: fired (" .. chatType .. ")")
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
            TriggerLine(ResolveSpellKey("Death: Guild", lang), name, lastWords)
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
    text = "|cffffd200GabbaRP|r\n\n|cffff8800Heads up:|r you have a skill set to Say/Yell chat, and \"Instant\" Say/Yell delivery selected in Settings.\n\nSending a Say/Yell message this way needs a real click or keypress, so it's queued and sent on your very next one. For mouse players, that means one click (e.g. your next action bar press) gets eaten by this instead of doing what you clicked.\n\nSwitch Say/Yell delivery to \"Safe\" in Settings to stop this (small delay instead, never eats a click), or switch the skill to Emote in the editor.",
    button1 = "Got it",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Warns once per login (as a popup, not a chat line that's easy to miss/scroll past) if
-- the "Instant" Say/Yell delivery mode (Libs/MessageQueue.lua) is actually going to
-- matter for this character right now -- i.e. at least one of their own class's
-- enabled skills currently resolves to Say or Yell AND "Instant" is the selected
-- delivery mode. That mode needs a real click/keypress to legally send a chat message
-- Blizzard didn't originate from one, so it grabs the player's very next click/keypress
-- ANYWHERE on screen to use as that trigger -- for a mouse player, that means one click
-- that was meant for something else (like the next action bar button) gets eaten
-- instead. The default "Safe" delivery mode (SayYellQueue.lua) never eats a click, so
-- this warning is skipped entirely while that's selected. Also silent when nothing's
-- actually configured for Say/Yell, since neither mode runs unless a Say/Yell line can
-- fire.
local function WarnIfSayYellConfigured()
    local db = GabbaRPCharDB.rp
    if db.sayYellDelivery ~= "instant" then return end
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
                    -- The legacy `inGuild` positional argument is only ever populated for
                    -- peer-corroborated deaths (DeathNotificationLib~Cache.lua only sets it
                    -- inside its "not auto_commit" branch) -- for a self-reported death
                    -- (auto_commit = true, the common case: the dying player's own client
                    -- reports it), inGuild stays nil even for an actual guildmate, and this
                    -- reaction would silently never fire. PassesGuildFilterMode does a live
                    -- check against playerData instead of trusting that stale flag, and is
                    -- the library's own newer, documented-as-more-robust API for exactly
                    -- this -- confirmed live: a same-guild, self-reported Hardcore death
                    -- didn't trigger Death: Guild until this was added. Falls back to the
                    -- old inGuild flag if an older DeathNotificationLib version is running.
                    local isGuildmate = inGuild
                    if DeathNotificationLib.PassesGuildFilterMode then
                        isGuildmate = DeathNotificationLib.PassesGuildFilterMode(playerData, "guild_only")
                    end
                    if isGuildmate and playerData and playerData.name then
                        -- Always the local language when the master switch is on, unconditionally
                        -- otherwise -- this goes to GUILD chat, whose audience is the guild by
                        -- definition, so there's no group composition to measure (the person who
                        -- died may not even be in your party/raid).
                        local lang = GabbaRPCharDB.rp.localLanguageEnabled and "local" or "en"
                        TriggerLine(ResolveSpellKey("Death: Guild", lang), playerData.name, playerData.last_words)
                    end
                end)
                if not ok then
                    ns.GabbaRP_Print("|cffff4444Error in DeathNotificationLib callback:|r " .. tostring(err))
                end
            end)
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subevent, _, sourceGUID, _, _, _, destGUID, destName, _, _, _, spellName = CombatLogGetCurrentEventInfo()
        -- Raw diagnostic: every combat-log event sourced from the player, regardless of
        -- subevent or whether anything below actually reacts to it -- for tracking down
        -- "what actually fires" cases like an item's Use: effect (e.g. applying a
        -- Soulstone to a target), which might not be a plain SPELL_CAST_SUCCESS the
        -- normal dispatch below expects.
        if sourceGUID == playerGUID and GabbaRPCharDB.rp.triggerDebugLog then
            TDebug(spellName or "?", "raw combat log event: subevent=" .. tostring(subevent) .. " dest=" .. tostring(destName))
        end
        if subevent == "SPELL_CAST_SUCCESS" and sourceGUID == playerGUID then
            -- GROUP_ANNOUNCE spells (Ritual of Summoning, Portals) are handled entirely
            -- by AnnounceGroupCast on cast start instead -- including the solo case,
            -- see its own EMOTE fallback. TriggerLine self-guards against calling it
            -- again here (GetChatType(spellName) == "GROUP_ANNOUNCE"), so this is a
            -- plain, unconditional dispatch for every other spell. RANK_ALIASES covers
            -- spells that share one line pool/config under a different rank/related
            -- name (Demon Skin, Detect Greater Invisibility, and Soulstone Resurrection
            -- -- the item-use cast that actually applies "Create Soulstone"'s lines,
            -- since casting Create Soulstone itself only conjures the item).
            spellName = RANK_ALIASES[spellName] or spellName
            TriggerLine(ResolveSpellKey(spellName, ns.GabbaRP_GetGroupLanguage()), destName)
            TryTargetWhisperReaction(spellName, destGUID, destName)
        elseif subevent == "SPELL_AURA_APPLIED" and destGUID == playerGUID and sourceGUID == playerGUID and not justZoned then
            -- for buff procs like Nightfall/"Shadow Trance" that aren't a cast of your own --
            -- sourceGUID must ALSO be the player, not just destGUID, otherwise this fires
            -- whenever anyone else's buff lands on you (e.g. another priest's Power Word:
            -- Shield/Fortitude), reacting as if you had cast it yourself. justZoned skips the
            -- zone-transition aura resync artifact described above.
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
    elseif event == "PLAYER_ENTERING_WORLD" then
        justZoned = true
        C_Timer.After(2, function() justZoned = false end)
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            CheckFoodDrink()
        end
    elseif event == "UNIT_SPELLCAST_START" then
        local unit, _, spellID = ...
        if unit == "player" then
            local spellName = GetSpellInfo(spellID)
            -- Deliberately NOT reacting to any "Create Soulstone" rank here anymore --
            -- that cast only CONJURES the item into your bags, with no target involved
            -- yet (the %t in these lines wouldn't even mean anything at this point).
            -- The actual "giving" moment -- and the only place %t makes sense -- is
            -- when the conjured Soulstone item gets USED on someone: a real, multi-
            -- second cast (confirmed live -- "begins casting Soulstone Resurrection" in
            -- the default combat log), so it needs the same RANK_ALIASES normalization
            -- applied here as the COMBAT_LOG_EVENT_UNFILTERED handler below does, or a
            -- "Group Start" chatType override on "Create Soulstone" would never
            -- actually fire for it.
            if spellName and not spellName:find("^Create Soulstone%f[%A]") then
                spellName = RANK_ALIASES[spellName] or spellName
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
