-- Builds the RP settings content shown in the Blizzard-native Options > AddOns panel
-- (see RP_BlizzardOptions.lua): ns.GabbaRP_BuildGeneralPanel(parent) for everything except
-- the class-skill list, and ns.GabbaRP_BuildSkillsPanel(parent, lang) for that list on its
-- own (registered as two sibling subcategories, one per language -- see
-- RP_BlizzardOptions.lua). Forked from the private Gabba addon's RP_Options.lua -- same
-- editor/settings logic, but self-contained (no dependency on that addon's shared
-- Options.lua window or its Gabba_NewCheckbox/Gabba_NewTabStrip helpers, which don't
-- exist here), and every global identifier renamed so this addon can coexist on the same
-- client as the private one without either clobbering the other's globals.

local ADDON_NAME, ns = ...

local checkboxCounter = 0
local function GabbaRP_NewCheckbox(parent, label)
    checkboxCounter = checkboxCounter + 1
    local name = "GRPCheckbox" .. checkboxCounter
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24) -- template defaults to 32x32, which overlapped tight row spacing
    local text = _G[name .. "Text"]
    if text then
        text:SetText(label)
    end
    cb.text = text
    return cb
end

-- A horizontal row of button "tabs" -- an exclusive selector where exactly one is active
-- at a time, shown pushed-in AND with its background lit (LockHighlight) so the active
-- one is unambiguous at a glance. Deliberately plain UIPanelButtonTemplate buttons (this
-- addon's look everywhere else) rather than Blizzard's PanelTabButtonTemplate art.
-- tabs: { {key=, label=, short=(optional, preferred for the button text if present),
-- width=(optional, default 70)}, ... }. onSelect(key) fires on click. Returns the tab
-- entries ({key=,btn=}); entries[1].btn is NOT anchored -- the caller positions it
-- (SetPoint) right after this call, tabs 2+ chain off it automatically.
local function GabbaRP_NewTabStrip(parent, tabs, onSelect)
    local entries = {}
    local prevBtn
    for _, tab in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        btn:SetSize(tab.width or 70, 22)
        if prevBtn then
            btn:SetPoint("LEFT", prevBtn, "RIGHT", 2, 0)
        end
        btn:SetText(tab.short or tab.label)
        btn:SetScript("OnClick", function() onSelect(tab.key) end)
        table.insert(entries, { key = tab.key, btn = btn })
        prevBtn = btn
    end
    return entries
end

local function GabbaRP_SyncTabStrip(entries, activeKey)
    for _, entry in ipairs(entries) do
        local active = entry.key == activeKey
        entry.btn:SetButtonState(active and "PUSHED" or "NORMAL", active)
        if active then
            entry.btn:LockHighlight()
        else
            entry.btn:UnlockHighlight()
        end
    end
end

local MODES = {
    { key = "self", label = "Only me (self)" },
    { key = "public", label = "Public" },
    { key = "both", label = "Both" },
}

-- Only relevant when NOT in a group -- grouped play instead picks Local/English
-- automatically based on how much of the group shares your guild (ns.GabbaRP_GetGroupLanguage,
-- RP_Core.lua).
local SOLO_LANGUAGES = {
    { key = "en", label = "English" },
    { key = "local", label = "Local Language" },
}

-- Say/Yell need a real hardware event to send (Blizzard requirement since 8.2.5/Classic
-- 1.13.3) -- Libs/MessageQueue.lua works around that by queueing the message and flushing
-- it on the player's next actual click/keypress. See GetChatType()/TriggerLine() in
-- RP_Core.lua.
-- "label" is the full description shown in the editor (below the tab row, for whichever
-- tab is currently selected); "short"/"width" size the tab button itself.
-- No standalone "Party"/"Raid" entries -- both dynamic Group types below auto-pick
-- whichever you're actually in, which covers what a static Party/Raid choice used to
-- be for. A specific LINE can still be forced to a fixed Party/Raid channel via the
-- "[PARTY]"/"[RAID]" per-line tag (ExtractLineChatTypeOverride, RP_Core.lua) if that's
-- ever genuinely needed.
local CHAT_TYPES = {
    { key = "EMOTE", short = "Emote", width = 60, label = "Emote (/me), third person, e.g. \"casts a shadow bolt\"" },
    { key = "SAY", short = "Say", width = 44, label = "Say" },
    { key = "YELL", short = "Yell", width = 44, label = "Yell" },
    { key = "GUILD", short = "Guild", width = 50, label = "Guild" },
    { key = "GROUP_ANNOUNCE", short = "Group Start", width = 90, label = "Party or Raid chat (whichever you're in), right when the cast starts. Always sent, ignores cooldown/gate." },
    { key = "GROUP_SUCCESS", short = "Group Success", width = 100, label = "Party or Raid chat (whichever you're in), once the cast succeeds. Normal cooldown/gate rules apply." },
}

local GREETING_TIME_SLOTS = {
    { key = "morning", label = "Morning", width = 70 },
    { key = "midday", label = "Midday", width = 70 },
    { key = "evening", label = "Evening", width = 70 },
    { key = "night", label = "Night", width = 60 },
}

-- Food/Drink/Food and Drink are "ALL"-class too, but they get their own dedicated rows
-- in the general panel instead of being buried in this per-class scroll list.
local SPELL_LIST_EXCLUDE = {
    ["Food"] = true,
    ["Drink"] = true,
    ["Food and Drink"] = true,
    ["Death: Group"] = true,
    ["Death: Raid"] = true,
    ["Death: Guild"] = true,
    ["Food (LOCAL)"] = true,
    ["Drink (LOCAL)"] = true,
    ["Food and Drink (LOCAL)"] = true,
    ["Death: Group (LOCAL)"] = true,
    ["Death: Raid (LOCAL)"] = true,
    ["Death: Guild (LOCAL)"] = true,
}

-- Whether a spell/reaction key is the local-language variant -- everything added by the
-- bilingual feature is a plain "(LOCAL)"-suffixed sibling key (see ResolveSpellKey,
-- RP_Core.lua), not a separate table, so this is just a name check.
local function IsLocalKey(name)
    return name:match(" %(LOCAL%)$") ~= nil
end

local function TrimText(s)
    return s:match("^%s*(.-)%s*$")
end

local function GetEffectiveLines(spellName)
    return GabbaRPCharDB.rp.customLines[spellName] or ns.GRP_Spells[spellName] or {}
end

local function GetEffectiveChatType(spellName)
    return GabbaRPCharDB.rp.customChatType[spellName] or ns.GRP_SpellChatType[spellName] or "EMOTE"
end

----------------------------------------------------------------------
-- Skill line editor: a single floating popup operating directly on GabbaRPCharDB.rp,
-- opened via the "Edit" button next to a skill/Food/Drink row.
----------------------------------------------------------------------

local editorFrame
-- Forward-declared here (defined below) so ShowLineEditor can close it -- the skill/Food/
-- Death editor and the greeting editor are two independent popups that can otherwise both
-- be open and spawn stacked on each other; opening one now closes the other instead.
local greetingEditorFrame
local editorBaseName -- e.g. "Food", "Death: Group", "Taunt" -- never has a "(LOCAL)" suffix
local editorAllowLanguage -- whether this popup shows the English/Local Language tab row
local editorLang = "en" -- "en" | "local", only meaningful when editorAllowLanguage
local editorSpellName -- computed: editorBaseName, or editorBaseName.." (LOCAL)" when applicable
local editorRows = {}
local editorChatTabs = {}
local editorLangTabs = {}
local editorSavedHideTimer

local function ComputeEditorSpellName()
    if editorAllowLanguage and editorLang == "local" then
        return editorBaseName .. " (LOCAL)"
    end
    return editorBaseName
end

-- Brief "Saved!" confirmation next to the "Lines:" heading -- the only feedback that an
-- edit/add/remove/reset actually took effect, since rows just silently update otherwise.
local function FlashEditorSaved()
    if not editorFrame or not editorFrame.savedText then return end
    editorFrame.savedText:Show()
    if editorSavedHideTimer then editorSavedHideTimer:Cancel() end
    editorSavedHideTimer = C_Timer.NewTimer(1.2, function()
        if editorFrame and editorFrame.savedText then editorFrame.savedText:Hide() end
    end)
end

-- Each row's text is a real EditBox, not a plain label -- click into it to edit that
-- line directly instead of having to delete it and retype the whole thing.
local function RefreshEditorRows()
    local lines = GetEffectiveLines(editorSpellName)
    for i, text in ipairs(lines) do
        local row = editorRows[i]
        if not row then
            row = CreateFrame("Frame", nil, editorFrame.scrollChild)
            row:SetSize(360, 20)

            row.text = CreateFrame("EditBox", nil, row)
            row.text:SetPoint("LEFT", row, "LEFT", 2, 0)
            row.text:SetSize(330, 18)
            row.text:SetAutoFocus(false)
            row.text:SetFontObject("GameFontHighlightSmall")
            row.text:SetJustifyH("LEFT")

            row.removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.removeBtn:SetSize(20, 18)
            row.removeBtn:SetText("X")
            row.removeBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0)

            editorRows[i] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -4 - (i - 1) * 22)
        row.text:SetText(text)
        row.text:SetCursorPosition(0)
        local function SaveEdit(self)
            local newText = TrimText(self:GetText())
            if newText == "" or newText == text then
                self:SetText(text) -- refuse an empty edit, and skip a no-op save
                return
            end
            local current = {}
            for j, l in ipairs(GetEffectiveLines(editorSpellName)) do
                current[j] = (j == i) and newText or l
            end
            GabbaRPCharDB.rp.customLines[editorSpellName] = current
            RefreshEditorRows()
            FlashEditorSaved()
        end
        row.text:SetScript("OnEnterPressed", function(self) SaveEdit(self) self:ClearFocus() end)
        row.text:SetScript("OnEditFocusLost", SaveEdit)
        row.text:SetScript("OnEscapePressed", function(self) self:SetText(text) self:ClearFocus() end)
        row.removeBtn:SetScript("OnClick", function()
            local current = {}
            for j, l in ipairs(GetEffectiveLines(editorSpellName)) do
                if j ~= i then table.insert(current, l) end
            end
            GabbaRPCharDB.rp.customLines[editorSpellName] = current
            RefreshEditorRows()
            FlashEditorSaved()
        end)
        row:Show()
    end
    for i = #lines + 1, #editorRows do
        editorRows[i]:Hide()
    end
    editorFrame.scrollChild:SetHeight(math.max(1, #lines * 22 + 8))
end

local function SyncEditorChatType(chatType)
    GabbaRP_SyncTabStrip(editorChatTabs, chatType)
    for _, ct in ipairs(CHAT_TYPES) do
        if ct.key == chatType then
            editorFrame.chatDesc:SetText(ct.label)
            break
        end
    end
end

local function SelectEditorChatType(chatType)
    GabbaRPCharDB.rp.customChatType[editorSpellName] = chatType
    SyncEditorChatType(chatType)
end

-- Reflects the EFFECTIVE state (override if set, else the code default from
-- RP_Data.lua) into the "Always react"/"React every N casts" controls -- same
-- override-wins-over-default relationship customChatType already has with
-- GRP_SpellChatType, just for the spam-gate instead of the send-as channel.
local function SyncEditorFrequency(spellName)
    local db = GabbaRPCharDB.rp
    -- Same default rule the actual dispatch uses (ns.GabbaRP_DefaultSkipGate,
    -- RP_Core.lua), so this checkbox is never out of sync with what really happens --
    -- e.g. Death/Imp reactions and Group Start spells now correctly show "checked" by
    -- default instead of looking unchecked despite always bypassing the gate.
    local skipGate = ns.GabbaRP_DefaultSkipGate(spellName, GetEffectiveChatType(spellName))
    if db.customSkipGate[spellName] ~= nil then skipGate = db.customSkipGate[spellName] end
    editorFrame.freqAlwaysCB:SetChecked(skipGate and true or false)
    editorFrame.freqIntervalBox:SetEnabled(not skipGate)
    editorFrame.freqIntervalBox:SetText(tostring(db.customInterval[spellName] or ns.GRP_SpellInterval and ns.GRP_SpellInterval[spellName] or ""))
end

local function SelectEditorLang(lang)
    editorLang = lang
    editorSpellName = ComputeEditorSpellName()
    editorFrame.title:SetText(editorSpellName)
    GabbaRP_SyncTabStrip(editorLangTabs, editorLang)
    SyncEditorChatType(GetEffectiveChatType(editorSpellName))
    SyncEditorFrequency(editorSpellName)
    RefreshEditorRows()
end

local function CreateEditorFrame()
    local f = CreateFrame("Frame", "GRPLineEditor", UIParent, "BasicFrameTemplateWithInset")
    -- 540, not 460: this frame is reused for both plain skill popups AND Food/Drink/Death
    -- Reaction popups (allowLanguage=true, which adds the whole Language row above "Send
    -- as:"). 460 had just enough slack for the plain case, but the language row plus the
    -- taller 230px line scroll pushed the Add box below the frame's bottom edge for the
    -- allowLanguage case specifically.
    f:SetSize(420, 540)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("HIGH")
    f:Hide()
    tinsert(UISpecialFrames, "GRPLineEditor")

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", f.TitleBg, "TOP", 0, -5)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 12, -30)
    hint:SetWidth(390)
    hint:SetJustifyH("LEFT")
    hint:SetText("Placeholders: %t = your current target's name, %p = your pet's name. A skill with 0 lines stays silent even when checked.")

    -- Only shown for popups opened with allowLanguage=true (Food/Drink, Death Reactions) --
    -- regular skills already pick English vs Local via separate class-skill panel tabs, so
    -- this row stays hidden and everything below re-anchors up to close the gap.
    local langLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    langLabel:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -12)
    langLabel:SetText("Language:")

    editorLangTabs = GabbaRP_NewTabStrip(f, {
        { key = "en", label = "English", width = 80 },
        { key = "local", label = "Local Language", width = 130 },
    }, SelectEditorLang)
    editorLangTabs[1].btn:SetPoint("TOPLEFT", langLabel, "BOTTOMLEFT", 0, -6)
    f.langLabel = langLabel

    -- Independent of "Send as:" (a spell reacts the same amount regardless of which
    -- channel it's sent to), so this sits in its own row above that section entirely
    -- rather than under it. Owns the language-row toggle that chatLabel used to have --
    -- chatLabel now anchors off this section's bottom instead, at a fixed offset.
    local freqLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    freqLabel:SetText("Reaction frequency:")
    f.freqLabel = freqLabel

    local freqAlwaysCB = GabbaRP_NewCheckbox(f, "Always react (skip cooldown/spam-gate)")
    freqAlwaysCB:SetPoint("TOPLEFT", freqLabel, "BOTTOMLEFT", -2, -6)
    freqAlwaysCB:SetScript("OnClick", function(self)
        GabbaRPCharDB.rp.customSkipGate[editorSpellName] = self:GetChecked() and true or false
        SyncEditorFrequency(editorSpellName)
    end)
    f.freqAlwaysCB = freqAlwaysCB

    local freqIntervalLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    freqIntervalLabel:SetPoint("TOPLEFT", freqAlwaysCB, "BOTTOMLEFT", 2, -8)
    freqIntervalLabel:SetText("React every")

    local freqIntervalBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    freqIntervalBox:SetSize(30, 20)
    freqIntervalBox:SetPoint("LEFT", freqIntervalLabel, "RIGHT", 8, 0)
    freqIntervalBox:SetAutoFocus(false)
    freqIntervalBox:SetNumeric(true)
    freqIntervalBox:SetMaxLetters(2)
    f.freqIntervalBox = freqIntervalBox

    local freqIntervalHint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    freqIntervalHint:SetPoint("LEFT", freqIntervalBox, "RIGHT", 8, 0)
    freqIntervalHint:SetText("casts (blank = default)")

    local function SaveFreqInterval(self)
        local text = self:GetText()
        GabbaRPCharDB.rp.customInterval[editorSpellName] = (text ~= "" and tonumber(text)) or nil
        SyncEditorFrequency(editorSpellName)
    end
    freqIntervalBox:SetScript("OnEnterPressed", function(self) SaveFreqInterval(self) self:ClearFocus() end)
    freqIntervalBox:SetScript("OnEditFocusLost", SaveFreqInterval)

    local chatLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatLabel:SetText("Send as:")
    chatLabel:SetPoint("TOPLEFT", freqIntervalLabel, "BOTTOMLEFT", -2, -14)
    f.chatLabel = chatLabel

    editorChatTabs = GabbaRP_NewTabStrip(f, CHAT_TYPES, SelectEditorChatType)
    -- -14, not -6: the button row needs to clear resetBtn's bottom edge (below), which
    -- sits level with this whole row since it's anchored off chatLabel's own TOP -- too
    -- small a gap here and the two visibly overlap (Reset to Default over Announce).
    editorChatTabs[1].btn:SetPoint("TOPLEFT", chatLabel, "BOTTOMLEFT", 0, -14)

    local chatDesc = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    chatDesc:SetPoint("TOPLEFT", editorChatTabs[1].btn, "BOTTOMLEFT", 0, -6)
    chatDesc:SetWidth(390)
    chatDesc:SetJustifyH("LEFT")
    f.chatDesc = chatDesc

    -- freqLabel's anchor toggles between two fixed points depending on whether the
    -- language row above it is shown -- everything below (frequency controls, chat
    -- tabs, lines, add/reset) is anchored relative to freqLabel or its descendants, so
    -- this single toggle is enough to reflow the whole popup instead of hiding-but-
    -- leaving-a-gap.
    function f.LayoutForLanguage(allowLanguage)
        freqLabel:ClearAllPoints()
        if allowLanguage then
            langLabel:Show()
            for _, e in ipairs(editorLangTabs) do e.btn:Show() end
            freqLabel:SetPoint("TOPLEFT", editorLangTabs[1].btn, "BOTTOMLEFT", 0, -18)
        else
            langLabel:Hide()
            for _, e in ipairs(editorLangTabs) do e.btn:Hide() end
            freqLabel:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -12)
        end
    end

    -- The "Mind Control Whisper"/"Mind Vision Whisper" dummy entries (RP_Data.lua,
    -- fired from RP_Core.lua's TryTargetWhisperReaction) are never sent via a chat
    -- type the user picks -- always a whisper to the actual target, or a Hermes-Say
    -- fallback for Mind Control specifically -- and don't go through the normal
    -- cooldown/gate at all, so neither the "Send as" nor "Reaction frequency"
    -- sections apply. Replaced with a single fixed explanation instead for these two.
    local whisperInfoText = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    whisperInfoText:SetWidth(390)
    whisperInfoText:SetJustifyH("LEFT")
    whisperInfoText:SetText("Always sent as a whisper to whoever you actually targeted, not a chat type you pick. Skipped entirely if the target isn't an actual player.\n\nMind Control against the opposing faction: sent as a Say translated through the Hermes addon if it's installed, otherwise skipped.\n\nMind Vision against the opposing faction: always skipped.")
    whisperInfoText:Hide()
    f.whisperInfoText = whisperInfoText

    -- Anchored to chatLabel's own TOP (not a fixed offset off hint) so it tracks
    -- chatLabel's row exactly regardless of how tall the frequency section above ends
    -- up being, and RIGHT off hint for the same horizontal position as before -- a
    -- frame can take one point from each axis like this as long as they don't conflict.
    local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    resetBtn:SetSize(140, 22)
    resetBtn:SetPoint("TOP", chatLabel, "TOP", 0, 0)
    resetBtn:SetPoint("RIGHT", hint, "RIGHT", 0, 0)
    resetBtn:SetText("Reset to Default")
    resetBtn:SetScript("OnClick", function()
        StaticPopupDialogs["GABBARP_CONFIRM_RESET_LINES"] = {
            text = "Reset \"" .. editorSpellName .. "\" to its default lines, chat type, and reaction frequency?\n\n|cffff4444This discards any custom edits and cannot be undone.|r",
            button1 = "Reset",
            button2 = "Cancel",
            OnAccept = function()
                GabbaRPCharDB.rp.customLines[editorSpellName] = nil
                GabbaRPCharDB.rp.customChatType[editorSpellName] = nil
                GabbaRPCharDB.rp.customSkipGate[editorSpellName] = nil
                GabbaRPCharDB.rp.customInterval[editorSpellName] = nil
                SyncEditorChatType(ns.GRP_SpellChatType[editorSpellName] or "EMOTE")
                SyncEditorFrequency(editorSpellName)
                RefreshEditorRows()
                FlashEditorSaved()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("GABBARP_CONFIRM_RESET_LINES")
    end)

    local linesLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    linesLabel:SetPoint("TOPLEFT", chatDesc, "BOTTOMLEFT", 0, -14)
    linesLabel:SetText("Lines: |cff888888(click a line to edit it)|r")

    function f.LayoutForWhisperDummy(isWhisperDummy)
        freqLabel:SetShown(not isWhisperDummy)
        freqAlwaysCB:SetShown(not isWhisperDummy)
        freqIntervalLabel:SetShown(not isWhisperDummy)
        freqIntervalBox:SetShown(not isWhisperDummy)
        freqIntervalHint:SetShown(not isWhisperDummy)
        chatLabel:SetShown(not isWhisperDummy)
        for _, e in ipairs(editorChatTabs) do e.btn:SetShown(not isWhisperDummy) end
        chatDesc:SetShown(not isWhisperDummy)
        whisperInfoText:SetShown(isWhisperDummy)

        linesLabel:ClearAllPoints()
        if isWhisperDummy then
            -- freqLabel is only hidden, not un-anchored -- its position (already
            -- correctly toggled by LayoutForLanguage above) is still valid to anchor
            -- off of.
            whisperInfoText:ClearAllPoints()
            whisperInfoText:SetPoint("TOPLEFT", freqLabel, "TOPLEFT", 0, 0)
            linesLabel:SetPoint("TOPLEFT", whisperInfoText, "BOTTOMLEFT", 0, -14)
        else
            linesLabel:SetPoint("TOPLEFT", chatDesc, "BOTTOMLEFT", 0, -14)
        end
    end

    local savedText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    savedText:SetPoint("LEFT", linesLabel, "RIGHT", 10, 0)
    savedText:SetTextColor(0.3, 1, 0.3)
    savedText:SetText("Saved!")
    savedText:Hide()
    f.savedText = savedText

    local scrollFrame = CreateFrame("ScrollFrame", "GRPLineEditorScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", linesLabel, "BOTTOMLEFT", 0, -6)
    -- Two-point anchor (not a fixed SetHeight) so this fills exactly whatever space is
    -- actually available between the lines label and the Add row, regardless of whether
    -- this popup has the extra Language row above "Send as:" (Food/Drink/Death Reactions)
    -- or not (plain skills) -- fixed-height guesses kept either overflowing past the
    -- frame's bottom edge or leaving a dead gap above the Add box, depending on which
    -- popup variant. 60px reserves room for the Add box/button below.
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 60)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(360)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild

    local addBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    addBox:SetSize(300, 20)
    addBox:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 6, -16)
    addBox:SetAutoFocus(false)

    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBtn:SetSize(60, 22)
    addBtn:SetPoint("LEFT", addBox, "RIGHT", 8, 0)
    addBtn:SetText("Add")
    local function AddLine()
        local text = addBox:GetText()
        if text == "" then return end
        local current = {}
        for _, l in ipairs(GetEffectiveLines(editorSpellName)) do table.insert(current, l) end
        table.insert(current, text)
        GabbaRPCharDB.rp.customLines[editorSpellName] = current
        addBox:SetText("")
        addBox:ClearFocus()
        RefreshEditorRows()
        FlashEditorSaved()
    end
    addBtn:SetScript("OnClick", AddLine)
    addBox:SetScript("OnEnterPressed", AddLine)

    editorFrame = f
end

-- allowLanguage: shows the English/Local Language tab row for spellName's "(LOCAL)"
-- sibling -- used for Food/Drink and Death Reactions, where one row now covers both
-- languages. Regular skills pass nothing/false (each language already has its own
-- class-skill panel tab, so a language switch inside the popup too would be redundant).
local function ShowLineEditor(spellName, allowLanguage)
    if not editorFrame then CreateEditorFrame() end
    -- Both editor popups default to dead-center -- closing the other one instead of just
    -- letting them stack avoids ever spawning one directly on top of the other.
    if greetingEditorFrame and greetingEditorFrame:IsShown() then
        greetingEditorFrame:Hide()
    end
    editorBaseName = spellName
    editorAllowLanguage = allowLanguage or false
    editorLang = "en"
    editorSpellName = ComputeEditorSpellName()
    editorFrame.title:SetText(editorSpellName)
    editorFrame.LayoutForLanguage(editorAllowLanguage)
    if editorAllowLanguage then
        GabbaRP_SyncTabStrip(editorLangTabs, editorLang)
    end
    SyncEditorChatType(GetEffectiveChatType(editorSpellName))
    SyncEditorFrequency(editorSpellName)
    -- "Mind Control Whisper"/"Mind Vision Whisper" (+ (LOCAL) mirrors) are always sent
    -- as a whisper to the actual target (or a Hermes fallback), never a chat type the
    -- user picks -- see RP_Core.lua's TryTargetWhisperReaction.
    local baseSpellName = editorSpellName:gsub(" %(LOCAL%)$", "")
    local isWhisperDummy = baseSpellName == "Mind Control Whisper" or baseSpellName == "Mind Vision Whisper"
    editorFrame.LayoutForWhisperDummy(isWhisperDummy)
    RefreshEditorRows()
    editorFrame:Show()
end

----------------------------------------------------------------------
-- Greeting line editor: same rows+add+reset shape as the skill line editor above, but
-- with a Language tab and a 4-way time-of-day tab since each category (join, welcome)
-- has a separate line list per time of day and language.
----------------------------------------------------------------------

local greetingEditorCategory
local greetingEditorTime = "morning"
local greetingEditorLang = "en"
local greetingEditorRows = {}
local greetingTimeCheckboxes = {}
local greetingLangCheckboxes = {}
local greetingSavedHideTimer

-- Which customLines table this editor writes to -- English and local-language overrides
-- are fully independent, mirroring how the shipped defaults (ns.GRP_GreetingLines vs
-- ns.GRP_GreetingLines_Local) are two separate tables too.
local function GetGreetingCustomTable()
    return greetingEditorLang == "local" and GabbaRPCharDB.greetings.customLinesLocal or GabbaRPCharDB.greetings.customLines
end

-- Brief "Saved!" confirmation next to the "Lines:" heading -- the only feedback that an
-- edit/add/remove/reset actually took effect, since rows just silently update otherwise.
local function FlashGreetingSaved()
    if not greetingEditorFrame or not greetingEditorFrame.savedText then return end
    greetingEditorFrame.savedText:Show()
    if greetingSavedHideTimer then greetingSavedHideTimer:Cancel() end
    greetingSavedHideTimer = C_Timer.NewTimer(1.2, function()
        if greetingEditorFrame and greetingEditorFrame.savedText then greetingEditorFrame.savedText:Hide() end
    end)
end

local function RefreshGreetingEditorRows()
    local lines = ns.GabbaRP_GetEffectiveGreetingLines(greetingEditorCategory, greetingEditorTime, greetingEditorLang)
    for i, text in ipairs(lines) do
        local row = greetingEditorRows[i]
        if not row then
            row = CreateFrame("Frame", nil, greetingEditorFrame.scrollChild)
            row:SetSize(360, 20)

            row.text = CreateFrame("EditBox", nil, row)
            row.text:SetPoint("LEFT", row, "LEFT", 2, 0)
            row.text:SetSize(330, 18)
            row.text:SetAutoFocus(false)
            row.text:SetFontObject("GameFontHighlightSmall")
            row.text:SetJustifyH("LEFT")

            row.removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.removeBtn:SetSize(20, 18)
            row.removeBtn:SetText("X")
            row.removeBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0)

            greetingEditorRows[i] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -4 - (i - 1) * 22)
        row.text:SetText(text)
        row.text:SetCursorPosition(0)
        local function SaveEdit(self)
            local newText = TrimText(self:GetText())
            if newText == "" or newText == text then
                self:SetText(text) -- refuse an empty edit, and skip a no-op save
                return
            end
            local current = {}
            for j, l in ipairs(ns.GabbaRP_GetEffectiveGreetingLines(greetingEditorCategory, greetingEditorTime, greetingEditorLang)) do
                current[j] = (j == i) and newText or l
            end
            local customTable = GetGreetingCustomTable()
            customTable[greetingEditorCategory] = customTable[greetingEditorCategory] or {}
            customTable[greetingEditorCategory][greetingEditorTime] = current
            RefreshGreetingEditorRows()
            FlashGreetingSaved()
        end
        row.text:SetScript("OnEnterPressed", function(self) SaveEdit(self) self:ClearFocus() end)
        row.text:SetScript("OnEditFocusLost", SaveEdit)
        row.text:SetScript("OnEscapePressed", function(self) self:SetText(text) self:ClearFocus() end)
        row.removeBtn:SetScript("OnClick", function()
            local current = {}
            for j, l in ipairs(ns.GabbaRP_GetEffectiveGreetingLines(greetingEditorCategory, greetingEditorTime, greetingEditorLang)) do
                if j ~= i then table.insert(current, l) end
            end
            local customTable = GetGreetingCustomTable()
            customTable[greetingEditorCategory] = customTable[greetingEditorCategory] or {}
            customTable[greetingEditorCategory][greetingEditorTime] = current
            RefreshGreetingEditorRows()
            FlashGreetingSaved()
        end)
        row:Show()
    end
    for i = #lines + 1, #greetingEditorRows do
        greetingEditorRows[i]:Hide()
    end
    greetingEditorFrame.scrollChild:SetHeight(math.max(1, #lines * 22 + 8))
end

local function SelectGreetingTime(timeOfDay)
    greetingEditorTime = timeOfDay
    GabbaRP_SyncTabStrip(greetingTimeCheckboxes, timeOfDay)
    RefreshGreetingEditorRows()
end

local function SelectGreetingLang(lang)
    greetingEditorLang = lang
    GabbaRP_SyncTabStrip(greetingLangCheckboxes, lang)
    RefreshGreetingEditorRows()
end

local function CreateGreetingEditorFrame()
    local f = CreateFrame("Frame", "GRPGreetingLineEditor", UIParent, "BasicFrameTemplateWithInset")
    -- Same 420x540 as CreateEditorFrame (skill/Food/Drink/Death Reactions popup) -- all
    -- editor popups should be visually consistent in size, not just internally correct.
    f:SetSize(420, 540)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("HIGH")
    f:Hide()
    tinsert(UISpecialFrames, "GRPGreetingLineEditor")

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", f.TitleBg, "TOP", 0, -5)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 12, -30)
    hint:SetWidth(390)
    hint:SetJustifyH("LEFT")
    hint:SetText("Welcome messages only: %t = the joining member's name here (in skill messages elsewhere, %t is your current target instead)")

    -- Language promoted above Time of day (and both are tabs, not checkboxes) -- which
    -- language you're editing matters more than which time slot, and picking one of
    -- several mutually-exclusive options reads more naturally as a tab than a checkbox.
    local langLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    langLabel:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -12)
    langLabel:SetText("Language:")

    greetingLangCheckboxes = GabbaRP_NewTabStrip(f, {
        { key = "en", label = "English", width = 80 },
        { key = "local", label = "Local Language", width = 130 },
    }, SelectGreetingLang)
    greetingLangCheckboxes[1].btn:SetPoint("TOPLEFT", langLabel, "BOTTOMLEFT", 0, -6)

    local timeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timeLabel:SetPoint("TOPLEFT", greetingLangCheckboxes[1].btn, "BOTTOMLEFT", 0, -18)
    timeLabel:SetText("Time of day:")

    greetingTimeCheckboxes = GabbaRP_NewTabStrip(f, GREETING_TIME_SLOTS, SelectGreetingTime)
    greetingTimeCheckboxes[1].btn:SetPoint("TOPLEFT", timeLabel, "BOTTOMLEFT", 0, -6)

    local linesLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    linesLabel:SetPoint("TOPLEFT", greetingTimeCheckboxes[1].btn, "BOTTOMLEFT", 0, -18)
    linesLabel:SetText("Lines: |cff888888(click a line to edit it)|r")

    local savedText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    savedText:SetPoint("LEFT", linesLabel, "RIGHT", 10, 0)
    savedText:SetTextColor(0.3, 1, 0.3)
    savedText:SetText("Saved!")
    savedText:Hide()
    f.savedText = savedText

    local scrollFrame = CreateFrame("ScrollFrame", "GRPGreetingLineEditorScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", linesLabel, "BOTTOMLEFT", 0, -6)
    -- Two-point anchor, not a fixed SetHeight -- same reasoning as CreateEditorFrame's
    -- scrollFrame: fills exactly the space actually available instead of guessing a pixel
    -- count. 100px reserved here (vs. that one's 60px) because this popup stacks BOTH the
    -- Add row AND the "Reset This Time Slot" button below the scroll area, not just Add.
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 100)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(360)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild

    local addBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    addBox:SetSize(300, 20)
    addBox:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 6, -16)
    addBox:SetAutoFocus(false)

    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBtn:SetSize(60, 22)
    addBtn:SetPoint("LEFT", addBox, "RIGHT", 8, 0)
    addBtn:SetText("Add")
    local function AddLine()
        local text = addBox:GetText()
        if text == "" then return end
        local current = {}
        for _, l in ipairs(ns.GabbaRP_GetEffectiveGreetingLines(greetingEditorCategory, greetingEditorTime, greetingEditorLang)) do table.insert(current, l) end
        table.insert(current, text)
        local customTable = GetGreetingCustomTable()
        customTable[greetingEditorCategory] = customTable[greetingEditorCategory] or {}
        customTable[greetingEditorCategory][greetingEditorTime] = current
        addBox:SetText("")
        addBox:ClearFocus()
        RefreshGreetingEditorRows()
        FlashGreetingSaved()
    end
    addBtn:SetScript("OnClick", AddLine)
    addBox:SetScript("OnEnterPressed", AddLine)

    local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    resetBtn:SetSize(220, 22)
    resetBtn:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -14)
    resetBtn:SetText("Reset This Time Slot to Default")
    resetBtn:SetScript("OnClick", function()
        local customTable = GetGreetingCustomTable()
        if customTable[greetingEditorCategory] then
            customTable[greetingEditorCategory][greetingEditorTime] = nil
        end
        RefreshGreetingEditorRows()
        FlashGreetingSaved()
    end)

    greetingEditorFrame = f
