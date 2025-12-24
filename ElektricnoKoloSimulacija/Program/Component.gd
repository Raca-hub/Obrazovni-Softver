extends Node2D
class_name CircuitComponent

# Tipovi komponenti - koristimo konstante umesto enuma za bolju vidljivost
const BATTERY = 0
const RESISTOR = 1
const BULB = 2
const SWITCH = 3
const WIRE = 4
const AMMETER = 5
const VOLTMETER = 6

# View modes
enum ViewMode {
	SCHEMATIC,
	VIEW_2D,
	VIEW_3D
}

# Svojstva komponente
var component_type: int = BATTERY
var value: float = 0.0  # Otpor (Ω), Napon (V), itd.
var current: float = 0.0  # Struja kroz komponentu (A)
var voltage: float = 0.0  # Pad napona (V)
var is_on: bool = true  # Za prekidač

# View mode
var view_mode = ViewMode.SCHEMATIC

# 2D Texture paths (postavi svoje putanje)
var texture_2d_path = ""
var texture_2d: Texture2D = null

# 3D Model (za buduću implementaciju)
var model_3d_scene_path = ""
var model_3d_instance: Node3D = null
var model_3d_root: Node3D = null  # Reference na 3D root u sceni

# Drag & Drop
var draggable = false
var dragging = false
var drag_offset = Vector2.ZERO

# Rotacija
var rotation_angle = 0  # 0, 90, 180, 270

# Terminali za povezivanje
var terminals = []

# Vizuelni elementi
var sprite: Sprite2D
var label: Label
var area: Area2D

# Hover efekat
var is_hovered = false

func _ready():
	# Postavi Area2D za interakciju
	setup_area2d()
	
	# Kreiraj terminale
	create_terminals()
	
	# Kreiraj vizuelne elemente
	create_visuals()

func setup_area2d():
	# Nađi ili kreiraj Area2D
	area = get_node_or_null("Area2D")
	if not area:
		area = Area2D.new()
		area.name = "Area2D"
		add_child(area)
		
		# Dodaj CollisionShape2D
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(100, 60)
		collision.shape = shape
		area.add_child(collision)
	
	# Povezi signale
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	area.input_event.connect(_on_input_event)

func _on_mouse_entered():
	is_hovered = true
	queue_redraw()

func _on_mouse_exited():
	is_hovered = false
	queue_redraw()

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if draggable:
					# Započni drag
					dragging = true
					drag_offset = global_position - get_global_mouse_position()
			else:
				# Završi drag
				if dragging:
					dragging = false
					# Snap to grid
					var grid_size = 20
					position = Vector2(
						round(position.x / grid_size) * grid_size,
						round(position.y / grid_size) * grid_size
					)
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Desni klik - rotacija
			rotate_component()
		
		# Prekidač toggle
		if component_type == SWITCH and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			toggle_switch()

func _process(delta):
	if dragging:
		global_position = get_global_mouse_position() + drag_offset
		
		# Ažuriraj 3D poziciju ako je u 3D modu
		if view_mode == ViewMode.VIEW_3D:
			update_3d_position()

func rotate_component():
	rotation_angle = (rotation_angle + 90) % 360
	rotation_degrees = rotation_angle
	
	# Ažuriraj terminale nakon rotacije
	update_terminal_positions()
	
	# Obavesti sve žice da se ažuriraju
	notify_wires_update()
	
	queue_redraw()
	print("Komponenta rotirana na: ", rotation_angle, "°")

func notify_wires_update():
	# Obavesti sve povezane žice da ažuriraju svoje pozicije
	for terminal in terminals:
		for connection in terminal.connections:
			if connection.has("wire"):
				connection.wire.force_update_positions()

func init(type: int, val: float = 0.0):
	component_type = type
	value = val
	
	# Postavi default vrednosti i putanje
	match type:
		BATTERY:
			value = 9.0 if val == 0 else val  # 9V baterija
			texture_2d_path = "res://assets/battery_2d.png"
			model_3d_scene_path = "res://models/battery_3d.tscn"
		RESISTOR:
			value = 100.0 if val == 0 else val  # 100Ω otpornik
			texture_2d_path = "res://assets/resistor_2d.png"
			model_3d_scene_path = "res://models/resistor_3d.tscn"
		BULB:
			value = 50.0 if val == 0 else val  # ~50Ω sijalica
			texture_2d_path = "res://assets/bulb_2d.png"
			model_3d_scene_path = "res://models/bulb_3d.tscn"
		SWITCH:
			texture_2d_path = "res://assets/switch_2d.png"
			model_3d_scene_path = "res://models/switch_3d.tscn"
	
	# Pokušaj učitati 2D teksturu
	load_2d_texture()
	
	# Ažuriraj terminale nakon init
	if terminals.size() > 0:
		update_terminal_positions()

