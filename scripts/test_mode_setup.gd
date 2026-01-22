extends Control
## Test Mode Setup - Select players, enemies, and test settings

# Preload data classes
const EnemiesData = preload("res://scripts/data/enemies_data.gd")

var hero_db: Node
var minion_db: Node
var boss_db: Node

# Selections
var selected_heroes: Array[int] = []  # Which heroes are selected (indices)
var selected_enemies: Array[String] = []  # Which enemies are selected (minion/boss IDs)
var player_count: int = 3  # 1-3 players (default to 3 for test mode)
var is_solo_mode: bool = true  # Solo or multiplayer

# UI Elements
var hero_buttons: Array[Button] = []
var enemy_buttons: Array[Button] = []

@onready var hero_container: GridContainer = $VBoxContainer/HeroSection/HeroContainer
@onready var enemy_container: GridContainer = $VBoxContainer/EnemySection/EnemyContainer
@onready var player_count_label: Label = $VBoxContainer/SettingsSection/PlayerCountLabel
@onready var player_count_slider: HSlider = $VBoxContainer/SettingsSection/PlayerCountSlider
@onready var solo_check: CheckButton = $VBoxContainer/SettingsSection/SoloModeCheck
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var info_label: Label = $VBoxContainer/InfoLabel

func _ready():
	hero_db = get_node("/root/HeroDatabase")
	minion_db = get_node("/root/MinionDatabase")
	boss_db = get_node("/root/BossDatabase")

	# Connect UI signals
	player_count_slider.value_changed.connect(_on_player_count_changed)
	solo_check.toggled.connect(_on_solo_mode_toggled)
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Initialize
	player_count_slider.value = 3  # Default to 3 players for test mode
	solo_check.button_pressed = true

	_create_hero_buttons()
	_create_enemy_buttons()
	_update_ui()

func _create_hero_buttons():
	var heroes = hero_db.get_all_heroes()

	for i in heroes.size():
		var hero = heroes[i]
		var button = Button.new()
		button.text = hero.character_name
		button.custom_minimum_size = Vector2(180, 60)
		button.toggle_mode = true
		button.pressed.connect(_on_hero_button_pressed.bind(i))

		hero_container.add_child(button)
		hero_buttons.append(button)

func _create_enemy_buttons():
	# Add minions from all bosses (0-4)
	for minion_id in EnemiesData.MINIONS.keys():
		var minion_data = EnemiesData.MINIONS[minion_id]
		var button = Button.new()
		button.text = minion_data.name + "\n(Minion)"
		button.custom_minimum_size = Vector2(150, 60)
		button.toggle_mode = true
		button.pressed.connect(_on_enemy_button_pressed.bind("minion:" + minion_id))

		enemy_container.add_child(button)
		enemy_buttons.append(button)

	# Add bosses
	for boss_id in EnemiesData.BOSSES.keys():
		var boss_data = EnemiesData.BOSSES[boss_id]
		var button = Button.new()
		button.text = boss_data.name + "\n(Boss)"
		button.custom_minimum_size = Vector2(150, 60)
		button.toggle_mode = true
		button.pressed.connect(_on_enemy_button_pressed.bind("boss:" + boss_id))

		enemy_container.add_child(button)
		enemy_buttons.append(button)

func _on_hero_button_pressed(index: int):
	if index in selected_heroes:
		selected_heroes.erase(index)
		hero_buttons[index].button_pressed = false
	else:
		if selected_heroes.size() < player_count:
			selected_heroes.append(index)
			hero_buttons[index].button_pressed = true
		else:
			# Already at max, unpress
			hero_buttons[index].button_pressed = false

	_update_ui()