end

local function ShowGreetingEditor(category)
    if not greetingEditorFrame then CreateGreetingEditorFrame() end
    if editorFrame and editorFrame:IsShown() then
        editorFrame:Hide()
    end
    greetingEditorCategory = category
    greetingEditorFrame.title:SetText(category == "join" and "Join Greeting" or "Welcome Greeting")
    SelectGreetingTime("morning")
    SelectGreetingLang("en")
    greetingEditorFrame:Show()
end

----------------------------------------------------------------------
-- General panel: everything except the class-skill list, organized into headed groups.
----------------------------------------------------------------------

-- A section heading + one-line explanation, anchored below whatever came before it (or
-- at the very top if this is the first section). Returns the explanation widget, since
-- that's what the next section anchors below.
local function AddSection(f, prevAnchor, title, explanation)
    local heading = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if prevAnchor then
        heading:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -22)
    else
        heading:SetPoint("TOPLEFT", 0, -4)
    end
    heading:SetText(title)

    local desc = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    desc:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -2)
    desc:SetWidth(260)
    desc:SetJustifyH("LEFT")
    desc:SetText(explanation)

    return desc
end

function ns.GabbaRP_BuildGeneralPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints(parent)
    panel:Hide()

    -- Several headed sections plus three sliders don't fit in the Blizzard-native
    -- canvas's fixed height (that host isn't user-resizable) -- wrapped in a scroll
    -- frame so it's never a problem regardless of host size.
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -18, 0)
    local f = CreateFrame("Frame", nil, scrollFrame)
    f:SetSize(380, 1050)
    scrollFrame:SetScrollChild(f)

    local modeCheckboxes = {}

    local function SetMode(mode)
        GabbaRPCharDB.rp.mode = mode
        for _, entry in ipairs(modeCheckboxes) do
            entry.cb:SetChecked(entry.key == mode)
        end
    end

    -- === General ===
    local generalDesc = AddSection(f, nil, "General",
        "Turns the RP module on/off and picks how lines get delivered.")

    local enabledCB = GabbaRP_NewCheckbox(f, "RP module enabled")
    enabledCB:SetPoint("TOPLEFT", generalDesc, "BOTTOMLEFT", 0, -6)
    enabledCB:SetScript("OnClick", function(self)
        GabbaRPCharDB.rp.enabled = self:GetChecked() and true or false
    end)

    local animCB = GabbaRP_NewCheckbox(f, "Play emote animation")
    animCB:SetPoint("TOPLEFT", enabledCB, "BOTTOMLEFT", 0, -4)
    animCB:SetScript("OnClick", function(self)
        GabbaRPCharDB.rp.anim = self:GetChecked() and true or false
    end)

    local animDesc = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    animDesc:SetPoint("TOPLEFT", animCB, "BOTTOMLEFT", 0, -2)
    animDesc:SetWidth(260)
    animDesc:SetJustifyH("LEFT")
    animDesc:SetText("Plays a matching character emote (e.g. /taunt) alongside the line, when the skill has one.")

    local modeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modeLabel:SetPoint("TOPLEFT", animDesc, "BOTTOMLEFT", 0, -10)
    modeLabel:SetText("Output mode:")

    local modeDesc = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    modeDesc:SetPoint("TOPLEFT", modeLabel, "BOTTOMLEFT", 0, -2)
    modeDesc:SetWidth(260)
    modeDesc:SetJustifyH("LEFT")
    modeDesc:SetText("Self: only you see it. Public: sent to chat. Both: you see it and it's sent.")

    local prevAnchor = modeDesc
    local firstMode = true
    for _, mode in ipairs(MODES) do
        local cb = GabbaRP_NewCheckbox(f, mode.label)
        cb:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, firstMode and -6 or -2)
        firstMode = false
        cb:SetScript("OnClick", function() SetMode(mode.key) end)
        table.insert(modeCheckboxes, { key = mode.key, cb = cb })
        prevAnchor = cb
    end

    local useLocalCB = GabbaRP_NewCheckbox(f, "Use local language")
    useLocalCB:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -10)
    useLocalCB:SetScript("OnClick", function(self)
        GabbaRPCharDB.rp.localLanguageEnabled = self:GetChecked() and true or false
    end)

    local useLocalDesc = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    useLocalDesc:SetPoint("TOPLEFT", useLocalCB, "BOTTOMLEFT", 0, -2)
    useLocalDesc:SetWidth(260)
    useLocalDesc:SetJustifyH("LEFT")
    useLocalDesc:SetText("Off by default. This addon ships English-only. Turn on and fill in your own lines (via each Edit button's Language tab) to use a local language instead of/alongside English.")

    prevAnchor = useLocalDesc

    -- Only shown when GreenWall is actually detected -- checked directly against
    -- GreenWall's own `gw` global (same as ns.GabbaRP_IsInPlayerGuild's confederation
    -- fallback, RP_Core.lua), deliberately NOT through DeathNotificationLib -- this
    -- feature stays independent of that addon, unlike the separate Death: Guild picker
    -- above which needs it either way. Without GreenWall there's no confederation to
    -- opt into, so a picker with a single option would just be clutter. Best-effort:
    -- unlike the own-guild check, this leans on GetGuildInfo(unit) to learn a
    -- non-guildmate's own guild, which this addon has already confirmed can
    -- occasionally return nil for a real, already-grouped unit.
    local localGuildScopeTabs
    if type(gw) == "table" and type(gw.config) == "table" then
        local localGuildScopeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        localGuildScopeLabel:SetPoint("TOPLEFT", useLocalDesc, "BOTTOMLEFT", 0, -6)
        localGuildScopeLabel:SetText("Local source:")

        localGuildScopeTabs = GabbaRP_NewTabStrip(f, {
            { key = "guild_only", label = "Guild Only", width = 90 },
            { key = "guild_confederation", label = "Guild + Confederation", width = 150 },
        }, function(key)
            GabbaRPCharDB.rp.localLanguageGuildScope = key
            GabbaRP_SyncTabStrip(localGuildScopeTabs, key)
        end)
        localGuildScopeTabs[1].btn:SetPoint("LEFT", localGuildScopeLabel, "RIGHT", 6, 0)
        prevAnchor = localGuildScopeLabel
    end

    local languageCheckboxes = {}
    local function SetSoloLanguage(lang)
        GabbaRPCharDB.rp.soloLanguage = lang
        for _, entry in ipairs(languageCheckboxes) do
            entry.cb:SetChecked(entry.key == lang)
        end
    end

    local soloLangLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    soloLangLabel:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -10)
    soloLangLabel:SetText("Solo language:")

    local soloLangDesc = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    soloLangDesc:SetPoint("TOPLEFT", soloLangLabel, "BOTTOMLEFT", 0, -2)
    soloLangDesc:SetWidth(260)
    soloLangDesc:SetJustifyH("LEFT")
    soloLangDesc:SetText("Used only when you're not in a group. Grouped play switches automatically based on how much of the group is in your guild.")

    prevAnchor = soloLangDesc
    local firstLang = true
    for _, lang in ipairs(SOLO_LANGUAGES) do
        local cb = GabbaRP_NewCheckbox(f, lang.label)
        cb:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, firstLang and -6 or -2)
        firstLang = false
        cb:SetScript("OnClick", function() SetSoloLanguage(lang.key) end)
        table.insert(languageCheckboxes, { key = lang.key, cb = cb })
        prevAnchor = cb
    end

    -- === Say/Yell Delivery ===
    local sayYellDesc = AddSection(f, prevAnchor, "Say/Yell Delivery",
        "Blizzard requires a real click/keypress to send Say/Yell. This picks how that requirement gets satisfied.")

    local SAY_YELL_MODES = {
        { key = "safe", label = "Safe (default)" },
        { key = "instant", label = "Instant" },
    }
    local sayYellCheckboxes = {}
    local function SetSayYellDelivery(mode)
        GabbaRPCharDB.rp.sayYellDelivery = mode
        for _, entry in ipairs(sayYellCheckboxes) do
            entry.cb:SetChecked(entry.key == mode)
        end
    end

    prevAnchor = sayYellDesc
    local firstSayYell = true
    for _, mode in ipairs(SAY_YELL_MODES) do
        local cb = GabbaRP_NewCheckbox(f, mode.label)
        cb:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, firstSayYell and -6 or -2)
        firstSayYell = false
        cb:SetScript("OnClick", function() SetSayYellDelivery(mode.key) end)
        table.insert(sayYellCheckboxes, { key = mode.key, cb = cb })
        prevAnchor = cb
    end

    local sayYellExplain = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sayYellExplain:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -6)
    sayYellExplain:SetWidth(260)
    sayYellExplain:SetJustifyH("LEFT")
    sayYellExplain:SetText("Safe: waits for your next real action (a skill or item use) to send. Never eats a click, but can lag a beat behind if you're not pressing anything.\n\nInstant: sends on your very next click or keypress anywhere, near-zero delay, but that click's own action doesn't happen.")

    prevAnchor = sayYellExplain

    -- === Group Greetings ===
    local greetingsDesc = AddSection(f, prevAnchor, "Group Greetings",
        "Greets the group on join, and welcomes anyone who joins after you by name. Uses the output mode above.")

    local greetingsCB = GabbaRP_NewCheckbox(f, "Group greetings enabled")
    greetingsCB:SetPoint("TOPLEFT", greetingsDesc, "BOTTOMLEFT", 0, -6)
    greetingsCB:SetScript("OnClick", function(self)
        GabbaRPCharDB.greetings.enabled = self:GetChecked() and true or false
    end)

    local joinBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    joinBtn:SetSize(170, 22)
    joinBtn:SetPoint("TOPLEFT", greetingsCB, "BOTTOMLEFT", 0, -8)
    joinBtn:SetText("Edit Join Messages")
    joinBtn:SetScript("OnClick", function() ShowGreetingEditor("join") end)

    local welcomeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    welcomeBtn:SetSize(170, 22)
    welcomeBtn:SetPoint("TOPLEFT", joinBtn, "BOTTOMLEFT", 0, -6)
    welcomeBtn:SetText("Edit Welcome Messages")
    welcomeBtn:SetScript("OnClick", function() ShowGreetingEditor("welcome") end)

    -- Toggles a spell's EN and LOCAL keys together -- one visible checkbox per reaction
    -- covers both languages; which language actually fires is picked automatically
    -- (ns.GabbaRP_GetGroupLanguage, RP_Core.lua) or chosen in the popup's Language tab
    -- (ShowLineEditor's allowLanguage), not by this checkbox.
    local function SetSpellEnabledBothLanguages(baseKey, enabled)
        GabbaRPCharDB.rp.disabledSpells[baseKey] = not enabled or nil
        GabbaRPCharDB.rp.disabledSpells[baseKey .. " (LOCAL)"] = not enabled or nil
    end

    -- === Food & Drink ===
    local foodDesc = AddSection(f, welcomeBtn, "Food & Drink",
        "The combined line fires instead of the individual ones when both buffs are up at once. Edit opens a Language tab for the English/Local Language line lists.")

    local foodCB = GabbaRP_NewCheckbox(f, "Comment when eating")
    foodCB:SetPoint("TOPLEFT", foodDesc, "BOTTOMLEFT", 0, -6)
    foodCB:SetScript("OnClick", function(self)
        SetSpellEnabledBothLanguages("Food", self:GetChecked())
    end)

    local foodEditBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    foodEditBtn:SetSize(40, 20)
    foodEditBtn:SetPoint("LEFT", foodCB.text, "RIGHT", 8, 0)
    foodEditBtn:SetText("Edit")
    foodEditBtn:SetScript("OnClick", function() ShowLineEditor("Food", true) end)

    local drinkCB = GabbaRP_NewCheckbox(f, "Comment when drinking")
    drinkCB:SetPoint("TOPLEFT", foodCB, "BOTTOMLEFT", 0, -4)
    drinkCB:SetScript("OnClick", function(self)
        SetSpellEnabledBothLanguages("Drink", self:GetChecked())
    end)

    local drinkEditBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    drinkEditBtn:SetSize(40, 20)
    drinkEditBtn:SetPoint("LEFT", drinkCB.text, "RIGHT", 8, 0)
    drinkEditBtn:SetText("Edit")
    drinkEditBtn:SetScript("OnClick", function() ShowLineEditor("Drink", true) end)

    local comboCB = GabbaRP_NewCheckbox(f, "Comment when eating and drinking at once")
    comboCB:SetPoint("TOPLEFT", drinkCB, "BOTTOMLEFT", 0, -4)
    comboCB:SetScript("OnClick", function(self)
        SetSpellEnabledBothLanguages("Food and Drink", self:GetChecked())
    end)

    local comboEditBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    comboEditBtn:SetSize(40, 20)
    comboEditBtn:SetPoint("LEFT", comboCB.text, "RIGHT", 8, 0)
    comboEditBtn:SetText("Edit")
    comboEditBtn:SetScript("OnClick", function() ShowLineEditor("Food and Drink", true) end)

    -- === Death Reactions ===
    -- One row per reaction (not per language) -- Edit opens the same popup Food/Drink
    -- uses, with a Language tab for the English/Local Language line lists.
    local deathDesc = AddSection(f, comboCB, "Death Reactions",
        "Comments when someone dies. Group/raid deaths are always caught live; guild deaths (even outside your group) need the separate DeathNotificationLib addon installed to be detected.")

    local deathGroupCB = GabbaRP_NewCheckbox(f, "Comment on party member deaths")
    deathGroupCB:SetPoint("TOPLEFT", deathDesc, "BOTTOMLEFT", 0, -6)
    deathGroupCB:SetScript("OnClick", function(self)
        SetSpellEnabledBothLanguages("Death: Group", self:GetChecked())
    end)

    local deathGroupEditBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    deathGroupEditBtn:SetSize(40, 20)
    deathGroupEditBtn:SetPoint("LEFT", deathGroupCB.text, "RIGHT", 8, 0)
    deathGroupEditBtn:SetText("Edit")
    deathGroupEditBtn:SetScript("OnClick", function() ShowLineEditor("Death: Group", true) end)

    local deathRaidCB = GabbaRP_NewCheckbox(f, "Comment on raid member deaths")
    deathRaidCB:SetPoint("TOPLEFT", deathGroupCB, "BOTTOMLEFT", 0, -4)
    deathRaidCB:SetScript("OnClick", function(self)
        SetSpellEnabledBothLanguages("Death: Raid", self:GetChecked())
    end)

    local deathRaidEditBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    deathRaidEditBtn:SetSize(40, 20)
    deathRaidEditBtn:SetPoint("LEFT", deathRaidCB.text, "RIGHT", 8, 0)
    deathRaidEditBtn:SetText("Edit")
    deathRaidEditBtn:SetScript("OnClick", function() ShowLineEditor("Death: Raid", true) end)

    local deathGuildCB = GabbaRP_NewCheckbox(f, "Comment on guild member deaths")
    deathGuildCB:SetPoint("TOPLEFT", deathRaidCB, "BOTTOMLEFT", 0, -4)
    deathGuildCB:SetScript("OnClick", function(self)
        SetSpellEnabledBothLanguages("Death: Guild", self:GetChecked())
    end)

    local deathGuildEditBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    deathGuildEditBtn:SetSize(40, 20)
    deathGuildEditBtn:SetPoint("LEFT", deathGuildCB.text, "RIGHT", 8, 0)
    deathGuildEditBtn:SetText("Edit")
    deathGuildEditBtn:SetScript("OnClick", function() ShowLineEditor("Death: Guild", true) end)

    -- Only shown when GreenWall is actually detected -- DeathNotificationLib.
    -- GetGuildFilterModeOptions only includes "guild_confederation" as an option in that
    -- case, and without GreenWall there's nothing to actually choose between (your own
    -- guild is the only guild there is), so a picker with one option would just be clutter.
    local guildFilterAnchor = deathGuildCB
    local guildFilterTabs
    if DeathNotificationLib and DeathNotificationLib.GetGuildFilterModeOptions then
        local options = DeathNotificationLib.GetGuildFilterModeOptions(true)
        if options["guild_confederation"] then
            local guildFilterLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            guildFilterLabel:SetPoint("TOPLEFT", deathGuildCB, "BOTTOMLEFT", 20, -6)
            guildFilterLabel:SetText("Count deaths from:")

            guildFilterTabs = GabbaRP_NewTabStrip(f, {
                { key = "guild_only", label = "Guild Only", width = 90 },
                { key = "guild_confederation", label = "Guild + Confederation", width = 150 },
            }, function(key)
                GabbaRPCharDB.rp.deathGuildFilterMode = key
                GabbaRP_SyncTabStrip(guildFilterTabs, key)
            end)
            guildFilterTabs[1].btn:SetPoint("LEFT", guildFilterLabel, "RIGHT", 6, 0)
            guildFilterAnchor = guildFilterLabel
        end
    end

    local suppressGroupRaidCB = GabbaRP_NewCheckbox(f, "Skip group/raid chat if they were also in your guild")
    suppressGroupRaidCB:SetPoint("TOPLEFT", guildFilterAnchor, "BOTTOMLEFT", guildFilterAnchor == deathGuildCB and 0 or -20, -4)
    suppressGroupRaidCB:SetScript("OnClick", function(self)
        GabbaRPCharDB.rp.suppressGroupRaidIfGuild = self:GetChecked() and true or false
    end)

    local suppressGroupRaidDesc = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    suppressGroupRaidDesc:SetPoint("TOPLEFT", suppressGroupRaidCB, "BOTTOMLEFT", 0, -2)
    suppressGroupRaidDesc:SetWidth(260)
    suppressGroupRaidDesc:SetJustifyH("LEFT")
    suppressGroupRaidDesc:SetText("Avoids a duplicate message when a guildmate who dies was also in your party/raid. Guild chat already covers it a few seconds later.")

    -- === Spam Protection ===
    local spamDesc = AddSection(f, suppressGroupRaidDesc, "Spam Protection",
        "Three layers, checked in order: (1) the same skill won't comment again until its own cooldown below has passed (skills cast very rapidly, like Life Tap, instead only trigger every couple of casts, not on a timer; not configurable here). (2) a floor on how close together ANY two lines can land, regardless of which skill. (3) a random chance to stay quiet even when nothing else blocked it. Together these keep the module from feeling like it comments on literally everything.")

    -- OptionsSliderTemplate needs a real global name -- its Low/High/Text labels are XML
    -- child regions wired up via "$parent" name substitution.
    local perSkillSlider = CreateFrame("Slider", "GRPPerSkillSlider", f, "OptionsSliderTemplate")
    -- x=60, not a small indent -- OptionsSliderTemplate centers its label ABOVE the
    -- slider's own (160px) width, but "Min. gap for the same skill" is much wider than
    -- that, so the centered label overhangs well past the slider's left edge. Too small
    -- an indent here let that overhang get clipped by the scroll frame.
    perSkillSlider:SetPoint("TOPLEFT", spamDesc, "BOTTOMLEFT", 60, -34)
    perSkillSlider:SetWidth(160)
    perSkillSlider:SetMinMaxValues(0, 30)
    perSkillSlider:SetValueStep(1)
    if perSkillSlider.SetObeyStepOnDrag then perSkillSlider:SetObeyStepOnDrag(true) end
    perSkillSlider:SetOrientation("HORIZONTAL")
    _G[perSkillSlider:GetName() .. "Low"]:SetText("0s")
    _G[perSkillSlider:GetName() .. "High"]:SetText("30s")
    _G[perSkillSlider:GetName() .. "Text"]:SetText("Min. gap for the same skill")

    local perSkillValue = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    perSkillValue:SetPoint("LEFT", perSkillSlider, "RIGHT", 12, 2)

    perSkillSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        GabbaRPCharDB.rp.perSkillCooldown = value
        perSkillValue:SetText(value .. "s")
    end)

    local cooldownSlider = CreateFrame("Slider", "GRPCooldownSlider", f, "OptionsSliderTemplate")
    cooldownSlider:SetPoint("TOPLEFT", perSkillSlider, "BOTTOMLEFT", 0, -44)
    cooldownSlider:SetWidth(160)
    cooldownSlider:SetMinMaxValues(0, 60)
    cooldownSlider:SetValueStep(1)
    if cooldownSlider.SetObeyStepOnDrag then cooldownSlider:SetObeyStepOnDrag(true) end
    cooldownSlider:SetOrientation("HORIZONTAL")
    _G[cooldownSlider:GetName() .. "Low"]:SetText("0s")
    _G[cooldownSlider:GetName() .. "High"]:SetText("60s")
    _G[cooldownSlider:GetName() .. "Text"]:SetText("Min. gap between ANY two lines")

    local cooldownValue = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cooldownValue:SetPoint("LEFT", cooldownSlider, "RIGHT", 12, 2)

    cooldownSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        GabbaRPCharDB.rp.globalCooldown = value
        cooldownValue:SetText(value .. "s")
    end)

    local chanceSlider = CreateFrame("Slider", "GRPChanceSlider", f, "OptionsSliderTemplate")
    chanceSlider:SetPoint("TOPLEFT", cooldownSlider, "BOTTOMLEFT", 0, -44)
    chanceSlider:SetWidth(160)
    chanceSlider:SetMinMaxValues(10, 100)
    chanceSlider:SetValueStep(5)
    if chanceSlider.SetObeyStepOnDrag then chanceSlider:SetObeyStepOnDrag(true) end
    chanceSlider:SetOrientation("HORIZONTAL")
    _G[chanceSlider:GetName() .. "Low"]:SetText("10%")
    _G[chanceSlider:GetName() .. "High"]:SetText("100%")
    _G[chanceSlider:GetName() .. "Text"]:SetText("Chance a line actually fires")

    local chanceValue = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    chanceValue:SetPoint("LEFT", chanceSlider, "RIGHT", 12, 2)

    chanceSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / 5 + 0.5) * 5
        GabbaRPCharDB.rp.triggerChance = value
        chanceValue:SetText(value .. "%")
    end)

    local spamResetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    spamResetBtn:SetSize(140, 22)
    spamResetBtn:SetPoint("TOPLEFT", chanceSlider, "BOTTOMLEFT", -10, -30)
    spamResetBtn:SetText("Reset to Default")
    spamResetBtn:SetScript("OnClick", function()
        GabbaRPCharDB.rp.perSkillCooldown = ns.GRP_DEFAULT_PER_SKILL_COOLDOWN
        GabbaRPCharDB.rp.globalCooldown = ns.GRP_DEFAULT_GLOBAL_COOLDOWN
        GabbaRPCharDB.rp.triggerChance = ns.GRP_DEFAULT_TRIGGER_CHANCE
        perSkillSlider:SetValue(ns.GRP_DEFAULT_PER_SKILL_COOLDOWN)
        cooldownSlider:SetValue(ns.GRP_DEFAULT_GLOBAL_COOLDOWN)
        chanceSlider:SetValue(ns.GRP_DEFAULT_TRIGGER_CHANCE)
    end)

    local function Refresh()
        local db = GabbaRPCharDB.rp
        enabledCB:SetChecked(db.enabled)
        animCB:SetChecked(db.anim)
        greetingsCB:SetChecked(GabbaRPCharDB.greetings.enabled)
        useLocalCB:SetChecked(db.localLanguageEnabled)
        if localGuildScopeTabs then
            GabbaRP_SyncTabStrip(localGuildScopeTabs, db.localLanguageGuildScope or "guild_only")
        end
        foodCB:SetChecked(not db.disabledSpells["Food"])
        drinkCB:SetChecked(not db.disabledSpells["Drink"])
        comboCB:SetChecked(not db.disabledSpells["Food and Drink"])
        deathGroupCB:SetChecked(not db.disabledSpells["Death: Group"])
        deathRaidCB:SetChecked(not db.disabledSpells["Death: Raid"])
        deathGuildCB:SetChecked(not db.disabledSpells["Death: Guild"])
        if guildFilterTabs then
            GabbaRP_SyncTabStrip(guildFilterTabs, db.deathGuildFilterMode or "guild_only")
        end
        suppressGroupRaidCB:SetChecked(db.suppressGroupRaidIfGuild)
        perSkillSlider:SetValue(db.perSkillCooldown or ns.GRP_DEFAULT_PER_SKILL_COOLDOWN)
        cooldownSlider:SetValue(db.globalCooldown or ns.GRP_DEFAULT_GLOBAL_COOLDOWN)
        chanceSlider:SetValue(db.triggerChance or ns.GRP_DEFAULT_TRIGGER_CHANCE)
        for _, entry in ipairs(modeCheckboxes) do
            entry.cb:SetChecked(entry.key == db.mode)
        end
        for _, entry in ipairs(languageCheckboxes) do
            entry.cb:SetChecked(entry.key == (db.soloLanguage or "en"))
        end
        for _, entry in ipairs(sayYellCheckboxes) do
            entry.cb:SetChecked(entry.key == (db.sayYellDelivery or "safe"))
        end
    end

    return { frame = panel, refresh = Refresh }
