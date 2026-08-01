-- Generates docs/data.json for the Line Pack Builder web tool directly from the addon's
-- own source files (RP_Data.lua, RP_Greeting.lua), so the web tool can never drift out of
-- sync with what's actually shipped in-game the way the old hand-copied version did.
--
-- Usage (from the repo root, this file's own grandparent directory):
--   lua tools/generate-linepack-data.lua > docs/data.json
--
-- Loads the real .lua files as plain data (they only assign to a local `ns` table passed in
-- via the addon vararg convention, no WoW API calls happen at load time), then serializes
-- exactly the tables the web tool needs.

local SRC = "" -- RP_Data.lua/RP_Greeting.lua are siblings of tools/ at the repo root

-- RP_Greeting.lua (and potentially other addon files) call real WoW API functions
-- (CreateFrame, RegisterEvent, ...) at file scope, not just inside function bodies -- these
-- need SOMETHING to call during loading even though nothing here ever actually invokes the
-- resulting event handlers. A blanket "any undefined global is a chainable no-op" sandbox
-- covers this without having to enumerate every WoW API the addon might reference.
local function makeStub()
    local stub
    stub = setmetatable({}, {
        __index = function() return function() return stub end end,
        __call = function() return stub end,
    })
    return stub
end

local function makeSandboxEnv()
    return setmetatable({}, {
        __index = function() return function() return makeStub() end end,
    })
end

local function loadAddonFile(filename)
    local chunk = assert(loadfile(SRC .. filename, "t", makeSandboxEnv()))
    local ns = {}
    chunk("GabbaRP", ns) -- mimics `local ADDON_NAME, ns = ...` with a fresh ns each time
    return ns
end

local dataNs = loadAddonFile("RP_Data.lua")
local greetingNs = loadAddonFile("RP_Greeting.lua")

-- ---------------------------------------------------------------------
-- Minimal JSON encoder (no external deps -- this only ever needs to handle the plain
-- string/number/array/string-keyed-map shapes these specific tables contain).
-- ---------------------------------------------------------------------

local function encodeString(s)
    local escaped = s:gsub('[%c"\\]', function(c)
        if c == '"' then return '\\"' end
        if c == '\\' then return '\\\\' end
        if c == '\n' then return '\\n' end
        if c == '\t' then return '\\t' end
        if c == '\r' then return '\\r' end
        return string.format('\\u%04x', c:byte())
    end)
    return '"' .. escaped .. '"'
end

local function isArray(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    for i = 1, n do
        if t[i] == nil then return false end
    end
    return n > 0 or next(t) == nil
end

local encodeValue

local function encodeArray(t)
    local parts = {}
    for i = 1, #t do
        parts[i] = encodeValue(t[i])
    end
    return "[" .. table.concat(parts, ",") .. "]"
end

local function encodeObject(t, keyOrder)
    local parts = {}
    local keys = keyOrder
    if not keys then
        keys = {}
        for k in pairs(t) do table.insert(keys, k) end
        table.sort(keys)
    end
    for _, k in ipairs(keys) do
        table.insert(parts, encodeString(k) .. ":" .. encodeValue(t[k]))
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

encodeValue = function(v)
    local t = type(v)
    if t == "string" then return encodeString(v) end
    if t == "number" then return tostring(v) end
    if t == "boolean" then return tostring(v) end
    if t == "nil" then return "null" end
    if t == "table" then
        if isArray(v) then return encodeArray(v) end
        return encodeObject(v)
    end
    error("cannot encode type " .. t)
end

-- ---------------------------------------------------------------------
-- Assemble the exact shape the web tool consumes.
-- ---------------------------------------------------------------------

local EXCLUDE_FROM_CLASS_LIST = {
    ["Food"] = true, ["Drink"] = true, ["Food and Drink"] = true,
    ["Death: Group"] = true, ["Death: Raid"] = true, ["Death: Guild"] = true,
}

-- spellClass: only base (non-LOCAL) keys, skip the universal Food/Drink/Death entries
-- (handled as their own dedicated sections client-side, same split the addon itself uses).
local spellClass = {}
for name, class in pairs(dataNs.GRP_SpellClass) do
    if not name:match(" %(LOCAL%)$") and not EXCLUDE_FROM_CLASS_LIST[name] then
        spellClass[name] = class
    end
end

-- spells: base English line pools for every key that has one (class skills + universal).
local spells = {}
for name, lines in pairs(dataNs.GRP_Spells) do
    if not name:match(" %(LOCAL%)$") then
        spells[name] = lines
    end
end

-- spellsLocal: whatever (LOCAL) content actually exists today (ships empty for everything
-- except the two whisper dummy entries) -- keyed WITHOUT the suffix, so the web tool can
-- look up `spellsLocal[name]` directly next to `spells[name]`.
local spellsLocal = {}
for name, lines in pairs(dataNs.GRP_Spells) do
    local base = name:match("^(.+) %(LOCAL%)$")
    if base then
        spellsLocal[base] = lines
    end
end

local chatType = {}
for name, ct in pairs(dataNs.GRP_SpellChatType) do
    if not name:match(" %(LOCAL%)$") then
        chatType[name] = ct
    end
end
local chatTypeLocal = {}
for name, ct in pairs(dataNs.GRP_SpellChatType) do
    local base = name:match("^(.+) %(LOCAL%)$")
    if base then
        chatTypeLocal[base] = ct
    end
end

local deathReactions = {}
local deathReactionsLocal = {}
for _, name in ipairs({ "Death: Group", "Death: Raid", "Death: Guild" }) do
    deathReactions[name] = dataNs.GRP_Spells[name] or {}
    deathReactionsLocal[name] = dataNs.GRP_Spells[name .. " (LOCAL)"] or {}
end

local food = {}
local foodLocal = {}
for _, name in ipairs({ "Food", "Drink", "Food and Drink" }) do
    food[name] = dataNs.GRP_Spells[name] or {}
    foodLocal[name] = dataNs.GRP_Spells[name .. " (LOCAL)"] or {}
end

local greetings = greetingNs.GRP_GreetingLines
local greetingsLocal = greetingNs.GRP_GreetingLines_Local

local output = {
    spellClass = spellClass,
    spells = spells,
    spellsLocal = spellsLocal,
    chatType = chatType,
    chatTypeLocal = chatTypeLocal,
    deathReactions = deathReactions,
    deathReactionsLocal = deathReactionsLocal,
    food = food,
    foodLocal = foodLocal,
    greetings = greetings,
    greetingsLocal = greetingsLocal,
}

print(encodeValue(output))
