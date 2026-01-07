extends Node

signal player_turn_started(player_index: int)
signal boss_turn_started()
signal card_played(character: Character, card: Card, target: Character)
signal combat_ended(victory: bool)
signal game_state_changed()
signal enemy_damaged_player(enemy_name: String, card_name: String, damage: int, target_player_index: int)

enum GameState {
	CHARACTER_SELECTION,
	COMBAT,
	REWARD,
	GAME_OVER,
	VICTORY
}

enum CombatPhase {
	MINION_COMBAT,
	BOSS_PHASE_1,
	BOSS_PHASE_2
}

enum TurnPhase {
	PLAYER_SELECTION,  # All players selecting cards
	PLAYER_ACTION,     # Players playing selected cards in flexible order
	ENEMY_TURN        # Enemies taking turns
}

enum EncounterType {
	MINION,        # Minion fight before boss
	BOSS_PHASE_1,  # First phase of boss fight
	BOSS_PHASE_2   # Second phase of boss fight (if boss has multiple phases)
}

var current_state: GameState = GameState.CHARACTER_SELECTION
var turn_phase: TurnPhase = TurnPhase.PLAYER_SELECTION
var players: Array[Character] = []
var enemies: Array[Character] = []  # Up to 3 enemies (minions + boss)
var current_boss: Character  # Points to boss in enemies array
var combat_phase: CombatPhase = CombatPhase.BOSS_PHASE_1
var boss_index: int = 0
var current_player_index: int = 0
var round_number: int = 1
var next_queue_id: int = 1  # Counter for unique queue instance IDs

var hero_db: Node
var boss_db: Node
var minion_db: Node

# Network tracking
var network_player_mapping: Dictionary = {}  # peer_id -> player_index
var local_player_index: int = -1  # Which character this client controls

# Deterministic RNG for multiplayer
var game_seed: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Last played cards for UI display (player_index -> Card)
var last_played_cards: Dictionary = {}

# Simultaneous card selection system
var players_ready: Dictionary = {}  # player_index -> bool
var queued_cards: Dictionary = {}   # player_index -> Array[Card] (no targets yet)
var players_done_acting: Dictionary = {}  # player_index -> bool (who clicked Done)

func _ready():
	hero_db = get_node("/root/HeroDatabase")
	boss_db = get_node("/root/BossDatabase")
	minion_db = get_node("/root/MinionDatabase")

func start_new_game():
	players.clear()
	boss_index = 0
	current_state = GameState.CHARACTER_SELECTION
	game_state_changed.emit()

@rpc("any_peer", "call_local", "reliable")
func select_heroes(hero_indices: Array):
	players.clear()
	var all_heroes = hero_db.get_all_heroes()

	for idx in hero_indices:
		if idx >= 0 and idx < all_heroes.size():
			# Duplicate the hero to avoid shared state
			var hero_copy = all_heroes[idx].duplicate_character()
			players.append(hero_copy)

	# NOTE: Encounter initialization now happens in calling scene (character_selection.gd)
	# using initialize_combat_encounter() for consistent modular setup

## DEPRECATED: Use initialize_combat_encounter() instead
## This function is kept for compatibility but should not be used in new code
func start_boss_encounter():
	push_warning("[DEPRECATED] start_boss_encounter() is deprecated. Use initialize_combat_encounter() instead.")
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

	# Setup enemies array - FIRST spawn minions for this boss
	enemies.clear()
	var minions = minion_db.get_minions_for_boss(boss_index)

	if minions.size() > 0:
		# Start with minion combat phase
		combat_phase = CombatPhase.MINION_COMBAT
		for minion in minions:
			enemies.append(minion)
	else:
		# No minions, go straight to boss
		combat_phase = CombatPhase.BOSS_PHASE_1
		current_boss.character_role = Character.CharacterRole.BOSS
		enemies.append(current_boss)

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

