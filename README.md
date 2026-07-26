# GabbaRP — v1.0.1

GabbaRP gives your character a voice. It listens for the spells you cast and, every so often, has your character say or emote something fitting in Say, Emote, Guild, Party or Raid chat — a Warrior taunting before a Charge, a Priest murmuring a prayer before Power Word: Shield, a Warlock's Imp mouthing off in Say chat. Every class is covered, every line is editable in-game, and nothing is sent to chat unless you're actually eligible to see it (no spamming a raid with your Rogue's inner monologue).

It's fully self-contained — no dependencies, no custom window to learn. Configuration lives directly in Blizzard's own **Options > AddOns > GabbaRP** panel, so it looks and feels like part of the game.

## Installation

Copy this folder to `World of Warcraft/_classic_era_/Interface/AddOns/GabbaRP` and enable **GabbaRP** in the AddOns list.

## Features

- Automatic flavor lines and emotes tied to your class's spells — all 9 classes, hundreds of lines out of the box.
- Three modes: **Self** (only you see it), **Public** (Say/Yell/Emote, everyone nearby sees it), or **Both**.
- Death reactions: your character reacts differently depending on whether a guildmate, party/raid member, or someone else died nearby.
- Warlock Imp Backtalk: your Voidwalker/Imp/etc. occasionally talks back when nearby monsters say or yell something.
- Group greetings: a line when you join a group, and a personal welcome line for whoever joins after you.
- Spam protection you control: a per-skill cooldown, a global "minimum gap between any two lines" cooldown, and a percent chance a line actually fires once eligible — each with its own slider. Fast-recast skills (like Life Tap) automatically fall back to an "only every Nth cast" rule instead of a cooldown, so they don't go silent forever on a short timer.
- **Optional local-language support**: off by default. Turn on "Use local language" and fill in your own translated lines (via each Edit button's Language tab) to have your character speak your guild's language instead of English when the group is mostly guildmates — falls back to English for anything you haven't translated yet.
- Every line list is fully editable in-game: add, remove, or reset any skill's lines to default, per language.
- Export/import your entire configuration as plain text, to back it up or share it with guildmates.
- Built-in troubleshooting: `/gabbarp report` prints a copy-pasteable diagnostic summary, and per-feature debug logs help track down "why didn't this fire" reports.

## Slash commands

```
/gabbarp on | off
/gabbarp mode self|public|both
/gabbarp anim on|off
/gabbarp greetings on|off
/gabbarp impdebug on|off       (troubleshooting log for Imp Backtalk)
/gabbarp greetdebug on|off     (troubleshooting log for language selection)
/gabbarp triggerdebug on|off   (troubleshooting log for why a skill did/didn't comment)
/gabbarp debuglog [clear]      (persisted debug trail, also readable from the saved GabbaRP.lua file)
/gabbarp report                (copy-pasteable diagnostic summary for bug reports)
```

Everything else — enabling/disabling individual skills, editing lines, spam-protection sliders, local-language setup — is in **Options > AddOns > GabbaRP**.

## Changelog

### V1.0.1

- Fixed: a buff landing on you from someone else (another priest's Power Word: Shield, a druid's Mark of the Wild, etc.) no longer made your character react as if you had cast it yourself.
- New: `%w` placeholder in Death: Guild lines for the deceased's last words (via DeathNotificationLib) — only picked when there actually are last words to show.
- New: any line can start with `[SAY]`, `[YELL]`, or `[EMOTE]` to override the chat type for just that one line.

### V1.0

- Initial public release: automatic RP lines and emotes for all 9 classes, Death Reactions, Imp Backtalk, Group Greetings, fully in-game editable, with optional local-language support.
