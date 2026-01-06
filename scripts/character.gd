extends Resource
class_name Character

@export var character_name: String
@export var description: String
@export var max_health: int = 100
@export var starting_energy: int = 3
@export var starting_deck: Array[Card] = []

# Character stats
var current_health: int
var current_energy: int
var max_energy: int
var shield: int = 0

# Status effects
var poison: int = 0
var burn: int = 0
var strength: int = 0
var vulnerable: int = 0
var weakness: int = 0
var armor: int = 0

# Deck management
var deck: Array[Card] = []
var hand: Array[Card] = []
var discard_pile: Array[Card] = []
var exhaust_pile: Array[Card] = []

# Character role
enum CharacterRole { PLAYER, MINION, BOSS }
var character_role: CharacterRole = CharacterRole.PLAYER
var is_minion: bool = false

# Network ownership
var network_owner_id: int = -1  # Which peer owns this character

func _init():
	current_health = max_health
	max_energy = starting_energy
	current_energy = max_energy
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
	print("[Character] ", character_name, " draw_cards(", amount, ") - starting with hand: ", hand.size(), " | deck: ", deck.size())
	for i in amount:
		var drawn = draw_card()
		if drawn == null:
			print("[Character] ", character_name, " draw_card() returned null at iteration ", i, " | hand: ", hand.size(), " | deck: ", deck.size(), " | discard: ", discard_pile.size())
	print("[Character] ", character_name, " draw_cards done - hand after: ", hand.size())

func discard_card(card: Card):
	hand.erase(card)
	discard_pile.append(card)

func exhaust_card(card: Card):
	hand.erase(card)
	exhaust_pile.append(card)

func play_card(card: Card):
	if card.can_afford(current_energy):
		current_energy -= card.energy_cost
		hand.erase(card)
		discard_pile.append(card)
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
	return actual_damage

func heal(amount: int):
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
	print("[Character] ", character_name, " start_turn - hand size BEFORE drawing: ", hand.size(), " | deck size: ", deck.size())
	current_energy = max_energy
	apply_status_effects()
	draw_cards(5)
	print("[Character] ", character_name, " start_turn - hand size AFTER drawing: ", hand.size(), " | deck size: ", deck.size())

func add_energy(amount: int):
	current_energy += amount
	current_energy = clamp(current_energy, 0, max_energy + 5)  # Allow slight overflow

func end_turn():
	# Discard hand
	while hand.size() > 0:
		discard_card(hand[0])

	# Reset shield
	shield = 0

	# Decay status effects at end of turn
	if vulnerable > 0:
		vulnerable -= GameConstants.STATUS_DECAY_AMOUNT
	if weakness > 0:
		weakness -= GameConstants.STATUS_DECAY_AMOUNT

func apply_status_effects():
	# Poison: deals damage, then decays
	if poison > 0:
		take_damage(poison, true)
		poison = max(0, poison - GameConstants.POISON_DECAY_AMOUNT)

	# Burn: deals damage each turn, does not decay
	if burn > 0:
		take_damage(burn, true)

func is_alive() -> bool:
	return current_health > 0

func reset_debuffs():
	# Reset all debuffs between bosses (keep buffs like strength/armor)
	poison = 0
	burn = 0
	vulnerable = 0
	weakness = 0

func add_card_to_deck(card: Card):
	deck.append(card)

func duplicate_character() -> Character:
	var new_char = Character.new()
	new_char.character_name = character_name
	new_char.description = description
	new_char.max_health = max_health
	new_char.current_health = max_health  # Initialize current_health to match max_health
	new_char.starting_energy = starting_energy
	new_char.max_energy = starting_energy
	new_char.current_energy = starting_energy

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
		"character_name": character_name,
		"current_health": current_health,
		"max_health": max_health,
		"current_energy": current_energy,
		"max_energy": max_energy,
		"shield": shield,
		"poison": poison,
		"burn": burn,
		"strength": strength,
		"vulnerable": vulnerable,
		"weakness": weakness,
		"armor": armor
	}

func apply_state_dict(state: Dictionary):
	character_name = state.character_name
	current_health = state.current_health
	max_health = state.max_health
	current_energy = state.current_energy
	max_energy = state.max_energy
	shield = state.shield
	poison = state.poison
	burn = state.burn
	strength = state.strength
	vulnerable = state.vulnerable
	weakness = state.weakness
	armor = state.armor

func get_hand_dict() -> Array[Dictionary]:
	var hand_data: Array[Dictionary] = []
	for card in hand:
		hand_data.append(card.serialize())
	return hand_data

func apply_hand_dict(hand_data: Array):
	print("[Character] ", character_name, " apply_hand_dict - hand size BEFORE clear: ", hand.size(), " | incoming data size: ", hand_data.size())
	hand.clear()
	for card_dict in hand_data:
		hand.append(Card.deserialize(card_dict))
	print("[Character] ", character_name, " apply_hand_dict - hand size AFTER: ", hand.size())