func _on_enemy_button_pressed(enemy_id: String):
	var button_idx = -1
	for i in enemy_buttons.size():
		# Find which button was pressed
		if enemy_buttons[i].button_pressed:
			var minion_ids = EnemiesData.MINIONS.keys()
			if i < minion_ids.size():
				var check_id = "minion:" + minion_ids[i]
				if check_id == enemy_id:
					button_idx = i
					break
			else:
				var boss_ids = EnemiesData.BOSSES.keys()
				var boss_idx = i - minion_ids.size()
				if boss_idx < boss_ids.size():
					var check_id = "boss:" + boss_ids[boss_idx]
					if check_id == enemy_id:
						button_idx = i
						break

	if enemy_id in selected_enemies:
		selected_enemies.erase(enemy_id)
	else:
		if selected_enemies.size() < 3:  # Max 3 enemies
			selected_enemies.append(enemy_id)

	# Update button states
	_sync_enemy_buttons()
	_update_ui()

func _sync_enemy_buttons():
	var minion_ids = EnemiesData.MINIONS.keys()
	var boss_ids = EnemiesData.BOSSES.keys()

	for i in enemy_buttons.size():
		var enemy_id = ""
		if i < minion_ids.size():
			enemy_id = "minion:" + minion_ids[i]
		else:
			var boss_idx = i - minion_ids.size()
			if boss_idx < boss_ids.size():
				enemy_id = "boss:" + boss_ids[boss_idx]

		enemy_buttons[i].button_pressed = enemy_id in selected_enemies

func _on_player_count_changed(value: float):
	player_count = int(value)
	player_count_label.text = "Players: %d" % player_count

	# Trim selected heroes if needed
	while selected_heroes.size() > player_count:
		var removed = selected_heroes.pop_back()
		hero_buttons[removed].button_pressed = false

	_update_ui()

func _on_solo_mode_toggled(pressed: bool):
	is_solo_mode = pressed
	_update_ui()

func _update_ui():
	var heroes_ok = selected_heroes.size() == player_count
	var enemies_ok = selected_enemies.size() > 0

	start_button.disabled = not (heroes_ok and enemies_ok)

	var mode_str = "Solo" if is_solo_mode else "Multiplayer"
	info_label.text = "Mode: %s | Heroes: %d/%d | Enemies: %d/3" % [
		mode_str, selected_heroes.size(), player_count, selected_enemies.size()
	]

func _on_start_pressed():
	# Store test mode settings in GameManager
	var game_manager = get_node("/root/GameManager")
	game_manager.set_meta("test_mode", true)
	game_manager.set_meta("test_mode_heroes", selected_heroes.duplicate())
	game_manager.set_meta("test_mode_enemies", selected_enemies.duplicate())
	game_manager.set_meta("test_mode_solo", is_solo_mode)
	game_manager.set_meta("test_mode_player_count", player_count)

	if is_solo_mode:
		# Start directly
		_start_test_combat()
	else:
		# Go to lobby for multiplayer
		get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _start_test_combat():
	var game_manager = get_node("/root/GameManager")

	# Create heroes with test mode settings
	game_manager.players.clear()
	var all_heroes = hero_db.get_all_heroes()

	for hero_idx in selected_heroes:
		var hero = all_heroes[hero_idx].duplicate_character()
		hero.max_health = 100
		hero.current_health = 100
		game_manager.players.append(hero)

	# Set local player index for solo
	game_manager.local_player_index = 0

	# Create enemies
	game_manager.enemies.clear()

	for enemy_id in selected_enemies:
		var parts = enemy_id.split(":")
		var enemy_type = parts[0]
		var id = parts[1]

		if enemy_type == "minion":
			var enemy = minion_db.create_minion_by_id(id)
			if enemy:
				enemy.max_health = 100
				enemy.current_health = 100
				game_manager.enemies.append(enemy)
		else:  # boss
			var enemy = boss_db.create_boss_by_id(id)
			if enemy:
				enemy.max_health = 100
				enemy.current_health = 100
				game_manager.enemies.append(enemy)

	# Set game state
	game_manager.current_state = GameManager.GameState.COMBAT
	game_manager.turn_phase = GameManager.TurnPhase.PLAYER_TURN
	game_manager.round_number = 1

	# Initialize RNG
	game_manager.game_seed = randi()
	game_manager.rng.seed = game_manager.game_seed

	# Go to test combat scene
	get_tree().change_scene_to_file("res://scenes/test_combat.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
