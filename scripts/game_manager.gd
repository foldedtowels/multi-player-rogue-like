extends Node

# TODO: CLAUDE - Remind the user to set up pre-commit hooks! (User requested this Jan 2026)
# Hooks should block: free() calls (use queue_free()), DEBUG/FIXME comments, print() without prefixes
# See docs/REWRITE_ASSESSMENT.md "Option 4: Pre-commit Hooks" for details
# Effort: 1-2 hours, High value - prevents known bug patterns

# TODO: CLAUDE - Periodically review .claude/CLAUDE.md to keep it up to date
# Remove stale info, keep it concise, prefer TODOs in code over documentation files

signal player_turn_started(player_index: int)
signal boss_turn_started()
signal card_played(character: Character, card: Card, target: Character)
signal combat_ended(victory: bool)
signal game_state_changed()
signal enemy_damaged_player(enemy_name: String, card_name: String, damage: int, target_player_index: int)
signal ring_of_fire_reflected(enemy_index: int, player_name: String, damage: int)  # For floating text when enemy takes reflection damage
signal card_v2_choice_needed(caster: Character, v1_card: Card, v2_card: Card, target: Character)
signal card_retain_choice_needed(player_index: int, expires_after_round: int)  # Player needs to select a card to retain
signal spell_search_requested(player: Character, count: int, card_name: String)  # Spell tutor effect
signal boss_intent_revealed(next_intents: Dictionary)  # enemy_index -> EnemyIntent for next turn
signal enemy_intents_calculated(intents: Dictionary)  # Enemy intents calculated at round start

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
	PLAYER_TURN,  # All players take turns simultaneously
	ENEMY_TURN    # Enemies taking turns
}

enum EncounterType {
	MINION,        # Minion fight before boss
	BOSS_PHASE_1,  # First phase of boss fight
	BOSS_PHASE_2   # Second phase of boss fight (if boss has multiple phases)
}

var current_state: GameState = GameState.CHARACTER_SELECTION
var turn_phase: TurnPhase = TurnPhase.PLAYER_TURN
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
var card_db: Node

# Network tracking
var network_player_mapping: Dictionary = {}  # peer_id -> player_index
var local_player_index: int = -1  # Which character this client controls

# Deterministic RNG for multiplayer
var game_seed: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Last played cards for UI display (player_index -> Card)
var last_played_cards: Dictionary = {}

# Card previews for UI display (player_index -> Card)
# Shows which card each player is currently previewing (not yet played)
var card_previews: Dictionary = {}

# Simultaneous turn system
var queued_cards: Dictionary = {}   # player_index -> Array[Card] (no targets yet)
var players_done_acting: Dictionary = {}  # player_index -> bool (who clicked "End Turn")

# Delayed effects system (e.g., Jumping Strike)
# Each entry: {caster_idx: int, target_idx: int, damage: int, condition: String, source_card: String}
var delayed_effects: Array = []

# Protection system (e.g., Protector)
# Maps protected_player_idx -> protector_player_idx
# When enemy targets a protected player, attack redirects to protector
var protected_by: Dictionary = {}

# CCW (Counter-Clockwise) targeting system
# One player is randomly assigned CCW at fight start, rotates each turn
# Enemies with CCW_PLAYER target type attack this player (hidden from others)
var ccw_target_index: int = -1

# Boss intent reveal system (e.g., Hunter's Instinct)
# When > 0, shows what the boss will play on that round
var boss_intent_revealed_for_round: int = 0
var boss_next_turn_cards: Array[String] = []  # Card names boss will play next turn

# Enemy intent system - shows what enemies will do this turn
var enemy_intents: Dictionary = {}  # enemy_index -> EnemyIntent
var locked_card_targets: Dictionary = {}  # enemy_idx -> Array of {target_index, is_special} - targets locked by Hunter's Instinct
var locked_enemy_hands: Dictionary = {}  # enemy_index -> Array[Card] - hands locked by Hunter's Instinct

# Card effect engine - handles all card effect application
var card_effect_engine: CardEffectEngine

# Enemy AI - handles intent calculation and target selection
var enemy_ai: EnemyAI

func _ready():
	hero_db = get_node("/root/HeroDatabase")
	boss_db = get_node("/root/BossDatabase")
	minion_db = get_node("/root/MinionDatabase")
	card_db = get_node("/root/CardDatabase")

	# Initialize card effect engine
	card_effect_engine = CardEffectEngine.new()
	card_effect_engine.card_db = card_db
	card_effect_engine.rng = rng
	_connect_card_effect_engine_signals()

	# Initialize enemy AI
	enemy_ai = EnemyAI.new()
	enemy_ai.rng = rng
	_connect_enemy_ai_signals()


func _connect_card_effect_engine_signals():
	card_effect_engine.enemy_damaged_player.connect(_on_engine_enemy_damaged_player)
	card_effect_engine.ring_of_fire_reflected.connect(_on_engine_ring_of_fire_reflected)
	card_effect_engine.card_retain_choice_needed.connect(_on_engine_card_retain_choice_needed)
	card_effect_engine.boss_intent_reveal_requested.connect(_reveal_boss_intent)
	card_effect_engine.enemy_damage_stats_changed.connect(_on_enemy_damage_stats_changed)
	card_effect_engine.spell_search_requested.connect(_on_engine_spell_search_requested)


