extends Control
class_name SpellDiscardModal

## Modal for selecting spell cards to discard (for cards like Repurpose, Mortar and Pestle)
## Shows the player's spell cards and lets them select the required number to discard.
## Supports both fixed counts and variable ranges (min/max).

signal discard_completed(discarded_spells: Array[Card])
signal discard_cancelled()

var min_count: int = 0
var max_count: int = -1  # -1 = unlimited
var selected_spells: Array[Card] = []
var available_spells: Array[Card] = []
var spell_buttons: Array[Button] = []

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var instructions_label: Label = $Panel/VBoxContainer/InstructionsLabel
@onready var spell_grid: GridContainer = $Panel/VBoxContainer/SpellGrid
@onready var confirm_button: Button = $Panel/VBoxContainer/ButtonContainer/ConfirmButton
@onready var cancel_button: Button = $Panel/VBoxContainer/ButtonContainer/CancelButton

func _ready():
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	hide()


## Show the modal to select spells to discard (fixed count mode)
## Returns true if player has enough spells, false otherwise
func show_discard(player: Character, count: int, card_name: String) -> bool:
	return show_discard_range(player, count, count, card_name)


## Show the modal to select spells to discard (variable range mode)
## min_discard: minimum spells required (0 = optional)
## max_discard: maximum spells allowed (-1 = unlimited)
## Returns true if player has at least min_discard spells, false otherwise
func show_discard_range(player: Character, min_discard: int, max_discard: int, card_name: String) -> bool:
	min_count = min_discard
	max_count = max_discard
	selected_spells.clear()
	available_spells.clear()

	# Find all spell cards in the player's hand
	# Note: Kevin's "spells" are cards with an element (FIRE, WATER, EARTH), not card_type SPELL
	for card in player.hand:
		if card.element != Card.ElementType.NONE:
			available_spells.append(card)

	# Check if player has enough spells for minimum requirement
	if available_spells.size() < min_count:
		print("[SPELL DISCARD] Not enough spells in hand: have ", available_spells.size(), ", need ", min_count)
		return false

	title_label.text = "Discard Spells for " + card_name
	_update_instructions()
	_create_spell_buttons()
	_update_confirm_button()

	show()
	return true


func _update_instructions():
	var current = selected_spells.size()
	var effective_max = max_count if max_count >= 0 else available_spells.size()

	if min_count == 0 and max_count < 0:
		# Variable mode: 0 to unlimited
		instructions_label.text = "Select any number of spells to discard (selected: %d)" % current
	elif min_count == max_count:
		# Fixed count mode
		var remaining = min_count - current
		if remaining > 0:
			instructions_label.text = "Select %d more spell(s) to discard" % remaining
		else:
			instructions_label.text = "Ready to confirm!"
	else:
		# Range mode
		if current < min_count:
			instructions_label.text = "Select at least %d spell(s) (selected: %d)" % [min_count, current]
		else:
			instructions_label.text = "Selected: %d spell(s) - Ready to confirm!" % current


func _create_spell_buttons():
	# Clear existing buttons
	for button in spell_buttons:
		button.queue_free()
	spell_buttons.clear()

	# Create a button for each available spell
	for spell in available_spells:
		var button = Button.new()
		button.text = spell.card_name + " (" + str(spell.stamina_cost) + ")"
		button.custom_minimum_size = Vector2(150, 50)
		button.toggle_mode = true
		button.toggled.connect(_on_spell_toggled.bind(spell))

		# Style based on element
		var element_colors = {
			Card.ElementType.FIRE: Color(1.0, 0.4, 0.3),
			Card.ElementType.WATER: Color(0.3, 0.6, 1.0),
			Card.ElementType.EARTH: Color(0.6, 0.5, 0.3)
		}
		if spell.element in element_colors:
			var style = StyleBoxFlat.new()
			style.bg_color = element_colors[spell.element].darkened(0.3)
			style.corner_radius_top_left = 5
			style.corner_radius_top_right = 5
			style.corner_radius_bottom_left = 5
			style.corner_radius_bottom_right = 5
			button.add_theme_stylebox_override("normal", style)

		spell_grid.add_child(button)
		spell_buttons.append(button)


func _on_spell_toggled(pressed: bool, spell: Card):
	var effective_max = max_count if max_count >= 0 else available_spells.size()

	if pressed:
		if selected_spells.size() < effective_max:
			selected_spells.append(spell)
		else:
			# Already at max, deselect this one
			for button in spell_buttons:
				if button.text.begins_with(spell.card_name):
					button.button_pressed = false
					break
	else:
		selected_spells.erase(spell)

	_update_instructions()
	_update_confirm_button()


func _update_confirm_button():
	# Confirm is enabled when we have at least min_count selected
	confirm_button.disabled = selected_spells.size() < min_count


func _on_confirm_pressed():
	var result: Array[Card] = []
	for spell in selected_spells:
		result.append(spell)
	hide()
	discard_completed.emit(result)


func _on_cancel_pressed():
	hide()
	discard_cancelled.emit()
