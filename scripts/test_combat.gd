extends Control
## Test Combat - Special combat scene for testing cards and characters
## Features:
## - All cards (main deck + reward deck) in hand
## - Two-row card display for many cards
## - Kill All Enemies button
## - Escape menu to switch characters/enemies
## - 1000 HP for all characters

var game_manager: Node
var hero_db: Node
var card_db: Node
var current_player: Character
var player_status_panel: PlayerStatusPanel
var enemy_panel_cache: Dictionary = {}

# Test Mode State
var test_mode_paused: bool = false

# UI References
@onready var left_player_panel: Panel = $MainArea/LeftPlayerPanel
@onready var right_player_panel: Panel = $MainArea/RightPlayerPanel
@onready var your_character_panel: Panel = $BottomArea/YourCharacterPanel
@onready var enemy_displays_container: HBoxContainer = $MainArea/CenterArea/EnemyDisplays
@onready var hand_row1: HBoxContainer = $BottomArea/HandPanel/HandRow1
@onready var hand_row2: HBoxContainer = $BottomArea/HandPanel/HandRow2
@onready var turn_label: Label = $TopBar/TurnLabel
@onready var stamina_label: Label = $TopBar/StaminaLabel
@onready var round_label: Label = $TopBar/RoundLabel
@onready var kill_enemies_button: Button = $TopBar/KillEnemiesButton
@onready var end_turn_button: Button = $BottomArea/YourCharacterPanel/HBoxContainer/EndTurnButton
@onready var escape_menu: Panel = $EscapeMenu

var card_scene = preload("res://scenes/card_visual.tscn")

func _ready():
	game_manager = get_node("/root/GameManager")
	hero_db = get_node("/root/HeroDatabase")
	card_db = get_node("/root/CardDatabase")

	# This node must process input even when paused (for Escape key)
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Create player status panel component
	player_status_panel = PlayerStatusPanel.new()
	add_child(player_status_panel)
	player_status_panel.setup(game_manager, left_player_panel, right_player_panel, your_character_panel)
	player_status_panel.panel_clicked.connect(_on_character_clicked)

	# Connect signals
	game_manager.game_state_changed.connect(_on_game_state_changed)
	game_manager.card_played.connect(_on_card_played)
	game_manager.enemy_damaged_player.connect(_on_enemy_damaged_player)

	# Connect buttons
	kill_enemies_button.pressed.connect(_on_kill_enemies_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	# Setup escape menu - must process when paused
	escape_menu.visible = false
	escape_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	var back_to_setup_btn = escape_menu.get_node("VBoxContainer/BackToSetupButton")
	var resume_btn = escape_menu.get_node("VBoxContainer/ResumeButton")
	var quit_btn = escape_menu.get_node("VBoxContainer/QuitButton")
	back_to_setup_btn.pressed.connect(_on_back_to_setup)
	resume_btn.pressed.connect(_on_resume)
	quit_btn.pressed.connect(_on_quit)

	# Setup drop zones for targeting
	_setup_drop_zones()

	# Initialize test combat
	_setup_test_combat()

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # Escape key
		test_mode_paused = not test_mode_paused
		escape_menu.visible = test_mode_paused
		get_tree().paused = test_mode_paused

func _setup_test_combat():
	# Set local player
	current_player = game_manager.players[game_manager.local_player_index]

	# Give all players ALL their cards (main deck + reward deck)
	for player in game_manager.players:
		_give_all_cards_to_player(player)

	# Start player turn
	game_manager.turn_phase = GameManager.TurnPhase.PLAYER_TURN
	for player in game_manager.players:
		player.current_stamina = 999  # Unlimited stamina for testing

	# Update displays
	_update_all_displays()

func _give_all_cards_to_player(player: Character):
	player.hand.clear()
	player.deck.clear()
	player.discard_pile.clear()

	# Get hero's main deck cards
	var hero_id = player.hero_id if player.hero_id else ""
	if hero_id == "":
		# Try to match by name
		for hid in HeroesData.HEROES.keys():
			if HeroesData.HEROES[hid].name == player.character_name:
				hero_id = hid
				break

	if hero_id != "" and HeroesData.HEROES.has(hero_id):
		var hero_data = HeroesData.HEROES[hero_id]

		# Add main deck cards
		for card_id in hero_data.deck:
			var card = card_db.get_card(card_id)
			if card:
				player.hand.append(card.duplicate())

		# Add reward deck cards if they exist
		if hero_data.has("reward_deck"):
			for card_id in hero_data.reward_deck:
				var card = card_db.get_card(card_id)
				if card:
					player.hand.append(card.duplicate())

	# Remove duplicates by card name (keep one of each)
	var unique_cards: Array[Card] = []
	var seen_names: Array[String] = []
	for card in player.hand:
		if card.card_name not in seen_names:
			seen_names.append(card.card_name)
			unique_cards.append(card)
	player.hand = unique_cards

func _update_all_displays():
	_display_hand()
	_update_enemy_displays()
	player_status_panel.update_all()
	_update_top_bar()

func _display_hand():
	# Clear existing cards
	for child in hand_row1.get_children():
		child.queue_free()
	for child in hand_row2.get_children():
		child.queue_free()

	var hand = current_player.hand
	var cards_per_row = (hand.size() + 1) / 2  # Split roughly in half

	for i in hand.size():
		var card = hand[i]
		var card_visual = card_scene.instantiate()

		# Add to row 1 or row 2
		if i < cards_per_row:
			hand_row1.add_child(card_visual)
		else:
			hand_row2.add_child(card_visual)

		card_visual.set_card(card)
		card_visual.set_playable(true)
		card_visual.scale = Vector2(0.6, 0.6)  # Smaller cards to fit more

		# Connect click for playing (signal already passes the card)
		card_visual.card_clicked.connect(_on_card_clicked)

func _update_enemy_displays():
	# Clear old panels
	for child in enemy_displays_container.get_children():
		child.queue_free()
	enemy_panel_cache.clear()

	for i in game_manager.enemies.size():
		var enemy = game_manager.enemies[i]
		var panel = _create_enemy_panel(enemy, i)
		enemy_displays_container.add_child(panel)
		enemy_panel_cache[i] = panel

func _create_enemy_panel(enemy: Character, index: int) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(200, 250)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.4, 0.2, 0.2) if enemy.is_alive() else Color(0.2, 0.2, 0.2)
	style.border_color = Color.RED
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	var name_label = Label.new()
	name_label.text = enemy.character_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)

	var hp_label = Label.new()
	hp_label.text = "HP: %d/%d" % [enemy.current_health, enemy.max_health]
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hp_label)

	if enemy.shield > 0:
		var shield_label = Label.new()
		shield_label.text = "Shield: %d" % enemy.shield
		shield_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shield_label.add_theme_color_override("font_color", Color.CYAN)
		vbox.add_child(shield_label)

	# Make panel a drop target
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_enemy_panel_input.bind(enemy))

	return panel

