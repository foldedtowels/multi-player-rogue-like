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
			{"name": "It bit my Hand!", "type": "ATTACK", "cost": 1, "damage": 3, "hinder": 1, "target": "HIGHEST_HP"},
			{"name": "It bit my Hand!", "type": "ATTACK", "cost": 1, "damage": 3, "hinder": 1, "target": "HIGHEST_HP"},
			{"name": "It bit my Hand!", "type": "ATTACK", "cost": 1, "damage": 3, "hinder": 1, "target": "HIGHEST_HP"},
		],
		"special_deck": [
			{"name": "Anger", "type": "BUFF", "cost": 0, "strength": 2, "target": "SELF"}
		],
		"special_chance": 0.5
	},

	# Boss 2 (Flame Warlord) minions
	"fire_imp": {
		"name": "Fire Imp",
		"max_health": 35,
		"starting_stamina": 2,
		"boss_index": 1,
		"cards_per_turn": 1,
		"deck": [
			{"name": "Fireball", "type": "ATTACK", "cost": 1, "damage": 7, "target": "SINGLE_ENEMY"},
			{"name": "Fireball", "type": "ATTACK", "cost": 1, "damage": 7, "target": "SINGLE_ENEMY"},
			{"name": "Ember Strike", "type": "ATTACK", "cost": 1, "damage": 4, "burn": 2, "target": "SINGLE_ENEMY"},
			{"name": "Ember Strike", "type": "ATTACK", "cost": 1, "damage": 4, "burn": 2, "target": "SINGLE_ENEMY"},
			{"name": "Flame Shield", "type": "BUFF", "cost": 1, "shield": 6, "target": "SELF"},
		]
	},
	"molten_warrior": {
		"name": "Molten Warrior",
		"max_health": 70,
		"starting_stamina": 3,
		"boss_index": 1,
		"cards_per_turn": 1,
		"deck": [
			{"name": "Molten Slash", "type": "ATTACK", "cost": 1, "damage": 9, "target": "SINGLE_ENEMY"},
			{"name": "Molten Slash", "type": "ATTACK", "cost": 1, "damage": 9, "target": "SINGLE_ENEMY"},
			{"name": "Inferno Strike", "type": "ATTACK", "cost": 2, "damage": 6, "burn": 3, "target": "SINGLE_ENEMY"},
			{"name": "Lava Armor", "type": "BUFF", "cost": 1, "shield": 10, "strength": 1, "target": "SELF"},
			{"name": "Flame Burst", "type": "ATTACK", "cost": 2, "damage": 5, "burn": 2, "target": "ALL_ENEMIES"},
		]
	},

	# Boss 3 (Lich Summoner) minions
	"skeleton_warrior": {
		"name": "Skeleton Warrior",
		"max_health": 45,
		"starting_stamina": 2,
		"boss_index": 2,
		"cards_per_turn": 1,
		"deck": [
			{"name": "Bone Strike", "type": "ATTACK", "cost": 1, "damage": 8, "target": "SINGLE_ENEMY"},
			{"name": "Bone Strike", "type": "ATTACK", "cost": 1, "damage": 8, "target": "SINGLE_ENEMY"},
			{"name": "Rusty Blade", "type": "ATTACK", "cost": 1, "damage": 5, "poison": 1, "target": "SINGLE_ENEMY"},
			{"name": "Rusty Blade", "type": "ATTACK", "cost": 1, "damage": 5, "poison": 1, "target": "SINGLE_ENEMY"},
			{"name": "Shield Bash", "type": "ATTACK", "cost": 2, "damage": 10, "shield": 4, "target": "SINGLE_ENEMY"},
		]
	},
	"wraith": {
		"name": "Wraith",
		"max_health": 50,
		"starting_stamina": 3,
		"boss_index": 2,
		"cards_per_turn": 1,
		"deck": [
			{"name": "Soul Drain", "type": "ATTACK", "cost": 2, "damage": 10, "lifesteal": true, "target": "SINGLE_ENEMY"},
			{"name": "Soul Drain", "type": "ATTACK", "cost": 2, "damage": 10, "lifesteal": true, "target": "SINGLE_ENEMY"},
			{"name": "Spectral Touch", "type": "ATTACK", "cost": 1, "damage": 6, "weakness": 1, "target": "SINGLE_ENEMY"},
			{"name": "Spectral Touch", "type": "ATTACK", "cost": 1, "damage": 6, "weakness": 1, "target": "SINGLE_ENEMY"},
			{"name": "Phase Shift", "type": "BUFF", "cost": 1, "shield": 12, "target": "SELF"},
		]
	},

	# Boss 4 (Storm Dragon) minions
	"thunder_drake": {
		"name": "Thunder Drake",
		"max_health": 55,
		"starting_stamina": 3,
		"boss_index": 3,
		"cards_per_turn": 1,
		"deck": [
			{"name": "Lightning Bite", "type": "ATTACK", "cost": 1, "damage": 9, "target": "SINGLE_ENEMY"},
			{"name": "Lightning Bite", "type": "ATTACK", "cost": 1, "damage": 9, "target": "SINGLE_ENEMY"},
			{"name": "Thunder Strike", "type": "ATTACK", "cost": 2, "damage": 14, "target": "SINGLE_ENEMY"},
			{"name": "Static Shield", "type": "BUFF", "cost": 1, "shield": 9, "target": "SELF"},
			{"name": "Chain Lightning", "type": "ATTACK", "cost": 2, "damage": 6, "target": "ALL_ENEMIES"},
		]
	},
	"storm_elemental": {
		"name": "Storm Elemental",
		"max_health": 65,
		"starting_stamina": 3,
		"boss_index": 3,
		"cards_per_turn": 1,
		"deck": [
			{"name": "Gale Force", "type": "ATTACK", "cost": 2, "damage": 12, "vulnerable": 1, "target": "SINGLE_ENEMY"},
			{"name": "Gale Force", "type": "ATTACK", "cost": 2, "damage": 12, "vulnerable": 1, "target": "SINGLE_ENEMY"},
			{"name": "Cyclone", "type": "ATTACK", "cost": 2, "damage": 7, "target": "ALL_ENEMIES"},
			{"name": "Wind Wall", "type": "BUFF", "cost": 1, "shield": 11, "target": "SELF"},
			{"name": "Tempest", "type": "ATTACK", "cost": 3, "damage": 18, "target": "SINGLE_ENEMY"},
		]
	},

	# Boss 5 (Void Titan) minions
	"void_spawn": {
		"name": "Void Spawn",
		"max_health": 50,
		"starting_stamina": 3,
		"boss_index": 4,
		"cards_per_turn": 1,
		"deck": [
			{"name": "Void Strike", "type": "ATTACK", "cost": 1, "damage": 10, "target": "SINGLE_ENEMY"},
			{"name": "Void Strike", "type": "ATTACK", "cost": 1, "damage": 10, "target": "SINGLE_ENEMY"},
			{"name": "Dark Pulse", "type": "ATTACK", "cost": 2, "damage": 8, "vulnerable": 1, "target": "SINGLE_ENEMY"},
			{"name": "Dark Pulse", "type": "ATTACK", "cost": 2, "damage": 8, "vulnerable": 1, "target": "SINGLE_ENEMY"},
			{"name": "Void Shield", "type": "BUFF", "cost": 1, "shield": 10, "target": "SELF"},
		]
	},
	"chaos_horror": {
		"name": "Chaos Horror",
		"max_health": 80,
		"starting_stamina": 3,
		"boss_index": 4,
		"cards_per_turn": 1,
		"deck": [
			{"name": "Chaos Bolt", "type": "ATTACK", "cost": 2, "damage": 15, "target": "SINGLE_ENEMY"},
			{"name": "Chaos Bolt", "type": "ATTACK", "cost": 2, "damage": 15, "target": "SINGLE_ENEMY"},
			{"name": "Reality Tear", "type": "ATTACK", "cost": 2, "damage": 10, "piercing": true, "target": "SINGLE_ENEMY"},
			{"name": "Madness", "type": "DEBUFF", "cost": 1, "vulnerable": 2, "weakness": 2, "target": "SINGLE_ENEMY"},
			{"name": "Warp Barrier", "type": "BUFF", "cost": 2, "shield": 15, "target": "SELF"},
		]
	},
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