func load_2d_texture():
	# Pokušaj učitati teksturu
	if texture_2d_path != "" and ResourceLoader.exists(texture_2d_path):
		texture_2d = load(texture_2d_path)
		print("Učitana 2D tekstura: ", texture_2d_path)
	else:
		# Ako tekstura ne postoji, napravi placeholder
		texture_2d = create_placeholder_texture()
		if texture_2d_path != "":
			print("UPOZORENJE: Tekstura ne postoji, koristim placeholder: ", texture_2d_path)

func create_placeholder_texture() -> ImageTexture:
	# Napravi placeholder sliku 100x100
	var img = Image.create(100, 100, false, Image.FORMAT_RGBA8)
	
	# Popuni pozadinu bojom zavisno od tipa
	var bg_color = Color.WHITE
	match component_type:
		BATTERY:
			bg_color = Color(0.9, 0.2, 0.2, 1.0)  # Crvena
		RESISTOR:
			bg_color = Color(0.9, 0.7, 0.2, 1.0)  # Žuta
		BULB:
			bg_color = Color(0.9, 0.9, 0.2, 1.0)  # Svetložuta
		SWITCH:
			bg_color = Color(0.2, 0.7, 0.9, 1.0)  # Plava
	
	img.fill(bg_color)
	
	# Dodaj ivicu
	for x in range(100):
		img.set_pixel(x, 0, Color.BLACK)
		img.set_pixel(x, 99, Color.BLACK)
	for y in range(100):
		img.set_pixel(0, y, Color.BLACK)
		img.set_pixel(99, y, Color.BLACK)
	
	return ImageTexture.create_from_image(img)

func set_view_mode(mode):
	print("    [Component ", get_instance_id(), "] Postavljam view_mode sa ", view_mode, " na ", mode)
	view_mode = mode
	
	# Upravljaj 3D modelom
	if mode == ViewMode.VIEW_3D:
		# Prikaži 3D model
		if not model_3d_instance:
			load_3d_model()
		if model_3d_instance:
			model_3d_instance.visible = true
	else:
		# Sakrij 3D model
		if model_3d_instance:
			model_3d_instance.visible = false
	
	# Forsiraj redraw
	queue_redraw()
	
	print("    [Component ", get_instance_id(), "] view_mode sada je: ", view_mode)

func load_3d_model():
	# Učitaj 3D model iz scene fajla
	if model_3d_scene_path == "":
		print("    UPOZORENJE: Nema putanje za 3D model")
		return
	
	if not ResourceLoader.exists(model_3d_scene_path):
		print("    UPOZORENJE: 3D model ne postoji: ", model_3d_scene_path)
		return
	
	var scene = load(model_3d_scene_path)
	if not scene:
		print("    GREŠKA: Nije moguće učitati 3D scenu: ", model_3d_scene_path)
		return
	
	model_3d_instance = scene.instantiate()
	
	# Pronađi 3D root u sceni
	model_3d_root = get_tree().get_first_node_in_group("3d_world")
	if not model_3d_root:
		print("    GREŠKA: Nema 3D world root node-a!")
		return
	
	# Dodaj model kao child 3D root-a
	model_3d_root.add_child(model_3d_instance)
	
	# Pozicioniraj 3D model na osnovu 2D pozicije
	update_3d_position()
	
	print("    Učitan 3D model: ", model_3d_scene_path)

func update_3d_position():
	# Sinhronizuj 3D poziciju sa 2D pozicijom
	if model_3d_instance:
		# Konvertuj 2D koordinate u 3D
		# 2D grid -> 3D world
		var pos_3d = Vector3(
			position.x / 100.0 - 6.4,  # Centriraj
			0.0,
			position.y / 100.0 - 3.6
		)
		model_3d_instance.position = pos_3d
		
		# Primeni rotaciju
		model_3d_instance.rotation_degrees = Vector3(0, -rotation_angle, 0)

