extends Node

## Central registry for all status effects in the game.
## Defines metadata for each effect: display name, decay behavior, modifiers, etc.
## Used by Character, GameManager, and UI to handle effects consistently.
##
## TODO: When adding or modifying status effects here, update docs/STATUS_EFFECTS_REFERENCE.md
##
## ============================================
## HOW TO ADD A NEW STATUS EFFECT
## ============================================
## Adding a new effect requires changes in 3-4 files IN SYNC. Missing any step
## causes SILENT FAILURES - the effect won't apply but no error is shown.
##
## STEP 1: Add effect to EFFECTS dictionary below
##   - Define display_name, symbol, type (BUFF/DEBUFF/DOT), decay behavior
##   - Set self_applicable: true if cards apply this to the caster (like exhausted)
##
## STEP 2: Add @export property to Card class (scripts/card.gd)
##   - Add: @export var apply_<effect_name>: int = 0
##   - MUST match registry name exactly! "poison" -> "apply_poison"
##   - Also add to serialize() and deserialize() methods
##
## STEP 3: Add property accessor to Character class (scripts/character.gd)
##   - Add getter/setter that reads from status_effects dictionary
##   - See existing examples like "var poison: int" around line 31
##   - This provides backward compatibility with direct property access
##
## STEP 4 (if needed): Add special handling in CardEffectEngine
##   - Only needed for effects with side effects (like invigorated -> damage_plus)
##   - See _apply_buffs() around line 444 for example
##
## VERIFICATION: After adding, grep for "apply_<effect_name>" across codebase
##   - Should appear in: this file, card.gd, character.gd, and card_effect_engine.gd
##
## ============================================
##
## REFACTORING STATUS (Phase 2) - COMPLETED
## [x] Added get_debuff_effect_names() -> Array[String]
## [x] Added get_buff_effect_names() -> Array[String]
## [x] Added get_self_debuff_effect_names() -> Array[String]
## [x] Updated card_effect_engine.gd to use these functions
## [x] Update player_status_panel.gd to use get_status_display_array() (optional - already has signature caching)

enum EffectType { BUFF, DEBUFF, DOT }  # DOT = Damage Over Time
enum DecayType { NONE, PER_TURN, END_OF_TURN, AFTER_TURN_START, END_OF_ENEMY_TURN }  # END_OF_ENEMY_TURN = removed after enemies finish attacking

