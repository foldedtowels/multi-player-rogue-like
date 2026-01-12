extends Resource
class_name Character

@export var character_name: String
@export var description: String
@export var max_health: int = 100
@export var starting_stamina: int = 3
@export var starting_deck: Array[Card] = []

# Hero template ID (e.g., "fabio", "flame_wielder") - used for reward deck lookups
var hero_id: String = ""

# Character stats
var current_health: int
var current_stamina: int
var max_stamina: int
var shield: int = 0
var damage_taken_this_turn: int = 0  # Tracks damage taken this turn (for Jumping Strike condition)

# ============================================
# MODULAR STATUS EFFECT SYSTEM
# ============================================
# All status effects stored in a single dictionary for easy iteration and extension.
# Individual properties below provide backward compatibility with existing code.
var status_effects: Dictionary = {}

# Backward-compatible property accessors (read/write to status_effects dictionary)
var poison: int:
	get: return get_effect_amount("poison")
	set(value): set_effect_amount("poison", value)
var burn: int:
	get: return get_effect_amount("burn")
	set(value): set_effect_amount("burn", value)
var strength: int:
	get: return get_effect_amount("strength")
	set(value): set_effect_amount("strength", value)
var vulnerable: int:
	get: return get_effect_amount("vulnerable")
	set(value): set_effect_amount("vulnerable", value)
var weakness: int:
	get: return get_effect_amount("weakness")
	set(value): set_effect_amount("weakness", value)
var armor: int:
	get: return get_effect_amount("armor")
	set(value): set_effect_amount("armor", value)
var rested: int:
	get: return get_effect_amount("rested")
	set(value): set_effect_amount("rested", value)
var invigorated: int:
	get: return get_effect_amount("invigorated")
	set(value): set_effect_amount("invigorated", value)
var damage_plus: int:
	get: return get_effect_amount("damage_plus")
	set(value): set_effect_amount("damage_plus", value)
var fatigued: int:
	get: return get_effect_amount("fatigued")
	set(value): set_effect_amount("fatigued", value)
var exhausted: int:
	get: return get_effect_amount("exhausted")
	set(value): set_effect_amount("exhausted", value)
var decay: int:
	get: return get_effect_amount("decay")
	set(value): set_effect_amount("decay", value)

# Passive ability system
var passive_ability_id: String = ""
var passive_ability_used_this_turn: bool = false

# Deck management
var deck: Array[Card] = []
var hand: Array[Card] = []
var discard_pile: Array[Card] = []
var exhaust_pile: Array[Card] = []

# Card retention system (e.g., Dig a Hole)
# Maps card_name -> expires_after_round (the round number when retention expires)
var retained_cards: Dictionary = {}

# Character role
enum CharacterRole { PLAYER, MINION, BOSS }
var character_role: CharacterRole = CharacterRole.PLAYER
var is_minion: bool = false

# Network ownership
var network_owner_id: int = -1  # Which peer owns this character

func _init():
	current_health = max_health
	max_stamina = starting_stamina
	current_stamina = max_stamina
	# Don't call reset_deck() here - starting_deck isn't populated yet!
	# HeroDatabase/BossDatabase will call reset_deck() after setting starting_deck

func reset_deck():
	deck = starting_deck.duplicate()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	# Shuffling handled by game_manager when needed
	deck.shuffle()

func draw_card() -> Card:
	# Check hand size limit against game constant
	if hand.size() >= GameConstants.MAX_HAND_SIZE:
		print("[Character] Hand full, cannot draw more cards")
		return null

	if deck.is_empty():
		if discard_pile.is_empty():
			return null
		deck = discard_pile.duplicate()
		discard_pile.clear()
		# Shuffling handled by built-in shuffle (deterministic via seed)
		deck.shuffle()

	var card = deck.pop_front()
	hand.append(card)
	return card

func draw_cards(amount: int):
	print("[CARD_DRAW] ", character_name, " drawing ", amount, " cards (hand before: ", hand.size(), ")")
	for i in amount:
		var drawn = draw_card()
	print("[CARD_DRAW] ", character_name, " finished drawing (hand after: ", hand.size(), ")")

func discard_card(card: Card):
	hand.erase(card)
	discard_pile.append(card)

func exhaust_card(card: Card):
	hand.erase(card)
	exhaust_pile.append(card)

