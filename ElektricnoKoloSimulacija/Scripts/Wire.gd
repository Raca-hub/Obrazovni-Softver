extends Line2D
class_name CircuitWire

var start_terminal = null
var end_terminal = null
var start_component = null
var end_component = null
var start_terminal_index = 0  # Index terminala (0 ili 1)
var end_terminal_index = 0
var current: float = 0.0

# View mode
var view_mode = 0  # 0=Schematic, 1=2D, 2=3D

# Animacija protoka struje
var electron_particles = []
var particle_speed = 100.0

# 2D/3D wire texture
var wire_texture_2d: Texture2D = null
var wire_texture_path = "res://assets/wire_2d.png"
var electron_texture_2d: Texture2D = null
var electron_texture_path = "res://assets/electron_2d.png"

# 3D wire
var wire_3d_instance: Node3D = null
var wire_3d_root: Node3D = null

func _ready():
	width = 3.0
	default_color = Color.DARK_GRAY
	
	# Učitaj texture za 2D/3D prikaz
	load_textures()
	
	# Kreiraj "elektrone" za animaciju
	create_electron_particles()

func load_textures():
	# Učitaj wire texture
	if ResourceLoader.exists(wire_texture_path):
		wire_texture_2d = load(wire_texture_path)
		print("Učitana wire texture: ", wire_texture_path)
	
	# Učitaj electron texture
	if ResourceLoader.exists(electron_texture_path):
		electron_texture_2d = load(electron_texture_path)
		print("Učitana electron texture: ", electron_texture_path)

func set_view_mode(mode):
	view_mode = mode
	
	# Ažuriraj izgled žice
	match mode:
		0:  # Schematic
			# Koristi Line2D (default)
			texture = null
			width = 3.0
			visible = true
			if wire_3d_instance:
				wire_3d_instance.visible = false
		1:  # 2D
			# Koristi teksturu ako postoji
			if wire_texture_2d:
				texture = wire_texture_2d
				texture_mode = Line2D.LINE_TEXTURE_TILE
				width = 8.0
			else:
				texture = null
				width = 5.0
			visible = true
			if wire_3d_instance:
				wire_3d_instance.visible = false
		2:  # 3D
			# Sakrij 2D liniju, prikaži 3D žicu
			visible = false
			if not wire_3d_instance:
				create_3d_wire()
			if wire_3d_instance:
				wire_3d_instance.visible = true
				update_3d_wire_position()
	
	# Ažuriraj elektrone
	update_electron_visuals()
	
	queue_redraw()

func create_3d_wire():
	# Kreiraj 3D verziju žice
	wire_3d_root = get_tree().get_first_node_in_group("3d_world")
	if not wire_3d_root:
		print("GREŠKA: Nema 3D world root!")
		return
	
	# Učitaj Wire3D scenu ili kreiraj proceduralno
	var Wire3DScene = preload("res://ElektricnoKoloSimulacija/Scenes/Wire3D.tscn")
	if ResourceLoader.exists("res://ElektricnoKoloSimulacija/Scenes/Wire3D.tscn"):
		wire_3d_instance = Wire3DScene.instantiate()
	else:
		# Kreiraj proceduralno ako scena ne postoji
		wire_3d_instance = Wire3DGenerator.new()
	
	wire_3d_root.add_child(wire_3d_instance)
	update_3d_wire_position()

func update_3d_wire_position():
	# Ažuriraj poziciju 3D žice na osnovu komponenti
	if not wire_3d_instance or not start_component or not end_component:
		return
	
	# Konvertuj 2D pozicije u 3D
	var start_pos_2d = start_component.global_position
	var end_pos_2d = end_component.global_position
	
	var start_pos_3d = Vector3(
		start_pos_2d.x / 100.0 - 6.4,
		0.0,
		start_pos_2d.y / 100.0 - 3.6
	)
	
	var end_pos_3d = Vector3(
		end_pos_2d.x / 100.0 - 6.4,
		0.0,
		end_pos_2d.y / 100.0 - 3.6
	)
	
	# Pozovi funkciju za generisanje žice
	if wire_3d_instance.has_method("generate_wire"):
		wire_3d_instance.generate_wire(start_pos_3d, end_pos_3d)
	elif wire_3d_instance.has_method("update_wire_position"):
		wire_3d_instance.update_wire_position(start_pos_3d, end_pos_3d)

func set_start_point(pos: Vector2):
	clear_points()
	add_point(to_local(pos))

func update_end_point(pos: Vector2):
	if get_point_count() == 1:
		add_point(to_local(pos))
	else:
		set_point_position(1, to_local(pos))

func connect_terminals(start, end):
	# Deprecated - sada postavljamo direktno u Main.gd
	start_terminal = start
	end_terminal = end
	
	clear_points()
	add_point(Vector2.ZERO)
	add_point(Vector2.ZERO)
	
	print("Žica povezana")

