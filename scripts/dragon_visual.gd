extends Node2D

var walk_direction: int = 1
var fire_timer: float = 0.0
var walk_speed: float = 50.0
var fire_cooldown: float = 3.0

@onready var body: ColorRect = $Body
@onready var head: ColorRect = $Head
@onready var wing1: Polygon2D = $Wing1
@onready var wing2: Polygon2D = $Wing2
@onready var tail: Polygon2D = $Tail
@onready var fire_particles: CPUParticles2D = $FireParticles

func _ready():
	# Create dragon body
	body = ColorRect.new()
	body.size = Vector2(80, 50)
	body.position = Vector2(-40, -25)
	body.color = Color(0.1, 0.6, 0.2)  # Green
	add_child(body)

	# Create dragon head
	head = ColorRect.new()
	head.size = Vector2(40, 35)
	head.position = Vector2(40, -20)
	head.color = Color(0.2, 0.7, 0.3)  # Lighter green
	add_child(head)

	# Create eyes
	var eye1 = ColorRect.new()
	eye1.size = Vector2(8, 8)
	eye1.position = Vector2(60, -12)
	eye1.color = Color(1, 1, 0)  # Yellow eyes
	add_child(eye1)

	var pupil1 = ColorRect.new()
	pupil1.size = Vector2(4, 4)
	pupil1.position = Vector2(62, -10)
	pupil1.color = Color(0, 0, 0)  # Black pupils
	add_child(pupil1)

	var eye2 = ColorRect.new()
	eye2.size = Vector2(8, 8)
	eye2.position = Vector2(60, 5)
	eye2.color = Color(1, 1, 0)  # Yellow eyes
	add_child(eye2)

	var pupil2 = ColorRect.new()
	pupil2.size = Vector2(4, 4)
	pupil2.position = Vector2(62, 7)
	pupil2.color = Color(0, 0, 0)  # Black pupils
	add_child(pupil2)

	# Create wings
	wing1 = Polygon2D.new()
	wing1.polygon = PackedVector2Array([
		Vector2(0, -20),
		Vector2(-30, -50),
		Vector2(-20, -10)
	])
	wing1.color = Color(0.15, 0.5, 0.2, 0.8)  # Dark green
	add_child(wing1)

	wing2 = Polygon2D.new()
	wing2.polygon = PackedVector2Array([
		Vector2(0, 20),
		Vector2(-30, 50),
		Vector2(-20, 10)
	])
	wing2.color = Color(0.15, 0.5, 0.2, 0.8)  # Dark green
	add_child(wing2)

	# Create tail
	tail = Polygon2D.new()
	tail.polygon = PackedVector2Array([
		Vector2(-40, 0),
		Vector2(-80, -15),
		Vector2(-70, 0),
		Vector2(-80, 15)
	])
	tail.color = Color(0.2, 0.6, 0.25)  # Green
	add_child(tail)

	# Create fire particles
	fire_particles = CPUParticles2D.new()
	fire_particles.position = Vector2(80, 0)
	fire_particles.emitting = false
	fire_particles.amount = 20
	fire_particles.lifetime = 0.5
	fire_particles.one_shot = false
	fire_particles.explosiveness = 0.8
	fire_particles.direction = Vector2(1, 0)
	fire_particles.spread = 30
	fire_particles.initial_velocity_min = 100
	fire_particles.initial_velocity_max = 150
	fire_particles.scale_amount_min = 8.0
	fire_particles.scale_amount_max = 15.0

	# Fire colors (red to orange to yellow)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0.3, 0, 1))
	gradient.add_point(0.5, Color(1, 0.6, 0, 0.8))
	gradient.add_point(1.0, Color(1, 1, 0, 0))
	fire_particles.color_ramp = gradient

	add_child(fire_particles)

	# Start at random position
	position.x = randf_range(200, 600)
	position.y = randf_range(150, 300)

func _process(delta: float):
	# Walk animation
	position.x += walk_direction * walk_speed * delta

	# Bounce at edges
	if position.x > 700:
		walk_direction = -1
		scale.x = -1  # Flip sprite
	elif position.x < 200:
		walk_direction = 1
		scale.x = 1

	# Wing flap animation
	var flap = sin(Time.get_ticks_msec() / 200.0) * 10
	wing1.position.y = flap
	wing2.position.y = -flap

	# Tail sway
	var sway = sin(Time.get_ticks_msec() / 300.0) * 5
	tail.position.y = sway

	# Fire breath timer
	fire_timer += delta
	if fire_timer >= fire_cooldown:
		breathe_fire()
		fire_timer = 0.0
		fire_cooldown = randf_range(2.0, 5.0)

func breathe_fire():
	fire_particles.emitting = true
	await get_tree().create_timer(0.6).timeout
	fire_particles.emitting = false
