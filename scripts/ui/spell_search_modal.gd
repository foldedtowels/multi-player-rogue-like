extends Control
class_name SpellSearchModal

## Modal for searching deck for spell cards (for cards like Reformulate)
## Shows only Spell cards in the player's deck and lets them select one to add to hand.

signal search_completed(selected_spells: Array[Card])
signal search_cancelled()

var card_visual_scene: PackedScene
var player: Character
var max_selections: int = 1
var selected_cards: Array[Card] = []

# UI Elements (built dynamically)
var modal_panel: Panel
var title_label: Label
var instructions_label: Label
var close_button: Button
var confirm_button: Button
var spell_scroll: ScrollContainer
var spell_grid: GridContainer
var card_buttons: Dictionary = {}  # card -> button mapping

const CARD_SIZE = Vector2(120, 160)
const GRID_COLUMNS = 6

func _ready():
	card_visual_scene = preload("res://scenes/card_visual.tscn")
	visible = false
	_build_ui()


func _build_ui():
	# Dark semi-transparent background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# Modal panel
	modal_panel = Panel.new()
	modal_panel.set_anchors_preset(Control.PRESET_CENTER)
	modal_panel.custom_minimum_size = Vector2(900, 500)
	modal_panel.offset_left = -450
	modal_panel.offset_right = 450
	modal_panel.offset_top = -250
	modal_panel.offset_bottom = 250
	add_child(modal_panel)

	# Main VBox
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_right = -20
	vbox.offset_top = 20
	vbox.offset_bottom = -20
	modal_panel.add_child(vbox)

	# Header HBox
	var header = HBoxContainer.new()
	vbox.add_child(header)

	# Title
	title_label = Label.new()
	title_label.text = "Search for Spell"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	# Close button
	close_button = Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(40, 40)
	close_button.pressed.connect(_on_cancel_pressed)
	header.add_child(close_button)

	# Instructions
	instructions_label = Label.new()
	instructions_label.text = "Select a Spell card to add to your hand"
	instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instructions_label)

	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Scroll container for spells
	spell_scroll = ScrollContainer.new()
	spell_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	spell_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spell_scroll)

	spell_grid = GridContainer.new()
	spell_grid.columns = GRID_COLUMNS
	spell_grid.add_theme_constant_override("h_separation", 10)
	spell_grid.add_theme_constant_override("v_separation", 10)
	spell_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spell_scroll.add_child(spell_grid)

	# Button container
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_container)

	confirm_button = Button.new()
	confirm_button.text = "Confirm"
	confirm_button.custom_minimum_size = Vector2(100, 40)
	confirm_button.disabled = true
	confirm_button.pressed.connect(_on_confirm_pressed)
	button_container.add_child(confirm_button)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	button_container.add_child(spacer)

	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(100, 40)
	cancel_button.pressed.connect(_on_cancel_pressed)
	button_container.add_child(cancel_button)


## Show the modal to search for spells in deck
## Returns true if there are spells in deck, false otherwise
func show_search(target_player: Character, count: int, card_name: String) -> bool:
	player = target_player
	max_selections = count
	selected_cards.clear()
	card_buttons.clear()

	title_label.text = card_name + " - Search Deck"
	_update_instructions()

	# Clear existing cards
	for child in spell_grid.get_children():
		child.queue_free()

	# Find spell cards in deck
	var spells_in_deck: Array[Card] = []
	for card in player.deck:
		if card.card_type == Card.CardType.SPELL:
			spells_in_deck.append(card)

	if spells_in_deck.is_empty():
		print("[SPELL SEARCH] No spells in deck to search")
		return false

	# Create card displays with click handlers
	for spell in spells_in_deck:
		var container = _create_selectable_card(spell)
		spell_grid.add_child(container)

	_update_confirm_button()
	visible = true
	return true


func _create_selectable_card(card: Card) -> Control:
	var container = Control.new()
	container.custom_minimum_size = CARD_SIZE

	var card_visual = card_visual_scene.instantiate()
	card_visual.custom_minimum_size = CARD_SIZE
	container.add_child(card_visual)

	# Set card data after adding to tree
	card_visual.set_card(card)
	card_visual.set_playable(true)

	# Create clickable overlay
	var overlay = Button.new()
	overlay.flat = true
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.toggle_mode = true
	overlay.toggled.connect(_on_card_toggled.bind(card))
	container.add_child(overlay)

	card_buttons[card] = overlay

	# Selection highlight (initially hidden)
	var highlight = ColorRect.new()
	highlight.name = "Highlight"
	highlight.color = Color(0.3, 0.8, 0.3, 0.3)
	highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight.visible = false
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(highlight)

	return container


func _on_card_toggled(pressed: bool, card: Card):
	if pressed:
		if selected_cards.size() < max_selections:
			selected_cards.append(card)
			_show_highlight(card, true)
		else:
			# Deselect if at max
			card_buttons[card].button_pressed = false
	else:
		selected_cards.erase(card)
		_show_highlight(card, false)

	_update_instructions()
	_update_confirm_button()


func _show_highlight(card: Card, show: bool):
	var button = card_buttons.get(card)
	if button:
		var highlight = button.get_parent().get_node_or_null("Highlight")
		if highlight:
			highlight.visible = show


func _update_instructions():
	var remaining = max_selections - selected_cards.size()
	if remaining > 0:
		instructions_label.text = "Select " + str(remaining) + " more spell(s) to add to hand"
	else:
		instructions_label.text = "Press Confirm to add selected spell(s)"


func _update_confirm_button():
	confirm_button.disabled = selected_cards.is_empty()


func _on_confirm_pressed():
	var result: Array[Card] = []
	for card in selected_cards:
		result.append(card)
	visible = false
	search_completed.emit(result)


func _on_cancel_pressed():
	visible = false
	search_cancelled.emit()


func _input(event: InputEvent):
	if visible and event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_cancel_pressed()
			get_viewport().set_input_as_handled()