## UNIFIED ENCOUNTER INITIALIZATION ##
## This function provides modular, consistent initialization for ALL combat encounters
## Use this instead of start_boss_encounter() + reset_players_between_encounters()
@rpc("any_peer", "call_local", "reliable")
func initialize_combat_encounter(encounter_type: EncounterType, boss_idx: int):
	"""
	Unified initialization for ALL combat encounters.
	Use this for first minion fight, second minion fight, boss fights, etc.
	Ensures consistent state reset and synchronization.

	Args:
		encounter_type: MINION, BOSS_PHASE_1, or BOSS_PHASE_2
		boss_idx: Which boss (0-4) to load enemies for
	"""

	print("[GameManager] initialize_combat_encounter - type: ", encounter_type, " boss_idx: ", boss_idx)

	# Step 1: Clear ALL combat state
	enemies.clear()
	queued_cards.clear()
	players_ready.clear()
	players_done_acting.clear()
	last_played_cards.clear()

	# Step 2: Set game state
	current_state = GameState.COMBAT
	round_number = 1
	current_player_index = 0
	boss_index = boss_idx

	# Step 3: Load boss reference (needed even for minion fights)
	# CRITICAL: Always load current_boss so it's available for transitions
	if encounter_type != EncounterType.BOSS_PHASE_2:
		current_boss = boss_db.get_boss(boss_idx).duplicate_character()

	# Step 4: Load enemies based on encounter type
	match encounter_type:
		EncounterType.MINION:
			var minions = minion_db.get_minions_for_boss(boss_idx)
			for minion in minions:
				enemies.append(minion)
			combat_phase = CombatPhase.MINION_COMBAT
			print("[GameManager] Loaded ", minions.size(), " minions for boss ", boss_idx, " (boss loaded for later: ", current_boss.character_name, ")")

		EncounterType.BOSS_PHASE_1:
			current_boss.character_role = Character.CharacterRole.BOSS
			enemies.append(current_boss)
			combat_phase = CombatPhase.BOSS_PHASE_1
			print("[GameManager] Loaded boss: ", current_boss.character_name)

		EncounterType.BOSS_PHASE_2:
			# Boss already exists, just add back to enemies
			enemies.append(current_boss)
			combat_phase = CombatPhase.BOSS_PHASE_2
			print("[GameManager] Boss phase 2: ", current_boss.character_name)

	# Step 5: Reset player state (keep earned cards!)
	for i in range(players.size()):
		var player = players[i]

		# Return all cards to deck (hand, discard)
		for card in player.hand:
			player.deck.append(card)
		player.hand.clear()

		for card in player.discard_pile:
			player.deck.append(card)
		player.discard_pile.clear()

		# Exhaust pile cards are removed (don't add back)
		player.exhaust_pile.clear()

		# Shuffle deck (includes earned cards!)
		player.deck.shuffle()

		# Reset temporary combat state
		player.shield = 0
		player.current_energy = player.max_energy
		player.reset_debuffs()

		print("[GameManager] Player ", i, " (", player.character_name, ") reset - deck: ", player.deck.size(), " cards")

	# Step 6: Sync state to all clients (server only)
	if multiplayer.is_server():
		# Assign network ownership
		assign_characters_to_network_peers()

		# Broadcast player state (don't send hands yet - start_round() will draw and send)
		for i in range(players.size()):
			broadcast_character_state(players[i])

		# Sync enemies
		match encounter_type:
			EncounterType.MINION:
				sync_minion_enemies()
			EncounterType.BOSS_PHASE_1, EncounterType.BOSS_PHASE_2:
				sync_boss_enemy()

		# Sync RNG seed for deterministic gameplay
		game_seed = randi()
		rpc("sync_game_seed", game_seed)

	rng.seed = game_seed

	print("[GameManager] initialize_combat_encounter complete - enemies: ", enemies.size(), " queued_cards cleared")

# Character state sync RPCs
@rpc("any_peer", "call_local", "reliable")
func sync_character_state(char_index: int, is_player: bool, state: Dictionary):
	# Safety check: ensure arrays are populated
	if is_player and (char_index < 0 or char_index >= players.size()):
		push_warning("[GameManager] sync_character_state: Invalid player index %d (players.size=%d)" % [char_index, players.size()])
		return
	if not is_player and (char_index < 0 or char_index >= enemies.size()):
		push_warning("[GameManager] sync_character_state: Invalid enemy index %d (enemies.size=%d)" % [char_index, enemies.size()])
		return

	var character: Character
	if is_player:
		character = players[char_index]
	else:
		character = enemies[char_index]
	character.apply_state_dict(state)

