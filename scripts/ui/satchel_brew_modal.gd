extends Control
## Modal for Kevin's "Alchemist's Brew" passive ability
##
## Two-phase modal:
## Phase 1: Select an Alc card from the satchel
## Phase 2: Select Spell cards from hand to discard as ingredients

signal brew_completed(alc_card: Card, discarded_spells: Array[Card])
signal brew_cancelled()

enum Phase { SELECT_ALC, SELECT_SPELLS }

@onready var modal_panel: Panel = $ModalPanel
@onready var title_label: Label = $ModalPanel/VBoxContainer/TitleLabel
@onready var description_label: Label = $ModalPanel/VBoxContainer/DescriptionLabel
@onready var alc_list_container: VBoxContainer = $ModalPanel/VBoxContainer/ScrollContainer/AlcListContainer
@onready var ingredient_label: Label = $ModalPanel/VBoxContainer/IngredientLabel
@onready var selected_spells_label: Label = $ModalPanel/VBoxContainer/SelectedSpellsLabel
@onready var confirm_button: Button = $ModalPanel/VBoxContainer/ButtonContainer/ConfirmButton
@onready var back_button: Button = $ModalPanel/VBoxContainer/ButtonContainer/BackButton
@onready var cancel_button: Button = $ModalPanel/VBoxContainer/ButtonContainer/CancelButton

var character: Character = null
var current_phase: Phase = Phase.SELECT_ALC
var selected_alc: Card = null
var selected_spells: Array[Card] = []
var required_elements: Array[String] = []
var satisfied_elements: Array[String] = []

# Element display names for UI
const ELEMENT_NAMES = {
	"fire": "Fire",
	"water": "Water",
	"earth": "Earth"
}

func _ready():
	visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

## Show the satchel brew modal
func show_brew(char: Character):
	character = char
	current_phase = Phase.SELECT_ALC
	selected_alc = null
	selected_spells.clear()
	required_elements.clear()
	satisfied_elements.clear()

	_update_ui()
	visible = true

## Update UI based on current phase
func _update_ui():
	# Clear previous alc buttons
	for child in alc_list_container.get_children():
		child.queue_free()

	if current_phase == Phase.SELECT_ALC:
		_show_alc_selection()
	else:
		_show_spell_selection()

## Phase 1: Show Alc cards from satchel
func _show_alc_selection():
	title_label.text = "Alchemist's Brew"
	description_label.text = "Select an Alc to brew:"
	ingredient_label.visible = false
	selected_spells_label.visible = false
	confirm_button.visible = false
	back_button.visible = false

	if character.satchel.is_empty():
		description_label.text = "No Alc cards in satchel!"
		return

	# Create a button for each Alc in the satchel
	for alc in character.satchel:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(400, 60)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		# Show name and ingredient requirements
		var ingredients_str = _format_ingredients(alc.ingredient_list)
		btn.text = "%s\nRequires: %s" % [alc.card_name, ingredients_str]

		# Check if player can afford this Alc (has matching spells)
		var can_brew = _can_brew_alc(alc)
		btn.disabled = not can_brew
		if not can_brew:
			btn.tooltip_text = "Not enough matching Spell cards in hand"

		btn.pressed.connect(_on_alc_selected.bind(alc))
		alc_list_container.add_child(btn)

## Phase 2: Show spell selection for ingredients
func _show_spell_selection():
	title_label.text = "Select Spell Ingredients"
	description_label.text = "Brewing: %s" % selected_alc.card_name
	ingredient_label.visible = true
	selected_spells_label.visible = true
	confirm_button.visible = true
	back_button.visible = true

	# Store required elements
	required_elements = selected_alc.ingredient_list.duplicate()

	_update_ingredient_display()
	_update_spell_buttons()

## Update the ingredient requirement display
func _update_ingredient_display():
	var display_parts: Array[String] = []
	for element in required_elements:
		var elem_name = ELEMENT_NAMES.get(element, element.capitalize())
		if satisfied_elements.has(element):
			display_parts.append("[X] %s" % elem_name)
		else:
			display_parts.append("[ ] %s" % elem_name)

	ingredient_label.text = "Ingredients needed: %s" % ", ".join(display_parts)

	# Show selected spells
	if selected_spells.is_empty():
		selected_spells_label.text = "Selected: None"
	else:
		var spell_names: Array[String] = []
		for spell in selected_spells:
			spell_names.append(spell.card_name)
		selected_spells_label.text = "Selected: %s" % ", ".join(spell_names)

	# Enable confirm only if all ingredients satisfied
	confirm_button.disabled = not _all_ingredients_satisfied()

