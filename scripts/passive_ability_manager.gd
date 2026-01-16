extends Node
## Manager for character passive abilities
##
## This autoload handles:
## - Defining all passive abilities from PASSIVE_ABILITIES const
## - Triggering passive abilities at appropriate times
## - Managing passive ability usage limits
##
## REFACTORING STATUS (Phase 3) - COMPLETED
## [x] Created PASSIVE_ABILITIES const dictionary (data-driven like StatusEffectRegistry)
## [x] Converted _define_all_abilities() to iterate over dictionary
## [x] Added support for custom handlers (Kevin's brew system)
## [x] IDs match between heroes_data.gd and this file

# ============================================
# PASSIVE ABILITY DEFINITIONS (Data-Driven)
# ============================================
# Each entry defines a passive ability with its properties.
# To add a new passive: add entry here, add passive_ability_id to hero in heroes_data.gd

const PASSIVE_ABILITIES: Dictionary = {
	"fabio_warrior_choice": {
		"name": "Warrior's Choice",
		"description": "Once per turn, choose: Deal 2 damage to enemy, Draw 1 card, or Give 3 shield to yourself or ally",
		"trigger_type": "on_demand",
		"effect_type": "choice",
		"uses_per_turn": 1,
		"stamina_cost": 0,
		"choices": [
			{"name": "Deal 2 Damage", "effect": "damage", "value": 2, "target": "boss"},
			{"name": "Draw 1 Card", "effect": "draw", "value": 1, "target": "self"},
			{"name": "Shield (Self/Ally)", "effect": "shield", "value": 3, "target": "ally"}
		]
	},

	"kevin_alchemist_brew": {
		"name": "Alchemy",
		"description": "Discard spell cards to play powerful Alc' cards from your Satchel",
		"trigger_type": "on_demand",
		"effect_type": "choice",  # Special handling via UI modal
		"uses_per_turn": -1,  # Unlimited
		"stamina_cost": 0,
		"is_custom_handler": true  # Indicates special UI handling
	},

	"enrique_aura_generation": {
		"name": "Divine Aura",
		"description": "Gain 1 Aura at the start of your turn",
		"trigger_type": "start_of_turn",
		"effect_type": "gain_stamina",  # Will use for aura later
		"uses_per_turn": -1,  # Unlimited (automatic)
		"stamina_cost": 0
	}
}

var defined_abilities: Dictionary = {}

func _ready():
	_define_all_abilities()

## Define all passive abilities by iterating over PASSIVE_ABILITIES const
func _define_all_abilities():
	for ability_id in PASSIVE_ABILITIES.keys():
		var data = PASSIVE_ABILITIES[ability_id]
		var ability = PassiveAbility.new()

		ability.ability_id = ability_id
		ability.ability_name = data.get("name", ability_id)
		ability.description = data.get("description", "")
		ability.uses_per_turn = data.get("uses_per_turn", 1)
		ability.stamina_cost = data.get("stamina_cost", 0)

		# Map trigger_type string to enum (all 7 types supported)
		match data.get("trigger_type", "on_demand"):
			"on_demand":
				ability.trigger_type = PassiveAbility.TriggerType.ON_DEMAND
			"start_of_turn":
				ability.trigger_type = PassiveAbility.TriggerType.START_OF_TURN
			"end_of_turn":
				ability.trigger_type = PassiveAbility.TriggerType.END_OF_TURN
			"on_damage_taken":
				ability.trigger_type = PassiveAbility.TriggerType.ON_DAMAGE_TAKEN
			"on_damage_dealt":
				ability.trigger_type = PassiveAbility.TriggerType.ON_DAMAGE_DEALT
			"on_card_played":
				ability.trigger_type = PassiveAbility.TriggerType.ON_CARD_PLAYED
			"on_kill":
				ability.trigger_type = PassiveAbility.TriggerType.ON_KILL

		# Map effect_type string to enum (all 8 types supported)
		match data.get("effect_type", "choice"):
			"choice":
				ability.effect_type = PassiveAbility.EffectType.CHOICE
			"gain_stamina":
				ability.effect_type = PassiveAbility.EffectType.GAIN_STAMINA
			"deal_damage":
				ability.effect_type = PassiveAbility.EffectType.DEAL_DAMAGE
			"heal":
				ability.effect_type = PassiveAbility.EffectType.HEAL
			"gain_shield":
				ability.effect_type = PassiveAbility.EffectType.GAIN_SHIELD
			"draw_cards":
				ability.effect_type = PassiveAbility.EffectType.DRAW_CARDS
			"apply_buff":
				ability.effect_type = PassiveAbility.EffectType.APPLY_BUFF
			"apply_debuff":
				ability.effect_type = PassiveAbility.EffectType.APPLY_DEBUFF

		# Copy choices array if present (use assign() for typed array compatibility)
		if data.has("choices"):
			for choice in data.choices:
				ability.choices.append(choice.duplicate())

		defined_abilities[ability_id] = ability

## Get a passive ability by ID
func get_ability(ability_id: String) -> PassiveAbility:
	if defined_abilities.has(ability_id):
		return defined_abilities[ability_id]
	return null

## Check if a character can use their passive ability
func can_use_passive(character: Character) -> bool:
	if character.passive_ability_id == "":
		return false

	var ability = get_ability(character.passive_ability_id)
	if not ability:
		return false

	# Check if already used this turn (for limited use abilities)
	if ability.uses_per_turn > 0 and character.passive_ability_used_this_turn:
		return false

	# Check stamina cost
	if ability.stamina_cost > character.current_stamina:
		return false

	return true

## Apply a passive ability choice (for Fabio's warrior choice)
func apply_choice(character: Character, choice_index: int, target: Character = null):
	var ability = get_ability(character.passive_ability_id)
	if not ability or choice_index >= ability.choices.size():
		return

	var choice = ability.choices[choice_index]

	# Deduct stamina cost
	character.current_stamina -= ability.stamina_cost

	# Mark as used if limited
	if ability.uses_per_turn > 0:
		character.passive_ability_used_this_turn = true

	# Apply the chosen effect
	match choice.effect:
		"damage":
			if target:
				target.take_damage(choice.value, false)
				print("[PassiveAbility] ", character.character_name, " dealt ", choice.value, " damage to ", target.character_name)

		"draw":
			character.draw_cards(choice.value)
			print("[PassiveAbility] ", character.character_name, " drew ", choice.value, " card(s)")

		"shield":
			if target:
				target.gain_shield(choice.value)
				print("[PassiveAbility] ", character.character_name, " gave ", choice.value, " shield to ", target.character_name)

## Reset passive ability usage at start of turn
func reset_passive_usage(character: Character):
	character.passive_ability_used_this_turn = false


# ============================================
# STATIC ACCESSORS (for external queries without autoload)
# ============================================

## Get raw ability data from const (doesn't require autoload to be ready)
static func get_ability_data(ability_id: String) -> Dictionary:
	return PASSIVE_ABILITIES.get(ability_id, {})

## Get all passive ability IDs
static func get_all_ability_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in PASSIVE_ABILITIES.keys():
		ids.append(key)
	return ids

## Check if ability uses custom handler (like Kevin's brew modal)
static func is_custom_handler(ability_id: String) -> bool:
	var data = get_ability_data(ability_id)
	return data.get("is_custom_handler", false)

## Get ability display name
static func get_ability_name(ability_id: String) -> String:
	var data = get_ability_data(ability_id)
	return data.get("name", ability_id.capitalize())