end

----------------------------------------------------------------------
-- Export/Import: a shared text format (also produced/consumed by the standalone
-- "GabbaRP Line Pack Builder" web tool) covering everything the Skills panel would show
-- for the current class, plus Food & Drink and all 8 greeting slots, in both languages.
-- Format:
--   # GabbaRP export v1
--
--   [Shadow Bolt: EMOTE]
--   line one.
--   line two.
--
--   [Greeting: Join / Morning]
--   line one.
----------------------------------------------------------------------

local CHAT_TYPE_SET = { EMOTE = true, SAY = true, YELL = true, PARTY = true, RAID = true, GUILD = true, GROUP_ANNOUNCE = true, GROUP_SUCCESS = true }
local GREETING_CATS = { "join", "welcome" }
local GREETING_TIMES = { "morning", "midday", "evening", "night" }

local function TitleCase(s)
    return s:sub(1, 1):upper() .. s:sub(2):lower()
end

local function BuildExportText()
    local parts = { "# GabbaRP export v1", "" }

    local function emitSpell(name)
        table.insert(parts, "[" .. name .. ": " .. GetEffectiveChatType(name) .. "]")
        for _, l in ipairs(GetEffectiveLines(name)) do table.insert(parts, l) end
        table.insert(parts, "")
    end

    local _, playerClass = UnitClass("player")
    local names = {}
    for spellName, class in pairs(ns.GRP_SpellClass) do
        if class == playerClass and not SPELL_LIST_EXCLUDE[spellName] and not IsLocalKey(spellName) then
            table.insert(names, spellName)
        end
    end
    table.sort(names)
    -- Emits each skill's "(LOCAL)" sibling right after it too, synthesized as name .. "
    -- (LOCAL)" -- GRP_SpellClass never actually contains that suffixed key for regular
    -- class skills (GabbaRP ships English-only; local-language content is something each
    -- user fills in themselves), so relying on it being already present in the table
    -- would silently skip every class skill's local-language export.
    for _, name in ipairs(names) do
        emitSpell(name)
        emitSpell(name .. " (LOCAL)")
    end

    emitSpell("Food")
    emitSpell("Drink")
    emitSpell("Food and Drink")
    emitSpell("Death: Group")
    emitSpell("Death: Raid")
    emitSpell("Death: Guild")
    emitSpell("Food (LOCAL)")
    emitSpell("Drink (LOCAL)")
    emitSpell("Food and Drink (LOCAL)")
    emitSpell("Death: Group (LOCAL)")
    emitSpell("Death: Raid (LOCAL)")
    emitSpell("Death: Guild (LOCAL)")

    for _, cat in ipairs(GREETING_CATS) do
        for _, time in ipairs(GREETING_TIMES) do
            table.insert(parts, "[Greeting: " .. TitleCase(cat) .. " / " .. TitleCase(time) .. "]")
            for _, l in ipairs(ns.GabbaRP_GetEffectiveGreetingLines(cat, time, "en")) do table.insert(parts, l) end
            table.insert(parts, "")

            table.insert(parts, "[Greeting (LOCAL): " .. TitleCase(cat) .. " / " .. TitleCase(time) .. "]")
            for _, l in ipairs(ns.GabbaRP_GetEffectiveGreetingLines(cat, time, "local")) do table.insert(parts, l) end
            table.insert(parts, "")
        end
    end

    return table.concat(parts, "\n")