const EFFECTS: Dictionary = {
	# ============================================
	# DAMAGE OVER TIME (DOT) EFFECTS
	# ============================================
	"poison": {
		"display_name": "Poison",
		"short_name": "Psn",
		"symbol": "☠️",
		"type": EffectType.DOT,
		"decay": DecayType.PER_TURN,
		"decay_amount": 1,
		"deals_damage": true,
		"piercing": true
	},
	"bleed": {
		"display_name": "Bleed",
		"short_name": "Bld",
		"symbol": "🩸",
		"type": EffectType.DOT,
		"decay": DecayType.PER_TURN,
		"decay_amount": 1,
		"deals_damage": true,
		"piercing": true
	},
	"burn": {
		"display_name": "Burn",
		"short_name": "Brn",
		"symbol": "🔥",
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
		"symbol": "💪",
		"type": EffectType.BUFF,
		"decay": DecayType.NONE,
		"attack_modifier": 1  # +1 damage per stack
	},
	"armor": {
		"display_name": "Armor",
		"short_name": "Arm",
		"symbol": "🛡️",
		"type": EffectType.BUFF,
		"decay": DecayType.NONE,
		"damage_reduction": 1  # -1 damage taken per stack
	},
	"feeble": {
		"display_name": "Feeble",
		"short_name": "Fbl",
		"symbol": "🦴",
		"type": EffectType.DEBUFF,
		"decay": DecayType.NONE,  # Permanent - must be removed by cards
		"attack_modifier": -1  # -1 damage per stack (reverse strength)
	},

	# ============================================
	# DECAYING DEBUFFS (lose stacks each turn)
	# ============================================
	"vulnerable": {
		"display_name": "Vulnerable",
		"short_name": "Vuln",
		"symbol": "💔",
		"type": EffectType.DEBUFF,
		"decay": DecayType.PER_TURN,
		"decay_amount": 1,
		"damage_taken_multiplier": 1.5  # Take 50% more damage
	},
	"weakness": {
		"display_name": "Weakness",
		"short_name": "Weak",
		"symbol": "😵",
		"type": EffectType.DEBUFF,
		"decay": DecayType.PER_TURN,
		"decay_amount": 1,
		"attack_modifier": -1  # -1 damage per stack
	},
	"fatigued": {
		"display_name": "Fatigued",
		"short_name": "Ftg",
		"symbol": "😴",
		"type": EffectType.DEBUFF,
		"decay": DecayType.AFTER_TURN_START,  # Apply at turn start, then remove (like Rested)
		"stamina_modifier": -1,
		"per_stack": true,  # Fatigued N = -N stamina next turn
		"apply_at": "turn_start",
		"self_applicable": true  # Can be applied to caster as card cost
	},
	"hinder": {
		"display_name": "Hinder",
		"short_name": "Hnd",
		"symbol": "🚫",
		"type": EffectType.DEBUFF,
		"decay": DecayType.END_OF_TURN,  # Completely removed at end of turn
		"attack_modifier": -1,  # -1 damage per stack
		"per_stack": true
	},

	# ============================================
	# SINGLE-TURN BUFFS (reset at end of turn)
	# ============================================
	"rested": {
		"display_name": "Rested",
		"short_name": "Rest",
		"symbol": "😌",
		"type": EffectType.BUFF,
		"decay": DecayType.AFTER_TURN_START,  # Persists through turn end, applies and is removed at next turn start
		"stamina_modifier": 1,
		"per_stack": true,  # +1 stamina per stack
		"apply_at": "turn_start"
	},
	"invigorated": {
		"display_name": "Invigorated",
		"short_name": "Invig",
		"symbol": "⚡",
		"type": EffectType.BUFF,
		"decay": DecayType.END_OF_TURN,
		"grants_on_apply": {"effect": "damage_plus", "multiplier": 2}
	},
	"damage_plus": {
		"display_name": "Damage+",
		"short_name": "Dmg+",
		"symbol": "⚔️",
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
		"symbol": "🥵",
		"type": EffectType.DEBUFF,
		"decay": DecayType.PER_TURN,
		"decay_amount": 1,
		"blocks_card_play": true,
		"self_applicable": true  # Cards apply this to caster, not enemies
	},
	"scared": {
		"display_name": "Scared",
		"short_name": "Scar",
		"symbol": "😨",
		"type": EffectType.DEBUFF,
		"decay": DecayType.END_OF_TURN,
		"blocks_attacks": true  # Only blocks attack cards, not all cards
	},
	"decay": {
		"display_name": "Decay",
		"short_name": "Dcy",
		"symbol": "💀",
		"type": EffectType.DEBUFF,
		"decay": DecayType.NONE,  # Permanent for entire fight - cannot be removed
		"blocks_healing": false,  # No longer blocks, just reduces by 5 per stack
		"permanent": true,  # Flag to prevent removal by cards
		"self_applicable": true  # Cards apply this to caster, not enemies
	},
	"venom": {
		"display_name": "Venom",
		"short_name": "Ven",
		"symbol": "🐍",
		"type": EffectType.DEBUFF,
		"decay": DecayType.NONE,  # Doesn't decay - triggers at 3 stacks
		"stackable": true,
		"threshold_trigger": 3,  # At 3 stacks, deals damage and resets
		"threshold_damage": 20  # Damage dealt when threshold is reached
	},

	# ============================================
	# KEVIN'S ALCHEMY EFFECTS
	# ============================================
	"wet": {
		"display_name": "Wet",
		"short_name": "Wet",
		"symbol": "💧",
		"type": EffectType.DEBUFF,
		"decay": DecayType.NONE,  # Doesn't decay naturally - must be removed by cards
		"stackable": true  # Can accumulate stacks for bonus damage mechanics
	},
	"ring_of_fire": {
		"display_name": "Ring of Fire",
		"short_name": "RoF",
		"symbol": "💍",
		"type": EffectType.BUFF,
		"decay": DecayType.END_OF_ENEMY_TURN,  # Persists through enemy attacks, then removed
		"reflect_damage": 3  # Deal 3 damage back to attacker when hit
	},

	# ============================================
	# ENRIQUE'S DIVINE EFFECTS
	# ============================================
	"played_twice": {
		"display_name": "Played Twice",
		"short_name": "x2",
		"symbol": "🔁",
		"type": EffectType.BUFF,
		"decay": DecayType.NONE,  # Manually consumed after playing a card
		"consumable": true  # Consumed when triggered (after playing one card)
	},
	"invincible": {
		"display_name": "Invincible",
		"short_name": "Inv",
		"symbol": "✨",
		"type": EffectType.BUFF,
		"decay": DecayType.END_OF_ENEMY_TURN,  # Lasts until enemy turn ends (like Ring of Fire)
		"prevents_damage": true
	},

	# ============================================
	# NEW CHARACTER DEBUFFS
	# ============================================
	"burden": {
		"display_name": "Burden",
		"short_name": "Brd",
		"symbol": "⚓",
		"type": EffectType.DEBUFF,
		"decay": DecayType.NONE,  # Must be removed by cards
		"end_of_turn_damage": 5  # 5 damage per stack at end of turn
	},
	"dissolve": {
		"display_name": "Dissolve",
		"short_name": "Dslv",
		"symbol": "🧪",
		"type": EffectType.DEBUFF,
		"decay": DecayType.NONE,  # Must be removed by cards
		"damage_on_card_play": true  # Take X damage per card played
	},

	# ============================================
	# MUTE'S DOLL DEBUFFS (Boss 4)
	# ============================================
	"doll_dissolve": {
		"display_name": "Doll: Dissolve",
		"description": "Take 1 damage per card played",
		"short_name": "D:Dslv",
		"symbol": "🎭",
		"type": EffectType.DEBUFF,
		"decay": DecayType.NONE,  # Permanent until removed
		"damage_on_card_play": 1  # Take 1 damage per stack per card played
	},
	"doll_suffering": {
		"display_name": "Doll: Suffering",
		"description": "Take 5 damage at end of turn",
		"short_name": "D:Suf",
		"symbol": "🎭",
		"type": EffectType.DEBUFF,
		"decay": DecayType.NONE,  # Permanent until removed
		"end_of_turn_damage": 5  # Take 5 damage per stack at end of turn
	},
	"doll_burden": {
		"display_name": "Doll: Burden",
		"description": "Draw 1 less card",
		"short_name": "D:Brd",
		"symbol": "🎭",
		"type": EffectType.DEBUFF,
		"decay": DecayType.NONE,  # Permanent until removed
		"reduces_draw": 1  # Draw 1 less card per stack
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

static func get_symbol(effect_name: String) -> String:
	return EFFECTS.get(effect_name, {}).get("symbol", "?")

static func get_description(effect_name: String) -> String:
	var data = EFFECTS.get(effect_name, {})
	return data.get("description", data.get("display_name", effect_name.capitalize()))

static func get_all_effect_names() -> Array:
	return EFFECTS.keys()

static func is_buff(effect_name: String) -> bool:
	var data = get_effect_data(effect_name)
	return data.get("type", EffectType.DEBUFF) == EffectType.BUFF

static func is_debuff(effect_name: String) -> bool:
	var data = get_effect_data(effect_name)
	return data.get("type", EffectType.DEBUFF) in [EffectType.DEBUFF, EffectType.DOT]


# ============================================
# DYNAMIC CATEGORY FUNCTIONS (Phase 2 Refactoring)
# ============================================
# These replace hardcoded arrays in card_effect_engine.gd

## Get all debuff effect names (applied to enemies/targets)
## Excludes self-applicable debuffs that are only applied to caster
static func get_debuff_effect_names() -> Array[String]:
	var result: Array[String] = []
	for effect_name in EFFECTS.keys():
		var data = EFFECTS[effect_name]
		var effect_type = data.get("type", EffectType.DEBUFF)
		# Include DEBUFF and DOT types, but also include self_applicable ones
		# since some (like fatigued) can be applied to either target or caster
		if effect_type in [EffectType.DEBUFF, EffectType.DOT]:
			result.append(effect_name)
	return result

## Get all buff effect names (applied to caster/allies)
static func get_buff_effect_names() -> Array[String]:
	var result: Array[String] = []
	for effect_name in EFFECTS.keys():
		var data = EFFECTS[effect_name]
		if data.get("type", EffectType.DEBUFF) == EffectType.BUFF:
			result.append(effect_name)
	return result

## Get self-debuff effect names (debuffs applied to caster as card cost)
static func get_self_debuff_effect_names() -> Array[String]:
	var result: Array[String] = []
	for effect_name in EFFECTS.keys():
		var data = EFFECTS[effect_name]
		if data.get("self_applicable", false):
			result.append(effect_name)
	return result


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
			"symbol": get_symbol(effect_name),
			"amount": amount,
			"is_buff": is_buff(effect_name)
		})

	return result
