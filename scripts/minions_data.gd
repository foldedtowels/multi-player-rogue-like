extends Node
## Minion data definitions - 2 unique minions per boss (10 total)

const MINIONS = {
	# Boss 1 (Minion Fight 1) - Swarm of Racoons and Alex
	"swarm_of_racoons": {
		"name": "Swarm of Racoons",
		"max_health": 35,
		"starting_stamina": 2,
		"boss_index": 0,
		"cards_per_turn": 1,
		"deck": [
			{"name": "Ankle Nibble", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Ankle Nibble", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Ankle Nibble", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Ankle Nibble", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Ankle Nibble", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Swarm!", "type": "ATTACK", "cost": 1, "damage": 3, "target": "ALL_ENEMIES"},
			{"name": "Swarm!", "type": "ATTACK", "cost": 1, "damage": 3, "target": "ALL_ENEMIES"},
			{"name": "Swarm!", "type": "ATTACK", "cost": 1, "damage": 3, "target": "ALL_ENEMIES"},
			{"name": "Swarm!", "type": "ATTACK", "cost": 1, "damage": 3, "target": "ALL_ENEMIES"},
			{"name": "Swarm!", "type": "ATTACK", "cost": 1, "damage": 3, "target": "ALL_ENEMIES"},
		]
	},
	"alex": {
		"name": "Alex",
		"max_health": 45,
		"starting_stamina": 2,
		"boss_index": 0,
		"cards_per_turn": 1,
		"deck": [
			{"name": "Monkey Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Monkey Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Monkey Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Monkey Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Monkey Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Monkey Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Monkey Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "It bit my Hand!", "type": "ATTACK", "cost": 1, "damage": 3, "target": "HIGHEST_HP"},
			{"name": "It bit my Hand!", "type": "ATTACK", "cost": 1, "damage": 3, "target": "HIGHEST_HP"},
			{"name": "It bit my Hand!", "type": "ATTACK", "cost": 1, "damage": 3, "target": "HIGHEST_HP"},
		],
		"special_deck": [
			{"name": "Anger", "type": "BUFF", "cost": 0, "strength": 2, "target": "SELF"}
		],
		"special_chance": 0.5
	},

	# Boss 2 (Mr. 67) minions - Brock, Mommy, Trogdor
	"brock": {
		"name": "Brock",
		"max_health": 25,
		"starting_stamina": 2,
		"boss_index": 1,
		"cards_per_turn": 1,
		"deck": [
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Brawl", "type": "ATTACK", "cost": 1, "damage": 4, "target": "ALL_ENEMIES"},
			{"name": "Brawl", "type": "ATTACK", "cost": 1, "damage": 4, "target": "ALL_ENEMIES"},
			{"name": "Brawl", "type": "ATTACK", "cost": 1, "damage": 4, "target": "ALL_ENEMIES"},
		],
		"special_deck": [
			{"name": "Anger", "type": "BUFF", "cost": 0, "strength": 2, "target": "SELF"}
		],
		"special_chance": 0.6
	},
	"mommy": {
		"name": "Mommy",
		"max_health": 35,
		"starting_stamina": 2,
		"boss_index": 1,
		"cards_per_turn": 1,
		"deck": [
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Angwy Punch", "type": "ATTACK", "cost": 1, "damage": 5, "target": "HIGHEST_HP", "damage_threshold_check": 1, "damage_threshold_modifier": 5},
			{"name": "Angwy Punch", "type": "ATTACK", "cost": 1, "damage": 5, "target": "HIGHEST_HP", "damage_threshold_check": 1, "damage_threshold_modifier": 5},
			{"name": "Angwy Punch", "type": "ATTACK", "cost": 1, "damage": 5, "target": "HIGHEST_HP", "damage_threshold_check": 1, "damage_threshold_modifier": 5},
		],
		"special_deck": [
			{"name": "Seduction", "type": "DEBUFF", "cost": 0, "hinder": 2, "target": "CCW_PLAYER"}
		],
		"special_chance": 0.4
	},
	"trogdor": {
		"name": "Trogdor",
		"max_health": 25,
		"starting_stamina": 2,
		"boss_index": 1,
		"cards_per_turn": 1,
		"deck": [
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Punch!", "type": "ATTACK", "cost": 1, "damage": 5, "target": "CCW_PLAYER"},
			{"name": "Vulnerable Approach", "type": "ATTACK", "cost": 1, "damage": 10, "target": "LOWEST_HP", "damage_threshold_check": 10, "damage_threshold_modifier": -10},
			{"name": "Vulnerable Approach", "type": "ATTACK", "cost": 1, "damage": 10, "target": "LOWEST_HP", "damage_threshold_check": 10, "damage_threshold_modifier": -10},
			{"name": "Vulnerable Approach", "type": "ATTACK", "cost": 1, "damage": 10, "target": "LOWEST_HP", "damage_threshold_check": 10, "damage_threshold_modifier": -10},
		],
		"special_deck": [
			{"name": "Handicap Helmet", "type": "BUFF", "cost": 0, "shield": 3, "target": "SELF"}
		],
		"special_chance": 0.5,
		"extra_main_deck_chance": 0.05
	}
}

func get_minion_data(minion_id: String) -> Dictionary:
	if MINIONS.has(minion_id):
		return MINIONS[minion_id]
	return {}

func get_minions_for_boss(boss_index: int) -> Array:
	var minion_ids: Array = []
	for minion_id in MINIONS.keys():
		if MINIONS[minion_id].boss_index == boss_index:
			minion_ids.append(minion_id)
	return minion_ids