@rpc("any_peer", "call_remote", "reliable")
func sync_character_hand(char_index: int, hand_data: Array):
	if char_index >= 0 and char_index < players.size():
		players[char_index].apply_hand_dict(hand_data)

@rpc("any_peer", "call_local", "reliable")
func sync_last_played_card(player_index: int, card_data: Dictionary):
	# Deserialize card and store it
	var card = Card.deserialize(card_data)
	last_played_cards[player_index] = card
	# UI will refresh and display this card in side panels

func broadcast_character_state(character: Character):
	if not multiplayer.is_server(): return

	var is_player = players.has(character)
	var char_index = -1
	if is_player:
		char_index = players.find(character)
	else:
		char_index = enemies.find(character)

	if char_index >= 0:
		rpc("sync_character_state", char_index, is_player, character.get_state_dict())

func send_hand_to_owner(character: Character):
	if not multiplayer.is_server(): return

	var char_index = players.find(character)
	if char_index == -1: return

	var hand_data = character.get_hand_dict()
	print("[GameManager] send_hand_to_owner - ", character.character_name, " (player ", char_index, ") | hand size: ", hand_data.size())

	# Broadcast to clients via RPC
	rpc("sync_character_hand", char_index, hand_data)

	# CRITICAL: Also update server's own copy since we use "call_remote"
	# This ensures all players (including host) have correct hand state
	character.apply_hand_dict(hand_data)

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

# Hero selection sync for character selection screen
@rpc("any_peer", "call_local", "reliable")
func receive_hero_selection(peer_id: int, hero_index: int):
	# Broadcast to character selection scene
	var char_select = get_tree().current_scene
	if char_select and char_select.has_method("on_player_selected_hero"):
		char_select.on_player_selected_hero(peer_id, hero_index)

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
		_server_end_player_turn()
		return

	player.start_turn()
	# Sync state to all clients
	broadcast_character_state(player)
	send_hand_to_owner(player)
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
	broadcast_character_state(player)

	# Move to next player
	_server_start_player_turn(current_player_index + 1)

func start_boss_turn():
	# Server controls boss turn
	if multiplayer.is_server():
		_server_start_boss_turn()
	# Clients will receive RPC

func _server_start_boss_turn():
	# Start turns for all alive enemies
	await start_enemies_turn()

func start_enemies_turn() -> bool:
	# Each enemy takes a turn sequentially
	for enemy in enemies:
		if not enemy.is_alive():
			continue

		enemy.start_turn()
		# Sync state to all clients
		broadcast_character_state(enemy)
		# Notify all clients
		rpc("client_enemy_turn_started", enemies.find(enemy))

		# AI: Enemy plays cards automatically
		await get_tree().create_timer(1.0).timeout
		play_enemy_turn(enemy)
		await get_tree().create_timer(0.5).timeout

	# All enemies finished, check victory
	return await check_combat_victory()

func check_combat_victory() -> bool:
	var alive_enemies = enemies.filter(func(e): return e.is_alive())
	if alive_enemies.is_empty():
		# Check combat phase
		if combat_phase == CombatPhase.MINION_COMBAT:
			# Minions defeated! Transition to buff selection
			await transition_to_buff_phase()
			return true  # Combat transitioning to boss phase
		else:
			# Boss defeated!
			boss_defeated()
			return true  # Combat ended

	# Continue to next round
	end_boss_turn()
	return false  # Combat continues

func transition_to_buff_phase():

	# Transition to buff selection scene
	if multiplayer.is_server():
		NetworkManager.change_scene_synchronized.rpc("res://scenes/buff_selection.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/buff_selection.tscn")

