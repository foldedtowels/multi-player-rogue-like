class_name FabioCardsData
## Fabio - The Warrior (Phase 1)
##
## A balanced fighter with attack and defense options.
## Uses Rested, Invigorated, and Fatigued mechanics.

const CARDS = {
	# === BASE DECK CARDS (9) ===
	"slash": {
		"card_name": "Slash",
		"description": "Deal 7 damage. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 7
	},

	"big_smack": {
		"card_name": "Big Smack",
		"description": "Deal 10 damage. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 3,
		"damage": 10
	},

	"duel_purpose": {
		"card_name": "Duel Purpose",
		"description": "Deal 3 damage and gain 5 Shield. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 1,
		"damage": 3,
		"shield_amount": 5
	},

	"rest": {
		"card_name": "Rest",
		"description": "Gain Rested (+1 stamina next turn). TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"apply_rested": 1
	},

	"bulk_up": {
		"card_name": "Bulk Up",
		"description": "Gain 1 Invigorated (+2 damage next attack) and 1 Fatigued (-1 stamina next turn). TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"apply_invigorated": 1,
		"apply_fatigued": 1
	},

	"dig_a_hole": {
		"card_name": "Dig a Hole",
		"description": "Plays instantly. Pick 1 card in your hand to keep until played or end of next turn. TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"plays_immediately": true,
		"grants_card_retain": true
	},

	"protector": {
		"card_name": "Protector",
		"description": "This turn all enemy attacks on target ally hit you instead. TARGET: 1 Ally.",
		"card_type": "BUFF",
		"target_type": "SINGLE_ALLY",
		"stamina_cost": 0,
		"swaps_enemy_target": true
	},

	"protective_footwear": {
		"card_name": "Protective Footwear",
		"description": "Gain 5 Shield. TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"shield_amount": 5
	},

	"hunters_instinct": {
		"card_name": "Hunter's Instinct",
		"description": "Plays instantly. Reveal the boss's cards for next turn. TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"plays_immediately": true,
		"reveals_boss_intent": true
	},

	# === FABIO REWARD CARDS (17) ===
	"dual_wield": {
		"card_name": "Dual Wield",
		"description": "Hit twice for 2 damage each (4 total). TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 2,
		"multi_hit": 2
	},

	"circular_strike": {
		"card_name": "Circular Strike",
		"description": "Deal 3 damage to ALL enemies. TARGET: All Enemies.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 1,
		"damage": 3,
		"aoe_damage": true
	},

	"cursed_dagger": {
		"card_name": "Cursed Dagger",
		"description": "Deal 2 damage. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 0,
		"damage": 2
	},

	"jumping_strike": {
		"card_name": "Jumping Strike",
		"description": "Next turn: Deal 5 damage IF you took no damage this turn. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 1,
		"damage": 0,
		"is_delayed_damage": true,
		"delay_condition": "no_damage_taken",
		"delayed_damage_amount": 5
	},

	"execution": {
		"card_name": "Execution",
		"description": "Deal 4 damage. +4 bonus damage if target is below 50% HP. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 4,
		"bonus_damage_if_wounded": 4
	},

	"frenzy": {
		"card_name": "Frenzy!",
		"description": "Deal 8 damage to ALL enemies. Gain 2 Exhausted (can't play cards until it wears off). TARGET: All Enemies.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 2,
		"damage": 8,
		"aoe_damage": true,
		"apply_exhausted": 2
	},

	"weak_point": {
		"card_name": "Weak Point!",
		"description": "Deal 2 damage +2 per debuff on target. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 1,
		"damage": 2,
		"bonus_damage_per_debuff": 2
	},

	"medkit": {
		"card_name": "Medkit",
		"description": "Heal 10 HP. Gain 1 Decay (-5 healing per stack, permanent). TARGET: Self.",
		"card_type": "HEAL",
		"target_type": "SELF",
		"stamina_cost": 2,
		"heal_amount": 10,
		"apply_decay": 1
	},

	# v2 Card - Fighter's Spirit
	"fighters_spirit": {
		"card_name": "Fighter's Spirit",
		"description": "CHOICE: Drop on Self to remove 1 debuff. OR gain 5 Shield instead. TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"remove_target_debuffs": 1,
		"has_v2": true,
		"v2_card_id": "fighters_spirit_v2"
	},

	"fighters_spirit_v2": {
		"card_name": "Fighter's Spirit V2",
		"description": "Gain 5 Shield. TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"shield_amount": 5
	},

	"sacrifice": {
		"card_name": "Sacrifice",
		"description": "This turn all enemy attacks on target ally hit you instead. TARGET: Other Allies.",
		"card_type": "BUFF",
		"target_type": "OTHER_ALLIES",
		"stamina_cost": 0,
		"swaps_enemy_target": true
	},

	# v2 Card - Leader
	"leader": {
		"card_name": "Leader",
		"description": "Plays instantly. CHOICE: All OTHER allies draw 1 card. OR discard 2 random cards and all OTHER allies draw 2. TARGET: Other Allies.",
		"card_type": "BUFF",
		"target_type": "OTHER_ALLIES",
		"stamina_cost": 0,
		"draw_cards": 1,
		"plays_immediately": true,
		"has_v2": true,
		"v2_card_id": "leader_v2"
	},

	"leader_v2": {
		"card_name": "Leader V2",
		"description": "Discard 2 random cards. All OTHER allies draw 2 cards. TARGET: Other Allies.",
		"card_type": "BUFF",
		"target_type": "OTHER_ALLIES",
		"stamina_cost": 0,
		"draw_cards": 2,
		"caster_discards_random": 2,
		"plays_immediately": true
	},

	# v2 Card - Test (debugging)
	"test": {
		"card_name": "Test",
		"description": "All teammates draw 1 card.",
		"card_type": "BUFF",
		"target_type": "OTHER_ALLIES",
		"stamina_cost": 0,
		"draw_cards": 1,
		"plays_immediately": true,
		"has_v2": true,
		"v2_card_id": "test_v2"
	},

	"test_v2": {
		"card_name": "Test V2",
		"description": "Discard 2 random cards. Teammates draw 2.",
		"card_type": "BUFF",
		"target_type": "OTHER_ALLIES",
		"stamina_cost": 0,
		"draw_cards": 2,
		"caster_discards_random": 2,
		"plays_immediately": true
	}
}

## Cards that make up Fabio's starting deck
const BASE_DECK = [
	"slash",
	"big_smack",
	"duel_purpose",
	"rest",
	"bulk_up",
	"dig_a_hole",
	"protector",
	"protective_footwear",
	"hunters_instinct"
]

## Cards available as rewards for Fabio
const REWARD_CARDS = [
	"dual_wield",
	"circular_strike",
	"cursed_dagger",
	"jumping_strike",
	"execution",
	"frenzy",
	"weak_point",
	"medkit",
	"fighters_spirit",
	"sacrifice",
	"leader",
	"test"
]
