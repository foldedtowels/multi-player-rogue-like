class_name EnemyCardsData
## Enemy Cards - Bosses and Minions
##
## Cards used by all enemy types (bosses and minions).
## Organized by enemy type.

const CARDS = {
	# =============================================================================
	# GIANT MOOSE CARDS (Boss 1)
	# =============================================================================
	"charge": {
		"card_name": "Charge",
		"description": "Rush at the weakest target.",
		"card_type": "ATTACK",
		"target_type": "LOWEST_HP",
		"stamina_cost": 1,
		"damage": 8
	},
	"stomp": {
		"card_name": "Stomp",
		"description": "Shake the ground beneath all foes.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 1,
		"damage": 5,
		"aoe_damage": true
	},
	"knocked_off_your_feet": {
		"card_name": "Knocked Off your Feet",
		"description": "A powerful blow that staggers the target.",
		"card_type": "ATTACK",
		"target_type": "HIGHEST_HP",
		"stamina_cost": 1,
		"damage": 5,
		"apply_hinder": 2
	},
	"roar": {
		"card_name": "Roar!",
		"description": "A terrifying bellow that frightens enemies.",
		"card_type": "DEBUFF",
		"target_type": "HIGHEST_HP",
		"stamina_cost": 1,
		"apply_scared": 1
	},
	"forage": {
		"card_name": "Forage",
		"description": "Find sustenance in the wild.",
		"card_type": "HEAL",
		"target_type": "SELF",
		"stamina_cost": 1,
		"heal_amount": 10
	},
	"fur_coat": {
		"card_name": "Fur Coat",
		"description": "Thick hide provides protection.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"shield_amount": 3
	},

	# =============================================================================
	# MR. 67 CARDS (Boss 2)
	# =============================================================================
	"big_punch": {
		"card_name": "Big Punch",
		"description": "A devastating punch to the nearest target.",
		"card_type": "ATTACK",
		"target_type": "CCW_PLAYER",
		"stamina_cost": 1,
		"damage": 7
	},
	"gut_punch": {
		"card_name": "Gut Punch",
		"description": "A punch that leaves you scared.",
		"card_type": "ATTACK",
		"target_type": "CCW_PLAYER",
		"stamina_cost": 1,
		"damage": 5,
		"apply_scared": 1
	},
	"ground_smash": {
		"card_name": "Ground Smash",
		"description": "Smash the ground, hitting everyone.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 1,
		"damage": 5,
		"aoe_damage": true
	},
	"protein_shake": {
		"card_name": "Protein Shake",
		"description": "Drink a shake to gain strength.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"apply_strength": 2
	},
	"muscle_shield": {
		"card_name": "Muscle Shield",
		"description": "Flex those muscles for protection.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"shield_amount": 5
	},
	"intimidating_flex": {
		"card_name": "Intimidating Flex",
		"description": "A flex so intimidating it hinders the target.",
		"card_type": "DEBUFF",
		"target_type": "HIGHEST_HP",
		"stamina_cost": 1,
		"apply_hinder": 2
	},

	# =============================================================================
	# SWARM OF RACCOONS CARDS (Minion - Boss 1)
	# =============================================================================
	"ankle_nibble": {
		"card_name": "Ankle Nibble",
		"description": "Quick bite at the ankles.",
		"card_type": "ATTACK",
		"target_type": "CCW_PLAYER",
		"stamina_cost": 1,
		"damage": 5
	},
	"swarm": {
		"card_name": "Swarm!",
		"description": "The swarm attacks everyone!",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 1,
		"damage": 3,
		"aoe_damage": true
	},

	# =============================================================================
	# ALEX THE MONKEY CARDS (Minion - Boss 1)
	# =============================================================================
	"monkey_punch": {
		"card_name": "Monkey Punch!",
		"description": "Alex throws a punch.",
		"card_type": "ATTACK",
		"target_type": "CCW_PLAYER",
		"stamina_cost": 1,
		"damage": 5
	},
	"it_bit_my_hand": {
		"card_name": "It bit my Hand!",
		"description": "A nasty bite to the strongest target.",
		"card_type": "ATTACK",
		"target_type": "HIGHEST_HP",
		"stamina_cost": 1,
		"damage": 3
	},
	"anger": {
		"card_name": "Anger",
		"description": "Get angry and stronger!",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"apply_strength": 2
	},

	# =============================================================================
	# BROCK CARDS (Minion - Boss 2)
	# =============================================================================
	"minion_punch": {
		"card_name": "Punch!",
		"description": "A basic punch attack.",
		"card_type": "ATTACK",
		"target_type": "CCW_PLAYER",
		"stamina_cost": 1,
		"damage": 5
	},
	"brawl": {
		"card_name": "Brawl",
		"description": "Attack all enemies in a brawl.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 1,
		"damage": 4,
		"aoe_damage": true
	},

	# =============================================================================
	# MOMMY CARDS (Minion - Boss 2)
	# =============================================================================
	"angwy_punch": {
		"card_name": "Angwy Punch",
		"description": "An angry punch. Deals +5 damage if Mommy took damage this turn.",
		"card_type": "ATTACK",
		"target_type": "HIGHEST_HP",
		"stamina_cost": 1,
		"damage": 5,
		"damage_threshold_check": 1,
		"damage_threshold_modifier": 5
	},
	"seduction": {
		"card_name": "Seduction",
		"description": "A seductive look that hinders the target.",
		"card_type": "DEBUFF",
		"target_type": "CCW_PLAYER",
		"stamina_cost": 0,
		"apply_hinder": 2
	},

	# =============================================================================
	# TROGDOR CARDS (Minion - Boss 2)
	# =============================================================================
	"vulnerable_approach": {
		"card_name": "Vulnerable Approach",
		"description": "Deals 10 damage, but 0 if Trogdor took 10+ damage this turn.",
		"card_type": "ATTACK",
		"target_type": "LOWEST_HP",
		"stamina_cost": 1,
		"damage": 10,
		"damage_threshold_check": 10,
		"damage_threshold_modifier": -10
	},
	"handicap_helmet": {
		"card_name": "Handicap Helmet",
		"description": "Put on the protective helmet.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"shield_amount": 3
	},

	# =============================================================================
	# GIANT CENTIPEDE CARDS (Minion - Boss 3)
	# =============================================================================
	"venomous_bite": {
		"card_name": "Venomous Bite",
		"description": "A poisonous bite that injects venom.",
		"card_type": "ATTACK",
		"target_type": "CCW_PLAYER",
		"stamina_cost": 1,
		"damage": 7,
		"apply_venom": 1
	},
	"beastly_chomp": {
		"card_name": "Beastly Chomp",
		"description": "A powerful bite attack.",
		"card_type": "ATTACK",
		"target_type": "CCW_PLAYER",
		"stamina_cost": 1,
		"damage": 10
	},
	"poison_cloud": {
		"card_name": "Poison Cloud",
		"description": "Release a cloud of venom affecting all players.",
		"card_type": "DEBUFF",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 0,
		"apply_venom": 1
	},
	"exoskeleton": {
		"card_name": "Exoskeleton",
		"description": "Harden the outer shell for protection.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"shield_amount": 5
	},

	# =============================================================================
	# SPIDER-QUEEN CARDS (Boss 3)
	# =============================================================================
	"venom_bite": {
		"card_name": "Venom Bite",
		"description": "A venomous bite that injects poison.",
		"card_type": "ATTACK",
		"target_type": "CCW_PLAYER",
		"stamina_cost": 1,
		"damage": 7,
		"apply_venom": 1
	},
	"heavy_strike": {
		"card_name": "Heavy Strike",
		"description": "A powerful crushing blow.",
		"card_type": "ATTACK",
		"target_type": "CCW_PLAYER",
		"stamina_cost": 1,
		"damage": 10
	},
	"venom_spray": {
		"card_name": "Venom Spray",
		"description": "Spray venom on all enemies.",
		"card_type": "DEBUFF",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 0,
		"apply_venom": 1
	},
	"web_shield": {
		"card_name": "Web Shield",
		"description": "Wrap yourself in protective webbing.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"shield_amount": 5
	},
	"terrify": {
		"card_name": "Terrify",
		"description": "Strike fear into a random enemy's heart.",
		"card_type": "DEBUFF",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 0,
		"apply_scared": 1
	},
	"spawn_spiderling": {
		"card_name": "Spawn Spiderling",
		"description": "Summon a Spiderling to aid in battle.",
		"card_type": "SUMMON",
		"target_type": "SELF",
		"stamina_cost": 0,
		"summon_minion_tag": "spiderling",
		"summon_count": 1
	},

	# =============================================================================
	# SPIDERLING CARDS (Summoned Minions)
	# =============================================================================
	"spiderling_venom_bite": {
		"card_name": "Spiderling Bite",
		"description": "A small but venomous bite.",
		"card_type": "ATTACK",
		"target_type": "HIGHEST_HP",
		"stamina_cost": 1,
		"damage": 5,
		"apply_venom": 1
	},
	"spiderling_swarm": {
		"card_name": "Spiderling Swarm",
		"description": "Attack all enemies in a swarm.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 1,
		"damage": 5,
		"aoe_damage": true
	},
	"spiderling_venom_snipe": {
		"card_name": "Venom Snipe",
		"description": "A precise venomous strike on the weakest target.",
		"card_type": "ATTACK",
		"target_type": "LOWEST_HP",
		"stamina_cost": 1,
		"damage": 5,
		"apply_venom": 1
	},

	# =============================================================================
	# WENDIGO CARDS (Minion - Boss 3)
	# =============================================================================
	"wendigo_rend": {
		"card_name": "Rend",
		"description": "Tear into the nearest target.",
		"card_type": "ATTACK",
		"target_type": "CCW_PLAYER",
		"stamina_cost": 1,
		"damage": 10
	},
	"wendigo_slash": {
		"card_name": "Slash",
		"description": "A quick slashing attack.",
		"card_type": "ATTACK",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 1,
		"damage": 7
	},
	"wendigo_chomp": {
		"card_name": "Chomp!",
		"description": "Bite down on a random foe.",
		"card_type": "ATTACK",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 1,
		"damage": 5
	},
	"wendigo_howl": {
		"card_name": "Howl",
		"description": "Let out a primal howl to gain strength.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"apply_strength": 2
	},
	"wendigo_roar": {
		"card_name": "Roar!",
		"description": "A terrifying roar that hinders all enemies.",
		"card_type": "DEBUFF",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 0,
		"apply_hinder": 2
	},

	# =============================================================================
	# AMALGAMATION CARDS (Minion - Boss 3)
	# =============================================================================
	"amalgamation_trample": {
		"card_name": "Trample",
		"description": "Stomp on all enemies.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 1,
		"damage": 4,
		"aoe_damage": true
	},
	"amalgamation_smack": {
		"card_name": "Smack",
		"description": "A heavy smack to the nearest target.",
		"card_type": "ATTACK",
		"target_type": "CCW_PLAYER",
		"stamina_cost": 1,
		"damage": 6
	},
	"amalgamation_scary_face": {
		"card_name": "Scary Face",
		"description": "Make a terrifying face that scares a random enemy.",
		"card_type": "DEBUFF",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 0,
		"apply_scared": 1
	},
	"amalgamation_rebuild": {
		"card_name": "Rebuild",
		"description": "Reform the body to heal wounds.",
		"card_type": "HEAL",
		"target_type": "SELF",
		"stamina_cost": 0,
		"heal_amount": 5
	},

	# =============================================================================
	# MUTE CARDS (Boss 4)
	# =============================================================================
	"mute_ravage": {
		"card_name": "Ravage",
		"description": "Tear into the marked target.",
		"card_type": "ATTACK",
		"target_type": "CCW_PLAYER",
		"stamina_cost": 1,
		"damage": 10
	},
	"mute_black_surge": {
		"card_name": "Black Surge",
		"description": "Dark energy strikes all foes.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 1,
		"damage": 6,
		"aoe_damage": true
	},
	"mute_instantiation": {
		"card_name": "Instantiation",
		"description": "Curse a random enemy with a random Doll affliction.",
		"card_type": "DEBUFF",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 1,
		"apply_random_doll": 1
	},
	"mute_hex_acquisition": {
		"card_name": "Hex: Acquisition",
		"description": "Exhaust the top card of all enemies' decks.",
		"card_type": "DEBUFF",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 1,
		"exhaust_target_deck": 1
	},
	"mute_hex_paranoia": {
		"card_name": "Hex: Paranoia",
		"description": "Hinder all enemies, reducing their damage.",
		"card_type": "DEBUFF",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 1,
		"apply_hinder": 2
	},

	# =============================================================================
	# FABIO, THE USURPER CARDS (Boss 5 Minion - Dark Hero)
	# =============================================================================
	"enemy_fabio_big_smack": {
		"card_name": "Big Smack",
		"description": "A devastating blow to a random player.",
		"card_type": "ATTACK",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 1,
		"damage": 10
	},
	"enemy_fabio_circular_strike": {
		"card_name": "Circular Strike",
		"description": "Strike all players.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 1,
		"damage": 5,
		"aoe_damage": true
	},
	"enemy_fabio_endless_strikes": {
		"card_name": "Endless Strikes",
		"description": "Attack the true Fabio 3 times.",
		"card_type": "ATTACK",
		"target_type": "TARGET_BY_NAME",
		"target_player_name": "Fabio",
		"stamina_cost": 1,
		"damage": 2,
		"multi_hit": 3
	},
	"enemy_fabio_execution": {
		"card_name": "Execution",
		"description": "Deal 8 damage to the true Fabio. Double damage if below half health.",
		"card_type": "ATTACK",
		"target_type": "TARGET_BY_NAME",
		"target_player_name": "Fabio",
		"stamina_cost": 1,
		"damage": 8,
		"bonus_damage_if_wounded": 8
	},
	"enemy_fabio_bulk_up": {
		"card_name": "Bulk Up",
		"description": "Gain 2 Strength.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"apply_strength": 2
	},
	"enemy_fabio_protector": {
		"card_name": "Protector",
		"description": "Take damage and debuffs for the weakest ally.",
		"card_type": "BUFF",
		"target_type": "LOWEST_HP_ALLY",
		"stamina_cost": 0,
		"swaps_enemy_target": true
	},
	"enemy_fabio_medkit": {
		"card_name": "Medkit",
		"description": "Heal 10 HP.",
		"card_type": "HEAL",
		"target_type": "SELF",
		"stamina_cost": 0,
		"heal_amount": 10
	},
	"enemy_fabio_fighters_spirit": {
		"card_name": "Fighter's Spirit",
		"description": "Remove all debuffs.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"remove_self_debuffs": true
	},
	"enemy_fabio_protective_footwear": {
		"card_name": "Protective Footwear",
		"description": "Gain 5 Shield.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"shield_amount": 5
	},

	# =============================================================================
	# KEVIN, THE DRUID CARDS (Boss 5 Minion - Dark Hero)
	# =============================================================================
	"enemy_kevin_water_ball": {
		"card_name": "Spell: Water Ball",
		"description": "Deal 2 damage and apply 1 Wet to the true Kevin.",
		"card_type": "ATTACK",
		"target_type": "TARGET_BY_NAME",
		"target_player_name": "Kevin",
		"stamina_cost": 1,
		"damage": 2,
		"apply_wet": 1
	},
	"enemy_kevin_typhoon": {
		"card_name": "Spell: Typhoon",
		"description": "Deal 5 damage and apply 2 Wet.",
		"card_type": "ATTACK",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 1,
		"damage": 5,
		"apply_wet": 2
	},
	"enemy_kevin_lightning_strike": {
		"card_name": "Spell: Lightning Strike",
		"description": "Deal 3 damage to wettest player. +3 per Wet stack.",
		"card_type": "ATTACK",
		"target_type": "MOST_WET",
		"stamina_cost": 1,
		"damage": 3,
		"bonus_damage_per_wet": 3
	},
	"enemy_kevin_tsunami": {
		"card_name": "Spell: Tsunami",
		"description": "Deal 4 damage to all players and apply 1 Wet.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 1,
		"damage": 4,
		"apply_wet": 1,
		"aoe_damage": true
	},
	"enemy_kevin_giant_shield": {
		"card_name": "Spell: Giant Shield",
		"description": "All allies gain 5 Shield.",
		"card_type": "BUFF",
		"target_type": "ALL_ALLIES",
		"stamina_cost": 0,
		"all_allies_shield": 5
	},
	"enemy_kevin_fiery_flash": {
		"card_name": "Spell: Fiery Flash",
		"description": "Apply 2 Hinder to the healthiest player.",
		"card_type": "DEBUFF",
		"target_type": "HIGHEST_HP",
		"stamina_cost": 0,
		"apply_hinder": 2
	},
	"enemy_kevin_ring_of_fire": {
		"card_name": "Spell: Ring of Fire",
		"description": "Weakest ally gains 5 Shield and reflects 3 damage.",
		"card_type": "BUFF",
		"target_type": "LOWEST_HP_ALLY",
		"stamina_cost": 0,
		"shield_amount": 5,
		"apply_ring_of_fire": 1
	},

	# =============================================================================
	# ENRIQUE, THE FALLEN CARDS (Boss 5 Minion - Dark Hero)
	# =============================================================================
	"enemy_enrique_expulsion": {
		"card_name": "Expulsion",
		"description": "Deal damage equal to Aura to all players. Lose all Aura.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 1,
		"damage": 0,
		"aoe_damage": true,
		"aura_cost_all": true,
		"damage_per_aura_spent": 1
	},
	"enemy_enrique_holy_plight": {
		"card_name": "Holy Plight",
		"description": "Deal 5 damage and gain 1 Aura.",
		"card_type": "ATTACK",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 1,
		"damage": 5,
		"aura_gain": 1
	},
	"enemy_enrique_prayer_beads": {
		"card_name": "Prayer Beads",
		"description": "Deal 1-6 damage and gain 1 Aura.",
		"card_type": "ATTACK",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 1,
		"damage": 0,
		"damage_is_d6": true,
		"aura_gain": 1
	},
	"enemy_enrique_humble_request": {
		"card_name": "Humble Request",
		"description": "Gain 2 Aura.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"aura_gain": 2
	},
	"enemy_enrique_healing_aura": {
		"card_name": "Healing Aura",
		"description": "Heal weakest ally for 10 HP.",
		"card_type": "HEAL",
		"target_type": "LOWEST_HP_ALLY",
		"stamina_cost": 0,
		"heal_amount": 10
	},
	"enemy_enrique_protection": {
		"card_name": "Protection",
		"description": "Give weakest ally 5 Shield.",
		"card_type": "BUFF",
		"target_type": "LOWEST_HP_ALLY",
		"stamina_cost": 0,
		"shield_amount": 5
	},
	"enemy_enrique_refuge": {
		"card_name": "Refuge",
		"description": "Gain 5 Shield and 2 Aura.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"shield_amount": 5,
		"aura_gain": 2
	},
	"enemy_enrique_gift": {
		"card_name": "Gift",
		"description": "Random ally gains 2 Strength.",
		"card_type": "BUFF",
		"target_type": "RANDOM_ALLY",
		"stamina_cost": 0,
		"apply_strength": 2
	},

	# =============================================================================
	# THE DOCTOR CARDS (Boss 5)
	# =============================================================================
	"doctor_vile_injection": {
		"card_name": "Vile Injection",
		"description": "A toxic injection that poisons the target.",
		"card_type": "ATTACK",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 1,
		"damage": 7,
		"apply_venom": 1
	},
	"doctor_putrid_mist": {
		"card_name": "Putrid Mist",
		"description": "A cloud of noxious gas that poisons all players.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 1,
		"damage": 5,
		"aoe_damage": true,
		"apply_venom": 1
	},
	"doctor_rupture": {
		"card_name": "Rupture",
		"description": "Exploits afflictions. Deals 4 damage for each debuff stack on target.",
		"card_type": "ATTACK",
		"target_type": "MOST_DEBUFFS",
		"stamina_cost": 1,
		"damage": 0,
		"bonus_damage_per_debuff": 4
	},
	"doctor_deep_stabs": {
		"card_name": "Deep Stabs",
		"description": "Apply 3 Hinder and 3 Bleed, then stab 3 times.",
		"card_type": "ATTACK",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 1,
		"damage": 3,
		"apply_hinder": 3,
		"apply_bleed": 3,
		"multi_hit": 3
	},
	"doctor_potion_goliath": {
		"card_name": "Potion: Goliath",
		"description": "Gain 1 Armor.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"apply_armor": 1
	},
	"doctor_potion_apotheosis": {
		"card_name": "Potion: Apotheosis",
		"description": "Become Invincible this turn.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"grants_invincible": true
	},
	"doctor_potion_rage": {
		"card_name": "Potion: Rage",
		"description": "Gain 2 Strength.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"apply_strength": 2
	},
	"doctor_dark_barrier": {
		"card_name": "Dark Barrier",
		"description": "Gain 8 Shield.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"shield_amount": 8
	},
	"doctor_potion_instantiate": {
		"card_name": "Potion: Instantiate",
		"description": "Inflict a random Doll curse on all players.",
		"card_type": "DEBUFF",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 0,
		"apply_random_doll": 1
	},

	# =============================================================================
	# THE DOCTOR EVENT CARDS (Given to players at fight start)
	# =============================================================================
	"doctor_event_boiling_blood": {
		"card_name": "Potion: Boiling Blood",
		"description": "Remove all debuffs and gain 10 Shield. Gain 3 Bleed. Exhausts.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"remove_self_debuffs": true,
		"shield_amount": 10,
		"caster_bleed": 3,
		"exhausts": true
	},
	"doctor_event_corrupted_incense": {
		"card_name": "Corrupted Incense",
		"description": "Target Boss: Remove all their buffs. Gain 8 Shield and 1 Feeble. Exhausts.",
		"card_type": "DEBUFF",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 0,
		"remove_target_buffs": true,
		"shield_amount": 8,
		"caster_feeble": 1,
		"exhausts": true
	},
	"doctor_event_corrupted_spirit": {
		"card_name": "Potion: Corrupted Spirit",
		"description": "Gain 8 Shield, 4 Damage+, and 3 Bleed. Exhausts.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"shield_amount": 8,
		"apply_damage_plus": 4,
		"caster_bleed": 3,
		"exhausts": true
	}
}
