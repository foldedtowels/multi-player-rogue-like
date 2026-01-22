extends Control
## Buff/Debuff Modal - Two-phase selection for test mode
## Phase 1: Select a player or enemy
## Phase 2: Click effects to add +1 stack each

signal effects_applied(character: Character)

enum Phase { SELECT_TARGET, SELECT_EFFECT }

@onready var title_label: Label = $ModalPanel/VBoxContainer/TitleLabel
@onready var description_label: Label = $ModalPanel/VBoxContainer/DescriptionLabel
@onready var list_container: VBoxContainer = $ModalPanel/VBoxContainer/ScrollContainer/ListContainer
@onready var back_button: Button = $ModalPanel/VBoxContainer/ButtonContainer/BackButton
@onready var close_button: Button = $ModalPanel/VBoxContainer/ButtonContainer/CloseButton

var game_manager: Node
var current_phase: Phase = Phase.SELECT_TARGET
var selected_character: Character = null


func _ready():
	game_manager = get_node("/root/GameManager")
	visible = false
	back_button.pressed.connect(_on_back_pressed)
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
		_show_effect_selection()


func _show_target_selection():
	title_label.text = "Select Character"
	description_label.text = "Choose a player or enemy to modify:"
	back_button.visible = false

	# Add player buttons
	for player in game_manager.players:
		var btn = Button.new()
		btn.text = player.character_name
		btn.custom_minimum_size = Vector2(400, 50)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_target_selected.bind(player))
		list_container.add_child(btn)

	# Add enemy buttons
	for enemy in game_manager.enemies:
		var btn = Button.new()
		btn.text = "[Enemy] " + enemy.character_name
		btn.custom_minimum_size = Vector2(400, 50)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_target_selected.bind(enemy))
		list_container.add_child(btn)


func _show_effect_selection():
	title_label.text = "Modify: " + selected_character.character_name
	description_label.text = "Click to add +1 stack:"
	back_button.visible = true

	# Add buff buttons
	var buffs_label = Label.new()
	buffs_label.text = "BUFFS"
	buffs_label.add_theme_font_size_override("font_size", 16)
	buffs_label.add_theme_color_override("font_color", Color.GREEN)
	buffs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list_container.add_child(buffs_label)

	for effect_name in StatusEffectRegistry.get_buff_effect_names():
		var data = StatusEffectRegistry.get_effect_data(effect_name)
		var display_name = data.get("display_name", effect_name.capitalize())
		var symbol = data.get("symbol", "")
		var btn = Button.new()
		btn.text = symbol + " " + display_name + " +1"
		btn.custom_minimum_size = Vector2(400, 40)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_effect_pressed.bind(effect_name))
		list_container.add_child(btn)

	# Add debuff buttons
	var debuffs_label = Label.new()
	debuffs_label.text = "DEBUFFS"
	debuffs_label.add_theme_font_size_override("font_size", 16)
	debuffs_label.add_theme_color_override("font_color", Color.RED)
	debuffs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list_container.add_child(debuffs_label)

	for effect_name in StatusEffectRegistry.get_debuff_effect_names():
		var data = StatusEffectRegistry.get_effect_data(effect_name)
		var display_name = data.get("display_name", effect_name.capitalize())
		var symbol = data.get("symbol", "")
		var btn = Button.new()
		btn.text = symbol + " " + display_name + " +1"
		btn.custom_minimum_size = Vector2(400, 40)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_effect_pressed.bind(effect_name))
		list_container.add_child(btn)


func _on_target_selected(character: Character):
	selected_character = character
	current_phase = Phase.SELECT_EFFECT
	_update_ui()


func _on_effect_pressed(effect_name: String):
	if selected_character == null:
		return

	# Use set_effect_amount directly (Object.set() doesn't work with computed properties)
	var current = selected_character.status_effects.get(effect_name, 0)
	selected_character.set_effect_amount(effect_name, current + 1)

	print("[BUFF/DEBUFF] +1 ", effect_name, " to ", selected_character.character_name)

	# Recalculate enemy intents if damage-affecting debuff applied to enemy
	if game_manager.enemies.has(selected_character) and effect_name in ["weakness", "hinder"]:
		game_manager.recalculate_enemy_intents()

	# Sync state to all clients in multiplayer
	if multiplayer.is_server():
		game_manager.broadcast_character_state(selected_character)

	# Emit game_state_changed to force UI refresh on all panels
	game_manager.game_state_changed.emit()

	effects_applied.emit(selected_character)


func _on_back_pressed():
	current_phase = Phase.SELECT_TARGET
	selected_character = null
	_update_ui()


func _on_close_pressed():
	visible = false


func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()
