extends Control
## Test Enemy Selection - Host selects enemies for test mode
## Other players see a waiting screen

var network_manager: Node
var game_manager: Node
var minion_db: Node
var boss_db: Node

var selected_enemies: Array[String] = []  # ["minion:minion_1", "boss:boss_0"]
var enemy_buttons: Array[Button] = []

# UI created dynamically
var title_label: Label
var enemy_container: GridContainer
var selected_label: Label
var start_button: Button
var waiting_label: Label
var back_button: Button

func _ready():
	network_manager = get_node("/root/NetworkManager")
	game_manager = get_node("/root/GameManager")
	minion_db = get_node("/root/MinionDatabase")
	boss_db = get_node("/root/BossDatabase")

	_create_ui()

	if network_manager.is_host:
		_create_enemy_buttons()
		start_button.visible = true
		waiting_label.visible = false
	else:
		# Clients just wait
		enemy_container.visible = false
		start_button.visible = false
		waiting_label.visible = true

func _create_ui():
	# Main VBox container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.set_anchor_and_offset(SIDE_LEFT, 0, 50)
	vbox.set_anchor_and_offset(SIDE_RIGHT, 1, -50)
	vbox.set_anchor_and_offset(SIDE_TOP, 0, 50)
	vbox.set_anchor_and_offset(SIDE_BOTTOM, 1, -50)
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)

	# Title
	title_label = Label.new()
	title_label.text = "TEST MODE: Select Enemies"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(title_label)

	# Waiting label (for clients)
	waiting_label = Label.new()
	waiting_label.text = "Waiting for host to select enemies..."
	waiting_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waiting_label.add_theme_font_size_override("font_size", 24)
	waiting_label.visible = false
	vbox.add_child(waiting_label)

	# Scroll container for enemy grid
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	# Enemy grid container
	enemy_container = GridContainer.new()
	enemy_container.columns = 4
	enemy_container.add_theme_constant_override("h_separation", 10)
	enemy_container.add_theme_constant_override("v_separation", 10)
	scroll.add_child(enemy_container)

	# Selected enemies label
	selected_label = Label.new()
	selected_label.text = "Selected: 0/3 enemies"
	selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(selected_label)

	# Button row
	var button_row = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 30)
	vbox.add_child(button_row)

	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(150, 50)
	back_button.pressed.connect(_on_back_pressed)
	button_row.add_child(back_button)

	start_button = Button.new()
	start_button.text = "Start Test"
	start_button.custom_minimum_size = Vector2(200, 50)
	start_button.pressed.connect(_on_start_test_pressed)
	start_button.disabled = true
	button_row.add_child(start_button)

func _create_enemy_buttons():
	# Add section label for minions
	var minion_label = Label.new()
	minion_label.text = "--- MINIONS ---"
	minion_label.add_theme_font_size_override("font_size", 18)
	minion_label.add_theme_color_override("font_color", Color.ORANGE)
	enemy_container.add_child(minion_label)

	# Add spacers for grid alignment
	for i in range(3):
		var spacer = Control.new()
		enemy_container.add_child(spacer)

	# Add minion buttons
	var minions_data = preload("res://scripts/minions_data.gd").new()
	for minion_id in minions_data.MINIONS.keys():
		var minion_data = minions_data.MINIONS[minion_id]
		var button = Button.new()
		button.text = minion_data.name
		button.custom_minimum_size = Vector2(180, 60)
		button.toggle_mode = true
		button.pressed.connect(_on_enemy_button_pressed.bind("minion:" + minion_id, button))
		enemy_container.add_child(button)
		enemy_buttons.append(button)

	# Add section label for bosses
	var boss_label = Label.new()
	boss_label.text = "--- BOSSES ---"
	boss_label.add_theme_font_size_override("font_size", 18)
	boss_label.add_theme_color_override("font_color", Color.RED)
	enemy_container.add_child(boss_label)

	# Add spacers for grid alignment
	for i in range(3):
		var spacer = Control.new()
		enemy_container.add_child(spacer)

	# Add boss buttons
	boss_db.create_boss_cards()  # Ensure boss cards exist
	for boss_id in BossesData.BOSSES.keys():
		var boss_data = BossesData.BOSSES[boss_id]
		var button = Button.new()
		button.text = boss_data.name
		button.custom_minimum_size = Vector2(180, 60)
		button.toggle_mode = true
		button.pressed.connect(_on_enemy_button_pressed.bind("boss:" + boss_id, button))
		enemy_container.add_child(button)
		enemy_buttons.append(button)

func _on_enemy_button_pressed(enemy_id: String, button: Button):
	if enemy_id in selected_enemies:
		# Deselect
		selected_enemies.erase(enemy_id)
		button.button_pressed = false
		button.modulate = Color.WHITE
	else:
		# Select if under limit
		if selected_enemies.size() < 3:
			selected_enemies.append(enemy_id)
			button.button_pressed = true
			button.modulate = Color(0.5, 1.0, 0.5)  # Green
		else:
			# At limit, unpress
			button.button_pressed = false

	_update_selected_label()

func _update_selected_label():
	selected_label.text = "Selected: %d/3 enemies" % selected_enemies.size()
	start_button.disabled = selected_enemies.size() == 0

func _on_back_pressed():
	# Go back to character selection
	network_manager.change_scene_synchronized.rpc("res://scenes/character_selection.tscn")

func _on_start_test_pressed():
	if not network_manager.is_host:
		return

	if selected_enemies.size() == 0:
		return

	# Initialize test encounter on all clients
	game_manager.initialize_test_encounter.rpc(selected_enemies)

	# Go to regular combat scene (with test mode active)
	network_manager.change_scene_synchronized.rpc("res://scenes/combat.tscn")
