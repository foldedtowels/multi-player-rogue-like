extends Node
## Manager for character passive abilities
##
## This autoload handles:
## - Defining all passive abilities
## - Triggering passive abilities at appropriate times
## - Managing passive ability usage limits

var defined_abilities: Dictionary = {}

func _ready():
	_define_all_abilities()

## Define all passive abilities in the game
func _define_all_abilities():
	# Fabio's Warrior's Choice
	var fabio_passive = PassiveAbility.new()
	fabio_passive.ability_id = "fabio_warrior_choice"
	fabio_passive.ability_name = "Warrior's Choice"
	fabio_passive.description = "Once per turn, choose: Deal 2 damage to boss, Draw 1 card, or Give 3 shield to an ally"
	fabio_passive.trigger_type = PassiveAbility.TriggerType.ON_DEMAND
	fabio_passive.effect_type = PassiveAbility.EffectType.CHOICE
	fabio_passive.uses_per_turn = 1
	fabio_passive.stamina_cost = 0  # Free
	fabio_passive.choices = [
		{"name": "Deal 2 Damage", "effect": "damage", "value": 2, "target": "boss"},
		{"name": "Draw 1 Card", "effect": "draw", "value": 1, "target": "self"},
		{"name": "Give 3 Shield", "effect": "shield", "value": 3, "target": "ally"}
	] as Array[Dictionary]
	defined_abilities["fabio_warrior_choice"] = fabio_passive

	# Enrique's Aura Generation (Phase 2 - placeholder)
	var enrique_passive = PassiveAbility.new()
	enrique_passive.ability_id = "enrique_aura_generation"
	enrique_passive.ability_name = "Divine Aura"
	enrique_passive.description = "Gain 1 Aura at the start of your turn"
	enrique_passive.trigger_type = PassiveAbility.TriggerType.START_OF_TURN
	enrique_passive.effect_type = PassiveAbility.EffectType.GAIN_STAMINA  # Will use for aura later
	enrique_passive.uses_per_turn = -1  # Unlimited (automatic)
	enrique_passive.stamina_cost = 0
	defined_abilities["enrique_aura_generation"] = enrique_passive

	# Kevin's Alchemy (Phase 3 - placeholder)
	var kevin_passive = PassiveAbility.new()
	kevin_passive.ability_id = "kevin_alchemy"
	kevin_passive.ability_name = "Alchemy"
	kevin_passive.description = "Discard spell cards to play powerful Alc' cards from your Satchel"
	kevin_passive.trigger_type = PassiveAbility.TriggerType.ON_DEMAND
	kevin_passive.effect_type = PassiveAbility.EffectType.CHOICE  # Special handling
	kevin_passive.uses_per_turn = -1  # Unlimited
	kevin_passive.stamina_cost = 0
	defined_abilities["kevin_alchemy"] = kevin_passive

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
