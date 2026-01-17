class_name RewardCardsData
## Generic Reward Cards
##
## These cards are available as rewards for any character.
## Split into RARE (powerful) and COMMON (decent) pools.

const CARDS = {
	# === RARE CARDS (Powerful rewards) ===
	"apocalypse": {
		"card_name": "Apocalypse",
		"description": "Destroy everything. Deals massive damage to all enemies.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 4,
		"damage": 30,
		"aoe_damage": true
	},

	"divine_intervention": {
		"card_name": "Divine Intervention",
		"description": "Fully heal and gain massive shield.",
		"card_type": "HEAL",
		"target_type": "SELF",
		"stamina_cost": 3,
		"heal_amount": 50,
		"shield_amount": 30
	},

	"berserker_rage": {
		"card_name": "Berserker Rage",
		"description": "Gain massive strength. Unleash fury!",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 2,
		"apply_strength": 5
	},

	"meteor_swarm": {
		"card_name": "Meteor Swarm",
		"description": "Rain fire from the heavens! Multi-hit AoE.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 3,
		"damage": 12,
		"multi_hit": 3,
		"aoe_damage": true
	},

	"time_stop": {
		"card_name": "Time Stop",
		"description": "Draw 5 cards instantly.",
		"card_type": "SPELL",
		"target_type": "SELF",
		"stamina_cost": 2,
		"draw_cards": 5
	},

	"life_drain": {
		"card_name": "Life Drain",
		"description": "Massive damage that heals you.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 3,
		"damage": 25,
		"lifesteal": true
	},

	"annihilation": {
		"card_name": "Annihilation",
		"description": "Pierce all defenses. Pure destruction.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 3,
		"damage": 35,
		"piercing": true
	},

	"omnipotence": {
		"card_name": "Omnipotence",
		"description": "Gain strength, armor, and draw cards.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 3,
		"shield_amount": 15,
		"draw_cards": 3,
		"apply_strength": 3,
		"apply_armor": 3
	},

	# === COMMON CARDS (Decent rewards) ===
	"steel_strike": {
		"card_name": "Steel Strike",
		"description": "Solid attack with good damage.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 16
	},

	"healing_potion": {
		"card_name": "Healing Potion",
		"description": "Restore health quickly.",
		"card_type": "HEAL",
		"target_type": "SELF",
		"stamina_cost": 1,
		"heal_amount": 15
	},

	"fortify": {
		"card_name": "Fortify",
		"description": "Gain good shield.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"shield_amount": 12
	},

	"power_strike": {
		"card_name": "Power Strike",
		"description": "Heavy single target damage.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 18
	},

	"battle_focus": {
		"card_name": "Battle Focus",
		"description": "Gain strength and draw a card.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 2,
		"draw_cards": 1,
		"apply_strength": 2
	},

	"cleave": {
		"card_name": "Cleave",
		"description": "Hit all enemies for decent damage.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 2,
		"damage": 10,
		"aoe_damage": true
	},

	"rejuvenation": {
		"card_name": "Rejuvenation",
		"description": "Heal and gain shield.",
		"card_type": "HEAL",
		"target_type": "SELF",
		"stamina_cost": 2,
		"heal_amount": 12,
		"shield_amount": 8
	},

	"iron_will": {
		"card_name": "Iron Will",
		"description": "Solid shield and armor.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 2,
		"shield_amount": 10,
		"apply_armor": 2
	},

	"quick_strike": {
		"card_name": "Quick Strike",
		"description": "Fast, efficient damage.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 1,
		"damage": 12
	},

	"tactical_advantage": {
		"card_name": "Tactical Advantage",
		"description": "Draw 2 cards.",
		"card_type": "SPELL",
		"target_type": "SELF",
		"stamina_cost": 1,
		"draw_cards": 2,
		"plays_immediately": true
	},

	# === DEMONSTRATION CARDS (Composability Examples) ===
	"vampiric_strike": {
		"card_name": "Vampiric Strike",
		"description": "Drain the life from your enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 12,
		"lifesteal": true
	},

	"toxic_cloud": {
		"card_name": "Toxic Cloud",
		"description": "Poison all enemies with noxious fumes.",
		"card_type": "SPELL",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 3,
		"damage": 8,
		"apply_poison": 4,
		"aoe_damage": true
	},

	"dark_pact": {
		"card_name": "Dark Pact",
		"description": "Sacrifice health for power and knowledge.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"heal_amount": -5,
		"draw_cards": 2,
		"apply_strength": 4
	},

	"blazing_fury": {
		"card_name": "Blazing Fury",
		"description": "Channel rage into a devastating strike that weakens enemies.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 15,
		"apply_burn": 3,
		"apply_vulnerable": 2
	},

	"pyroclasm": {
		"card_name": "Pyroclasm",
		"description": "Massive explosion that generates embers.",
		"card_type": "SPELL",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 4,
		"damage": 18,
		"aoe_damage": true,
		"generate_cards": ["ember", "ember"]
	}
}

## Rare card IDs for reward selection
const RARE_CARDS = [
	"apocalypse",
	"divine_intervention",
	"berserker_rage",
	"meteor_swarm",
	"time_stop",
	"life_drain",
	"annihilation",
	"omnipotence"
]

## Common card IDs for reward selection
const COMMON_CARDS = [
	"steel_strike",
	"healing_potion",
	"fortify",
	"power_strike",
	"battle_focus",
	"cleave",
	"rejuvenation",
	"iron_will",
	"quick_strike",
	"tactical_advantage"
]

## Demonstration cards (for testing composability)
const DEMO_CARDS = [
	"vampiric_strike",
	"toxic_cloud",
	"dark_pact",
	"blazing_fury",
	"pyroclasm"
]
