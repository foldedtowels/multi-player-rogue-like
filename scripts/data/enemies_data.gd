class_name EnemiesData
## Data definitions for all enemy encounters (bosses and minions)
##
## This file contains all enemy configurations in a data-driven format.
## Bosses and minions use the same structure for consistency.
## Cards are defined in scripts/data/cards/enemy_cards.gd

# =============================================================================
# BOSS DEFINITIONS
# =============================================================================
## Boss entity configurations
## Properties:
## - name: Display name shown in UI
## - description: Flavor text describing the boss
## - max_health: Boss HP
## - starting_stamina: Stamina per turn
## - cards_per_turn: Number of main deck cards to play per turn
## - special_chance: Chance to play from special deck
## - extra_main_deck_chance: Chance to play additional main deck card
## - special_deck_double_chance: Chance to play 2 cards from special deck
## - deck: Dictionary mapping card IDs to counts
## - special_deck: Dictionary mapping card IDs to counts
const BOSSES = {
	"giant_moose": {
		"name": "Giant Moose",
		"description": "A massive territorial moose that charges at intruders.",
		"max_health": 60,
		"starting_stamina": 3,
		"cards_per_turn": 1,
		"special_chance": 0.75,
		"deck": {
			"charge": 4,
			"stomp": 4,
			"knocked_off_your_feet": 2
		},
		"special_deck": {
			"roar": 5,
			"forage": 2,
			"fur_coat": 3
		}
	},

	"mr_67": {
		"name": "Mr. 67",
		"description": "A muscle-bound menace who never skips leg day.",
		"max_health": 75,
		"starting_stamina": 3,
		"cards_per_turn": 1,
		"extra_main_deck_chance": 0.3,
		"special_chance": 0.7,
		"special_deck_double_chance": 0.3,
		"deck": {
			"big_punch": 4,
			"gut_punch": 4,
			"ground_smash": 2
		},
		"special_deck": {
			"protein_shake": 2,
			"muscle_shield": 6,
			"intimidating_flex": 2
		}
	},

	"spider_queen": {
		"name": "Spider-Queen",
		"description": "A terrifying arachnid matriarch who spawns endless spiderlings.",
		"max_health": 75,
		"starting_stamina": 3,
		"cards_per_turn": 1,
		"extra_main_deck_chance": 0.4,
		"special_chance": 0.5,
		"special_deck_double_chance": 0.3,
		"deck": {
			"venom_bite": 5,
			"heavy_strike": 5
		},
		"special_deck": {
			"venom_spray": 2,
			"web_shield": 3,
			"terrify": 2,
			"spawn_spiderling": 3
		}
	},

	"mute": {
		"name": "Mute",
		"description": "A silent horror that curses with dark magic.",
		"max_health": 80,
		"starting_stamina": 3,
		"cards_per_turn": 1,
		"extra_main_deck_chance": 0.20,
		"special_chance": 0.60,
		"special_deck_double_chance": 0.30,
		"deck": {
			"mute_ravage": 6,
			"mute_black_surge": 4
		},
		"special_deck": {
			"mute_instantiation": 6,
			"mute_hex_acquisition": 1,
			"mute_hex_paranoia": 3
		}
	},

	"the_doctor": {
		"name": "The Doctor",
		"description": "A twisted physician who weaponizes disease and suffering.",
		"max_health": 120,
		"starting_stamina": 3,
		"cards_per_turn": 1,
		"extra_main_deck_chance": 0.40,
		"special_chance": 0.50,
		"special_deck_double_chance": 0.35,
		"deck": {
			"doctor_vile_injection": 3,
			"doctor_putrid_mist": 2,
			"doctor_rupture": 2,
			"doctor_deep_stabs": 3
		},
		"special_deck": {
			"doctor_potion_goliath": 2,
			"doctor_potion_apotheosis": 2,
			"doctor_potion_rage": 2,
			"doctor_dark_barrier": 3,
			"doctor_potion_instantiate": 1
		},
		# Boss Event: Distribute these cards randomly to players at fight start
		"start_event_cards": [
			"doctor_event_boiling_blood",
			"doctor_event_corrupted_incense",
			"doctor_event_corrupted_spirit"
		]
	}
}

## Map boss index to boss ID
const BOSS_ORDER = [
	"giant_moose",      # Boss 1 - The Giant Moose (index 0)
	"mr_67",            # Boss 2 - Mr. 67 (index 1)
	"spider_queen",     # Boss 3 - The Spider-Queen (index 2)
	"mute",             # Boss 4 - Mute (index 3)
	"the_doctor"        # Boss 5 - The Doctor (index 4)
]

