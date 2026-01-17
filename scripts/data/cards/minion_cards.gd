class_name MinionCardsData
## Enemy Minion Cards
##
## Cards used by minion enemies that appear before boss fights.
## Organized by minion type.

const CARDS = {
	# === SWARM OF RACCOONS CARDS ===
	"ankle_nibble": {
		"card_name": "Ankle Nibble",
		"description": "Quick bite at the ankles.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
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

	# === ALEX THE MONKEY CARDS ===
	"monkey_punch": {
		"card_name": "Monkey Punch!",
		"description": "Alex throws a punch.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 1,
		"damage": 5
	},

	"it_bit_my_hand": {
		"card_name": "It bit my Hand!",
		"description": "Deal 3 damage. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 1,
		"damage": 3
	},

	"anger": {
		"card_name": "Anger",
		"description": "Alex gets angry and stronger!",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"apply_strength": 2
	}
}

## Minion deck configurations
const MINION_DECKS = {
	"raccoon_swarm": {
		"cards": ["ankle_nibble", "swarm"],
		"counts": [3, 2]
	},
	"alex_monkey": {
		"cards": ["monkey_punch", "it_bit_my_hand", "anger"],
		"counts": [2, 2, 1]
	}
}
