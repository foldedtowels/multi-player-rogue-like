extends Control

## Reward scene - displays after defeating a boss
## Uses modular RewardManager for privacy-aware reward selection

var game_manager: Node
var card_db: Node
var wizard: Node2D
var reward_manager: RewardManager

# Reward state
var reward_phase: int = 0  ## 0 = rare card phase, 1 = common card/heal phase
var chosen_player_index: int = 0

# UI Elements
@onready var wizard_container: Control = $WizardContainer
@onready var continue_button: Button = $ContinueButton
var rare_panel: RewardDisplayPanel
var common_panel: RewardDisplayPanel
var skip_button: Button

func _ready():
	game_manager = get_node("/root/GameManager")
	card_db = get_node("/root/CardDatabase")

	# Create reward panels programmatically
	rare_panel = RewardDisplayPanel.new()
	rare_panel.set_anchors_preset(Control.PRESET_CENTER)
	rare_panel.offset_left = -400
	rare_panel.offset_top = -150
	rare_panel.offset_right = 400
	rare_panel.offset_bottom = 150
	rare_panel.custom_minimum_size = Vector2(800, 300)
	add_child(rare_panel)

	common_panel = RewardDisplayPanel.new()
	common_panel.set_anchors_preset(Control.PRESET_CENTER)
	common_panel.offset_left = -400
	common_panel.offset_top = -150
	common_panel.offset_right = 400
	common_panel.offset_bottom = 150
	common_panel.custom_minimum_size = Vector2(800, 300)
	add_child(common_panel)

	# Create skip button
	skip_button = Button.new()
	skip_button.text = "Skip (Auto-select first choice)"
	skip_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	skip_button.position = Vector2(-150, -80)
	skip_button.custom_minimum_size = Vector2(300, 50)
	skip_button.visible = false
	skip_button.pressed.connect(_on_skip_pressed)
	add_child(skip_button)

	# Create wizard visual
	wizard = Node2D.new()
	wizard.set_script(load("res://scripts/wizard_visual.gd"))
	wizard.position = Vector2(400, 400)
	wizard_container.add_child(wizard)

	# Create reward manager
	reward_manager = RewardManager.new()
	add_child(reward_manager)

	# Connect signals
	continue_button.pressed.connect(_on_continue_pressed)
	reward_manager.spectator_reward_complete.connect(_on_rare_reward_complete)
	reward_manager.all_players_ready.connect(_on_all_common_rewards_complete)
	reward_manager.spectator_choice_made.connect(_on_spectator_choice_made)
	reward_manager.private_choice_made.connect(_on_private_choice_made)

	# Setup UI
	continue_button.visible = false
	rare_panel.visible = false
	common_panel.visible = false

	# Start reward sequence
	await get_tree().create_timer(GameConstants.WIZARD_INTRO_DELAY).timeout
	start_rare_reward()

func start_rare_reward():
	reward_phase = 0

	# CRITICAL: Server picks the chosen player and broadcasts to all clients
	if multiplayer.is_server():
		chosen_player_index = randi() % 3
		print("[WIZARD] Server chose player ", chosen_player_index, " for rare reward")
		rpc("sync_chosen_player", chosen_player_index)
	else:
		# Clients wait for server to tell them who was chosen
		print("[WIZARD] Client waiting for server to choose player...")
		return  # Will be called again via RPC

@rpc("any_peer", "call_local", "reliable")
func sync_chosen_player(player_idx: int):
	chosen_player_index = player_idx
	print("[WIZARD] Received chosen player: ", chosen_player_index)
	_show_rare_reward()

func _show_rare_reward():
	var chosen_player = game_manager.players[chosen_player_index]

	wizard.say("Greetings, brave heroes! You have bested the beast!\n\n%s, step forward. I have powerful magic for you..." % chosen_player.character_name)

	await get_tree().create_timer(GameConstants.WIZARD_RARE_CARD_DELAY).timeout

	# Generate rare card choices
	var rare_choices = _generate_rare_choices()

	var my_index = game_manager.local_player_index
	var is_chosen = (my_index == chosen_player_index)
	print("[WIZARD] Showing rare reward - my_index: ", my_index, " chosen: ", chosen_player_index, " am I chosen: ", is_chosen)

	# Show spectator mode reward (all players watch, only chosen one can select)
	reward_manager.show_spectator_reward(chosen_player_index, rare_choices, rare_panel)

	# Show skip button for chosen player
	if is_chosen:
		skip_button.visible = true

