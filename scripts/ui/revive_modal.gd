extends Control
## Revive Modal - Select a dead teammate to revive
## Shows list of dead players and allows selection for revival

signal teammate_selected(teammate: Character)
signal cancelled()

@onready var title_label: Label = $ModalPanel/VBoxContainer/TitleLabel
@onready var description_label: Label = $ModalPanel/VBoxContainer/DescriptionLabel
@onready var list_container: VBoxContainer = $ModalPanel/VBoxContainer/ScrollContainer/ListContainer
@onready var close_button: Button = $ModalPanel/VBoxContainer/ButtonContainer/CloseButton

var game_manager: Node
var caster: Character = null
var dead_teammates: Array[Character] = []


func _ready():
	game_manager = get_node("/root/GameManager")
	visible = false
	close_button.pressed.connect(_on_close_pressed)


## Show the modal for selecting a dead teammate to revive
## Returns false if no dead teammates exist
func show_revive_selection(revive_caster: Character) -> bool:
	caster = revive_caster
	dead_teammates.clear()

	# Find dead teammates (excluding the caster)
	for player in game_manager.players:
		if player != caster and not player.is_alive():
			dead_teammates.append(player)

	if dead_teammates.is_empty():
		print("[REVIVE MODAL] No dead teammates to revive")
		return false

	_update_ui()
	visible = true
	return true


func _update_ui():
	title_label.text = "Revive Teammate"
	description_label.text = "Select a dead teammate to revive (50% HP):"

	# Clear previous buttons
	for child in list_container.get_children():
		child.queue_free()

	# Add button for each dead teammate
	for teammate in dead_teammates:
		var btn = Button.new()
		btn.text = "%s (was %d/%d HP)" % [teammate.character_name, 0, teammate.max_health]
		btn.custom_minimum_size = Vector2(300, 50)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.add_theme_font_size_override("font_size", 16)

		# Green styling for revive option
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.4, 0.2)  # Dark green
		style.border_color = Color(0.4, 0.8, 0.4)  # Light green border
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
		btn.add_theme_stylebox_override("normal", style)

		# Hover style
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.3, 0.5, 0.3)  # Brighter green
		hover_style.border_color = Color(0.5, 1.0, 0.5)  # Bright green
		hover_style.border_width_left = 2
		hover_style.border_width_right = 2
		hover_style.border_width_top = 2
		hover_style.border_width_bottom = 2
		hover_style.corner_radius_top_left = 5
		hover_style.corner_radius_top_right = 5
		hover_style.corner_radius_bottom_left = 5
		hover_style.corner_radius_bottom_right = 5
		btn.add_theme_stylebox_override("hover", hover_style)

		btn.pressed.connect(_on_teammate_selected.bind(teammate))
		list_container.add_child(btn)

	# If no dead teammates, show message
	if dead_teammates.is_empty():
		var no_targets_label = Label.new()
		no_targets_label.text = "No dead teammates to revive."
		no_targets_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_targets_label.add_theme_font_size_override("font_size", 16)
		no_targets_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		list_container.add_child(no_targets_label)


func _on_teammate_selected(teammate: Character):
	print("[REVIVE MODAL] Selected teammate: ", teammate.character_name)
	visible = false
	teammate_selected.emit(teammate)


func _on_close_pressed():
	visible = false
	cancelled.emit()


func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		visible = false
		cancelled.emit()
		get_viewport().set_input_as_handled()