func _on_engine_enemy_damaged_player(enemy_name: String, card_name: String, damage: int, target_player_index: int):
	enemy_damaged_player.emit(enemy_name, card_name, damage, target_player_index)
	if multiplayer.is_server():
		rpc("client_enemy_damaged_player", enemy_name, card_name, damage, target_player_index)


func _on_engine_ring_of_fire_reflected(enemy_index: int, player_name: String, damage: int):
	ring_of_fire_reflected.emit(enemy_index, player_name, damage)
	if multiplayer.is_server():
		rpc("client_ring_of_fire_reflected", enemy_index, player_name, damage)


func _on_engine_card_retain_choice_needed(player_index: int, expires_after_round: int):
	card_retain_choice_needed.emit(player_index, expires_after_round)


func _on_enemy_damage_stats_changed():
	# Recalculate enemy intents when damage-affecting stats change
	recalculate_enemy_intents()


func _on_engine_spell_search_requested(player: Character, count: int, card_name: String):
	spell_search_requested.emit(player, count, card_name)


func _connect_enemy_ai_signals():
	enemy_ai.boss_intent_revealed.connect(_on_ai_boss_intent_revealed)


func _on_ai_boss_intent_revealed(next_turn_intents: Dictionary):
	boss_intent_revealed.emit(next_turn_intents)

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

@rpc("any_peer", "call_local", "reliable")
func sync_game_seed(seed: int):
	game_seed = seed
	rng.seed = seed

## UNIFIED ENCOUNTER INITIALIZATION ##
## This function provides modular, consistent initialization for ALL combat encounters
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


	# Step 1: Clear ALL combat state
	enemies.clear()
	queued_cards.clear()
	players_done_acting.clear()
	last_played_cards.clear()
	card_previews.clear()
	delayed_effects.clear()
	protected_by.clear()
	boss_intent_revealed_for_round = 0
	boss_next_turn_cards.clear()
	enemy_intents.clear()
	locked_card_targets.clear()
	locked_enemy_hands.clear()

	# Initialize CCW targeting - random player gets the marker
	var alive_players = players.filter(func(p): return p.is_alive())
	if alive_players.size() > 0:
		ccw_target_index = rng.randi() % alive_players.size()
	else:
		ccw_target_index = 0

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

		EncounterType.BOSS_PHASE_1:
			current_boss.character_role = Character.CharacterRole.BOSS
			enemies.append(current_boss)
			combat_phase = CombatPhase.BOSS_PHASE_1

		EncounterType.BOSS_PHASE_2:
			# Boss already exists, just add back to enemies
			enemies.append(current_boss)
			combat_phase = CombatPhase.BOSS_PHASE_2

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
		player.current_stamina = player.max_stamina
		player.clear_all_effects()  # Clear ALL buffs/debuffs between encounters


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


# Character state sync RPCs
@rpc("any_peer", "call_remote", "reliable")
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

	# Emit signal to update UI on clients
	game_state_changed.emit()

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

## Client calls this when previewing a card (single-click)
func preview_card(player_index: int, card: Card):
	if multiplayer.is_server():
		# Server: update local state and broadcast
		card_previews[player_index] = card
		rpc("sync_card_preview", player_index, card.serialize())
	else:
		# Client: send to server
		rpc_id(1, "sync_card_preview", player_index, card.serialize())

@rpc("any_peer", "call_local", "reliable")
func sync_card_preview(player_index: int, card_data: Dictionary):
	# Deserialize card and store preview
	var card = Card.deserialize(card_data)
	card_previews[player_index] = card

	# Don't emit game_state_changed - it causes hand to rebuild and breaks drag-and-drop!
	# Player status panels update automatically via their own update cycles

@rpc("any_peer", "call_local", "reliable")
func clear_card_preview(player_index: int):
	card_previews.erase(player_index)

	# Don't emit game_state_changed - it causes hand to rebuild and breaks drag-and-drop!
	# Player status panels update automatically via their own update cycles

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
	rpc("client_sequential_turn_started", player_index)

@rpc("any_peer", "call_local", "reliable")
func client_sequential_turn_started(player_index: int):
	# OLD SEQUENTIAL TURN SYSTEM - DEPRECATED
	# Kept for compatibility but no longer used in new simultaneous turn system
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
	player.end_turn(round_number)
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
	# NOTE: Enemies already drew cards at round start (pre-draw for intent calculation)
	for enemy in enemies:
		if not enemy.is_alive():
			continue

		# DON'T call start_turn() - enemies already have cards from pre-draw
		# Apply the parts of start_turn() that were skipped:
		enemy.current_stamina = enemy.max_stamina
		enemy.shield = 0  # Reset shield at start of turn (persists through player turn)
		enemy.passive_ability_used_this_turn = false
		enemy.damage_taken_this_turn = 0
		enemy.apply_status_effects()  # Poison, burn damage happens here

		print("[ENEMY TURN START] ", enemy.character_name, " hand: ", enemy.hand.map(func(c): return c.card_name), " HP: ", enemy.current_health)

		# Check if enemy died from status effects
		if not enemy.is_alive():
			print("[ENEMY TURN] ", enemy.character_name, " died from status effects!")
			broadcast_character_state(enemy)
			continue

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