end

local function ParseExportText(text)
    local blocks = {}
    local current = nil
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        if not line:match("^%s*#") then
            local header = line:match("^%[(.+)%]%s*$")
            if header then
                if current then table.insert(blocks, current) end
                local name, ct = header:match("^(.-):%s*([%u_]+)%s*$")
                if name and ct and CHAT_TYPE_SET[ct] then
                    current = { name = TrimText(name), chatType = ct, lines = {} }
                else
                    current = { name = TrimText(header), chatType = nil, lines = {} }
                end
            elseif current then
                local trimmed = TrimText(line)
                if trimmed ~= "" then
                    table.insert(current.lines, trimmed)
                end
            end
        end
    end
    if current then table.insert(blocks, current) end
    return blocks
end

-- Returns appliedCount, skippedNames.
local function ApplyImport(blocks)
    local applied, skipped = 0, {}
    for _, b in ipairs(blocks) do
        local greetingHeaderLocal = b.name:match("^Greeting %(LOCAL%):%s*(.+)$")
        local greetingHeader = greetingHeaderLocal or b.name:match("^Greeting:%s*(.+)$")
        if greetingHeader then
            local catWord, timeWord = greetingHeader:match("^(%a+)%s*/%s*(%a+)$")
            local cat = catWord and catWord:lower()
            local time = timeWord and timeWord:lower()
            if cat and time and (cat == "join" or cat == "welcome")
                and (time == "morning" or time == "midday" or time == "evening" or time == "night") then
                local customTable = greetingHeaderLocal and GabbaRPCharDB.greetings.customLinesLocal or GabbaRPCharDB.greetings.customLines
                customTable[cat] = customTable[cat] or {}
                customTable[cat][time] = b.lines
                applied = applied + 1
            else
                table.insert(skipped, b.name)
            end
        elseif ns.GRP_SpellClass[b.name] or (IsLocalKey(b.name) and ns.GRP_SpellClass[b.name:gsub(" %(LOCAL%)$", "")]) then
            -- The second condition covers a class skill's synthesized "(LOCAL)" key (see
            -- BuildExportText/BuildSpellList above) -- GRP_SpellClass itself never
            -- contains that suffixed key directly for regular class skills, only its base
            -- EN name, so validating against b.name alone would reject every one of them.
            GabbaRPCharDB.rp.customLines[b.name] = b.lines
            if b.chatType then
                GabbaRPCharDB.rp.customChatType[b.name] = b.chatType
            end
            applied = applied + 1
        else
            table.insert(skipped, b.name)
        end
    end
    return applied, skipped
