extends Control

var hero_db: Node
var network_manager: Node
var my_selection: int = -1  # -1 = not selected
var all_selections: Dictionary = {}  # peer_id -> hero_index

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
	network_manager = get_node("/root/NetworkManager")

	start_button.pressed.connect(_on_start_pressed)
	start_button.disabled = true
	info_panel.visible = false

	# Add multiplayer status indicator
	var status_label = Label.new()
	status_label.text = "Multiplayer: Each player picks ONE hero"
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", Color(1, 1, 0))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(400, 20)
	add_child(status_label)

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
	# In multiplayer, each player picks ONE hero
	if my_selection == index:
		# Deselect
		my_selection = -1
	else:
		# Select this hero
		my_selection = index

	# Broadcast selection to all clients
	var game_manager = get_node("/root/GameManager")
	if multiplayer.is_server():
		game_manager.rpc("receive_hero_selection", multiplayer.get_unique_id(), my_selection)
	else:
		game_manager.rpc_id(1, "receive_hero_selection", multiplayer.get_unique_id(), my_selection)

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
		if my_selection == i:
			# My selection - green
			button.modulate = Color(0.5, 1.0, 0.5)
		elif is_hero_taken_by_others(i):
			# Taken by another player - red
			button.modulate = Color(1.0, 0.5, 0.5)
			button.disabled = true
		else:
			button.modulate = Color.WHITE
			button.disabled = false

func is_hero_taken_by_others(hero_index: int) -> bool:
	for peer_id in all_selections.keys():
		if peer_id != multiplayer.get_unique_id() and all_selections[peer_id] == hero_index:
			return true
	return false

func update_selected_label():
	var count = all_selections.size()
	var player_count = NetworkManager.players.size()
	selected_label.text = "Players Ready: %d/%d" % [count, player_count]

	# Enable start button only for host when all players selected
	if network_manager.is_host:
		start_button.disabled = (count < player_count)
		start_button.visible = true
	else:
		start_button.visible = false

func on_player_selected_hero(peer_id: int, hero_index: int):
	# Called by GameManager RPC when any player selects a hero
	if hero_index == -1:
		all_selections.erase(peer_id)
	else:
		all_selections[peer_id] = hero_index

	update_hero_buttons()
	update_selected_label()

func _on_start_pressed():
	# Host starts the game - collect all selections
	var selected_heroes: Array[int] = []
	var peer_ids = NetworkManager.players.keys()
	peer_ids.sort()  # Ensure consistent order

	for peer_id in peer_ids:
		if all_selections.has(peer_id):
			selected_heroes.append(all_selections[peer_id])

	if selected_heroes.size() == 3:
		var game_manager = get_node("/root/GameManager")
		# Call select_heroes via RPC so it runs on ALL clients
		game_manager.select_heroes.rpc(selected_heroes)
		network_manager.change_scene_synchronized.rpc("res://scenes/combat.tscn")
