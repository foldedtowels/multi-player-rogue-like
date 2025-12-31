class_name HeroesData
## Data definitions for all playable heroes
##
## This file contains all hero configurations in a data-driven format.
## To add a new hero, simply add a new entry to the HEROES dictionary below.

## Complete hero definitions
## Each hero entry contains:
## - name: Display name shown in UI
## - description: Flavor text describing the hero's playstyle
## - max_health: Starting and maximum HP for this hero
## - starting_energy: Energy available per turn
## - deck: Array of card IDs that make up the hero's starting deck (14+ cards recommended)
const HEROES = {
	"flame_wielder": {
		"name": "Pyra, Flame Wielder",
		"description": "Master of fire magic, dealing devastating burn damage.",
		"max_health": 90,
		"starting_energy": 3,
		"deck": [
			"lightning_bolt",
			"lightning_bolt",
			"shock",
			"shock",
			"shock",
			"flame_slash",
			"flame_slash",
			"burning_hands",
			"burning_hands",
			"volcanic_strike",
			"flame_barrier",
			"flame_barrier",
			"ignite",
			"fireball"
		]
	},

	"life_weaver": {
		"name": "Selene, Life Weaver",
		"description": "Divine healer and protector of allies.",
		"max_health": 110,
		"starting_energy": 3,
		"deck": [
			"healing_salve",
			"healing_salve",
			"healing_salve",
			"divine_light",
			"divine_light",
			"holy_strike",
			"holy_strike",
			"guardian_shield",
			"guardian_shield",
			"guardian_shield",
			"pacify",
			"blessing",
			"blessing",
			"mass_heal",
			"smite"
		]
	},

	"shadow_assassin": {
		"name": "Nyx, Shadow Assassin",
		"description": "Silent killer who drains life and spreads poison.",
		"max_health": 85,
		"starting_energy": 3,
		"deck": [
			"doom_blade",
			"doom_blade",
			"drain_life",
			"drain_life",
			"poison_strike",
			"poison_strike",
			"poison_strike",
			"shadow_step",
			"shadow_step",
			"dark_pact",
			"corrupt",
			"corrupt",
			"assassination",
			"vampiric_touch"
		]
	},

	"storm_caller": {
		"name": "Zephyr, Storm Caller",
		"description": "Lightning mage who controls the battlefield with spells.",
		"max_health": 95,
		"starting_energy": 3,
		"deck": [
			"lightning_strike",
			"lightning_strike",
			"lightning_strike",
			"frost_bolt",
			"frost_bolt",
			"chain_lightning",
			"chain_lightning",
			"arcane_intellect",
			"arcane_intellect",
			"divination",
			"counterspell",
			"mana_shield",
			"mana_shield",
			"storm_surge"
		]
	},

	"beast_tamer": {
		"name": "Thorne, Beast Tamer",
		"description": "Primal warrior who channels nature's fury.",
		"max_health": 120,
		"starting_energy": 3,
		"deck": [
			"wild_strike",
			"wild_strike",
			"wild_strike",
			"bear_claws",
			"bear_claws",
			"giant_growth",
			"giant_growth",
			"regrowth",
			"regrowth",
			"natures_lore",
			"primal_rage",
			"stampede",
			"regenerate",
			"regenerate"
		]
	},

	"chrono_mage": {
		"name": "Kairos, Chrono Mage",
		"description": "Time manipulator with unmatched card advantage.",
		"max_health": 100,
		"starting_energy": 3,
		"deck": [
			"temporal_bolt",
			"temporal_bolt",
			"temporal_bolt",
			"blink",
			"blink",
			"rewind",
			"rewind",
			"haste",
			"haste",
			"slow",
			"slow",
			"time_warp",
			"chrono_blast",
			"moment_of_clarity"
		]
	}
}

## Get list of all hero IDs for iteration
static func get_all_hero_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in HEROES.keys():
		ids.append(key)
	return ids

## Validate that a hero ID exists
static func has_hero(hero_id: String) -> bool:
	return HEROES.has(hero_id)
