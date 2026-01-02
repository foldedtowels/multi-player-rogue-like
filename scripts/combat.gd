extends Control

var game_manager: Node
var current_player: Character
var selected_card: Card
var awaiting_target: bool = false

# UI References - New multiplayer layout
@onready var left_player_panel: Panel = $MainArea/LeftPlayerPanel
@onready var right_player_panel: Panel = $MainArea/RightPlayerPanel
@onready var your_character_panel: Panel = $BottomArea/YourCharacterPanel
@onready var enemy_displays_container: HBoxContainer = $MainArea/CenterArea/EnemyDisplays
@onready var hand_container: HBoxContainer = $BottomArea/HandPanel/HandContainer
@onready var deck_count_label: Label = $BottomArea/YourCharacterPanel/HBoxContainer/DeckCountLabel
@onready var discard_count_label: Label = $BottomArea/YourCharacterPanel/HBoxContainer/DiscardCountLabel
@onready var end_turn_button: Button = $ControlPanel/EndTurnButton
@onready var turn_label: Label = $TopBar/TurnLabel
@onready var energy_label: Label = $TopBar/EnergyLabel
@onready var round_label: Label = $TopBar/RoundLabel

var card_scene = preload("res://scenes/card_visual.tscn")
var boss_visual: Node2D = null

func _ready():
	game_manager = get_node("/root/GameManager")

	# Add animated background
	create_animated_background()

	# Connect signals
	game_manager.player_turn_started.connect(_on_player_turn_started)
	game_manager.boss_turn_started.connect(_on_boss_turn_started)
	game_manager.card_played.connect(_on_card_played)
	game_manager.game_state_changed.connect(_on_game_state_changed)
	game_manager.combat_ended.connect(_on_combat_ended)

	end_turn_button.pressed.connect(_on_end_turn_pressed)

	update_all_displays()

	# Start the first player's turn after signals are connected
	if game_manager.current_state == game_manager.GameState.COMBAT:
		game_manager.start_player_turn(0)

func create_animated_background():
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -100
	bg.set_script(load("res://scripts/animated_background.gd"))
	add_child(bg)
	move_child(bg, 0)  # Move to back

func update_all_displays():
	update_player_displays()
	update_enemy_displays()
	update_hand_display()
	update_deck_counts()
	update_turn_display()

func update_player_displays():
	var my_index = game_manager.local_player_index
	if my_index == -1:
		push_error("[Combat] Local player index not set!")
		return

	# Safety check: ensure player index is valid
	if my_index >= game_manager.players.size():
		push_error("[Combat] Invalid local player index: %d" % my_index)
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
		update_other_player_panel(left_player_panel, left_char, other_indices[0])
	else:
		# No left player (< 2 players total)
		left_player_panel.visible = false

	# Right player (second "other")
	if other_indices.size() > 1:
		var right_char = game_manager.players[other_indices[1]]
		update_other_player_panel(right_player_panel, right_char, other_indices[1])
	else:
		# No right player (< 3 players total)
		right_player_panel.visible = false

	# Your character (bottom)
	update_your_character_panel(my_character)

func update_other_player_panel(panel: Panel, character: Character, player_index: int):
	panel.visible = true

	# Connect click handler for targeting (disconnect first to avoid duplicates)
	if not panel.gui_input.is_connected(_on_character_clicked):
		panel.gui_input.connect(_on_character_clicked.bind(character))

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

func update_your_character_panel(character: Character):
	# Connect click handler for self-targeting
	if not your_character_panel.gui_input.is_connected(_on_character_clicked):
		your_character_panel.gui_input.connect(_on_character_clicked.bind(character))

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

func update_deck_counts():
	var my_index = game_manager.local_player_index
	if my_index == -1 or my_index >= game_manager.players.size():
		return

	var my_character = game_manager.players[my_index]
	deck_count_label.text = "Deck: %d" % my_character.deck.size()
	discard_count_label.text = "Discard: %d" % my_character.discard_pile.size()

func update_hand_display():
	# Clear existing cards
	for child in hand_container.get_children():
		child.queue_free()

	var my_index = game_manager.local_player_index
	if my_index == -1 or my_index >= game_manager.players.size():
		return

	var my_character = game_manager.players[my_index]

	# Only show hand if it's your turn
	var is_my_turn = game_manager.local_player_index == game_manager.current_player_index

	if is_my_turn:
		# Display cards in hand (only YOUR cards)
		for card in my_character.hand:
			var card_visual = card_scene.instantiate()
			hand_container.add_child(card_visual)

			card_visual.set_card(card)
			card_visual.set_playable(card.can_afford(my_character.current_energy))
			card_visual.card_clicked.connect(_on_card_clicked)