end

local exportImportFrame

local function CreateExportImportFrame()
    local f = CreateFrame("Frame", "GRPExportImport", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(520, 480)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("HIGH")
    f:Hide()
    tinsert(UISpecialFrames, "GRPExportImport")

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", f.TitleBg, "TOP", 0, -5)
    f.title:SetText("Export / Import")

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 12, -30)
    hint:SetWidth(490)
    hint:SetJustifyH("LEFT")
    hint:SetText("Generate covers your class's skills + Food & Drink + Greetings, in both languages. Click in the box, Ctrl+A to select all, Ctrl+C to copy (WoW can't copy to clipboard for you). To import, paste text below and Apply.")

    -- Multi-line EditBox needs an explicit width for word wrap and must live inside a
    -- ScrollFrame to scroll -- every other EditBox in this addon is single-line, this is
    -- the one exception.
    local scrollFrame = CreateFrame("ScrollFrame", "GRPExportScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 90)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(460)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", editBox.ClearFocus)
    scrollFrame:SetScrollChild(editBox)
    f.editBox = editBox

    local statusText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("BOTTOMLEFT", 12, 12)
    statusText:SetPoint("RIGHT", -12, 0)
    statusText:SetJustifyH("LEFT")

    local genBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    genBtn:SetSize(150, 22)
    genBtn:SetPoint("BOTTOMLEFT", 12, 50)
    genBtn:SetText("Generate Export")
    genBtn:SetScript("OnClick", function()
        editBox:SetText(BuildExportText())
        editBox:SetFocus()
        editBox:HighlightText()
        statusText:SetText("")
    end)

    local applyBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    applyBtn:SetSize(150, 22)
    applyBtn:SetPoint("LEFT", genBtn, "RIGHT", 10, 0)
    applyBtn:SetText("Apply Import")
    applyBtn:SetScript("OnClick", function()
        local blocks = ParseExportText(editBox:GetText())
        if #blocks == 0 then
            statusText:SetText("No [Section] headers found, nothing changed.")
            return
        end
        StaticPopupDialogs["GABBARP_CONFIRM_IMPORT"] = {
            text = "This will overwrite lines for " .. #blocks .. " section(s) mentioned in the text below.\n\n|cffff4444This cannot be undone.|r Continue?",
            button1 = "Apply",
            button2 = "Cancel",
            OnAccept = function()
                local applied, skipped = ApplyImport(blocks)
                local msg = "Loaded " .. applied .. " section(s)."
                if #skipped > 0 then
                    msg = msg .. " Skipped (unrecognized): " .. table.concat(skipped, ", ")
                end
                statusText:SetText(msg)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("GABBARP_CONFIRM_IMPORT")
    end)

    exportImportFrame = f
end

local function ShowExportImport()
    if not exportImportFrame then CreateExportImportFrame() end
    exportImportFrame.editBox:SetText("")
    exportImportFrame:Show()
end

----------------------------------------------------------------------
-- "What's new" changelog popup: shown once per meaningful update. This addon has no
-- custom window of its own (RP_BlizzardOptions.lua only registers Blizzard Settings
-- categories), so there's nowhere to put an in-place changelog -- a standalone popup on
-- login is the standard alternative other addons (WeakAuras, ElvUI, Details!) use for the
-- same reason. CHANGELOG_VERSION is deliberately separate from both the addon's
-- ## Version (.toc, human-facing) and CHAR_SCHEMA_VERSION (Core.lua, SavedVariables
-- migrations) -- bump it only when there's something worth telling the user about, not
-- on every release. Add the next entry as CHANGELOG[N] and bump CHANGELOG_VERSION to N;
-- anyone behind sees every entry they missed concatenated, not just the latest.
----------------------------------------------------------------------