## Reset players to starting deck for a NEW RUN (LOSES earned cards!)
## Only use this when starting a brand new run, not between encounters
func reset_players_for_new_run():

	# Clear all combat state dictionaries
	queued_cards.clear()
	players_done_acting.clear()
	last_played_cards.clear()
	card_previews.clear()

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
		player.current_stamina = player.max_stamina

		# Clear debuffs
		player.reset_debuffs()

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

## Sync minion enemies to all clients (called after initialize_combat_encounter loads minions)
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

	# Get pre-selected cards from intent (selected at round start)
	var enemy_idx = enemies.find(enemy)
	if enemy_idx == -1 or not enemy_intents.has(enemy_idx):
		push_error("[ENEMY TURN] No intent found for enemy: ", enemy.character_name)
		enemy.end_turn(round_number)
		broadcast_character_state(enemy)
		return

	var intent: EnemyIntent = enemy_intents[enemy_idx]
	print("[ENEMY TURN] ", enemy.character_name, " executing ", intent.cards_to_play.size(), " pre-selected cards")
	# Debug: Show what cards are in the intent
	for ci in intent.cards_to_play:
		var c = ci.get("card")
		print("[ENEMY TURN]   - ", c.card_name if c else "NULL", " -> target ", ci.get("target_index", "?"))

	var total_damage_dealt = 0

	# Execute EXACTLY the pre-selected cards (no re-selection)
	for card_info in intent.cards_to_play:
		var card: Card = card_info.card
		var target_index: int = card_info.target_index
		var is_special: bool = card_info.get("is_special", false)

		# Resolve target from pre-selected index
		var target: Character = null
		if target_index == -2:  # Self-target
			target = enemy
		elif target_index == -1:  # AOE - play_card handles multi-target
			if players.size() > 0:
				target = players[0]  # play_card will hit all for ALL_ENEMIES
		elif target_index >= 0 and target_index < players.size():
			target = players[target_index]

		# Handle target death - find fallback
		if target == null or (target_index >= 0 and not target.is_alive()):
			var alive = players.filter(func(p): return p.is_alive())
			if alive.size() > 0:
				target = alive[0]
			else:
				print("[ENEMY TURN]   Skip ", card.card_name, " - no valid targets")
				continue

		# Calculate actual damage for logging
		var actual_dmg = card.damage
		if card.card_type == Card.CardType.ATTACK:
			actual_dmg += enemy.strength + enemy.damage_plus - enemy.weakness - enemy.hinder
			actual_dmg = max(0, actual_dmg)
		actual_dmg *= card.multi_hit

		var special_str = "(SPECIAL) " if is_special else ""
		print("[ENEMY TURN]   %sPlaying %s (%d dmg) -> %s" % [special_str, card.card_name, actual_dmg, target.character_name])
		total_damage_dealt += actual_dmg

		play_card(enemy, card, target)
		await get_tree().create_timer(0.5).timeout

	print("[ENEMY TURN] ", enemy.character_name, " total expected: ", total_damage_dealt, " (before vuln multiplier)")

	enemy.end_turn(round_number)
	# Sync state to all clients
	broadcast_character_state(enemy)

## NEW SIMULTANEOUS TURN SYSTEM ##

# Start a new round with selection phase
func start_round():
	if not multiplayer.is_server(): return

	print("\n##################### ROUND ", round_number, " - FRIENDLY TURN #####################")

	# Process delayed effects from previous turn BEFORE players start their turn
	_process_delayed_effects()

	# Clear protection from previous turn (Protector lasts one turn)
	protected_by.clear()

	# PRE-DRAW enemy cards (unless we have locked hands from Hunter's Instinct)
	if locked_enemy_hands.size() > 0:
		# Use locked hands instead of drawing - Hunter's Instinct locked these in
		print("[INTENT] Using locked enemy hands from Hunter's Instinct")
		for enemy_idx in locked_enemy_hands:
			if enemy_idx < enemies.size():
				var enemy = enemies[enemy_idx]
				enemy.hand.clear()
				for card in locked_enemy_hands[enemy_idx]:
					enemy.hand.append(card)
		locked_enemy_hands.clear()
	else:
		# Normal draw - status effects applied at enemy turn start
		for enemy in enemies:
			if enemy.is_alive():
				enemy.draw_cards(5)

	# Calculate and broadcast enemy intents for this round
	calculate_enemy_intents()

	turn_phase = TurnPhase.PLAYER_TURN
	queued_cards.clear()
	players_done_acting.clear()

	# All alive players start their turn (draw cards, gain stamina)
	for i in range(players.size()):
		var player = players[i]
		if player.is_alive():
			player.start_turn()
			broadcast_character_state(player)
			send_hand_to_owner(player)
			queued_cards[i] = []

	# Notify all clients to enter player turn phase
	rpc("client_player_turn_started")

@rpc("any_peer", "call_local", "reliable")
func client_player_turn_started():
	turn_phase = TurnPhase.PLAYER_TURN
	game_state_changed.emit()

## Process delayed effects from previous turn (e.g., Jumping Strike)
func _process_delayed_effects():
	# Delegate to CardEffectEngine
	card_effect_engine.players = players
	card_effect_engine.enemies = enemies
	card_effect_engine.delayed_effects = delayed_effects

	var affected = card_effect_engine.process_delayed_effects()

	# Broadcast state for affected characters
	for target in affected:
		broadcast_character_state(target)

