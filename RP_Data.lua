-- Spell name (as it appears in the combat log) -> list of flavor lines.
-- Add/edit lines here. One is picked at random each time the spell is cast successfully.
local ADDON_NAME, ns = ...

ns.GRP_Spells = {
    -- Universal (every class, triggered by the generic Food/Drink regen buff)
    ["Food"] = {
        "digs in for a bite to eat.",
        "figures a full stomach beats an empty one.",
        "takes a moment to eat something.",
        "puts the heroics on hold, food first.",
        "grabs a quick meal before getting back to it.",
    },
    ["Drink"] = {
        "takes a moment to rehydrate.",
        "downs a quick drink.",
        "stops for a drink.",
        "takes a breather with a full cup.",
        "drinks up before the next fight.",
    },
    ["Food and Drink"] = {
        "eats with one hand, drinks with the other.",
        "juggles a meal and a drink at once.",
        "takes a quick bite, then a quick sip.",
        "can't decide which is needed more, so takes both.",
        "figures a proper meal deserves a proper drink.",
    },

    -- Universal (every class, triggered by a party/raid/guild member's death)
    ["Death: Group"] = {
        "grits their teeth. lost %t today.",
        "goes quiet for a moment, then murmurs a farewell to %t.",
        "sees %t fall, and calls for the group to regroup.",
        "swears under their breath. not %t too.",
    },
    ["Death: Raid"] = {
        "bows their head for %t.",
        "falls quiet, marking %t's fall.",
        "adds %t to tonight's toll.",
        "vows, quietly, to finish this for %t.",
    },
    -- Sent as a direct GUILD chat message (not an emote), so these read as first-person
    -- speech rather than third-person narration -- the game already prefixes them with
    -- "CharName:" the same way it does for Say.
    ["Death: Guild"] = {
        "Oh no, %t is gone. Rest easy, we won't forget you.",
        "Just heard about %t... that's rough. Sending strength to everyone who knew them.",
        "Damn, %t didn't make it. They'll be missed.",
        "%t is gone. That one hurts. We'll remember you, always.",
        "Rip %t. Gone too soon.",
    },

    -- Warrior
    ["Taunt"] = {
        "waves %t over with a mocking grin.",
        "plants their feet and dares %t to come closer.",
        "roars a challenge straight at %t.",
    },
    ["Charge"] = {
        "charges in, ready or not.",
        "barrels forward, shoving everything out of the way.",
    },
    ["Intimidating Shout"] = {
        "unleashes a shout that sends %t reeling.",
        "roars until %t looks ready to break and run.",
    },
    ["Bloodrage"] = {
        "shrugs off the pain and lets it fuel the rage.",
        "spills a little of their own blood for the fury it buys.",
        "stops thinking and starts hitting harder.",
    },
    ["Battle Shout"] = {
        "rallies the group with a battle cry.",
        "bellows for everyone to hit harder.",
        "shouts for the group to show what they're made of.",
    },
    ["Demoralizing Shout"] = {
        "roars until %t starts shaking.",
        "watches %t's courage leave the battlefield.",
        "grins as fear creeps into %t.",
    },
    ["Revenge"] = {
        "answers %t with a payback strike.",
        "makes %t regret that last hit.",
        "takes their turn on %t.",
    },
    ["Bloodthirst"] = {
        "can already taste the blood.",
        "answers blood with blood.",
        "feels the thirst rise again.",
    },
    ["Death Wish"] = {
        "grins, unafraid of the end.",
        "dares death to come and see how far they'll go.",
        "welcomes the end, if it comes swinging.",
    },
    ["Rend"] = {
        "opens a wound on %t that won't close soon.",
        "leaves %t bleeding.",
        "lets the wound on %t fester.",
    },
    ["Execute"] = {
        "moves in to finish %t off.",
        "shows %t no mercy.",
        "ends it right here.",
    },
    ["Overpower"] = {
        "catches %t wide open.",
        "punishes %t for being too slow.",
        "saw that opening coming a mile away.",
    },
    ["Sunder Armor"] = {
        "cracks %t's armor open, piece by piece.",
        "finds the seam in %t's armor and pries at it.",
        "wears %t's defenses down, hit by hit.",
    },
    ["Shield Slam"] = {
        "slams a shield into %t.",
        "greets %t with a faceful of shield.",
    },
    ["Shield Bash"] = {
        "silences %t with a shield to the jaw.",
        "cuts %t's spellcasting short with a shield bash.",
    },
    ["Whirlwind"] = {
        "spins through everyone in reach.",
        "gives everybody nearby a turn.",
        "warns everyone to stay back if they value their limbs.",
    },
    ["Hamstring"] = {
        "cripples %t's leg so they can't run.",
        "slows %t down with a well-placed cut.",
    },
    ["Mocking Blow"] = {
        "taunts %t between hits. is that all they've got?",
        "goads %t to keep swinging and missing.",
    },
    ["Disarm"] = {
        "knocks the weapon clean out of %t's hands.",
        "figures %t's hands are more dangerous than their weapon anyway.",
    },
    ["Berserker Rage"] = {
        "lets the rage take hold.",
        "feeds rage with more rage.",
        "starts looking a little unhinged.",
    },
    ["Recklessness"] = {
        "throws caution to the wind.",
        "goes all in, no holding back.",
        "decides consequences are a problem for later.",
    },
    ["Shield Wall"] = {
        "hunkers down behind an unbreakable shield.",
        "dares the enemy to try and get through.",
    },
    ["Retaliation"] = {
        "promises every hit landed will be answered.",
        "dares anyone to strike and see what happens.",
    },
    ["Thunder Clap"] = {
        "slams the ground and sends a shockwave out.",
        "makes the ground itself answer.",
    },
    ["Heroic Strike"] = {
        "puts their full weight behind a heavy strike.",
        "winds up for a strike that's going to hurt.",
    },
    ["Cleave"] = {
        "swings wide, sharing the pain with everyone nearby.",
        "cuts through more than one target at once.",
    },
    ["Pummel"] = {
        "cuts %t's spell short with a solid pummel.",
        "makes sure %t doesn't get to finish that cast.",
    },

    -- Rogue
    ["Sap"] = {
        "puts %t to sleep before the fight even starts.",
        "quietly taps %t out of the fight.",
    },
    ["Vanish"] = {
        "melts into the shadows.",
        "vanishes without a trace.",
    },
    ["Kidney Shot"] = {
        "drops %t with a shot to the kidney.",
        "leaves %t staggered and stuck in place.",
    },
    ["Eviscerate"] = {
        "finishes %t off with a final, brutal cut.",
        "delivers the closing blow. nothing personal.",
    },
    ["Sinister Strike"] = {
        "strikes fast, %t barely sees it coming.",
        "moves in quick and quiet.",
    },
    ["Ambush"] = {
        "catches %t completely by surprise.",
        "strikes from the shadows before %t can react.",
    },
    ["Cheap Shot"] = {
        "figures rules are for people who fight fair.",
        "drops %t with a shot they never saw coming.",
    },
    ["Blind"] = {
        "blinds %t. can't hit what you can't see.",
        "leaves %t stumbling in sudden darkness.",
    },
    ["Evasion"] = {
        "slips out of harm's way with practiced ease.",
        "dares %t to try landing a hit now.",
    },
    ["Rupture"] = {
        "opens a wound on %t that'll keep bleeding a while.",
        "leaves %t counting down the seconds.",
    },
    ["Slice and Dice"] = {
        "picks up the pace, faster with every strike.",
        "moves with no wasted motion at all.",
    },
    ["Garrote"] = {
        "strikes from behind without a sound.",
        "silences %t before they even hear it coming.",
    },
    ["Backstab"] = {
        "drives a blade right between %t's shoulder blades.",
        "strikes from behind. %t never saw it coming.",
    },
    ["Gouge"] = {
        "buys a second with a quick gouge to %t's eyes.",
        "drops %t just long enough to make an escape.",
    },
    ["Kick"] = {
        "cuts %t's cast short with a swift kick.",
        "silences %t mid-spell.",
    },
    ["Expose Armor"] = {
        "finds the gap in %t's armor.",
        "spots the seam in %t's armor about to fail.",
    },
    ["Feint"] = {
        "slips out of sight while %t looks elsewhere.",
        "draws %t's eyes away, then disappears from view.",
    },
    ["Sprint"] = {
        "breaks into a dead sprint. catch them if you can.",
        "takes off, far too fast to follow.",
    },
    ["Cold Blood"] = {
        "steadies their hands and their mind.",
        "leaves no room for mistakes now.",
    },
    ["Adrenaline Rush"] = {
        "feels everything speed up at once.",
        "can't slow down now.",
    },
    ["Distract"] = {
        "points at nothing and %t falls for it every time.",
        "draws every eye away from where it matters.",
    },

    -- Mage
    ["Polymorph"] = {
        "turns %t into a sheep. baa, indeed.",
        "leaves %t in a much better looking wool coat.",
    },
    ["Fireball"] = {
        "hurls a fireball straight at %t.",
        "lets %t feel the heat.",
    },
    ["Frost Nova"] = {
        "freezes %t solid where they stand.",
        "tells %t to chill out, literally.",
    },
    ["Frostbolt"] = {
        "sends a cold snap straight at %t.",
        "lets the frost slow %t down.",
        "makes sure winter finds %t first.",
    },
    ["Arcane Missiles"] = {
        "lets raw arcane power do the talking.",
        "unleashes a volley straight at %t.",
    },
    ["Blink"] = {
        "blinks out of reach before %t can react.",
        "is here, then suddenly gone.",
    },
    ["Ice Block"] = {
        "seals themselves inside a block of ice.",
        "turns cold and untouchable.",
    },
    ["Counterspell"] = {
        "silences %t's spell before it finishes.",
        "shuts %t's casting down cold.",
    },
    ["Cone of Cold"] = {
        "freezes everyone standing in front of them.",
        "brings winter crashing down on the area.",
    },
    ["Evocation"] = {
        "takes a moment to draw the arcane back in.",
        "pauses to refill their reserves.",
    },
    ["Pyroblast"] = {
        "hurls a blast that's going to leave a crater.",
        "warns %t to brace for impact.",
    },
    ["Arcane Explosion"] = {
        "sends everyone nearby reeling with a burst of arcane.",
        "reminds everyone nearby that arcane doesn't discriminate.",
    },
    ["Fire Blast"] = {
        "burns %t point blank, full heat.",
        "lets loose at close range.",
    },
    ["Frost Armor"] = {
        "wraps themselves in a layer of frost.",
        "stays cold to the touch, for safety.",
    },
    ["Mana Shield"] = {
        "turns their own mana into armor.",
        "stays protected, for now, at a cost.",
    },
    ["Slow Fall"] = {
        "treats gravity as more of a suggestion.",
        "drifts down, landing gracefully as always.",
    },
    ["Conjure Food"] = {
        "conjures up a fine meal out of thin air.",
        "pulls fresh bread straight from the ether.",
    },
    ["Conjure Water"] = {
        "conjures a fresh drink out of nothing.",
        "provides hydration, courtesy of the arcane.",
    },
    ["Remove Lesser Curse"] = {
        "strips the curse right off %t.",
        "undoes what shouldn't have stuck in the first place.",
    },
    ["Dragon's Breath"] = {
        "breathes fire like a dragon at %t.",
        "hopes %t isn't afraid of flames.",
    },
    ["Scorch"] = {
        "lets %t feel a taste of what's coming.",
        "leaves %t simmering.",
    },
    ["Teleport: Stormwind"] = {
        "steps through a portal home to Stormwind.",
        "answers Stormwind's call for a quick trip.",
    },
    ["Teleport: Ironforge"] = {
        "teleports off to Ironforge.",
        "heads back to the mountain halls.",
    },
    ["Teleport: Orgrimmar"] = {
        "teleports back to Orgrimmar.",
        "heads for the horde capital.",
    },
    ["Teleport: Undercity"] = {
        "teleports back to the Undercity.",
        "slips into the shadows below.",
    },
    ["Teleport: Darnassus"] = {
        "teleports off to Darnassus.",
        "heads back among the trees.",
    },
    ["Teleport: Thunder Bluff"] = {
        "teleports off to Thunder Bluff.",
        "heads back to the plains.",
    },
    ["Portal: Stormwind"] = {
        "opens a portal to Stormwind, ready and waiting!",
        "holds a portal open, Stormwind's just on the other side!",
    },
    ["Portal: Ironforge"] = {
        "opens a portal to Ironforge, ready and waiting!",
        "holds a portal open, the mountain awaits!",
    },
    ["Portal: Orgrimmar"] = {
        "opens a portal to Orgrimmar, ready and waiting!",
        "holds a portal open, the horde capital's just ahead!",
    },
    ["Portal: Undercity"] = {
        "opens a portal to Undercity, ready and waiting!",
        "holds a portal open, the shadows are waiting!",
    },
    ["Portal: Darnassus"] = {
        "opens a portal to Darnassus, ready and waiting!",
        "holds a portal open, the trees are calling!",
    },
    ["Portal: Thunder Bluff"] = {
        "opens a portal to Thunder Bluff, ready and waiting!",
        "holds a portal open, the plains await!",
    },

    -- Priest
    ["Mind Flay"] = {
        "digs into %t's mind, uninvited.",
        "picks %t's brain, whether they like it or not.",
    },
    ["Shadow Word: Pain"] = {
        "leaves %t with a pain that's going to linger.",
    },
    ["Psychic Scream"] = {
        "unleashes a psychic scream that sends everyone reeling.",
        "conjures something wicked, right in everyone's mind.",
    },
    ["Power Word: Shield"] = {
        "wraps %t in a shield of pure light.",
        "makes sure nothing gets through to %t.",
    },
    ["Renew"] = {
        "sets a slow, steady healing on %t.",
        "lets the light keep working on %t over time.",
    },
    ["Heal"] = {
        "mends %t up with a quick prayer.",
        "leaves %t good as new.",
    },
    ["Greater Heal"] = {
        "closes the gap in %t's wounds.",
        "leaves %t feeling much better.",
    },
    ["Holy Nova"] = {
        "washes the light over everyone nearby.",
        "shares the light with the whole group.",
    },
    ["Fade"] = {
        "steps back and asks for attention elsewhere.",
        "quietly slips out of the spotlight.",
    },
    ["Smite"] = {
        "brings the light's judgment down on %t.",
        "smites %t, and rightly so.",
    },
    ["Flash Heal"] = {
        "patches %t up in a flash.",
        "mends %t as quick as the light allows.",
    },
    ["Cure Disease"] = {
        "cleanses %t's illness away.",
        "leaves %t good as new.",
    },
    ["Levitate"] = {
        "treats gravity as a suggestion, for a while.",
        "floats free for a moment.",
    },
    ["Mana Burn"] = {
        "burns straight through %t's reserves.",
        "takes %t's power for their own.",
    },
    ["Touch of Weakness"] = {
        "delivers weakness with a single touch.",
        "makes %t regret that last hit.",
    },
    ["Dispel Magic"] = {
        "strips the magic right off %t.",
        "decides that spell doesn't belong on %t anymore.",
    },
    ["Mind Blast"] = {
        "presses straight into %t's mind.",
        "lets %t feel that pushing in.",
    },
    ["Vampiric Embrace"] = {
        "turns %t's suffering into shared strength.",
        "finds a use for shared pain.",
    },
    ["Resurrection"] = {
        "calls %t back. it's not their time yet.",
        "brings %t back to their feet.",
    },
    ["Prayer of Healing"] = {
        "eases the whole group's wounds at once.",
        "makes sure the light doesn't play favorites.",
    },
    ["Power Word: Fortitude"] = {
        "bolsters %t with a word of fortitude.",
        "leaves %t standing a little stronger.",
    },
    ["Mind Vision"] = {
        "peeks through %t's eyes for a moment.",
        "borrows a glimpse of what %t sees.",
    },
    -- Dummy entries, not a real spell name -- hold the line pool for the separate
    -- whisper-to-target reaction Mind Control/Mind Vision get (see RP_Core.lua's
    -- TryTargetWhisperReaction), fired ALONGSIDE the normal group-facing line above,
    -- not instead of it. Always sent as a whisper to whoever was actually targeted, or
    -- (Mind Control against the opposing faction only) via the Hermes addon's Say
    -- translation if installed -- never a fixed chat type a user picks, so these don't
    -- get the usual "Send as" selector in the editor. Sent as an actual whisper/Say (first
    -- person speech), not an emote, so these stay first-person on purpose.
    ["Mind Vision Whisper"] = {
        "Just borrowing your eyes for a moment.",
        "Relax, I'm only looking.",
        "Didn't mean to intrude, just curious what you're up to.",
    },
    ["Divine Spirit"] = {
        "clears %t's mind and steadies their spirit.",
        "sharpens %t's focus with the light.",
    },
    ["Inner Fire"] = {
        "lets the light burn within, armored by faith.",
        "wraps themselves in the light's own armor.",
    },
    ["Shackle Undead"] = {
        "binds %t in place. even the dead answer to the light.",
        "pins %t down with a shackle of light.",
    },
    ["Mind Control"] = {
        "bends %t's will to their own, for now.",
        "makes %t do exactly as they're told.",
    },
    ["Mind Control Whisper"] = {
        "Your mind belongs to me now. Don't fight it, it's easier that way.",
        "Just do as I say, this will be over soon.",
        "Relax. Struggling only makes this worse.",
    },
    ["Holy Fire"] = {
        "sets %t burning in righteous fire.",
        "reminds %t that the light doesn't forgive.",
    },
    ["Abolish Disease"] = {
        "cleanses %t of whatever was lingering.",
        "makes sure that sickness doesn't stick around.",
    },
    ["Inner Focus"] = {
        "channels a spell that costs nothing but will.",
        "finds their focus sharpened wonderfully.",
    },
    ["Desperate Prayer"] = {
        "refuses to go down like this, not today.",
        "buys one more moment with a desperate prayer.",
    },
    ["Starshards"] = {
        "reminds %t that the stars have teeth too.",
        "silences %t, courtesy of the night sky.",
    },
    ["Elune's Grace"] = {
        "calls on Elune's grace to watch over the group.",
        "feels the goddess lending her favor.",
    },
    ["Fear Ward"] = {
        "makes sure no fear finds purchase here.",
        "steadies the group. nothing can shake them now.",
    },

    -- Warlock
    ["Fear"] = {
        "sends %t running in blind terror.",
        "watches %t's nightmares begin.",
        "makes sure %t knows fleeing won't save them.",
    },
    ["Corruption"] = {
        "sets %t rotting from the inside out.",
        "lets the decay take hold of %t.",
        "turns %t's own flesh against them.",
    },
    ["Curse of Agony"] = {
        "curses %t with a long, painful minute.",
        "makes sure %t suffers slowly.",
        "stretches every second into an eternity for %t.",
    },
    ["Curse of Weakness"] = {
        "curses %t's strength away.",
        "leaves %t feeble in their presence.",
    },
    ["Curse of Recklessness"] = {
        "curses %t's guard right off them.",
        "leaves %t's carelessness to be their undoing.",
    },
    ["Curse of Tongues"] = {
        "curses %t's tongue to twist and fail.",
        "makes sure %t's incantations mean nothing now.",
    },
    ["Curse of Elements"] = {
        "curses %t, exposed before all magic now.",
        "makes every spell that touches %t burn twice as hard.",
    },
    ["Curse of Shadow"] = {
        "lets the shadows find every crack in %t's defenses.",
        "seeps darkness into %t's very bones.",
    },
    ["Curse of Doom"] = {
        "curses %t. their time is running out.",
        "gives %t one minute, and not a second more.",
    },
    ["Shadow Bolt"] = {
        "hurls a bolt of shadow at %t.",
        "lets the void's touch find %t.",
        "sends darkness straight at %t.",
        "delivers a gift from the shadows to %t.",
        "leaves no light where %t is headed.",
        "calls a bolt from the abyss down on %t.",
    },
    ["Shadow Trance"] = {
        -- Procs from the Nightfall talent (free, instant Shadow Bolt)
        "feels the shadows favor them.",
        "takes the free power without a second thought.",
        "grins as the void smiles upon them.",
        "watches nightfall strike right on cue.",
    },
    ["Immolate"] = {
        "sets %t ablaze with unholy fire.",
        "lets the flames of the abyss cleanse %t.",
    },
    ["Drain Life"] = {
        "drains the life straight out of %t.",
        "takes %t's life for their own.",
    },
    ["Drain Soul"] = {
        "pulls %t's soul toward the void.",
        "feels %t's essence slipping away.",
    },
    ["Death Coil"] = {
        "gives %t a taste of death itself.",
        "wraps %t in a cold, deathly embrace.",
    },
    ["Life Tap"] = {
        "trades a little pain for a lot of power.",
        "borrows strength from their own blood.",
        "pays power's price without hesitation.",
        "drains themselves a little to keep going.",
    },
    ["Howl of Terror"] = {
        "lets loose a howl of true horror.",
        "invites everyone to witness true terror.",
    },
    ["Banish"] = {
        "banishes %t somewhere this world can't reach.",
        "sends %t out of sight, out of reach, for now.",
    },
    -- Demon Skin and Demon Armor are the same spell, just the low- and high-rank
    -- names -- shares one line pool/config under the higher-rank name (see
    -- RP_Core.lua's combat-log dispatch, which normalizes "Demon Skin" to this key)
    -- instead of splitting reactions across two effectively-identical entries.
    ["Demon Armor"] = {
        "wraps themselves in the demon's own hide.",
        "armors up, courtesy of the abyss.",
    },
    ["Unending Breath"] = {
        "decides drowning is someone else's problem today.",
        "breathes easy, the void doesn't need air either.",
    },
    -- Detect Invisibility and Detect Greater Invisibility are the same spell, just the
    -- low- and high-rank names -- shares one line pool/config under the base name (see
    -- RP_Core.lua's combat-log dispatch, which normalizes "Detect Greater Invisibility"
    -- to this key) instead of splitting reactions across two effectively-identical
    -- entries, same as Demon Armor/Demon Skin above.
    ["Detect Invisibility"] = {
        "sees through every hiding spell nearby.",
        "notices what wanted to stay hidden.",
    },
    ["Rain of Fire"] = {
        "brings the sky down in flame.",
        "rains hellfire down on everyone below.",
    },
    ["Hellfire"] = {
        "burns everyone nearby, themselves included.",
        "lets the abyss consume everything in reach.",
    },
    ["Searing Pain"] = {
        "leaves %t burning with torment.",
    },
    ["Summon Imp"] = {
        "calls their imp forth to serve.",
    },
    -- Split by which real Imp voice line it's talking back to (see ns.GRP_ImpQuotePatterns
    -- below) instead of one generic bucket for any Imp chatter. %t is replaced with your
    -- Imp's name.
    ["Imp: Attack"] = {
        "tells %t that if this is the last one, they had better make it count.",
        "orders %t to back them up instead of standing around uselessly.",
        "tells %t to stop complaining and start helping.",
        "reminds %t that they were summoned to fight, not to make demands.",
        "tells %t that if the imp can handle it, so can they.",
        "demands that %t make themselves useful for once.",
        "tells %t to keep up before the imp has to do all the work.",
        "assures %t that this is absolutely the last one, until the next one.",
    },
    ["Imp: Order"] = {
        "tells %t to stop yelling, the imp is already doing all the work.",
        "reminds %t that repeating the order will not make it more intelligent.",
        "asks %t if they really need help with something this pathetic.",
        "tells %t to keep shouting while the imp handles the actual fighting.",
        "agrees to go, since apparently %t cannot do anything alone.",
        "tells %t to calm down before they embarrass themselves further.",
        "reminds %t that obedience does not require constant supervision.",
        "tells %t that the imp heard them the first time, unlike the enemy.",
    },
    ["Imp: Dismiss"] = {
        "tells %t not to sound so desperate, they will be summoned again soon enough.",
        "releases %t and reminds them that the void is not an escape.",
        "tells %t to enjoy the silence while it lasts.",
        "sends %t back to the void and promises to summon them again at the worst possible moment.",
        "ignores %t's complaints and dismisses them anyway.",
        "agrees that they have both had enough of each other.",
        "tells %t that their dramatic exit was not nearly as impressive as they thought.",
        "warns %t that being dismissed is the closest thing they will get to a vacation.",
        "sends %t away before the complaining becomes even more unbearable.",
        "tells %t to stop whining and wait in the void like a good little demon.",
    },
    -- Fallback for when the Imp mutters something in Demonic instead of Common/Orcish --
    -- doesn't match any of the categories above, so this fires instead of staying silent.
    ["Imp: Gibberish"] = {
        "tells %t to speak Common before anyone mistakes that for an actual argument.",
        "admits they do not speak Demonic and tells %t to try again.",
        "tells %t to keep the demonic babbling to themselves.",
        "asks %t whether they are casting a spell or simply complaining.",
        "tells %t that none of that makes any sense, even by demonic standards.",
        "reminds %t that speaking louder in Demonic will not make it more understandable.",
        "tells %t to stop mumbling and use words everyone can understand.",
        "notes that %t is babbling again and pretends not to notice.",
        "tells %t that if they have something useful to say, they should say it in Common.",
        "assumes %t is complaining and tells them to get back to work.",
    },
    ["Summon Voidwalker"] = {
        "calls a voidwalker forth to serve.",
    },
    ["Summon Succubus"] = {
        "calls a succubus forth to serve.",
    },
    ["Summon Felhunter"] = {
        "calls a felhunter forth to hunt.",
    },
    ["Ritual of Summoning"] = {
        -- %t is replaced with the name of the summoned player
        "opening a portal for %t — step through when you're ready!",
        "the gateway is open for %t, come on through!",
        "summoning circle complete, get ready to step in, %t!",
    },
    -- Soulstone is functionally decorative in Hardcore (a real death is permanent, no
    -- resurrection), so these lean into the futility of the gesture rather than pretending
    -- it's a real safety net. %t is replaced with whoever receives the soulstone. Bypasses
    -- the global spam gate the same way Imp/Death reactions do (see TriggerLine) -- giving
    -- someone a soulstone is rare and deliberate, never spammy.
    ["Create Soulstone"] = {
        "hands %t a Soulstone. Not that it'll do any good when they actually die.",
        "gives %t a Soulstone. Hardcore doesn't care, but feel free to pretend it matters.",
        "presses one freshly cursed, completely useless Soulstone into %t's hand.",
        "hands it over. It's basically just an expensive rock with false advertising.",
        "tells %t to enjoy the Soulstone, and save the tears for when it fails to save them.",
        "hands over a Soulstone that won't save %t, but at least it looks reassuring.",
        "gives %t a second chance that Hardcore will politely ignore.",
        "delivers one Soulstone. Completely useless, but very comforting.",
        "insures %t's soul. Unfortunately, Hardcore does not honor the policy.",
        "hands it over, in case the rules suddenly stop mattering.",
        "traps %t's soul in a stone. Shame it won't help in Hardcore.",
        "finishes the Soulstone. %t's survival still depends on not dying.",
        "calls it a decorative resurrection device, and means it.",
        "hands over a Soulstone with one job and no chance of doing it.",
        "reminds %t that in Hardcore, death is still permanent, theory or not.",
        "stores %t's soul safely. Sadly, not their character's future.",
        "compares the Soulstone to a parachute at the bottom of the ocean.",
        "hands out one complimentary Soulstone. No refunds, no resurrection, no miracles.",
        "gives %t a Soulstone, and wishes there were a game mode that let it matter.",
        "applies the Soulstone, and reminds %t that Hardcore considers death a permanent feature.",
    },

    -- Hunter
    ["Concussive Shot"] = {
        "slows %t down with a concussive shot.",
        "makes sure %t isn't going anywhere fast.",
    },
    ["Multi-Shot"] = {
        "fires a volley, everybody gets one.",
    },
    ["Aspect of the Monkey"] = {
        "channels the monkey's own agility.",
    },
    ["Aimed Shot"] = {
        "steadies, aims, and lets loose.",
        "makes the one shot count.",
    },
    ["Arcane Shot"] = {
        "lets the arrow do the talking.",
        "fires off a quick, clean shot.",
    },
    ["Serpent Sting"] = {
        "leaves %t with venom just getting started.",
        "lets the sting work its way through %t.",
    },
    ["Wing Clip"] = {
        "clips %t's wings. not going anywhere now.",
        "slows %t right down.",
    },
    ["Freezing Trap"] = {
        "springs a trap, freezing %t solid.",
        "asks %t, politely, to step right there.",
    },
    ["Explosive Trap"] = {
        "sets an explosive trap and waits.",
        "warns everyone to watch their step.",
    },
    ["Feign Death"] = {
        "drops to the ground, playing dead.",
        "isn't really dead, just patient.",
    },
    ["Distracting Shot"] = {
        "fires a shot to pull every eye onto themselves.",
        "makes sure the enemy's watching them, not the group.",
    },
    ["Raptor Strike"] = {
        "strikes quick and sharp.",
        "hits without a moment's hesitation.",
    },
    ["Mongoose Bite"] = {
        "strikes faster than %t would think.",
        "finds the opening and bites down.",
    },
    ["Hunter's Mark"] = {
        "marks %t. there's no losing them now.",
        "makes sure %t can't escape notice.",
    },
    ["Aspect of the Hawk"] = {
        "sharpens their aim with the hawk's own eyes.",
        "lets the hawk guide every shot now.",
    },
    ["Aspect of the Cheetah"] = {
        "builds for speed, faster than anything can catch.",
    },
    ["Tranquilizing Shot"] = {
        "calms %t down with a tranquilizing shot.",
        "takes the rage right out of %t.",
    },
    ["Scare Beast"] = {
        "sends the beast running, little and afraid.",
        "makes sure there's nothing left to see here.",
    },

    -- Paladin
    ["Hammer of Justice"] = {
        "brings the hammer of justice down on %t.",
        "lets %t feel the hammer.",
    },
    ["Judgement"] = {
        "passes judgement on %t.",
    },
    ["Holy Light"] = {
        "lets the light mend %t.",
        "delivers healing, as promised.",
    },
    ["Flash of Light"] = {
        "patches %t up, just enough to keep them standing.",
        "delivers a quick flash of healing light.",
    },
    ["Consecration"] = {
        "hallows the ground beneath their feet.",
        "makes sure nothing unholy stands here.",
    },
    ["Exorcism"] = {
        "casts %t out. the light has no patience for their kind.",
        "banishes what shouldn't be here.",
    },
    ["Seal of Righteousness"] = {
        "lets righteousness guide their hand.",
        "blesses every strike to come.",
    },
    ["Seal of Command"] = {
        "delivers what the light commands.",
        "warns %t to obey, or face the consequences.",
    },
    ["Blessing of Might"] = {
        "grants strength, courtesy of the light.",
        "makes sure %t hits harder now.",
    },
    ["Blessing of Wisdom"] = {
        "shares the light's own wisdom with %t.",
        "grants %t clarity and power both.",
    },
    ["Blessing of Protection"] = {
        "makes sure nothing touches %t now.",
        "shields %t, for a while.",
    },
    ["Divine Shield"] = {
        "becomes untouchable, if only briefly.",
        "lets the light surround them completely.",
    },
    ["Divine Protection"] = {
        "lets the light soften the next blow.",
        "stays protected, but not invincible.",
    },
    ["Lay on Hands"] = {
        "gives everything they have, freely.",
        "shows exactly what devotion looks like.",
    },
    ["Cleanse"] = {
        "burns the affliction off %t with the light.",
        "leaves %t purified.",
    },
    ["Redemption"] = {
        "calls %t back. their story isn't over.",
        "brings %t back with the light's own call.",
    },
    ["Turn Undead"] = {
        "sends %t fleeing, rejected by the light.",
        "orders %t away, creature of darkness.",
    },

    -- Shaman
    ["Earth Shock"] = {
        "lets %t feel the earth's fury.",
    },
    ["Lightning Bolt"] = {
        "calls down a bolt of lightning on %t.",
        "lets the sky answer their call.",
    },
    ["Chain Lightning"] = {
        "lets the bolt jump from target to target.",
        "spreads one strike across plenty of targets.",
    },
    ["Frost Shock"] = {
        "locks %t in place with a shock of frost.",
        "asks %t if that's cold enough for them.",
    },
    ["Flame Shock"] = {
        "leaves %t burning a while longer.",
        "lets the fire linger on %t.",
    },
    ["Healing Wave"] = {
        "lets the spirits mend %t.",
        "sends healing waters over %t.",
    },
    ["Lesser Healing Wave"] = {
        "sends just enough healing to keep %t up.",
        "delivers a small but welcome mend.",
    },
    ["Purge"] = {
        "strips magic off %t that doesn't belong there.",
        "cleanses %t of borrowed power.",
    },
    ["Windfury Weapon"] = {
        "lets the wind guide every strike now.",
        "calls on the spirits to favor this blade.",
    },
    ["Stoneskin Totem"] = {
        "plants a totem, steady as stone.",
        "lets the earth protect the group.",
    },
    ["Earthbind Totem"] = {
        "plants a totem that roots everyone nearby in place.",
    },
    ["Tremor Totem"] = {
        "plants a totem to steady every fear.",
        "lets the earth calm the mind.",
    },
    ["Grounding Totem"] = {
        "plants a totem to redirect the next spell their way.",
    },
    ["Healing Stream Totem"] = {
        "plants a totem, letting healing waters flow.",
    },
    ["Fire Nova Totem"] = {
        "plants a totem and lets the earth erupt.",
        "warns everyone back before the totem goes off.",
    },
    ["Astral Recall"] = {
        "answers the call of home.",
        "lets the spirits guide them back.",
    },
    ["Ghost Wolf"] = {
        "shifts into a ghost wolf, swift as the spirits allow.",
    },

    -- Druid
    ["Entangling Roots"] = {
        "roots %t in place. stuck, are they?",
    },
    ["Bash"] = {
        "sends %t down with a heavy bash.",
    },
    ["Moonfire"] = {
        "marks %t with the moon's own light.",
        "lets the light burn into %t.",
    },
    ["Wrath"] = {
        "aims nature's fury straight at %t.",
        "reminds %t the wilds don't forgive.",
    },
    ["Starfire"] = {
        "calls the stars down on %t.",
        "lets the light fall on %t.",
    },
    ["Rejuvenation"] = {
        "lets nature do its slow, steady work on %t.",
    },
    ["Regrowth"] = {
        "lets life find a way, quickly, for %t.",
        "knits %t's wounds back together.",
    },
    ["Healing Touch"] = {
        "lets the wilds mend %t.",
        "provides what nature always does.",
    },
    ["Rebirth"] = {
        "calls %t back. not done yet, rise.",
        "grants %t one more chance from nature itself.",
    },
    ["Hibernate"] = {
        "lulls %t into a deep, quiet sleep.",
    },
    ["Faerie Fire"] = {
        "marks %t with faerie fire. can't hide from that.",
    },
    ["Thorns"] = {
        "warns %t to be careful, nature bites back.",
    },
    ["Mark of the Wild"] = {
        "lets %t carry the wild with them now.",
        "grants %t the wilds' own favor.",
    },
    ["Innervate"] = {
        "lends %t a burst of the wilds' own energy.",
    },
    ["Nature's Grasp"] = {
        "lets the earth itself hold %t back.",
        "finds %t caught fast by roots.",
    },
    ["Barkskin"] = {
        "toughens their hide, hard as bark.",
    },
    ["Maul"] = {
        "swings claws first, questions later.",
        "leaves %t with a mark that'll stay.",
    },
    ["Claw"] = {
        "strikes sharp and quick.",
    },
    ["Rip"] = {
        "tears a wound into %t that won't close soon.",
        "leaves %t bleeding freely.",
    },
    ["Ferocious Bite"] = {
        "finishes %t off the feral way, all teeth, no mercy.",
    },
}

-- Maps each skill/trigger to a class so the options menu only shows the
-- entries relevant to your current class. "ALL" shows up for every class.
ns.GRP_SpellClass = {
    ["Food"] = "ALL",
    ["Drink"] = "ALL",
    ["Food and Drink"] = "ALL",
    ["Death: Group"] = "ALL",
    ["Death: Raid"] = "ALL",
    ["Death: Guild"] = "ALL",

    ["Taunt"] = "WARRIOR",
    ["Charge"] = "WARRIOR",
    ["Intimidating Shout"] = "WARRIOR",
    ["Bloodrage"] = "WARRIOR",
    ["Battle Shout"] = "WARRIOR",
    ["Demoralizing Shout"] = "WARRIOR",
    ["Revenge"] = "WARRIOR",
    ["Bloodthirst"] = "WARRIOR",
    ["Death Wish"] = "WARRIOR",
    ["Rend"] = "WARRIOR",
    ["Execute"] = "WARRIOR",
    ["Overpower"] = "WARRIOR",
    ["Sunder Armor"] = "WARRIOR",
    ["Shield Slam"] = "WARRIOR",
    ["Shield Bash"] = "WARRIOR",
    ["Whirlwind"] = "WARRIOR",
    ["Hamstring"] = "WARRIOR",
    ["Mocking Blow"] = "WARRIOR",
    ["Disarm"] = "WARRIOR",
    ["Berserker Rage"] = "WARRIOR",
    ["Recklessness"] = "WARRIOR",
    ["Shield Wall"] = "WARRIOR",
    ["Retaliation"] = "WARRIOR",
    ["Thunder Clap"] = "WARRIOR",
    ["Heroic Strike"] = "WARRIOR",
    ["Cleave"] = "WARRIOR",
    ["Pummel"] = "WARRIOR",

    ["Sap"] = "ROGUE",
    ["Vanish"] = "ROGUE",
    ["Kidney Shot"] = "ROGUE",
    ["Eviscerate"] = "ROGUE",
    ["Sinister Strike"] = "ROGUE",
    ["Ambush"] = "ROGUE",
    ["Cheap Shot"] = "ROGUE",
    ["Blind"] = "ROGUE",
    ["Evasion"] = "ROGUE",
    ["Rupture"] = "ROGUE",
    ["Slice and Dice"] = "ROGUE",
    ["Garrote"] = "ROGUE",
    ["Backstab"] = "ROGUE",
    ["Gouge"] = "ROGUE",
    ["Kick"] = "ROGUE",
    ["Expose Armor"] = "ROGUE",
    ["Feint"] = "ROGUE",
    ["Sprint"] = "ROGUE",
    ["Cold Blood"] = "ROGUE",
    ["Adrenaline Rush"] = "ROGUE",
    ["Distract"] = "ROGUE",

    ["Polymorph"] = "MAGE",
    ["Fireball"] = "MAGE",
    ["Frost Nova"] = "MAGE",
    ["Frostbolt"] = "MAGE",
    ["Arcane Missiles"] = "MAGE",
    ["Blink"] = "MAGE",
    ["Ice Block"] = "MAGE",
    ["Counterspell"] = "MAGE",
    ["Cone of Cold"] = "MAGE",
    ["Evocation"] = "MAGE",
    ["Pyroblast"] = "MAGE",
    ["Arcane Explosion"] = "MAGE",
    ["Fire Blast"] = "MAGE",
    ["Frost Armor"] = "MAGE",
    ["Mana Shield"] = "MAGE",
    ["Slow Fall"] = "MAGE",
    ["Conjure Food"] = "MAGE",
    ["Conjure Water"] = "MAGE",
    ["Remove Lesser Curse"] = "MAGE",
    ["Dragon's Breath"] = "MAGE",
    ["Scorch"] = "MAGE",
    ["Teleport: Stormwind"] = "MAGE",
    ["Teleport: Ironforge"] = "MAGE",
    ["Teleport: Orgrimmar"] = "MAGE",
    ["Teleport: Undercity"] = "MAGE",
    ["Teleport: Darnassus"] = "MAGE",
    ["Teleport: Thunder Bluff"] = "MAGE",
    ["Portal: Stormwind"] = "MAGE",
    ["Portal: Ironforge"] = "MAGE",
    ["Portal: Orgrimmar"] = "MAGE",
    ["Portal: Undercity"] = "MAGE",
    ["Portal: Darnassus"] = "MAGE",
    ["Portal: Thunder Bluff"] = "MAGE",

    ["Mind Flay"] = "PRIEST",
    ["Shadow Word: Pain"] = "PRIEST",
    ["Psychic Scream"] = "PRIEST",
    ["Power Word: Shield"] = "PRIEST",
    ["Renew"] = "PRIEST",
    ["Heal"] = "PRIEST",
    ["Greater Heal"] = "PRIEST",
    ["Holy Nova"] = "PRIEST",
    ["Fade"] = "PRIEST",
    ["Smite"] = "PRIEST",
    ["Flash Heal"] = "PRIEST",
    ["Cure Disease"] = "PRIEST",
    ["Levitate"] = "PRIEST",
    ["Mana Burn"] = "PRIEST",
    ["Touch of Weakness"] = "PRIEST",
    ["Dispel Magic"] = "PRIEST",
    ["Mind Blast"] = "PRIEST",
    ["Vampiric Embrace"] = "PRIEST",
    ["Resurrection"] = "PRIEST",
    ["Prayer of Healing"] = "PRIEST",
    ["Power Word: Fortitude"] = "PRIEST",
    ["Mind Vision"] = "PRIEST",
    ["Mind Vision Whisper"] = "PRIEST",
    ["Mind Vision Whisper (LOCAL)"] = "PRIEST",
    ["Divine Spirit"] = "PRIEST",
    ["Inner Fire"] = "PRIEST",
    ["Shackle Undead"] = "PRIEST",
    ["Mind Control"] = "PRIEST",
    ["Mind Control Whisper"] = "PRIEST",
    ["Mind Control Whisper (LOCAL)"] = "PRIEST",
    ["Holy Fire"] = "PRIEST",
    ["Abolish Disease"] = "PRIEST",
    ["Inner Focus"] = "PRIEST",
    ["Desperate Prayer"] = "PRIEST",
    ["Starshards"] = "PRIEST",
    ["Elune's Grace"] = "PRIEST",
    ["Fear Ward"] = "PRIEST",

    ["Fear"] = "WARLOCK",
    ["Corruption"] = "WARLOCK",
    ["Curse of Agony"] = "WARLOCK",
    ["Curse of Weakness"] = "WARLOCK",
    ["Curse of Recklessness"] = "WARLOCK",
    ["Curse of Tongues"] = "WARLOCK",
    ["Curse of Elements"] = "WARLOCK",
    ["Curse of Shadow"] = "WARLOCK",
    ["Curse of Doom"] = "WARLOCK",
    ["Shadow Bolt"] = "WARLOCK",
    ["Shadow Trance"] = "WARLOCK",
    ["Immolate"] = "WARLOCK",
    ["Drain Life"] = "WARLOCK",
    ["Drain Soul"] = "WARLOCK",
    ["Death Coil"] = "WARLOCK",
    ["Life Tap"] = "WARLOCK",
    ["Howl of Terror"] = "WARLOCK",
    ["Banish"] = "WARLOCK",
    ["Demon Armor"] = "WARLOCK",
    ["Unending Breath"] = "WARLOCK",
    ["Detect Invisibility"] = "WARLOCK",
    ["Rain of Fire"] = "WARLOCK",
    ["Hellfire"] = "WARLOCK",
    ["Searing Pain"] = "WARLOCK",
    ["Summon Imp"] = "WARLOCK",
    ["Imp: Attack"] = "WARLOCK",
    ["Imp: Order"] = "WARLOCK",
    ["Imp: Dismiss"] = "WARLOCK",
    ["Imp: Gibberish"] = "WARLOCK",
    ["Create Soulstone"] = "WARLOCK",
    ["Summon Voidwalker"] = "WARLOCK",
    ["Summon Succubus"] = "WARLOCK",
    ["Summon Felhunter"] = "WARLOCK",
    ["Ritual of Summoning"] = "WARLOCK",

    ["Concussive Shot"] = "HUNTER",
    ["Multi-Shot"] = "HUNTER",
    ["Aspect of the Monkey"] = "HUNTER",
    ["Aimed Shot"] = "HUNTER",
    ["Arcane Shot"] = "HUNTER",
    ["Serpent Sting"] = "HUNTER",
    ["Wing Clip"] = "HUNTER",
    ["Freezing Trap"] = "HUNTER",
    ["Explosive Trap"] = "HUNTER",
    ["Feign Death"] = "HUNTER",
    ["Distracting Shot"] = "HUNTER",
    ["Raptor Strike"] = "HUNTER",
    ["Mongoose Bite"] = "HUNTER",
    ["Hunter's Mark"] = "HUNTER",
    ["Aspect of the Hawk"] = "HUNTER",
    ["Aspect of the Cheetah"] = "HUNTER",
    ["Tranquilizing Shot"] = "HUNTER",
    ["Scare Beast"] = "HUNTER",

    ["Hammer of Justice"] = "PALADIN",
    ["Judgement"] = "PALADIN",
    ["Holy Light"] = "PALADIN",
    ["Flash of Light"] = "PALADIN",
    ["Consecration"] = "PALADIN",
    ["Exorcism"] = "PALADIN",
    ["Seal of Righteousness"] = "PALADIN",
    ["Seal of Command"] = "PALADIN",
    ["Blessing of Might"] = "PALADIN",
    ["Blessing of Wisdom"] = "PALADIN",
    ["Blessing of Protection"] = "PALADIN",
    ["Divine Shield"] = "PALADIN",
    ["Divine Protection"] = "PALADIN",
    ["Lay on Hands"] = "PALADIN",
    ["Cleanse"] = "PALADIN",
    ["Redemption"] = "PALADIN",
    ["Turn Undead"] = "PALADIN",

    ["Earth Shock"] = "SHAMAN",
    ["Lightning Bolt"] = "SHAMAN",
    ["Chain Lightning"] = "SHAMAN",
    ["Frost Shock"] = "SHAMAN",
    ["Flame Shock"] = "SHAMAN",
    ["Healing Wave"] = "SHAMAN",
    ["Lesser Healing Wave"] = "SHAMAN",
    ["Purge"] = "SHAMAN",
    ["Windfury Weapon"] = "SHAMAN",
    ["Stoneskin Totem"] = "SHAMAN",
    ["Earthbind Totem"] = "SHAMAN",
    ["Tremor Totem"] = "SHAMAN",
    ["Grounding Totem"] = "SHAMAN",
    ["Healing Stream Totem"] = "SHAMAN",
    ["Fire Nova Totem"] = "SHAMAN",
    ["Astral Recall"] = "SHAMAN",
    ["Ghost Wolf"] = "SHAMAN",

    ["Entangling Roots"] = "DRUID",
    ["Bash"] = "DRUID",
    ["Moonfire"] = "DRUID",
    ["Wrath"] = "DRUID",
    ["Starfire"] = "DRUID",
    ["Rejuvenation"] = "DRUID",
    ["Regrowth"] = "DRUID",
    ["Healing Touch"] = "DRUID",
    ["Rebirth"] = "DRUID",
    ["Hibernate"] = "DRUID",
    ["Faerie Fire"] = "DRUID",
    ["Thorns"] = "DRUID",
    ["Mark of the Wild"] = "DRUID",
    ["Innervate"] = "DRUID",
    ["Nature's Grasp"] = "DRUID",
    ["Barkskin"] = "DRUID",
    ["Maul"] = "DRUID",
    ["Claw"] = "DRUID",
    ["Rip"] = "DRUID",
    ["Ferocious Bite"] = "DRUID",
}

-- Optional: for very frequently cast skills (e.g. Life Tap) the normal time
-- cooldown isn't enough. Here you can instead set "only every Nth cast triggers".
ns.GRP_SpellInterval = {
    ["Life Tap"] = 2,
    -- Rage dumps/combo builders/fillers spammed far more often than the per-skill
    -- cooldown window -- "every Nth cast" instead of a timer, same reasoning as Life Tap.
    ["Heroic Strike"] = 3,
    ["Cleave"] = 3,
    ["Sunder Armor"] = 2,
    ["Sinister Strike"] = 3,
    ["Backstab"] = 3,
    ["Scorch"] = 2,
    ["Fireball"] = 2,
    ["Frostbolt"] = 2,
    ["Shadow Bolt"] = 2,
    ["Flash Heal"] = 3,
    ["Smite"] = 2,
    ["Arcane Shot"] = 2,
    ["Lightning Bolt"] = 2,
    ["Lesser Healing Wave"] = 3,
    ["Claw"] = 3,
    ["Rejuvenation"] = 2,
}

-- The opposite problem: spells that should always get a reaction, bypassing the
-- global gate's random triggerChance/cooldown entirely (same reasoning as the
-- hardcoded Imp:/Death: bypass in RP_Core.lua's PassesGlobalGate check) -- typically
-- because the spell itself is already a rare RNG proc, so subjecting it to an
-- additional random chance on top would mean its reaction rarely ever shows at all.
ns.GRP_SkipGlobalGate = {
    ["Shadow Trance"] = true,
}

-- How each skill's line gets sent, when it fires: "EMOTE" (/me, third person, e.g. "casts
-- a shadow bolt"), "SAY"/"PARTY"/"RAID" (a direct first-person line, e.g. "watch out!"),
-- or "GROUP_ANNOUNCE" -- a special case that bypasses /gabba rp mode entirely: it fires on
-- cast START (not success) and is always sent to party/raid, e.g. so the group knows a
-- summon is coming before the (long) cast finishes. Spells not listed default to "EMOTE".
-- Overridable per character in GabbaRPCharDB.rp.customChatType via the line editor UI.
ns.GRP_SpellChatType = {
    ["Ritual of Summoning"] = "GROUP_ANNOUNCE",
    -- Portals are cast FOR the group, same reasoning as Ritual of Summoning -- worth
    -- announcing the moment it's up rather than only commenting to yourself. Teleports
    -- are self-only, so those stay on the "EMOTE" default instead.
    ["Portal: Stormwind"] = "GROUP_ANNOUNCE",
    ["Portal: Ironforge"] = "GROUP_ANNOUNCE",
    ["Portal: Orgrimmar"] = "GROUP_ANNOUNCE",
    ["Portal: Undercity"] = "GROUP_ANNOUNCE",
    ["Portal: Darnassus"] = "GROUP_ANNOUNCE",
    ["Portal: Thunder Bluff"] = "GROUP_ANNOUNCE",
    -- A guildmate's death is guild-wide news, not just a private reaction -- defaults to
    -- actually posting in guild chat instead of just an emote only nearby players see.
    ["Death: Guild"] = "GUILD",
}

-- Optional: matching Blizzard emote animation token (see /emote list) for a spell.
-- Only fill in ones you're sure exist in-game, otherwise leave the spell out of this table
-- (the flavor line will still fire, just without a character animation).
ns.GRP_EmoteTokens = {
    ["Taunt"] = "TAUNT",
    ["Charge"] = "CHARGE",
    ["Vanish"] = "SNEAK",
    -- THREATEN, not BOGGLE -- these are cast FROM the caster's perspective (they're
    -- instilling the fear, not experiencing it), so a menacing/intimidating gesture fits
    -- better than a startled one.
    ["Fear"] = "THREATEN",
    ["Psychic Scream"] = "THREATEN",
    ["Howl of Terror"] = "THREATEN",
    ["Death: Group"] = "MOURN",
    ["Death: Raid"] = "MOURN",
    ["Death: Guild"] = "MOURN",
    -- Aggressive Warrior shouts, from the caster's own perspective (see the THREATEN note
    -- above) -- a battle roar fits a Warrior riling themselves or the enemy up.
    ["Berserker Rage"] = "ROAR",
    ["Bloodrage"] = "ROAR",
    ["Death Wish"] = "ROAR",
    ["Intimidating Shout"] = "ROAR",
    ["Demoralizing Shout"] = "ROAR",
    ["Recklessness"] = "FLEX",
    ["Retaliation"] = "FLEX",
    ["Shield Wall"] = "FLEX",
    -- CC/utility spells that target someone specific -- a pointing gesture fits the act
    -- of singling that target out.
    ["Shackle Undead"] = "POINT",
    ["Mind Control"] = "POINT",
    ["Hunter's Mark"] = "POINT",
    ["Distracting Shot"] = "POINT",
    ["Faerie Fire"] = "POINT",
    ["Banish"] = "POINT",
    -- Druid melee (Bear/Cat form) -- a roar fits the ferocity.
    ["Bash"] = "ROAR",
    ["Maul"] = "ROAR",
    ["Claw"] = "ROAR",
    ["Rip"] = "ROAR",
    ["Ferocious Bite"] = "ROAR",

    -- Local-language (LOCAL) mirrors -- same animations as their English counterparts
    -- above. ResolveSpellKey can hand TriggerLine a "(LOCAL)"-suffixed spellName, and this
    -- table is looked up by that exact key, so every entry above needs one of these or the
    -- animation silently doesn't play for a local-language cast.
    ["Taunt (LOCAL)"] = "TAUNT",
    ["Charge (LOCAL)"] = "CHARGE",
    ["Vanish (LOCAL)"] = "SNEAK",
    ["Fear (LOCAL)"] = "THREATEN",
    ["Psychic Scream (LOCAL)"] = "THREATEN",
    ["Howl of Terror (LOCAL)"] = "THREATEN",
    ["Death: Group (LOCAL)"] = "MOURN",
    ["Death: Raid (LOCAL)"] = "MOURN",
    ["Death: Guild (LOCAL)"] = "MOURN",
    ["Berserker Rage (LOCAL)"] = "ROAR",
    ["Bloodrage (LOCAL)"] = "ROAR",
    ["Death Wish (LOCAL)"] = "ROAR",
    ["Intimidating Shout (LOCAL)"] = "ROAR",
    ["Demoralizing Shout (LOCAL)"] = "ROAR",
    ["Recklessness (LOCAL)"] = "FLEX",
    ["Retaliation (LOCAL)"] = "FLEX",
    ["Shield Wall (LOCAL)"] = "FLEX",
    ["Shackle Undead (LOCAL)"] = "POINT",
    ["Mind Control (LOCAL)"] = "POINT",
    ["Hunter's Mark (LOCAL)"] = "POINT",
    ["Distracting Shot (LOCAL)"] = "POINT",
    ["Faerie Fire (LOCAL)"] = "POINT",
    ["Bash (LOCAL)"] = "ROAR",
    ["Maul (LOCAL)"] = "ROAR",
    ["Claw (LOCAL)"] = "ROAR",
    ["Rip (LOCAL)"] = "ROAR",
    ["Ferocious Bite (LOCAL)"] = "ROAR",
}

