class_name PlayerStatusPanel
extends Node

## Manages player status panel updates for combat UI
## Handles left, right, and your character panels with consistent styling

var game_manager: Node
var left_player_panel: Panel
var right_player_panel: Panel
var your_character_panel: Panel
var card_scene = preload("res://scenes/card_visual.tscn")

func setup(gm: Node, left: Panel, right: Panel, your: Panel):
	game_manager = gm
	left_player_panel = left
	right_player_panel = right
	your_character_panel = your

	# Connect click handlers for targeting
	_connect_panel_click_handlers()

func _connect_panel_click_handlers():
	# Connect click handlers will be set up when updating panels
	pass

## Update all player panels
func update_all():
	var my_index = game_manager.local_player_index
	if my_index == -1:
		push_error("[PlayerStatusPanel] Local player index not set!")
		return

	# Safety check: ensure player index is valid
	if my_index >= game_manager.players.size():
		push_error("[PlayerStatusPanel] Invalid local player index: %d" % my_index)
		return

	var my_character = game_manager.players[my_index]

	# Determine left and right players
	var other_indices = []
	for i in range(game_manager.players.size()):
		if i != my_index:
			other_indices.append(i)

	# Left player (first "other")
	if other_indices.size() > 0:
		var left_char = game_manager.players[other_indices[0]]
		_update_other_panel(left_player_panel, left_char, other_indices[0])
	else:
		# No left player (< 2 players total)
		left_player_panel.visible = false

	# Right player (second "other")
	if other_indices.size() > 1:
		var right_char = game_manager.players[other_indices[1]]
		_update_other_panel(right_player_panel, right_char, other_indices[1])
	else:
		# No right player (< 3 players total)
		right_player_panel.visible = false

	# Your character (bottom)
	_update_your_panel(my_character)

## Update other player panel (left or right)
func _update_other_panel(panel: Panel, character: Character, player_index: int):
	panel.visible = true

	# Connect click handler for targeting (disconnect first to avoid duplicates)
	if not panel.gui_input.is_connected(_on_panel_clicked):
		panel.gui_input.connect(_on_panel_clicked.bind(character))

	# Update name, HP, Energy
	var name_label = panel.get_node("VBoxContainer/NameLabel")
	var hp_label = panel.get_node("VBoxContainer/HPLabel")
	var energy_label = panel.get_node("VBoxContainer/EnergyLabel")

	name_label.text = character.character_name
	hp_label.text = "HP: %d/%d" % [character.current_health, character.max_health]

	if character.shield > 0:
		hp_label.text += "\nShield: %d" % character.shield

	energy_label.text = "E: %d/%d" % [character.current_energy, character.max_energy]

	# Update panel background color based on status
	var bg_color = Color(0.2, 0.2, 0.2)
	if not character.is_alive():
		bg_color = Color(0.3, 0.1, 0.1)  # Red for dead
	elif player_index == game_manager.current_player_index:
		bg_color = Color(0.2, 0.4, 0.6)  # Blue for active

	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color.WHITE
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)

	# Update "playing card" display
	var playing_card_container = panel.get_node("VBoxContainer/PlayingCardContainer")
	# Clear existing
	for child in playing_card_container.get_children():
		child.queue_free()

	# Show last played card if available
	if game_manager.last_played_cards.has(player_index):
		var last_card = game_manager.last_played_cards[player_index]
		var small_card_visual = card_scene.instantiate()
		playing_card_container.add_child(small_card_visual)

		small_card_visual.set_card(last_card)
		small_card_visual.set_playable(false)  # Not playable, just for display
		small_card_visual.scale = Vector2(0.67, 0.67)  # Scale to 100x140 from 150x220

## Update your character panel (bottom)
func _update_your_panel(character: Character):
	# Connect click handler for self-targeting
	if not your_character_panel.gui_input.is_connected(_on_panel_clicked):
		your_character_panel.gui_input.connect(_on_panel_clicked.bind(character))

	var name_label = your_character_panel.get_node("HBoxContainer/NameLabel")
	var hp_label = your_character_panel.get_node("HBoxContainer/HPLabel")
	var energy_label = your_character_panel.get_node("HBoxContainer/EnergyLabel")
	var shield_label = your_character_panel.get_node("HBoxContainer/ShieldLabel")

	name_label.text = character.character_name
	hp_label.text = "HP: %d/%d" % [character.current_health, character.max_health]
	energy_label.text = "Energy: %d/%d" % [character.current_energy, character.max_energy]
	shield_label.text = "Shield: %d" % character.shield

	# Highlight panel if it's your turn
	var is_my_turn = game_manager.local_player_index == game_manager.current_player_index
	var bg_color = Color(0.3, 0.5, 0.7) if is_my_turn else Color(0.2, 0.2, 0.2)

	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color.YELLOW if is_my_turn else Color.WHITE
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	your_character_panel.add_theme_stylebox_override("panel", style)

## Forward panel clicks to parent for targeting
signal panel_clicked(event: InputEvent, character: Character)

func _on_panel_clicked(event: InputEvent, character: Character):
	panel_clicked.emit(event, character)
