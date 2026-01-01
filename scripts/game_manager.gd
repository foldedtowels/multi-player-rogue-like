extends Node

signal player_turn_started(player_index: int)
signal boss_turn_started()
signal card_played(character: Character, card: Card, target: Character)
signal combat_ended(victory: bool)
signal game_state_changed()

enum GameState {
	CHARACTER_SELECTION,
	COMBAT,
	REWARD,
	GAME_OVER,
	VICTORY
}

var current_state: GameState = GameState.CHARACTER_SELECTION
var players: Array[Character] = []
var current_boss: Character
var boss_index: int = 0
var current_player_index: int = 0
var round_number: int = 1

var hero_db: Node
var boss_db: Node

# Network tracking
var network_player_mapping: Dictionary = {}  # peer_id -> player_index
var local_player_index: int = -1  # Which character this client controls

# Deterministic RNG for multiplayer
var game_seed: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready():
	hero_db = get_node("/root/HeroDatabase")
	boss_db = get_node("/root/BossDatabase")

func start_new_game():
	players.clear()
	boss_index = 0
	current_state = GameState.CHARACTER_SELECTION
	game_state_changed.emit()

func select_heroes(hero_indices: Array):
	players.clear()
	var all_heroes = hero_db.get_all_heroes()

	for idx in hero_indices:
		if idx >= 0 and idx < all_heroes.size():
			# Duplicate the hero to avoid shared state
			var hero_copy = all_heroes[idx].duplicate_character()
			players.append(hero_copy)

	if players.size() == 3:
		start_boss_encounter()

func start_boss_encounter():
	current_boss = boss_db.get_boss(boss_index)
	if current_boss == null:
		# All bosses defeated!
		current_state = GameState.VICTORY
		game_state_changed.emit()
		return

	# Reset player debuffs between bosses
	for player in players:
		player.reset_debuffs()

	current_state = GameState.COMBAT
	round_number = 1
	current_player_index = 0

	# Characters are already initialized via their constructors
	# Don't call _init() manually - it's automatically called by Character.new()

	# Initialize deterministic RNG for multiplayer
	if multiplayer.is_server():
		game_seed = randi()
		rpc("sync_game_seed", game_seed)
	rng.seed = game_seed

	# Assign network ownership
	assign_characters_to_network_peers()

	# Don't start turn here - let combat scene do it after _ready()

@rpc("any_peer", "call_local", "reliable")
func sync_game_seed(seed: int):
	game_seed = seed
	rng.seed = seed

func assign_characters_to_network_peers():
	# Server assigns character indices to network peers
	if not multiplayer.is_server(): return
	var peer_ids = NetworkManager.players.keys()
	for i in range(min(3, peer_ids.size())):
		network_player_mapping[peer_ids[i]] = i
		rpc("receive_character_assignment", peer_ids[i], i)

@rpc("any_peer", "call_local", "reliable")
func receive_character_assignment(peer_id: int, character_index: int):
	network_player_mapping[peer_id] = character_index
	if peer_id == multiplayer.get_unique_id():
		local_player_index = character_index
	# Assign network owner to character
	if character_index < players.size():
		players[character_index].network_owner_id = peer_id

func start_player_turn(player_index: int):
	# Server controls turn flow
	if multiplayer.is_server():
		_server_start_player_turn(player_index)
	# Clients will receive RPC

func _server_start_player_turn(player_index: int):
	if player_index >= players.size():
		# All players have gone, now boss turn
		_server_start_boss_turn()
		return

	current_player_index = player_index
	var player = players[player_index]

	if not player.is_alive():
		# Skip dead players
		print("[Game] Skipping turn for dead player: ", player.character_name)
		_server_end_player_turn()
		return

	player.start_turn()
	# Sync state to all clients
	player.sync_state_to_clients()
	player.sync_hand_to_owner()
	# Notify all clients
	rpc("client_player_turn_started", player_index)

@rpc("any_peer", "call_local", "reliable")
func client_player_turn_started(player_index: int):
	current_player_index = player_index
	player_turn_started.emit(player_index)

func end_player_turn():
	# Server controls turn flow
	if multiplayer.is_server():
		_server_end_player_turn()
	else:
		# Client sends request to server
		rpc_id(1, "server_end_player_turn")

@rpc("any_peer", "call_remote", "reliable")
func server_end_player_turn():
	_server_end_player_turn()

func _server_end_player_turn():
	var player = players[current_player_index]
	player.end_turn()
	# Sync state to all clients
	player.sync_state_to_clients()

	# Move to next player
	_server_start_player_turn(current_player_index + 1)

func start_boss_turn():
	# Server controls boss turn
	if multiplayer.is_server():
		_server_start_boss_turn()
	# Clients will receive RPC

func _server_start_boss_turn():
	if not current_boss.is_alive():
		# Boss defeated!
		boss_defeated()
		return

	current_boss.start_turn()
	# Sync state to all clients
	current_boss.sync_state_to_clients()
	# Notify all clients
	rpc("client_boss_turn_started")

	# AI: Boss plays cards automatically
	await get_tree().create_timer(1.0).timeout
	play_boss_turn()

@rpc("any_peer", "call_local", "reliable")
func client_boss_turn_started():
	boss_turn_started.emit()

