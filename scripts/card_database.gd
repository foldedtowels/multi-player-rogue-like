extends Node
## Central repository for all player and boss cards
##
## This autoload singleton creates and manages all cards in the game.
## Cards are defined using the create_card() factory function with parameters:
##
## create_card(name, description, card_type, target_type, cost, dmg, heal, shield, draw)
##
## PARAMETER GUIDE:
## - name: Display name shown on the card
## - description: Flavor text explaining what the card does
## - card_type: ATTACK | SPELL | BUFF | DEBUFF | HEAL
## - target_type: SELF | SINGLE_ALLY | SINGLE_ENEMY | RANDOM_ENEMY | ALL_ALLIES | ALL_ENEMIES
## - cost: Energy required to play the card (0-5 typically)
## - dmg: Base damage dealt to target(s) (0 if non-damaging)
## - heal: HP restored to target (0 if no healing, negative to damage self)
## - shield: Temporary HP gained (0 if no shield)
## - draw: Number of cards drawn when played (0 if no card draw)
##
## EXAMPLE:
## create_card("Lightning Bolt", "Fast damage", ATTACK, SINGLE_ENEMY, 1, 12, 0, 0, 0)
##                                                                     ↑  ↑↑  ↑   ↑  ↑
##                                                                  cost |  |   |   |
##                                                                    damage |   |   |
##                                                                       healing |   |
##                                                                          shield   |
##                                                                              card draw
##
## ADVANCED PROPERTIES (set after create_card):
## - aoe_damage: true = hits all targets instead of just one
## - apply_burn: Apply burn status (damage per turn)
## - apply_poison: Apply poison status (damage per turn, decays)
## - apply_strength: Increase attack damage
## - apply_vulnerable: Increase damage taken
## - apply_weakness: Reduce damage dealt
## - apply_armor: Permanent damage reduction
## - lifesteal: true = heal for damage dealt
## - piercing: true = ignores shield and armor

var all_cards = {}

## Path to CSV file for card definitions (set to "" to disable CSV loading)
var csv_path: String = "res://csvs/cards.csv"

## If true, print detailed loading info
var verbose_loading: bool = true

func _ready():
	_create_all_cards()
	_load_cards_from_csv()


## Load cards from CSV file (overrides/adds to hardcoded cards)
func _load_cards_from_csv() -> void:
	if csv_path == "":
		return

	if not FileAccess.file_exists(csv_path):
		if verbose_loading:
			print("[CardDatabase] No CSV file at: " + csv_path + " (using hardcoded cards only)")
		return

	var csv_cards = CSVCardLoader.load_cards_from_csv(csv_path)
	var override_count = 0
	var new_count = 0

	for card_id in csv_cards:
		if all_cards.has(card_id):
			override_count += 1
		else:
			new_count += 1
		all_cards[card_id] = csv_cards[card_id]

	if verbose_loading:
		print("[CardDatabase] CSV loaded: " + str(override_count) + " overrides, " + str(new_count) + " new cards")


## Export all current cards to CSV (useful for creating initial CSV from hardcoded cards)
## Call this from the debugger or a test script: CardDatabase.export_all_cards_to_csv()
func export_all_cards_to_csv(output_path: String = "res://csvs/cards.csv") -> bool:
	return CSVCardLoader.export_cards_to_csv(all_cards, output_path)