func update_enemy_displays():
	# Clear existing enemy UI
	for child in enemy_displays_container.get_children():
		child.queue_free()

	# Create UI for each enemy
	for i in game_manager.enemies.size():
		var enemy = game_manager.enemies[i]
		var enemy_panel = Panel.new()
		enemy_panel.name = "Enemy" + str(i)
		enemy_panel.custom_minimum_size = Vector2(200, 150)
		enemy_displays_container.add_child(enemy_panel)

		# Add VBoxContainer for labels
		var vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.offset_left = 10
		vbox.offset_top = 10
		vbox.offset_right = -10
		vbox.offset_bottom = -10
		vbox.add_theme_constant_override("separation", 5)
		enemy_panel.add_child(vbox)

		# Add labels
		var name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 18)
		vbox.add_child(name_label)

		var hp_label = Label.new()
		hp_label.name = "HPLabel"
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(hp_label)

		var status_label = Label.new()
		status_label.name = "StatusLabel"
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(status_label)

		# Connect click handler
		enemy_panel.gui_input.connect(_on_character_clicked.bind(enemy))

		# Update display
		update_enemy_display(enemy_panel, enemy)

func update_enemy_display(display: Panel, enemy: Character):
	var name_label = display.get_node("VBoxContainer/NameLabel")
	var hp_label = display.get_node("VBoxContainer/HPLabel")
	var status_label = display.get_node("VBoxContainer/StatusLabel")

	name_label.text = enemy.character_name
	hp_label.text = "HP: %d/%d" % [enemy.current_health, enemy.max_health]

	if enemy.shield > 0:
		hp_label.text += "\nShield: %d" % enemy.shield

	# Status effects
	var status_text = ""
	if enemy.strength > 0:
		status_text += "Str +%d " % enemy.strength
	if enemy.poison > 0:
		status_text += "Poison %d " % enemy.poison
	if enemy.burn > 0:
		status_text += "Burn %d " % enemy.burn
	if enemy.vulnerable > 0:
		status_text += "Vuln %d " % enemy.vulnerable
	if enemy.armor > 0:
		status_text += "Armor %d " % enemy.armor
	status_label.text = status_text

	# Background color
	var bg_color = Color(0.4, 0.2, 0.2) if not enemy.is_alive() else Color(0.3, 0.1, 0.1)
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color(0.8, 0.2, 0.2)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	display.add_theme_stylebox_override("panel", style)

func update_turn_display():
	if game_manager.current_player_index >= 0 and game_manager.current_player_index < game_manager.players.size():
		var current = game_manager.players[game_manager.current_player_index]
		turn_label.text = "Turn: %s" % current.character_name
		energy_label.text = "Energy: %d/%d" % [current.current_energy, current.max_energy]

	round_label.text = "Round: %d" % game_manager.round_number

func _on_player_turn_started(player_index: int):
	current_player = game_manager.players[player_index]
	update_all_displays()

	# Only enable end turn button if it's YOUR turn
	var is_my_turn = game_manager.local_player_index == player_index
	end_turn_button.disabled = not is_my_turn

func _on_boss_turn_started():
	turn_label.text = "Turn: Boss"
	end_turn_button.disabled = true
	update_all_displays()

func _on_card_played(character: Character, card: Card, target: Character):
	update_all_displays()

func _on_game_state_changed():
	update_all_displays()

func _on_combat_ended(victory: bool):
	if victory:
		turn_label.text = "VICTORY!"
	else:
		turn_label.text = "DEFEAT!"

	end_turn_button.disabled = true

func _on_card_clicked(card: Card):
	# Only allow card clicks if it's your turn
	var my_index = game_manager.local_player_index
	if my_index == -1 or my_index != game_manager.current_player_index:
		return

	var my_character = game_manager.players[my_index]

	if not card.can_afford(my_character.current_energy):
		return

	selected_card = card

	# Check if card needs targeting
	match card.target_type:
		Card.TargetType.SELF:
			# Play immediately on self
			game_manager.play_card(my_character, card, my_character)
			selected_card = null
		Card.TargetType.ALL_ALLIES, Card.TargetType.ALL_ENEMIES:
			# Play immediately, no targeting needed
			# Use first alive enemy as target (AoE will handle all)
			var first_enemy = game_manager.enemies[0] if game_manager.enemies.size() > 0 else null
			if first_enemy:
				game_manager.play_card(my_character, card, first_enemy)
			selected_card = null
		_:
			# Need to select a target
			awaiting_target = true
			turn_label.text = "Select a target..."

func _on_character_clicked(event: InputEvent, character: Character):
	if not awaiting_target or not selected_card:
		return

	if event is InputEventMouseButton and event.pressed:
		# Validate target
		var valid_target = false

		match selected_card.target_type:
			Card.TargetType.SINGLE_ALLY:
				valid_target = game_manager.players.has(character)
			Card.TargetType.SINGLE_ENEMY, Card.TargetType.RANDOM_ENEMY:
				valid_target = game_manager.enemies.has(character)

		if valid_target:
			var my_index = game_manager.local_player_index
			if my_index >= 0 and my_index < game_manager.players.size():
				var my_character = game_manager.players[my_index]
				game_manager.play_card(my_character, selected_card, character)
				selected_card = null
				awaiting_target = false
				turn_label.text = "Turn: %s" % my_character.character_name

func _on_end_turn_pressed():
	# Only allow ending turn if it's your turn
	var my_index = game_manager.local_player_index
	if my_index == game_manager.current_player_index:
		game_manager.end_player_turn()
		awaiting_target = false
		selected_card = null
