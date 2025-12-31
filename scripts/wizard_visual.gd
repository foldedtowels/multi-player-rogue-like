extends Node2D

var float_offset: float = 0.0
var speech_bubble: Control
var speech_text: Label

func _ready():
	# Wizard robe (main body)
	var robe = Polygon2D.new()
	robe.polygon = PackedVector2Array([
		Vector2(0, 20),      # Top center
		Vector2(-40, 30),    # Left shoulder
		Vector2(-50, 100),   # Left bottom
		Vector2(50, 100),    # Right bottom
		Vector2(40, 30),     # Right shoulder
	])
	robe.color = Color(0.2, 0.1, 0.6)  # Deep purple
	add_child(robe)

	# Robe trim
	var trim = Polygon2D.new()
	trim.polygon = PackedVector2Array([
		Vector2(-45, 95),
		Vector2(-50, 100),
		Vector2(50, 100),
		Vector2(45, 95)
	])
	trim.color = Color(0.8, 0.7, 0.1)  # Gold trim
	add_child(trim)

	# Wizard head (circle)
	var head = ColorRect.new()
	head.size = Vector2(35, 40)
	head.position = Vector2(-17.5, -10)
	head.color = Color(0.9, 0.8, 0.7)  # Skin tone
	add_child(head)

	# Wizard hat
	var hat = Polygon2D.new()
	hat.polygon = PackedVector2Array([
		Vector2(0, -60),     # Point
		Vector2(-25, -10),   # Left base
		Vector2(25, -10)     # Right base
	])
	hat.color = Color(0.2, 0.1, 0.6)  # Purple
	add_child(hat)

	# Hat brim
	var brim = ColorRect.new()
	brim.size = Vector2(60, 8)
	brim.position = Vector2(-30, -15)
	brim.color = Color(0.15, 0.08, 0.5)
	add_child(brim)

	# Star on hat
	var star = Polygon2D.new()
	star.polygon = PackedVector2Array([
		Vector2(0, -50), Vector2(3, -42), Vector2(10, -42),
		Vector2(5, -37), Vector2(7, -30), Vector2(0, -35),
		Vector2(-7, -30), Vector2(-5, -37), Vector2(-10, -42),
		Vector2(-3, -42)
	])
	star.color = Color(1, 1, 0)  # Gold star
	add_child(star)

	# Eyes
	var eye1 = ColorRect.new()
	eye1.size = Vector2(6, 6)
	eye1.position = Vector2(-10, 5)
	eye1.color = Color(0, 0, 0)
	add_child(eye1)

	var eye2 = ColorRect.new()
	eye2.size = Vector2(6, 6)
	eye2.position = Vector2(5, 5)
	eye2.color = Color(0, 0, 0)
	add_child(eye2)

	# Beard
	var beard = Polygon2D.new()
	beard.polygon = PackedVector2Array([
		Vector2(-15, 20),
		Vector2(-20, 35),
		Vector2(-12, 40),
		Vector2(0, 45),
		Vector2(12, 40),
		Vector2(20, 35),
		Vector2(15, 20)
	])
	beard.color = Color(0.9, 0.9, 0.9)  # White beard
	add_child(beard)

	# Magic staff
	var staff_pole = ColorRect.new()
	staff_pole.size = Vector2(6, 90)
	staff_pole.position = Vector2(40, 20)
	staff_pole.color = Color(0.4, 0.25, 0.1)  # Brown
	add_child(staff_pole)

	# Staff orb
	var orb = ColorRect.new()
	orb.size = Vector2(18, 18)
	orb.position = Vector2(34, 10)
	orb.color = Color(0.3, 0.6, 1, 0.8)  # Glowing blue
	add_child(orb)

	# Orb glow effect
	var glow = ColorRect.new()
	glow.size = Vector2(26, 26)
	glow.position = Vector2(30, 6)
	glow.color = Color(0.5, 0.8, 1, 0.3)
	add_child(glow)

	# Magic sparkles around staff
	create_sparkles()

	# Create speech bubble
	create_speech_bubble()

func create_sparkles():
	for i in range(5):
		var sparkle = CPUParticles2D.new()
		sparkle.position = Vector2(43, 19)
		sparkle.emitting = true
		sparkle.amount = 8
		sparkle.lifetime = 1.5
		sparkle.one_shot = false
		sparkle.explosiveness = 0.1
		sparkle.local_coords = false
		sparkle.direction = Vector2(0, -1)
		sparkle.spread = 180
		sparkle.gravity = Vector2(0, -20)
		sparkle.initial_velocity_min = 20
		sparkle.initial_velocity_max = 40
		sparkle.scale_amount_min = 3.0
		sparkle.scale_amount_max = 6.0

		var gradient = Gradient.new()
		gradient.add_point(0.0, Color(1, 1, 0, 1))
		gradient.add_point(0.5, Color(0.5, 0.8, 1, 0.8))
		gradient.add_point(1.0, Color(1, 1, 1, 0))
		sparkle.color_ramp = gradient

		add_child(sparkle)

func create_speech_bubble():
	speech_bubble = Control.new()
	speech_bubble.position = Vector2(-250, -180)
	add_child(speech_bubble)

	# Bubble background
	var bubble_bg = Panel.new()
	bubble_bg.custom_minimum_size = Vector2(450, 150)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.95)
	style.border_color = Color(0, 0, 0)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	bubble_bg.add_theme_stylebox_override("panel", style)
	speech_bubble.add_child(bubble_bg)

	# Speech tail (triangle pointing to wizard)
	var tail = Polygon2D.new()
	tail.polygon = PackedVector2Array([
		Vector2(100, 120),
		Vector2(120, 150),
		Vector2(140, 120)
	])
	tail.color = Color(1, 1, 1, 0.95)
	speech_bubble.add_child(tail)

	var tail_border = Polygon2D.new()
	tail_border.polygon = PackedVector2Array([
		Vector2(100, 120),
		Vector2(120, 150),
		Vector2(140, 120)
	])
	tail_border.color = Color(0, 0, 0)
	speech_bubble.add_child(tail_border)
	tail_border.z_index = -1

	# Text label
	speech_text = Label.new()
	speech_text.position = Vector2(15, 15)
	speech_text.custom_minimum_size = Vector2(420, 120)
	speech_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	speech_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speech_text.add_theme_color_override("font_color", Color(0, 0, 0))
	speech_text.add_theme_font_size_override("font_size", 16)
	speech_bubble.add_child(speech_text)

func say(text: String):
	speech_text.text = text
	speech_bubble.visible = true

func clear_speech():
	speech_bubble.visible = false

func _process(delta: float):
	# Gentle floating animation
	float_offset += delta
	position.y = sin(float_offset * 2.0) * 10

	# Staff orb pulse
	var pulse = (sin(float_offset * 3.0) + 1.0) / 2.0
	if get_child_count() > 11:  # Orb is child 11
		var orb = get_child(11)
		if orb is ColorRect:
			orb.modulate = Color(1, 1, 1, 0.6 + pulse * 0.4)
