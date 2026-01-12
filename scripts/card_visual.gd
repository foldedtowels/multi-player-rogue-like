extends Control

var card_data: Card
var is_playable: bool = false
var is_hovered: bool = false
var last_click_time: float = 0.0
const DOUBLE_CLICK_TIME: float = 0.3  # 300ms for double-click

@onready var card_bg: Panel = $Background
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var cost_label: Label = $CostLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var type_label: Label = $VBoxContainer/TypeLabel

signal card_clicked(card: Card)
signal card_double_clicked(card: Card)
signal card_hovered(card: Card)
signal card_drag_started(card: Card)
signal card_drag_ended(card: Card)

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

	# Make sure all child elements pass clicks through to this Control
	if card_bg:
		card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Set all labels and containers to ignore mouse so clicks reach parent
	var vbox = get_node_or_null("VBoxContainer")
	if vbox:
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Also set all children of VBoxContainer
		for child in vbox.get_children():
			if child is Control:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if cost_label:
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_card(card: Card):
	card_data = card
	update_display()

func update_display():
	if not card_data:
		return

	name_label.text = card_data.card_name
	cost_label.text = str(card_data.stamina_cost)
	description_label.text = card_data.get_full_description()

	var type_text = ""
	match card_data.card_type:
		Card.CardType.ATTACK: type_text = "Attack"
		Card.CardType.SPELL: type_text = "Spell"
		Card.CardType.BUFF: type_text = "Buff"
		Card.CardType.DEBUFF: type_text = "Debuff"
		Card.CardType.HEAL: type_text = "Heal"

	type_label.text = type_text

	# Color based on card type
	update_card_color()

func update_card_color():
	if not card_bg:
		return

	var style = StyleBoxFlat.new()

	if not is_playable:
		style.bg_color = Color(0.3, 0.3, 0.3)  # Gray when unplayable
	else:
		match card_data.card_type:
			Card.CardType.ATTACK:
				style.bg_color = Color(0.9, 0.1, 0.1)  # BRIGHT RED
			Card.CardType.SPELL:
				style.bg_color = Color(1.0, 0.9, 0.0)  # BRIGHT YELLOW
			Card.CardType.BUFF:
				style.bg_color = Color(0.1, 0.9, 0.1)  # BRIGHT GREEN
			Card.CardType.DEBUFF:
				style.bg_color = Color(0.7, 0.1, 0.9)  # BRIGHT PURPLE
			Card.CardType.HEAL:
				style.bg_color = Color(0.1, 0.6, 0.9)  # BRIGHT BLUE

	if is_hovered and is_playable:
		style.bg_color = style.bg_color.lightened(0.2)

	style.border_color = Color.WHITE if is_playable else Color.DARK_GRAY
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2

	card_bg.add_theme_stylebox_override("panel", style)

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
