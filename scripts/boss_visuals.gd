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
		"Corrupted Treant":
			create_treant()
		"Flame Warlord":
			create_warlord()
		"Lich Summoner":
			create_lich()
		"Storm Dragon":
			create_dragon()
		"Void Titan":
			create_void_titan()

func create_treant():
	# Tree trunk
	var trunk = ColorRect.new()
	trunk.size = Vector2(60, 120)
	trunk.position = Vector2(-30, -60)
	trunk.color = Color(0.3, 0.2, 0.1)
	add_child(trunk)

	# Corrupted bark texture
	for i in range(5):
		var scar = ColorRect.new()
		scar.size = Vector2(50, 5)
		scar.position = Vector2(-25, -50 + i * 25)
		scar.color = Color(0.1, 0.5, 0.1)
		add_child(scar)

	# Evil face
	var eye1 = ColorRect.new()
	eye1.size = Vector2(12, 12)
	eye1.position = Vector2(-20, -30)
	eye1.color = Color(1, 0, 0)  # Red glowing eyes
	add_child(eye1)

	var eye2 = ColorRect.new()
	eye2.size = Vector2(12, 12)
	eye2.position = Vector2(8, -30)
	eye2.color = Color(1, 0, 0)
	add_child(eye2)

	# Branches/arms
	var branch1 = Polygon2D.new()
	branch1.polygon = PackedVector2Array([
		Vector2(-30, -20),
		Vector2(-70, -40),
		Vector2(-65, -30),
		Vector2(-30, -15)
	])
	branch1.color = Color(0.25, 0.15, 0.08)
	add_child(branch1)

	var branch2 = Polygon2D.new()
	branch2.polygon = PackedVector2Array([
		Vector2(30, -20),
		Vector2(70, -40),
		Vector2(65, -30),
		Vector2(30, -15)
	])
	branch2.color = Color(0.25, 0.15, 0.08)
	add_child(branch2)

	# Green corrupted particles
	var particles = CPUParticles2D.new()
	particles.position = Vector2(0, -30)
	particles.emitting = true
	particles.amount = 15
	particles.lifetime = 2.0
	particles.direction = Vector2(0, -1)
	particles.spread = 45
	particles.gravity = Vector2(0, 20)
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 50
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 7.0

	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.2, 0.8, 0.2, 0.8))
	gradient.add_point(1.0, Color(0.1, 0.4, 0.1, 0))
	particles.color_ramp = gradient
	add_child(particles)

func create_warlord():
	# Armor body
	var body = ColorRect.new()
	body.size = Vector2(70, 90)
	body.position = Vector2(-35, -45)
	body.color = Color(0.3, 0.3, 0.3)  # Dark metal
	add_child(body)

	# Flame trim
	var trim1 = ColorRect.new()
	trim1.size = Vector2(70, 8)
	trim1.position = Vector2(-35, -40)
	trim1.color = Color(1, 0.3, 0)
	add_child(trim1)

	# Helmet
	var helmet = Polygon2D.new()
	helmet.polygon = PackedVector2Array([
		Vector2(0, -80),
		Vector2(-25, -45),
		Vector2(25, -45)
	])
	helmet.color = Color(0.2, 0.2, 0.2)
	add_child(helmet)

	# Eye slit (glowing)
	var eye_slit = ColorRect.new()
	eye_slit.size = Vector2(40, 6)
	eye_slit.position = Vector2(-20, -55)
	eye_slit.color = Color(1, 0.5, 0, 1)
	add_child(eye_slit)

	# Flaming sword
	var sword = ColorRect.new()
	sword.size = Vector2(10, 80)
	sword.position = Vector2(40, -60)
	sword.color = Color(0.5, 0.5, 0.5)
	add_child(sword)

	# Sword flames
	var sword_flame = CPUParticles2D.new()
	sword_flame.position = Vector2(45, -60)
	sword_flame.emitting = true
	sword_flame.amount = 20
	sword_flame.lifetime = 0.8
	sword_flame.direction = Vector2(0, -1)
	sword_flame.spread = 30
	sword_flame.gravity = Vector2(0, -30)
	sword_flame.initial_velocity_min = 40
	sword_flame.initial_velocity_max = 60
	sword_flame.scale_amount_min = 5.0
	sword_flame.scale_amount_max = 8.0

	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0.3, 0, 1))
	gradient.add_point(0.5, Color(1, 0.6, 0, 0.7))
	gradient.add_point(1.0, Color(1, 1, 0, 0))
	sword_flame.color_ramp = gradient
	add_child(sword_flame)