# =============================================================================
# MINION DEFINITIONS
# =============================================================================
## Minion entity configurations
## Properties (same as bosses):
## - name: Display name shown in UI
## - max_health: Minion HP
## - starting_stamina: Stamina per turn
## - boss_index: Which boss this minion appears before (0-indexed)
## - cards_per_turn: Number of main deck cards to play per turn
## - special_chance: Chance to play from special deck (optional)
## - extra_main_deck_chance: Chance to play additional main deck card (optional)
## - special_deck_double_chance: Chance to play 2 cards from special deck (optional)
## - deck: Dictionary mapping card IDs to counts
## - special_deck: Dictionary mapping card IDs to counts (optional)
const MINIONS = {
	# Boss 1 (Giant Moose) minions
	"swarm_of_racoons": {
		"name": "Swarm of Racoons",
		"max_health": 35,
		"starting_stamina": 2,
		"boss_index": 0,
		"cards_per_turn": 1,
		"deck": {
			"ankle_nibble": 5,
			"swarm": 5
		}
	},
	"alex": {
		"name": "Alex",
		"max_health": 45,
		"starting_stamina": 2,
		"boss_index": 0,
		"cards_per_turn": 1,
		"special_chance": 0.5,
		"deck": {
			"monkey_punch": 7,
			"it_bit_my_hand": 3
		},
		"special_deck": {
			"anger": 1
		}
	},

	# Boss 2 (Mr. 67) minions
	"brock": {
		"name": "Brock",
		"max_health": 25,
		"starting_stamina": 2,
		"boss_index": 1,
		"cards_per_turn": 1,
		"special_chance": 0.6,
		"deck": {
			"minion_punch": 7,
			"brawl": 3
		},
		"special_deck": {
			"anger": 1
		}
	},
	"mommy": {
		"name": "Mommy",
		"max_health": 35,
		"starting_stamina": 2,
		"boss_index": 1,
		"cards_per_turn": 1,
		"special_chance": 0.4,
		"deck": {
			"minion_punch": 7,
			"angwy_punch": 3
		},
		"special_deck": {
			"seduction": 1
		}
	},
	"trogdor": {
		"name": "Trogdor",
		"max_health": 25,
		"starting_stamina": 2,
		"boss_index": 1,
		"cards_per_turn": 1,
		"special_chance": 0.5,
		"extra_main_deck_chance": 0.05,
		"deck": {
			"minion_punch": 7,
			"vulnerable_approach": 3
		},
		"special_deck": {
			"handicap_helmet": 1
		}
	},

	# Boss 3 minions (Spider-Queen) - pre-fight minions
	"giant_centipede": {
		"name": "Giant Centipede",
		"max_health": 70,
		"starting_stamina": 2,
		"boss_index": 2,
		"cards_per_turn": 1,
		"extra_main_deck_chance": 0.3,
		"special_chance": 0.4,
		"special_deck_double_chance": 0.0,
		"deck": {
			"venomous_bite": 5,
			"beastly_chomp": 5
		},
		"special_deck": {
			"poison_cloud": 5,
			"exoskeleton": 5
		}
	},
	"wendigo": {
		"name": "Wendigo",
		"max_health": 40,
		"starting_stamina": 2,
		"boss_index": 3,
		"cards_per_turn": 1,
		"extra_main_deck_chance": 0.60,
		"special_chance": 0.30,
		"special_deck_double_chance": 0.10,
		"deck": {
			"wendigo_rend": 4,
			"wendigo_slash": 3,
			"wendigo_chomp": 3
		},
		"special_deck": {
			"wendigo_howl": 5,
			"wendigo_roar": 5
		}
	},
	"amalgamation": {
		"name": "Amalgamation",
		"max_health": 35,
		"starting_stamina": 2,
		"boss_index": 3,
		"cards_per_turn": 1,
		"extra_main_deck_chance": 0.20,
		"special_chance": 0.50,
		"special_deck_double_chance": 0.30,
		"deck": {
			"amalgamation_trample": 5,
			"amalgamation_smack": 5
		},
		"special_deck": {
			"amalgamation_scary_face": 3,
			"amalgamation_rebuild": 7
		}
	},

	# Summonable Spiderlings (spawned by Spider-Queen during combat)
	"spiderling_alf": {
		"name": "SpiderLing-Alf",
		"max_health": 10,
		"starting_stamina": 1,
		"boss_index": 2,
		"cards_per_turn": 1,
		"is_summonable": true,
		"summon_tag": "spiderling",
		"deck": {
			"spiderling_venom_bite": 5
		}
	},
	"spiderling_enrique": {
		"name": "SpiderLing-Enrique",
		"max_health": 15,
		"starting_stamina": 1,
		"boss_index": 2,
		"cards_per_turn": 1,
		"is_summonable": true,
		"summon_tag": "spiderling",
		"deck": {
			"spiderling_swarm": 5
		}
	},
	"spiderling_jeff": {
		"name": "SpiderLing-Jeff",
		"max_health": 10,
		"starting_stamina": 1,
		"boss_index": 2,
		"cards_per_turn": 1,
		"is_summonable": true,
		"summon_tag": "spiderling",
		"deck": {
			"spiderling_venom_snipe": 5
		}
	},

	# === FABIO, THE USURPER (Boss 5 Minion - index 4) ===
	"fabio_the_usurper": {
		"name": "Fabio, The Usurper",
		"max_health": 50,
		"starting_stamina": 2,
		"boss_index": 4,
		"cards_per_turn": 1,
		"extra_main_deck_chance": 0.3,
		"special_chance": 0.4,
		"special_deck_double_chance": 0.1,
		"deck": {
			"enemy_fabio_big_smack": 2,
			"enemy_fabio_circular_strike": 2,
			"enemy_fabio_endless_strikes": 3,
			"enemy_fabio_execution": 3
		},
		"special_deck": {
			"enemy_fabio_bulk_up": 3,
			"enemy_fabio_protector": 2,
			"enemy_fabio_medkit": 1,
			"enemy_fabio_fighters_spirit": 1,
			"enemy_fabio_protective_footwear": 3
		}
	},

	# === KEVIN, THE DRUID (Boss 5 Minion - index 4) ===
	"kevin_the_druid": {
		"name": "Kevin, The Druid",
		"max_health": 40,
		"starting_stamina": 2,
		"boss_index": 4,
		"cards_per_turn": 1,
		"extra_main_deck_chance": 0.15,
		"special_chance": 0.4,
		"special_deck_double_chance": 0.3,
		"deck": {
			"enemy_kevin_water_ball": 1,
			"enemy_kevin_typhoon": 3,
			"enemy_kevin_lightning_strike": 2,
			"enemy_kevin_tsunami": 4
		},
		"special_deck": {
			"enemy_kevin_giant_shield": 2,
			"enemy_kevin_fiery_flash": 4,
			"enemy_kevin_ring_of_fire": 4
		}
	},

	# === ENRIQUE, THE FALLEN (Boss 5 Minion - index 4) ===
	"enrique_the_fallen": {
		"name": "Enrique, The Fallen",
		"max_health": 30,
		"starting_stamina": 2,
		"starting_aura": 10,  # Aura system for Expulsion
		"passive_ability_id": "enrique_aura_generation",  # Gain 1 Aura per turn
		"boss_index": 4,
		"cards_per_turn": 1,
		"extra_main_deck_chance": 0.15,
		"special_chance": 0.5,
		"special_deck_double_chance": 0.3,
		"deck": {
			"enemy_enrique_expulsion": 2,
			"enemy_enrique_holy_plight": 4,
			"enemy_enrique_prayer_beads": 4
		},
		"special_deck": {
			"enemy_enrique_humble_request": 3,
			"enemy_enrique_healing_aura": 2,
			"enemy_enrique_protection": 3,
			"enemy_enrique_refuge": 3,
			"enemy_enrique_gift": 2
		}
	}
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Get boss ID from index
static func get_boss_id(index: int) -> String:
	if index >= 0 and index < BOSS_ORDER.size():
		return BOSS_ORDER[index]
	return ""

## Validate that a boss ID exists
static func has_boss(boss_id: String) -> bool:
	return BOSSES.has(boss_id)

## Validate that a minion ID exists
static func has_minion(minion_id: String) -> bool:
	return MINIONS.has(minion_id)

## Get minion data by ID
static func get_minion_data(minion_id: String) -> Dictionary:
	if MINIONS.has(minion_id):
		return MINIONS[minion_id]
	return {}

## Get all minion IDs for a specific boss (excludes summonable minions)
static func get_minions_for_boss(boss_index: int) -> Array:
	var minion_ids: Array = []
	for minion_id in MINIONS.keys():
		var minion_data = MINIONS[minion_id]
		if minion_data.boss_index == boss_index:
			# Skip summonable minions - they are spawned during combat, not pre-fight
			if minion_data.get("is_summonable", false):
				continue
			minion_ids.append(minion_id)
	return minion_ids

## Get all summonable minion IDs that match the given tag
static func get_summonable_minions_by_tag(tag: String) -> Array:
	var minion_ids: Array = []
	for minion_id in MINIONS.keys():
		var minion_data = MINIONS[minion_id]
		if minion_data.get("is_summonable", false) and minion_data.get("summon_tag", "") == tag:
			minion_ids.append(minion_id)
	return minion_ids