func update_3d_visual_state():
	# Ažuriraj vizuelni prikaz 3D modela (svetlo sijalice, itd.)
	if not model_3d_instance:
		return
	
	match component_type:
		BULB:
			# Pronađi OmniLight3D u modelu
			var light = model_3d_instance.get_node_or_null("Light")
			if light and light is OmniLight3D:
				# Postavi intenzitet svetla na osnovu struje
				var brightness = clamp(current * 2.0, 0.0, 1.0)
				light.light_energy = brightness * 3.0
				light.visible = current > 0.001
		
		SWITCH:
			# Animiraj prekidač
			# (potrebno je da imaš AnimationPlayer u 3D modelu)
			var anim_player = model_3d_instance.get_node_or_null("AnimationPlayer")
			if anim_player:
				if is_on:
					anim_player.play("switch_on")
				else:
					anim_player.play("switch_off")

func create_terminals():
	# Kreiraj dva terminala (levi i desni)
	# Pozicije se rotiraju zajedno sa komponentom
	var left_terminal = {
		"position": Vector2(-40, 0),
		"connections": []
	}
	var right_terminal = {
		"position": Vector2(40, 0),
		"connections": []
	}
	
	terminals = [left_terminal, right_terminal]

func update_terminal_positions():
	# Ažuriraj pozicije terminala na osnovu rotacije
	if terminals.size() < 2:
		return
	
	var angle_rad = deg_to_rad(rotation_angle)
	
	# Početne pozicije pre rotacije
	var left_base = Vector2(-40, 0)
	var right_base = Vector2(40, 0)
	
	# Rotiraj pozicije
	terminals[0].position = left_base.rotated(angle_rad)
	terminals[1].position = right_base.rotated(angle_rad)
	
	print("Terminali ažurirani: ", terminals[0].position, " i ", terminals[1].position)

func create_visuals():
	# Kreiraj sprite za komponentu
	sprite = Sprite2D.new()
	add_child(sprite)
	
	# Učitaj teksturu zavisno od tipa
	match component_type:
		BATTERY:
			draw_battery()
		RESISTOR:
			draw_resistor()
		BULB:
			draw_bulb()
		SWITCH:
			draw_switch()
	
	# Dodaj label za vrednost
	label = Label.new()
	label.position = Vector2(-20, -30)
	add_child(label)
	update_label()

func draw_battery():
	# Nacrtaj bateriju koristeći CanvasItem
	queue_redraw()

func draw_resistor():
	queue_redraw()

func draw_bulb():
	queue_redraw()

func draw_switch():
	queue_redraw()

func _draw():
	# Nacrtaj highlight ako je hovered
	if is_hovered:
		draw_rect(Rect2(-50, -30, 100, 60), Color(0.5, 0.7, 1.0, 0.2))
	
	# Debug - prikaži trenutni view mode
	#print("_draw() pozvan, view_mode=", view_mode)
	
	# Različit prikaz zavisno od view mode-a
	match view_mode:
		ViewMode.SCHEMATIC:
			draw_schematic()
		ViewMode.VIEW_2D:
			draw_2d_view()
		ViewMode.VIEW_3D:
			# 3D prikaz se radi sa 3D nodovima, ne sa _draw()
			# Ovde možemo nacrtati samo placeholder
			draw_3d_placeholder()
		_:
			# Default fallback
			print("NEPOZNAT VIEW MODE: ", view_mode)
			draw_schematic()
	
	# Uvek crtaj terminale
	draw_circle(Vector2(-40, 0), 4, Color.DARK_RED)
	draw_circle(Vector2(-40, 0), 3, Color.RED)
	draw_circle(Vector2(40, 0), 4, Color.DARK_RED)
	draw_circle(Vector2(40, 0), 3, Color.RED)

