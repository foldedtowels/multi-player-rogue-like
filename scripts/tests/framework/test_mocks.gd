class_name TestMocks
## Mock objects for test isolation
## Provides fake implementations of game systems for controlled testing

# ============================================
# MOCK GAME MANAGER
# ============================================

## A minimal GameManager mock for unit tests
## Only includes the properties/methods needed for card effect testing
class MockGameManager extends RefCounted:
	enum GameState { MENU, COMBAT, REWARD, MAP }
	enum TurnPhase { PLAYER_TURN, ENEMY_TURN, RESOLVING }

	var players: Array[Character] = []
	var enemies: Array[Character] = []
	var protected_by: Dictionary = {}  # player_index -> protector_player_index
	var delayed_effects: Array[Dictionary] = []
	var queued_cards: Array[Dictionary] = []

	var current_state: GameState = GameState.COMBAT
	var turn_phase: TurnPhase = TurnPhase.PLAYER_TURN
	var round_number: int = 1
	var local_player_index: int = 0

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()

	func _init():
		rng.seed = 12345  # Deterministic for tests

	func get_local_player() -> Character:
		if local_player_index >= 0 and local_player_index < players.size():
			return players[local_player_index]
		return null

	func get_all_characters() -> Array[Character]:
		var all: Array[Character] = []
		all.append_array(players)
		all.append_array(enemies)
		return all

	func get_alive_players() -> Array[Character]:
		var alive: Array[Character] = []
		for p in players:
			if p.is_alive():
				alive.append(p)
		return alive

	func get_alive_enemies() -> Array[Character]:
		var alive: Array[Character] = []
		for e in enemies:
			if e.is_alive():
				alive.append(e)
		return alive

	func is_player(char: Character) -> bool:
		return char in players

	func is_enemy(char: Character) -> bool:
		return char in enemies

	func get_player_index(char: Character) -> int:
		return players.find(char)

	func get_enemy_index(char: Character) -> int:
		return enemies.find(char)


# ============================================
# MOCK CARD DATABASE
# ============================================

## A minimal CardDatabase mock that can hold test cards
class MockCardDatabase extends RefCounted:
	var cards: Dictionary = {}

	func add_card(card_id: String, card: Card) -> void:
		cards[card_id] = card

	func get_card(card_id: String) -> Card:
		if cards.has(card_id):
			return cards[card_id].duplicate()
		return null

	func has_card(card_id: String) -> bool:
		return cards.has(card_id)


# ============================================
# MOCK RNG
# ============================================

## A deterministic RNG for reproducible tests
class MockRNG extends RefCounted:
	var sequence: Array[int] = []
	var index: int = 0

	func _init(values: Array[int] = []):
		sequence = values

	func randi() -> int:
		if sequence.is_empty():
			return 0
		var value = sequence[index % sequence.size()]
		index += 1
		return value

	func randi_range(from: int, to: int) -> int:
		var range_size = to - from + 1
		return from + (randi() % range_size)

	func randf() -> float:
		return float(randi()) / float(0x7FFFFFFF)

	func randf_range(from: float, to: float) -> float:
		return from + randf() * (to - from)

	## Set specific sequence of values to return
	func set_sequence(values: Array[int]) -> void:
		sequence = values
		index = 0

	## Reset to beginning of sequence
	func reset() -> void:
		index = 0


# ============================================
# MOCK NETWORK
# ============================================

## Mock network peer for multiplayer tests
class MockNetworkPeer extends RefCounted:
	var peer_id: int = 1
	var is_host: bool = true
	var connected_peers: Array[int] = [1]
	var rpc_calls: Array[Dictionary] = []  # Records all RPC calls for verification

	func get_unique_id() -> int:
		return peer_id

	func is_server() -> bool:
		return is_host

	func get_peers() -> Array[int]:
		return connected_peers

	## Record an RPC call for later verification
	func record_rpc(method: String, args: Array) -> void:
		rpc_calls.append({
			"method": method,
			"args": args,
			"time": Time.get_ticks_msec()
		})

	## Check if a specific RPC was called
	func was_rpc_called(method: String) -> bool:
		for call in rpc_calls:
			if call.method == method:
				return true
		return false

	## Get all calls to a specific RPC method
	func get_rpc_calls(method: String) -> Array[Dictionary]:
		var calls: Array[Dictionary] = []
		for call in rpc_calls:
			if call.method == method:
				calls.append(call)
		return calls

	## Clear recorded RPC calls
	func clear_rpc_calls() -> void:
		rpc_calls.clear()


# ============================================
# MOCK UI MANAGER
# ============================================

## Mock UI manager that records UI calls without actual rendering
class MockUIManager extends RefCounted:
	var shown_modals: Array[String] = []
	var displayed_messages: Array[String] = []
	var updated_panels: Array[String] = []

	func show_modal(modal_type: String, _data: Dictionary = {}) -> void:
		shown_modals.append(modal_type)

	func display_message(message: String) -> void:
		displayed_messages.append(message)

	func update_panel(panel_name: String) -> void:
		updated_panels.append(panel_name)

	func was_modal_shown(modal_type: String) -> bool:
		return modal_type in shown_modals

	func was_message_displayed(message: String) -> bool:
		return message in displayed_messages

	func clear() -> void:
		shown_modals.clear()
		displayed_messages.clear()
		updated_panels.clear()


# ============================================
# FACTORY METHODS
# ============================================

## Create a mock game manager with players and enemies set up
static func create_mock_game_manager(player_count: int = 1, enemy_count: int = 1) -> MockGameManager:
	var gm = MockGameManager.new()

	for i in range(player_count):
		var p = TestFixtures.player("Player%d" % (i + 1), 100, 10)
		gm.players.append(p)

	for i in range(enemy_count):
		var e = TestFixtures.enemy("Enemy%d" % (i + 1), 100)
		gm.enemies.append(e)

	return gm


## Create a mock card database with basic test cards
static func create_mock_card_db() -> MockCardDatabase:
	var db = MockCardDatabase.new()

	# Add some basic test cards
	var attack = Card.new()
	attack.card_name = "Test Attack"
	attack.damage = 10
	attack.stamina_cost = 1
	attack.card_type = Card.CardType.ATTACK
	attack.target_type = Card.TargetType.SINGLE_ENEMY
	db.add_card("test_attack", attack)

	var buff = Card.new()
	buff.card_name = "Test Buff"
	buff.shield = 5
	buff.stamina_cost = 1
	buff.card_type = Card.CardType.BUFF
	buff.target_type = Card.TargetType.SELF
	db.add_card("test_buff", buff)

	var heal = Card.new()
	heal.card_name = "Test Heal"
	heal.heal = 10
	heal.stamina_cost = 1
	heal.card_type = Card.CardType.BUFF
	heal.target_type = Card.TargetType.SELF
	db.add_card("test_heal", heal)

	return db


## Create a deterministic RNG with a specific sequence
static func create_mock_rng(sequence: Array[int] = []) -> MockRNG:
	return MockRNG.new(sequence)


## Create a mock network peer configured as host
static func create_host_peer() -> MockNetworkPeer:
	var peer = MockNetworkPeer.new()
	peer.peer_id = 1
	peer.is_host = true
	peer.connected_peers = [1, 2]
	return peer


## Create a mock network peer configured as client
static func create_client_peer(client_id: int = 2) -> MockNetworkPeer:
	var peer = MockNetworkPeer.new()
	peer.peer_id = client_id
	peer.is_host = false
	peer.connected_peers = [1, client_id]
	return peer
