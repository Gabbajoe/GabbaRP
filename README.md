# GabbaRP - v1.0.10

[![Release](https://github.com/Gabbajoe/GabbaRP/actions/workflows/release.yml/badge.svg)](https://github.com/Gabbajoe/GabbaRP/actions/workflows/release.yml)
[![Latest Release](https://img.shields.io/github/v/release/Gabbajoe/GabbaRP)](https://github.com/Gabbajoe/GabbaRP/releases/latest)
[![License: MIT](https://img.shields.io/github/license/Gabbajoe/GabbaRP)](LICENSE.txt)

GabbaRP gives your character a voice. It listens for the spells you cast and, every so often, has your character say or emote something fitting in Say, Emote, Guild chat, or automatically to whichever of Party/Raid you're actually in: a Warrior taunting before a Charge, a Priest murmuring a prayer before Power Word: Shield, a Warlock's Imp mouthing off in Say chat. Every class is covered, every line is editable in-game, and nothing is sent to chat unless you're actually eligible to see it (no spamming a raid with your Rogue's inner monologue).

It's fully self-contained, no dependencies, no custom window to learn. Configuration lives directly in Blizzard's own **Options > AddOns > GabbaRP** panel, so it looks and feels like part of the game.

## Installation

Copy this folder to `World of Warcraft/_classic_era_/Interface/AddOns/GabbaRP` and enable **GabbaRP** in the AddOns list.

## Features

- Automatic flavor lines and emotes tied to your class's spells: all 9 classes, hundreds of lines out of the box.
- Three modes: **Self** (only you see it), **Public** (Say/Yell/Emote, everyone nearby sees it), or **Both**.
- Character animations: many skills also play a matching emote animation alongside the line (a Warrior's Charge plays a charging animation, Fear-type spells play a menacing gesture, and so on), toggled on or off as a whole with `/gabbarp anim on|off`. Always fires together with the line, never on its own separate timer.
- Death reactions: your character reacts differently depending on whether a guildmate, party/raid member, or someone else died nearby.
- Warlock Imp Backtalk: your Voidwalker/Imp/etc. occasionally talks back when nearby monsters say or yell something.
- Priest Mind Control / Mind Vision whisper: successfully casting either on an actual player also whispers them directly, on top of the normal group-facing line. Against the opposing faction, direct whispers are blocked by Blizzard, so Mind Control instead falls back to a Say translated through the optional Hermes addon if it's installed (handy for PvP), while Mind Vision is simply skipped since there's no equivalent workaround for it. Both are skipped entirely against non-player targets.
- Group greetings: a line when you join a group, and a personal welcome line for whoever joins after you.
- Spam protection you control: a per-skill cooldown, a global "minimum gap between any two lines" cooldown, and a percent chance a line actually fires once eligible, each with its own slider. Fast-recast skills (like Life Tap) automatically fall back to an "only every Nth cast" rule instead of a cooldown, so they don't go silent forever on a short timer. Every skill's editor also has its own "Reaction frequency" override: force a skill to always react (skip the cooldown/gate entirely) or to react only every Nth cast, regardless of the built-in default.
- **Optional local-language support**: off by default. Turn on "Use local language" and fill in your own translated lines (via each Edit button's Language tab) to have your character speak your guild's language instead of English when the group is mostly guildmates. Falls back to English for anything you haven't translated yet.
- Every line list is fully editable in-game: add, remove, or reset any skill's lines to default, per language.
- Export/import your entire configuration as plain text, to back it up or share it with guildmates. The **[Line Pack Builder](https://gabbajoe.github.io/GabbaRP/)** is a browser-based editor for this: write or translate lines for every skill in a proper full-size editor, then paste the generated export straight into the in-game Import box.
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
/gabbarp testdeath <name> [last words]  (simulate a Death: Guild reaction, for testing)
```

Everything else (enabling/disabling individual skills, editing lines, spam-protection sliders, local-language setup) is in **Options > AddOns > GabbaRP**.

## Known limitation: Say/Yell and mouse clicks

Blizzard requires a real click or keypress before an addon is allowed to send a Say/Yell chat message. There's no way around this. By default (**Safe** delivery), GabbaRP queues the message and sends it on your next real action (a skill or item use), so nothing gets eaten, just possibly a beat slower. A separate **Instant** delivery option in Settings trades that off for near-zero delay by capturing your very next click or keypress anywhere instead. For mouse players, that means **one click gets "eaten"** by this instead of doing what you actually clicked (e.g. your next action bar press won't register: the queued message sends instead, and the button works normally on the click after that).

This only matters if you have a skill configured to send **Say** or **Yell** specifically (Emote, the default for most skills, isn't affected) while **Instant** delivery is selected. GabbaRP shows a one-time popup at login if any of your currently enabled skills are set that way, as a reminder. Switch the skill back to Emote in the line editor, or stay on **Safe** delivery, if this bothers you.

## Get Involved

Found a skill that's missing a line, or one that should react but doesn't? Have an idea for a new feature? Open an issue on GitHub: **https://github.com/Gabbajoe/GabbaRP/issues**. Missing-skill reports are especially useful since there are hundreds of spells across 9 classes and it's easy for a niche one to slip through.

## Changelog

Latest: **v1.0.10** caches local-language guild/group lookups, eliminating repeated
full guild-roster scans during spell-trigger processing.

See [CHANGELOG.md](CHANGELOG.md) for the full version history.
