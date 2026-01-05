class_name RewardManager
extends Node

## Manages reward selection with privacy modes
## SPECTATOR: All players watch one player choose (rare cards)
## PRIVATE: Each player sees only their own choices (common rewards)

signal spectator_reward_complete()
signal all_players_ready()
signal spectator_choice_made(player_index: int, choice: RewardChoice)  ## Emitted when spectator makes choice
signal private_choice_made(player_index: int, choice: RewardChoice)  ## Emitted when player makes private choice

enum RewardMode {
	SPECTATOR,  ## One player chooses, others watch
	PRIVATE     ## Each player sees only their own choices
}

var _game_manager: Node
var _players_ready: Dictionary = {}  ## player_index -> bool

func _ready():
	_game_manager = get_node("/root/GameManager")

## SPECTATOR MODE: Show reward to all players, but only one can interact
## @param chosen_player_index: Which player can make the selection
## @param choices: Array of RewardChoice options
## @param panel: The RewardDisplayPanel to use for display
func show_spectator_reward(chosen_player_index: int, choices: Array[RewardChoice], panel):
	var my_index = _game_manager.local_player_index
	var is_choosing = (my_index == chosen_player_index)

	# All players see the same panel, but only chosen player can interact
	var chosen_player = _game_manager.players[chosen_player_index]

	panel.setup(
		"%s - Choose ONE" % chosen_player.character_name,
		choices,
		is_choosing  ## Only chosen player has enabled=true
	)

	panel.visible = true

	if is_choosing:
		# Only connect signal for the choosing player
		if not panel.choice_selected.is_connected(_on_spectator_choice_selected):
			panel.choice_selected.connect(_on_spectator_choice_selected)

## Handle spectator choice selection
func _on_spectator_choice_selected(choice: RewardChoice):
	var my_index = _game_manager.local_player_index
	print("[WIZARD] Player ", my_index, " selected spectator reward: ", choice.display_name)

	# Emit signal to parent (reward.gd) to handle RPC (can't call RPC from dynamic node)
	print("[WIZARD] Emitting spectator_choice_made signal to reward.gd for RPC handling")
	spectator_choice_made.emit(my_index, choice)

## Apply the spectator choice (called after RPC from reward.gd)
func apply_spectator_choice(player_index: int, choice: RewardChoice):
	print("[WIZARD] Applying spectator choice for player ", player_index, ": ", choice.display_name)
	var player = _game_manager.players[player_index]
	choice.apply_to_player(player)

## Called via RPC from reward.gd when spectator choice is complete
func notify_spectator_complete():
	print("[WIZARD] notify_spectator_complete called - emitting signal to close rare panel")
	spectator_reward_complete.emit()

## PRIVATE MODE: Each player sees only their own choices
## @param choices_per_player: Dictionary {player_index: Array[RewardChoice]}
## @param panel: The RewardDisplayPanel to use for display
func show_private_rewards(choices_per_player: Dictionary, panel):
	var my_index = _game_manager.local_player_index

	# Only show THIS player's choices
	if not choices_per_player.has(my_index):
		push_error("[RewardManager] No choices for player %d" % my_index)
		return

	var my_choices = choices_per_player[my_index]

	panel.setup(
		"Your Reward - Choose ONE",
		my_choices,
		true  ## Always enabled for your own choices
	)

	panel.visible = true

	# Connect signal if not already connected
	if not panel.choice_selected.is_connected(_on_private_choice_selected):
		panel.choice_selected.connect(_on_private_choice_selected)

## Handle private choice selection
func _on_private_choice_selected(choice: RewardChoice):
	var my_index = _game_manager.local_player_index
	print("[WIZARD] Player ", my_index, " selected private reward: ", choice.display_name)

	# Emit signal to parent (reward.gd) to handle RPC (can't call RPC from dynamic node)
	print("[WIZARD] Emitting private_choice_made signal to reward.gd for RPC handling")
	private_choice_made.emit(my_index, choice)

## Apply the private choice (called after RPC from reward.gd)
func apply_private_choice(player_index: int, choice: RewardChoice):
	print("[WIZARD] Applying private choice for player ", player_index, ": ", choice.display_name)
	var player = _game_manager.players[player_index]
	choice.apply_to_player(player)

	# Mark this player as ready
	_players_ready[player_index] = true
	print("[WIZARD] Player ", player_index, " marked ready. Total ready: ", _players_ready.size())

## Update ready status (called from reward.gd after RPC)
func update_ready_status(ready_indices: Array):
	_players_ready.clear()
	for idx in ready_indices:
		_players_ready[idx] = true
	print("[WIZARD] Ready status updated: ", _players_ready.size(), " players ready")

## Check if all players are ready (called from reward.gd on server only)
func check_all_players_ready() -> bool:
	var alive_count = 0
	for player in _game_manager.players:
		if player.is_alive():
			alive_count += 1

	var all_ready = _players_ready.size() >= alive_count
	print("[WIZARD] Checking ready status: ", _players_ready.size(), "/", alive_count, " - all ready: ", all_ready)
	return all_ready

## Notify that all players are ready (called from reward.gd after RPC)
func notify_all_players_ready():
	print("[WIZARD] All players ready - emitting signal")
	all_players_ready.emit()

## Reset ready state for next reward phase
func reset():
	_players_ready.clear()