local CHANGELOG_VERSION = 11
-- Exposed so Core.lua's GabbaRP_EnsureDefaults can stamp brand-new characters as
-- already-current (a fresh install has nothing to "catch up" on, so it shouldn't see a
-- changelog immediately) without this file needing to load before that logic runs.
ns.GabbaRP_CHANGELOG_VERSION = CHANGELOG_VERSION
local CHANGELOG = {
    [1] = "|cffffd200Welcome to GabbaRP v1.0!|r This addon gives your character a voice: automatic roleplay lines and emotes for every class, triggered by your spell casts, fully editable in-game.\n\n" ..
        "|cffffd200Highlights:|r Self, Public, and Both modes; Death Reactions; Imp Backtalk for Warlocks; Group Greetings; and spam protection you fully control, with sliders for the per-skill cooldown, the global cooldown, and the trigger chance.\n\n" ..
        "|cffffd200Also included:|r optional local-language support, off by default. Turn on \"Use local language\" in Settings, then add your own translated lines through each Edit button's Language tab.\n\n" ..
        "|cffffd200For bug reports:|r /gabbarp report prints a copy-pasteable summary, and /gabbarp triggerdebug, greetdebug, and debuglog help track down anything that isn't working as expected.",
    [2] = "|cffffd200GabbaRP v1.0.1|r\n\n" ..
        "|cffffd200Fixed:|r a buff landing on you from someone else (another priest's Power Word: Shield, a druid's Mark of the Wild, etc.) no longer makes your character react as if you had cast it yourself.\n\n" ..
        "|cffffd200New:|r use %w in a Death: Guild line to include the deceased's last words. A %w line is only ever picked when there actually are last words to show; otherwise your normal lines are used instead.\n\n" ..
        "|cffffd200New:|r any line can start with [SAY], [YELL], or [EMOTE] to say just that one line differently than the skill's usual chat type. Falls back to the skill's normal chat type if the tag is missing or misspelled.",
    [3] = "|cffffd200GabbaRP v1.0.2|r\n\n" ..
        "|cffffd200New:|r flavor lines for five Priest racials/talent that were missing entirely: Fear Ward, Desperate Prayer, Starshards, Elune's Grace, and Inner Focus.\n\n" ..
        "|cffffd200New:|r character animations for more skills: Warrior war cries and self-buffs, Druid melee, and several CC/utility spells (Shackle Undead, Mind Control, Hunter's Mark, Distracting Shot, Faerie Fire).\n\n" ..
        "|cffffd200Changed:|r Fear, Psychic Scream, and Howl of Terror now play a menacing gesture instead of a startled one. You're the one causing the fear, not feeling it.\n\n" ..
        "|cffffd200Fixed:|r the Local Language skill list was empty for every class. It now correctly lists every skill, and Export/Import handles local-language lines properly too.\n\n" ..
        "|cffffd200New:|r a one-time login warning if you have a skill set to Say/Yell chat, explaining why one of your clicks can occasionally get \"eaten\" (an unavoidable side effect of how Say/Yell messages have to be sent).\n\n" ..
        "|cffffd200Fixed:|r removed two Priest entries that don't actually exist on this client (Shadowguard, Shadow Word: Death).\n\n" ..
        "|cffffd200Changed:|r the editor popups (Skills, Food/Drink, Death Reactions, Greetings) are now a consistent size, with no more overlapping buttons or wasted empty space.",
    [4] = "|cffffd200GabbaRP v1.0.3|r\n\n" ..
        "|cffffd200Fixed:|r forming a group by inviting someone yourself no longer says both the generic \"Join\" greeting AND the personal welcome for that first invitee. If you're the group leader, only the personal welcome fires.",
    [5] = "|cffffd200GabbaRP v1.0.4|r\n\n" ..
        "|cffffd200New:|r flavor lines for four more Warlock skills: Banish, Demon Armor (also covers Demon Skin), Unending Breath, and Detect Invisibility (also covers Detect Greater Invisibility).\n\n" ..
        "|cffffd200Fixed:|r Create Soulstone (and other rank-named skills) sometimes went completely silent, especially solo. The reaction now always fires, falling back to an emote when there's no group to announce to.\n\n" ..
        "|cffffd200Fixed:|r Shadow Trance no longer gets randomly swallowed by the spam gate. It's a rare proc already, so it now always reacts.\n\n" ..
        "|cffffd200New:|r a \"Reaction frequency\" section in each skill's editor: \"Always react\" (skip the cooldown/spam-gate) and \"React every N casts\", overriding the built-in defaults per character.\n\n" ..
        "|cffffd200Changed:|r the static Party/Raid chat-type buttons are gone, replaced by two dynamic types that auto-pick whichever you're in: \"Group Start\" (on cast start, always sent) and \"Group Success\" (on cast success, normal cooldown rules). Individual lines can still force a fixed Party/Raid channel with [PARTY]/[RAID].",
    [6] = "|cffffd200GabbaRP v1.0.5|r\n\n" ..
        "|cffffd200Fixed:|r Create Soulstone reacted at the wrong moment: when you conjure the item, before you've even picked a target. It now waits for the item to actually be used on someone, which is also when the %t placeholder finally means something.\n\n" ..
        "|cffffd200Fixed:|r a \"Group Start\"/\"Group Success\" override on Create Soulstone (English or the local-language mirror) could go completely silent after the change above. Both are now correctly reconnected.\n\n" ..
        "|cffffd200New:|r a one-line heads-up on login if any settings were automatically adjusted for this version, instead of that happening completely invisibly.\n\n" ..
        "|cffffd200New:|r /gabbarp triggerdebug now also logs every combat-log event you personally trigger, not just ones the addon already recognizes. Helpful for figuring out exactly what an item or spell fires as.",
    [7] = "|cffffd200GabbaRP v1.0.6|r\n\n" ..
        "|cffffd200New:|r Say/Yell reactions now have a delivery option in Settings. \"Safe\" (new default) waits for your next real action (a skill or item use) to send, so it never eats a click, just possibly a beat slower. \"Instant\" keeps the old behavior: near-zero delay, but your very next click or keypress gets swallowed.\n\n" ..
        "|cffffd200New:|r Mind Control and Mind Vision now also whisper the target directly when successfully cast on a player, on top of their normal group-facing line. Mind Control against the opposing faction falls back to a Say translated through the Hermes addon if it's installed. Mind Vision against the opposing faction is always skipped. Both are skipped entirely against non-player targets.",
    [8] = "|cffffd200GabbaRP v1.0.7|r\n\n" ..
        "|cffffd200Fixed:|r a self-buff line (e.g. Demon Armor) could fire on its own right when zoning into an instance or through a portal, with no actual cast involved. The game can resend an \"aura applied\" event for a buff you already had up during a zone transition; that resync is now recognized and ignored instead of read as a fresh cast.",
    [9] = "|cffffd200GabbaRP v1.0.8|r\n\n" ..
        "|cffffd200Changed:|r every skill's default flavor line was rewritten. Most skills default to sending as an Emote, which prefixes your character's name, and a lot of the old lines read grammatically wrong once that name was added (\"Charlie embrace the void.\"). All of them now read correctly as a proper third-person emote, and several use %t to actually name the target where they didn't before.\n\n" ..
        "|cffffd200Fixed:|r Export/Import silently dropped any skill set to the \"Group Success\" chat type, since that value was missing from the importer's list of recognized chat types.\n\n" ..
        "|cffffd200New:|r the Line Pack Builder, a browser-based editor for composing or translating lines for every skill, Death Reaction, and Greeting outside the game, then exporting a block that pastes straight into the in-game Import box. https://gabbajoe.github.io/GabbaRP/",
    [10] = "|cffffd200GabbaRP v1.0.9|r\n\n" ..
        "|cffffd200Fixed:|r Death: Guild could silently never fire for a guildmate's death. DeathNotificationLib only reliably reports guild membership for peer-corroborated deaths; a self-reported death (the common case) left that flag unset even for an actual guildmate. Now checked live against your guild roster instead.",
    [11] = "|cffffd200GabbaRP v1.0.10|r\n\n" ..
        "|cffffd200Changed:|r local-language guild membership and the group-language result are now cached. Spell reactions no longer rescan the full guild roster on every trigger; group and guild changes safely refresh the cache when needed.\n\n" ..
        "|cffffd200Fixed:|r temporary missing guild data while a group is forming, including the optional GreenWall confederation check, is retried instead of being remembered as English.",
}