func _create_all_cards():
	# === FLAME WIELDER CARDS (Red - Burn/Aggro) ===
	all_cards["lightning_bolt"] = create_card(
		"Lightning Bolt",
		"The classic red spell. Fast and deadly.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 12, 0, 0, 0
	)

	all_cards["shock"] = create_card(
		"Shock",
		"A quick jolt of energy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 8, 0, 0, 0
	)

	all_cards["fireball"] = create_card(
		"Fireball",
		"Explosive power that hits everything.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		3, 15, 0, 0, 0
	)
	all_cards["fireball"].aoe_damage = true

	all_cards["flame_slash"] = create_card(
		"Flame Slash",
		"Searing blade of fire.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 10, 0, 0, 0
	)

	all_cards["burning_hands"] = create_card(
		"Burning Hands",
		"Touch of flame that keeps burning.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 8, 0, 0, 0
	)
	all_cards["burning_hands"].apply_burn = 5

	all_cards["volcanic_strike"] = create_card(
		"Volcanic Strike",
		"Mighty blow that pierces defenses.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 16, 0, 0, 0
	)
	all_cards["volcanic_strike"].piercing = true

	all_cards["flame_barrier"] = create_card(
		"Flame Barrier",
		"Protective wall of fire.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 8, 0
	)

	all_cards["ignite"] = create_card(
		"Ignite",
		"Set the world ablaze.",
		Card.CardType.DEBUFF,
		Card.TargetType.ALL_ENEMIES,
		2, 0, 0, 0, 0
	)
	all_cards["ignite"].apply_burn = 3

	# === LIFE WEAVER CARDS (White/Green - Healing/Buffs) ===
	all_cards["healing_salve"] = create_card(
		"Healing Salve",
		"Gentle restoration of life.",
		Card.CardType.HEAL,
		Card.TargetType.SINGLE_ALLY,
		1, 0, 15, 0, 0
	)

	all_cards["divine_light"] = create_card(
		"Divine Light",
		"Radiant healing for all allies.",
		Card.CardType.HEAL,
		Card.TargetType.ALL_ALLIES,
		2, 0, 10, 0, 0
	)

	all_cards["holy_strike"] = create_card(
		"Holy Strike",
		"Righteous punishment.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 10, 0, 0, 0
	)

	all_cards["guardian_shield"] = create_card(
		"Guardian Shield",
		"Protection from harm.",
		Card.CardType.BUFF,
		Card.TargetType.SINGLE_ALLY,
		1, 0, 0, 12, 0
	)

	all_cards["pacify"] = create_card(
		"Pacify",
		"Weaken the enemy's resolve.",
		Card.CardType.DEBUFF,
		Card.TargetType.SINGLE_ENEMY,
		1, 0, 0, 0, 0
	)
	all_cards["pacify"].apply_weakness = 2

	all_cards["blessing"] = create_card(
		"Blessing",
		"Empower an ally with divine strength.",
		Card.CardType.BUFF,
		Card.TargetType.SINGLE_ALLY,
		1, 0, 0, 0, 0
	)
	all_cards["blessing"].apply_strength = 3

	all_cards["mass_heal"] = create_card(
		"Mass Heal",
		"Powerful restoration for the party.",
		Card.CardType.HEAL,
		Card.TargetType.ALL_ALLIES,
		3, 0, 20, 0, 0
	)

	all_cards["smite"] = create_card(
		"Smite",
		"Holy wrath pierces all defenses.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 14, 0, 0, 0
	)
	all_cards["smite"].piercing = true

	# === SHADOW ASSASSIN CARDS (Black - Removal/Drain) ===
	all_cards["doom_blade"] = create_card(
		"Doom Blade",
		"Strike from the shadows.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 18, 0, 0, 0
	)

	all_cards["drain_life"] = create_card(
		"Drain Life",
		"Steal vitality from your foe.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 12, 0, 0, 0
	)
	all_cards["drain_life"].lifesteal = true

	all_cards["poison_strike"] = create_card(
		"Poison Strike",
		"Venomous blade that lingers.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 6, 0, 0, 0
	)
	all_cards["poison_strike"].apply_poison = 4

	all_cards["shadow_step"] = create_card(
		"Shadow Step",
		"Strike twice from the darkness.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 7, 0, 0, 1
	)
	all_cards["shadow_step"].multi_hit = 2

	all_cards["dark_pact"] = create_card(
		"Dark Pact",
		"Sacrifice health for power.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, -5, 0, 2
	)
	all_cards["dark_pact"].apply_strength = 4

	all_cards["corrupt"] = create_card(
		"Corrupt",
		"Spread decay to all enemies.",
		Card.CardType.DEBUFF,
		Card.TargetType.ALL_ENEMIES,
		2, 0, 0, 0, 0
	)
	all_cards["corrupt"].apply_poison = 3

	all_cards["assassination"] = create_card(
		"Assassination",
		"Silent kill that bypasses armor.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		3, 25, 0, 0, 0
	)
	all_cards["assassination"].piercing = true

	all_cards["vampiric_touch"] = create_card(
		"Vampiric Touch",
		"Drain life force continuously.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 10, 0, 0, 0
	)
	all_cards["vampiric_touch"].lifesteal = true
	all_cards["vampiric_touch"].apply_poison = 2

	# === STORM CALLER CARDS (Blue - Control/Draw) ===
	all_cards["counterspell"] = create_card(
		"Counterspell",
		"Shield yourself and draw insight.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		2, 0, 0, 10, 1
	)

	all_cards["divination"] = create_card(
		"Divination",
		"Peer into the future.",
		Card.CardType.SPELL,
		Card.TargetType.SELF,
		2, 0, 0, 0, 2
	)
	all_cards["divination"].plays_immediately = true

	all_cards["lightning_strike"] = create_card(
		"Lightning Strike",
		"Call down the storm.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 11, 0, 0, 0
	)

	all_cards["frost_bolt"] = create_card(
		"Frost Bolt",
		"Freeze and weaken your enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 10, 0, 0, 0
	)
	all_cards["frost_bolt"].apply_vulnerable = 2

	all_cards["arcane_intellect"] = create_card(
		"Arcane Intellect",
		"Deep study yields knowledge.",
		Card.CardType.SPELL,
		Card.TargetType.SELF,
		1, 0, 0, 0, 2
	)
	all_cards["arcane_intellect"].plays_immediately = true

	all_cards["chain_lightning"] = create_card(
		"Chain Lightning",
		"Electricity arcs between foes.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 8, 0, 0, 0
	)
	all_cards["chain_lightning"].multi_hit = 2

	all_cards["storm_surge"] = create_card(
		"Storm Surge",
		"Unleash the tempest.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		3, 12, 0, 0, 0
	)
	all_cards["storm_surge"].aoe_damage = true

	all_cards["mana_shield"] = create_card(
		"Mana Shield",
		"Convert energy into protection.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 15, 0
	)

	# === BEAST TAMER CARDS (Green - Creatures/Growth) ===
	all_cards["giant_growth"] = create_card(
		"Giant Growth",
		"Empower yourself with primal strength.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 0, 0
	)
	all_cards["giant_growth"].apply_strength = 4

	all_cards["wild_strike"] = create_card(
		"Wild Strike",
		"Savage, relentless attack.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 9, 0, 0, 0
	)

	all_cards["regrowth"] = create_card(
		"Regrowth",
		"Nature's healing embrace.",
		Card.CardType.HEAL,
		Card.TargetType.SELF,
		1, 0, 12, 0, 0
	)

	all_cards["bear_claws"] = create_card(
		"Bear Claws",
		"Tear into your enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 14, 0, 0, 0
	)

	all_cards["natures_lore"] = create_card(
		"Nature's Lore",
		"Commune with the wild.",
		Card.CardType.SPELL,
		Card.TargetType.SELF,
		1, 0, 0, 0, 1
	)
	all_cards["natures_lore"].apply_armor = 2
	all_cards["natures_lore"].plays_immediately = true

	all_cards["primal_rage"] = create_card(
		"Primal Rage",
		"Unleash the beast within.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		2, 0, 0, 0, 0
	)
	all_cards["primal_rage"].apply_strength = 5
	all_cards["primal_rage"].apply_vulnerable = 1

	all_cards["stampede"] = create_card(
		"Stampede",
		"Overwhelming force crushes all.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		3, 16, 0, 0, 0
	)
	all_cards["stampede"].aoe_damage = true

	all_cards["regenerate"] = create_card(
		"Regenerate",
		"Rapid cellular restoration.",
		Card.CardType.HEAL,
		Card.TargetType.SELF,
		2, 0, 18, 0, 0
	)

	# === CHRONO MAGE CARDS (Blue/White - Tempo/Time) ===
	all_cards["time_warp"] = create_card(
		"Time Warp",
		"Bend time to your will.",
		Card.CardType.SPELL,
		Card.TargetType.SELF,
		3, 0, 0, 0, 3
	)
	all_cards["time_warp"].plays_immediately = true

	all_cards["blink"] = create_card(
		"Blink",
		"Phase out of danger.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 10, 1
	)
	all_cards["blink"].plays_immediately = true

	all_cards["temporal_bolt"] = create_card(
		"Temporal Bolt",
		"Strike with the force of time.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 12, 0, 0, 0
	)

	all_cards["rewind"] = create_card(
		"Rewind",
		"Turn back the clock.",
		Card.CardType.HEAL,
		Card.TargetType.SINGLE_ALLY,
		2, 0, 14, 0, 1
	)
	all_cards["rewind"].plays_immediately = true

	all_cards["haste"] = create_card(
		"Haste",
		"Accelerate your actions.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 0, 2
	)
	all_cards["haste"].plays_immediately = true

	all_cards["slow"] = create_card(
		"Slow",
		"Reduce enemy efficiency.",
		Card.CardType.DEBUFF,
		Card.TargetType.SINGLE_ENEMY,
		1, 0, 0, 0, 0
	)
	all_cards["slow"].apply_weakness = 3

	all_cards["chrono_blast"] = create_card(
		"Chrono Blast",
		"Temporal energy explosion.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		3, 14, 0, 0, 0
	)
	all_cards["chrono_blast"].aoe_damage = true

	all_cards["moment_of_clarity"] = create_card(
		"Moment of Clarity",
		"Perfect insight and protection.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		2, 0, 0, 12, 2
	)
	all_cards["moment_of_clarity"].plays_immediately = true

	# === FABIO CARDS (Phase 1 - The Warrior) ===

	# Base Deck Cards (9)
	all_cards["slash"] = create_card(
		"Slash",
		"A quick sword strike.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 7, 0, 0, 0
	)

	all_cards["big_smack"] = create_card(
		"Big Smack",
		"A powerful overhead blow.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		3, 10, 0, 0, 0
	)

	all_cards["duel_purpose"] = create_card(
		"Duel Purpose",
		"Strike while defending yourself.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 3, 0, 5, 0
	)

	all_cards["rest"] = create_card(
		"Rest",
		"Take a breather and recover your stamina.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 0, 0
	)
	all_cards["rest"].apply_rested = 1

	all_cards["bulk_up"] = create_card(
		"Bulk Up",
		"Push your body to the limit for explosive power.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		0, 0, 0, 0, 0
	)
	all_cards["bulk_up"].apply_invigorated = 1
	all_cards["bulk_up"].apply_fatigued = 1  # -1 stamina next turn

	all_cards["dig_a_hole"] = create_card(
		"Dig a Hole",
		"Select a card to retain. It stays in hand until played or end of next turn.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		0, 0, 0, 0, 0  # No draw cards - retention only
	)
	all_cards["dig_a_hole"].plays_immediately = true
	all_cards["dig_a_hole"].grants_card_retain = true

	all_cards["protector"] = create_card(
		"Protector",
		"Redirect enemy attacks from an ally to yourself this turn.",
		Card.CardType.BUFF,
		Card.TargetType.SINGLE_ALLY,
		0, 0, 0, 0, 0  # No shield - just redirects attacks
	)
	all_cards["protector"].swaps_enemy_target = true

	all_cards["protective_footwear"] = create_card(
		"Protective Footwear",
		"Sturdy boots provide defense.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 5, 0
	)

	all_cards["hunters_instinct"] = create_card(
		"Hunter's Instinct",
		"Reveal what cards the boss will play next turn.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 0, 0  # No card draw - reveals boss intent
	)
	all_cards["hunters_instinct"].plays_immediately = true
	all_cards["hunters_instinct"].reveals_boss_intent = true

	# Reward Cards (17)
	all_cards["dual_wield"] = create_card(
		"Dual Wield",
		"Strike twice with both weapons.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 2, 0, 0, 0
	)
	all_cards["dual_wield"].multi_hit = 2

	all_cards["circular_strike"] = create_card(
		"Circular Strike",
		"Swing in a wide arc hitting all enemies.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		1, 3, 0, 0, 0
	)
	all_cards["circular_strike"].aoe_damage = true

	all_cards["cursed_dagger"] = create_card(
		"Cursed Dagger",
		"A free but weak strike with a cursed blade.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		0, 2, 0, 0, 0
	)

	all_cards["jumping_strike"] = create_card(
		"Jumping Strike",
		"Leap attack. Next turn: Deal 5 damage if you took no damage this turn.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 0, 0, 0, 0  # 0 immediate damage
	)
	all_cards["jumping_strike"].is_delayed_damage = true
	all_cards["jumping_strike"].delay_condition = "no_damage_taken"
	all_cards["jumping_strike"].delayed_damage_amount = 5

	all_cards["execution"] = create_card(
		"Execution",
		"Finishing blow. +4 damage if target below 50% HP.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 4, 0, 0, 0
	)
	all_cards["execution"].bonus_damage_if_wounded = 4

	all_cards["frenzy"] = create_card(
		"Frenzy!",
		"Unleash wild fury on all enemies, exhausting yourself.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		2, 8, 0, 0, 0
	)
	all_cards["frenzy"].aoe_damage = true
	all_cards["frenzy"].apply_exhausted = 1  # Cannot play more cards this turn

	all_cards["weak_point"] = create_card(
		"Weak Point!",
		"Expose enemy vulnerabilities.",
		Card.CardType.DEBUFF,
		Card.TargetType.SINGLE_ENEMY,
		1, 0, 0, 0, 0
	)
	all_cards["weak_point"].apply_vulnerable = 2

	all_cards["medkit"] = create_card(
		"Medkit",
		"Heal 10 HP. Apply 1 Decay.",
		Card.CardType.HEAL,
		Card.TargetType.SELF,
		2, 0, 10, 0, 0
	)
	all_cards["medkit"].apply_decay = 1

	# v2 Card System - Fighter's Spirit
	var fighters_spirit_v1 = create_card(
		"Fighter's Spirit",
		"Channel your inner strength.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 0, 0
	)
	fighters_spirit_v1.apply_strength = 1
	fighters_spirit_v1.has_v2 = true
	fighters_spirit_v1.v2_card_id = "fighters_spirit_v2"

	var fighters_spirit_v2 = create_card(
		"Fighter's Spirit V2",
		"Fortify your defenses.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 5, 0
	)
	all_cards["fighters_spirit_v2"] = fighters_spirit_v2

	fighters_spirit_v1.v2_card = fighters_spirit_v2
	all_cards["fighters_spirit"] = fighters_spirit_v1

	all_cards["sacrifice"] = create_card(
		"Sacrifice",
		"Empower an ally with your strength.",
		Card.CardType.BUFF,
		Card.TargetType.SINGLE_ALLY,
		1, 0, 0, 0, 0
	)
	all_cards["sacrifice"].apply_strength = 1

	# v2 Card System - Leader
	var leader_v1 = create_card(
		"Leader",
		"All teammates draw 1 card.",
		Card.CardType.BUFF,
		Card.TargetType.OTHER_ALLIES,
		0, 0, 0, 0, 1  # 0 cost, draw 1 for other allies
	)
	leader_v1.has_v2 = true
	leader_v1.v2_card_id = "leader_v2"
	leader_v1.plays_immediately = true

	var leader_v2 = create_card(
		"Leader V2",
		"Discard 2 random cards. Teammates draw 2.",
		Card.CardType.BUFF,
		Card.TargetType.OTHER_ALLIES,
		0, 0, 0, 0, 2  # 0 cost, draw 2 for other allies
	)
	leader_v2.caster_discards_random = 2
	leader_v2.plays_immediately = true
	all_cards["leader_v2"] = leader_v2

	leader_v1.v2_card = leader_v2
	all_cards["leader"] = leader_v1

	# v2 Card System - Test
	var test_v1 = create_card(
		"Test",
		"All teammates draw 1 card.",
		Card.CardType.BUFF,
		Card.TargetType.OTHER_ALLIES,
		0, 0, 0, 0, 1  # 0 cost, draw 1 for other allies
	)
	test_v1.has_v2 = true
	test_v1.v2_card_id = "test_v2"
	test_v1.plays_immediately = true

	var test_v2 = create_card(
		"Test V2",
		"Discard 2 random cards. Teammates draw 2.",
		Card.CardType.BUFF,
		Card.TargetType.OTHER_ALLIES,
		0, 0, 0, 0, 2  # 0 cost, draw 2 for other allies
	)
	test_v2.caster_discards_random = 2
	test_v2.plays_immediately = true
	all_cards["test_v2"] = test_v2

	test_v1.v2_card = test_v2
	all_cards["test"] = test_v1

	# Shared reward card (used by multiple characters)
	all_cards["energy"] = create_card(
		"Energy!",
		"Gain 1 stamina immediately.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		0, 0, 0, 0, 0
	)
	all_cards["energy"].stamina_gain = 1
	all_cards["energy"].plays_immediately = true

	# === NEW DEMONSTRATION CARDS (Composability Examples) ===

	all_cards["vampiric_strike"] = create_card(
		"Vampiric Strike",
		"Drain the life from your enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 12, 0, 0, 0
	)
	all_cards["vampiric_strike"].lifesteal = true

	all_cards["fortify"] = create_card(
		"Fortify",
		"Harden your defenses permanently.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		2, 0, 0, 10, 0
	)
	all_cards["fortify"].apply_armor = 3

	all_cards["toxic_cloud"] = create_card(
		"Toxic Cloud",
		"Poison all enemies with noxious fumes.",
		Card.CardType.SPELL,
		Card.TargetType.ALL_ENEMIES,
		3, 8, 0, 0, 0
	)
	all_cards["toxic_cloud"].apply_poison = 4
	all_cards["toxic_cloud"].aoe_damage = true

	all_cards["dark_pact"] = create_card(
		"Dark Pact",
		"Sacrifice health for power and knowledge.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, -5, 0, 2
	)
	all_cards["dark_pact"].apply_strength = 4

	all_cards["blazing_fury"] = create_card(
		"Blazing Fury",
		"Channel rage into a devastating strike that weakens enemies.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 15, 0, 0, 0
	)
	all_cards["blazing_fury"].apply_burn = 3
	all_cards["blazing_fury"].apply_vulnerable = 2

	all_cards["ember"] = create_card(
		"Ember",
		"A small flame token.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		0, 4, 0, 0, 0
	)

	all_cards["pyroclasm"] = create_card(
		"Pyroclasm",
		"Massive explosion that generates embers.",
		Card.CardType.SPELL,
		Card.TargetType.ALL_ENEMIES,
		4, 18, 0, 0, 0
	)
	all_cards["pyroclasm"].aoe_damage = true
	var pyroclasm_embers: Array[String] = ["ember", "ember"]
	all_cards["pyroclasm"].generate_cards = pyroclasm_embers

	# === MINION CARDS (Boss 1: Swarm of Racoons + Alex) ===

	all_cards["ankle_nibble"] = create_card(
		"Ankle Nibble",
		"Quick bite at the ankles.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 5, 0, 0, 0
	)

	all_cards["swarm"] = create_card(
		"Swarm!",
		"The swarm attacks everyone!",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		1, 3, 0, 0, 0
	)
	all_cards["swarm"].aoe_damage = true

	all_cards["monkey_punch"] = create_card(
		"Monkey Punch!",
		"Alex throws a punch.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 5, 0, 0, 0
	)

	all_cards["it_bit_my_hand"] = create_card(
		"It bit my Hand!",
		"A nasty bite that slows you down.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 3, 0, 0, 0
	)
	all_cards["it_bit_my_hand"].apply_hinder = 1

	all_cards["anger"] = create_card(
		"Anger",
		"Alex gets angry and stronger!",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		0, 0, 0, 0, 0
	)
	all_cards["anger"].apply_strength = 2

	# === GENERIC REWARD CARDS ===

	# RARE CARDS (Powerful rewards)
	all_cards["apocalypse"] = create_card(
		"Apocalypse",
		"Destroy everything. Deals massive damage to all enemies.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		4, 30, 0, 0, 0
	)
	all_cards["apocalypse"].aoe_damage = true

	all_cards["divine_intervention"] = create_card(
		"Divine Intervention",
		"Fully heal and gain massive shield.",
		Card.CardType.HEAL,
		Card.TargetType.SELF,
		3, 0, 50, 30, 0
	)

	all_cards["berserker_rage"] = create_card(
		"Berserker Rage",
		"Gain massive strength. Unleash fury!",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		2, 0, 0, 0, 0
	)
	all_cards["berserker_rage"].apply_strength = 5

	all_cards["meteor_swarm"] = create_card(
		"Meteor Swarm",
		"Rain fire from the heavens! Multi-hit AoE.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		3, 12, 0, 0, 0
	)
	all_cards["meteor_swarm"].multi_hit = 3
	all_cards["meteor_swarm"].aoe_damage = true

	all_cards["time_stop"] = create_card(
		"Time Stop",
		"Draw 5 cards instantly.",
		Card.CardType.SPELL,
		Card.TargetType.SELF,
		2, 0, 0, 0, 5
	)

	all_cards["life_drain"] = create_card(
		"Life Drain",
		"Massive damage that heals you.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		3, 25, 0, 0, 0
	)
	all_cards["life_drain"].lifesteal = true

	all_cards["annihilation"] = create_card(
		"Annihilation",
		"Pierce all defenses. Pure destruction.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		3, 35, 0, 0, 0
	)
	all_cards["annihilation"].piercing = true

	all_cards["omnipotence"] = create_card(
		"Omnipotence",
		"Gain strength, armor, and draw cards.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		3, 0, 0, 15, 3
	)
	all_cards["omnipotence"].apply_strength = 3
	all_cards["omnipotence"].apply_armor = 3

	# COMMON CARDS (Decent rewards)
	all_cards["steel_strike"] = create_card(
		"Steel Strike",
		"Solid attack with good damage.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 16, 0, 0, 0
	)

	all_cards["healing_potion"] = create_card(
		"Healing Potion",
		"Restore health quickly.",
		Card.CardType.HEAL,
		Card.TargetType.SELF,
		1, 0, 15, 0, 0
	)

	all_cards["fortify"] = create_card(
		"Fortify",
		"Gain good shield.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 12, 0
	)

	all_cards["power_strike"] = create_card(
		"Power Strike",
		"Heavy single target damage.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 18, 0, 0, 0
	)

	all_cards["battle_focus"] = create_card(
		"Battle Focus",
		"Gain strength and draw a card.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		2, 0, 0, 0, 1
	)
	all_cards["battle_focus"].apply_strength = 2

	all_cards["cleave"] = create_card(
		"Cleave",
		"Hit all enemies for decent damage.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		2, 10, 0, 0, 0
	)
	all_cards["cleave"].aoe_damage = true

	all_cards["rejuvenation"] = create_card(
		"Rejuvenation",
		"Heal and gain shield.",
		Card.CardType.HEAL,
		Card.TargetType.SELF,
		2, 0, 12, 8, 0
	)

	all_cards["iron_will"] = create_card(
		"Iron Will",
		"Solid shield and armor.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		2, 0, 0, 10, 0
	)
	all_cards["iron_will"].apply_armor = 2

	all_cards["quick_strike"] = create_card(
		"Quick Strike",
		"Fast, efficient damage.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 12, 0, 0, 0
	)

	all_cards["tactical_advantage"] = create_card(
		"Tactical Advantage",
		"Draw 2 cards.",
		Card.CardType.SPELL,
		Card.TargetType.SELF,
		1, 0, 0, 0, 2
	)
	all_cards["tactical_advantage"].plays_immediately = true