func _generate_rare_choices() -> Array[RewardChoice]:
	var rare_pool = card_db.get_rare_cards()
	rare_pool.shuffle()

	var choices: Array[RewardChoice] = []
	for i in range(GameConstants.REWARD_RARE_CARD_CHOICES):
		var choice = RewardChoice.new()
		choice.choice_type = RewardChoice.ChoiceType.CARD
		choice.card_data = rare_pool[i]
		choice.display_name = rare_pool[i].card_name
		choice.description = rare_pool[i].description
		choices.append(choice)

	return choices

func _on_rare_reward_complete():
	print("[WIZARD] _on_rare_reward_complete called - hiding rare panel and moving to common rewards")
	wizard.say("Excellent choice! The power is now yours!")

	# Hide rare panel and skip button
	rare_panel.visible = false
	skip_button.visible = false

	await get_tree().create_timer(2.0).timeout
	start_common_reward()

func start_common_reward():
	print("[WIZARD] start_common_reward called - showing common/heal choices")
	reward_phase = 1
	wizard.say("Now, all of you may choose:\nRestore half your health, OR take a useful card!\n\nChoose wisely!")

	await get_tree().create_timer(GameConstants.WIZARD_COMMON_CHOICE_DELAY).timeout

	# Generate choices for each player (private mode)
	var choices_per_player = _generate_common_choices()

	# Show private mode rewards (each player sees only their own)
	reward_manager.show_private_rewards(choices_per_player, common_panel)

	# Show skip button for all players
	skip_button.visible = true

func _generate_common_choices() -> Dictionary:
	var choices = {}

	for player_idx in range(3):
		var player = game_manager.players[player_idx]
		var player_choices: Array[RewardChoice] = []

		# Option 1: Heal
		var heal_choice = RewardChoice.new()
		heal_choice.choice_type = RewardChoice.ChoiceType.HEAL
		heal_choice.heal_amount = int(player.max_health * GameConstants.REWARD_HEAL_PERCENTAGE)
		heal_choice.display_name = "Heal"
		heal_choice.description = "Restore %d HP" % heal_choice.heal_amount
		player_choices.append(heal_choice)

		# Options 2-4: Random common cards
		var common_pool = card_db.get_common_cards()
		common_pool.shuffle()

		for i in range(GameConstants.REWARD_COMMON_CARD_CHOICES):
			var card_choice = RewardChoice.new()
			card_choice.choice_type = RewardChoice.ChoiceType.CARD
			card_choice.card_data = common_pool[i]
			card_choice.display_name = common_pool[i].card_name
			card_choice.description = common_pool[i].description
			player_choices.append(card_choice)

		choices[player_idx] = player_choices

	return choices

func _on_all_common_rewards_complete():
	print("[WIZARD] All common rewards complete - showing continue button")
	wizard.say("Your choices are made! Steel yourselves...\nThe next challenge awaits!")

	# Common panel should already be hidden for each player
	# Just show the continue button (only for host)
	await get_tree().create_timer(2.0).timeout
	if multiplayer.is_server():
		continue_button.visible = true
	else:
		# Non-hosts see a waiting message
		continue_button.text = "Waiting for host to continue..."
		continue_button.disabled = true
		continue_button.visible = true

## Handle spectator choice made - send to server or apply directly
func _on_spectator_choice_made(player_index: int, choice: RewardChoice):
	print("[WIZARD] Spectator choice made by player ", player_index, " - handling RPC from reward.gd")

	# Send choice to server for processing
	if multiplayer.is_server():
		print("[WIZARD] Server applying choice directly")
		_apply_and_broadcast_choice(player_index, choice)
	else:
		print("[WIZARD] Client sending choice to server via reward.gd RPC")
		rpc_id(1, "server_receive_spectator_choice", player_index, choice.serialize())

## Server receives spectator choice from client
@rpc("any_peer", "call_remote", "reliable")
func server_receive_spectator_choice(player_index: int, choice_data: Dictionary):
	print("[WIZARD] Server received spectator choice RPC from player ", player_index)
	var choice = RewardChoice.deserialize(choice_data)
	_apply_and_broadcast_choice(player_index, choice)