## DEPRECATED: Use initialize_combat_encounter() instead
## Reset players between combat encounters (KEEPS earned cards in deck!)
## This function is kept for compatibility but should not be used in new code
func reset_players_between_encounters():
	push_warning("[DEPRECATED] reset_players_between_encounters() is deprecated. Use initialize_combat_encounter() instead.")
	print("[GameManager] Resetting players between encounters (keeping earned cards)")

	# DEBUG: Show queued_cards before clearing
	print("[QUEUED_CARDS DEBUG] BEFORE reset_players_between_encounters:")
	for player_idx in queued_cards.keys():
		print("  Player ", player_idx, ": ", queued_cards[player_idx].size(), " cards")

	# Clear all combat state dictionaries
	queued_cards.clear()
	players_ready.clear()
	players_done_acting.clear()
	last_played_cards.clear()

	# DEBUG: Confirm cleared
	print("[QUEUED_CARDS DEBUG] AFTER reset_players_between_encounters - queued_cards.size(): ", queued_cards.size())

	# Reset each player's temporary state (but keep their deck!)
	for i in range(players.size()):
		var player = players[i]

		# CRITICAL: Return all cards to deck before shuffling (don't lose them!)
		# Add cards from hand back to deck
		for card in player.hand:
			player.deck.append(card)
		player.hand.clear()

		# Add cards from discard back to deck
		for card in player.discard_pile:
			player.deck.append(card)
		player.discard_pile.clear()

		# Exhaust pile cards are intentionally removed (don't add back to deck)
		player.exhaust_pile.clear()

		# Shuffle deck (now includes ALL non-exhausted cards)
		player.deck.shuffle()

		# Clear temporary combat buffs
		player.shield = 0

		# Reset energy to max
		player.current_energy = player.max_energy

		# Clear debuffs between fights (keep permanent buffs like strength/armor)
		player.reset_debuffs()

		print("[GameManager] Player ", i, " (", player.character_name, ") reset - deck: ", player.deck.size(), " cards")

## Reset players to starting deck for a NEW RUN (LOSES earned cards!)
## Only use this when starting a brand new run, not between encounters
func reset_players_for_new_run():
	print("[GameManager] Resetting players for NEW RUN (back to starting deck)")

	# Clear all combat state dictionaries
	queued_cards.clear()
	players_ready.clear()
	players_done_acting.clear()
	last_played_cards.clear()

	# Reset each player to starting state
	for i in range(players.size()):
		var player = players[i]

		# Clear all card piles (no need to return to deck since we're resetting to starting deck anyway)
		player.hand.clear()
		player.discard_pile.clear()
		player.exhaust_pile.clear()

		# RESET deck to starting deck (loses earned cards!)
		player.deck = player.starting_deck.duplicate()
		player.deck.shuffle()

		# Clear temporary combat buffs
		player.shield = 0

		# Reset energy to max
		player.current_energy = player.max_energy

		# Clear debuffs
		player.reset_debuffs()

		print("[GameManager] Player ", i, " (", player.character_name, ") reset to starting deck - ", player.deck.size(), " cards")

## DEPRECATED: Use initialize_combat_encounter() instead
## This function is kept for compatibility but should not be used in new code
func start_boss_phase_1():
	push_warning("[DEPRECATED] start_boss_phase_1() is deprecated. Use initialize_combat_encounter() instead.")
	# Clear minions, add boss
	enemies.clear()
	current_boss.character_role = Character.CharacterRole.BOSS
	enemies.append(current_boss)
	combat_phase = CombatPhase.BOSS_PHASE_1

	# Reset combat state
	round_number = 1
	current_player_index = 0

	# CRITICAL: Reset player state between encounters (keeps earned cards!)
	reset_players_between_encounters()

	# Broadcast updated state to all clients before scene change
	if multiplayer.is_server():
		for i in range(players.size()):
			broadcast_character_state(players[i])
			send_hand_to_owner(players[i])  # CRITICAL: Sync cleared hands!

		# Sync boss enemy to all clients
		sync_boss_enemy()

	# Restart combat (this will reload the combat scene)
	if multiplayer.is_server():
		NetworkManager.change_scene_synchronized.rpc("res://scenes/combat.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/combat.tscn")

func sync_boss_enemy():
	# Server syncs the boss enemy to all clients
	if not multiplayer.is_server(): return

	var boss_state = current_boss.get_state_dict()
	rpc("client_receive_boss_enemy", boss_state)

@rpc("any_peer", "call_local", "reliable")
func client_receive_boss_enemy(boss_state: Dictionary):
	# Clear enemies and add the boss
	enemies.clear()
	enemies.append(current_boss)

	# Apply the state to the boss
	current_boss.apply_state_dict(boss_state)
	combat_phase = CombatPhase.BOSS_PHASE_1

	# Emit state change so UI updates
	game_state_changed.emit()

