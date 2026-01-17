class_name BossesData
## Data definitions for all boss encounters
##
## This file contains all boss configurations in a data-driven format.
## To add a new boss, add an entry to BOSSES and define boss-specific cards in BOSS_CARDS.

## Boss card definitions
## Each boss has unique cards that are created and added to CardDatabase
## Format matches Card properties: card_name, description, card_type, target_type, etc.
const BOSS_CARDS = {
	# === GIANT MOOSE CARDS ===
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

	# === MR. 67 CARDS ===
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

}

## Boss definitions
## Each boss entry contains:
## - name: Display name shown in UI
## - description: Flavor text describing the boss
## - max_health: Boss HP (also set in GameConstants.BOSS_HP_SCALING)
## - starting_stamina: Stamina per turn (also set in GameConstants.BOSS_STAMINA_SCALING)
## - deck: Dictionary mapping card IDs to counts
const BOSSES = {
	"giant_moose": {
		"name": "Giant Moose",
		"description": "A massive territorial moose that charges at intruders.",
		"max_health": 60,
		"starting_stamina": 3,
		"special_chance": 0.75,
		"cards_per_turn": 1,
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
	}
}

## Map boss index to boss ID
const BOSS_ORDER = [
	"giant_moose",      # Boss 1 - The Giant Moose (index 0)
	"mr_67"             # Boss 2 - Mr. 67 (index 1)
]

## Get boss ID from index
static func get_boss_id(index: int) -> String:
	if index >= 0 and index < BOSS_ORDER.size():
		return BOSS_ORDER[index]
	return ""

## Validate that a boss ID exists
static func has_boss(boss_id: String) -> bool:
	return BOSSES.has(boss_id)