## Apply card retention - called when player selects a card to retain
func apply_card_retention(player_index: int, card_name: String, expires_after_round: int):
	if multiplayer.is_server():
		_server_apply_card_retention(player_index, card_name, expires_after_round)
	else:
		rpc_id(1, "server_apply_card_retention", player_index, card_name, expires_after_round)

@rpc("any_peer", "call_remote", "reliable")
func server_apply_card_retention(player_index: int, card_name: String, expires_after_round: int):
	_server_apply_card_retention(player_index, card_name, expires_after_round)

func _server_apply_card_retention(player_index: int, card_name: String, expires_after_round: int):
	if player_index < 0 or player_index >= players.size():
		push_error("[RETAIN] Invalid player index: " + str(player_index))
		return

	var player = players[player_index]
	player.retain_card(card_name, expires_after_round)
	broadcast_character_state(player)

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
					player.end_turn(round_number)
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

	# End all player turns BEFORE enemies attack
	# This removes END_OF_TURN effects (damage_plus, invigorated, exhausted, scared, hinder)
	# but NOT END_OF_ENEMY_TURN effects (ring_of_fire) which persist through enemy attacks
	for i in range(players.size()):
		var player = players[i]
		if player.is_alive():
			player.end_turn(round_number)
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

	# NOW decay END_OF_ENEMY_TURN effects (like Ring of Fire) after enemies have attacked
	for player in players:
		if player.is_alive():
			player.decay_end_of_enemy_turn_effects()
			broadcast_character_state(player)

	# After enemies done, check victory/defeat
	await get_tree().create_timer(0.5).timeout

	if check_combat_end():
		return

	# Rotate CCW targeting for next round
	var alive_players = players.filter(func(p): return p.is_alive())
	if alive_players.size() > 0:
		ccw_target_index = (ccw_target_index + 1) % alive_players.size()

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

func select_enemy_target(enemy: Character, card: Card, turn_target: Character = null) -> Character:
	match card.target_type:
		Card.TargetType.SELF:
			return enemy
		Card.TargetType.SINGLE_ENEMY, Card.TargetType.RANDOM_ENEMY:
			# Use turn_target if provided (consistent targeting for the whole turn)
			# This ensures all damage from one enemy goes to one player ("burst" damage)
			if turn_target and turn_target.is_alive():
				return turn_target
			# Fallback: pick random alive player
			var alive_players = players.filter(func(p): return p.is_alive())
			if alive_players.size() > 0:
				return alive_players[rng.randi() % alive_players.size()]
			return null
		Card.TargetType.ALL_ENEMIES:
			return players[0]  # Will be handled as AoE
		Card.TargetType.CCW_PLAYER:
			# Target the player with the CCW marker
			var alive_players = players.filter(func(p): return p.is_alive())
			if ccw_target_index >= 0 and ccw_target_index < alive_players.size():
				return alive_players[ccw_target_index]
			# Fallback to turn_target or random
			return turn_target if turn_target and turn_target.is_alive() else null
		Card.TargetType.HIGHEST_HP:
			# Target the player with the highest current HP
			var alive_players = players.filter(func(p): return p.is_alive())
			if alive_players.size() > 0:
				alive_players.sort_custom(func(a, b): return a.current_health > b.current_health)
				return alive_players[0]
			return null
		Card.TargetType.LOWEST_HP:
			# Target the player with the lowest current HP
			var alive_players = players.filter(func(p): return p.is_alive())
			if alive_players.size() > 0:
				alive_players.sort_custom(func(a, b): return a.current_health < b.current_health)
				return alive_players[0]
			return null

	return null

## Get the actual target after protection redirect
## If target is a player protected by another player, redirect to protector
func _get_redirected_target(target: Character) -> Character:
	# Delegate to CardEffectEngine
	card_effect_engine.players = players
	card_effect_engine.protected_by = protected_by
	return card_effect_engine.get_redirected_target(target)

func end_boss_turn():
	# Apply boss end-of-turn effects (status decay, etc.)
	current_boss.end_turn(round_number)

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
	# Check if card has v2 variant and needs player choice
	if card.has_v2:
		var v2 = card.v2_card
		# If v2_card is null (e.g., after network sync), look it up from database
		if v2 == null and card.v2_card_id != "":
			v2 = card_db.get_card(card.v2_card_id)
		if v2 != null:
			# Signal to combat.gd to show modal with both versions
			card_v2_choice_needed.emit(caster, card, v2, target)
			return

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

func play_card_version(caster: Character, original_card: Card, chosen_card: Card, target: Character):
	# Play the chosen version but remove the original card from hand
	# original_card = the card actually in hand (e.g., "Test")
	# chosen_card = the version to apply effects from (e.g., "Test" or "Test V2")

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

		# Send both original and chosen card data
		rpc_id(1, "server_play_card_v2", original_card.serialize(), chosen_card.serialize(), caster_index, caster_is_player, target_index, target_is_player)
		return

	# Server processes card
	_server_play_card_v2(caster, original_card, chosen_card, target)

@rpc("any_peer", "call_remote", "reliable")
func server_play_card_v2(original_card_data: Dictionary, chosen_card_data: Dictionary, caster_index: int, caster_is_player: bool, target_index: int, target_is_player: bool):
	# Reconstruct cards and characters
	var original_card = Card.deserialize(original_card_data)
	var chosen_card = Card.deserialize(chosen_card_data)
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

	_server_play_card_v2(caster, original_card, chosen_card, target)