func draw_schematic():
	# Šematski prikaz (originalani kod)
	match component_type:
		BATTERY:
			# Nacrtaj simbol baterije
			draw_line(Vector2(-40, 0), Vector2(-20, 0), Color.BLACK, 2.0)
			draw_line(Vector2(-20, -15), Vector2(-20, 15), Color.BLACK, 4.0)
			draw_line(Vector2(-10, -10), Vector2(-10, 10), Color.BLACK, 2.0)
			draw_line(Vector2(-10, 0), Vector2(20, 0), Color.BLACK, 2.0)
			draw_line(Vector2(20, -15), Vector2(20, 15), Color.BLACK, 4.0)
			draw_line(Vector2(20, 0), Vector2(40, 0), Color.BLACK, 2.0)
			
			# + i - oznake
			draw_string(ThemeDB.fallback_font, Vector2(25, -5), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.RED)
			draw_string(ThemeDB.fallback_font, Vector2(-35, -5), "-", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.BLUE)
		
		RESISTOR:
			# Nacrtaj simbol otpornika (cik-cak)
			draw_line(Vector2(-40, 0), Vector2(-30, 0), Color.BLACK, 2.0)
			var points = [
				Vector2(-30, 0), Vector2(-25, -10), Vector2(-15, 10),
				Vector2(-5, -10), Vector2(5, 10), Vector2(15, -10),
				Vector2(25, 10), Vector2(30, 0)
			]
			for i in range(points.size() - 1):
				draw_line(points[i], points[i + 1], Color.BLACK, 2.0)
			draw_line(Vector2(30, 0), Vector2(40, 0), Color.BLACK, 2.0)
		
		BULB:
			# Nacrtaj sijalicu (krug)
			draw_circle(Vector2(0, 0), 20, Color.WHITE)
			draw_arc(Vector2(0, 0), 20, 0, TAU, 32, Color.BLACK, 2.0)
			
			# Žarulja u sredini
			if current > 0.001:  # Ako ima struje, svetli
				var brightness = clamp(current * 10.0, 0.0, 1.0)
				draw_circle(Vector2(0, 0), 15, Color.YELLOW * brightness)
			
			# Prikaz filamentа
			draw_line(Vector2(-8, -8), Vector2(8, 8), Color.BLACK, 1.5)
			draw_line(Vector2(-8, 8), Vector2(8, -8), Color.BLACK, 1.5)
			
			# Terminali
			draw_line(Vector2(-40, 0), Vector2(-20, 0), Color.BLACK, 2.0)
			draw_line(Vector2(20, 0), Vector2(40, 0), Color.BLACK, 2.0)
		
		SWITCH:
			# Nacrtaj prekidač
			draw_line(Vector2(-40, 0), Vector2(-20, 0), Color.BLACK, 2.0)
			draw_circle(Vector2(-20, 0), 3, Color.BLACK)
			draw_circle(Vector2(20, 0), 3, Color.BLACK)
			
			if is_on:
				draw_line(Vector2(-20, 0), Vector2(20, 0), Color.GREEN, 2.0)
			else:
				draw_line(Vector2(-20, 0), Vector2(15, -10), Color.RED, 2.0)
			
			draw_line(Vector2(20, 0), Vector2(40, 0), Color.BLACK, 2.0)
	
	# Nacrtaj terminale kao male krugove (u lokalnom koordinatnom sistemu pre rotacije)
	# Terminali su na (-40, 0) i (40, 0) uvek
	draw_circle(Vector2(-40, 0), 4, Color.DARK_RED)
	draw_circle(Vector2(-40, 0), 3, Color.RED)
	draw_circle(Vector2(40, 0), 4, Color.DARK_RED)
	draw_circle(Vector2(40, 0), 3, Color.RED)

func draw_2d_view():
	# 2D prikaz sa slikama/teksturama
	if texture_2d:
		# Nacrtaj teksturu centriranu i skaliranu
		var tex_size = texture_2d.get_size()
		
		# Skaliraj da bude otprilike iste veličine kao šematski prikaz
		var target_width = 80.0
		var scale_factor = target_width / tex_size.x
		var scaled_size = tex_size * scale_factor
		
		var draw_pos = -scaled_size / 2
		var draw_rect = Rect2(draw_pos, scaled_size)
		
		draw_texture_rect(texture_2d, draw_rect, false)
		
		# Dodaj label ispod
		var label_text = ""
		match component_type:
			BATTERY:
				label_text = str(value) + "V"
			RESISTOR:
				label_text = str(value) + "Ω"
			BULB:
				label_text = "BULB"
			SWITCH:
				label_text = "ON" if is_on else "OFF"
		
		draw_string(ThemeDB.fallback_font, Vector2(-20, 50), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.BLACK)
	else:
		# Fallback na šematski prikaz ako nema teksture
		draw_schematic()
		
		# Prikaži poruku da tekstura nedostaje
		draw_string(ThemeDB.fallback_font, Vector2(-30, 40), "No 2D texture", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.RED)

