extends ColorRect

var time: float = 0.0
var gradient_shader: Shader

func _ready():
	# Create animated gradient background
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.1, 0.05, 0.2))
	gradient.add_point(0.5, Color(0.15, 0.1, 0.3))
	gradient.add_point(1.0, Color(0.2, 0.15, 0.4))

	# Add floating particles
	create_particles()

func create_particles():
	var particles = CPUParticles2D.new()
	particles.position = Vector2(size.x / 2, 0)
	particles.emitting = true
	particles.amount = 50
	particles.lifetime = 8.0
	particles.preprocess = 4.0
	particles.local_coords = false
	particles.emission_shape = 3  # BOX shape (Godot 4)
	particles.emission_rect_extents = Vector2(size.x, 10)

	particles.direction = Vector2(0, 1)
	particles.spread = 30
	particles.gravity = Vector2(0, 15)
	particles.initial_velocity_min = 20
	particles.initial_velocity_max = 40
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0

	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.5, 0.3, 0.8, 0.6))
	gradient.add_point(0.5, Color(0.7, 0.5, 1.0, 0.4))
	gradient.add_point(1.0, Color(0.8, 0.6, 1.0, 0))
	particles.color_ramp = gradient

	add_child(particles)

func _process(delta: float):
	time += delta
	# Gentle color pulsing
	var pulse = (sin(time * 0.5) + 1.0) / 2.0
	color = Color(0.1 + pulse * 0.05, 0.05 + pulse * 0.05, 0.2 + pulse * 0.1)