## Sync minion enemies to all clients (called after start_boss_encounter loads minions)
func sync_minion_enemies():
	# Server syncs the minion enemies to all clients
	if not multiplayer.is_server(): return

	# Serialize all minion states
	var minion_states: Array[Dictionary] = []
	for enemy in enemies:
		minion_states.append(enemy.get_state_dict())

	rpc("client_receive_minion_enemies", minion_states)

@rpc("any_peer", "call_local", "reliable")
func client_receive_minion_enemies(minion_states: Array[Dictionary]):
	# Clear enemies and recreate minions from state data
	enemies.clear()

	# Recreate minions from serialized data
	var minions = minion_db.get_minions_for_boss(boss_index)
	for i in range(minion_states.size()):
		if i < minions.size():
			enemies.append(minions[i])
			minions[i].apply_state_dict(minion_states[i])

	combat_phase = CombatPhase.MINION_COMBAT

	# Emit state change so UI updates
	game_state_changed.emit()

@rpc("any_peer", "call_local", "reliable")
func client_enemy_turn_started(enemy_index: int):
	boss_turn_started.emit()

@rpc("any_peer", "call_local", "reliable")
func client_boss_turn_started():
	boss_turn_started.emit()

func play_boss_turn():
	# Legacy function for backward compatibility
	# Now handled by play_enemy_turn in start_enemies_turn()
	pass

func play_enemy_turn(enemy: Character):
	# Don't play turn if enemy is dead (HP <= 0)
	if not enemy.is_alive():
		return

	# Simple AI: Play cards until out of energy
	var enemy_hand = enemy.hand.duplicate()

	for card in enemy_hand:
		if not card.can_afford(enemy.current_energy):
			continue

		var target = select_enemy_target(enemy, card)
		if target:
			play_card(enemy, card, target)
			await get_tree().create_timer(0.5).timeout

	enemy.end_turn()
	# Sync state to all clients
	broadcast_character_state(enemy)

## NEW SIMULTANEOUS TURN SYSTEM ##

# Start a new round with selection phase
func start_round():
	if not multiplayer.is_server(): return

	print("\n##################### ROUND ", round_number, " - FRIENDLY TURN #####################")

	# DEBUG: Show queued_cards before clearing
	print("[QUEUED_CARDS DEBUG] start_round() BEFORE clear - queued_cards:")
	for player_idx in queued_cards.keys():
		print("  Player ", player_idx, ": ", queued_cards[player_idx].size(), " cards")

	turn_phase = TurnPhase.PLAYER_SELECTION
	players_ready.clear()
	queued_cards.clear()
	players_done_acting.clear()

	print("[QUEUED_CARDS DEBUG] start_round() AFTER clear - queued_cards.size(): ", queued_cards.size())

	# All alive players start their turn (draw cards, gain energy)
	for i in range(players.size()):
		var player = players[i]
		if player.is_alive():
			player.start_turn()
			broadcast_character_state(player)
			send_hand_to_owner(player)
			queued_cards[i] = []
			print("[QUEUED_CARDS DEBUG] start_round() initialized queued_cards[", i, "] = []")

	# Notify all clients to enter selection phase
	rpc("client_selection_phase_started")

@rpc("any_peer", "call_local", "reliable")
func client_selection_phase_started():
	turn_phase = TurnPhase.PLAYER_SELECTION
	game_state_changed.emit()

# Sync a queued card from a player (no target yet)
func sync_queued_card(player_index: int, card_data: Dictionary):
	if multiplayer.is_server():
		_server_receive_queued_card(player_index, card_data)
	else:
		rpc_id(1, "server_receive_queued_card", player_index, card_data)

@rpc("any_peer", "call_remote", "reliable")
func server_receive_queued_card(player_index: int, card_data: Dictionary):
	_server_receive_queued_card(player_index, card_data)

func _server_receive_queued_card(player_index: int, card_data: Dictionary):
	var card = Card.deserialize(card_data)

	# Assign unique queue instance ID to distinguish identical cards
	card.queue_instance_id = next_queue_id
	next_queue_id += 1

	# Add to server's queued cards
	if not queued_cards.has(player_index):
		queued_cards[player_index] = []
	queued_cards[player_index].append(card)

	# DEBUG: Log card being added
	print("[QUEUED_CARDS DEBUG] _server_receive_queued_card - Player ", player_index, " queued ", card.card_name, " (total now: ", queued_cards[player_index].size(), ")")

	# Broadcast to all clients (with the assigned queue_instance_id)
	rpc("client_receive_queued_card", player_index, card.serialize())

