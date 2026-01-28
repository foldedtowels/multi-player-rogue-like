class_name KevinCardsData
## Kevin - The Alchemist (Elemental Spells)
##
## An elemental spellcaster who brews powerful Alc cards.
## Uses Fire, Water, and Earth spells to create combinations.
## Alc cards go to the Satchel and return after being played.
##
## TODO: When adding or modifying cards here, update docs/CARDS_REFERENCE.md

const CARDS = {
	# === BASE DECK CARDS ===
	"poke": {
		"card_name": "Poke",
		"description": "Deal 2 damage. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 1,
		"damage": 2
	},

	"meditate": {
		"card_name": "Meditate",
		"description": "Draw 2 cards. TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"draw_cards": 2
	},

	"fetal_position": {
		"card_name": "Fetal Position",
		"description": "Gain 5 Shield. TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 1,
		"shield_amount": 5
	},

	# === ELEMENTAL SPELLS ===
	"spell_fire_smash": {
		"card_name": "Fire Smash",
		"description": "Deal 5 damage. [Fire Spell]. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 5,
		"element": "FIRE"
	},

	"spell_water_ball": {
		"card_name": "Water Ball",
		"description": "Deal 1 damage. Apply 1 Wet (bonus damage from Lightning Storm). [Water Spell]. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 1,
		"damage": 1,
		"element": "WATER",
		"apply_wet": 1
	},

	"spell_earthquake": {
		"card_name": "Earth Quake",
		"description": "Deal 2 damage to ALL enemies. [Earth Spell]. TARGET: All Enemies.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 1,
		"damage": 2,
		"element": "EARTH",
		"aoe_damage": true
	},

	"spell_fiery_flash": {
		"card_name": "Fiery Flash!",
		"description": "Deal 4 damage. Apply 4 Hinder (reduced damage dealt). [Fire Spell]. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 4,
		"element": "FIRE",
		"apply_hinder": 4
	},

	"spell_ice_shield": {
		"card_name": "Ice Shield",
		"description": "Give target 5 Shield. [Water Spell]. TARGET: 1 Ally (including self).",
		"card_type": "BUFF",
		"target_type": "SINGLE_ALLY",
		"stamina_cost": 1,
		"shield_amount": 5,
		"element": "WATER"
	},

	"spell_encapsulation": {
		"card_name": "Encapsulation",
		"description": "Pick 1 card in your hand to keep until played or end of next turn. [Earth Spell]. TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"element": "EARTH",
		"plays_immediately": true,
		"grants_card_retain": true
	},

	# === SATCHEL (ALC) CARDS ===
	"alc_lightning_storm": {
		"card_name": "Alc: Lightning Storm",
		"description": "Deal 3 damage per Wet on target. Brew by discarding 1 Water + 1 Earth spell. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 0,
		"is_alc": true,
		"ingredient_list": ["water", "earth"],
		"bonus_damage_per_wet": 3
	},

	"alc_accumulation": {
		"card_name": "Alc: Accumulation",
		"description": "Discard all Spells in hand. Deal 3 damage per Spell discarded. Brew by discarding 1 Water + 1 Fire spell. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 2,
		"damage": 0,
		"is_alc": true,
		"ingredient_list": ["water", "fire"],
		"discard_all_spells": true,
		"damage_per_spell_discarded": 3
	},

	"alc_giant_shield": {
		"card_name": "Alc: Giant Shield",
		"description": "ALL allies gain 5 Shield. Brew by discarding 1 Earth + 1 Fire spell. TARGET: All Allies.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 2,
		"is_alc": true,
		"ingredient_list": ["earth", "fire"],
		"all_players_shield": 5
	},

	# === REWARD CARDS ===
	"spell_tsunami": {
		"card_name": "Tsunami",
		"description": "Deal 4 damage to ALL enemies. Apply 1 Wet to all. [Water Spell]. TARGET: All Enemies.",
		"card_type": "ATTACK",
		"target_type": "ALL_ENEMIES",
		"stamina_cost": 2,
		"damage": 4,
		"element": "WATER",
		"aoe_damage": true,
		"apply_wet": 1
	},

	"repurpose": {
		"card_name": "Repurpose",
		"description": "Discard any number of Spells. Deal 2 damage +2 per Spell discarded. TARGET: 1 Enemy.",
		"card_type": "ATTACK",
		"target_type": "SINGLE_ENEMY",
		"stamina_cost": 0,
		"damage": 2,
		"min_spell_discard": 0,
		"max_spell_discard": -1,
		"damage_per_spell_discarded": 2
	},

	"spell_future_vision": {
		"card_name": "Future Vision",
		"description": "Reveal the boss's cards for next turn. [Earth Spell]. TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"element": "EARTH",
		"plays_immediately": true,
		"reveals_boss_intent": true
	},

	"spell_mortar_pestle": {
		"card_name": "Mortar and Pestle",
		"description": "Discard 1 spell. Draw 2 cards. [Earth Spell].",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"element": "EARTH",
		"discard_spell_requirement": 1,
		"draw_cards": 2
	},

	"spell_enflame": {
		"card_name": "Enflame",
		"description": "Target's next attack deals +2 damage. [Fire Spell]. TARGET: 1 Ally (including self).",
		"card_type": "BUFF",
		"target_type": "SINGLE_ALLY",
		"stamina_cost": 1,
		"element": "FIRE",
		"apply_damage_plus": 2
	},

	"spell_restore": {
		"card_name": "Restore",
		"description": "Remove all Wet from target. Heal 5 HP per Wet removed. [Water Spell]. TARGET: 1 Ally (including self).",
		"card_type": "HEAL",
		"target_type": "SINGLE_ALLY",
		"stamina_cost": 1,
		"element": "WATER",
		"remove_all_wet": true,
		"heal_per_wet_removed": 5
	},

	"spell_ring_of_fire": {
		"card_name": "Ring Of Fire",
		"description": "Give target 5 Shield. When shield is hit deal 3 damage back to attacker. [Fire Spell]. TARGET: 1 Ally (including self).",
		"card_type": "BUFF",
		"target_type": "SINGLE_ALLY",
		"stamina_cost": 1,
		"shield_amount": 5,
		"element": "FIRE",
		"apply_ring_of_fire": 1
	},

	"reformulate": {
		"card_name": "Reformulate",
		"description": "Discard 1 Spell. Search your deck for a different Spell. TARGET: Self.",
		"card_type": "BUFF",
		"target_type": "SELF",
		"stamina_cost": 0,
		"discard_spell_requirement": 1,
		"choose_spell_from_deck": 1
	},

	"accretion": {
		"card_name": "Accretion",
		"description": "Discard 2 Spells. Target ally gains 1 stamina. TARGET: 1 Ally (including self).",
		"card_type": "BUFF",
		"target_type": "SINGLE_ALLY",
		"stamina_cost": 0,
		"discard_spell_requirement": 2,
		"target_stamina_gain": 1
	}
}

## Cards that make up Kevin's starting deck
const BASE_DECK = [
	"poke",
	"meditate",
	"fetal_position",
	"spell_fire_smash",
	"spell_water_ball",
	"spell_earthquake",
	"spell_fiery_flash",
	"spell_ice_shield",
	"spell_encapsulation"
]

## Alc cards that start in Kevin's Satchel
const SATCHEL = [
	"alc_lightning_storm",
	"alc_accumulation",
	"alc_giant_shield"
]

## Cards available as rewards for Kevin
const REWARD_CARDS = [
	"spell_tsunami",
	"repurpose",
	"spell_future_vision",
	"spell_mortar_pestle",
	"spell_enflame",
	"spell_restore",
	"spell_ring_of_fire",
	"reformulate",
	"accretion"
]