-- The Imp's own real voice lines, grouped by which command provoked them -- used to match
-- an overheard CHAT_MSG_MONSTER_SAY/YELL from your Imp against a category, so
-- "Imp: Attack"/"Imp: Order"/"Imp: Dismiss" each get their own comeback instead of one
-- generic reaction to any Imp chatter. Matched as plain substring checks (not exact
-- equality) for forgiveness against any minor text variance.
--
-- These are Classic Era's actual (older, smaller) Imp voice line set, confirmed directly
-- against real in-game chat log output -- NOT the same lines as retail's revamped
-- Imp/Fel Imp model (Warcraft Wiki's "Summon Imp" page documents that newer, larger set,
-- which doesn't exist on this client at all; an earlier version of this table was built
-- from that page and consequently never matched anything real, always falling through to
-- Gibberish). The category each line is filed under is a best-effort guess from its tone
-- (no authoritative per-line context labels exist for this Classic-only set) -- if one
-- turns out to fire from the wrong kind of command in practice, move it to a better-fitting
-- category.
ns.GRP_ImpQuotePatterns = {
    ["Imp: Attack"] = {
        "This better be the last one!",
        "You better back me up on this one!",
        "Make yourself useful and help me out here!",
    },
    ["Imp: Order"] = {
        "Alright I'm going! Stop yelling!",
        "What? You mean you can't kill this one by yourself?",
    },
    ["Imp: Dismiss"] = {
        "Just release me already! I've had enough!",
    },
}