local changelogFrame

local function CreateChangelogFrame()
    local f = CreateFrame("Frame", "GRPChangelog", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(460, 420)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("HIGH")
    f:Hide()
    tinsert(UISpecialFrames, "GRPChangelog")

    -- Gold, matching the look of Blizzard's own frame titles (e.g. the Game Menu's
    -- "Main Menu") -- GameFontHighlight alone is plain white. GameFontNormalLarge
    -- was tried first but ran too wide/tall for this title bar; GameFontNormal fits.
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOP", f.TitleBg, "TOP", 0, -6)
    f.title:SetTextColor(1, 0.82, 0)
    f.title:SetText("GabbaRP - What's New")

    local scrollFrame = CreateFrame("ScrollFrame", "GRPChangelogScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 56)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(410)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    local text = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT")
    text:SetWidth(410)
    text:SetJustifyH("LEFT")
    f.text = text
    f.scrollChild = scrollChild

    -- Only checking the box (not just closing the window some other way, e.g. Escape or
    -- an accidental drag-close) marks this version seen -- a stray close shouldn't
    -- silently skip content the player never actually read; it just reappears next login.
    local dontShowCB = GabbaRP_NewCheckbox(f, "Don't show this again")
    dontShowCB:SetPoint("BOTTOMLEFT", 16, 16)
    dontShowCB:SetScript("OnClick", function(self)
        GabbaRPCharDB.lastSeenChangelogVersion = self:GetChecked() and CHANGELOG_VERSION or 0
    end)
    f.dontShowCB = dontShowCB

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeBtn:SetSize(100, 22)
    closeBtn:SetPoint("BOTTOMRIGHT", -16, 14)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    changelogFrame = f