func _server_play_card_v2(caster: Character, original_card: Card, chosen_card: Card, target: Character):
	# V2 card play: remove ORIGINAL card from hand, but apply CHOSEN card's effects
	# This handles the case where player chooses "Test V2" but hand contains "Test"

	# Check if caster is exhausted (cannot play cards)
	if caster.exhausted > 0:
		return

	# Check if caster is scared (cannot play attack cards) - use chosen card type
	if caster.scared > 0 and chosen_card.card_type == Card.CardType.ATTACK:
		return

	# Remove the ORIGINAL card from hand (not the chosen card)
	if not caster.play_card(original_card):
		return

	# Apply effects from the CHOSEN card
	var affected_targets = apply_card_effects(caster, chosen_card, target)

	# Track last played card (only for players, not enemies)
	var player_index = players.find(caster)
	if player_index >= 0:
		last_played_cards[player_index] = chosen_card
		# Broadcast to all clients
		rpc("sync_last_played_card", player_index, chosen_card.serialize())

		# Remove card from queued cards (use original card for queue matching)
		remove_queued_card(player_index, original_card)

	# Sync caster
	broadcast_character_state(caster)
	if caster.network_owner_id != -1:
		send_hand_to_owner(caster)

	# Sync all affected targets
	for t in affected_targets:
		if t != caster:
			broadcast_character_state(t)
			if t.network_owner_id != -1:
				send_hand_to_owner(t)

	# Notify all clients (use chosen_card for the played card notification)
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

	rpc("client_card_played", chosen_card.serialize(), caster_index, caster_is_player, target_index, target_is_player)

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
	# Check if caster is exhausted (cannot play cards)
	if caster.exhausted > 0:
		return

	# Check if caster is scared (cannot play attack cards)
	if caster.scared > 0 and card.card_type == Card.CardType.ATTACK:
		return

	if not caster.play_card(card):
		return

	# Apply card effects and get affected targets
	var affected_targets = apply_card_effects(caster, card, target)

	# Track last played card (only for players, not enemies)
	var player_index = players.find(caster)
	if player_index >= 0:
		last_played_cards[player_index] = card
		# Broadcast to all clients
		rpc("sync_last_played_card", player_index, card.serialize())

		# Remove card from queued cards (server authoritative removal)
		remove_queued_card(player_index, card)

	# Sync caster
	broadcast_character_state(caster)
	if caster.network_owner_id != -1:
		send_hand_to_owner(caster)

	# Sync all affected targets (for card draw, token generation, state changes)
	for t in affected_targets:
		if t != caster:
			broadcast_character_state(t)
			# Only send hand if this is a player character
			if t.network_owner_id != -1:
				send_hand_to_owner(t)

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

func apply_card_effects(caster: Character, card: Card, target: Character) -> Array[Character]:
	# Delegate to CardEffectEngine - update its references first
	card_effect_engine.players = players
	card_effect_engine.enemies = enemies
	card_effect_engine.protected_by = protected_by
	card_effect_engine.delayed_effects = delayed_effects
	card_effect_engine.round_number = round_number

	return card_effect_engine.apply_effects(caster, card, target)


