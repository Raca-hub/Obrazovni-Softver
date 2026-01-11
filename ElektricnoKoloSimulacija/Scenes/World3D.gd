extends Node3D
# 3D Svet - samo za vizuelni pregled kola koje je napravljeno u 2D

@onready var camera_controller = $CameraController
@onready var directional_light = $DirectionalLight3D
@onready var environment = $WorldEnvironment

func _ready():
	# Postavi grupu za 3D svet
	add_to_group("3d_world")
	
	setup_environment()
	setup_lighting()
	
	print("✓ World3D spreman")

func setup_environment():
	# Kreiraj WorldEnvironment ako ne postoji
	if not environment:
		environment = WorldEnvironment.new()
		environment.name = "WorldEnvironment"
		add_child(environment)
	
	# Kreiraj Environment
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.15)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.3, 0.4)
	env.ambient_light_energy = 0.5
	
	# Dodaj Glow za lepši efekat
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_strength = 0.8
	env.glow_bloom = 0.1
	
	environment.environment = env

func setup_lighting():
	# Kreiraj DirectionalLight3D ako ne postoji
	if not directional_light:
		directional_light = DirectionalLight3D.new()
		directional_light.name = "DirectionalLight3D"
		add_child(directional_light)
	
	directional_light.light_energy = 0.8
	directional_light.light_color = Color(1.0, 0.95, 0.9)
	directional_light.rotation_degrees = Vector3(-45, 30, 0)
	directional_light.shadow_enabled = true

func add_component_3d(component_2d):
	# Ova funkcija se poziva kada komponenta treba da se prikaže u 3D
	# Komponenta sama kreira svoj 3D model i dodaje ga ovde
	pass

func clear_3d_components():
	# Obriši sve 3D komponente
	for child in get_children():
		if child.is_in_group("component_3d"):
			child.queue_free()