@rpc("any_peer", "call_local", "reliable")
func client_receive_queued_card(player_index: int, card_data: Dictionary):
	# Server already added the card in _server_receive_queued_card
	# Don't add it again when receiving own broadcast
	if multiplayer.is_server():
		return

	var card = Card.deserialize(card_data)

	# Add to client's queued cards
	if not queued_cards.has(player_index):
		queued_cards[player_index] = []
	queued_cards[player_index].append(card)

	game_state_changed.emit()

# Player marks ready (done selecting cards)
func player_ready():
	var my_index = local_player_index
	if my_index == -1: return

	# Send to server
	if multiplayer.is_server():
		_server_player_ready(my_index)
	else:
		rpc_id(1, "server_player_ready", my_index)

@rpc("any_peer", "call_remote", "reliable")
func server_player_ready(player_index: int):
	_server_player_ready(player_index)

func _server_player_ready(player_index: int):
	players_ready[player_index] = true

	# Broadcast ready status
	rpc("client_player_ready_status", Array(players_ready.keys()))

	# Check if all alive players are ready
	check_all_players_ready()

@rpc("any_peer", "call_local", "reliable")
func client_player_ready_status(ready_indices: Array):
	players_ready.clear()
	for idx in ready_indices:
		players_ready[idx] = true
	game_state_changed.emit()

func check_all_players_ready():
	if not multiplayer.is_server(): return

	var alive_count = 0
	for player in players:
		if player.is_alive():
			alive_count += 1

	print("[SYNC] Players ready: ", players_ready.size(), "/", alive_count)
	if players_ready.size() >= alive_count:
		print("[SYNC] All players ready - starting action phase")
		start_action_phase()

# Transition to action phase
func start_action_phase():
	if not multiplayer.is_server(): return

	turn_phase = TurnPhase.PLAYER_ACTION
	players_done_acting.clear()

	# Notify all clients
	rpc("client_action_phase_started")

@rpc("any_peer", "call_local", "reliable")
func client_action_phase_started():
	turn_phase = TurnPhase.PLAYER_ACTION
	players_done_acting.clear()
	game_state_changed.emit()

# Remove a played card from the queue
func remove_queued_card(player_index: int, card: Card):
	if not queued_cards.has(player_index):
		return

	# Find and remove the matching card by unique queue instance ID
	for i in range(queued_cards[player_index].size()):
		var queued_card = queued_cards[player_index][i]
		# Match by queue_instance_id if available, otherwise fall back to card_name
		var matches = false
		if card.queue_instance_id > 0 and queued_card.queue_instance_id > 0:
			matches = (queued_card.queue_instance_id == card.queue_instance_id)
		else:
			matches = (queued_card.card_name == card.card_name)

		if matches:
			queued_cards[player_index].remove_at(i)

			# Broadcast removal to all clients (using queue_instance_id for precision)
			if multiplayer.is_server():
				rpc("client_remove_queued_card", player_index, card.queue_instance_id)
			return

@rpc("any_peer", "call_local", "reliable")
func client_remove_queued_card(player_index: int, queue_id: int):
	if not queued_cards.has(player_index):
		return

	# Find and remove the card by unique queue instance ID
	for i in range(queued_cards[player_index].size()):
		if queued_cards[player_index][i].queue_instance_id == queue_id:
			queued_cards[player_index].remove_at(i)
			game_state_changed.emit()
			return

# Player finishes their actions (clicked Done)
func player_done():
	var my_index = local_player_index
	if my_index == -1: return

	if multiplayer.is_server():
		_server_player_done(my_index)
	else:
		rpc_id(1, "server_player_done", my_index)

@rpc("any_peer", "call_remote", "reliable")
func server_player_done(player_index: int):
	_server_player_done(player_index)

func _server_player_done(player_index: int):
	players_done_acting[player_index] = true

	# Broadcast done status
	rpc("client_player_done_status", Array(players_done_acting.keys()))

	# Check if all players done
	check_action_phase_complete()