func create_lich():
	# Skeletal body
	var body = ColorRect.new()
	body.size = Vector2(50, 80)
	body.position = Vector2(-25, -40)
	body.color = Color(0.9, 0.9, 0.8)  # Bone white
	add_child(body)

	# Skull head
	var head = ColorRect.new()
	head.size = Vector2(40, 50)
	head.position = Vector2(-20, -90)
	head.color = Color(0.95, 0.95, 0.85)
	add_child(head)

	# Eye sockets (dark)
	var eye1 = ColorRect.new()
	eye1.size = Vector2(10, 15)
	eye1.position = Vector2(-15, -75)
	eye1.color = Color(0, 0, 0)
	add_child(eye1)

	var eye2 = ColorRect.new()
	eye2.size = Vector2(10, 15)
	eye2.position = Vector2(5, -75)
	eye2.color = Color(0, 0, 0)
	add_child(eye2)

	# Glowing eyes inside sockets
	var glow1 = ColorRect.new()
	glow1.size = Vector2(6, 6)
	glow1.position = Vector2(-13, -70)
	glow1.color = Color(0, 1, 0.5)  # Sickly green
	add_child(glow1)

	var glow2 = ColorRect.new()
	glow2.size = Vector2(6, 6)
	glow2.position = Vector2(7, -70)
	glow2.color = Color(0, 1, 0.5)
	add_child(glow2)

	# Dark robe
	var robe = Polygon2D.new()
	robe.polygon = PackedVector2Array([
		Vector2(0, -40),
		Vector2(-40, -20),
		Vector2(-50, 60),
		Vector2(50, 60),
		Vector2(40, -20)
	])
	robe.color = Color(0.1, 0.05, 0.15)  # Dark purple
	add_child(robe)

	# Necromantic particles
	var particles = CPUParticles2D.new()
	particles.position = Vector2(0, 0)
	particles.emitting = true
	particles.amount = 25
	particles.lifetime = 3.0
	particles.direction = Vector2(0, -1)
	particles.spread = 360
	particles.gravity = Vector2(0, -10)
	particles.initial_velocity_min = 20
	particles.initial_velocity_max = 40
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0

	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.5, 0, 0.8, 0.8))
	gradient.add_point(0.5, Color(0.3, 0, 0.5, 0.5))
	gradient.add_point(1.0, Color(0.2, 0, 0.3, 0))
	particles.color_ramp = gradient
	add_child(particles)

func create_dragon():
	# Reuse the dragon visual but make it bigger and more menacing
	var dragon_script = load("res://scripts/dragon_visual.gd")
	var dragon = Node2D.new()
	dragon.set_script(dragon_script)
	dragon.scale = Vector2(1.5, 1.5)  # Bigger!
	add_child(dragon)

func create_void_titan():
	# Cosmic horror shape
	var core = ColorRect.new()
	core.size = Vector2(80, 100)
	core.position = Vector2(-40, -50)
	core.color = Color(0.1, 0, 0.2, 0.9)
	add_child(core)

	# Void tendrils
	for i in range(6):
		var tentacle = Polygon2D.new()
		var angle = (i / 6.0) * TAU
		var base_x = cos(angle) * 30
		var base_y = sin(angle) * 30
		var end_x = cos(angle) * 80
		var end_y = sin(angle) * 80

		tentacle.polygon = PackedVector2Array([
			Vector2(base_x, base_y),
			Vector2(end_x, end_y),
			Vector2(end_x + 5, end_y + 5),
			Vector2(base_x + 5, base_y + 5)
		])
		tentacle.color = Color(0.2, 0, 0.3, 0.7)
		add_child(tentacle)

	# Cosmic eye
	var eye = ColorRect.new()
	eye.size = Vector2(30, 30)
	eye.position = Vector2(-15, -30)
	eye.color = Color(0.5, 0, 1, 1)
	add_child(eye)

	var pupil = ColorRect.new()
	pupil.size = Vector2(10, 10)
	pupil.position = Vector2(-5, -20)
	pupil.color = Color(0, 0, 0)
	add_child(pupil)

	# Reality-warping particles
	var particles = CPUParticles2D.new()
	particles.position = Vector2(0, 0)
	particles.emitting = true
	particles.amount = 40
	particles.lifetime = 2.5
	particles.direction = Vector2(0, 0)
	particles.spread = 360
	particles.gravity = Vector2(0, 0)
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 60
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 10.0

	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.8, 0, 1, 1))
	gradient.add_point(0.3, Color(0, 0.5, 1, 0.7))
	gradient.add_point(0.6, Color(1, 0, 0.5, 0.5))
	gradient.add_point(1.0, Color(0.5, 0, 0.8, 0))
	particles.color_ramp = gradient
	add_child(particles)

func _process(delta: float):
	animation_time += delta

	match boss_name:
		"Corrupted Treant":
			# Swaying motion
			rotation = sin(animation_time * 0.5) * 0.1
		"Flame Warlord":
			# Threatening stance
			position.y = sin(animation_time * 2.0) * 5
		"Lich Summoner":
			# Floating motion
			position.y = sin(animation_time * 1.5) * 15
		"Storm Dragon":
			# Handled by dragon script
			pass
		"Void Titan":
			# Pulsing/warping effect
			scale = Vector2(1.0 + sin(animation_time * 2.0) * 0.1, 1.0 + cos(animation_time * 2.0) * 0.1)