## Apply choice and broadcast completion to all clients
func _apply_and_broadcast_choice(player_index: int, choice: RewardChoice):
	print("[WIZARD] Applying choice and broadcasting to all clients")

	# Apply the choice
	reward_manager.apply_spectator_choice(player_index, choice)

	# Broadcast completion to all clients (including self)
	print("[WIZARD] Broadcasting spectator choice complete via RPC")
	rpc("client_notify_spectator_complete")

@rpc("any_peer", "call_local", "reliable")
func client_notify_spectator_complete():
	print("[WIZARD] RPC received in reward.gd - calling reward_manager.notify_spectator_complete()")
	reward_manager.notify_spectator_complete()

## Handle private choice made - send to server or apply directly
func _on_private_choice_made(player_index: int, choice: RewardChoice):
	print("[WIZARD] Private choice made by player ", player_index, " - handling RPC from reward.gd")

	# Hide the common panel and skip button for THIS player immediately
	common_panel.visible = false
	skip_button.visible = false
	print("[WIZARD] Hiding common panel for player ", player_index)

	# Send choice to server for processing
	if multiplayer.is_server():
		print("[WIZARD] Server applying private choice directly")
		_apply_and_check_private_choice(player_index, choice)
	else:
		print("[WIZARD] Client sending private choice to server via reward.gd RPC")
		rpc_id(1, "server_receive_private_choice", player_index, choice.serialize())

## Server receives private choice from client
@rpc("any_peer", "call_remote", "reliable")
func server_receive_private_choice(player_index: int, choice_data: Dictionary):
	print("[WIZARD] Server received private choice RPC from player ", player_index)
	var choice = RewardChoice.deserialize(choice_data)
	_apply_and_check_private_choice(player_index, choice)

## Apply private choice and check if all players are ready
func _apply_and_check_private_choice(player_index: int, choice: RewardChoice):
	print("[WIZARD] Applying private choice for player ", player_index)

	# Apply the choice
	reward_manager.apply_private_choice(player_index, choice)

	# Broadcast updated ready status to all clients
	var ready_indices = Array(reward_manager._players_ready.keys())
	print("[WIZARD] Broadcasting ready status: ", ready_indices)
	rpc("client_update_ready_status", ready_indices)

	# Check if all players are ready (server only)
	if reward_manager.check_all_players_ready():
		print("[WIZARD] All players ready - broadcasting completion")
		rpc("client_all_players_ready")

## RPC to update ready status on all clients
@rpc("any_peer", "call_local", "reliable")
func client_update_ready_status(ready_indices: Array):
	print("[WIZARD] Received ready status update: ", ready_indices)
	reward_manager.update_ready_status(ready_indices)

## RPC to notify all clients that everyone is ready
@rpc("any_peer", "call_local", "reliable")
func client_all_players_ready():
	print("[WIZARD] Received all players ready notification")
	reward_manager.notify_all_players_ready()

func _on_continue_pressed():
	# ONLY server should handle this button - clients wait for RPC
	if not multiplayer.is_server():
		print("[REWARD] ERROR: Non-host clicked continue button!")
		return

	var boss_idx = game_manager.boss_index

	# Initialize next combat encounter (RPC runs on all clients)
	if boss_idx < 5:  # Still have bosses to fight (0-4)
		game_manager.initialize_combat_encounter.rpc(GameManager.EncounterType.MINION, boss_idx)
	else:
		# All 5 bosses defeated - victory!
		print("[REWARD] All bosses defeated! Victory!")
		# TODO: Transition to victory screen instead of combat
		return

	# Wait for initialization RPC to complete on all clients
	await get_tree().create_timer(0.5).timeout

	# Change scene (RPC runs on all clients)
	var network_manager = get_node_or_null("/root/NetworkManager")
	if network_manager:
		network_manager.change_scene_synchronized.rpc("res://scenes/combat.tscn")
	else:
		push_error("[REWARD] NetworkManager not found!")

func _on_skip_pressed():
	print("[REWARD] Player skipped rewards - auto-selecting first choice")

	# Hide skip button
	skip_button.visible = false

	# For rare card phase (spectator mode)
	if reward_phase == 0:
		var my_index = game_manager.local_player_index
		if my_index == chosen_player_index:
			# Auto-select first choice
			var first_choice = _generate_rare_choices()[0]
			_on_spectator_choice_made(my_index, first_choice)

	# For common card phase (private mode)
	elif reward_phase == 1:
		var my_index = game_manager.local_player_index
		var choices = _generate_common_choices()[my_index]
		# Auto-select first choice (heal)
		_on_private_choice_made(my_index, choices[0])
