# GabbaRP Changelog

### V1.0.10

- Changed: local-language guild membership and the resulting group-language decision are
  now cached instead of rescanning the complete guild roster for every eligible spell
  trigger. Guild/group roster events only invalidate the cache; a delayed, on-demand
  rebuild coalesces bursts of roster updates without a client hitch.
- Fixed: a short-lived missing guild lookup on a newly formed group or the optional
  GreenWall confederation path is kept provisional and retried instead of being cached as
  an incorrect English result.

### V1.0.9

- Fixed: Death: Guild could silently never fire for a guildmate's death. DeathNotificationLib only reliably reports guild membership for peer-corroborated deaths; a self-reported death (the common case) left that flag unset even for an actual guildmate. Now checked live against your guild roster instead.

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
