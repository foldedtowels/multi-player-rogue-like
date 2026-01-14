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

	# === CORRUPTED TREANT CARDS ===
	"root_lash": {
		"card_name": "Root Lash",
		"description": "Whip with thorny roots.",
		"card_type": "ATTACK",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 1,
		"damage": 8
	},
	"bark_armor": {
		"card_name": "Bark Armor",
		"description": "Harden bark for protection.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"shield_amount": 10
	},
	"natures_wrath": {
		"card_name": "Nature's Wrath",
		"description": "Channel corrupted nature energy.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 2,
		"damage": 6,
		"aoe_damage": true
	},

	# === FLAME WARLORD CARDS ===
	"battle_axe": {
		"card_name": "Battle Axe",
		"description": "Heavy strike with flaming weapon.",
		"card_type": "ATTACK",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 1,
		"damage": 12
	},
	"war_cry": {
		"card_name": "War Cry",
		"description": "Rally strength for the next assault.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"apply_strength": 3
	},
	"inferno_wave": {
		"card_name": "Inferno Wave",
		"description": "Massive fire blast.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 2,
		"damage": 10,
		"apply_burn": 3,
		"aoe_damage": true
	},
	"flame_shield": {
		"card_name": "Flame Shield",
		"description": "Barrier of living fire.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"shield_amount": 15
	},

	# === LICH SUMMONER CARDS ===
	"death_coil": {
		"card_name": "Death Coil",
		"description": "Drain life from enemies.",
		"card_type": "ATTACK",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 1,
		"damage": 10,
		"lifesteal": true
	},
	"plague_cloud": {
		"card_name": "Plague Cloud",
		"description": "Spread disease to all foes.",
		"card_type": "DEBUFF",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 2,
		"apply_poison": 4,
		"damage": 5,
		"aoe_damage": true
	},
	"bone_shield": {
		"card_name": "Bone Shield",
		"description": "Summon protective bones.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"shield_amount": 12,
		"apply_armor": 2
	},
	"dark_ritual": {
		"card_name": "Dark Ritual",
		"description": "Sacrifice life for power.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"apply_strength": 4,
		"heal_amount": -8
	},
	"soul_drain": {
		"card_name": "Soul Drain",
		"description": "Consume enemy essence.",
		"card_type": "ATTACK",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 2,
		"damage": 15,
		"lifesteal": true,
		"apply_weakness": 2
	},

	# === STORM DRAGON CARDS ===
	"dragon_bite": {
		"card_name": "Dragon Bite",
		"description": "Crushing jaws.",
		"card_type": "ATTACK",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 1,
		"damage": 16
	},
	"lightning_breath": {
		"card_name": "Lightning Breath",
		"description": "Devastating electrical discharge.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 2,
		"damage": 14,
		"apply_vulnerable": 2,
		"aoe_damage": true
	},
	"wing_buffet": {
		"card_name": "Wing Buffet",
		"description": "Powerful wind blast.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 2,
		"damage": 10,
		"apply_weakness": 2,
		"aoe_damage": true
	},
	"dragon_scales": {
		"card_name": "Dragon Scales",
		"description": "Impenetrable armor.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"shield_amount": 20,
		"apply_armor": 3
	},
	"thunderstorm": {
		"card_name": "Thunderstorm",
		"description": "Call down devastating lightning.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 3,
		"damage": 18,
		"aoe_damage": true
	},

	# === VOID TITAN CARDS ===
	"void_slam": {
		"card_name": "Void Slam",
		"description": "Reality-shattering blow.",
		"card_type": "ATTACK",
		"target_type": "RANDOM_ENEMY",
		"stamina_cost": 1,
		"damage": 20,
		"piercing": true
	},
	"cosmic_beam": {
		"card_name": "Cosmic Beam",
		"description": "Annihilating energy blast.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 2,
		"damage": 16,
		"piercing": true,
		"aoe_damage": true
	},
	"void_armor": {
		"card_name": "Void Armor",
		"description": "Shield of nothingness.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"shield_amount": 25,
		"apply_armor": 5
	},
	"reality_tear": {
		"card_name": "Reality Tear",
		"description": "Rip through existence itself.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 3,
		"damage": 22,
		"apply_vulnerable": 3,
		"piercing": true,
		"aoe_damage": true
	},
	"entropy": {
		"card_name": "Entropy",
		"description": "Spread chaos and decay.",
		"card_type": "DEBUFF",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 2,
		"apply_poison": 5,
		"apply_burn": 5,
		"apply_weakness": 2
	}
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

	"corrupted_treant": {
		"name": "Corrupted Treant",
		"description": "Ancient guardian twisted by dark magic.",
		"max_health": 200,  # See GameConstants.BOSS_HP_SCALING[0]
		"starting_stamina": 2,  # See GameConstants.BOSS_ENERGY_SCALING[0]
		"cards_per_turn": 1,
		"deck": {
			"root_lash": 6,
			"bark_armor": 4,
			"natures_wrath": 3
		}
	},

	"flame_warlord": {
		"name": "Flame Warlord",
		"description": "Brutal warrior engulfed in eternal flames.",
		"max_health": 280,  # See GameConstants.BOSS_HP_SCALING[1]
		"starting_stamina": 3,  # See GameConstants.BOSS_ENERGY_SCALING[1]
		"cards_per_turn": 1,
		"deck": {
			"battle_axe": 5,
			"war_cry": 3,
			"inferno_wave": 4,
			"flame_shield": 3
		}
	},

	"lich_summoner": {
		"name": "Lich Summoner",
		"description": "Undead necromancer who commands death itself.",
		"max_health": 350,  # See GameConstants.BOSS_HP_SCALING[2]
		"starting_stamina": 3,  # See GameConstants.BOSS_ENERGY_SCALING[2]
		"cards_per_turn": 1,
		"deck": {
			"death_coil": 4,
			"plague_cloud": 4,
			"bone_shield": 3,
			"dark_ritual": 2,
			"soul_drain": 3
		}
	},

	"storm_dragon": {
		"name": "Storm Dragon",
		"description": "Ancient wyrm that commands lightning and thunder.",
		"max_health": 450,  # See GameConstants.BOSS_HP_SCALING[3]
		"starting_stamina": 4,  # See GameConstants.BOSS_ENERGY_SCALING[3]
		"cards_per_turn": 1,
		"deck": {
			"dragon_bite": 4,
			"lightning_breath": 4,
			"wing_buffet": 3,
			"dragon_scales": 3,
			"thunderstorm": 2
		}
	},

	"void_titan": {
		"name": "Void Titan",
		"description": "Cosmic horror from beyond reality.",
		"max_health": 600,  # See GameConstants.BOSS_HP_SCALING[4]
		"starting_stamina": 4,  # See GameConstants.BOSS_ENERGY_SCALING[4]
		"cards_per_turn": 1,
		"deck": {
			"void_slam": 5,
			"cosmic_beam": 4,
			"void_armor": 3,
			"reality_tear": 3,
			"entropy": 2
		}
	}
}

## Map boss index to boss ID
const BOSS_ORDER = [
	"giant_moose",      # Boss 1 - The Giant Moose
	"corrupted_treant", # Boss 2
	"flame_warlord",    # Boss 3
	"lich_summoner",    # Boss 4
	"storm_dragon",     # Boss 5
	"void_titan"        # Boss 6
]

## Get boss ID from index
static func get_boss_id(index: int) -> String:
	if index >= 0 and index < BOSS_ORDER.size():
		return BOSS_ORDER[index]
	return ""

## Validate that a boss ID exists
static func has_boss(boss_id: String) -> bool:
	return BOSSES.has(boss_id)
