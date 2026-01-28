extends Node2D
## Wizard NPC visual for reward scenes
## Displays dialogue to guide players through reward selection

var speech_label: Label

func _ready():
	# Create speech bubble label
	speech_label = Label.new()
	speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speech_label.add_theme_font_size_override("font_size", 18)
	speech_label.add_theme_color_override("font_color", Color(1, 1, 1))
	speech_label.position = Vector2(-200, -100)
	speech_label.size = Vector2(400, 100)
	speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(speech_label)

func say(text: String) -> void:
	if speech_label:
		speech_label.text = text
