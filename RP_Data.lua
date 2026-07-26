-- Spell name (as it appears in the combat log) -> list of flavor lines.
-- Add/edit lines here. One is picked at random each time the spell is cast successfully.
local ADDON_NAME, ns = ...

ns.GRP_Spells = {
    -- Universal (every class, triggered by the generic Food/Drink regen buff)
    ["Food"] = {
        "time for a bite.",
        "can't adventure on an empty stomach.",
        "digging in.",
        "food first, heroics later.",
        "a quick meal never hurt anyone.",
    },
    ["Drink"] = {
        "just need a drink.",
        "rehydrating.",
        "bottoms up.",
        "a moment of peace and a full cup.",
        "drinking up before the next fight.",
    },
    ["Food and Drink"] = {
        "food in one hand, drink in the other.",
        "eating and drinking, priorities in order.",
        "quick bite, quick sip, back to it.",
        "can't decide which i need more, so i'm having both.",
        "a proper meal deserves a proper drink.",
    },

    -- Universal (every class, triggered by a party/raid/guild member's death)
    ["Death: Group"] = {
        "grits their teeth. we lost %t.",
        "goes quiet for a moment. rest easy, %t.",
        "%t is down. regroup.",
        "swears under their breath. not %t too.",
    },
    ["Death: Raid"] = {
        "bows their head for %t.",
        "the raid grows quieter. %t has fallen.",
        "adds %t to tonight's toll.",
        "%t... we'll finish this for you.",
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
        "hey ugly, over here!",
        "get over here and face me, coward!",
        "you call that a fight? Try me!",
    },
    ["Charge"] = {
        "here I come, ready or not!",
        "out of my way!",
    },
    ["Intimidating Shout"] = {
        "run while you still can!",
        "you should be terrified right now.",
    },
    ["Bloodrage"] = {
        "pain is just fuel.",
        "my own blood, my own rage.",
        "i don't need to think, i just need to hit harder.",
    },
    ["Battle Shout"] = {
        "rally up, we're not done yet!",
        "hit harder, all of you!",
        "let's show them what we're made of!",
    },
    ["Demoralizing Shout"] = {
        "you should be shaking by now.",
        "your courage just left the battlefield.",
        "that's fear creeping in, isn't it?",
    },
    ["Revenge"] = {
        "that's payback.",
        "you shouldn't have done that.",
        "now it's my turn.",
    },
    ["Bloodthirst"] = {
        "i can already taste it.",
        "blood calls to blood.",
        "the thirst never truly fades.",
    },
    ["Death Wish"] = {
        "death doesn't scare me, it excites me.",
        "come and see how far i'll go.",
        "i welcome the end, if it comes swinging.",
    },
    ["Rend"] = {
        "bleed for me.",
        "that wound isn't closing anytime soon.",
        "let it fester.",
    },
    ["Execute"] = {
        "time to finish this.",
        "no mercy for the weak.",
        "this ends now.",
    },
    ["Overpower"] = {
        "too slow!",
        "you left yourself wide open.",
        "i saw that coming.",
    },
    ["Sunder Armor"] = {
        "let's see what's underneath.",
        "that armor won't hold much longer.",
        "cracking you open, piece by piece.",
    },
    ["Shield Slam"] = {
        "eat shield.",
        "how's that for a greeting?",
    },
    ["Shield Bash"] = {
        "shut it.",
        "not another word.",
    },
    ["Whirlwind"] = {
        "everybody gets a turn!",
        "spin to win.",
        "stay back if you value your limbs.",
    },
    ["Hamstring"] = {
        "you're not going anywhere.",
        "let's slow you down a bit.",
    },
    ["Mocking Blow"] = {
        "is that all you've got?",
        "come on, hit me. I'll wait.",
    },
    ["Disarm"] = {
        "you won't be needing that.",
        "hands are more dangerous than steel anyway.",
    },
    ["Berserker Rage"] = {
        "now I'm just getting started.",
        "rage feeds rage.",
        "you don't want to see me like this.",
    },
    ["Recklessness"] = {
        "consequences are for later.",
        "all in, no holding back.",
        "caution's for cowards.",
    },
    ["Shield Wall"] = {
        "nothing's getting through this.",
        "hit me with everything you've got.",
    },
    ["Retaliation"] = {
        "every hit you land, you'll regret.",
        "strike me and see what happens.",
    },
    ["Thunder Clap"] = {
        "feel that?",
        "the ground itself answers to me.",
    },
    ["Heroic Strike"] = {
        "this one's going to hurt.",
        "full weight behind that.",
    },
    ["Cleave"] = {
        "one swing, plenty to go around.",
        "share the pain, all of you.",
    },
    ["Pummel"] = {
        "not this time.",
        "no spells for you.",
    },

    -- Rogue
    ["Sap"] = {
        "nighty night.",
        "shh... sleep tight.",
    },
    ["Vanish"] = {
        "now you see me...",
        "poof. Gone.",
    },
    ["Kidney Shot"] = {
        "stay down.",
        "that's gonna leave a mark.",
    },
    ["Eviscerate"] = {
        "and that's the finish.",
        "curtain call.",
        "nothing personal.",
    },
    ["Sinister Strike"] = {
        "didn't even see it coming.",
        "quick and quiet.",
    },
    ["Ambush"] = {
        "surprise.",
        "should've watched your back.",
        "too easy.",
    },
    ["Cheap Shot"] = {
        "rules are for people who fight fair.",
        "lights out.",
    },
    ["Blind"] = {
        "can't hit what you can't see.",
        "enjoy the darkness.",
    },
    ["Evasion"] = {
        "you'll need to be faster than that.",
        "catch me if you can.",
    },
    ["Rupture"] = {
        "that'll keep bleeding a while.",
        "count your seconds.",
    },
    ["Slice and Dice"] = {
        "getting faster now.",
        "no wasted motion.",
    },
    ["Garrote"] = {
        "not a sound.",
        "quiet now.",
        "should've heard me coming.",
    },
    ["Backstab"] = {
        "right between the shoulder blades.",
        "never saw it coming, did you?",
    },
    ["Gouge"] = {
        "stay down for a second.",
        "that ought to buy me some time.",
    },
    ["Kick"] = {
        "not today.",
        "save your breath.",
    },
    ["Expose Armor"] = {
        "found the gap in your armor.",
        "that seam's about to fail.",
    },
    ["Feint"] = {
        "not even looking at me now, are you?",
        "eyes over here. or not.",
    },
    ["Sprint"] = {
        "catch me if you can.",
        "too slow.",
    },
    ["Cold Blood"] = {
        "steady hands, steady mind.",
        "no room for mistakes now.",
    },
    ["Adrenaline Rush"] = {
        "everything's speeding up.",
        "can't slow down now.",
    },
    ["Distract"] = {
        "look over there.",
        "works every time.",
    },

    -- Mage
    ["Polymorph"] = {
        "baa. Baa, I say.",
        "enjoy your new wool coat.",
        "much better looking now.",
    },
    ["Fireball"] = {
        "burn, baby, burn!",
        "feel the heat!",
    },
    ["Frost Nova"] = {
        "chill out.",
        "ice to meet you.",
    },
    ["Frostbolt"] = {
        "cold snap.",
        "let it slow you down.",
        "winter finds you first.",
    },
    ["Arcane Missiles"] = {
        "raw power, straight at you.",
        "let the arcane do the talking.",
    },
    ["Blink"] = {
        "not fast enough.",
        "here, then gone.",
    },
    ["Ice Block"] = {
        "can't touch me now.",
        "cold and untouchable.",
    },
    ["Counterspell"] = {
        "not on my watch.",
        "silence, please.",
    },
    ["Cone of Cold"] = {
        "everyone in front of me, freeze.",
        "winter has arrived.",
    },
    ["Evocation"] = {
        "just need a moment.",
        "drawing the arcane back in.",
    },
    ["Pyroblast"] = {
        "this one's going to leave a crater.",
        "brace yourself.",
    },
    ["Arcane Explosion"] = {
        "everybody back.",
        "arcane doesn't discriminate.",
    },
    ["Fire Blast"] = {
        "point blank and burning.",
        "close range, full heat.",
    },
    ["Frost Armor"] = {
        "cold to the touch, always.",
        "frost keeps me safe.",
    },
    ["Mana Shield"] = {
        "my mana, my armor.",
        "protected, for now.",
    },
    ["Slow Fall"] = {
        "gravity's more of a suggestion.",
        "landing gracefully, as always.",
    },
    ["Conjure Food"] = {
        "magic makes a fine chef.",
        "bread, straight from the ether.",
    },
    ["Conjure Water"] = {
        "water, conjured fresh.",
        "hydration, courtesy of the arcane.",
    },
    ["Remove Lesser Curse"] = {
        "that curse doesn't belong to you anymore.",
        "let's undo that.",
    },
    ["Dragon's Breath"] = {
        "hope you're not afraid of fire.",
        "dragons would be proud.",
    },
    ["Scorch"] = {
        "just a taste of what's coming.",
        "let that simmer.",
    },
    ["Teleport: Stormwind"] = {
        "off to stormwind for a bit.",
        "stormwind calls, i answer.",
        "quick trip home.",
    },
    ["Teleport: Ironforge"] = {
        "ironforge, here i come.",
        "back to the mountain halls.",
        "off to see the dwarves.",
    },
    ["Teleport: Orgrimmar"] = {
        "orgrimmar bound.",
        "back to the horde capital.",
        "off to the valley of strength.",
    },
    ["Teleport: Undercity"] = {
        "back to the undercity.",
        "into the shadows i go.",
        "off to see the forsaken.",
    },
    ["Teleport: Darnassus"] = {
        "darnassus awaits.",
        "off to the night elf city.",
        "back among the trees.",
    },
    ["Teleport: Thunder Bluff"] = {
        "off to thunder bluff.",
        "back to the plains.",
        "the tauren await.",
    },
    ["Portal: Stormwind"] = {
        "portal to stormwind, open and ready!",
        "step through, stormwind's just on the other side.",
        "quick trip to stormwind, right this way!",
    },
    ["Portal: Ironforge"] = {
        "portal to ironforge, open and ready!",
        "step through, the mountain awaits.",
        "quick trip to ironforge, hop in!",
    },
    ["Portal: Orgrimmar"] = {
        "portal to orgrimmar, open and ready!",
        "step through, the horde capital's just ahead.",
        "quick trip to orgrimmar, hop in!",
    },
    ["Portal: Undercity"] = {
        "portal to undercity, open and ready!",
        "step through, the shadows are waiting.",
        "quick trip below, hop in!",
    },
    ["Portal: Darnassus"] = {
        "portal to darnassus, open and ready!",
        "step through, the trees are calling.",
        "quick trip to darnassus, hop in!",
    },
    ["Portal: Thunder Bluff"] = {
        "portal to thunder bluff, open and ready!",
        "step through, the plains await.",
        "quick trip to thunder bluff, hop in!",
    },

    -- Priest
    ["Mind Flay"] = {
        "get out of my head... or rather, get into yours.",
        "let me pick your brain.",
    },
    ["Shadow Word: Pain"] = {
        "this is going to hurt for a while.",
    },
    ["Psychic Scream"] = {
        "boo!",
        "something wicked this way comes.",
    },
    ["Power Word: Shield"] = {
        "you're covered.",
        "nothing gets through that.",
        "stay safe out there.",
    },
    ["Renew"] = {
        "healing, drop by drop.",
        "that'll keep working on its own.",
    },
    ["Heal"] = {
        "here, let me fix that.",
        "good as new.",
    },
    ["Greater Heal"] = {
        "that should close the gap.",
        "much better now.",
    },
    ["Holy Nova"] = {
        "light for all of you.",
        "let the light wash over us.",
    },
    ["Fade"] = {
        "not it.",
        "attention, please look elsewhere.",
    },
    ["Smite"] = {
        "feel the light's judgment.",
        "smitten, and rightly so.",
    },
    ["Flash Heal"] = {
        "quick as the light allows.",
        "there, patched up in a flash.",
    },
    ["Cure Disease"] = {
        "that illness ends here.",
        "cleansed, good as new.",
    },
    ["Levitate"] = {
        "gravity's just a suggestion for now.",
        "floating free, for a while.",
    },
    ["Mana Burn"] = {
        "your power is mine to take.",
        "burning through your reserves.",
    },
    ["Touch of Weakness"] = {
        "that touch will cost you.",
        "weakness, delivered by hand.",
    },
    ["Dispel Magic"] = {
        "that spell doesn't belong there.",
        "unmaking it now.",
    },
    ["Mind Blast"] = {
        "a little pressure, right there.",
        "feel that pushing in?",
    },
    ["Vampiric Embrace"] = {
        "your suffering, my strength.",
        "shared pain has its uses.",
    },
    ["Resurrection"] = {
        "not your time yet. Come back.",
        "rise again.",
    },
    ["Prayer of Healing"] = {
        "everyone, breathe easier now.",
        "the light doesn't play favorites.",
    },
    ["Power Word: Fortitude"] = {
        "stand a little stronger now.",
        "the light bolsters you.",
    },
    ["Mind Vision"] = {
        "let's see what you see.",
        "peeking through your eyes for a moment.",
    },
    ["Divine Spirit"] = {
        "a clearer mind, a steadier spirit.",
        "the light sharpens your focus.",
    },
    ["Inner Fire"] = {
        "the light burns within now.",
        "armored in faith.",
    },
    ["Shackle Undead"] = {
        "stay put.",
        "the light binds even the dead.",
    },
    ["Mind Control"] = {
        "your will is mine, for now.",
        "just do as I say.",
    },
    ["Holy Fire"] = {
        "burn in righteousness.",
        "the light doesn't forgive.",
    },
    ["Abolish Disease"] = {
        "that sickness won't linger.",
        "cleansing you now.",
    },
    ["Inner Focus"] = {
        "this one costs nothing but will.",
        "focus sharpens the mind wonderfully.",
    },
    ["Desperate Prayer"] = {
        "not today. not like this.",
        "a prayer for one more moment.",
    },
    ["Starshards"] = {
        "the stars have teeth too.",
        "silence, courtesy of the night sky.",
    },
    ["Elune's Grace"] = {
        "the goddess lends her grace.",
        "Elune watches your steps now.",
    },
    ["Fear Ward"] = {
        "no fear finds purchase here.",
        "steady now, nothing can shake you.",
    },

    -- Warlock
    ["Fear"] = {
        "boo.",
        "run, little one, run.",
        "your nightmares are just beginning.",
        "flee. It won't save you.",
    },
    ["Corruption"] = {
        "rot from the inside out.",
        "let the decay take you.",
        "your flesh betrays you now.",
    },
    ["Curse of Agony"] = {
        "this is going to be a long, painful minute.",
        "suffer slowly.",
        "every second will feel like an eternity.",
    },
    ["Curse of Weakness"] = {
        "feel your strength wither away.",
        "you grow feeble in my presence.",
    },
    ["Curse of Recklessness"] = {
        "let your guard fall.",
        "carelessness will be your undoing.",
    },
    ["Curse of Tongues"] = {
        "let your tongue twist and fail you.",
        "speak now, if you still can.",
        "your incantations mean nothing now.",
    },
    ["Curse of Elements"] = {
        "the elements themselves will tear you apart.",
        "every spell that touches you will burn twice as hard.",
        "you stand exposed before all magic.",
    },
    ["Curse of Shadow"] = {
        "the shadows will find every crack in your defenses.",
        "darkness seeps into your very bones.",
        "you'll wish you never crossed into the dark.",
    },
    ["Curse of Doom"] = {
        "your time is running out.",
        "one minute. that's all you have left.",
        "doom finds everyone, eventually.",
    },
    ["Shadow Bolt"] = {
        "embrace the void.",
        "darkness consumes all.",
        "a gift from the shadows.",
        "let the shadows find you.",
        "feel the void's touch.",
        "there is no light where you're going.",
        "a bolt from the abyss.",
        "the dark has chosen you.",
    },
    ["Shadow Trance"] = {
        -- Procs from the Nightfall talent (free, instant Shadow Bolt)
        "the shadows favor me!",
        "free power, don't mind if I do.",
        "the void smiles upon me.",
        "nightfall strikes!",
        "darkness itself hands me the bolt.",
    },
    ["Immolate"] = {
        "burn in unholy fire.",
        "let the flames of the abyss cleanse you.",
    },
    ["Drain Life"] = {
        "your life is mine now.",
        "i'll take that, thank you.",
    },
    ["Drain Soul"] = {
        "your soul belongs to the void.",
        "i can feel your essence slipping away.",
    },
    ["Death Coil"] = {
        "taste death itself.",
        "a cold embrace awaits you.",
    },
    ["Life Tap"] = {
        "pain fuels power.",
        "my blood, my strength.",
        "a little pain, a lot of power.",
        "borrowing from myself again.",
        "blood for mana, fair trade.",
        "i'll feel that later. worth it.",
        "draining myself to keep going.",
        "power has its price, and i'm paying it.",
    },
    ["Howl of Terror"] = {
        "witness true horror!",
        "scream all you like.",
    },
    ["Rain of Fire"] = {
        "let the sky burn.",
        "hellfire rains upon you all.",
    },
    ["Hellfire"] = {
        "we burn together.",
        "the abyss consumes everything, myself included.",
    },
    ["Searing Pain"] = {
        "feel the fires of torment.",
    },
    ["Summon Imp"] = {
        "rise, my little servant.",
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
        "assures %t that this is absolutely the last one -- until the next one.",
    },
    ["Imp: Order"] = {
        "tells %t to stop yelling -- the imp is already doing all the work.",
        "reminds %t that repeating the order will not make it more intelligent.",
        "asks %t if they really need help with something this pathetic.",
        "tells %t to keep shouting while the imp handles the actual fighting.",
        "agrees to go, since apparently %t cannot do anything alone.",
        "tells %t to calm down before they embarrass themselves further.",
        "reminds %t that obedience does not require constant supervision.",
        "tells %t that the imp heard them the first time, unlike the enemy.",
    },
    ["Imp: Dismiss"] = {
        "tells %t not to sound so desperate; they will be summoned again soon enough.",
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
        "come forth from the void.",
    },
    ["Summon Succubus"] = {
        "obey me, temptress.",
    },
    ["Summon Felhunter"] = {
        "hunt for me.",
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
        "There you go, %t. Not that it'll do you any good when you actually die.",
        "Here's your Soulstone, %t. Hardcore doesn't care, but feel free to pretend it matters.",
        "%t, one Soulstone, freshly cursed and completely useless in Hardcore.",
        "Take it, %t. It's basically just an expensive rock with false advertising.",
        "%t, enjoy your Soulstone. Save your tears for when it fails to save you.",
        "Here's your Soulstone, %t. It won't save you, but at least it looks reassuring.",
        "%t, you now have a second chance that Hardcore will politely ignore.",
        "One Soulstone for %t. Completely useless, but very comforting.",
        "%t, your soul is insured. Unfortunately, Hardcore does not honor the policy.",
        "Take this, %t. It might bring you back, assuming the rules suddenly stop mattering.",
        "%t, I've trapped your soul in a stone. Shame it won't help you in Hardcore.",
        "Your Soulstone is ready, %t. Your survival still depends on not dying.",
        "%t, consider this a decorative resurrection device.",
        "Here's your Soulstone, %t. It has one job and absolutely no chance to do it.",
        "%t, death may be temporary in theory. In Hardcore, it's still permanent.",
        "Your soul has been safely stored, %t. Sadly, your character's future has not.",
        "%t, this Soulstone is about as useful as a parachute at the bottom of the ocean.",
        "One complimentary Soulstone for %t. No refunds, no resurrection, and no miracles.",
        "%t, I've given you a Soulstone. Now all you need is a game mode that allows it to matter.",
        "Soulstone applied to %t. Please remember that Hardcore considers death a permanent feature.",
    },

    -- Hunter
    ["Concussive Shot"] = {
        "not so fast!",
        "that'll slow you down.",
    },
    ["Multi-Shot"] = {
        "everybody gets one!",
    },
    ["Aspect of the Monkey"] = {
        "ook ook!",
    },
    ["Aimed Shot"] = {
        "steady... and loose.",
        "one shot, that's all it takes.",
    },
    ["Arcane Shot"] = {
        "let the arrow do the talking.",
        "quick and clean.",
    },
    ["Serpent Sting"] = {
        "that venom's just getting started.",
        "let it work its way through you.",
    },
    ["Wing Clip"] = {
        "not going anywhere now.",
        "let's slow that down.",
    },
    ["Freezing Trap"] = {
        "step right there, please.",
        "frozen solid.",
    },
    ["Explosive Trap"] = {
        "watch your step.",
        "surprise.",
    },
    ["Feign Death"] = {
        "playing dead has its uses.",
        "not really dead. just patient.",
    },
    ["Distracting Shot"] = {
        "over here!",
        "eyes on me, not my friends.",
    },
    ["Raptor Strike"] = {
        "quick and sharp.",
        "no hesitation.",
    },
    ["Mongoose Bite"] = {
        "faster than you'd think.",
        "opening struck.",
    },
    ["Hunter's Mark"] = {
        "now I can't lose you.",
        "marked. no escaping that.",
    },
    ["Aspect of the Hawk"] = {
        "sharper eyes, steadier aim.",
        "the hawk guides my shots now.",
    },
    ["Aspect of the Cheetah"] = {
        "can't catch what you can't reach.",
        "built for speed now.",
    },
    ["Tranquilizing Shot"] = {
        "calm down.",
        "that rage isn't helping you now.",
    },
    ["Scare Beast"] = {
        "run along, little one.",
        "nothing to see here.",
    },

    -- Paladin
    ["Hammer of Justice"] = {
        "justice has arrived.",
        "feel the hammer!",
    },
    ["Judgement"] = {
        "you have been judged.",
    },
    ["Holy Light"] = {
        "let the light mend you.",
        "healing, as promised.",
    },
    ["Flash of Light"] = {
        "quick, but it'll hold.",
        "just enough to keep you standing.",
    },
    ["Consecration"] = {
        "hallowed ground now.",
        "nothing unholy stands here.",
    },
    ["Exorcism"] = {
        "the light has no patience for your kind.",
        "begone.",
    },
    ["Seal of Righteousness"] = {
        "righteousness guides my hand.",
        "every strike, blessed.",
    },
    ["Seal of Command"] = {
        "the light commands, I deliver.",
        "obey, or face the consequences.",
    },
    ["Blessing of Might"] = {
        "strength, courtesy of the light.",
        "hit harder now.",
    },
    ["Blessing of Wisdom"] = {
        "clarity and power, both yours.",
        "the light shares its wisdom.",
    },
    ["Blessing of Protection"] = {
        "nothing touches you now.",
        "you're shielded, for now.",
    },
    ["Divine Shield"] = {
        "untouchable, if only briefly.",
        "the light surrounds me.",
    },
    ["Divine Protection"] = {
        "the light softens the blow.",
        "protected, but not invincible.",
    },
    ["Lay on Hands"] = {
        "everything I have, given freely.",
        "this is what devotion looks like.",
    },
    ["Cleanse"] = {
        "let the light burn that away.",
        "purified.",
    },
    ["Redemption"] = {
        "rise. your story isn't over.",
        "the light calls you back.",
    },
    ["Turn Undead"] = {
        "the light rejects you.",
        "flee, creature of darkness.",
    },

    -- Shaman
    ["Earth Shock"] = {
        "feel the earth's fury!",
    },
    ["Lightning Bolt"] = {
        "the sky answers me.",
        "feel the storm.",
    },
    ["Chain Lightning"] = {
        "let it jump between you.",
        "one bolt, plenty of targets.",
    },
    ["Frost Shock"] = {
        "cold enough for you?",
        "let the frost hold you in place.",
    },
    ["Flame Shock"] = {
        "burn a while.",
        "the fire lingers.",
    },
    ["Healing Wave"] = {
        "let the spirits mend you.",
        "the waters heal.",
    },
    ["Lesser Healing Wave"] = {
        "small, but it'll help.",
        "just enough to keep you up.",
    },
    ["Purge"] = {
        "that magic doesn't belong to you.",
        "cleansed.",
    },
    ["Windfury Weapon"] = {
        "let the wind guide my strikes.",
        "the spirits favor this blade now.",
    },
    ["Stoneskin Totem"] = {
        "steady as stone now.",
        "the earth protects us.",
    },
    ["Earthbind Totem"] = {
        "the ground itself holds you.",
        "not going anywhere, are you.",
    },
    ["Tremor Totem"] = {
        "steady your fears.",
        "the earth calms the mind.",
    },
    ["Grounding Totem"] = {
        "send that magic my way instead.",
        "i'll take that for you.",
    },
    ["Healing Stream Totem"] = {
        "let it flow, slow and steady.",
        "the waters keep working.",
    },
    ["Fire Nova Totem"] = {
        "everybody back, now.",
        "the earth erupts.",
    },
    ["Astral Recall"] = {
        "home calls.",
        "the spirits guide me back.",
    },
    ["Ghost Wolf"] = {
        "swift as the spirits allow.",
        "the wolf runs free.",
    },

    -- Druid
    ["Entangling Roots"] = {
        "stuck, are we?",
    },
    ["Bash"] = {
        "down you go!",
    },
    ["Moonfire"] = {
        "the moon marks you now.",
        "let the light burn.",
    },
    ["Wrath"] = {
        "nature's fury, aimed at you.",
        "the wilds don't forgive.",
    },
    ["Starfire"] = {
        "the stars answer my call.",
        "let the light fall on you.",
    },
    ["Rejuvenation"] = {
        "let nature do its work.",
        "slow and steady healing.",
    },
    ["Regrowth"] = {
        "life finds a way, quickly.",
        "that'll knit back together.",
    },
    ["Healing Touch"] = {
        "let the wilds mend you.",
        "nature provides.",
    },
    ["Rebirth"] = {
        "not done yet. Rise.",
        "nature grants one more chance.",
    },
    ["Hibernate"] = {
        "sleep now.",
        "quiet, and still.",
    },
    ["Faerie Fire"] = {
        "can't hide from that.",
        "marked by the fae.",
    },
    ["Thorns"] = {
        "careful, I bite back.",
        "nature protects its own.",
    },
    ["Mark of the Wild"] = {
        "carry the wild with you now.",
        "the wilds favor you.",
    },
    ["Innervate"] = {
        "take what you need, quickly.",
        "the wilds lend their energy.",
    },
    ["Nature's Grasp"] = {
        "the earth itself holds you back.",
        "roots find you fast.",
    },
    ["Barkskin"] = {
        "tough as bark now.",
        "hard to hurt like this.",
    },
    ["Maul"] = {
        "claws first, questions later.",
        "that's going to leave a mark.",
    },
    ["Claw"] = {
        "sharp and quick.",
        "feel that?",
    },
    ["Rip"] = {
        "that wound isn't closing soon.",
        "let it bleed.",
    },
    ["Ferocious Bite"] = {
        "finishing this the feral way.",
        "all teeth, no mercy.",
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
    ["Divine Spirit"] = "PRIEST",
    ["Inner Fire"] = "PRIEST",
    ["Shackle Undead"] = "PRIEST",
    ["Mind Control"] = "PRIEST",
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
