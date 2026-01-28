class_name EnriqueCardsData
## Enrique - The Cleric (Divine Aura)
##
## A support character who builds and spends Aura for powerful effects.
## Uses Aura as a secondary resource alongside Stamina.
##
## TODO: When adding or modifying cards here, update docs/CARDS_REFERENCE.md

const CARDS = {
	# === BASE DECK CARDS ===
	"expulsion": {
		"card_name": "Expulsion",
		"description": "Spends ALL your Aura. Deal 3 damage per aura spent to ALL enemies. TARGET: All Enemies.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 2,
		"damage": 0,
		"aura_cost_all": true,
		"damage_per_aura_spent": 3,
		"aoe_damage": true
	},

	"focused_purge": {
		"card_name": "Focused Purge",
		"description": "Deal 3 damage. Gain 1 Aura. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 1,
		"damage": 3,
		"aura_gain": 1
	},

	"holy_plight": {
		"card_name": "Holy Plight",
		"description": "Deal 5 damage. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 1,
		"damage": 5,
		"aura_cost": 2
	},

	"prayer_beads": {
		"card_name": "Prayer Beads",
		"description": "Deal 1-6 random damage (rolls a D6). TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 1,
		"damage": 0,
		"aura_cost": 1,
		"damage_is_d6": true
	},

	"humble_request": {
		"card_name": "Humble Request",
		"description": "Gain 2 Aura. TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"aura_gain": 2
	},

	"divine_reflection": {
		"card_name": "Divine Reflection",
		"description": "Target ally's next card plays twice. TARGET: 1 Ally.",
		"card_type": "BUFF",
		"target_type": "SINGLE_ALLY",
		"stamina_cost": 0,
		"aura_cost": 3,
		"grants_played_twice": true
	},

	"healing_aura": {
		"card_name": "Healing Aura",
		"description": "Heal target 10 HP. You gain 1 Decay (-5 healing received per stack, permanent). TARGET: 1 Ally (including self).",
		"card_type": "HEAL",
		"target_type": "SINGLE_ALLY",
		"stamina_cost": 0,
		"heal_amount": 10,
		"aura_cost": 2,
		"apply_decay": 1
	},

	"magical_purge": {
		"card_name": "Magical Purge",
		"description": "Remove 1 debuff from yourself. TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"aura_cost": 2,
		"remove_target_debuffs": 1
	},

	"story_of_jacob": {
		"card_name": "Story Of Jacob",
		"description": "Gain 5 Aura. Gain 1 Fatigued (-1 stamina next turn). TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"aura_gain": 5,
		"apply_fatigued": 1
	},

	"protection": {
		"card_name": "Protection",
		"description": "Give target 5 Shield. TARGET: 1 Ally.",
		"card_type": "BUFF",
		"target_type": "SINGLE_ALLY",
		"stamina_cost": 1,
		"shield_amount": 5,
		"aura_cost": 1
	},

	# === REWARD CARDS ===
	"divine_force": {
		"card_name": "Divine Force",
		"description": "CHOICE: Drop on Ally to heal 10 HP (you gain 1 Decay). Drop on Enemy to deal 6 damage.",
		"card_type": "HEAL",
		"target_type": "SINGLE_ALLY",
		"stamina_cost": 2,
		"heal_amount": 10,
		"aura_cost": 2,
		"apply_decay": 1,
		"has_v2": true,
		"v2_card_id": "divine_force_v2",
		"context_sensitive_v2": true
	},

	"divine_force_v2": {
		"card_name": "Divine Force",
		"description": "Deal 6 damage. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 6,
		"aura_cost": 2
	},

	"purging_water": {
		"card_name": "Purging Water",
		"description": "Remove 1 debuff from target ally. TARGET: 1 Ally.",
		"card_type": "BUFF",
		"target_type": "SINGLE_ALLY",
		"stamina_cost": 1,
		"aura_cost": 1,
		"remove_target_debuffs": 1
	},

	"divine_barrier": {
		"card_name": "Divine Barrier",
		"description": "Target ally becomes Invincible (takes no damage) this turn. TARGET: 1 Ally.",
		"card_type": "BUFF",
		"target_type": "SINGLE_ALLY",
		"stamina_cost": 1,
		"aura_cost": 3,
		"grants_invincible": true
	},

	"refuge": {
		"card_name": "Refuge",
		"description": "Gain 5 Shield and 1 Aura. TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"shield_amount": 5,
		"aura_gain": 1
	},

	"gift": {
		"card_name": "Gift",
		"description": "Target ally draws 2 cards. TARGET: 1 Ally.",
		"card_type": "BUFF",
		"target_type": "SINGLE_ALLY",
		"stamina_cost": 0,
		"draw_cards": 2,
		"aura_cost": 2
	},

	"divine_gift": {
		"card_name": "Divine Gift",
		"description": "Give target ally 2 stamina. TARGET: 1 Ally.",
		"card_type": "BUFF",
		"target_type": "SINGLE_ALLY",
		"stamina_cost": 2,
		"aura_cost": 2,
		"target_stamina_gain": 2
	},

	"guy_with_beard": {
		"card_name": "Guy with Beard",
		"description": "ALL players draw 1 card. TARGET: Self (affects all).",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"aura_cost": 2,
		"all_players_draw": 1
	}
}

## Cards that make up Enrique's starting deck
const BASE_DECK = [
	"expulsion",
	"focused_purge",
	"holy_plight",
	"prayer_beads",
	"humble_request",
	"divine_reflection",
	"healing_aura",
	"magical_purge",
	"story_of_jacob",
	"protection"
]

## Cards available as rewards for Enrique
const REWARD_CARDS = [
	"divine_force",
	"purging_water",
	"divine_barrier",
	"refuge",
	"gift",
	"divine_gift",
	"guy_with_beard"
]
