extends Control

## Buff Selection scene - displays after defeating minions, before boss
## Each player chooses a reward to strengthen their character
## Uses modular RewardManager for privacy-aware selection

var game_manager: Node
var card_db: Node
var reward_manager: RewardManager

# UI Elements
@onready var title_label: Label = $TitleLabel
@onready var reward_panel: RewardDisplayPanel = $RewardPanel
@onready var status_label: Label = $StatusLabel

func _ready():
	game_manager = get_node("/root/GameManager")
	card_db = get_node("/root/CardDatabase")

	# CRITICAL: Background must not block clicks - set to IGNORE so clicks reach buttons/cards
	$ColorRect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Create reward manager with stable name for RPC routing
	reward_manager = RewardManager.new()
	reward_manager.name = "RewardManager"
	add_child(reward_manager)

	# Connect signals
	reward_manager.all_players_ready.connect(_on_all_players_ready)
	reward_manager.private_choice_made.connect(_on_private_choice_made)

	# Setup UI
	title_label.text = "Minions Defeated! Choose Your Reward"
	status_label.text = "Waiting for all players to choose..."
	reward_panel.visible = false

	# Start buff selection
	await get_tree().create_timer(1.0).timeout
	_show_buff_choices()

## Display buff choices to all players (private mode)
func _show_buff_choices():
	var choices_per_player = _generate_buff_choices()

	# Show private mode rewards (each player sees only their own)
	reward_manager.show_private_rewards(choices_per_player, reward_panel)

	# Update status based on ready state
	_update_status()

## Generate buff choices for each player
func _generate_buff_choices() -> Dictionary:
	var choices = {}

	for player_idx in range(3):
		var player = game_manager.players[player_idx]
		var player_choices: Array[RewardChoice] = []

		# Option 1: +1 Max Energy
		var energy_buff = RewardChoice.new()
		energy_buff.choice_type = RewardChoice.ChoiceType.BUFF
		energy_buff.display_name = "+1 Energy"
		energy_buff.description = "Increase max energy by 1"
		energy_buff.buff_type = "max_energy"
		energy_buff.buff_amount = 1
		player_choices.append(energy_buff)

		# Option 2: +15 Max HP
		var hp_buff = RewardChoice.new()
		hp_buff.choice_type = RewardChoice.ChoiceType.BUFF
		hp_buff.display_name = "+15 Max HP"
		hp_buff.description = "Permanently increase max health"
		hp_buff.buff_type = "max_health"
		hp_buff.buff_amount = 15
		player_choices.append(hp_buff)

		# Option 3: Random rare card
		var rare_pool = card_db.get_rare_cards()
		rare_pool.shuffle()
		var rare_card = rare_pool[0]

		var card_choice = RewardChoice.new()
		card_choice.choice_type = RewardChoice.ChoiceType.CARD
		card_choice.card_data = rare_card
		card_choice.display_name = rare_card.card_name
		card_choice.description = rare_card.description
		player_choices.append(card_choice)

		choices[player_idx] = player_choices

	return choices

## Update status label showing ready players
func _update_status():
	var ready_count = reward_manager._players_ready.size()
	var total_alive = 0
	for player in game_manager.players:
		if player.is_alive():
			total_alive += 1

	status_label.text = "Players ready: %d/%d" % [ready_count, total_alive]

## Handle private choice made - send to server or apply directly
func _on_private_choice_made(player_index: int, choice: RewardChoice):
	print("[BUFF] Private choice made by player ", player_index, " - handling RPC from buff_selection.gd")

	# Hide the reward panel for THIS player immediately
	reward_panel.visible = false
	print("[BUFF] Hiding reward panel for player ", player_index)

	# Send choice to server for processing
	if multiplayer.is_server():
		print("[BUFF] Server applying private choice directly")
		_apply_and_check_private_choice(player_index, choice)
	else:
		print("[BUFF] Client sending private choice to server via buff_selection.gd RPC")
		rpc_id(1, "server_receive_private_choice", player_index, choice.serialize())

## Server receives private choice from client
@rpc("any_peer", "call_remote", "reliable")
func server_receive_private_choice(player_index: int, choice_data: Dictionary):
	print("[BUFF] Server received private choice RPC from player ", player_index)
	var choice = RewardChoice.deserialize(choice_data)
	_apply_and_check_private_choice(player_index, choice)

## Apply private choice and check if all players are ready
func _apply_and_check_private_choice(player_index: int, choice: RewardChoice):
	print("[BUFF] Applying private choice for player ", player_index)

	# Apply the choice
	reward_manager.apply_private_choice(player_index, choice)

	# Update status display
	_update_status()

	# Broadcast updated ready status to all clients
	var ready_indices = Array(reward_manager._players_ready.keys())
	print("[BUFF] Broadcasting ready status: ", ready_indices)
	rpc("client_update_ready_status", ready_indices)

	# Check if all players are ready (server only)
	if reward_manager.check_all_players_ready():
		print("[BUFF] All players ready - broadcasting completion")
		rpc("client_all_players_ready")

## RPC to update ready status on all clients
@rpc("any_peer", "call_local", "reliable")
func client_update_ready_status(ready_indices: Array):
	print("[BUFF] Received ready status update: ", ready_indices)
	reward_manager.update_ready_status(ready_indices)
	_update_status()

## RPC to notify all clients that everyone is ready
@rpc("any_peer", "call_local", "reliable")
func client_all_players_ready():
	print("[BUFF] Received all players ready notification")
	reward_manager.notify_all_players_ready()

## All players have chosen their buffs
func _on_all_players_ready():
	print("[BUFF] All players ready - preparing for boss battle")
	status_label.text = "All players ready! Preparing for boss battle..."
	reward_panel.visible = false

	await get_tree().create_timer(2.0).timeout
	_continue_to_boss()

## Transition to boss combat
func _continue_to_boss():
	print("[BUFF] Transitioning to boss combat")

	# Call start_boss_phase_1() which sets up boss and changes scene to combat.tscn
	# It handles the scene change internally, so we don't need to do it here
	game_manager.start_boss_phase_1()