@rpc("any_peer", "call_local", "reliable")
func client_player_done_status(done_indices: Array):
	players_done_acting.clear()
	for idx in done_indices:
		players_done_acting[idx] = true
	game_state_changed.emit()

func check_action_phase_complete():
	if not multiplayer.is_server(): return

	var alive_count = 0
	for player in players:
		if player.is_alive():
			alive_count += 1

	print("[SYNC] Players done acting: ", players_done_acting.size(), "/", alive_count)
	if players_done_acting.size() >= alive_count:

		# Check if all enemies are already dead (killed during action phase)
		var enemies_alive = false
		for enemy in enemies:
			if enemy.is_alive():
				enemies_alive = true
				break

		if not enemies_alive:
			# Enemies defeated during action phase, end turns and check victory
			turn_phase = TurnPhase.ENEMY_TURN
			for i in range(players.size()):
				var player = players[i]
				if player.is_alive():
					player.end_turn()
					broadcast_character_state(player)
					send_hand_to_owner(player)  # Sync cleared hand
			rpc("client_enemy_turn_phase_started")
			await get_tree().create_timer(0.5).timeout
			await check_combat_victory()
		else:
			start_enemy_turn_phase()

# Start enemy turn phase
func start_enemy_turn_phase():
	if not multiplayer.is_server(): return

	# Build enemy names string for banner
	var enemy_names = []
	for enemy in enemies:
		if enemy.is_alive():
			enemy_names.append(enemy.character_name)
	var enemy_names_str = ", ".join(enemy_names)

	print("\n##################### ROUND ", round_number, " - ENEMY (", enemy_names_str, ") TURN #####################")

	turn_phase = TurnPhase.ENEMY_TURN

	# End all player turns
	for i in range(players.size()):
		var player = players[i]
		if player.is_alive():
			player.end_turn()
			broadcast_character_state(player)
			send_hand_to_owner(player)  # Sync cleared hand

	# Notify clients
	rpc("client_enemy_turn_phase_started")

	# Play enemy turns
	await get_tree().create_timer(0.5).timeout
	var combat_ended = await start_enemies_turn()

	# If combat transitioned (minions->boss) or ended, don't continue
	if combat_ended:
		return

	# After enemies done, check victory/defeat
	await get_tree().create_timer(0.5).timeout

	if check_combat_end():
		return

	# Start next round
	round_number += 1
	start_round()

@rpc("any_peer", "call_local", "reliable")
func client_enemy_turn_phase_started():
	turn_phase = TurnPhase.ENEMY_TURN
	game_state_changed.emit()

func check_combat_end() -> bool:
	# Check if all enemies dead (victory)
	var enemies_alive = false
	for enemy in enemies:
		if enemy.is_alive():
			enemies_alive = true
			break

	if not enemies_alive:
		rpc("client_combat_victory")
		return true

	# Check if all players dead (defeat)
	var players_alive = false
	for player in players:
		if player.is_alive():
			players_alive = true
			break

	if not players_alive:
		rpc("client_combat_defeat")
		return true

	return false

@rpc("any_peer", "call_local", "reliable")
func client_combat_victory():
	combat_ended.emit(true)
	current_state = GameState.REWARD

@rpc("any_peer", "call_local", "reliable")
func client_combat_defeat():
	combat_ended.emit(false)
	current_state = GameState.GAME_OVER

## END OF NEW SIMULTANEOUS TURN SYSTEM ##

func select_boss_target(card: Card) -> Character:
	# Legacy function for backward compatibility
	return select_enemy_target(current_boss, card)

func select_enemy_target(enemy: Character, card: Card) -> Character:
	match card.target_type:
		Card.TargetType.SELF:
			return enemy
		Card.TargetType.SINGLE_ENEMY, Card.TargetType.RANDOM_ENEMY:
			# Target random alive player using deterministic RNG
			var alive_players = players.filter(func(p): return p.is_alive())
			if alive_players.size() > 0:
				return alive_players[rng.randi() % alive_players.size()]
		Card.TargetType.ALL_ENEMIES:
			return players[0]  # Will be handled as AoE

	return null

