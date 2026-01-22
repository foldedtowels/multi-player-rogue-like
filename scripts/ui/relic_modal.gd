extends Control
## Relic Modal - Two-phase selection for test mode
## Phase 1: Select a player
## Phase 2: Toggle relics on/off for that player

signal relics_changed(character: Character)
signal restart_requested()

enum Phase { SELECT_TARGET, SELECT_RELIC }

@onready var title_label: Label = $ModalPanel/VBoxContainer/TitleLabel
@onready var description_label: Label = $ModalPanel/VBoxContainer/DescriptionLabel
@onready var list_container: VBoxContainer = $ModalPanel/VBoxContainer/ScrollContainer/ListContainer
@onready var back_button: Button = $ModalPanel/VBoxContainer/ButtonContainer/BackButton
@onready var restart_button: Button = $ModalPanel/VBoxContainer/ButtonContainer/RestartButton
@onready var close_button: Button = $ModalPanel/VBoxContainer/ButtonContainer/CloseButton

var game_manager: Node
var current_phase: Phase = Phase.SELECT_TARGET
var selected_character: Character = null


func _ready():
	game_manager = get_node("/root/GameManager")
	visible = false
	back_button.pressed.connect(_on_back_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	close_button.pressed.connect(_on_close_pressed)


func show_modal():
	current_phase = Phase.SELECT_TARGET
	selected_character = null
	_update_ui()
	visible = true


func _update_ui():
	# Clear previous buttons
	for child in list_container.get_children():
		child.queue_free()

	if current_phase == Phase.SELECT_TARGET:
		_show_target_selection()
	else:
		_show_relic_selection()


func _show_target_selection():
	title_label.text = "Select Character"
	description_label.text = "Choose a player to modify relics:"
	back_button.visible = false
	restart_button.visible = false

	# Add player buttons only (relics are player-only)
	for player in game_manager.players:
		var btn = Button.new()
		var relic_count = player.relics.size()
		btn.text = player.character_name + " (" + str(relic_count) + " relics)"
		btn.custom_minimum_size = Vector2(400, 50)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_target_selected.bind(player))
		list_container.add_child(btn)


func _show_relic_selection():
	title_label.text = "Relics: " + selected_character.character_name
	description_label.text = "Click to toggle relics on/off:"
	back_button.visible = true
	restart_button.visible = true

	# Get character's hero type for filtering relics
	var hero_id = selected_character.hero_id

	# Universal relics
	_add_category_label("UNIVERSAL", Color.WHITE)
	for relic_id in RelicRegistry.get_relics_for_category(RelicRegistry.RelicCategory.UNIVERSAL):
		_add_relic_button(relic_id)

	# Character-specific relics based on hero_id
	if hero_id == "kevin":
		_add_category_label("KEVIN", Color.CYAN)
		for relic_id in RelicRegistry.get_relics_for_category(RelicRegistry.RelicCategory.KEVIN):
			_add_relic_button(relic_id)
	elif hero_id == "fabio":
		_add_category_label("FABIO", Color.ORANGE)
		for relic_id in RelicRegistry.get_relics_for_category(RelicRegistry.RelicCategory.FABIO):
			_add_relic_button(relic_id)
	elif hero_id == "enrique":
		_add_category_label("ENRIQUE", Color.YELLOW)
		for relic_id in RelicRegistry.get_relics_for_category(RelicRegistry.RelicCategory.ENRIQUE):
			_add_relic_button(relic_id)


func _add_category_label(text: String, color: Color):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list_container.add_child(label)


func _add_relic_button(relic_id: String):
	var relic = RelicRegistry.get_relic(relic_id)
	if relic.is_empty():
		return

	var display_name = relic.get("display_name", relic_id.capitalize())
	var description = relic.get("description", "")
	var has_relic = selected_character.has_relic(relic_id)

	var btn = Button.new()
	btn.text = ("[X] " if has_relic else "[ ] ") + display_name
	btn.tooltip_text = description
	btn.custom_minimum_size = Vector2(400, 40)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# Color based on whether relic is active
	if has_relic:
		btn.add_theme_color_override("font_color", Color.GREEN)

	btn.pressed.connect(_on_relic_pressed.bind(relic_id))
	list_container.add_child(btn)


func _on_target_selected(character: Character):
	selected_character = character
	current_phase = Phase.SELECT_RELIC
	_update_ui()


func _on_relic_pressed(relic_id: String):
	if selected_character == null:
		return

	# Toggle relic
	if selected_character.has_relic(relic_id):
		selected_character.remove_relic(relic_id)
		print("[RELIC MODAL] Removed ", relic_id, " from ", selected_character.character_name)
	else:
		selected_character.add_relic(relic_id)
		# Apply ON_PICKUP effects for newly added relic
		RelicRegistry.apply_on_pickup(selected_character, relic_id)
		print("[RELIC MODAL] Added ", relic_id, " to ", selected_character.character_name)

	# Sync state to all clients in multiplayer
	if multiplayer.is_server():
		game_manager.broadcast_character_state(selected_character)

	# Emit game_state_changed to force UI refresh
	game_manager.game_state_changed.emit()

	# Refresh the relic list to show updated state
	_update_ui()

	relics_changed.emit(selected_character)


func _on_back_pressed():
	current_phase = Phase.SELECT_TARGET
	selected_character = null
	_update_ui()


func _on_close_pressed():
	visible = false


func _on_restart_pressed():
	visible = false
	restart_requested.emit()


func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()
