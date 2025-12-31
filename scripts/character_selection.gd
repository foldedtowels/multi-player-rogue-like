extends Control

var hero_db: Node
var selected_heroes: Array[int] = []
var hero_buttons: Array[Button] = []

@onready var hero_container: HBoxContainer = $VBoxContainer/HeroContainer
@onready var selected_label: Label = $VBoxContainer/SelectedLabel
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var info_panel: Panel = $InfoPanel
@onready var info_name: Label = $InfoPanel/VBoxContainer/NameLabel
@onready var info_description: Label = $InfoPanel/VBoxContainer/DescriptionLabel
@onready var info_stats: Label = $InfoPanel/VBoxContainer/StatsLabel

func _ready():
	hero_db = get_node("/root/HeroDatabase")
	start_button.pressed.connect(_on_start_pressed)
	start_button.disabled = true
	info_panel.visible = false

	create_hero_buttons()
	update_selected_label()

func create_hero_buttons():
	var heroes = hero_db.get_all_heroes()

	for i in heroes.size():
		var hero = heroes[i]
		var button = Button.new()
		button.text = hero.character_name
		button.custom_minimum_size = Vector2(250, 120)
		button.pressed.connect(_on_hero_button_pressed.bind(i))
		button.mouse_entered.connect(_on_hero_button_hovered.bind(i))

		hero_container.add_child(button)
		hero_buttons.append(button)

func _on_hero_button_pressed(index: int):
	if selected_heroes.has(index):
		# Deselect
		selected_heroes.erase(index)
	else:
		# Select if less than 3
		if selected_heroes.size() < 3:
			selected_heroes.append(index)

	update_hero_buttons()
	update_selected_label()

func _on_hero_button_hovered(index: int):
	var heroes = hero_db.get_all_heroes()
	var hero = heroes[index]

	info_panel.visible = true
	info_name.text = hero.character_name
	info_description.text = hero.description
	info_stats.text = "HP: %d | Energy: %d | Deck Size: %d" % [
		hero.max_health,
		hero.starting_energy,
		hero.starting_deck.size()
	]

func update_hero_buttons():
	for i in hero_buttons.size():
		var button = hero_buttons[i]
		if selected_heroes.has(i):
			button.modulate = Color(0.5, 1.0, 0.5)
		else:
			button.modulate = Color.WHITE

		# Disable if 3 already selected and this isn't one of them
		if selected_heroes.size() >= 3 and not selected_heroes.has(i):
			button.disabled = true
		else:
			button.disabled = false

func update_selected_label():
	selected_label.text = "Selected Heroes: %d/3" % selected_heroes.size()
	start_button.disabled = (selected_heroes.size() != 3)

func _on_start_pressed():
	if selected_heroes.size() == 3:
		var game_manager = get_node("/root/GameManager")
		game_manager.select_heroes(selected_heroes)
		get_tree().change_scene_to_file("res://scenes/combat.tscn")
