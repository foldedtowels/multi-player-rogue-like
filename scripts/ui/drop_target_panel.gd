extends Panel

## Panel that can accept card drops for drag-and-drop gameplay

signal card_dropped(card_data: Dictionary)

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