func play_card(card: Card):
	if card.can_afford(current_stamina):
		current_stamina -= card.stamina_cost

		# CRITICAL FIX: Find and remove card by name, not by reference
		# When card is deserialized from RPC, it's a new instance and hand.erase() won't find it
		var card_to_remove: Card = null
		for c in hand:
			if c.card_name == card.card_name:
				card_to_remove = c
				break

		if card_to_remove:
			hand.erase(card_to_remove)
			discard_pile.append(card_to_remove)
		else:
			# Card not in hand - might already have been removed or is invalid
			print("[CHARACTER] Warning: Tried to play card '", card.card_name, "' but it's not in hand")

		return true
	return false

func take_damage(amount: int, is_piercing: bool = false):
	# Validate input
	if amount < 0:
		push_warning("Negative damage attempted: " + str(amount))
		return 0

	var actual_damage = amount

	# Apply vulnerable status effect damage multiplier
	if vulnerable > 0:
		actual_damage = int(actual_damage * GameConstants.VULNERABLE_DAMAGE_MULTIPLIER)

	if not is_piercing and shield > 0:
		var shield_absorbed = min(shield, actual_damage)
		shield -= shield_absorbed
		actual_damage -= shield_absorbed

	if armor > 0 and not is_piercing:
		actual_damage = max(0, actual_damage - armor)

	current_health -= actual_damage
	current_health = max(0, current_health)  # Prevent negative health

	# Track damage for conditional effects (e.g., Jumping Strike)
	damage_taken_this_turn += actual_damage

	return actual_damage

func heal(amount: int):
	if decay > 0:
		print("[CHARACTER] Cannot heal while affected by Decay")
		return
	if amount < 0:
		push_warning("Negative heal attempted: " + str(amount))
		return
	current_health = min(current_health + amount, max_health)

func gain_shield(amount: int):
	if amount < 0:
		push_warning("Negative shield attempted: " + str(amount))
		return
	shield += amount
	# Cap shield to prevent infinite stacking exploits
	shield = min(shield, GameConstants.SHIELD_CAP)

func start_turn():
	current_stamina = max_stamina

	# Reset passive ability usage
	passive_ability_used_this_turn = false

	# Reset damage tracking for new turn (used by Jumping Strike condition)
	damage_taken_this_turn = 0

	apply_status_effects()
	draw_cards(5)

func add_stamina(amount: int):
	current_stamina += amount
	current_stamina = clamp(current_stamina, 0, max_stamina + 5)  # Allow slight overflow

func end_turn(current_round: int = 0):
	# Check for expired card retentions
	var expired_retentions: Array[String] = []
	for card_name in retained_cards.keys():
		if retained_cards[card_name] <= current_round:
			expired_retentions.append(card_name)
			print("[RETAIN] ", character_name, "'s retention on ", card_name, " expired")
	for card_name in expired_retentions:
		retained_cards.erase(card_name)

	# Discard hand, but skip retained cards
	var cards_to_discard: Array[Card] = []
	for card in hand:
		if retained_cards.has(card.card_name):
			print("[RETAIN] ", character_name, " keeps ", card.card_name, " in hand (retained until round ", retained_cards[card.card_name], ")")
		else:
			cards_to_discard.append(card)

	for card in cards_to_discard:
		discard_card(card)

	# Reset shield
	shield = 0

	# Process end-of-turn effects using registry
	process_turn_end_effects()

func apply_status_effects():
	# Process start-of-turn effects using registry
	process_turn_start_effects()

