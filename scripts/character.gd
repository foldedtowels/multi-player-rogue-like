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
		deck.shuffle()

	var card = deck.pop_front()
	hand.append(card)
	return card

func draw_cards(amount: int):
	for i in amount:
		draw_card()

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
	print("[Character] ", character_name, " starting turn. Deck: ", deck.size(), " cards")
	current_energy = max_energy
	apply_status_effects()
	draw_cards(5)
	print("[Character] After drawing 5 cards. Hand: ", hand.size(), " cards")

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

# Network synchronization functions
func sync_state_to_clients():
	# Server syncs state to all clients
	if not multiplayer.is_server(): return
	rpc("receive_state_sync", {
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
	})

@rpc("any_peer", "call_local", "reliable")
func receive_state_sync(state: Dictionary):
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

# Private hand sync (only to owner)
func sync_hand_to_owner():
	if not multiplayer.is_server(): return
	if network_owner_id == -1: return
	var hand_data: Array[Dictionary] = []
	for card in hand:
		hand_data.append(card.serialize())
	rpc_id(network_owner_id, "receive_hand_sync", hand_data)

@rpc("any_peer", "call_local", "reliable")
func receive_hand_sync(hand_data: Array):
	hand.clear()
	for card_dict in hand_data:
		hand.append(Card.deserialize(card_dict))
