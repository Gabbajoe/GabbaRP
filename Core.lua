-- Minimal standalone init for the extracted RP module: its own SavedVariablesPerCharacter,
-- print prefix, and slash command. Forked from the private Gabba addon's Core.lua (see
-- that file for the ApplyDefaults pattern this mirrors) -- only the rp/greetings slice of
-- its CHAR_DB_DEFAULTS is needed here, since that's all this addon does.

local ADDON_NAME, ns = ...

if math.randomseed then
    math.randomseed(GetTime() * 1000)
else
    for _ = 1, (math.floor(GetTime() * 1000) % 100) + 1 do
        math.random()
    end
end

local GABBARP_PREFIX = "|cffff8800GabbaRP:|r "

function ns.GabbaRP_Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(GABBARP_PREFIX .. msg)
end

-- Persisted debug trail, written to disk on every /reload/logout the same as any other
-- SavedVariable -- lets debug output be inspected directly from the saved GabbaRP.lua file
-- afterwards instead of requiring a chat-log copy-paste (handy when troubleshooting for
-- someone else's character, e.g. via /gabbarp report). Capped so a long play session
-- doesn't grow this forever; oldest entries drop first.
local DEBUG_LOG_MAX = 300
function ns.GabbaRP_DebugLog(tag, msg)
    local log = GabbaRPCharDB.debugLog
    table.insert(log, { time = date("%Y-%m-%d %H:%M:%S"), tag = tag, msg = msg })
    while #log > DEBUG_LOG_MAX do
        table.remove(log, 1)
    end
end

-- Single source of truth for the RP module's spam-protection defaults -- referenced here
-- AND by RP_Options.lua's slider resets/display fallbacks, instead of repeating each
-- literal in several places that would all need updating together. NOT used for
-- RP_Core.lua's own defensive fallbacks (PassesGlobalGate's "or 0", the chance check's
-- implicit always-pass-when-nil) -- those are a deliberately more permissive safety net
-- for the DB-not-initialized-yet edge case, not "what the shipped default is", so they
-- stay their own literals rather than reusing these.
ns.GRP_DEFAULT_PER_SKILL_COOLDOWN = 8
ns.GRP_DEFAULT_GLOBAL_COOLDOWN = 15
ns.GRP_DEFAULT_TRIGGER_CHANCE = 35