func end_boss_turn():
	# Apply boss end-of-turn effects (status decay, etc.)
	current_boss.end_turn()

	# NOTE: round_number increment removed - handled by start_enemy_turn_phase()
	# NOTE: start_player_turn() removed - using new simultaneous turn system via start_round()

	# Check if all players are dead
	var alive_count = 0
	for player in players:
		if player.is_alive():
			alive_count += 1

	if alive_count == 0:
		game_over()
		return

func play_card(caster: Character, card: Card, target: Character):
	# Server validates and processes
	if not multiplayer.is_server():
		# Client sends request to server
		var caster_index = -1
		var caster_is_player = players.has(caster)
		if caster_is_player:
			caster_index = players.find(caster)
		else:
			caster_index = enemies.find(caster)

		var target_index = -1
		var target_is_player = players.has(target)
		if target_is_player:
			target_index = players.find(target)
		else:
			target_index = enemies.find(target)

		rpc_id(1, "server_play_card", card.serialize(), caster_index, caster_is_player, target_index, target_is_player)
		return

	# Server processes card
	_server_play_card(caster, card, target)

@rpc("any_peer", "call_remote", "reliable")
func server_play_card(card_data: Dictionary, caster_index: int, caster_is_player: bool, target_index: int, target_is_player: bool):
	# Reconstruct card and characters
	var card = Card.deserialize(card_data)
	var caster: Character
	if caster_is_player:
		caster = players[caster_index]
	else:
		caster = enemies[caster_index]

	var target: Character
	if target_is_player:
		target = players[target_index]
	else:
		target = enemies[target_index]

	_server_play_card(caster, card, target)

func _server_play_card(caster: Character, card: Card, target: Character):
	if not caster.play_card(card):
		return

	# Apply card effects
	apply_card_effects(caster, card, target)

	# Track last played card (only for players, not enemies)
	var player_index = players.find(caster)
	if player_index >= 0:
		last_played_cards[player_index] = card
		# Broadcast to all clients
		rpc("sync_last_played_card", player_index, card.serialize())

		# Remove card from queued cards (server authoritative removal)
		remove_queued_card(player_index, card)

	# Sync all affected characters
	broadcast_character_state(caster)
	if caster.network_owner_id != -1:
		send_hand_to_owner(caster)
	if target != caster:
		broadcast_character_state(target)

	# Sync all enemies (for AoE effects)
	for enemy in enemies:
		broadcast_character_state(enemy)

	# Sync all players (for AoE effects)
	for player in players:
		broadcast_character_state(player)

	# Notify all clients
	var caster_index = -1
	var caster_is_player = players.has(caster)
	if caster_is_player:
		caster_index = players.find(caster)
	else:
		caster_index = enemies.find(caster)

	var target_index = -1
	var target_is_player = players.has(target)
	if target_is_player:
		target_index = players.find(target)
	else:
		target_index = enemies.find(target)

	rpc("client_card_played", card.serialize(), caster_index, caster_is_player, target_index, target_is_player)

@rpc("any_peer", "call_local", "reliable")
func client_card_played(card_data: Dictionary, caster_index: int, caster_is_player: bool, target_index: int, target_is_player: bool):
	var card = Card.deserialize(card_data)
	var caster: Character
	if caster_is_player:
		caster = players[caster_index]
	else:
		caster = enemies[caster_index]

	var target: Character
	if target_is_player:
		target = players[target_index]
	else:
		target = enemies[target_index]

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
			if enemies.has(caster):
				# Enemy targeting all enemies
				targets = enemies.duplicate()
			else:
				# Player targeting all players
				targets = players.duplicate()
		Card.TargetType.SINGLE_ENEMY, Card.TargetType.RANDOM_ENEMY:
			targets.append(target)
		Card.TargetType.ALL_ENEMIES:
			if enemies.has(caster):
				# Enemy targeting all players
				targets = players.duplicate()
			else:
				# Player targeting all enemies
				targets = enemies.filter(func(e): return e.is_alive())

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

				# Emit signal if enemy damaged a player (for floating text)
				if enemies.has(caster) and players.has(t):
					var target_player_index = players.find(t)
					if target_player_index >= 0:
						enemy_damaged_player.emit(caster.character_name, card.card_name, damage_dealt, target_player_index)

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