func _update_top_bar():
	turn_label.text = "Test Mode - " + current_player.character_name
	stamina_label.text = "Stamina: %d" % current_player.current_stamina
	round_label.text = "Round: %d" % game_manager.round_number

func _setup_drop_zones():
	# Setup enemy panels as drop targets
	pass  # Handled in _create_enemy_panel

func _on_card_clicked(card: Card):
	# For self/all target cards, play immediately
	if card.target_type == Card.TargetType.SELF:
		_play_card(card, current_player)
	elif card.target_type == Card.TargetType.ALL_ENEMIES:
		if game_manager.enemies.size() > 0:
			_play_card(card, game_manager.enemies[0])
	elif card.target_type == Card.TargetType.ALL_ALLIES:
		_play_card(card, current_player)
	# Other cards need targeting - show prompt
	else:
		turn_label.text = "Click an enemy to target with " + card.card_name
		# Store card for targeting
		set_meta("pending_card", card)

func _on_enemy_panel_input(event: InputEvent, enemy: Character):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pending_card = get_meta("pending_card") if has_meta("pending_card") else null
		if pending_card:
			_play_card(pending_card, enemy)
			remove_meta("pending_card")

func _on_character_clicked(event: InputEvent, character: Character):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pending_card = get_meta("pending_card") if has_meta("pending_card") else null
		if pending_card:
			_play_card(pending_card, character)
			remove_meta("pending_card")

func _play_card(card: Card, target: Character):
	if current_player.current_stamina < card.stamina_cost:
		turn_label.text = "Not enough stamina!"
		return

	game_manager.play_card(current_player, card, target)
	_update_all_displays()

func _on_kill_enemies_pressed():
	for enemy in game_manager.enemies:
		enemy.current_health = 0
	_update_all_displays()
	turn_label.text = "All enemies killed!"

func _on_end_turn_pressed():
	# Reset stamina and refresh hand
	current_player.current_stamina = 999
	_give_all_cards_to_player(current_player)
	game_manager.round_number += 1

	# Enemy turn (simple version - enemies attack)
	for enemy in game_manager.enemies:
		if enemy.is_alive():
			enemy.current_stamina = enemy.max_stamina

	_update_all_displays()

func _on_game_state_changed():
	_update_all_displays()

func _on_card_played(caster: Character, card: Card, target: Character):
	_update_all_displays()

func _on_enemy_damaged_player(enemy_name: String, card_name: String, damage: int, target_idx: int):
	_update_all_displays()

func _on_back_to_setup():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/test_mode_setup.tscn")

func _on_resume():
	test_mode_paused = false
	escape_menu.visible = false
	get_tree().paused = false

func _on_quit():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