## Factory function for creating cards with basic stats
##
## @param name: Card display name
## @param desc: Description text shown on card
## @param type: Card type (ATTACK, SPELL, BUFF, DEBUFF, HEAL)
## @param target: Who can be targeted (SELF, SINGLE_ENEMY, ALL_ENEMIES, etc.)
## @param cost: Energy required to play (0-5 typically)
## @param dmg: Base damage dealt (0 if no damage)
## @param heal: HP restored (0 if no healing, can be negative for self-harm)
## @param shield: Temporary HP gained (0 if no shield)
## @param draw: Cards drawn when played (0 if no card draw)
## @returns: New Card instance with properties set
##
## NOTE: For advanced effects (burn, poison, lifesteal, etc.), set properties
##       on the returned Card object after calling this function.
func create_card(name: String, desc: String, type: Card.CardType, target: Card.TargetType,
				 cost: int, dmg: int, heal: int, shield: int, draw: int) -> Card:
	var card = Card.new()
	card.card_name = name
	card.description = desc
	card.card_type = type
	card.target_type = target
	card.stamina_cost = cost
	card.damage = dmg
	card.heal_amount = heal
	card.shield_amount = shield
	card.draw_cards = draw
	return card

func get_card(card_id: String) -> Card:
	if all_cards.has(card_id):
		var original = all_cards[card_id]
		var copy = original.duplicate()
		# v2_card_id is @export so it's copied by duplicate()
		# v2_card reference can be set locally for efficiency
		if original.has_v2 and original.v2_card != null:
			copy.v2_card = original.v2_card.duplicate()
		return copy
	else:
		push_error("Card not found: " + card_id)
		return null

