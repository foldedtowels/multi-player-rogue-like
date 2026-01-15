extends Panel

## Panel that can accept card drops for drag-and-drop gameplay
## Also emits panel_clicked for click detection (used by passive ability targeting)

signal card_dropped(card_data: Dictionary)
signal panel_clicked(event: InputEventMouseButton)

func _gui_input(event: InputEvent):
	# Emit panel_clicked on left mouse button press for target selection
	# Drag-and-drop is handled separately by _can_drop_data/_drop_data
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		panel_clicked.emit(event)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Check if data is a valid card drop
	if typeof(data) != TYPE_DICTIONARY:
		return false

	if not data.has("card"):
		return false

	# For now, always allow drops (validation will happen in the drop handler)
	return true

func _drop_data(at_position: Vector2, data: Variant):
	if typeof(data) == TYPE_DICTIONARY and data.has("card"):
		# Emit signal with card data
		card_dropped.emit(data)
