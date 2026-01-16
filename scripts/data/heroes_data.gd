class_name HeroesData
## Data definitions for all playable heroes
##
## This file contains all hero configurations in a data-driven format.
## To add a new hero, simply add a new entry to the HEROES dictionary below.
##
## ============================================================================
## REFACTORING PLAN SUMMARY (Jan 2026) - ALL PHASES COMPLETE
## ============================================================================
## Phase 1: COMPLETED - Removed 5 characters (Pyra, Nyx, Zephyr, Thorne, Kairos)
##          Kept: Selene (life_weaver), Fabio, Kevin.
##
## Phase 2: COMPLETED - Status effect system now data-driven
##          See: status_effect_registry.gd (dynamic category functions)
##          See: card_effect_engine.gd (uses registry for buff/debuff lists)
##
## Phase 3: COMPLETED - Passive ability registry system
##          See: passive_ability_manager.gd (PASSIVE_ABILITIES const)
##
## Phase 4: COMPLETED - Enrique added as WIP placeholder (deck TBD)
##
## FIXED ISSUES:
## - Kevin's passive ID mismatch (now uses kevin_alchemist_brew consistently)
## - UI tearing (added signature caching to card_hand_display.gd & player_status_panel.gd)
## ============================================================================

## Complete hero definitions
## Each hero entry contains:
## - name: Display name shown in UI
## - description: Flavor text describing the hero's playstyle
## - max_health: Starting and maximum HP for this hero
## - starting_stamina: Stamina available per turn
## - deck: Array of card IDs that make up the hero's starting deck (14+ cards recommended)
const HEROES = {
	"life_weaver": {
		"name": "Selene, Life Weaver",
		"description": "Divine healer and protector of allies.",
		"max_health": 110,
		"starting_stamina": 3,
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
		],
		# Reward deck: support/healer themed cards from shared pool
		"reward_deck": [
			"sacrifice",
			"medkit",
			"energy",
			"fighters_spirit",
			"protector",
			"leader",
			"fortify",
			"rejuvenation",
			"healing_potion"
		]
	},

	# Phase 1 Heroes: Fabio, Kevin (Selene above)
	"fabio": {
		"name": "Fabio, The Warrior",
		"description": "Versatile fighter with tactical abilities and battlefield control.",
		"max_health": 50,
		"starting_stamina": 2,
		"passive_ability_id": "fabio_warrior_choice",
		"deck": [
			# === BASE DECK (keep these) ===
			"slash",
			"big_smack",
			"duel_purpose",
			"rest",
			"bulk_up",
			"dig_a_hole",
			"protector",
			"protective_footwear",
			"hunters_instinct",
			"medkit",
			# === REWARD CARDS (move back to reward_deck after testing) ===
			"dual_wield",
			"circular_strike",
			"cursed_dagger",
			"jumping_strike",
			"execution",
			"frenzy",
			"weak_point",
			"energy",
			"fighters_spirit",
			"sacrifice",
			"leader"
		],
		# Reward deck: cards offered after defeating bosses
		"reward_deck": [
			"dual_wield",
			"circular_strike",
			"cursed_dagger",
			"jumping_strike",
			"execution",
			"frenzy",
			"weak_point",
			"energy",
			"fighters_spirit",
			"sacrifice",
			"leader"
		]
	},

	"kevin": {
		"name": "Kevin, The Alchemist",
		"description": "Elemental mage who brews powerful spell combinations from his satchel.",
		"max_health": 40,
		"starting_stamina": 2,
		"passive_ability_id": "kevin_alchemist_brew",
		# Base deck: Spells and basic cards only (NO reward cards)
		"deck": [
			"spell_fire_smash",
			"spell_water_ball",
			"spell_earthquake",
			"spell_fiery_flash",
			"poke",
			"meditate",
			"rest",
			"fetal_position",
			"spell_ice_shield",
			"spell_encapsulation"
		],
		# Satchel: Alc cards brewed with passive ability (static pool, not shuffled)
		"satchel": [
			"alc_lightning_storm",
			"alc_accumulation",
			"alc_giant_shield"
		],
		# Reward deck: cards offered after defeating bosses
		"reward_deck": [
			"spell_future_vision",
			"spell_mortar_pestle",
			"spell_enflame",
			"spell_restore",
			"spell_ring_of_fire",
			"reformulate",
			"accretion",
			# Special cards also in rewards
			"spell_tsunami",
			"repurpose"
		]
	},

	# Enrique: The Cleric - Uses Aura as a second resource
	"enrique": {
		"name": "Enrique, The Cleric",
		"description": "Divine healer who channels Aura to protect and restore allies.",
		"max_health": 30,
		"starting_stamina": 2,
		"starting_aura": 5,  # Second resource: Aura (gains 1 per turn from passive)
		"passive_ability_id": "enrique_aura_generation",
		# Base deck: 10 cards
		"deck": [
			# === BASE DECK (keep these) ===
			"expulsion",
			"focused_purge",
			"holy_plight",
			"prayer_beads",
			"humble_request",
			"divine_reflection",
			"healing_aura",
			"magical_purge",
			"story_of_jacob",
			"protection",
			# === REWARD CARDS (move back to reward_deck after testing) ===
			"divine_force",
			"purging_water",
			"divine_barrier",
			"refuge",
			"gift",
			"divine_gift",
			"guy_with_beard",
			"energy",
			"meditate"
		],
		# Reward deck: cards offered after defeating bosses
		"reward_deck": [
			"divine_force",
			"purging_water",
			"divine_barrier",
			"refuge",
			"gift",
			"divine_gift",
			"guy_with_beard",
			"energy",  # From shared pool
			"meditate"  # From shared pool
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