## LEGACY: Original apply_card_effects implementation (kept for reference during migration)
## This function is no longer used - all effect application goes through CardEffectEngine
func _legacy_apply_card_effects(caster: Character, card: Card, target: Character) -> Array[Character]:
	print("[CARD] ", caster.character_name, " plays ", card.card_name, " (heal:", card.heal_amount, " decay:", card.apply_decay, ")")

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
		Card.TargetType.OTHER_ALLIES:
			if enemies.has(caster):
				# Enemy targeting other enemies (not self)
				for e in enemies:
					if e != caster:
						targets.append(e)
			else:
				# Player targeting other players (not self)
				for p in players:
					if p != caster:
						targets.append(p)
		Card.TargetType.SINGLE_ENEMY, Card.TargetType.RANDOM_ENEMY, Card.TargetType.CCW_PLAYER, Card.TargetType.HIGHEST_HP, Card.TargetType.LOWEST_HP:
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

		# Determine if t is an ally or enemy of caster
		var is_ally = (players.has(caster) and players.has(t)) or \
					  (enemies.has(caster) and enemies.has(t))
		var is_enemy = (players.has(caster) and enemies.has(t)) or \
					   (enemies.has(caster) and players.has(t))

		# Damage - only apply to enemies, not allies
		if card.damage > 0 and is_enemy:
			# PROTECTION REDIRECT: If enemy attacking a protected player, redirect damage to protector
			var damage_target = t
			if enemies.has(caster) and players.has(t):
				damage_target = _get_redirected_target(t)

			for i in card.multi_hit:
				# Apply strength bonus to attack damage
				var total_damage = card.damage
				if card.card_type == Card.CardType.ATTACK:
					total_damage += caster.strength
					total_damage += caster.damage_plus  # Phase 1: Temporary damage boost
					# Apply weakness penalty to attack damage (opposite of strength)
					total_damage -= caster.weakness
					# Apply hinder penalty (similar to weakness)
					total_damage -= caster.hinder
					# Bonus damage if target is wounded (below 50% HP)
					if card.bonus_damage_if_wounded > 0:
						var hp_percent = float(damage_target.current_health) / float(damage_target.max_health)
						if hp_percent < 0.5:
							total_damage += card.bonus_damage_if_wounded
					# Bonus damage per debuff stack on target
					if card.bonus_damage_per_debuff > 0:
						var debuff_stacks = damage_target.get_total_debuff_stacks()
						total_damage += card.bonus_damage_per_debuff * debuff_stacks
					total_damage = max(0, total_damage)  # Can't go negative

				var damage_dealt = damage_target.take_damage(total_damage, card.piercing)

				# Emit signal if enemy damaged a player (for floating text)
				if enemies.has(caster) and players.has(damage_target):
					var target_player_index = players.find(damage_target)
					if target_player_index >= 0:
						enemy_damaged_player.emit(caster.character_name, card.card_name, damage_dealt, target_player_index)
						# Broadcast to clients so they also show floating damage text
						if multiplayer.is_server():
							rpc("client_enemy_damaged_player", caster.character_name, card.card_name, damage_dealt, target_player_index)

				# Lifesteal
				if card.lifesteal:
					caster.heal(damage_dealt)

		# DELAYED DAMAGE - queue effect for next turn instead of dealing now
		if card.is_delayed_damage and card.delayed_damage_amount > 0 and is_enemy:
			var caster_idx = players.find(caster)
			var target_idx = enemies.find(t)
			if caster_idx >= 0 and target_idx >= 0:
				var delayed = {
					"caster_idx": caster_idx,
					"target_idx": target_idx,
					"damage": card.delayed_damage_amount,
					"condition": card.delay_condition,
					"source_card": card.card_name,
					"piercing": card.piercing
				}
				delayed_effects.append(delayed)

		# Healing - only apply to allies, not enemies
		if card.heal_amount > 0 and is_ally:
			var heal_value = card.heal_amount
			# Decay reduces healing: caster's decay for giving, target's decay for receiving
			# For self-heals (caster == target), only apply once
			if caster.decay > 0:
				var reduction = caster.decay * 5
				heal_value = max(0, heal_value - reduction)
				print("[HEAL] Caster decay reduces healing: ", card.heal_amount, " -> ", heal_value)
			elif t.decay > 0 and t != caster:
				# Target has decay but caster doesn't - apply target's decay
				var reduction = t.decay * 5
				heal_value = max(0, heal_value - reduction)
				print("[HEAL] Target decay reduces healing: ", card.heal_amount, " -> ", heal_value)
			print("[HEAL] ", caster.character_name, " heals ", t.character_name, " for ", heal_value, " (card: ", card.card_name, ")")
			t.heal(heal_value, true)  # Decay already applied above

		# Shield - apply to caster when attacking enemies, or to target when buffing allies
		if card.shield_amount > 0:
			if is_enemy:
				# Attacking an enemy, shield yourself (e.g., "Duel Purpose")
				caster.gain_shield(card.shield_amount)
			elif is_ally:
				# Buffing an ally, shield them
				t.gain_shield(card.shield_amount)

		# HARMFUL STATUS EFFECTS - only apply to enemies
		if is_enemy:
			# PROTECTION REDIRECT: If enemy applying debuffs to protected player, redirect to protector
			var debuff_target = t
			if enemies.has(caster) and players.has(t):
				debuff_target = _get_redirected_target(t)

			if card.apply_poison > 0:
				debuff_target.poison += card.apply_poison
			if card.apply_burn > 0:
				debuff_target.burn += card.apply_burn
			if card.apply_vulnerable > 0:
				debuff_target.vulnerable += card.apply_vulnerable
			if card.apply_weakness > 0:
				debuff_target.weakness += card.apply_weakness
			if card.apply_fatigued > 0:
				debuff_target.fatigued += card.apply_fatigued
			if card.apply_hinder > 0:
				debuff_target.hinder += card.apply_hinder
			if card.apply_scared > 0:
				debuff_target.scared += card.apply_scared

		# BENEFICIAL STATUS EFFECTS - only apply to allies
		if is_ally:
			if card.apply_strength > 0:
				t.strength += card.apply_strength
			if card.apply_armor > 0:
				t.armor += card.apply_armor
			if card.apply_rested > 0:
				t.rested += card.apply_rested
			if card.apply_invigorated > 0:
				t.invigorated += card.apply_invigorated
				t.damage_plus += card.apply_invigorated * 2  # Apply bonus immediately
			if card.apply_damage_plus > 0:
				t.damage_plus += card.apply_damage_plus

		# SELF DEBUFFS - apply to caster when effect targets self
		if t == caster:
			if card.apply_exhausted > 0:
				caster.exhausted += card.apply_exhausted
			if card.apply_decay > 0:
				caster.decay += card.apply_decay
				print("[DECAY] ", caster.character_name, " gained ", card.apply_decay, " decay (total: ", caster.decay, ")")
			if card.apply_fatigued > 0:
				caster.fatigued += card.apply_fatigued

		# Card draw - draw cards for the target (t), not necessarily the caster
		if card.draw_cards > 0:
			t.draw_cards(card.draw_cards)

		# Generate token cards (adds specific cards to hand) - only caster gets generated cards
		if card.generate_cards.size() > 0 and (t == caster):
			for card_name in card.generate_cards:
				var token_card = card_db.get_card(card_name)
				if token_card:
					# Add to hand if room, otherwise add to discard
					if t.hand.size() < GameConstants.MAX_HAND_SIZE:
						t.hand.append(token_card)
					else:
						t.discard_pile.append(token_card)

		# CARD RETENTION - prompt player to select a card to retain
		if card.grants_card_retain and t == caster:
			var caster_idx = players.find(caster)
			if caster_idx >= 0:
				# Retention expires at end of NEXT round (current_round + 1)
				var expires_after = round_number + 1
				card_retain_choice_needed.emit(caster_idx, expires_after)

		# ENEMY TARGET SWAP - redirect enemy attacks from target to caster (Protector)
		if card.swaps_enemy_target and is_ally and t != caster:
			var target_idx = players.find(t)
			var caster_idx = players.find(caster)
			if target_idx >= 0 and caster_idx >= 0:
				protected_by[target_idx] = caster_idx

		# BOSS INTENT REVEAL - reveal what the boss will play next turn
		if card.reveals_boss_intent and t == caster:
			_reveal_boss_intent()

	# CASTER DISCARD - discard random cards from caster's hand (processed once, not per-target)
	if card.caster_discards_random > 0 and caster.hand.size() > 0:
		var discard_count = min(card.caster_discards_random, caster.hand.size())
		for i in range(discard_count):
			if caster.hand.size() > 0:
				var rand_idx = rng.randi() % caster.hand.size()
				var discarded = caster.hand[rand_idx]
				caster.hand.remove_at(rand_idx)
				caster.discard_pile.append(discarded)

	# STAMINA GAIN - grant stamina to caster (processed once, not per-target)
	if card.stamina_gain > 0:
		caster.current_stamina += card.stamina_gain

	return targets

