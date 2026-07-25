-- Registers the RP settings as a native Blizzard Options > AddOns category -- this
-- addon's ONLY settings surface (no custom window), per design: ns.GabbaRP_BuildGeneralPanel/
-- ns.GabbaRP_BuildSkillsPanel build the content. The class-skill list gets its own indented
-- sub-entry under the main category (same tree pattern the installed addon GatherMate 2
-- uses for its Minimap/Filters/etc. children), via Settings.RegisterCanvasLayoutSubcategory
-- -- verified against GatherMate2/SimpleItemLevel/KBigDebuffs's real (AceConfigDialog-
-- generated) calls: the parent argument must be the CATEGORY OBJECT returned by
-- RegisterCanvasLayoutCategory, not a string/ID.

local ADDON_NAME, ns = ...

local function ShowPanel(host, panel)
    panel.frame:SetAllPoints(host)
    -- The panel factories hide their frame by default (it's normally a tab shown on
    -- selection) -- here `host`'s own shown state (driven by Blizzard's settings UI) is
    -- what should control visibility instead, so undo that default hide once.
    panel.frame:Show()
    host:SetScript("OnShow", panel.refresh)
    -- A freshly created frame is already in the "shown" state by default, so the very
    -- first time Blizzard's Settings UI displays this category, OnShow never actually
    -- fires (no hidden->shown transition to trigger it) -- content stayed empty until a
    -- second visit. Refreshing once immediately here covers that first display too.
    panel.refresh()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    local host = CreateFrame("Frame", "GRPBlizzardPanel", UIParent)
    host.name = "GabbaRP"
    ShowPanel(host, ns.GabbaRP_BuildGeneralPanel(host))

    local category = Settings.RegisterCanvasLayoutCategory(host, host.name)
    Settings.RegisterAddOnCategory(category)

    local className = UnitClass("player")

    local skillsHost = CreateFrame("Frame", "GRPSkillsBlizzardPanel", UIParent)
    ShowPanel(skillsHost, ns.GabbaRP_BuildSkillsPanel(skillsHost, "en"))
    Settings.RegisterCanvasLayoutSubcategory(category, skillsHost, className .. " Skills (EN)")

    local skillsHostLocal = CreateFrame("Frame", "GRPSkillsLocalBlizzardPanel", UIParent)
    ShowPanel(skillsHostLocal, ns.GabbaRP_BuildSkillsPanel(skillsHostLocal, "local"))
    Settings.RegisterCanvasLayoutSubcategory(category, skillsHostLocal, className .. " Skills (LOCAL)")
end)
