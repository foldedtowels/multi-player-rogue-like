extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var multiplayer_button: Button = $VBoxContainer/MultiplayerButton
@onready var test_mode_button: Button = $VBoxContainer/TestModeButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_pressed)
	test_mode_button.pressed.connect(_on_test_mode_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/character_selection.tscn")

func _on_multiplayer_pressed():
	# Clear test mode flag for regular multiplayer
	var game_manager = get_node("/root/GameManager")
	if game_manager.has_meta("test_mode"):
		game_manager.remove_meta("test_mode")
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_test_mode_pressed():
	# Set test mode flag and go to lobby (multiplayer test mode)
	var game_manager = get_node("/root/GameManager")
	game_manager.set_meta("test_mode", true)
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_quit_pressed():
	get_tree().quit()
