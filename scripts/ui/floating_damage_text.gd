class_name FloatingDamageText
extends Control

## Floating text that displays damage/heal numbers with card names
## Auto-fades and deletes itself after 2 seconds

var label: Label
var tween: Tween

func _ready():
	# Create label
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)

	# Set up label styling
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)

	# Center the label
	label.set_anchors_preset(Control.PRESET_CENTER)

func show_damage(card_name: String, damage: int, spawn_position: Vector2):
	label.text = "%s - %d damage" % [card_name, damage]
	label.add_theme_color_override("font_color", Color.RED)
	global_position = spawn_position
	_animate_and_destroy()

func show_heal(card_name: String, heal: int, spawn_position: Vector2):
	label.text = "%s - +%d HP" % [card_name, heal]
	label.add_theme_color_override("font_color", Color.GREEN)
	global_position = spawn_position
	_animate_and_destroy()

func _animate_and_destroy():
	# Create tween for fade out and float up
	tween = create_tween()
	tween.set_parallel(true)

	# Fade out over 2 seconds
	tween.tween_property(self, "modulate:a", 0.0, 2.0)

	# Float upward
	tween.tween_property(self, "position:y", position.y - 50, 2.0)

	# Delete after animation
	tween.chain().tween_callback(queue_free)