func draw_3d_placeholder():
	# Placeholder kada je 3D mod aktivan
	# U 3D modu, 3D model se prikazuje kao Node3D, ne kroz _draw()
	
	# Nacrtaj 3D-like box (pseudo 3D)
	var box_color = Color(0.3, 0.3, 0.4, 0.8)
	
	# Front face
	draw_rect(Rect2(-35, -20, 70, 40), box_color)
	
	# Top face (perspective)
	var top_points = PackedVector2Array([
		Vector2(-35, -20), Vector2(-25, -28),
		Vector2(45, -28), Vector2(35, -20)
	])
	draw_colored_polygon(top_points, box_color.lightened(0.2))
	
	# Right face (perspective)
	var right_points = PackedVector2Array([
		Vector2(35, -20), Vector2(45, -28),
		Vector2(45, 12), Vector2(35, 20)
	])
	draw_colored_polygon(right_points, box_color.darkened(0.2))
	
	# Outline
	draw_rect(Rect2(-35, -20, 70, 40), Color.BLACK, false, 2.0)
	
	# Label
	var label_text = ""
	match component_type:
		BATTERY:
			label_text = "🔋 3D"
		RESISTOR:
			label_text = "⚡ 3D"
		BULB:
			label_text = "💡 3D"
		SWITCH:
			label_text = "🔘 3D"
	
	draw_string(ThemeDB.fallback_font, Vector2(-15, 5), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func get_nearest_terminal(pos: Vector2):
	# Pronađi najbliži terminal do date pozicije
	# MORA da uzme u obzir rotaciju komponente!
	var min_dist = INF
	var nearest = null
	var nearest_idx = -1
	
	for i in range(terminals.size()):
		# Bazna pozicija terminala
		var base_pos = Vector2(-40, 0) if i == 0 else Vector2(40, 0)
		
		# Primeni rotaciju
		var rotated_pos = base_pos.rotated(deg_to_rad(rotation_degrees))
		
		# Globalna pozicija terminala
		var terminal_global_pos = global_position + rotated_pos
		
		# Rastojanje do kliknutog mesta
		var dist = terminal_global_pos.distance_to(pos)
		
		if dist < min_dist:
			min_dist = dist
			nearest = terminals[i]
			nearest_idx = i
	
	# Debug
	if nearest:
		print("  Najbliži terminal: index=", nearest_idx, " udaljenost=", min_dist, "px")
	
	return nearest

func get_rect() -> Rect2:
	# Vrati pravougaonik za detekciju klika
	return Rect2(position - Vector2(50, 30), Vector2(100, 60))

func connect_to(other_component: CircuitComponent, wire):
	# Poveži ovu komponentu sa drugom
	terminals[1].connections.append({
		"component": other_component,
		"wire": wire
	})

func update_label():
	# Ažuriraj label sa vrednošću
	match component_type:
		BATTERY:
			label.text = str(value) + "V"
		RESISTOR:
			label.text = str(value) + "Ω"
		BULB:
			label.text = "💡"
	
	# Prikaži struju ako postoji
	if current > 0.001:
		label.text += "\n" + str(snapped(current, 0.001)) + "A"

func update_visual_state():
	# Ažuriraj vizuelni prikaz na osnovu trenutne struje
	update_label()
	queue_redraw()
	
	# Ažuriraj 3D vizuale
	if view_mode == ViewMode.VIEW_3D:
		update_3d_visual_state()

func toggle_switch():
	# Za prekidač
	if component_type == SWITCH:
		is_on = !is_on
		queue_redraw()
		print("Prekidač: ", "UKLJUČEN" if is_on else "ISKLJUČEN")

func _input_event(viewport, event, shape_idx):
	# Deprecated - sada koristimo Area2D signale
	pass

func show_context_menu():
	# Prikaži kontekstualni meni za menjanje vrednosti
	pass
