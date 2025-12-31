extends Control

var game_manager: Node
var current_player: Character
var selected_card: Card
var awaiting_target: bool = false

# UI References
@onready var player1_display: Control = $PlayerDisplays/Player1
@onready var player2_display: Control = $PlayerDisplays/Player2
@onready var player3_display: Control = $PlayerDisplays/Player3
@onready var boss_display: Control = $BossDisplay
@onready var hand_container: HBoxContainer = $HandPanel/HandContainer
@onready var end_turn_button: Button = $ControlPanel/EndTurnButton
@onready var turn_label: Label = $TopBar/TurnLabel
@onready var energy_label: Label = $TopBar/EnergyLabel
@onready var round_label: Label = $TopBar/RoundLabel

var player_displays: Array[Control] = []
var card_scene = preload("res://scenes/card_visual.tscn")
var boss_visual: Node2D = null

func _ready():
	game_manager = get_node("/root/GameManager")

	# Add animated background
	create_animated_background()

	player_displays = [player1_display, player2_display, player3_display]

	# Connect signals
	game_manager.player_turn_started.connect(_on_player_turn_started)
	game_manager.boss_turn_started.connect(_on_boss_turn_started)
	game_manager.card_played.connect(_on_card_played)
	game_manager.game_state_changed.connect(_on_game_state_changed)
	game_manager.combat_ended.connect(_on_combat_ended)

	end_turn_button.pressed.connect(_on_end_turn_pressed)

	# Connect character click signals once
	_setup_character_displays()

	update_displays()

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

func _setup_character_displays():
	# Connect click handlers for players
	for i in player_displays.size():
		var display = player_displays[i]
		var player = game_manager.players[i]
		display.gui_input.connect(_on_character_clicked.bind(player))

	# Boss click handler will be connected in update_boss_binding()
	update_boss_binding()

func update_boss_binding():
	# Disconnect old boss binding if it exists
	if boss_display.gui_input.is_connected(_on_character_clicked):
		var connections = boss_display.gui_input.get_connections()
		for connection in connections:
			if connection["signal"].get_name() == "gui_input":
				boss_display.gui_input.disconnect(_on_character_clicked)
				break

	# Connect to current boss
	if game_manager.current_boss:
		boss_display.gui_input.connect(_on_character_clicked.bind(game_manager.current_boss))

	# Update boss visual
	update_boss_visual()

func update_boss_visual():
	# Remove existing boss visual if any
	if boss_visual:
		boss_visual.queue_free()
		boss_visual = null

	# Add boss visual for current boss
	if game_manager.current_boss:
		boss_visual = Node2D.new()
		boss_visual.set_script(load("res://scripts/boss_visuals.gd"))
		boss_visual.position = Vector2(600, 300)  # Position on screen
		add_child(boss_visual)
		boss_visual.set_boss(game_manager.current_boss.character_name)

func _on_player_turn_started(player_index: int):
	current_player = game_manager.players[player_index]
	turn_label.text = "Turn: %s" % current_player.character_name
	update_displays()
	update_hand()
	end_turn_button.disabled = false

func _on_boss_turn_started():
	turn_label.text = "Turn: %s" % game_manager.current_boss.character_name
	end_turn_button.disabled = true
	clear_hand()
	update_boss_binding()  # Reconnect boss click handler for new boss
	update_displays()

func _on_card_played(character: Character, card: Card, target: Character):
	update_displays()
	update_hand()

func _on_game_state_changed():
	update_displays()
	update_hand()

func _on_combat_ended(victory: bool):
	if victory:
		turn_label.text = "VICTORY!"
	else:
		turn_label.text = "DEFEAT!"

	end_turn_button.disabled = true

func update_displays():
	# Update player displays
	for i in game_manager.players.size():
		var player = game_manager.players[i]
		var display = player_displays[i]
		update_character_display(display, player, i == game_manager.current_player_index)

	# Update boss display
	if game_manager.current_boss:
		update_character_display(boss_display, game_manager.current_boss, false)

	# Update top bar
	if current_player:
		energy_label.text = "Energy: %d/%d" % [current_player.current_energy, current_player.max_energy]

	round_label.text = "Round: %d" % game_manager.round_number

func update_character_display(display: Control, character: Character, is_active: bool):
	var name_label = display.get_node_or_null("VBoxContainer/NameLabel")
	var hp_label = display.get_node_or_null("VBoxContainer/HPLabel")
	var status_label = display.get_node_or_null("VBoxContainer/StatusLabel")
	var bg = display.get_node_or_null("Background")

	if name_label:
		name_label.text = character.character_name

	if hp_label:
		hp_label.text = "HP: %d/%d" % [character.current_health, character.max_health]
		if character.shield > 0:
			hp_label.text += " [Shield: %d]" % character.shield

	if status_label:
		var status_text = ""
		if character.strength > 0:
			status_text += "Str +%d " % character.strength
		if character.poison > 0:
			status_text += "Poison %d " % character.poison
		if character.burn > 0:
			status_text += "Burn %d " % character.burn
		if character.vulnerable > 0:
			status_text += "Vuln %d " % character.vulnerable
		if character.armor > 0:
			status_text += "Armor %d " % character.armor
		status_label.text = status_text

	if bg:
		var style = StyleBoxFlat.new()
		if is_active:
			style.bg_color = Color(0.3, 0.5, 0.8)
		elif not character.is_alive():
			style.bg_color = Color(0.3, 0.3, 0.3)
		else:
			style.bg_color = Color(0.2, 0.2, 0.2)
		style.border_color = Color.WHITE
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		bg.add_theme_stylebox_override("panel", style)

func update_hand():
	print("[Combat] update_hand() called")
	if current_player:
		print("[Combat] Player hand size: ", current_player.hand.size())

	clear_hand()

	if not current_player:
		print("[Combat] WARNING: current_player is null!")
		return

	for card in current_player.hand:
		var card_visual = card_scene.instantiate()
		hand_container.add_child(card_visual)

		card_visual.set_card(card)
		card_visual.set_playable(card.can_afford(current_player.current_energy))
		card_visual.card_clicked.connect(_on_card_clicked)

func clear_hand():
	for child in hand_container.get_children():
		child.queue_free()

func _on_card_clicked(card: Card):
	if not current_player:
		return

	if not card.can_afford(current_player.current_energy):
		return

	selected_card = card

	# Check if card needs targeting
	match card.target_type:
		Card.TargetType.SELF:
			# Play immediately on self
			game_manager.play_card(current_player, card, current_player)
			selected_card = null
		Card.TargetType.ALL_ALLIES, Card.TargetType.ALL_ENEMIES:
			# Play immediately, no targeting needed
			game_manager.play_card(current_player, card, game_manager.current_boss)
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
				valid_target = (character == game_manager.current_boss)

		if valid_target:
			game_manager.play_card(current_player, selected_card, character)
			selected_card = null
			awaiting_target = false
			turn_label.text = "Turn: %s" % current_player.character_name

func _on_end_turn_pressed():
	if current_player:
		game_manager.end_player_turn()
		awaiting_target = false
		selected_card = null
