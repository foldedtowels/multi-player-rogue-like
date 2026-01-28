extends Control
## Modal for viewing all cards in a player's deck
##
## Shows cards organized by location: Deck, Hand, Discard, Exhaust
## Cards are displayed in a scrollable grid

signal closed

var card_visual_scene: PackedScene

# UI Elements (will be created dynamically)
var modal_panel: Panel
var title_label: Label
var close_button: Button
var tab_container: TabContainer
var deck_scroll: ScrollContainer
var hand_scroll: ScrollContainer
var discard_scroll: ScrollContainer
var exhaust_scroll: ScrollContainer
var deck_grid: GridContainer
var hand_grid: GridContainer
var discard_grid: GridContainer
var exhaust_grid: GridContainer

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
	bg.mouse_filter = Control.MOUSE_FILTER_STOP  # Block clicks to combat UI
	add_child(bg)

	# Modal panel
	modal_panel = Panel.new()
	modal_panel.set_anchors_preset(Control.PRESET_CENTER)
	modal_panel.custom_minimum_size = Vector2(900, 600)
	modal_panel.offset_left = -450
	modal_panel.offset_right = 450
	modal_panel.offset_top = -300
	modal_panel.offset_bottom = 300
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
	title_label.text = "Your Deck"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	# Close button
	close_button = Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(40, 40)
	close_button.pressed.connect(_on_close_pressed)
	header.add_child(close_button)

	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Tab container
	tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(tab_container)

	# Create tabs with scroll containers and grids
	deck_scroll = _create_scroll_tab("Draw Pile")
	deck_grid = deck_scroll.get_child(0) as GridContainer

	hand_scroll = _create_scroll_tab("Hand")
	hand_grid = hand_scroll.get_child(0) as GridContainer

	discard_scroll = _create_scroll_tab("Discard")
	discard_grid = discard_scroll.get_child(0) as GridContainer

	exhaust_scroll = _create_scroll_tab("Exhausted")
	exhaust_grid = exhaust_scroll.get_child(0) as GridContainer

func _create_scroll_tab(tab_name: String) -> ScrollContainer:
	var scroll = ScrollContainer.new()
	scroll.name = tab_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.add_child(scroll)

	var grid = GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	return scroll

## Show the modal with the player's cards
## If randomize_draw_pile is true, the draw pile will be shown in random order (for combat)
## If false, cards are shown in actual order (for reward screen / out of combat)
func show_deck(player: Character, randomize_draw_pile: bool = false):
	title_label.text = "%s's Deck" % player.character_name

	# Clear existing cards
	_clear_grid(deck_grid)
	_clear_grid(hand_grid)
	_clear_grid(discard_grid)
	_clear_grid(exhaust_grid)

	# Populate grids - randomize draw pile if requested (prevents card counting during combat)
	var deck_cards = player.deck.duplicate()
	if randomize_draw_pile:
		deck_cards.shuffle()
	_populate_grid(deck_grid, deck_cards, "Draw Pile (%d)", player)
	_populate_grid(hand_grid, player.hand, "Hand (%d)", player)
	_populate_grid(discard_grid, player.discard_pile, "Discard (%d)", player)
	_populate_grid(exhaust_grid, player.exhaust_pile, "Exhausted (%d)", player)

	# Update tab names with counts
	tab_container.set_tab_title(0, "Draw Pile (%d)" % player.deck.size())
	tab_container.set_tab_title(1, "Hand (%d)" % player.hand.size())
	tab_container.set_tab_title(2, "Discard (%d)" % player.discard_pile.size())
	tab_container.set_tab_title(3, "Exhausted (%d)" % player.exhaust_pile.size())

	visible = true

func _clear_grid(grid: GridContainer):
	for child in grid.get_children():
		child.queue_free()

func _populate_grid(grid: GridContainer, cards: Array, _tab_format: String, owner: Character = null):
	if cards.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No cards"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		grid.add_child(empty_label)
		return

	for card in cards:
		var card_visual = card_visual_scene.instantiate()
		card_visual.custom_minimum_size = CARD_SIZE
		card_visual.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		grid.add_child(card_visual)

		# Set card data after adding to tree
		card_visual.set_card(card)
		if owner:
			card_visual.set_card_owner(owner)  # For card background color
		card_visual.set_playable(true)  # Show colors properly

		# Disable interaction (view only)
		card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_close_pressed():
	visible = false
	closed.emit()

func _input(event: InputEvent):
	if visible and event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()