func play_boss_turn():
	# Simple AI: Play cards until out of energy
	var boss_hand = current_boss.hand.duplicate()

	for card in boss_hand:
		if not card.can_afford(current_boss.current_energy):
			continue

		var target = select_boss_target(card)
		if target:
			play_card(current_boss, card, target)
			await get_tree().create_timer(0.5).timeout

	end_boss_turn()

func select_boss_target(card: Card) -> Character:
	match card.target_type:
		Card.TargetType.SELF:
			return current_boss
		Card.TargetType.SINGLE_ENEMY, Card.TargetType.RANDOM_ENEMY:
			# Target random alive player using deterministic RNG
			var alive_players = players.filter(func(p): return p.is_alive())
			if alive_players.size() > 0:
				return alive_players[rng.randi() % alive_players.size()]
		Card.TargetType.ALL_ENEMIES:
			return players[0]  # Will be handled as AoE

	return null

func end_boss_turn():
	current_boss.end_turn()
	round_number += 1

	# Check if all players are dead
	var alive_count = 0
	for player in players:
		if player.is_alive():
			alive_count += 1

	if alive_count == 0:
		game_over()
		return

	# Start next round
	current_player_index = 0
	start_player_turn(0)

func play_card(caster: Character, card: Card, target: Character):
	# Server validates and processes
	if not multiplayer.is_server():
		# Client sends request to server
		var caster_index = players.find(caster)
		var target_index = -1
		if target == current_boss:
			target_index = -2  # Special index for boss
		else:
			target_index = players.find(target)
		rpc_id(1, "server_play_card", card.serialize(), caster_index, target_index)
		return

	# Server processes card
	_server_play_card(caster, card, target)

@rpc("any_peer", "call_remote", "reliable")
func server_play_card(card_data: Dictionary, caster_index: int, target_index: int):
	# Reconstruct card and characters
	var card = Card.deserialize(card_data)
	var caster = players[caster_index]
	var target: Character
	if target_index == -2:
		target = current_boss
	else:
		target = players[target_index]

	_server_play_card(caster, card, target)

func _server_play_card(caster: Character, card: Card, target: Character):
	if not caster.play_card(card):
		return

	# Apply card effects
	apply_card_effects(caster, card, target)

	# Sync all affected characters
	caster.sync_state_to_clients()
	caster.sync_hand_to_owner()
	if target != caster:
		target.sync_state_to_clients()

	# Notify all clients
	var caster_index = players.find(caster)
	var target_index = -1
	if target == current_boss:
		target_index = -2
	else:
		target_index = players.find(target)
	rpc("client_card_played", card.serialize(), caster_index, target_index)

@rpc("any_peer", "call_local", "reliable")
func client_card_played(card_data: Dictionary, caster_index: int, target_index: int):
	var card = Card.deserialize(card_data)
	var caster = players[caster_index]
	var target: Character
	if target_index == -2:
		target = current_boss
	else:
		target = players[target_index]

	card_played.emit(caster, card, target)
	game_state_changed.emit()

func apply_card_effects(caster: Character, card: Card, target: Character):
	# Determine targets based on target type
	var targets: Array[Character] = []

	match card.target_type:
		Card.TargetType.SELF:
			targets.append(caster)
		Card.TargetType.SINGLE_ALLY:
			targets.append(target)
		Card.TargetType.ALL_ALLIES:
			if caster == current_boss:
				targets.append(current_boss)
			else:
				targets = players.duplicate()
		Card.TargetType.SINGLE_ENEMY, Card.TargetType.RANDOM_ENEMY:
			targets.append(target)
		Card.TargetType.ALL_ENEMIES:
			if caster == current_boss:
				targets = players.duplicate()
			else:
				targets.append(current_boss)

	# Apply effects to all targets
	for t in targets:
		if not t.is_alive():
			continue

		# Damage
		if card.damage > 0:
			for i in card.multi_hit:
				# Apply strength bonus to attack damage
				var total_damage = card.damage
				if card.card_type == Card.CardType.ATTACK:
					total_damage += caster.strength

				var damage_dealt = t.take_damage(total_damage, card.piercing)

				# Lifesteal
				if card.lifesteal:
					caster.heal(damage_dealt)

		# Healing
		if card.heal_amount > 0:
			t.heal(card.heal_amount)

		# Shield
		if card.shield_amount > 0:
			t.gain_shield(card.shield_amount)

		# Status effects
		if card.apply_poison > 0:
			t.poison += card.apply_poison
		if card.apply_burn > 0:
			t.burn += card.apply_burn
		if card.apply_strength > 0:
			t.strength += card.apply_strength
		if card.apply_vulnerable > 0:
			t.vulnerable += card.apply_vulnerable
		if card.apply_weakness > 0:
			t.weakness += card.apply_weakness
		if card.apply_armor > 0:
			t.armor += card.apply_armor

		# Card draw
		if card.draw_cards > 0 and (t == caster):
			t.draw_cards(card.draw_cards)

func boss_defeated():
	current_state = GameState.REWARD
	boss_index += 1

	await get_tree().create_timer(2.0).timeout

	if boss_index >= 5:
		victory()
	else:
		# Load reward scene (synchronized for multiplayer)
		if multiplayer.is_server():
			NetworkManager.change_scene_synchronized.rpc("res://scenes/reward.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/reward.tscn")

func game_over():
	current_state = GameState.GAME_OVER
	combat_ended.emit(false)
	game_state_changed.emit()

func victory():
	current_state = GameState.VICTORY
	combat_ended.emit(true)
	game_state_changed.emit()
