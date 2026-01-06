extends Control

var game_manager: Node
var current_player: Character
var card_hand_display: CardHandDisplay
var player_status_panel: PlayerStatusPanel
var last_turn_phase = null  # Track phase changes for animations

# UI References - New multiplayer layout
@onready var left_player_panel: Panel = $MainArea/LeftPlayerPanel
@onready var right_player_panel: Panel = $MainArea/RightPlayerPanel
@onready var your_character_panel: Panel = $BottomArea/YourCharacterPanel
@onready var enemy_displays_container: HBoxContainer = $MainArea/CenterArea/EnemyDisplays
@onready var hand_container: HBoxContainer = $BottomArea/HandPanel/HandContainer
@onready var deck_count_label: Label = $BottomArea/YourCharacterPanel/HBoxContainer/DeckCountLabel
@onready var discard_count_label: Label = $BottomArea/YourCharacterPanel/HBoxContainer/DiscardCountLabel
@onready var phase_label: Label = $BottomArea/YourCharacterPanel/HBoxContainer/PhaseLabel
@onready var ready_button: Button = $BottomArea/YourCharacterPanel/HBoxContainer/ReadyButton
@onready var pass_button: Button = $BottomArea/YourCharacterPanel/HBoxContainer/PassButton
@onready var ready_status_label: Label = $BottomArea/YourCharacterPanel/HBoxContainer/ReadyStatusLabel
@onready var turn_label: Label = $TopBar/TurnLabel
@onready var energy_label: Label = $TopBar/EnergyLabel
@onready var round_label: Label = $TopBar/RoundLabel

var card_scene = preload("res://scenes/card_visual.tscn")
var boss_visual: Node2D = null

func _ready():
	game_manager = get_node("/root/GameManager")

	# Create card hand display component
	card_hand_display = CardHandDisplay.new()
	add_child(card_hand_display)
	card_hand_display.setup(game_manager, hand_container, turn_label)
	card_hand_display.card_queued.connect(_on_card_queued)

	# Create player status panel component
	player_status_panel = PlayerStatusPanel.new()
	add_child(player_status_panel)
	player_status_panel.setup(game_manager, left_player_panel, right_player_panel, your_character_panel)
	player_status_panel.panel_clicked.connect(_on_character_clicked)

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

	# CRITICAL FIX: Allow mouse events to pass through panels to reach cards
	var hand_panel = $BottomArea/HandPanel
	hand_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# DEBUG: Check turn_phase BEFORE start_round
	print("[COMBAT DEBUG] _ready() - turn_phase BEFORE start_round: ", game_manager.turn_phase)

	# Start the first round with simultaneous selection phase
	if game_manager.current_state == game_manager.GameState.COMBAT:
		game_manager.start_round()

	# DEBUG: Check turn_phase AFTER start_round
	print("[COMBAT DEBUG] _ready() - turn_phase AFTER start_round: ", game_manager.turn_phase)

	# Update displays AFTER round is properly initialized
	update_all_displays()

func create_animated_background():
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -100
	bg.set_script(load("res://scripts/animated_background.gd"))
	add_child(bg)
	move_child(bg, 0)  # Move to back

func update_all_displays():
	player_status_panel.update_all()
	update_enemy_displays()
	card_hand_display.update_display()
	update_deck_counts()
	update_turn_display()
	update_button_states()

func update_deck_counts():
	var my_index = game_manager.local_player_index
	if my_index == -1 or my_index >= game_manager.players.size():
		return

	var my_character = game_manager.players[my_index]
	deck_count_label.text = "Deck: %d" % my_character.deck.size()
	discard_count_label.text = "Discard: %d" % my_character.discard_pile.size()

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
			pass_button.text = "Done"

			# Disable Done if already done
			var i_am_done = game_manager.players_done_acting.has(my_index)
			pass_button.disabled = i_am_done

			# Show done status
			var done_count = game_manager.players_done_acting.size()
			var total_alive = 0
			for player in game_manager.players:
				if player.is_alive():
					total_alive += 1
			ready_status_label.text = "Done: %d/%d" % [done_count, total_alive]

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
	# Detect phase transitions for animations
	var current_phase = game_manager.turn_phase

	# DEBUG: Log state change
	var phase_name_old = ""
	var phase_name_new = ""
	match last_turn_phase:
		game_manager.TurnPhase.PLAYER_SELECTION:
			phase_name_old = "SELECTION"
		game_manager.TurnPhase.PLAYER_ACTION:
			phase_name_old = "ACTION"
		game_manager.TurnPhase.ENEMY_TURN:
			phase_name_old = "ENEMY"
		null:
			phase_name_old = "NULL"
	match current_phase:
		game_manager.TurnPhase.PLAYER_SELECTION:
			phase_name_new = "SELECTION"
		game_manager.TurnPhase.PLAYER_ACTION:
			phase_name_new = "ACTION"
		game_manager.TurnPhase.ENEMY_TURN:
			phase_name_new = "ENEMY"
	print("[COMBAT DEBUG] _on_game_state_changed - phase transition: ", phase_name_old, " -> ", phase_name_new)

	# CRITICAL: Clear queued cards when entering SELECTION phase from another phase
	if last_turn_phase != game_manager.TurnPhase.PLAYER_SELECTION and current_phase == game_manager.TurnPhase.PLAYER_SELECTION:
		print("[STATE] Phase transition: ", last_turn_phase, " -> SELECTION - Clearing queued cards")
		card_hand_display.clear_queued_cards()

	if last_turn_phase == game_manager.TurnPhase.PLAYER_SELECTION and current_phase == game_manager.TurnPhase.PLAYER_ACTION:
		# Transition to ACTION phase - animate cards
		print("[STATE] Phase transition: SELECTION -> ACTION - Animating cards")
		card_hand_display.animate_selection_to_action()

	last_turn_phase = current_phase
	update_all_displays()

func _on_combat_ended(victory: bool):
	if victory:
		turn_label.text = "VICTORY!"
	else:
		turn_label.text = "DEFEAT!"

	ready_button.disabled = true
	pass_button.disabled = true

func _on_card_queued(card: Card):
	# Update displays when a card is queued
	update_all_displays()

func _on_character_clicked(event: InputEvent, character: Character):
	if event is InputEventMouseButton and event.pressed:
		# Try to handle target selection via card hand display
		if card_hand_display.on_character_clicked(character):
			update_all_displays()

func _on_ready_pressed():
	# Mark player as ready during selection phase
	print("[COMBAT] Player marked ready - queued cards: ", game_manager.queued_cards.get(game_manager.local_player_index, []).size())
	game_manager.player_ready()
	card_hand_display.cancel_target_selection()
	update_button_states()

func _on_pass_pressed():
	# Player finishes their actions
	game_manager.player_done()
	card_hand_display.cancel_target_selection()
	update_button_states()
