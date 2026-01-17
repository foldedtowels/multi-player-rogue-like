extends Node2D

var boss_name: String = ""
var animation_time: float = 0.0

func set_boss(name: String):
	boss_name = name
	create_boss_visual()

func create_boss_visual():
	# Clear existing children
	for child in get_children():
		child.queue_free()

	match boss_name:
		"Giant Moose":
			create_moose()
		"Mr. 67":
			create_mr_67()

func create_moose():
	# Large moose body
	var body = ColorRect.new()
	body.size = Vector2(80, 60)
	body.position = Vector2(-40, -30)
	body.color = Color(0.4, 0.3, 0.2)  # Brown fur
	add_child(body)

	# Moose head
	var head = ColorRect.new()
	head.size = Vector2(40, 50)
	head.position = Vector2(-20, -80)
	head.color = Color(0.45, 0.35, 0.25)
	add_child(head)

	# Snout
	var snout = ColorRect.new()
	snout.size = Vector2(30, 20)
	snout.position = Vector2(-15, -50)
	snout.color = Color(0.35, 0.25, 0.15)
	add_child(snout)

	# Eyes
	var eye1 = ColorRect.new()
	eye1.size = Vector2(8, 8)
	eye1.position = Vector2(-15, -70)
	eye1.color = Color(0.1, 0.1, 0.1)
	add_child(eye1)

	var eye2 = ColorRect.new()
	eye2.size = Vector2(8, 8)
	eye2.position = Vector2(7, -70)
	eye2.color = Color(0.1, 0.1, 0.1)
	add_child(eye2)

	# Antlers (left)
	var antler1 = Polygon2D.new()
	antler1.polygon = PackedVector2Array([
		Vector2(-20, -80),
		Vector2(-50, -100),
		Vector2(-60, -90),
		Vector2(-45, -85),
		Vector2(-55, -75),
		Vector2(-40, -80),
		Vector2(-25, -75)
	])
	antler1.color = Color(0.6, 0.5, 0.4)
	add_child(antler1)

	# Antlers (right)
	var antler2 = Polygon2D.new()
	antler2.polygon = PackedVector2Array([
		Vector2(20, -80),
		Vector2(50, -100),
		Vector2(60, -90),
		Vector2(45, -85),
		Vector2(55, -75),
		Vector2(40, -80),
		Vector2(25, -75)
	])
	antler2.color = Color(0.6, 0.5, 0.4)
	add_child(antler2)

	# Legs
	for i in range(4):
		var leg = ColorRect.new()
		leg.size = Vector2(12, 40)
		leg.position = Vector2(-35 + i * 20, 30)
		leg.color = Color(0.35, 0.25, 0.15)
		add_child(leg)

func create_mr_67():
	# Muscular body
	var body = ColorRect.new()
	body.size = Vector2(70, 80)
	body.position = Vector2(-35, -40)
	body.color = Color(0.9, 0.7, 0.6)  # Skin tone
	add_child(body)

	# Tank top
	var shirt = ColorRect.new()
	shirt.size = Vector2(70, 50)
	shirt.position = Vector2(-35, -20)
	shirt.color = Color(0.2, 0.2, 0.8)  # Blue
	add_child(shirt)

	# Head
	var head = ColorRect.new()
	head.size = Vector2(40, 45)
	head.position = Vector2(-20, -85)
	head.color = Color(0.9, 0.7, 0.6)
	add_child(head)

	# Angry eyes
	var eye1 = ColorRect.new()
	eye1.size = Vector2(10, 6)
	eye1.position = Vector2(-15, -70)
	eye1.color = Color(1, 1, 1)
	add_child(eye1)

	var pupil1 = ColorRect.new()
	pupil1.size = Vector2(4, 4)
	pupil1.position = Vector2(-12, -69)
	pupil1.color = Color(0, 0, 0)
	add_child(pupil1)

	var eye2 = ColorRect.new()
	eye2.size = Vector2(10, 6)
	eye2.position = Vector2(5, -70)
	eye2.color = Color(1, 1, 1)
	add_child(eye2)

	var pupil2 = ColorRect.new()
	pupil2.size = Vector2(4, 4)
	pupil2.position = Vector2(8, -69)
	pupil2.color = Color(0, 0, 0)
	add_child(pupil2)

	# Angry eyebrows
	var brow1 = ColorRect.new()
	brow1.size = Vector2(12, 3)
	brow1.position = Vector2(-16, -76)
	brow1.rotation = -0.3
	brow1.color = Color(0.3, 0.2, 0.1)
	add_child(brow1)

	var brow2 = ColorRect.new()
	brow2.size = Vector2(12, 3)
	brow2.position = Vector2(4, -76)
	brow2.rotation = 0.3
	brow2.color = Color(0.3, 0.2, 0.1)
	add_child(brow2)

	# Biceps (bulging arms)
	var arm1 = Polygon2D.new()
	arm1.polygon = PackedVector2Array([
		Vector2(-35, -30),
		Vector2(-55, -20),
		Vector2(-60, 10),
		Vector2(-50, 20),
		Vector2(-35, 10)
	])
	arm1.color = Color(0.9, 0.7, 0.6)
	add_child(arm1)

	var arm2 = Polygon2D.new()
	arm2.polygon = PackedVector2Array([
		Vector2(35, -30),
		Vector2(55, -20),
		Vector2(60, 10),
		Vector2(50, 20),
		Vector2(35, 10)
	])
	arm2.color = Color(0.9, 0.7, 0.6)
	add_child(arm2)

	# "67" on shirt
	var label = Label.new()
	label.text = "67"
	label.position = Vector2(-12, -10)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(label)

func _process(delta: float):
	animation_time += delta

	match boss_name:
		"Giant Moose":
			# Breathing/swaying motion
			rotation = sin(animation_time * 0.8) * 0.05
		"Mr. 67":
			# Flexing/bouncing motion
			scale = Vector2(1.0 + sin(animation_time * 3.0) * 0.05, 1.0 - sin(animation_time * 3.0) * 0.03)
