# GabbaRP

A WoW Classic Era addon: automatic RP flavor lines and emotes triggered by spell casts, for every class. No custom window — configuration lives directly in Blizzard's Options > AddOns > GabbaRP panel.

## File layout (load order matters, see the .toc)

- `Core.lua` — namespace setup (`local ADDON_NAME, ns = ...`), SavedVariablesPerCharacter defaults (`CHAR_DB_DEFAULTS`), the schema-migration system (`CHAR_SCHEMA_VERSION`/`MIGRATIONS`/`RunMigrations`), the persisted `debugLog`, `/gabbarp report`, and the slash-command/event wiring.
- `RP_Data.lua` — all spell/line data: `GabbaRP_Spells`, `GabbaRP_SpellClass`, `GabbaRP_SpellChatType`, `GabbaRP_SpellInterval` (spammy-skill "every Nth cast" overrides), plus greeting line pools. Local-language content is stored as ordinary sibling keys suffixed `" (LOCAL)"` in the same tables (e.g. `["Shadow Bolt (LOCAL)"]`), not a parallel table.
- `RP_Core.lua` — the trigger/dispatch logic: `TriggerLine`, spam-protection layering (`perSkillCooldown`/`GabbaRP_SpellInterval` override, then `PassesGlobalGate` for `globalCooldown`+`triggerChance`), `GabbaRP_GetGroupLanguage`/`ResolveSpellKey` for local-language selection, Imp Backtalk, Death Reactions.
- `RP_Greeting.lua` — join/welcome greeting logic.
- `RP_Options.lua` — the entire Blizzard-panel UI: skill list builders, the line editor popup, spam-protection sliders, export/import, and the "What's New" changelog popup.
- `RP_BlizzardOptions.lua` — registers the Blizzard Options subcategories.
- `Libs/` — bundled MessageQueue library (see its own LICENSE).

## Conventions

- **Namespace-table pattern**: every file starts `local ADDON_NAME, ns = ...`. Cross-file access goes through `ns.*`; the only true globals are the SavedVariables tables (`GabbaRPCharDB`) and the frame-name strings WoW itself needs (e.g. `SLASH_GABBARP1`). Never define a bare global function — this addon is designed to coexist with the user's other addons in the same Lua namespace, and a same-named bare global silently overwrites whichever addon loads later.
- **Schema migrations**: SavedVariables structure changes go through `CHAR_SCHEMA_VERSION` + `MIGRATIONS[N]` in `Core.lua`, never an ad-hoc one-off migration function. Bump `CHAR_SCHEMA_VERSION` and add the next `MIGRATIONS[N]` entry; brand-new characters get stamped straight to current (nothing to migrate). This is deliberately separate from the `.toc`'s `## Version` (human-facing) and `RP_Options.lua`'s `CHANGELOG_VERSION` (the "what's new" popup) — three independent counters.
- **Local-language content**: suffix-key convention (`" (LOCAL)"`), resolved via `ResolveSpellKey`/`GabbaRP_GetGroupLanguage`. Gated by `localLanguageEnabled` (default **off** — this addon ships English-only; local-language content is something each user opts into and fills in themselves via the line editor, not something pre-translated for a guild that might not even use it).
- **Debug tooling**: per-feature `/gabbarp xdebug on|off` toggles + a persisted rolling `GabbaRP_DebugLog` (capped, readable directly from the saved `.lua` file) + `/gabbarp report` for a copy-pasteable diagnostic block. Follow this pattern for any new troubleshooting need rather than ad-hoc `print()` debugging.
- **Popups** (line editor, changelog): `SetFrameStrata("HIGH")`, not `"DIALOG"` — `DIALOG` renders above other game UI (bags etc.), which is unwanted here. Mutually-exclusive popups auto-close each other rather than stacking.
- German is the working language with this user in conversation; code comments and commit-style content stay in English.
- Keep the `.toc`'s `## Version`, this README's Changelog section, and `RP_Options.lua`'s in-addon `CHANGELOG` table in sync when shipping a release worth telling users about.

## Known open item

The bundled `Icon.png` is **not committed** to this repo (`.gitignore`) — its rights aren't owned by this project. It still works for local/live use, but a new original icon is needed before this repo's release artifacts (CurseForge package, etc.) ship one.

## Note

This file mirrors `CLAUDE.md` in the same directory (Claude Code's equivalent convention). Keep the two in sync if either is updated.
