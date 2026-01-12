extends Node

## Central registry for all status effects in the game.
## Defines metadata for each effect: display name, decay behavior, modifiers, etc.
## Used by Character, GameManager, and UI to handle effects consistently.

enum EffectType { BUFF, DEBUFF, DOT }  # DOT = Damage Over Time
enum DecayType { NONE, PER_TURN, END_OF_TURN, AFTER_TURN_START }  # AFTER_TURN_START = removed after applying at next turn start

const EFFECTS: Dictionary = {
	# ============================================
	# DAMAGE OVER TIME (DOT) EFFECTS
	# ============================================
	"poison": {
		"display_name": "Poison",
		"short_name": "Psn",
		"type": EffectType.DOT,
		"decay": DecayType.PER_TURN,
		"decay_amount": 1,
		"deals_damage": true,
		"piercing": true
	},
	"burn": {
		"display_name": "Burn",
		"short_name": "Brn",
		"type": EffectType.DOT,
		"decay": DecayType.NONE,
		"deals_damage": true,
		"piercing": true
	},

	# ============================================
	# PERMANENT BUFFS (no decay)
	# ============================================
	"strength": {
		"display_name": "Strength",
		"short_name": "Str",
		"type": EffectType.BUFF,
		"decay": DecayType.NONE,
		"attack_modifier": 1  # +1 damage per stack
	},
	"armor": {
		"display_name": "Armor",
		"short_name": "Arm",
		"type": EffectType.BUFF,
		"decay": DecayType.NONE,
		"damage_reduction": 1  # -1 damage taken per stack
	},

	# ============================================
	# DECAYING DEBUFFS (lose stacks each turn)
	# ============================================
	"vulnerable": {
		"display_name": "Vulnerable",
		"short_name": "Vuln",
		"type": EffectType.DEBUFF,
		"decay": DecayType.PER_TURN,
		"decay_amount": 1,
		"damage_taken_multiplier": 1.5  # Take 50% more damage
	},
	"weakness": {
		"display_name": "Weakness",
		"short_name": "Weak",
		"type": EffectType.DEBUFF,
		"decay": DecayType.PER_TURN,
		"decay_amount": 1,
		"attack_modifier": -1  # -1 damage per stack
	},
	"fatigued": {
		"display_name": "Fatigued",
		"short_name": "Ftg",
		"type": EffectType.DEBUFF,
		"decay": DecayType.PER_TURN,
		"decay_amount": 1,
		"stamina_modifier": -1,
		"per_stack": false,  # Flat -1 stamina, amount just tracks duration
		"apply_at": "turn_start"
	},

	# ============================================
	# SINGLE-TURN BUFFS (reset at end of turn)
	# ============================================
	"rested": {
		"display_name": "Rested",
		"short_name": "Rest",
		"type": EffectType.BUFF,
		"decay": DecayType.AFTER_TURN_START,  # Persists through turn end, applies and is removed at next turn start
		"stamina_modifier": 1,
		"per_stack": true,  # +1 stamina per stack
		"apply_at": "turn_start"
	},
	"invigorated": {
		"display_name": "Invigorated",
		"short_name": "Invig",
		"type": EffectType.BUFF,
		"decay": DecayType.END_OF_TURN,
		"grants_on_apply": {"effect": "damage_plus", "multiplier": 2}
	},
	"damage_plus": {
		"display_name": "Damage+",
		"short_name": "Dmg+",
		"type": EffectType.BUFF,
		"decay": DecayType.END_OF_TURN,
		"attack_modifier": 1  # +1 damage per stack
	},

	# ============================================
	# SINGLE-TURN DEBUFFS (reset at end of turn)
	# ============================================
	"exhausted": {
		"display_name": "Exhausted",
		"short_name": "Exh",
		"type": EffectType.DEBUFF,
		"decay": DecayType.END_OF_TURN,
		"blocks_card_play": true
	},
	"decay": {
		"display_name": "Decay",
		"short_name": "Dcy",
		"type": EffectType.DEBUFF,
		"decay": DecayType.END_OF_TURN,
		"blocks_healing": true
	}
}


# ============================================
# STATIC ACCESSORS
# ============================================

static func get_effect_data(effect_name: String) -> Dictionary:
	return EFFECTS.get(effect_name, {})

static func get_display_name(effect_name: String) -> String:
	return EFFECTS.get(effect_name, {}).get("display_name", effect_name.capitalize())

static func get_short_name(effect_name: String) -> String:
	return EFFECTS.get(effect_name, {}).get("short_name", effect_name.left(4).capitalize())

static func get_all_effect_names() -> Array:
	return EFFECTS.keys()

static func is_buff(effect_name: String) -> bool:
	var data = get_effect_data(effect_name)
	return data.get("type", EffectType.DEBUFF) == EffectType.BUFF

static func is_debuff(effect_name: String) -> bool:
	var data = get_effect_data(effect_name)
	return data.get("type", EffectType.DEBUFF) in [EffectType.DEBUFF, EffectType.DOT]


# ============================================
# DISPLAY HELPERS
# ============================================

## Generate a status display string for a character's active effects
static func get_status_display_string(status_effects: Dictionary, use_short_names: bool = true) -> String:
	var parts: Array[String] = []

	for effect_name in status_effects.keys():
		var amount = status_effects[effect_name]
		if amount <= 0:
			continue

		var name = get_short_name(effect_name) if use_short_names else get_display_name(effect_name)
		parts.append("%s %d" % [name, amount])

	return " ".join(parts)

## Get an array of effect info for UI display (icon, name, amount, is_buff)
static func get_status_display_array(status_effects: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for effect_name in status_effects.keys():
		var amount = status_effects[effect_name]
		if amount <= 0:
			continue

		result.append({
			"effect_name": effect_name,
			"display_name": get_display_name(effect_name),
			"short_name": get_short_name(effect_name),
			"amount": amount,
			"is_buff": is_buff(effect_name)
		})

	return result
