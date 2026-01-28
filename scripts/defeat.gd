extends Control

## Defeat screen shown when all players die

var game_manager: Node

func _ready():
	game_manager = get_node_or_null("/root/GameManager")

	# Set up the UI
	_setup_ui()

func _setup_ui():
	# Background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.15, 0.05, 0.05, 1)  # Dark red tint
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Main container
	var container = VBoxContainer.new()
	container.name = "MainContainer"
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.offset_left = -300
	container.offset_right = 300
	container.offset_top = -200
	container.offset_bottom = 200
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(container)

	# Defeat title
	var title = Label.new()
	title.name = "DefeatTitle"
	title.text = "DEFEAT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	container.add_child(title)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 30)
	container.add_child(spacer1)

	# Message
	var message = Label.new()
	message.name = "DefeatMessage"
	message.text = "Your party has fallen..."
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 24)
	message.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	container.add_child(message)

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 50)
	container.add_child(spacer2)

	# Boss progress info
	if game_manager:
		var progress = Label.new()
		progress.name = "ProgressLabel"
		var boss_idx = game_manager.boss_index
		progress.text = "Bosses Defeated: %d / 5" % boss_idx
		progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		progress.add_theme_font_size_override("font_size", 18)
		progress.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		container.add_child(progress)

		# Spacer
		var spacer3 = Control.new()
		spacer3.custom_minimum_size = Vector2(0, 30)
		container.add_child(spacer3)

	# Return to menu button (host-only to ensure synchronized transition)
	var button = Button.new()
	button.name = "ReturnButton"
	button.custom_minimum_size = Vector2(250, 50)
	button.pressed.connect(_on_return_pressed)
	if multiplayer.is_server():
		button.text = "Return to Main Menu"
	else:
		button.text = "Waiting for host..."
		button.disabled = true
	container.add_child(button)

func _on_return_pressed():
	if not multiplayer.is_server():
		return

	# Reset game state
	if game_manager:
		game_manager.current_state = game_manager.GameState.CHARACTER_SELECTION
		game_manager.boss_index = 0
		game_manager.round_number = 1
		game_manager.players.clear()
		game_manager.enemies.clear()

	var network_manager = get_node_or_null("/root/NetworkManager")
	if network_manager:
		network_manager.change_scene_synchronized.rpc("res://scenes/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
