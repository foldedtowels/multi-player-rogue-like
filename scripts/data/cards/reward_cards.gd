class_name RewardCardsData
## Generic Reward Cards
##
## These cards are available as rewards for any character.
## Split into RARE (powerful) and COMMON (decent) pools.

const CARDS = {
	# === RARE CARDS (Powerful rewards) ===
	"apocalypse": {
		"card_name": "Apocalypse",
		"description": "Deal 30 damage to ALL enemies.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 4,
		"damage": 30,
		"aoe_damage": true
	},

	"divine_intervention": {
		"card_name": "Divine Intervention",
		"description": "Heal 50 HP. Gain 30 Shield.",
		"card_type": "HEAL",
		"target_type": "SELF",
		"stamina_cost": 3,
		"heal_amount": 50,
		"shield_amount": 30
	},

	"berserker_rage": {
		"card_name": "Berserker Rage",
		"description": "Gain 5 Strength (permanent +5 attack damage).",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 2,
		"apply_strength": 5
	},

	"meteor_swarm": {
		"card_name": "Meteor Swarm",
		"description": "Hit ALL enemies 3 times for 12 damage each (36 total).",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 3,
		"damage": 12,
		"multi_hit": 3,
		"aoe_damage": true
	},

	"time_stop": {
		"card_name": "Time Stop",
		"description": "Draw 5 cards.",
		"card_type": "SPELL",
		"target_type": "SELF",
		"stamina_cost": 2,
		"draw_cards": 5,
		"plays_immediately": true
	},

	"life_drain": {
		"card_name": "Life Drain",
		"description": "Deal 25 damage. Heal for damage dealt.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 3,
		"damage": 25,
		"lifesteal": true
	},

	"annihilation": {
		"card_name": "Annihilation",
		"description": "Deal 35 piercing damage (ignores Shield).",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 3,
		"damage": 35,
		"piercing": true
	},

	"omnipotence": {
		"card_name": "Omnipotence",
		"description": "Gain 15 Shield, 3 Strength, 3 Armor. Draw 3 cards.",
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
		"description": "Deal 16 damage.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 16
	},

	"healing_potion": {
		"card_name": "Healing Potion",
		"description": "Heal 15 HP.",
		"card_type": "HEAL",
		"target_type": "SELF",
		"stamina_cost": 1,
		"heal_amount": 15
	},

	"fortify": {
		"card_name": "Fortify",
		"description": "Gain 12 Shield.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"shield_amount": 12
	},

	"power_strike": {
		"card_name": "Power Strike",
		"description": "Deal 18 damage.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 18
	},

	"battle_focus": {
		"card_name": "Battle Focus",
		"description": "Gain 2 Strength. Draw 1 card.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 2,
		"draw_cards": 1,
		"apply_strength": 2
	},

	"cleave": {
		"card_name": "Cleave",
		"description": "Deal 10 damage to ALL enemies.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 2,
		"damage": 10,
		"aoe_damage": true
	},

	"rejuvenation": {
		"card_name": "Rejuvenation",
		"description": "Heal 12 HP. Gain 8 Shield.",
		"card_type": "HEAL",
		"target_type": "SELF",
		"stamina_cost": 2,
		"heal_amount": 12,
		"shield_amount": 8
	},

	"iron_will": {
		"card_name": "Iron Will",
		"description": "Gain 10 Shield and 2 Armor.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 2,
		"shield_amount": 10,
		"apply_armor": 2
	},

	"quick_strike": {
		"card_name": "Quick Strike",
		"description": "Deal 12 damage.",
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
		"description": "Deal 12 damage. Heal for damage dealt.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 12,
		"lifesteal": true
	},

	"toxic_cloud": {
		"card_name": "Toxic Cloud",
		"description": "Deal 8 damage to ALL enemies. Apply 4 Poison.",
		"card_type": "SPELL",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 3,
		"damage": 8,
		"apply_poison": 4,
		"aoe_damage": true
	},

	"dark_pact": {
		"card_name": "Dark Pact",
		"description": "Lose 5 HP. Gain 4 Strength. Draw 2 cards.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"heal_amount": -5,
		"draw_cards": 2,
		"apply_strength": 4
	},

	"blazing_fury": {
		"card_name": "Blazing Fury",
		"description": "Deal 15 damage. Apply 3 Burn and 2 Vulnerable.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 15,
		"apply_burn": 3,
		"apply_vulnerable": 2
	},

	"pyroclasm": {
		"card_name": "Pyroclasm",
		"description": "Deal 18 damage to ALL enemies. Add 2 Ember tokens to hand.",
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
