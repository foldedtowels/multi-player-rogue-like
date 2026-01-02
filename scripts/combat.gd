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
@onready var phase_label: Label = $ControlPanel/VBoxContainer/PhaseLabel
@onready var ready_button: Button = $ControlPanel/VBoxContainer/ReadyButton
@onready var pass_button: Button = $ControlPanel/VBoxContainer/PassButton
@onready var ready_status_label: Label = $ControlPanel/VBoxContainer/ReadyStatusLabel
@onready var turn_label: Label = $TopBar/TurnLabel
@onready var energy_label: Label = $TopBar/EnergyLabel
@onready var round_label: Label = $TopBar/RoundLabel

var card_scene = preload("res://scenes/card_visual.tscn")
var boss_visual: Node2D = null

func _ready():
	game_manager = get_node("/root/GameManager")

	# Add animated background
	create_animated_background()

	# Connect game manager signals
	game_manager.player_turn_started.connect(_on_player_turn_started)
	game_manager.boss_turn_started.connect(_on_boss_turn_started)
	game_manager.card_played.connect(_on_card_played)
	game_manager.game_state_changed.connect(_on_game_state_changed)
	game_manager.combat_ended.connect(_on_combat_ended)

	# Connect button signals
	ready_button.pressed.connect(_on_ready_pressed)
	pass_button.pressed.connect(_on_pass_pressed)

	update_all_displays()

	# Start the first round with simultaneous selection phase
	if game_manager.current_state == game_manager.GameState.COMBAT:
		game_manager.start_round()

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
	update_button_states()

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

	# Show hand during SELECTION and ACTION phases (not during ENEMY_TURN)
	var show_hand = (game_manager.turn_phase == game_manager.TurnPhase.PLAYER_SELECTION or
					 game_manager.turn_phase == game_manager.TurnPhase.PLAYER_ACTION)

	if show_hand:
		# Display cards in hand (only YOUR cards)
		for card in my_character.hand:
			var card_visual = card_scene.instantiate()
			hand_container.add_child(card_visual)

			card_visual.set_card(card)

			# Cards are only playable during ACTION phase
			var is_action_phase = game_manager.turn_phase == game_manager.TurnPhase.PLAYER_ACTION
			var can_afford = card.can_afford(my_character.current_energy)
			var not_passed = not game_manager.players_acted_this_round.has(my_index)

			card_visual.set_playable(is_action_phase and can_afford and not_passed)
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
	var my_index = game_manager.local_player_index
	if my_index >= 0 and my_index < game_manager.players.size():
		var my_character = game_manager.players[my_index]
		energy_label.text = "Energy: %d/%d" % [my_character.current_energy, my_character.max_energy]

	round_label.text = "Round: %d" % game_manager.round_number

	# Update turn label based on phase
	match game_manager.turn_phase:
		game_manager.TurnPhase.PLAYER_SELECTION:
			turn_label.text = "Selection Phase"
		game_manager.TurnPhase.PLAYER_ACTION:
			turn_label.text = "Action Phase"
		game_manager.TurnPhase.ENEMY_TURN:
			turn_label.text = "Enemy Turn"

func update_button_states():
	var my_index = game_manager.local_player_index
	if my_index == -1:
		return

	# Update based on current turn phase
	match game_manager.turn_phase:
		game_manager.TurnPhase.PLAYER_SELECTION:
			phase_label.text = "Selection Phase"
			ready_button.visible = true
			pass_button.visible = false

			# Disable ready if already ready
			var i_am_ready = game_manager.players_ready.has(my_index)
			ready_button.disabled = i_am_ready

			# Update ready status
			var ready_count = game_manager.players_ready.size()
			var total_alive = 0
			for player in game_manager.players:
				if player.is_alive():
					total_alive += 1
			ready_status_label.text = "Ready: %d/%d" % [ready_count, total_alive]

		game_manager.TurnPhase.PLAYER_ACTION:
			phase_label.text = "Action Phase"
			ready_button.visible = false
			pass_button.visible = true

			# Disable pass if already passed
			var i_passed = game_manager.players_acted_this_round.has(my_index)
			pass_button.disabled = i_passed

			# Update ready status to show who has passed
			var passed_count = game_manager.players_acted_this_round.size()
			var total_alive = 0
			for player in game_manager.players:
				if player.is_alive():
					total_alive += 1
			ready_status_label.text = "Passed: %d/%d" % [passed_count, total_alive]

		game_manager.TurnPhase.ENEMY_TURN:
			phase_label.text = "Enemy Turn"
			ready_button.visible = false
			pass_button.visible = false
			ready_status_label.text = "Enemies Acting..."

func _on_player_turn_started(player_index: int):
	# Legacy signal - still emitted by old boss AI code
	# Just update displays for now
	update_all_displays()

func _on_boss_turn_started():
	# Legacy signal - still emitted by old boss AI code
	# Just update displays for now
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

	ready_button.disabled = true
	pass_button.disabled = true

func _on_card_clicked(card: Card):
	# Only allow card clicks during ACTION phase
	var my_index = game_manager.local_player_index
	if my_index == -1:
		return

	# Must be in ACTION phase to play cards
	if game_manager.turn_phase != game_manager.TurnPhase.PLAYER_ACTION:
		return

	# Can't play cards if you've already passed
	if game_manager.players_acted_this_round.has(my_index):
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

func _on_ready_pressed():
	# Mark player as ready during selection phase
	game_manager.player_ready()
	awaiting_target = false
	selected_card = null
	update_button_states()

func _on_pass_pressed():
	# Mark player as done acting during action phase
	game_manager.player_pass()
	awaiting_target = false
	selected_card = null
	update_button_states()