local CHAR_DB_DEFAULTS = {
    -- See ns.GabbaRP_DebugLog above -- a rolling, on-disk trail for troubleshooting
    -- without needing a chat-log copy-paste.
    debugLog = {},
    -- Which "what's new" changelog entry (RP_Options.lua's CHANGELOG_VERSION) this
    -- character has last acknowledged -- see ns.GabbaRP_ShowChangelogIfNeeded. Brand-new
    -- characters get this stamped to the current version immediately in
    -- GabbaRP_EnsureDefaults below (nothing to "catch up" on), so 0 here only ever
    -- applies to a character that existed before this field did.
    lastSeenChangelogVersion = 0,
    rp = {
        enabled = true,
        mode = "self", -- "self" | "public" | "both"
        anim = true,
        disabledSpells = {},
        -- Minimum gap between two lines for the SAME skill (skills with a
        -- ns.GRP_SpellInterval entry in RP_Data.lua, e.g. Life Tap, use "only every Nth
        -- cast" instead and ignore this).
        perSkillCooldown = ns.GRP_DEFAULT_PER_SKILL_COOLDOWN, -- seconds
        globalCooldown = ns.GRP_DEFAULT_GLOBAL_COOLDOWN, -- seconds, minimum gap between any two lines
        triggerChance = ns.GRP_DEFAULT_TRIGGER_CHANCE, -- percent chance a line actually fires once eligible
        customLines = {},
        customChatType = {},
        -- How Say/Yell reactions actually get sent -- Blizzard requires a real
        -- click/keypress for those, which a spell cast (or any other automatic
        -- trigger) never is. "safe" (default): hooks the functions real game actions
        -- go through (UseAction/CastSpellByName/CastSpellByID/UseInventoryItem) and
        -- piggybacks on the next one -- hooksecurefunc can't cancel/replace what it
        -- hooks, so nothing is ever lost, just possibly a beat slower than "instant".
        -- "instant": the old SayYellQueue.lua predecessor (Libs/MessageQueue.lua)
        -- behavior -- captures the player's literal next hardware input anywhere on
        -- screen for near-zero delay, but that input's own action doesn't happen.
        sayYellDelivery = "safe", -- "safe" | "instant"
        -- Per-spell overrides for the "spammy vs. never-throttle" gate (RP_Core.lua's
        -- PassesGlobalGate/bypassesGlobalGate check), editable via the line editor.
        -- customSkipGate[name] = true/false always wins over ns.GRP_SkipGlobalGate's
        -- code default once set (nil = not touched, defers to the code default).
        -- customInterval[name] = a number overrides ns.GRP_SpellInterval's code default
        -- ("every Nth cast" instead of the normal cooldown); nil defers to the code
        -- default. There's deliberately no way to override an existing code-default
        -- interval back OFF via this table alone -- customSkipGate covers "never
        -- throttle this" already, and that's the only override direction actually
        -- requested.
        customSkipGate = {},
        customInterval = {},
        -- If a guildmate who dies is also in your current party/raid, guild chat (via
        -- DeathNotificationLib, a few seconds later) will already cover it -- skip the
        -- immediate "Death: Group"/"Death: Raid" reaction so the same death isn't
        -- announced twice. On by default; uncheck to always get the group/raid reaction
        -- regardless.
        suppressGroupRaidIfGuild = true,
        -- Off by default -- noisy, prints on every nearby monster Say/Yell (not just your
        -- own Imp's), meant only for troubleshooting "Imp Backtalk doesn't fire" reports.
        -- /gabbarp impdebug on|off.
        impDebugLog = false,
        -- Off by default -- writes each LOCAL/EN language decision (join/welcome
        -- greetings) to the persisted debug log, meant for troubleshooting "local
        -- language greeting doesn't fire" reports. /gabbarp greetdebug on|off.
        greetDebugLog = false,
        -- Off by default -- writes why each skill cast did or didn't produce a line
        -- (disabled, per-skill cooldown, global spam gate, chance roll, no lines) to the
        -- persisted debug log, meant for troubleshooting "this skill never comments"
        -- reports. /gabbarp triggerdebug on|off.
        triggerDebugLog = false,
        -- Master switch for the whole local-language (LOCAL) system -- off means
        -- everything is said in English only, ignoring group/guild composition and
        -- soloLanguage entirely. Default OFF here (unlike the private Gabba addon): this
        -- addon ships English-only, and local-language content is something each user
        -- opts into and fills in themselves (via the line editor) rather than something
        -- shipped pre-translated for a guild that might not even speak German.
        localLanguageEnabled = false,
        -- Language used when NOT in a group (no group composition to measure against).
        -- Grouped play instead picks local/English based on how much of the group
        -- shares your guild -- see ns.GabbaRP_GetGroupLanguage in RP_Core.lua. "en" | "local".
        soloLanguage = "en",
    },
    greetings = {
        enabled = true,
        -- Per-category-per-time-of-day overrides of ns.GRP_GreetingLines (RP_Greeting.lua).
        -- customLines[category][timeOfDay], when present, is the COMPLETE line list for
        -- that slot. category is "join" or "welcome"; timeOfDay is
        -- "morning"/"midday"/"evening"/"night".
        customLines = {},
        -- Same shape as customLines above, but overriding the local-language defaults
        -- (ns.GRP_GreetingLines_Local) instead of the English ones.
        customLinesLocal = {},
    },
}

local function ApplyDefaults(tbl, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            tbl[k] = tbl[k] or {}
            ApplyDefaults(tbl[k], v)
        elseif tbl[k] == nil then
            tbl[k] = v
        end
    end
end

-- Data-schema version for GabbaRPCharDB, separate from the addon's ## Version in the .toc
-- (that one's for humans/changelogs; this one drives the migration system below and only
-- moves when a SavedVariables structure actually changes -- a key gets renamed, data moves
-- between tables, etc.). To ship a migration: add the next MIGRATIONS[N] entry and bump
-- this constant to N. Each numbered step runs in order for any character behind the
-- current version, so it doesn't matter how many versions behind a given character (or a
-- friend's own copy of this addon) is -- every migration it missed replays in sequence on
-- next load. Old steps are safe to leave here indefinitely; they're cheap and only run for
-- characters that still need them.
local CHAR_SCHEMA_VERSION = 4

local MIGRATIONS = {
    -- The static "Party"/"Raid" chat-type buttons were removed from the line editor --
    -- both dynamic "Group Start"/"Group Success" types auto-pick whichever you're
    -- actually in, covering what a static choice used to be for. Any per-character
    -- override that was still literally "PARTY"/"RAID" would otherwise keep working
    -- exactly as before (SendChatMessage still accepts those strings) but could no
    -- longer be RE-selected from the UI -- remapped to the closest equivalent instead
    -- of leaving it as an orphaned, no-longer-visible choice.
    [2] = function(db)
        for spellName, chatType in pairs(db.rp.customChatType) do
            if chatType == "PARTY" or chatType == "RAID" then
                db.rp.customChatType[spellName] = "GROUP_SUCCESS"
            end
        end
    end,
    [3] = function(db)
        -- "Create Soulstone" no longer reacts on its own cast (that only conjures the
        -- item -- see RP_Core.lua's UNIT_SPELLCAST_START handler) -- it now fires when
        -- the conjured item is actually USED on someone ("Soulstone Resurrection",
        -- aliased to this same stored key). That's a normal cast-success moment, not a
        -- multi-second cast worth a cast-start pre-warning, so a "Group Start"
        -- (GROUP_ANNOUNCE) override -- which is ONLY ever fired from cast-start -- would
        -- now go completely silent instead. Remapped to "Group Success" (cast-success,
        -- same dynamic Party/Raid auto-channel), which is what this spell actually needs.
        if db.rp and db.rp.customChatType and db.rp.customChatType["Create Soulstone"] == "GROUP_ANNOUNCE" then
            db.rp.customChatType["Create Soulstone"] = "GROUP_SUCCESS"
        end
    end,
    [4] = function(db)
        -- Same as migration [3] above, but for the local-language mirror key -- missed
        -- the first time around. Confirmed live: a character whose group-language
        -- resolved to "local" for a Soulstone cast hit exactly this unmigrated key and
        -- went silent the same way the English one would have.
        if db.rp and db.rp.customChatType and db.rp.customChatType["Create Soulstone (LOCAL)"] == "GROUP_ANNOUNCE" then
            db.rp.customChatType["Create Soulstone (LOCAL)"] = "GROUP_SUCCESS"
        end
    end,
}

local function RunMigrations(db, isNewCharacter)
    if isNewCharacter then
        -- Never had any data to migrate -- ApplyDefaults above already gave it the
        -- current shape directly, so just stamp it current instead of replaying old
        -- steps against empty tables.
        db.schemaVersion = CHAR_SCHEMA_VERSION
        return
    end
    local startingVersion = db.schemaVersion or 0
    local v = startingVersion
    while v < CHAR_SCHEMA_VERSION do
        v = v + 1
        if MIGRATIONS[v] then MIGRATIONS[v](db) end
    end
    db.schemaVersion = CHAR_SCHEMA_VERSION
    -- One short, generic heads-up when at least one migration actually ran -- no
    -- per-step detail (these are silent, deterministic data changes with no
    -- interesting success/failure state), just visibility that something changed in
    -- the background after an addon update.
    if startingVersion < CHAR_SCHEMA_VERSION then
        ns.GabbaRP_Print("Some settings were automatically updated for this version. /gabbarp report if anything looks off.")
    end
end

local function GabbaRP_EnsureDefaults()
    local isNewCharacter = GabbaRPCharDB == nil
    GabbaRPCharDB = GabbaRPCharDB or {}
    ApplyDefaults(GabbaRPCharDB, CHAR_DB_DEFAULTS)
    RunMigrations(GabbaRPCharDB, isNewCharacter)
    if isNewCharacter then
        -- ns.GabbaRP_CHANGELOG_VERSION is set by RP_Options.lua, loaded after this file --
        -- safe to read here since this whole function only ever runs from ADDON_LOADED,
        -- by which point every file has finished loading.
        GabbaRPCharDB.lastSeenChangelogVersion = ns.GabbaRP_CHANGELOG_VERSION or 0
    end
end

-- GetAddOnMetadata was moved under C_AddOns in a later client than this one still ships,
-- but Blizzard has a track record of eventually removing the old global elsewhere (see the
-- IsAddOnLoaded/GetSpellInfo shims in RP_Core.lua) -- shimmed the same defensive way.
local GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata

-- /gabbarp report -- a copy-pasteable diagnostic summary for bug reports. Printed as
-- several separate chat lines (not one long string) so it's easy to drag-select in the
-- chat frame; whoever's reporting can paste this plus, if a relevant *debug flag was on,
-- the tail of /gabbarp debuglog.
function ns.GabbaRP_PrintReport()
    local db = GabbaRPCharDB.rp
    local version = GetAddOnMetadata and GetAddOnMetadata("GabbaRP", "Version") or "?"
    local clientVersion, clientBuild, _, tocVersion = GetBuildInfo()
    local name, realm = UnitName("player")
    realm = realm ~= "" and realm or GetRealmName()
    local _, className = UnitClass("player")

    ns.GabbaRP_Print("=== GabbaRP Report (copy/paste this) ===")
    ns.GabbaRP_Print(string.format("Addon: v%s (schema %d)", tostring(version), GabbaRPCharDB.schemaVersion or 0))
    ns.GabbaRP_Print(string.format("Client: %s (build %s, interface %s)", tostring(clientVersion), tostring(clientBuild), tostring(tocVersion)))
    ns.GabbaRP_Print(string.format("Character: %s-%s, %s", tostring(name), tostring(realm), tostring(className)))
    ns.GabbaRP_Print(string.format("RP: enabled=%s mode=%s anim=%s localLanguage=%s soloLanguage=%s sayYellDelivery=%s",
        tostring(db.enabled), tostring(db.mode), tostring(db.anim), tostring(db.localLanguageEnabled), tostring(db.soloLanguage), tostring(db.sayYellDelivery)))
    ns.GabbaRP_Print(string.format("Spam protection: perSkillCooldown=%ds globalCooldown=%ds triggerChance=%s%%",
        db.perSkillCooldown or 0, db.globalCooldown or 0, tostring(db.triggerChance)))
    ns.GabbaRP_Print(string.format("Debug flags: impdebug=%s greetdebug=%s triggerdebug=%s (%d log entries stored)",
        tostring(db.impDebugLog), tostring(db.greetDebugLog), tostring(db.triggerDebugLog), #GabbaRPCharDB.debugLog))
    ns.GabbaRP_Print("=== end report ===")
end

local shownChangelogThisSession = false

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == "GabbaRP" then
        GabbaRP_EnsureDefaults()
        ns.GabbaRP_Print("Loaded. Type /gabbarp for commands.")
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Not PLAYER_LOGIN: Blizzard's own UI code closes every UISpecialFrames-registered
        -- frame (which the changelog popup is, so Escape can dismiss it) as part of its
        -- loading-screen-transition cleanup right around PLAYER_ENTERING_WORLD. Showing the
        -- popup at PLAYER_LOGIN (which fires slightly earlier) meant it got shown and then
        -- immediately closed again by that cleanup before the player ever saw it. A short
        -- delay after PLAYER_ENTERING_WORLD dodges that race. Guarded to only ever fire
        -- once per session -- this event also fires on every zone change/instance entry.
        if not shownChangelogThisSession then
            shownChangelogThisSession = true
            C_Timer.After(2, function()
                if ns.GabbaRP_ShowChangelogIfNeeded then
                    ns.GabbaRP_ShowChangelogIfNeeded()
                end
            end)
        end
    end
end)

local function SlashHandler(msg)
    if ns.GabbaRP_HandleCommand then
        ns.GabbaRP_HandleCommand(msg)
    end
end

SLASH_GABBARP1 = "/gabbarp"
SlashCmdList["GABBARP"] = SlashHandler