## Create buttons for spell cards in hand
func _update_spell_buttons():
	# Clear previous
	for child in alc_list_container.get_children():
		child.queue_free()

	# Get spell cards from hand
	var spell_cards = _get_spell_cards_in_hand()

	if spell_cards.is_empty():
		var label = Label.new()
		label.text = "No Spell cards in hand!"
		alc_list_container.add_child(label)
		return

	for spell in spell_cards:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(400, 50)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		var elem_name = _get_element_name(spell.element)
		btn.text = "%s (%s)" % [spell.card_name, elem_name]

		# Check if this spell is already selected
		var is_selected = selected_spells.has(spell)
		if is_selected:
			btn.text = "[SELECTED] " + btn.text
			btn.modulate = Color(0.7, 1.0, 0.7)  # Green tint

		# Check if this element is still needed
		var element_str = _element_to_string(spell.element)
		var still_needed = _is_element_still_needed(element_str)

		if not is_selected and not still_needed:
			btn.disabled = true
			btn.tooltip_text = "This element is not needed"

		btn.pressed.connect(_on_spell_toggled.bind(spell))
		alc_list_container.add_child(btn)

## Check if player has the spells to brew an Alc
func _can_brew_alc(alc: Card) -> bool:
	var available_elements: Array[String] = []
	for card in character.hand:
		if card.element != Card.ElementType.NONE:
			available_elements.append(_element_to_string(card.element))

	# Check if we have all required elements
	var needed = alc.ingredient_list.duplicate()
	for elem in available_elements:
		var idx = needed.find(elem)
		if idx >= 0:
			needed.remove_at(idx)

	return needed.is_empty()

## Get spell cards from hand
func _get_spell_cards_in_hand() -> Array[Card]:
	var spells: Array[Card] = []
	for card in character.hand:
		if card.element != Card.ElementType.NONE:
			spells.append(card)
	return spells

## Convert element enum to string
func _element_to_string(element: Card.ElementType) -> String:
	match element:
		Card.ElementType.FIRE: return "fire"
		Card.ElementType.WATER: return "water"
		Card.ElementType.EARTH: return "earth"
		_: return ""

## Get display name for element
func _get_element_name(element: Card.ElementType) -> String:
	var elem_str = _element_to_string(element)
	return ELEMENT_NAMES.get(elem_str, "None")

## Format ingredient list for display
func _format_ingredients(ingredients: Array[String]) -> String:
	var parts: Array[String] = []
	for elem in ingredients:
		parts.append(ELEMENT_NAMES.get(elem, elem.capitalize()))
	return ", ".join(parts)

## Check if an element is still needed (not yet satisfied)
func _is_element_still_needed(element: String) -> bool:
	# Count how many of this element are required
	var required_count = required_elements.count(element)
	# Count how many are already satisfied
	var satisfied_count = satisfied_elements.count(element)
	return satisfied_count < required_count

## Check if all ingredients are satisfied
func _all_ingredients_satisfied() -> bool:
	if required_elements.size() != satisfied_elements.size():
		return false

	# Check each required element is satisfied
	var temp_satisfied = satisfied_elements.duplicate()
	for elem in required_elements:
		var idx = temp_satisfied.find(elem)
		if idx < 0:
			return false
		temp_satisfied.remove_at(idx)
	return true

## Called when an Alc is selected
func _on_alc_selected(alc: Card):
	selected_alc = alc
	selected_spells.clear()
	satisfied_elements.clear()
	current_phase = Phase.SELECT_SPELLS
	_update_ui()

## Called when a spell is toggled
func _on_spell_toggled(spell: Card):
	var element_str = _element_to_string(spell.element)

	if selected_spells.has(spell):
		# Deselect
		selected_spells.erase(spell)
		var idx = satisfied_elements.find(element_str)
		if idx >= 0:
			satisfied_elements.remove_at(idx)
	else:
		# Select (only if element is still needed)
		if _is_element_still_needed(element_str):
			selected_spells.append(spell)
			satisfied_elements.append(element_str)

	_update_ingredient_display()
	_update_spell_buttons()

## Confirm brewing
func _on_confirm_pressed():
	if selected_alc and _all_ingredients_satisfied():
		brew_completed.emit(selected_alc, selected_spells)
		visible = false

## Go back to Alc selection
func _on_back_pressed():
	current_phase = Phase.SELECT_ALC
	selected_alc = null
	selected_spells.clear()
	satisfied_elements.clear()
	_update_ui()

## Cancel brewing
func _on_cancel_pressed():
	brew_cancelled.emit()
	visible = false
