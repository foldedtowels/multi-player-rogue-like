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
	# === LIFE WEAVER CARDS (Selene - Healing/Buffs) ===
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

	# === FABIO CARDS (Phase 1 - The Warrior) ===

	# Base Deck Cards (9)
	all_cards["slash"] = create_card(
		"Slash",
		"Deal 7 damage. TARGET: 1 Enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 7, 0, 0, 0
	)

	all_cards["big_smack"] = create_card(
		"Big Smack",
		"Deal 10 damage. TARGET: 1 Enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		3, 10, 0, 0, 0
	)

	all_cards["duel_purpose"] = create_card(
		"Duel Purpose",
		"Deal 3 damage and gain 5 Shield. TARGET: 1 Enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 3, 0, 5, 0
	)

	all_cards["rest"] = create_card(
		"Rest",
		"Gain Rested (draw 1 extra card next turn). TARGET: Self.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 0, 0
	)
	all_cards["rest"].apply_rested = 1

	all_cards["bulk_up"] = create_card(
		"Bulk Up",
		"Gain 1 Invigorated (+2 damage next attack) and 1 Fatigued (-1 stamina next turn). TARGET: Self.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		0, 0, 0, 0, 0
	)
	all_cards["bulk_up"].apply_invigorated = 1
	all_cards["bulk_up"].apply_fatigued = 1  # -1 stamina next turn

	all_cards["dig_a_hole"] = create_card(
		"Dig a Hole",
		"Plays instantly. Pick 1 card in your hand to keep until played or end of next turn. TARGET: Self.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		0, 0, 0, 0, 0  # No draw cards - retention only
	)
	all_cards["dig_a_hole"].plays_immediately = true
	all_cards["dig_a_hole"].grants_card_retain = true

	all_cards["protector"] = create_card(
		"Protector",
		"This turn all enemy attacks on target ally hit you instead. TARGET: 1 Ally.",
		Card.CardType.BUFF,
		Card.TargetType.SINGLE_ALLY,
		0, 0, 0, 0, 0  # No shield - just redirects attacks
	)
	all_cards["protector"].swaps_enemy_target = true

	all_cards["protective_footwear"] = create_card(
		"Protective Footwear",
		"Gain 5 Shield. TARGET: Self.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 5, 0
	)

	all_cards["hunters_instinct"] = create_card(
		"Hunter's Instinct",
		"Plays instantly. Reveal the boss's cards for next turn. TARGET: Self.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 0, 0  # No card draw - reveals boss intent
	)
	all_cards["hunters_instinct"].plays_immediately = true
	all_cards["hunters_instinct"].reveals_boss_intent = true

	# Reward Cards (17)
	all_cards["dual_wield"] = create_card(
		"Dual Wield",
		"Hit twice for 2 damage each (4 total). TARGET: 1 Enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 2, 0, 0, 0
	)
	all_cards["dual_wield"].multi_hit = 2

	all_cards["circular_strike"] = create_card(
		"Circular Strike",
		"Deal 3 damage to ALL enemies. TARGET: All Enemies.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		1, 3, 0, 0, 0
	)
	all_cards["circular_strike"].aoe_damage = true

	all_cards["cursed_dagger"] = create_card(
		"Cursed Dagger",
		"Deal 2 damage. TARGET: 1 Enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		0, 2, 0, 0, 0
	)

	all_cards["jumping_strike"] = create_card(
		"Jumping Strike",
		"Next turn: Deal 5 damage IF you took no damage this turn. TARGET: 1 Enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 0, 0, 0, 0  # 0 immediate damage
	)
	all_cards["jumping_strike"].is_delayed_damage = true
	all_cards["jumping_strike"].delay_condition = "no_damage_taken"
	all_cards["jumping_strike"].delayed_damage_amount = 5

	all_cards["execution"] = create_card(
		"Execution",
		"Deal 4 damage. +4 bonus damage if target is below 50% HP. TARGET: 1 Enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 4, 0, 0, 0
	)
	all_cards["execution"].bonus_damage_if_wounded = 4

	all_cards["frenzy"] = create_card(
		"Frenzy!",
		"Deal 8 damage to ALL enemies. Gain 2 Exhausted (can't play cards until it wears off). TARGET: All Enemies.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		2, 8, 0, 0, 0
	)
	all_cards["frenzy"].aoe_damage = true
	all_cards["frenzy"].apply_exhausted = 2  # Exhausted lasts until end of next turn

	all_cards["weak_point"] = create_card(
		"Weak Point!",
		"Deal 2 damage +2 per debuff on target. TARGET: 1 Enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 2, 0, 0, 0
	)
	all_cards["weak_point"].bonus_damage_per_debuff = 2

	all_cards["medkit"] = create_card(
		"Medkit",
		"Heal 10 HP. Gain 1 Decay (-1 max HP permanently). TARGET: Self.",
		Card.CardType.HEAL,
		Card.TargetType.SELF,
		2, 0, 10, 0, 0
	)
	all_cards["medkit"].apply_decay = 1

	# v2 Card System - Fighter's Spirit
	var fighters_spirit_v1 = create_card(
		"Fighter's Spirit",
		"CHOICE: Drop on Self to remove 1 debuff. OR gain 5 Shield instead. TARGET: Self.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 0, 0
	)
	fighters_spirit_v1.remove_target_debuffs = 1
	fighters_spirit_v1.has_v2 = true
	fighters_spirit_v1.v2_card_id = "fighters_spirit_v2"

	var fighters_spirit_v2 = create_card(
		"Fighter's Spirit V2",
		"Gain 5 Shield. TARGET: Self.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 5, 0
	)
	all_cards["fighters_spirit_v2"] = fighters_spirit_v2

	fighters_spirit_v1.v2_card = fighters_spirit_v2
	all_cards["fighters_spirit"] = fighters_spirit_v1

	all_cards["sacrifice"] = create_card(
		"Sacrifice",
		"Give target 1 Strength (+2 damage per attack). TARGET: 1 Ally.",
		Card.CardType.BUFF,
		Card.TargetType.SINGLE_ALLY,
		1, 0, 0, 0, 0
	)
	all_cards["sacrifice"].apply_strength = 1

	# v2 Card System - Leader
	var leader_v1 = create_card(
		"Leader",
		"Plays instantly. CHOICE: All OTHER allies draw 1 card. OR discard 2 random cards and all OTHER allies draw 2. TARGET: Other Allies.",
		Card.CardType.BUFF,
		Card.TargetType.OTHER_ALLIES,
		0, 0, 0, 0, 1  # 0 cost, draw 1 for other allies
	)
	leader_v1.has_v2 = true
	leader_v1.v2_card_id = "leader_v2"
	leader_v1.plays_immediately = true

	var leader_v2 = create_card(
		"Leader V2",
		"Discard 2 random cards. All OTHER allies draw 2 cards. TARGET: Other Allies.",
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
		"Plays instantly. Gain 1 stamina. TARGET: Self.",
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
		"Deal 3 damage. TARGET: 1 Enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 3, 0, 0, 0
	)

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

	# === ENRIQUE - THE CLERIC (Divine Aura) ===
	# Base Deck

	# Expulsion: 2 stamina, ALL aura, deal 3 damage per aura spent to all enemies
	all_cards["expulsion"] = create_card(
		"Expulsion",
		"Spends ALL your Aura. Deal 3 damage per aura spent to ALL enemies. TARGET: All Enemies.",
		Card.CardType.ATTACK,
		Card.TargetType.ALL_ENEMIES,
		2, 0, 0, 0, 0
	)
	all_cards["expulsion"].aura_cost_all = true
	all_cards["expulsion"].damage_per_aura_spent = 3
	all_cards["expulsion"].aoe_damage = true

	# Focused Purge: 1 stamina, 0 aura, 3 damage, gain 1 aura
	all_cards["focused_purge"] = create_card(
		"Focused Purge",
		"Deal 3 damage. Gain 1 Aura. TARGET: 1 Enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 3, 0, 0, 0
	)
	all_cards["focused_purge"].aura_gain = 1

	# Holy Plight: 1 stamina, 2 aura, 5 damage
	all_cards["holy_plight"] = create_card(
		"Holy Plight",
		"Deal 5 damage. TARGET: 1 Enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 5, 0, 0, 0
	)
	all_cards["holy_plight"].aura_cost = 2

	# Prayer Beads (Special): 1 stamina, 1 aura, D6 damage
	all_cards["prayer_beads"] = create_card(
		"Prayer Beads",
		"Deal 1-6 random damage (rolls a D6). TARGET: 1 Enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		1, 0, 0, 0, 0
	)
	all_cards["prayer_beads"].aura_cost = 1
	all_cards["prayer_beads"].damage_is_d6 = true

	# Humble Request: 1 stamina, 0 aura, gain 2 aura
	all_cards["humble_request"] = create_card(
		"Humble Request",
		"Gain 2 Aura. TARGET: Self.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 0, 0
	)
	all_cards["humble_request"].aura_gain = 2

	# Divine Reflection: 0 stamina, 3 aura, target's next card plays twice
	all_cards["divine_reflection"] = create_card(
		"Divine Reflection",
		"Target ally's next card plays twice. TARGET: 1 Ally.",
		Card.CardType.BUFF,
		Card.TargetType.SINGLE_ALLY,
		0, 0, 0, 0, 0
	)
	all_cards["divine_reflection"].aura_cost = 3
	all_cards["divine_reflection"].grants_played_twice = true

	# Healing Aura: 0 stamina, 2 aura, heal 10, apply decay to self
	all_cards["healing_aura"] = create_card(
		"Healing Aura",
		"Heal target 10 HP. You gain 1 Decay (-1 max HP permanently). TARGET: 1 Ally.",
		Card.CardType.HEAL,
		Card.TargetType.SINGLE_ALLY,
		0, 0, 10, 0, 0
	)
	all_cards["healing_aura"].aura_cost = 2
	all_cards["healing_aura"].apply_decay = 1

	# Magical Purge: 0 stamina, 2 aura, remove 1 debuff from self
	all_cards["magical_purge"] = create_card(
		"Magical Purge",
		"Remove 1 debuff from yourself. TARGET: Self.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		0, 0, 0, 0, 0
	)
	all_cards["magical_purge"].aura_cost = 2
	all_cards["magical_purge"].remove_target_debuffs = 1

	# Story Of Jacob: 1 stamina, 0 aura, gain 5 aura, apply fatigued to self
	all_cards["story_of_jacob"] = create_card(
		"Story Of Jacob",
		"Gain 5 Aura. Gain 1 Fatigued (-1 stamina next turn). TARGET: Self.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 0, 0
	)
	all_cards["story_of_jacob"].aura_gain = 5
	all_cards["story_of_jacob"].apply_fatigued = 1

	# Protection: 1 stamina, 1 aura, give ally 5 shield
	all_cards["protection"] = create_card(
		"Protection",
		"Give target 5 Shield. TARGET: 1 Ally.",
		Card.CardType.BUFF,
		Card.TargetType.SINGLE_ALLY,
		1, 0, 0, 5, 0
	)
	all_cards["protection"].aura_cost = 1

	# === ENRIQUE REWARD CARDS ===

	# Divine Force: 2 stamina, 2 aura, heal 10, apply decay to self
	all_cards["divine_force"] = create_card(
		"Divine Force",
		"CHOICE: Drop on Ally to heal 10 HP (you gain 1 Decay). Drop on Enemy to deal 6 damage.",
		Card.CardType.HEAL,
		Card.TargetType.SINGLE_ALLY,
		2, 0, 10, 0, 0
	)
	all_cards["divine_force"].aura_cost = 2
	all_cards["divine_force"].apply_decay = 1
	all_cards["divine_force"].has_v2 = true
	all_cards["divine_force"].v2_card_id = "divine_force_v2"
	all_cards["divine_force"].context_sensitive_v2 = true  # Drop target determines version

	# Divine Force v2: 2 stamina, 2 aura, 6 damage
	all_cards["divine_force_v2"] = create_card(
		"Divine Force",
		"Deal 6 damage. TARGET: 1 Enemy.",
		Card.CardType.ATTACK,
		Card.TargetType.SINGLE_ENEMY,
		2, 6, 0, 0, 0
	)
	all_cards["divine_force_v2"].aura_cost = 2

	# Purging Water: 1 stamina, 1 aura, remove 1 debuff from ally
	all_cards["purging_water"] = create_card(
		"Purging Water",
		"Remove 1 debuff from target ally. TARGET: 1 Ally.",
		Card.CardType.BUFF,
		Card.TargetType.SINGLE_ALLY,
		1, 0, 0, 0, 0
	)
	all_cards["purging_water"].aura_cost = 1
	all_cards["purging_water"].remove_target_debuffs = 1

	# Divine Barrier: 1 stamina, 3 aura, grant invincible to ally
	all_cards["divine_barrier"] = create_card(
		"Divine Barrier",
		"Target ally becomes Invincible (takes no damage) this turn. TARGET: 1 Ally.",
		Card.CardType.BUFF,
		Card.TargetType.SINGLE_ALLY,
		1, 0, 0, 0, 0
	)
	all_cards["divine_barrier"].aura_cost = 3
	all_cards["divine_barrier"].grants_invincible = true

	# Refuge: 1 stamina, 0 aura, 5 shield, gain 1 aura
	all_cards["refuge"] = create_card(
		"Refuge",
		"Gain 5 Shield and 1 Aura. TARGET: Self.",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		1, 0, 0, 5, 0
	)
	all_cards["refuge"].aura_gain = 1

	# Gift: 0 stamina, 2 aura, ally draws 2 cards
	all_cards["gift"] = create_card(
		"Gift",
		"Target ally draws 2 cards. TARGET: 1 Ally.",
		Card.CardType.BUFF,
		Card.TargetType.SINGLE_ALLY,
		0, 0, 0, 0, 2
	)
	all_cards["gift"].aura_cost = 2

	# Divine Gift: 2 stamina, 2 aura, give ally 2 stamina
	all_cards["divine_gift"] = create_card(
		"Divine Gift",
		"Give target ally 2 stamina. TARGET: 1 Ally.",
		Card.CardType.BUFF,
		Card.TargetType.SINGLE_ALLY,
		2, 0, 0, 0, 0
	)
	all_cards["divine_gift"].aura_cost = 2
	all_cards["divine_gift"].target_stamina_gain = 2

	# Guy with Beard: 0 stamina, 2 aura, all players draw 1
	all_cards["guy_with_beard"] = create_card(
		"Guy with Beard",
		"ALL players draw 1 card. TARGET: Self (affects all).",
		Card.CardType.BUFF,
		Card.TargetType.SELF,
		0, 0, 0, 0, 0
	)
	all_cards["guy_with_beard"].aura_cost = 2
	all_cards["guy_with_beard"].all_players_draw = 1

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