# === REWARD CARD GETTERS ===

func get_rare_cards() -> Array[Card]:
	var rare_pool: Array[Card] = []
	rare_pool.append(all_cards["apocalypse"].duplicate())
	rare_pool.append(all_cards["divine_intervention"].duplicate())
	rare_pool.append(all_cards["berserker_rage"].duplicate())
	rare_pool.append(all_cards["meteor_swarm"].duplicate())
	rare_pool.append(all_cards["time_stop"].duplicate())
	rare_pool.append(all_cards["life_drain"].duplicate())
	rare_pool.append(all_cards["annihilation"].duplicate())
	rare_pool.append(all_cards["omnipotence"].duplicate())
	return rare_pool

func get_common_cards() -> Array[Card]:
	var common_pool: Array[Card] = []
	common_pool.append(all_cards["steel_strike"].duplicate())
	common_pool.append(all_cards["healing_potion"].duplicate())
	common_pool.append(all_cards["fortify"].duplicate())
	common_pool.append(all_cards["power_strike"].duplicate())
	common_pool.append(all_cards["battle_focus"].duplicate())
	common_pool.append(all_cards["cleave"].duplicate())
	common_pool.append(all_cards["rejuvenation"].duplicate())
	common_pool.append(all_cards["iron_will"].duplicate())
	common_pool.append(all_cards["quick_strike"].duplicate())
	common_pool.append(all_cards["tactical_advantage"].duplicate())
	return common_pool