func create_electron_particles():
	# Kreiraj nekoliko "elektrona" za animaciju protoka struje
	for i in range(5):
		var particle = create_electron()
		particle.set_meta("position_ratio", i / 5.0)  # Koristi meta umesto direktnog property-ja
		electron_particles.append(particle)
		add_child(particle)

func create_electron() -> Node2D:
	var electron = Node2D.new()
	
	# Ako imamo electron teksturu, koristi Sprite2D
	if view_mode > 0 and electron_texture_2d:
		var sprite = Sprite2D.new()
		sprite.texture = electron_texture_2d
		sprite.scale = Vector2(0.3, 0.3)  # Skaliraj da bude mali
		electron.add_child(sprite)
	else:
		# Default - koristi ColorRect (plavi kvadrat)
		var circle = ColorRect.new()
		circle.size = Vector2(6, 6)
		circle.position = -circle.size / 2
		circle.color = Color.CYAN
		electron.add_child(circle)
	
	electron.modulate.a = 0.0  # Početno nevidljiv
	
	return electron

func update_electron_visuals():
	# Ažuriraj vizuelni prikaz svih elektrona
	for particle in electron_particles:
		# Obriši stare child node-ove
		for child in particle.get_children():
			child.queue_free()
		
		# Dodaj nove vizuelne elemente
		if view_mode > 0 and electron_texture_2d:
			var sprite = Sprite2D.new()
			sprite.texture = electron_texture_2d
			sprite.scale = Vector2(0.3, 0.3)
			particle.add_child(sprite)
		else:
			var circle = ColorRect.new()
			circle.size = Vector2(6, 6)
			circle.position = -circle.size / 2
			circle.color = Color.CYAN
			particle.add_child(circle)

func _process(delta):
	# Ažuriraj pozicije žice da prate komponente
	update_wire_positions()
	
	# Ažuriraj 3D žicu ako postoji
	if view_mode == 2 and wire_3d_instance:
		update_3d_wire_position()
	
	if current > 0.001:
		# Animiraj protok struje
		animate_current(delta)

func update_wire_positions():
	# Ažuriraj pozicije žice na osnovu komponenti i terminala
	if start_component and end_component:
		# Bazne pozicije terminala su uvek (-40, 0) za terminal[0] i (40, 0) za terminal[1]
		var start_base_pos = Vector2(-40, 0) if start_terminal_index == 0 else Vector2(40, 0)
		var end_base_pos = Vector2(-40, 0) if end_terminal_index == 0 else Vector2(40, 0)
		
		# Primeni rotaciju komponente
		var start_rotated = start_base_pos.rotated(deg_to_rad(start_component.rotation_degrees))
		var end_rotated = end_base_pos.rotated(deg_to_rad(end_component.rotation_degrees))
		
		# Dodaj globalnu poziciju komponente
		var start_pos = start_component.global_position + start_rotated
		var end_pos = end_component.global_position + end_rotated
		
		if get_point_count() >= 2:
			set_point_position(0, to_local(start_pos))
			set_point_position(1, to_local(end_pos))

func force_update_positions():
	# Forsiraj trenutno ažuriranje pozicija (poziva se kada se komponenta rotira)
	update_wire_positions()

func animate_current(delta):
	if get_point_count() < 2:
		return
	
	var start_pos = get_point_position(0)
	var end_pos = get_point_position(1)
	var wire_length = start_pos.distance_to(end_pos)
	
	if wire_length < 0.1:
		# Žica je premala, sakrij elektrone
		for particle in electron_particles:
			particle.modulate.a = 0.0
		return
	
	# Brzina proporcionalna struji (usporavamo malo)
	var speed = particle_speed * clamp(current, 0.0, 0.5)
	
	for particle in electron_particles:
		# Uzmi position_ratio iz meta
		var pos_ratio = particle.get_meta("position_ratio", 0.0)
		
		# Pomeri elektron duž žice
		pos_ratio += (speed * delta) / wire_length
		
		# Ako je prošao kraj, vrati na početak
		if pos_ratio > 1.0:
			pos_ratio = fmod(pos_ratio, 1.0)
		
		# Sačuvaj novi position_ratio
		particle.set_meta("position_ratio", pos_ratio)
		
		# Pozicioniraj elektron duž žice
		particle.position = start_pos.lerp(end_pos, pos_ratio)
		
		# Napravi ga vidljivim ako ima struje
		var alpha = clamp(current * 3.0, 0.0, 0.9)
		particle.modulate.a = alpha

func update_current_animation():
	# Promeni boju žice na osnovu struje
	if current > 0.001:
		# Što je veća struja, žica je svetlija/crvenkastija
		var intensity = clamp(current * 5.0, 0.0, 1.0)
		default_color = Color.RED.lerp(Color.YELLOW, intensity) * 0.7
	else:
		default_color = Color.DARK_GRAY

func get_resistance() -> float:
	# Žica ima mali otpor
	return 0.1

func set_current(value: float):
	current = value
	update_current_animation()