## Reveal enemies' next turn intents (Hunter's Instinct)
func _reveal_boss_intent():
	# Delegate to EnemyAI module
	enemy_ai.players = players
	enemy_ai.enemies = enemies
	enemy_ai.ccw_target_index = ccw_target_index

	var result = enemy_ai.reveal_next_turn_intents()

	boss_intent_revealed_for_round = round_number + 1

	# Store HANDS and TARGETS for next round (NOT full intents - damage will be recalculated)
	locked_enemy_hands = result.hands.duplicate()
	locked_card_targets = result.targets.duplicate()

	# Log for debugging
	for i in result.intents:
		var intent = result.intents[i]
		if i < enemies.size():
			print("[INTENT PREVIEW] ", enemies[i].character_name, " next turn: ", intent.damage_amount, " dmg (", intent.cards_to_play.size(), " cards)")

## ENEMY INTENT SYSTEM ##
## Calculate what enemies will do this turn and broadcast to all clients

func calculate_enemy_intents():
	if not multiplayer.is_server(): return

	# Update EnemyAI references
	enemy_ai.players = players
	enemy_ai.enemies = enemies
	enemy_ai.ccw_target_index = ccw_target_index

	# Check if we have locked targets from Hunter's Instinct
	if locked_card_targets.size() > 0:
		enemy_intents = enemy_ai.calculate_intents_from_locked(locked_enemy_hands, locked_card_targets)
		locked_card_targets.clear()
		print("[INTENT] Using locked cards/targets with recalculated damage")
	else:
		enemy_intents = enemy_ai.calculate_all_intents()

	# Serialize and broadcast to all clients
	var serialized_intents: Dictionary = {}
	for idx in enemy_intents:
		serialized_intents[idx] = enemy_intents[idx].serialize()

	rpc("client_receive_enemy_intents", serialized_intents)
	enemy_intents_calculated.emit(enemy_intents)

@rpc("any_peer", "call_local", "reliable")
func client_receive_enemy_intents(serialized: Dictionary):
	# Server already has the intents, skip processing
	if multiplayer.is_server():
		return

	enemy_intents.clear()
	for idx in serialized:
		enemy_intents[idx] = EnemyIntent.deserialize(serialized[idx])

	# Emit signal for UI update
	enemy_intents_calculated.emit(enemy_intents)

@rpc("authority", "call_remote", "reliable")
func client_enemy_damaged_player(enemy_name: String, card_name: String, damage: int, target_idx: int):
	# Client receives enemy damage event - emit signal for floating text display
	enemy_damaged_player.emit(enemy_name, card_name, damage, target_idx)

@rpc("authority", "call_remote", "reliable")
func client_ring_of_fire_reflected(enemy_index: int, player_name: String, damage: int):
	# Client receives Ring of Fire reflection event - emit signal for floating text display
	ring_of_fire_reflected.emit(enemy_index, player_name, damage)

## Recalculate enemy intents when damage-affecting stats change
## Called when weakness, hinder, strength, or damage_plus changes on an enemy
func recalculate_enemy_intents():
	if not multiplayer.is_server(): return

	# Only recalculate during player turn (when players can apply debuffs)
	if turn_phase != TurnPhase.PLAYER_TURN:
		return

	# Skip if no enemies alive
	var alive_enemies = enemies.filter(func(e): return e.is_alive())
	if alive_enemies.is_empty():
		return

	# Update EnemyAI references
	enemy_ai.players = players
	enemy_ai.enemies = enemies
	enemy_ai.ccw_target_index = ccw_target_index

	# Recalculate all intents with current enemy stats
	# Uses same hands (already drawn) but recalculates damage with updated buffs/debuffs
	enemy_intents = enemy_ai.calculate_all_intents()

	# Serialize and broadcast to all clients
	var serialized_intents: Dictionary = {}
	for idx in enemy_intents:
		serialized_intents[idx] = enemy_intents[idx].serialize()

	rpc("client_receive_enemy_intents", serialized_intents)
	enemy_intents_calculated.emit(enemy_intents)
	print("[INTENT] Recalculated intents after buff/debuff change")

