class_name RewardDisplayPanel
extends Panel

## Reusable UI component for displaying reward choices
## Supports cards, heals, buffs, and other reward types

signal choice_selected(choice: RewardChoice)

var _choices: Array[RewardChoice] = []
var _card_scene = preload("res://scenes/card_visual.tscn")

var title_label: Label
var choices_container: HBoxContainer

func _ready():
	# Handle both scene-based and programmatic instantiation
	if has_node("VBoxContainer"):
		# Panel is part of a scene - get references to existing nodes
		title_label = $VBoxContainer/TitleLabel
		choices_container = $VBoxContainer/ChoicesContainer
	else:
		# Panel created programmatically - create UI structure
		_create_ui_structure()

## Setup the panel with title, choices, and interaction state
func setup(title: String, choices: Array[RewardChoice], enabled: bool):
	title_label.text = title
	_choices = choices
	_display_choices()
	set_interaction_enabled(enabled)

## Display all choices in the container
func _display_choices():
	# Clear existing choices
	for child in choices_container.get_children():
		child.queue_free()

	# Create visual for each choice
	for i in range(_choices.size()):
		var choice = _choices[i]

		match choice.choice_type:
			RewardChoice.ChoiceType.CARD:
				_create_card_visual(choice, i)
			RewardChoice.ChoiceType.HEAL, RewardChoice.ChoiceType.BUFF:
				_create_button_visual(choice, i)

## Create a card visual for card-type rewards
func _create_card_visual(choice: RewardChoice, index: int):
	var card_visual = _card_scene.instantiate()
	choices_container.add_child(card_visual)

	card_visual.set_card(choice.card_data)
	card_visual.set_playable(true)

	# Connect signal - note: card_clicked already emits the card, we just need the choice
	card_visual.card_clicked.connect(func(_card): choice_selected.emit(choice))

## Create a button visual for non-card rewards (heal, buff, etc.)
func _create_button_visual(choice: RewardChoice, index: int):
	var button = Button.new()
	button.text = "%s\n%s" % [choice.display_name, choice.description]
	button.custom_minimum_size = Vector2(150, 100)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	choices_container.add_child(button)

	button.pressed.connect(func(): choice_selected.emit(choice))

## Enable or disable interaction with all choices
func set_interaction_enabled(enabled: bool):
	for child in choices_container.get_children():
		if child is Button:
			child.disabled = not enabled
		elif child.has_method("set_playable"):
			child.set_playable(enabled)

		# Also control mouse filter for visual feedback
		if enabled:
			child.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

## Create UI structure programmatically (for manual instantiation)
func _create_ui_structure():
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_top = 10
	vbox.offset_right = -10
	vbox.offset_bottom = -10
	add_child(vbox)

	var title = Label.new()
	title.name = "TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	var hbox = HBoxContainer.new()
	hbox.name = "ChoicesContainer"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)

	title_label = title
	choices_container = hbox