end

-- Concatenates every entry the player hasn't seen yet (not just the latest), so someone
-- who skipped several versions gets the full picture in one popup instead of only the
-- newest bullet points.
local function ShowChangelogIfNeeded()
    local seen = GabbaRPCharDB.lastSeenChangelogVersion or 0
    if seen >= CHANGELOG_VERSION then return end
    if not changelogFrame then CreateChangelogFrame() end

    local parts = {}
    for v = seen + 1, CHANGELOG_VERSION do
        if CHANGELOG[v] then table.insert(parts, CHANGELOG[v]) end
    end
    changelogFrame.text:SetText(table.concat(parts, "\n\n"))
    changelogFrame.scrollChild:SetHeight(math.max(1, changelogFrame.text:GetStringHeight() + 8))
    changelogFrame.dontShowCB:SetChecked(false)
    changelogFrame:Show()
end
ns.GabbaRP_ShowChangelogIfNeeded = ShowChangelogIfNeeded

----------------------------------------------------------------------
-- Skills panel: just the per-class skill list, on its own.
----------------------------------------------------------------------

-- lang: "en" (default) or "local" -- picks between the plain spell-name keys and their
-- "(LOCAL)"-suffixed siblings (see ResolveSpellKey, RP_Core.lua). Two independent
-- instances of this factory are registered (see RP_BlizzardOptions.lua), one per
-- language, so switching languages is just picking which subcategory you're on.
function ns.GabbaRP_BuildSkillsPanel(parent, lang)
    lang = lang or "en"
    local f = CreateFrame("Frame", nil, parent)
    f:SetAllPoints(parent)
    f:Hide()

    local spellCheckboxes = {}
    local spellListBuilt = false
    local className, playerClass = UnitClass("player")

    local desc = AddSection(f, nil, className .. " Skills (" .. lang:upper() .. ")",
        "Checked skills comment when cast; unchecked ones stay silent. A skill with every line removed via Edit stays silent too, even if checked.")

    local exportBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    exportBtn:SetSize(160, 22)
    exportBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -8)
    exportBtn:SetText("Export / Import Lines...")
    exportBtn:SetScript("OnClick", ShowExportImport)

    -- Must include lang, not just parent -- both the EN and LOCAL instances of this panel
    -- are registered as sibling Blizzard subcategories (see RP_BlizzardOptions.lua), each
    -- with its own host frame, but a parent-only suffix would still be fragile if that
    -- ever changes -- CreateFrame silently returns the existing global frame for an
    -- already-used name instead of erroring, which would make both language panels
    -- quietly share one scroll frame.
    local scrollSuffix = (parent:GetName() or tostring(parent)):gsub("%W", "") .. lang
    local scrollFrame = CreateFrame("ScrollFrame", "GRPSkillsScrollFrame" .. scrollSuffix, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -18, 0)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(230)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    local function BuildSpellList()
        if spellListBuilt then return end
        spellListBuilt = true

        -- The "(LOCAL)" list is synthesized from the EN class-skill list (base name +
        -- " (LOCAL)") rather than requiring GRP_SpellClass to already contain that
        -- suffixed key. GabbaRP ships English-only by design -- no "(LOCAL)" keys are
        -- pre-seeded in GRP_SpellClass for regular class skills, only for the universal
        -- Food/Drink/Death entries (see SPELL_LIST_EXCLUDE above and BuildExportText's
        -- hardcoded emitSpell calls). Without this, the Local Language tab showed nothing
        -- to translate for any class, and a character's already-existing custom (LOCAL)
        -- line data (e.g. merged in from elsewhere) had no way to surface in the UI or in
        -- Export/Import, since both are driven by this same class-skill list.
        local names = {}
        for spellName, class in pairs(ns.GRP_SpellClass) do
            if (class == playerClass or class == "ALL") and not SPELL_LIST_EXCLUDE[spellName]
                and not IsLocalKey(spellName) then
                table.insert(names, lang == "local" and (spellName .. " (LOCAL)") or spellName)
            end
        end
        table.sort(names)

        local rowHeight = 26 -- matches GabbaRP_NewCheckbox's 24px size plus a little breathing room
        local y = -4

        for _, spellName in ipairs(names) do
            -- Display label drops the "(LOCAL)" suffix -- the full key (with suffix) is what
            -- actually gets used for disabledSpells/ShowLineEditor below.
            local displayName = lang == "local" and spellName:gsub(" %(LOCAL%)$", "") or spellName
            local cb = GabbaRP_NewCheckbox(scrollChild, displayName)
            cb:SetPoint("TOPLEFT", 4, y)
            cb:SetChecked(not GabbaRPCharDB.rp.disabledSpells[spellName])
            cb:SetScript("OnClick", function(self)
                GabbaRPCharDB.rp.disabledSpells[spellName] = not self:GetChecked() or nil
            end)
            spellCheckboxes[spellName] = cb

            local editBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
            editBtn:SetSize(40, 20)
            editBtn:SetPoint("LEFT", cb.text, "RIGHT", 8, 0)
            editBtn:SetText("Edit")
            editBtn:SetScript("OnClick", function() ShowLineEditor(spellName) end)

            y = y - rowHeight
        end

        if #names == 0 then
            local fs = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            fs:SetPoint("TOPLEFT", 4, y)
            fs:SetText("No skills configured for your class.")
            y = y - rowHeight
        end

        scrollChild:SetHeight(math.max(1, -y))
    end

    local function Refresh()
        BuildSpellList()
        for spellName, cb in pairs(spellCheckboxes) do
            cb:SetChecked(not GabbaRPCharDB.rp.disabledSpells[spellName])
        end
    end

    return { frame = f, refresh = Refresh }
end
