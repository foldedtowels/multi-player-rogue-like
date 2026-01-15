extends Control

var card_data: Card
var is_playable: bool = false
var is_hovered: bool = false
var last_click_time: float = 0.0
const DOUBLE_CLICK_TIME: float = 0.3  # 300ms for double-click

# Owner character for dynamic description calculations (damage/heal with buffs)
var owner_character = null

# Texture references
const BG_FABIO = preload("res://assets/temp cards/Fabio.png")
const BG_KEVIN = preload("res://assets/temp cards/Kevin.png")
const BG_DEFAULT = preload("res://assets/temp cards/Enrique.png")
const CARD_TEXT_BOX = preload("res://assets/temp cards/card text box.png")
const STAMINA_CIRCLE = preload("res://assets/temp cards/Stamina.png")
const STAMINA_NUMS = [
	preload("res://assets/temp cards/0.png"),
	preload("res://assets/temp cards/1.png"),
	preload("res://assets/temp cards/2.png"),
	preload("res://assets/temp cards/3.png")
]
const TYPE_BOX_ATTACK = preload("res://assets/temp cards/attack text box.png")
const TYPE_BOX_SKILL = preload("res://assets/temp cards/Skill text box.png")
const TYPE_TEXT_ATTACK = preload("res://assets/temp cards/Attack.png")
const TYPE_TEXT_SKILL = preload("res://assets/temp cards/Skill.png")
const ELEM_FIRE = preload("res://assets/temp cards/Fire.png")
const ELEM_WATER = preload("res://assets/temp cards/Water.png")
const ELEM_EARTH = preload("res://assets/temp cards/Earth.png")

# Node references
@onready var background: TextureRect = $Background
@onready var card_text_box: TextureRect = $CardTextBox
@onready var stamina_circle: TextureRect = $StaminaCircle
@onready var stamina_number: TextureRect = $StaminaCircle/StaminaNumber
@onready var element_icon: TextureRect = $ElementIcon
@onready var type_box: TextureRect = $TypeBox
@onready var type_text: TextureRect = $TypeBox/TypeText
@onready var name_label: Label = $NameLabel
@onready var description_label: Label = $DescriptionLabel

signal card_clicked(card: Card)
signal card_double_clicked(card: Card)
signal card_hovered(card: Card)
signal card_drag_started(card: Card)
signal card_drag_ended(card: Card)

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

	# Set all child elements to pass clicks through to this Control
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# Also handle nested children
			for subchild in child.get_children():
				if subchild is Control:
					subchild.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_card(card: Card):
	card_data = card
	update_display()

func set_card_owner(character):
	owner_character = character
	update_display()

func update_display():
	if not card_data:
		return

	# Set background based on owner hero
	var hero_id = ""
	if owner_character and owner_character.hero_id:
		hero_id = owner_character.hero_id

	match hero_id:
		"fabio":
			background.texture = BG_FABIO
		"kevin":
			background.texture = BG_KEVIN
		_:
			background.texture = BG_DEFAULT

	# Card text box (cream background for text)
	card_text_box.texture = CARD_TEXT_BOX

	# Stamina circle and number
	stamina_circle.texture = STAMINA_CIRCLE
	var cost = clampi(card_data.stamina_cost, 0, 3)
	stamina_number.texture = STAMINA_NUMS[cost]

	# Type box and text based on card type
	var is_attack = card_data.card_type == Card.CardType.ATTACK
	type_box.texture = TYPE_BOX_ATTACK if is_attack else TYPE_BOX_SKILL
	type_text.texture = TYPE_TEXT_ATTACK if is_attack else TYPE_TEXT_SKILL

	# Element icon (Kevin's spells only)
	if card_data.element != Card.ElementType.NONE:
		element_icon.visible = true
		match card_data.element:
			Card.ElementType.FIRE:
				element_icon.texture = ELEM_FIRE
			Card.ElementType.WATER:
				element_icon.texture = ELEM_WATER
			Card.ElementType.EARTH:
				element_icon.texture = ELEM_EARTH
	else:
		element_icon.visible = false

	# Text labels
	name_label.text = card_data.card_name
	# Pass owner for dynamic description (damage/heal adjusted by buffs/debuffs)
	description_label.text = card_data.get_full_description(owner_character)

	# Update visual state based on playability
	update_card_color()

func update_card_color():
	if not is_playable:
		# Gray out when unplayable
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

	if is_hovered and is_playable:
		modulate = modulate.lightened(0.15)

func set_playable(playable: bool):
	is_playable = playable
	update_card_color()

func _on_mouse_entered():
	is_hovered = true
	if is_playable:
		scale = Vector2(1.1, 1.1)
		z_index = 10
		card_hovered.emit(card_data)
	update_card_color()

func _on_mouse_exited():
	is_hovered = false
	scale = Vector2(1.0, 1.0)
	z_index = 0
	update_card_color()

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if is_playable:
				# Check for double-click
				var current_time = Time.get_ticks_msec() / 1000.0
				var time_since_last_click = current_time - last_click_time

				if time_since_last_click < DOUBLE_CLICK_TIME:
					# Double-click detected!
					card_double_clicked.emit(card_data)
					last_click_time = 0.0  # Reset to prevent triple-click from triggering
				else:
					# Single click (might become double-click)
					card_clicked.emit(card_data)
					last_click_time = current_time

## Drag-and-drop support
func _get_drag_data(at_position: Vector2):
	if not is_playable or not card_data:
		return null

	# Emit drag started signal
	card_drag_started.emit(card_data)

	# Create ghost preview (semi-transparent copy of card)
	var preview = Control.new()
	var ghost_card = duplicate() as Control
	ghost_card.modulate = Color(1, 1, 1, 0.5)  # Semi-transparent
	preview.add_child(ghost_card)

	set_drag_preview(preview)

	# Return card data as drag data
	return {"card": card_data, "source": self}

## Called when drag ends (whether successful drop or cancelled)
func _notification(what: int):
	if what == NOTIFICATION_DRAG_END:
		card_drag_ended.emit(card_data)
