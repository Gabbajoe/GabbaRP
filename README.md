# GabbaRP - v1.0.8

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

### V1.0.8

- Changed: every skill's default flavor line was rewritten. Most skills default to sending as an Emote, which prefixes your character's name, and a lot of the old lines read grammatically wrong once that name was added ("Charlie embrace the void."). All of them now read correctly as a proper third-person emote, and several use %t to actually name the target where they didn't before.
- Fixed: Export/Import silently dropped any skill set to the "Group Success" chat type, since that value was missing from the importer's list of recognized chat types.
- New: the [Line Pack Builder](https://gabbajoe.github.io/GabbaRP/), a browser-based editor for composing or translating lines for every skill, Death Reaction, and Greeting outside the game, then exporting a block that pastes straight into the in-game Import box.

### V1.0.7

- Fixed: a self-buff line (e.g. Demon Armor) could fire on its own right when zoning into an instance or through a portal, with no actual cast involved. The game can resend an "aura applied" event for a buff you already had up during a zone transition; that resync is now recognized and ignored instead of read as a fresh cast.

### V1.0.6

- New: Say/Yell reactions now have a delivery option in Settings. "Safe" (new default) waits for your next real action (a skill or item use) to send, so it never eats a click, just possibly a beat slower. "Instant" keeps the old behavior: near-zero delay, but your very next click or keypress gets swallowed.
- New: Mind Control and Mind Vision now also whisper the target directly when successfully cast on a player, on top of their normal group-facing line. Mind Control against the opposing faction falls back to a Say translated through the Hermes addon if it's installed. Mind Vision against the opposing faction is always skipped. Both are skipped entirely against non-player targets.

### V1.0.5

- Fixed: Create Soulstone reacted at the wrong moment, when you conjure the item, before you've even picked a target. It now waits for the item to actually be used on someone, which is also when the `%t` placeholder finally means something.
- Fixed: a "Group Start"/"Group Success" override on Create Soulstone (English or the local-language mirror) could go completely silent after the change above. Both are now correctly reconnected.
- New: a one-line heads-up on login if any settings were automatically adjusted for this version, instead of that happening completely invisibly.
- New: `/gabbarp triggerdebug` now also logs every combat-log event you personally trigger, not just ones the addon already recognizes. Helpful for figuring out exactly what an item or spell fires as.

### V1.0.4

- New: flavor lines for four more Warlock skills: Banish, Demon Armor (also covers Demon Skin), Unending Breath, and Detect Invisibility (also covers Detect Greater Invisibility).
- Fixed: Create Soulstone (and other rank-named skills) sometimes went completely silent, especially solo. The reaction now always fires, falling back to an emote when there's no group to announce to.
- Fixed: Shadow Trance no longer gets randomly swallowed by the spam gate. It's a rare proc already, so it now always reacts.
- New: a "Reaction frequency" section in each skill's editor: "Always react" (skip the cooldown/spam-gate) and "React every N casts", overriding the built-in defaults per character.
- Changed: the static Party/Raid chat-type buttons are gone, replaced by two dynamic types that auto-pick whichever you're in: "Group Start" (on cast start, always sent) and "Group Success" (on cast success, normal cooldown rules). Individual lines can still force a fixed Party/Raid channel with `[PARTY]`/`[RAID]`.

### V1.0.3

- Fixed: forming a group by inviting someone yourself no longer says both the generic "Join" greeting AND the personal welcome for that first invitee. If you're the group leader, only the personal welcome fires.

### V1.0.2

- New: flavor lines for five Priest racials/talent that were missing entirely: Fear Ward, Desperate Prayer, Starshards, Elune's Grace, and Inner Focus.
- New: character animations for more skills: Warrior war cries and self-buffs, Druid melee, and several CC/utility spells (Shackle Undead, Mind Control, Hunter's Mark, Distracting Shot, Faerie Fire).
- Changed: Fear, Psychic Scream, and Howl of Terror now play a menacing gesture instead of a startled one. You're the one causing the fear, not feeling it.
- Fixed: the Local Language skill list was empty for every class. It now correctly lists every skill, and Export/Import handles local-language lines properly too.
- New: a one-time login warning if you have a skill set to Say/Yell chat, explaining the click-eating behavior below.
- Fixed: removed two Priest entries that don't actually exist on this client (Shadowguard, Shadow Word: Death).
- Changed: the editor popups (Skills, Food/Drink, Death Reactions, Greetings) are now a consistent size, with no more overlapping buttons or wasted empty space.

### V1.0.1

- Fixed: a buff landing on you from someone else (another priest's Power Word: Shield, a druid's Mark of the Wild, etc.) no longer made your character react as if you had cast it yourself.
- New: `%w` placeholder in Death: Guild lines for the deceased's last words (via DeathNotificationLib), only picked when there actually are last words to show.
- New: any line can start with `[SAY]`, `[YELL]`, or `[EMOTE]` to override the chat type for just that one line.

### V1.0

- Initial public release: automatic RP lines and emotes for all 9 classes, Death Reactions, Imp Backtalk, Group Greetings, fully in-game editable, with optional local-language support.
