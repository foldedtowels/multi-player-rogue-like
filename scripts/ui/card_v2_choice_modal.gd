extends Control
## Modal for choosing between v1 and v2 card effects
##
## When a player plays a card with has_v2 = true, this modal appears
## showing both effects. The player clicks one to proceed with that version.

signal choice_made(chosen_card: Card)

@onready var modal_panel: Panel = $ModalPanel
@onready var title_label: Label = $ModalPanel/VBoxContainer/TitleLabel
@onready var v1_container: VBoxContainer = $ModalPanel/VBoxContainer/V1Container
@onready var v1_name_label: Label = $ModalPanel/VBoxContainer/V1Container/NameLabel
@onready var v1_description_label: Label = $ModalPanel/VBoxContainer/V1Container/DescriptionLabel
@onready var v1_button: Button = $ModalPanel/VBoxContainer/V1Container/ChooseButton

@onready var v2_container: VBoxContainer = $ModalPanel/VBoxContainer/V2Container
@onready var v2_name_label: Label = $ModalPanel/VBoxContainer/V2Container/NameLabel
@onready var v2_description_label: Label = $ModalPanel/VBoxContainer/V2Container/DescriptionLabel
@onready var v2_button: Button = $ModalPanel/VBoxContainer/V2Container/ChooseButton

var v1_card: Card = null
var v2_card: Card = null

func _ready():
	# Hide initially
	visible = false

	# Connect button signals
	v1_button.pressed.connect(_on_v1_button_pressed)
	v2_button.pressed.connect(_on_v2_button_pressed)

## Show the modal with both card options
func show_choice(card_v1: Card, card_v2: Card):
	v1_card = card_v1
	v2_card = card_v2

	# Set v1 info
	v1_name_label.text = card_v1.card_name
	v1_description_label.text = card_v1.get_full_description()

	# Set v2 info
	v2_name_label.text = card_v2.card_name
	v2_description_label.text = card_v2.get_full_description()

	# Set title
	title_label.text = "Choose Card Effect: " + card_v1.card_name

	# Show modal
	visible = true

## Player chose v1 effect
func _on_v1_button_pressed():
	choice_made.emit(v1_card)
	visible = false

## Player chose v2 effect
func _on_v2_button_pressed():
	choice_made.emit(v2_card)
	visible = false