## Registry-based turn start processing
func process_turn_start_effects():
	# Get a copy of keys since we might modify the dictionary
	var effect_names = status_effects.keys().duplicate()

	for effect_name in effect_names:
		var amount = status_effects.get(effect_name, 0)
		if amount <= 0:
			continue

		var effect_data = StatusEffectRegistry.get_effect_data(effect_name)

		# DOT effects: deal damage equal to stacks
		if effect_data.get("deals_damage", false):
			take_damage(amount, effect_data.get("piercing", false))

			# Apply per-turn decay for DOT effects (e.g., poison decays, burn doesn't)
			if effect_data.get("decay") == StatusEffectRegistry.DecayType.PER_TURN:
				var decay_amount = effect_data.get("decay_amount", 1)
				set_effect_amount(effect_name, amount - decay_amount)

		# Stamina modifiers at turn start (rested, fatigued)
		if effect_data.get("apply_at") == "turn_start" and effect_data.has("stamina_modifier"):
			var base_modifier = effect_data.stamina_modifier
			# Check if modifier is per stack or flat
			var stamina_change: int
			if effect_data.get("per_stack", true):  # Default to per-stack for backward compat
				stamina_change = amount * base_modifier
			else:
				stamina_change = base_modifier  # Flat modifier regardless of stacks

			if stamina_change > 0:
				add_stamina(stamina_change)
			else:
				current_stamina = max(0, current_stamina + stamina_change)

		# Remove AFTER_TURN_START effects after they've applied (e.g., rested grants stamina then is removed)
		if effect_data.get("decay") == StatusEffectRegistry.DecayType.AFTER_TURN_START:
			clear_effect(effect_name)

## Registry-based turn end processing
func process_turn_end_effects():
	var effects_to_remove: Array[String] = []

	for effect_name in status_effects.keys():
		var amount = status_effects.get(effect_name, 0)
		if amount <= 0:
			continue

		var effect_data = StatusEffectRegistry.get_effect_data(effect_name)
		var decay_type = effect_data.get("decay", StatusEffectRegistry.DecayType.NONE)

		match decay_type:
			StatusEffectRegistry.DecayType.PER_TURN:
				# Decrement by decay amount (but not DOT effects - those decay at turn start)
				if not effect_data.get("deals_damage", false):
					var decay_amount = effect_data.get("decay_amount", 1)
					var new_amount = amount - decay_amount
					if new_amount <= 0:
						effects_to_remove.append(effect_name)
					else:
						status_effects[effect_name] = new_amount
			StatusEffectRegistry.DecayType.END_OF_TURN:
				# Remove completely at end of turn
				effects_to_remove.append(effect_name)
			StatusEffectRegistry.DecayType.AFTER_TURN_START:
				# Persists through turn end - will be removed at next turn start after applying
				pass
			# NONE: permanent effects, don't decay

	for effect_name in effects_to_remove:
		status_effects.erase(effect_name)

func is_alive() -> bool:
	return current_health > 0


# ============================================
# STATUS EFFECT HELPER METHODS
# ============================================

## Get the current amount of a status effect (0 if not present)
func get_effect_amount(effect_name: String) -> int:
	return status_effects.get(effect_name, 0)

## Set the amount of a status effect (removes if <= 0)
func set_effect_amount(effect_name: String, value: int):
	if value <= 0:
		status_effects.erase(effect_name)
	else:
		status_effects[effect_name] = value

## Apply (add) an amount of status effect, handling immediate grants
func apply_effect(effect_name: String, amount: int):
	if amount <= 0:
		return

	var current = get_effect_amount(effect_name)
	set_effect_amount(effect_name, current + amount)

	# Handle immediate grants (e.g., invigorated -> damage_plus)
	var effect_data = StatusEffectRegistry.get_effect_data(effect_name)
	if effect_data.has("grants_on_apply"):
		var grant = effect_data.grants_on_apply
		apply_effect(grant.effect, int(amount * grant.multiplier))

## Check if character has a status effect
func has_effect(effect_name: String) -> bool:
	return get_effect_amount(effect_name) > 0

## Remove a status effect completely
func clear_effect(effect_name: String):
	status_effects.erase(effect_name)

## Clear all status effects
func clear_all_effects():
	status_effects.clear()

## Get status display string for UI
func get_status_display_string(use_short_names: bool = true) -> String:
	return StatusEffectRegistry.get_status_display_string(status_effects, use_short_names)

## Get status display array for detailed UI rendering
func get_status_display_array() -> Array[Dictionary]:
	return StatusEffectRegistry.get_status_display_array(status_effects)


# ============================================
# CARD RETENTION METHODS
# ============================================

## Retain a card in hand until the end of the specified round
func retain_card(card_name: String, expires_after_round: int):
	retained_cards[card_name] = expires_after_round
	print("[RETAIN] ", character_name, " retains ", card_name, " until end of round ", expires_after_round)

## Check if a card is currently retained
func is_card_retained(card_name: String) -> bool:
	return retained_cards.has(card_name)

## Clear retention for a card (e.g., when played)
func clear_card_retention(card_name: String):
	retained_cards.erase(card_name)

