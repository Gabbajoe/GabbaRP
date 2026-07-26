# GabbaRP — v1.0.2

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
/gabbarp testdeath <name> [last words]  (simulate a Death: Guild reaction, for testing)
```

Everything else — enabling/disabling individual skills, editing lines, spam-protection sliders, local-language setup — is in **Options > AddOns > GabbaRP**.

## Known limitation: Say/Yell and mouse clicks

Blizzard requires a real click or keypress before an addon is allowed to send a Say/Yell chat message — there's no way around this. GabbaRP works around it by queuing the message and sending it on your very next click or keypress, anywhere. For mouse players, that means **one click gets "eaten"** by this instead of doing what you actually clicked (e.g. your next action bar press won't register — the queued message sends instead, and the button works normally on the click after that).

This only matters if you have a skill configured to send **Say** or **Yell** specifically (Emote, the default for most skills, isn't affected). GabbaRP shows a one-time popup at login if any of your currently enabled skills are set that way, as a reminder. Switch the skill back to Emote in the line editor if this bothers you.

## Changelog

### V1.0.2

- New: flavor lines for five Priest racials/talent that were missing entirely — Fear Ward, Desperate Prayer, Starshards, Elune's Grace, and Inner Focus.
- New: character animations for more skills — Warrior war cries and self-buffs, Druid melee, and several CC/utility spells (Shackle Undead, Mind Control, Hunter's Mark, Distracting Shot, Faerie Fire).
- Changed: Fear, Psychic Scream, and Howl of Terror now play a menacing gesture instead of a startled one — you're the one causing the fear, not feeling it.
- Fixed: the Local Language skill list was empty for every class — it now correctly lists every skill, and Export/Import handles local-language lines properly too.
- New: a one-time login warning if you have a skill set to Say/Yell chat, explaining the click-eating behavior below.
- Fixed: removed two Priest entries that don't actually exist on this client (Shadowguard, Shadow Word: Death).
- Changed: the editor popups (Skills, Food/Drink, Death Reactions, Greetings) are now a consistent size, with no more overlapping buttons or wasted empty space.

### V1.0.1

- Fixed: a buff landing on you from someone else (another priest's Power Word: Shield, a druid's Mark of the Wild, etc.) no longer made your character react as if you had cast it yourself.
- New: `%w` placeholder in Death: Guild lines for the deceased's last words (via DeathNotificationLib) — only picked when there actually are last words to show.
- New: any line can start with `[SAY]`, `[YELL]`, or `[EMOTE]` to override the chat type for just that one line.

### V1.0

- Initial public release: automatic RP lines and emotes for all 9 classes, Death Reactions, Imp Backtalk, Group Greetings, fully in-game editable, with optional local-language support.