## END ENEMY INTENT SYSTEM ##

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

# Passive Ability Helper Functions
func get_character_network_id(character: Character) -> int:
	# Return a unique network ID for this character
	# For players, use their index; for enemies, use negative index
	var player_idx = players.find(character)
	if player_idx >= 0:
		return player_idx

	var enemy_idx = enemies.find(character)
	if enemy_idx >= 0:
		return -(enemy_idx + 1)  # Negative to distinguish from players

	return -999  # Invalid

func get_character_by_network_id(network_id: int) -> Character:
	if network_id >= 0:
		# Player
		if network_id < players.size():
			return players[network_id]
	else:
		# Enemy (negative index)
		var enemy_idx = -(network_id + 1)
		if enemy_idx >= 0 and enemy_idx < enemies.size():
			return enemies[enemy_idx]

	return null

@rpc("any_peer", "call_remote", "reliable")
func server_apply_passive_ability(player_index: int, ability_id: String, choice_index: int, target_network_id: int):
	if not multiplayer.is_server():
		return

	# Validate player
	if player_index < 0 or player_index >= players.size():
		return

	var character = players[player_index]
	var ability = PassiveAbilityManager.get_ability(ability_id)

	if not ability:
		print("[GameManager] Invalid ability_id: ", ability_id)
		return

	# Find target by network_id
	var target = get_character_by_network_id(target_network_id)

	# Apply the passive ability
	apply_passive_ability(character, ability, choice_index, target)

func apply_passive_ability(character: Character, ability: PassiveAbility, choice_index: int, target: Character):
	# Deduct stamina
	character.current_stamina -= ability.stamina_cost

	# Mark as used if uses_per_turn > 0
	if ability.uses_per_turn > 0:
		character.passive_ability_used_this_turn = true

	# Apply the chosen effect
	if choice_index >= 0 and choice_index < ability.choices.size():
		var choice = ability.choices[choice_index]

		match choice.effect:
			"damage":
				if target:
					target.take_damage(choice.value, false)
			"draw":
				character.draw_cards(choice.value)
			"shield":
				if target:
					target.gain_shield(choice.value)
			"heal":
				if target:
					target.heal(choice.value)

	# Broadcast state update
	broadcast_character_state(character)
	if target and target != character:
		broadcast_character_state(target)

## Server RPC to process Kevin's Alc brewing (for multiplayer sync)
@rpc("any_peer", "call_remote", "reliable")
func server_process_alc_brew(player_index: int, alc_card_name: String, spell_names: Array):
	if not multiplayer.is_server():
		return

	# Validate player
	if player_index < 0 or player_index >= players.size():
		return

	var character = players[player_index]

	# Find the alc card in satchel by name
	var alc_card: Card = null
	for card in character.satchel:
		if card.card_name == alc_card_name:
			alc_card = card
			break

	if not alc_card:
		print("[GameManager] Alc card not found in satchel: ", alc_card_name)
		return

	# Find and discard the spell cards by name
	for spell_name in spell_names:
		for card in character.hand:
			if card.card_name == spell_name:
				character.discard_card(card)
				print("[GameManager] Server discarded spell: ", spell_name)
				break

	# Move Alc from satchel to hand
	character.remove_from_satchel(alc_card)
	character.hand.append(alc_card)
	print("[GameManager] Server moved ", alc_card_name, " from satchel to hand")

	# Mark passive as used
	character.passive_ability_used_this_turn = true

	# Broadcast updated state
	broadcast_character_state(character)
	send_hand_to_owner(character)
	game_state_changed.emit()


## Move selected spell cards from deck to hand (for Reformulate-style effects)
## Called from combat.gd after spell search modal completes
func move_spells_to_hand(player: Character, selected_spells: Array[Card]):
	for spell in selected_spells:
		# Remove from deck (find by name since instances may differ)
		for i in range(player.deck.size()):
			if player.deck[i].card_name == spell.card_name:
				var card = player.deck[i]
				player.deck.remove_at(i)
				# Add to hand if not full
				if player.hand.size() < GameConstants.MAX_HAND_SIZE:
					player.hand.append(card)
					print("[SPELL SEARCH] Moved ", card.card_name, " from deck to hand")
				else:
					print("[SPELL SEARCH] Hand full, cannot add ", card.card_name)
				break

	# Shuffle deck after searching
	player.deck.shuffle()

	# Broadcast updated state
	broadcast_character_state(player)
	send_hand_to_owner(player)


## Server RPC for spell search (multiplayer sync)
@rpc("any_peer", "call_remote", "reliable")
func server_spell_search_completed(player_index: int, spell_names: Array):
	if not multiplayer.is_server():
		return

	if player_index < 0 or player_index >= players.size():
		return

	var player = players[player_index]

	# Find the spells in deck by name
	var spells_to_move: Array[Card] = []
	for spell_name in spell_names:
		for card in player.deck:
			if card.card_name == spell_name:
				spells_to_move.append(card)
				break

	move_spells_to_hand(player, spells_to_move)