## Clear all card retentions
func clear_all_retentions():
	retained_cards.clear()


func reset_debuffs():
	# Reset all debuffs between bosses (keep buffs like strength/armor)
	poison = 0
	burn = 0
	vulnerable = 0
	weakness = 0
	exhausted = 0
	decay = 0

func add_card_to_deck(card: Card):
	deck.append(card)

func duplicate_character() -> Character:
	var new_char = Character.new()
	new_char.hero_id = hero_id  # Copy hero template ID for reward deck lookups
	new_char.character_name = character_name
	new_char.description = description
	new_char.max_health = max_health
	new_char.current_health = max_health  # Initialize current_health to match max_health
	new_char.starting_stamina = starting_stamina
	new_char.max_stamina = starting_stamina
	new_char.current_stamina = starting_stamina

	# Copy passive ability
	new_char.passive_ability_id = passive_ability_id

	# Deep copy the starting deck
	var deck_copy: Array[Card] = []
	for card in starting_deck:
		deck_copy.append(card.duplicate())
	new_char.starting_deck = deck_copy
	new_char.reset_deck()  # Initialize deck now that starting_deck is populated

	return new_char

# Network synchronization - data only, RPCs handled by GameManager
func get_state_dict() -> Dictionary:
	return {
		"hero_id": hero_id,  # Hero template ID for reward deck lookups
		"character_name": character_name,
		"current_health": current_health,
		"max_health": max_health,
		"current_stamina": current_stamina,
		"max_stamina": max_stamina,
		"shield": shield,
		"damage_taken_this_turn": damage_taken_this_turn,
		# NEW: Send all effects as single dictionary
		"status_effects": status_effects.duplicate(),
		# BACKWARD COMPAT: Also send individual fields for older clients
		"poison": poison,
		"burn": burn,
		"strength": strength,
		"vulnerable": vulnerable,
		"weakness": weakness,
		"armor": armor,
		"rested": rested,
		"invigorated": invigorated,
		"damage_plus": damage_plus,
		"fatigued": fatigued,
		"exhausted": exhausted,
		"decay": decay,
		"passive_ability_id": passive_ability_id,
		"passive_ability_used_this_turn": passive_ability_used_this_turn,
		"retained_cards": retained_cards.duplicate()
	}

func apply_state_dict(state: Dictionary):
	hero_id = state.get("hero_id", "")  # Load hero template ID
	character_name = state.character_name
	current_health = state.current_health
	max_health = state.max_health
	current_stamina = state.current_stamina
	max_stamina = state.max_stamina
	shield = state.shield
	damage_taken_this_turn = state.get("damage_taken_this_turn", 0)

	# NEW: Load from status_effects dictionary if present
	if state.has("status_effects"):
		status_effects = state.status_effects.duplicate()
	else:
		# BACKWARD COMPAT: Load from individual fields
		status_effects.clear()
		set_effect_amount("poison", state.get("poison", 0))
		set_effect_amount("burn", state.get("burn", 0))
		set_effect_amount("strength", state.get("strength", 0))
		set_effect_amount("vulnerable", state.get("vulnerable", 0))
		set_effect_amount("weakness", state.get("weakness", 0))
		set_effect_amount("armor", state.get("armor", 0))
		set_effect_amount("rested", state.get("rested", 0))
		set_effect_amount("invigorated", state.get("invigorated", 0))
		set_effect_amount("damage_plus", state.get("damage_plus", 0))
		set_effect_amount("fatigued", state.get("fatigued", 0))
		set_effect_amount("exhausted", state.get("exhausted", 0))
		set_effect_amount("decay", state.get("decay", 0))

	passive_ability_id = state.get("passive_ability_id", "")
	passive_ability_used_this_turn = state.get("passive_ability_used_this_turn", false)
	retained_cards = state.get("retained_cards", {}).duplicate()

func get_hand_dict() -> Array[Dictionary]:
	var hand_data: Array[Dictionary] = []
	for card in hand:
		hand_data.append(card.serialize())
	return hand_data

func apply_hand_dict(hand_data: Array):
	print("[CARD_DRAW] ", character_name, " hand synced from server (new size: ", hand_data.size(), ")")
	hand.clear()
	for card_dict in hand_data:
		hand.append(Card.deserialize(card_dict))
